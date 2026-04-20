import Foundation
import CoreData

/// Central service for progression and reward bookkeeping.
///
/// Responsibilities:
///   * Maintain `DailyRecord` footprints used by streaks, the prayer tree,
///     and the challenge road map.
///   * Accumulate XP (progression score) and drops (consumable currency)
///     driven by `RewardCalculator`.
///   * Track once-per-day challenge bonuses and once-per-tier challenge
///     completion / perfect bonuses.
///
/// XP and drops are persisted in two layers:
///   * Per-session amounts live on `PrayerSession.xpEarned` / `dropsEarned`
///     so that each session keeps its own reward receipt.
///   * Aggregate challenge bonuses and drop expenditure live in
///     `UserDefaults` under the `ProgressKey` namespace so they do not
///     require Core Data relationships back to a user entity.
final class GamificationService: ObservableObject {

    private let persistence: PersistenceController
    private let defaults: UserDefaults

    init(
        persistence: PersistenceController = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.persistence = persistence
        self.defaults = defaults
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - UserDefaults Keys

    private enum ProgressKey {
        static let challengeBonusXP      = "Progress_ChallengeBonusXP"
        static let challengeBonusDrops   = "Progress_ChallengeBonusDrops"
        static let dropsSpent            = "Progress_DropsSpent"

        /// Key suffix: identifies the last calendar day a daily challenge bonus was awarded,
        /// scoped to the tier so switching tiers resets the claim.
        static func dailyBonusDay(tier: Int) -> String { "Progress_DailyBonusDay_\(tier)" }

        /// Key suffix: completion bonus was awarded for this tier.
        static func completionAwarded(tier: Int) -> String { "Progress_CompletionAwarded_\(tier)" }

        /// Key suffix: perfect bonus was awarded for this tier.
        static func perfectAwarded(tier: Int) -> String { "Progress_PerfectAwarded_\(tier)" }

        /// Key suffix: continuity has been broken at some point during this tier.
        /// Set when the user chooses "continue normally" after a missed day.
        static func continuityBroken(tier: Int) -> String { "Progress_ContinuityBroken_\(tier)" }
    }

    // MARK: - Daily Activity Recording

    /// Updates the `DailyRecord` footprint for the day the session occurred.
    /// Call after a session has been persisted.
    @discardableResult
    func recordDailyActivity(date: Date = Date(), session: PrayerSession) -> DailyRecord {
        let record = DailyRecord.findOrCreate(for: date, in: context)
        record.personalSessionCount += 1
        record.hasFootprint = true

        let intercessoryCount = Int16(session.intercessoryItems.count)
        record.intercessoryItemCount += intercessoryCount

        session.dailyRecord = record
        persistence.save()
        return record
    }

    // MARK: - Session Reward Application

    /// Computes the reward breakdown for a session and saves it to the session row.
    /// `tier` and `isChallengeActive` control whether the daily challenge bonus is
    /// eligible; the bonus is only granted once per calendar day per tier.
    @discardableResult
    func applySessionReward(
        _ session: PrayerSession,
        tier: Int?,
        isChallengeInProgress: Bool
    ) -> SessionRewardBreakdown {
        let bonusEligible = isChallengeInProgress
            && tier != nil
            && claimDailyChallengeBonusIfAvailable(tier: tier!, date: session.date ?? Date())

        let breakdown = RewardCalculator.sessionReward(
            itemCount: session.itemList.count,
            categories: session.coveredCategories,
            durationSeconds: Double(session.duration),
            isChallengeDailyBonusEligible: bonusEligible
        )
        session.applyReward(breakdown)
        persistence.save()
        return breakdown
    }

    /// If today has not yet received the daily challenge bonus for this tier,
    /// mark it claimed and return `true`. Otherwise return `false`.
    /// Implemented this way so reward calculation and claim-tracking stay atomic.
    private func claimDailyChallengeBonusIfAvailable(tier: Int, date: Date) -> Bool {
        let dayKey = calendarDayKey(for: date)
        let storageKey = ProgressKey.dailyBonusDay(tier: tier)
        if defaults.string(forKey: storageKey) == dayKey { return false }
        defaults.set(dayKey, forKey: storageKey)
        return true
    }

    private func calendarDayKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    // MARK: - Challenge Bonuses

    /// Grants the challenge-completion reward for `tier` (plus perfect bonus
    /// when eligible) unless it has already been awarded. Returns the applied
    /// reward, or an empty reward if nothing was granted.
    @discardableResult
    func awardChallengeCompletionIfNeeded(tier: Int, isPerfect: Bool) -> ChallengeCompletionReward {
        var applied = ChallengeCompletionReward()

        let completionKey = ProgressKey.completionAwarded(tier: tier)
        if !defaults.bool(forKey: completionKey) {
            applied.completionXP    = RewardCalculator.challengeCompletionXP(totalDays: tier)
            applied.completionDrops = RewardCalculator.challengeCompletionDrops(totalDays: tier)
            defaults.set(true, forKey: completionKey)
        }

        let perfectKey = ProgressKey.perfectAwarded(tier: tier)
        if isPerfect && !defaults.bool(forKey: perfectKey) {
            applied.perfectXP    = RewardCalculator.perfectBonusXP(totalDays: tier)
            applied.perfectDrops = RewardCalculator.perfectBonusDrops(totalDays: tier)
            defaults.set(true, forKey: perfectKey)
        }

        if applied.totalXP > 0 || applied.totalDrops > 0 {
            addBonusXP(applied.totalXP)
            addBonusDrops(applied.totalDrops)
        }

        return applied
    }

    // MARK: - Break Handling (§3.5.3)

    /// Marks continuity as broken for `tier`, making the user ineligible for the
    /// perfect bonus. Used when the user chooses "continue normally" after a missed day.
    func markContinuityBroken(tier: Int) {
        defaults.set(true, forKey: ProgressKey.continuityBroken(tier: tier))
    }

    /// Has continuity been broken during the current run of `tier`?
    func isContinuityBroken(tier: Int) -> Bool {
        defaults.bool(forKey: ProgressKey.continuityBroken(tier: tier))
    }

    /// Attempts to spend drops to preserve continuity after a missed day.
    /// Returns `true` if the spend succeeded, `false` if the user cannot afford it.
    func spendDropsToPreserveContinuity(tier: Int) -> Bool {
        let cost = RewardCalculator.continuityRecoveryCost(totalDays: tier)
        return spendDrops(cost)
    }

    /// Awards the fixed reward for completing a full-ACTS recovery prayer.
    /// Continuity is preserved for the caller by not marking it broken.
    func awardActsRecoveryBonus() -> (xp: Int, drops: Int) {
        let bonus = RewardCalculator.actsRecoveryReward
        addBonusXP(bonus.xp)
        addBonusDrops(bonus.drops)
        return bonus
    }

    /// Resets all per-tier challenge state (daily claim, completion, perfect, continuity).
    /// Called when a new run of the tier is started.
    func resetChallengeState(tier: Int) {
        defaults.removeObject(forKey: ProgressKey.dailyBonusDay(tier: tier))
        defaults.removeObject(forKey: ProgressKey.completionAwarded(tier: tier))
        defaults.removeObject(forKey: ProgressKey.perfectAwarded(tier: tier))
        defaults.removeObject(forKey: ProgressKey.continuityBroken(tier: tier))
    }

    // MARK: - Drop Spending

    /// Deducts `amount` from the user's drop balance if they can afford it.
    /// Returns `true` on success, `false` when the balance is insufficient.
    @discardableResult
    func spendDrops(_ amount: Int) -> Bool {
        guard amount > 0 else { return true }
        guard getTotalDrops() >= amount else { return false }
        defaults.set(defaults.integer(forKey: ProgressKey.dropsSpent) + amount,
                     forKey: ProgressKey.dropsSpent)
        return true
    }

    private func addBonusXP(_ amount: Int) {
        guard amount != 0 else { return }
        defaults.set(defaults.integer(forKey: ProgressKey.challengeBonusXP) + amount,
                     forKey: ProgressKey.challengeBonusXP)
    }

    private func addBonusDrops(_ amount: Int) {
        guard amount != 0 else { return }
        defaults.set(defaults.integer(forKey: ProgressKey.challengeBonusDrops) + amount,
                     forKey: ProgressKey.challengeBonusDrops)
    }

    // MARK: - Totals

    /// Cumulative XP across every session plus challenge bonuses.
    func getTotalXP() -> Int {
        let sessionSum = sumSessionXP()
        let bonus = defaults.integer(forKey: ProgressKey.challengeBonusXP)
        return sessionSum + bonus
    }

    /// Spendable drop balance: session drops + bonus drops − drops already spent.
    func getTotalDrops() -> Int {
        let sessionSum = sumSessionDrops()
        let bonus = defaults.integer(forKey: ProgressKey.challengeBonusDrops)
        let spent = defaults.integer(forKey: ProgressKey.dropsSpent)
        return max(0, sessionSum + bonus - spent)
    }

    private func sumSessionXP() -> Int {
        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        guard let sessions = try? context.fetch(request) else { return 0 }
        return sessions.reduce(0) { $0 + Int($1.xpEarned) }
    }

    private func sumSessionDrops() -> Int {
        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        guard let sessions = try? context.fetch(request) else { return 0 }
        return sessions.reduce(0) { $0 + Int($1.dropsEarned) }
    }

    // MARK: - Level Progression (§3.5.4)

    /// Full level-progress snapshot derived from total XP.
    func levelProgress() -> LevelProgress {
        RewardCalculator.levelProgress(forTotalXP: getTotalXP())
    }

    /// Convenience: current level only.
    func calculateLevel() -> Int {
        levelProgress().level
    }

    // MARK: - Streak & Footprint Stats

    /// Consecutive days of prayer activity ending today.
    func getStreakCount() -> Int {
        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.predicate = NSPredicate(format: "hasFootprint == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyRecord.date, ascending: false)]
        guard let records = try? context.fetch(request) else { return 0 }

        var streak = 0
        var expectedDate = Calendar.current.startOfDay(for: Date())

        for record in records {
            guard let recordDate = record.date else { break }
            let day = Calendar.current.startOfDay(for: recordDate)
            if day == expectedDate {
                streak += 1
                expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: expectedDate)!
            } else {
                break
            }
        }
        return streak
    }

    func getTotalSessionCount() -> Int {
        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    func getTotalAnsweredCount() -> Int {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", PrayerStatus.answered.rawValue)
        return (try? context.count(for: request)) ?? 0
    }

    func getPrayedItemCount() -> Int {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(format: "isIntercessory == NO AND prayedCount > 0")
        return (try? context.count(for: request)) ?? 0
    }

    func getIntercessionPrayedCount() -> Int {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(format: "isIntercessory == YES AND prayedCount > 0")
        return (try? context.count(for: request)) ?? 0
    }

    func getTotalPrayerDuration() -> Float {
        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        guard let sessions = try? context.fetch(request) else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration }
    }

    func getTotalPrayerDays() -> Int {
        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.predicate = NSPredicate(format: "hasFootprint == YES")
        return (try? context.count(for: request)) ?? 0
    }

    func fetchDailyRecords(month: Date) -> [DailyRecord] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: comps),
              let end   = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }

        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyRecord.date, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    func fetchAllDailyRecords() -> [DailyRecord] {
        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyRecord.date, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Decoration Availability

    /// Returns decorations that are both (a) still locked and (b) now within reach
    /// of the user's current level. The UI can surface these as "available to buy".
    /// The actual purchase flow lives in `DecorationService.purchase(_:)`.
    func availableDecorationsForPurchase() -> [Decoration] {
        let level = calculateLevel()
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        request.predicate = NSPredicate(format: "isUnlocked == NO")
        guard let locked = try? context.fetch(request) else { return [] }
        return locked.filter { $0.isAvailable(atLevel: level) }
    }
}
