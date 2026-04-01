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
}

// MARK: - ViewModel

final class RoadMapViewModel: ObservableObject {

    private let gamificationService: GamificationService
    private let sessionService: SessionService

    @Published var challenge: PrayerChallenge = PrayerChallenge(
        totalDays: 3, title: "3-Day Prayer Challenge", days: []
    )
    @Published var streakCount: Int = 0

    // Banner stats
    @Published var level: Int = 1
    @Published var currentXP: Int = 0
    @Published var nextLevelXP: Int = 20
    @Published var xpProgress: Double = 0
    @Published var prayedItemCount: Int = 0
    @Published var intercessionPrayedCount: Int = 0
    @Published var dropletCount: Int = 0

    init(
        gamificationService: GamificationService = GamificationService(),
        sessionService: SessionService = SessionService()
    ) {
        self.gamificationService = gamificationService
        self.sessionService = sessionService
    }

    func fetchRecords() {
        streakCount = gamificationService.getStreakCount()
        challenge = buildChallenge(totalDays: 3)

        level = gamificationService.calculateLevel()
        currentXP = gamificationService.calculateXP()
        nextLevelXP = gamificationService.xpForLevel(level + 1)
        let currentLevelBase = gamificationService.xpForLevel(level)
        let needed = max(nextLevelXP - currentLevelBase, 1)
        xpProgress = min(Double(currentXP - currentLevelBase) / Double(needed), 1.0)
        prayedItemCount = gamificationService.getPrayedItemCount()
        intercessionPrayedCount = gamificationService.getIntercessionPrayedCount()
        dropletCount = gamificationService.calculateDroplets()
    }

    private func buildChallenge(totalDays: Int) -> PrayerChallenge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let startDate = challengeStartDate(streak: streakCount, totalDays: totalDays, today: today)

        // Pre-fetch DailyRecords covering the challenge window
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

    /// Determines the start date of the current challenge window.
    /// streak=0 or 1 → today is day 1 (fresh start or just started today).
    /// streak=2 → yesterday is day 1, today is day 2.
    /// streak>=totalDays → challenge is fully covered ending today.
    private func challengeStartDate(streak: Int, totalDays: Int, today: Date) -> Date {
        let calendar = Calendar.current
        let offset = min(max(streak - 1, 0), totalDays - 1)
        return calendar.date(byAdding: .day, value: -offset, to: today) ?? today
    }

    /// Star rating for a day's sessions:
    /// 1 star = at least one completed session
    /// 2 stars = full ACTS (items covering all 4 categories)
    /// 3 stars = full ACTS + at least one intercession item prayed
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
}
