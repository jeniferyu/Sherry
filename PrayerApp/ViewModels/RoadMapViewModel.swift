import Foundation
import Combine
import CoreData

// MARK: - Challenge Models

struct ChallengeDay: Identifiable {
    let id: Int
    let dayNumber: Int          // 1-based
    let date: Date?
    let starRating: Int         // 0-3
    let isCompleted: Bool
    let isCurrent: Bool
    let isLocked: Bool
}

struct PrayerChallenge {
    let totalDays: Int
    let title: String
    var days: [ChallengeDay]

    var completedDays: Int { days.filter(\.isCompleted).count }
    var totalStars: Int { days.reduce(0) { $0 + $1.starRating } }
    var maxStars: Int { totalDays * 3 }
    var isFullyCompleted: Bool { completedDays >= totalDays }
}

struct ChallengeTier: Identifiable {
    let id: Int          // totalDays as unique key
    let totalDays: Int
    let title: String
    let isUnlocked: Bool
    let isCompleted: Bool
}

/// How the user chose to resolve a missed day — see §3.5.3.
enum MissedDayResolution {
    case continueNormally
    case spendDrops
    case actsRecoveryPrayer
}

/// Outcome of resolving a missed day, returned so the view can show feedback.
struct MissedDayResolutionOutcome {
    let resolution: MissedDayResolution
    let success: Bool
    let xpAwarded: Int
    let dropsAwarded: Int
    let dropsSpent: Int
    let continuityBroken: Bool
}

// MARK: - ViewModel

final class RoadMapViewModel: ObservableObject {

    private let gamificationService: GamificationService
    private let sessionService: SessionService

    static let allTiers = [3, 7, 14, 21]

    /// Temporary testing only — set to `false` before shipping.
    /// When `true`, every challenge tier in the picker is unlocked and tappable so you can exercise 3/7/14/21-day UI without meeting normal progress rules.
    private static let unlockAllChallengeTiersForTesting = true

    @Published var challenge: PrayerChallenge = PrayerChallenge(
        totalDays: 3, title: "3-Day Prayer Challenge", days: []
    )
    @Published var streakCount: Int = 0
    @Published var challengeTiers: [ChallengeTier] = []
    @Published var activeTierDays: Int = 3
    @Published var currentChallengeInProgress: Bool = true

    // Banner stats
    @Published var level: Int = 1
    @Published var currentXP: Int = 0
    @Published var nextLevelXP: Int = 75
    @Published var xpProgress: Double = 0
    @Published var prayedItemCount: Int = 0
    @Published var intercessionPrayedCount: Int = 0
    @Published var dropletCount: Int = 0

    // Progress summary
    @Published var totalChallengesCompleted: Int = 0
    @Published var totalStarsEarned: Int = 0
    @Published var totalPrayerDays: Int = 0

    // Challenge / continuity state
    @Published var pendingMissedDays: [Int] = []       // dayNumbers awaiting resolution
    @Published var continuityBroken: Bool = false      // true ⇒ perfect bonus unavailable

    init(
        gamificationService: GamificationService = GamificationService(),
        sessionService: SessionService = SessionService()
    ) {
        self.gamificationService = gamificationService
        self.sessionService = sessionService
        self.activeTierDays = Self.loadActiveTier()
    }

    // MARK: - Fetch

    func fetchRecords() {
        streakCount = gamificationService.getStreakCount()

        var completed = Self.loadCompletedTiers()
        activeTierDays = Self.loadActiveTier()
        challenge = buildChallenge(totalDays: activeTierDays)

        // When the active challenge is fully complete, attempt to award the
        // completion + perfect bonuses (idempotent, guarded inside the service).
        if challenge.isFullyCompleted {
            let isPerfect = !gamificationService.isContinuityBroken(tier: activeTierDays)
            gamificationService.awardChallengeCompletionIfNeeded(
                tier: activeTierDays,
                isPerfect: isPerfect
            )
            if !completed.contains(activeTierDays) {
                Self.markTierCompleted(activeTierDays)
                completed = Self.loadCompletedTiers()
            }
        }

        currentChallengeInProgress = !challenge.isFullyCompleted
        challengeTiers = buildTiers(completedTiers: completed, challengeInProgress: currentChallengeInProgress)

        refreshBannerStats()
        refreshContinuityState()

        totalPrayerDays = gamificationService.getTotalPrayerDays()
        let completedSet = Self.loadCompletedTiers()
        totalChallengesCompleted = completedSet.count

        var allStars = challenge.totalStars
        for tier in completedSet where tier != activeTierDays {
            let past = buildChallenge(totalDays: tier)
            allStars += past.totalStars
        }
        totalStarsEarned = allStars
    }

    /// Refreshes XP, level, drops, and related prayer counters from the gamification service.
    /// Split out so it can be called after reward-granting actions without rebuilding everything.
    private func refreshBannerStats() {
        let progress = gamificationService.levelProgress()
        level = progress.level
        currentXP = progress.xpIntoLevel
        nextLevelXP = progress.xpForNextLevel
        xpProgress = progress.fraction

        prayedItemCount = gamificationService.getPrayedItemCount()
        intercessionPrayedCount = gamificationService.getIntercessionPrayedCount()
        dropletCount = gamificationService.getTotalDrops()
    }

    // MARK: - Tier Selection

    func selectChallenge(_ tier: Int) {
        if !Self.unlockAllChallengeTiersForTesting {
            guard challengeTiers.first(where: { $0.totalDays == tier })?.isUnlocked == true else { return }
        }
        // Switching to a different tier starts a fresh run — reset its bonus /
        // continuity / daily-claim state so the user can earn them again.
        if tier != activeTierDays {
            gamificationService.resetChallengeState(tier: tier)
            Self.clearLastResolvedMissedDay(tier: tier)
        }
        Self.saveActiveTier(tier)
        activeTierDays = tier
        fetchRecords()
    }

    // MARK: - Scroll Focus

    /// Index for map scroll and the "current step" arrow: first day not yet completed.
    /// When every day is done, points at the last day.
    var focusDayIndex: Int {
        let days = challenge.days
        guard !days.isEmpty else { return 0 }
        if let i = days.firstIndex(where: { !$0.isCompleted }) { return i }
        return days.count - 1
    }

    // MARK: - Missed Day Handling (§3.5.3)

    /// Rebuilds `pendingMissedDays` and `continuityBroken` from the latest challenge snapshot.
    private func refreshContinuityState() {
        continuityBroken = gamificationService.isContinuityBroken(tier: activeTierDays)
        let lastResolved = Self.loadLastResolvedMissedDay(tier: activeTierDays)
        pendingMissedDays = challenge.days
            .filter { !$0.isCompleted && !$0.isLocked && !$0.isCurrent && $0.dayNumber > lastResolved }
            .map(\.dayNumber)
    }

    /// Applies a user-chosen resolution to the oldest outstanding missed day.
    /// Returns an outcome describing what happened, so the UI can show feedback.
    @discardableResult
    func resolveMissedDay(_ resolution: MissedDayResolution) -> MissedDayResolutionOutcome {
        guard let nextMissed = pendingMissedDays.min() else {
            return MissedDayResolutionOutcome(
                resolution: resolution,
                success: true,
                xpAwarded: 0, dropsAwarded: 0, dropsSpent: 0,
                continuityBroken: continuityBroken
            )
        }

        var outcome = MissedDayResolutionOutcome(
            resolution: resolution,
            success: false,
            xpAwarded: 0, dropsAwarded: 0, dropsSpent: 0,
            continuityBroken: continuityBroken
        )

        switch resolution {
        case .continueNormally:
            gamificationService.markContinuityBroken(tier: activeTierDays)
            outcome = MissedDayResolutionOutcome(
                resolution: .continueNormally, success: true,
                xpAwarded: 0, dropsAwarded: 0, dropsSpent: 0,
                continuityBroken: true
            )

        case .spendDrops:
            if gamificationService.spendDropsToPreserveContinuity(tier: activeTierDays) {
                let cost = RewardCalculator.continuityRecoveryCost(totalDays: activeTierDays)
                outcome = MissedDayResolutionOutcome(
                    resolution: .spendDrops, success: true,
                    xpAwarded: 0, dropsAwarded: 0, dropsSpent: cost,
                    continuityBroken: false
                )
            } else {
                // Not enough drops — keep the missed day pending, caller can fall back.
                return outcome
            }

        case .actsRecoveryPrayer:
            let reward = gamificationService.awardActsRecoveryBonus()
            outcome = MissedDayResolutionOutcome(
                resolution: .actsRecoveryPrayer, success: true,
                xpAwarded: reward.xp, dropsAwarded: reward.drops, dropsSpent: 0,
                continuityBroken: false
            )
        }

        Self.saveLastResolvedMissedDay(tier: activeTierDays, dayNumber: nextMissed)
        refreshBannerStats()
        refreshContinuityState()
        return outcome
    }

    // MARK: - Challenge Tier Logic

    /// Unlock rules for the "next challenge" picker:
    /// - Challenge in progress → ALL tiers locked
    /// - Challenge completed → unlock completed tiers + the next tier above the highest completed
    private func buildTiers(completedTiers: Set<Int>, challengeInProgress: Bool) -> [ChallengeTier] {
        let nextAboveHighest: Int? = {
            guard !Self.unlockAllChallengeTiersForTesting else { return nil }
            let highestCompleted = Self.allTiers.last(where: { completedTiers.contains($0) })
            guard let highest = highestCompleted else { return nil }
            return Self.allTiers.first(where: { $0 > highest })
        }()

        return Self.allTiers.map { days in
            let isCompleted = completedTiers.contains(days)
            let isUnlocked: Bool

            if Self.unlockAllChallengeTiersForTesting {
                isUnlocked = true
            } else if challengeInProgress {
                isUnlocked = false
            } else if isCompleted {
                isUnlocked = true
            } else if days == nextAboveHighest {
                isUnlocked = true
            } else {
                isUnlocked = false
            }

            return ChallengeTier(
                id: days,
                totalDays: days,
                title: "\(days)-Day Challenge",
                isUnlocked: isUnlocked,
                isCompleted: isCompleted
            )
        }
    }

    // MARK: - Build Active Challenge

    private func buildChallenge(totalDays: Int) -> PrayerChallenge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let startDate = challengeStartDate(streak: streakCount, totalDays: totalDays, today: today)

        let allRecords = gamificationService.fetchAllDailyRecords()
        let recordsByDay = Dictionary(uniqueKeysWithValues:
            allRecords.compactMap { r -> (Date, DailyRecord)? in
                guard let d = r.date else { return nil }
                return (calendar.startOfDay(for: d), r)
            }
        )

        var days: [ChallengeDay] = []
        for i in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            let isCurrent = dayStart == today
            let isLocked = dayStart > today
            let record = recordsByDay[dayStart]
            let isCompleted = (record?.hasFootprint ?? false) && !isLocked

            var stars = 0
            if isCompleted, let record {
                stars = starRating(for: record.sessionList)
            }

            days.append(ChallengeDay(
                id: i,
                dayNumber: i + 1,
                date: date,
                starRating: stars,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLocked: isLocked
            ))
        }

        return PrayerChallenge(totalDays: totalDays, title: "\(totalDays)-Day Prayer Challenge", days: days)
    }

    private func challengeStartDate(streak: Int, totalDays: Int, today: Date) -> Date {
        let calendar = Calendar.current
        let offset = min(max(streak - 1, 0), totalDays - 1)
        return calendar.date(byAdding: .day, value: -offset, to: today) ?? today
    }

    private func starRating(for sessions: [PrayerSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let allPersonalItems = sessions.flatMap(\.personalItems)
        let allIntercessoryItems = sessions.flatMap(\.intercessoryItems)

        let categories = Set(allPersonalItems.map(\.categoryEnum))
        let isFullACTS = categories.contains(.adoration)
            && categories.contains(.confession)
            && categories.contains(.thanksgiving)
            && categories.contains(.supplication)

        let hasIntercession = !allIntercessoryItems.isEmpty

        if isFullACTS && hasIntercession { return 3 }
        if isFullACTS { return 2 }
        return 1
    }

    // MARK: - Persistence (UserDefaults)

    private static let completedKey = "RoadMap_CompletedTiers"
    private static let activeTierKey = "RoadMap_ActiveTier"
    private static func lastResolvedKey(tier: Int) -> String { "RoadMap_LastResolvedMissedDay_\(tier)" }

    static func loadCompletedTiers() -> Set<Int> {
        let arr = UserDefaults.standard.array(forKey: completedKey) as? [Int] ?? []
        return Set(arr)
    }

    static func markTierCompleted(_ tier: Int) {
        var set = loadCompletedTiers()
        set.insert(tier)
        UserDefaults.standard.set(Array(set), forKey: completedKey)
    }

    static func loadActiveTier() -> Int {
        let val = UserDefaults.standard.integer(forKey: activeTierKey)
        return val > 0 ? val : 3
    }

    static func saveActiveTier(_ tier: Int) {
        UserDefaults.standard.set(tier, forKey: activeTierKey)
    }

    static func loadLastResolvedMissedDay(tier: Int) -> Int {
        UserDefaults.standard.integer(forKey: lastResolvedKey(tier: tier))
    }

    static func saveLastResolvedMissedDay(tier: Int, dayNumber: Int) {
        let current = loadLastResolvedMissedDay(tier: tier)
        if dayNumber > current {
            UserDefaults.standard.set(dayNumber, forKey: lastResolvedKey(tier: tier))
        }
    }

    static func clearLastResolvedMissedDay(tier: Int) {
        UserDefaults.standard.removeObject(forKey: lastResolvedKey(tier: tier))
    }

    // MARK: - Static Helpers for Session Integration

    /// Snapshot of the currently-active tier, used by `PrayerSessionViewModel`
    /// when it applies per-session rewards without needing a road-map instance.
    struct ActiveTierState {
        let tier: Int?
        let isInProgress: Bool
    }

    /// Reads the currently-selected tier and determines whether it is still in progress.
    /// Completed tiers return `isInProgress == false`, which disables the daily bonus.
    static func currentTierState() -> ActiveTierState {
        let tier = loadActiveTier()
        let completed = loadCompletedTiers().contains(tier)
        return ActiveTierState(tier: tier, isInProgress: !completed)
    }

    /// Invoked after a session is saved to see if the session finalised the
    /// active challenge. If so, awards completion + perfect bonuses (idempotently).
    @discardableResult
    static func finalizeIfCompleted(
        tier: Int,
        gamificationService: GamificationService
    ) -> ChallengeCompletionReward? {
        let tempVM = RoadMapViewModel(gamificationService: gamificationService)
        tempVM.streakCount = gamificationService.getStreakCount()
        tempVM.activeTierDays = tier
        let snapshot = tempVM.buildChallenge(totalDays: tier)
        guard snapshot.isFullyCompleted else { return nil }

        let isPerfect = !gamificationService.isContinuityBroken(tier: tier)
        let reward = gamificationService.awardChallengeCompletionIfNeeded(
            tier: tier,
            isPerfect: isPerfect
        )
        if reward.totalXP == 0 && reward.totalDrops == 0 {
            // Already awarded previously.
            return nil
        }
        markTierCompleted(tier)
        return reward
    }
}
