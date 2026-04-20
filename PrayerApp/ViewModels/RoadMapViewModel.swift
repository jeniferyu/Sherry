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
    @Published var nextLevelXP: Int = 20
    @Published var xpProgress: Double = 0
    @Published var prayedItemCount: Int = 0
    @Published var intercessionPrayedCount: Int = 0
    @Published var dropletCount: Int = 0

    // Progress summary
    @Published var totalChallengesCompleted: Int = 0
    @Published var totalStarsEarned: Int = 0
    @Published var totalPrayerDays: Int = 0

    init(
        gamificationService: GamificationService = GamificationService(),
        sessionService: SessionService = SessionService()
    ) {
        self.gamificationService = gamificationService
        self.sessionService = sessionService
        self.activeTierDays = Self.loadActiveTier()
    }

    func fetchRecords() {
        streakCount = gamificationService.getStreakCount()

        var completed = Self.loadCompletedTiers()
        activeTierDays = Self.loadActiveTier()
        challenge = buildChallenge(totalDays: activeTierDays)

        // Auto-mark completion: if the active challenge is fully done, persist it
        if challenge.isFullyCompleted && !completed.contains(activeTierDays) {
            Self.markTierCompleted(activeTierDays)
            completed = Self.loadCompletedTiers()
        }

        currentChallengeInProgress = !challenge.isFullyCompleted
        challengeTiers = buildTiers(completedTiers: completed, challengeInProgress: currentChallengeInProgress)

        level = gamificationService.calculateLevel()
        currentXP = gamificationService.calculateXP()
        nextLevelXP = gamificationService.xpForLevel(level + 1)
        let currentLevelBase = gamificationService.xpForLevel(level)
        let needed = max(nextLevelXP - currentLevelBase, 1)
        xpProgress = min(Double(currentXP - currentLevelBase) / Double(needed), 1.0)
        prayedItemCount = gamificationService.getPrayedItemCount()
        intercessionPrayedCount = gamificationService.getIntercessionPrayedCount()
        dropletCount = gamificationService.calculateDroplets()

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

    func selectChallenge(_ tier: Int) {
        // Temporary testing only: skip unlock guard when `unlockAllChallengeTiersForTesting` is true.
        if !Self.unlockAllChallengeTiersForTesting {
            guard challengeTiers.first(where: { $0.totalDays == tier })?.isUnlocked == true else { return }
        }
        Self.saveActiveTier(tier)
        activeTierDays = tier
        fetchRecords()
    }

    // MARK: - Scroll Focus

    /// Index for map scroll and the “current step” arrow: first day not yet completed.
    /// When every day is done, points at the last day.
    var focusDayIndex: Int {
        let days = challenge.days
        guard !days.isEmpty else { return 0 }
        if let i = days.firstIndex(where: { !$0.isCompleted }) { return i }
        return days.count - 1
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

            // Temporary testing only: replace normal unlock rules with “all unlocked.” Revert by deleting this branch and restoring the `if challengeInProgress { … }` chain below.
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
}
