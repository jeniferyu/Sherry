import Foundation
import CoreData

final class GamificationService: ObservableObject {

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - Daily Activity Recording

    /// Call this after a session is finished to update the DailyRecord and check unlocks.
    @discardableResult
    func recordDailyActivity(date: Date = Date(), session: PrayerSession) -> DailyRecord {
        let record = DailyRecord.findOrCreate(for: date, in: context)
        record.personalSessionCount += 1
        record.hasFootprint = true

        // Count intercessory items in this session
        let intercessoryCount = Int16(session.intercessoryItems.count)
        record.intercessoryItemCount += intercessoryCount

        // Link session to record
        session.dailyRecord = record

        persistence.save()
        return record
    }

    // MARK: - Fetch

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

    /// Returns all DailyRecords sorted by date ascending, for use by the journey map.
    func fetchAllDailyRecords() -> [DailyRecord] {
        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyRecord.date, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Streak

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

    // MARK: - Prayer Counts

    /// Personal prayer items that have been prayed at least once.
    func getPrayedItemCount() -> Int {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(format: "isIntercessory == NO AND prayedCount > 0")
        return (try? context.count(for: request)) ?? 0
    }

    /// Intercession items that have been prayed at least once.
    func getIntercessionPrayedCount() -> Int {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(format: "isIntercessory == YES AND prayedCount > 0")
        return (try? context.count(for: request)) ?? 0
    }

    /// Total prayer duration across all sessions, in seconds.
    func getTotalPrayerDuration() -> Float {
        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        guard let sessions = try? context.fetch(request) else { return 0 }
        return sessions.reduce(0) { $0 + $1.duration }
    }

    /// Total days with hasFootprint (days the user actually prayed).
    func getTotalPrayerDays() -> Int {
        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.predicate = NSPredicate(format: "hasFootprint == YES")
        return (try? context.count(for: request)) ?? 0
    }

    // MARK: - Level Calculation

    /// XP is earned from sessions, streaks, and answered prayers.
    /// Level grows progressively: Level = floor(sqrt(XP / 20)) + 1
    ///
    /// XP sources:
    ///   - Each completed session:   10 XP
    ///   - Current streak day bonus: 5 XP per streak day (e.g. 7-day streak = 35 XP)
    ///   - Each answered prayer:     25 XP
    func calculateXP() -> Int {
        let sessions = getTotalSessionCount()
        let streak = getStreakCount()
        let answered = getTotalAnsweredCount()
        return sessions * 10 + streak * 5 + answered * 25
    }

    func calculateLevel() -> Int {
        let xp = calculateXP()
        return max(1, Int(sqrt(Double(xp) / 20.0)) + 1)
    }

    /// XP needed to reach the next level.
    func xpForLevel(_ level: Int) -> Int {
        let l = max(level - 1, 0)
        return l * l * 20
    }

    // MARK: - Droplet Calculation

    /// Droplets accumulate from prayer activity:
    ///   - Each prayer day:         10 base droplets
    ///   - Consecutive day bonus:   streak * (streak + 1) / 2  (triangular: 1+2+3+...)
    ///   - Prayer duration:         1 droplet per 30 seconds
    ///   - Answered prayers:        5 droplets each
    func calculateDroplets() -> Int {
        let prayerDays = getTotalPrayerDays()
        let streak = getStreakCount()
        let duration = getTotalPrayerDuration()
        let answered = getTotalAnsweredCount()

        let baseDrop = prayerDays * 10
        let streakBonus = streak * (streak + 1) / 2
        let durationBonus = Int(duration / 30.0)
        let answeredBonus = answered * 5

        return baseDrop + streakBonus + durationBonus + answeredBonus
    }

    // MARK: - Decoration Unlocks

    @discardableResult
    func checkUnlockConditions() -> [Decoration] {
        var newlyUnlocked: [Decoration] = []

        let streak      = getStreakCount()
        let totalCount  = getTotalSessionCount()
        let answered    = getTotalAnsweredCount()

        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        request.predicate = NSPredicate(format: "isUnlocked == NO")
        guard let locked = try? context.fetch(request) else { return [] }

        for decoration in locked {
            guard let condition = decoration.unlockCondition else { continue }
            var shouldUnlock = false

            switch condition {
            case "streak_3":   shouldUnlock = streak >= 3
            case "streak_7":   shouldUnlock = streak >= 7
            case "streak_30":  shouldUnlock = streak >= 30
            case "sessions_5": shouldUnlock = totalCount >= 5
            case "sessions_10": shouldUnlock = totalCount >= 10
            case "sessions_50": shouldUnlock = totalCount >= 50
            case "answered_1":  shouldUnlock = answered >= 1
            case "answered_5":  shouldUnlock = answered >= 5
            default: break
            }

            if shouldUnlock {
                decoration.isUnlocked = true
                decoration.unlockedDate = Date()
                newlyUnlocked.append(decoration)
            }
        }

        if !newlyUnlocked.isEmpty {
            persistence.save()
        }

        return newlyUnlocked
    }
}
