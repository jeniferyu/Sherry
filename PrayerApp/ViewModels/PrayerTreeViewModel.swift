import Foundation
import SwiftUI
import Combine
import CoreData

struct StarData: Identifiable {
    let id: UUID
    let prayerItem: PrayerItem
    var position: CGPoint
}

final class PrayerTreeViewModel: ObservableObject {

    // MARK: - Dependencies
    private let sessionService: SessionService
    private let gamificationService: GamificationService

    // MARK: - Published State
    @Published var stars: [StarData] = []
    @Published var selectedStar: StarData? = nil
    @Published var yearSessionCount: Int = 0

    // Banner stats
    @Published var level: Int = 1
    @Published var xpProgress: Double = 0
    @Published var prayedItemCount: Int = 0
    @Published var intercessionPrayedCount: Int = 0
    @Published var dropletCount: Int = 0

    /// Approximate cap: 1 session per day for a full year
    let maxYearSessions: Int = 365

    var treeGrowthFraction: Double {
        min(1.0, Double(yearSessionCount) / Double(maxYearSessions))
    }

    // MARK: - Init
    init(
        sessionService: SessionService = SessionService(),
        gamificationService: GamificationService = GamificationService()
    ) {
        self.sessionService = sessionService
        self.gamificationService = gamificationService
    }

    // MARK: - Fetch

    func fetchTreeData() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let sessions = sessionService.fetchSessions(forYear: currentYear)

        yearSessionCount = sessions.count
        buildStars(from: sessions)

        level = gamificationService.calculateLevel()
        let currentXP = gamificationService.calculateXP()
        let nextLevelXP = gamificationService.xpForLevel(level + 1)
        let currentLevelBase = gamificationService.xpForLevel(level)
        let needed = max(nextLevelXP - currentLevelBase, 1)
        xpProgress = min(Double(currentXP - currentLevelBase) / Double(needed), 1.0)
        prayedItemCount = gamificationService.getPrayedItemCount()
        intercessionPrayedCount = gamificationService.getIntercessionPrayedCount()
        dropletCount = gamificationService.calculateDroplets()
    }

    private func buildStars(from sessions: [PrayerSession]) {
        var seen = Set<NSManagedObjectID>()
        var items: [(PrayerItem, Date)] = []

        for session in sessions {
            for item in session.intercessoryItems where !seen.contains(item.objectID) {
                seen.insert(item.objectID)
                let date = item.lastPrayedDate ?? item.createdDate ?? .distantPast
                items.append((item, date))
            }
        }

        items.sort { $0.1 > $1.1 }

        let count = items.count
        var result: [StarData] = []

        for (index, (item, _)) in items.enumerated() {
            let position = starPosition(index: index, total: count, seed: item.objectID.hashValue)
            result.append(StarData(
                id: item.id ?? UUID(),
                prayerItem: item,
                position: position
            ))
        }

        stars = result
    }

    /// Positions stars scattered across the sky band.
    /// Newer items (lower index) get higher positions (lower Y).
    /// X alternates left/right of center with a deterministic offset.
    private func starPosition(index: Int, total: Int, seed: Int) -> CGPoint {
        guard total > 0 else { return CGPoint(x: 0.5, y: 0.15) }

        let yPadding: Double = 0.05
        let yRange: Double = 0.90

        let y: Double
        if total == 1 {
            y = yPadding + yRange * 0.5
        } else {
            y = yPadding + yRange * Double(index) / Double(total - 1)
        }

        var rng = SeededRNG(state: UInt64(bitPattern: Int64(seed)))
        let jitter = rng.nextDouble() * 0.15

        let baseX: Double
        if index % 2 == 0 {
            baseX = 0.25 + jitter
        } else {
            baseX = 0.65 + jitter
        }

        let xClamped = min(0.92, max(0.08, baseX))

        return CGPoint(x: xClamped, y: y)
    }

    // MARK: - Selection

    func selectStar(_ star: StarData) { selectedStar = star }
    func clearSelection() { selectedStar = nil }
}

// MARK: - Simple seeded RNG

private struct SeededRNG {
    var state: UInt64
    mutating func nextDouble() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(UInt64(1) << 31)
    }
}
