import Foundation
import SwiftUI
import Combine

struct LeafData: Identifiable {
    let id: UUID
    let prayerItem: PrayerItem
    let position: CGPoint  // Normalized 0-1 position on tree canvas
    var isAnswered: Bool { prayerItem.statusEnum == .answered }
}

struct StarData: Identifiable {
    let id: UUID
    let prayerItem: PrayerItem
    let position: CGPoint
}

final class PrayerTreeViewModel: ObservableObject {

    // MARK: - Dependencies
    private let sessionService: SessionService
    private let gamificationService: GamificationService

    // MARK: - Published State
    @Published var leaves: [LeafData] = []
    @Published var stars: [StarData] = []
    @Published var selectedLeaf: LeafData? = nil
    @Published var selectedStar: StarData? = nil
    @Published var currentMonth: Date = Date()

    // MARK: - Init
    init(
        sessionService: SessionService = SessionService(),
        gamificationService: GamificationService = GamificationService()
    ) {
        self.sessionService = sessionService
        self.gamificationService = gamificationService
    }

    // MARK: - Fetch

    func fetchTreeData(for month: Date? = nil) {
        let target = month ?? currentMonth
        let sessions = sessionService.fetchSessions(forMonth: target)
        buildLeaves(from: sessions)
        buildStars(from: sessions)
    }

    private func buildLeaves(from sessions: [PrayerSession]) {
        // Each personal prayer item with prayedCount > 0 gets a leaf
        var seen = Set<NSManagedObjectID>()
        var result: [LeafData] = []

        for session in sessions {
            for item in session.personalItems where !seen.contains(item.objectID) {
                seen.insert(item.objectID)
                let position = randomLeafPosition(seed: item.objectID.hashValue)
                result.append(LeafData(id: item.id ?? UUID(), prayerItem: item, position: position))
            }
        }
        leaves = result
    }

    private func buildStars(from sessions: [PrayerSession]) {
        // Each intercessory prayer item gets a star
        var seen = Set<NSManagedObjectID>()
        var result: [StarData] = []

        for session in sessions {
            for item in session.intercessoryItems where !seen.contains(item.objectID) {
                seen.insert(item.objectID)
                let position = randomStarPosition(seed: item.objectID.hashValue)
                result.append(StarData(id: item.id ?? UUID(), prayerItem: item, position: position))
            }
        }
        stars = result
    }

    // Deterministic pseudo-random positions based on a seed
    private func randomLeafPosition(seed: Int) -> CGPoint {
        var rng = seededRNG(seed: seed)
        let x = 0.15 + rng.nextDouble() * 0.70
        let y = 0.10 + rng.nextDouble() * 0.60
        return CGPoint(x: x, y: y)
    }

    private func randomStarPosition(seed: Int) -> CGPoint {
        var rng = seededRNG(seed: seed &+ 12345)
        let x = rng.nextDouble()
        let y = rng.nextDouble() * 0.30
        return CGPoint(x: x, y: y)
    }

    // MARK: - Detail Actions

    func selectLeaf(_ leaf: LeafData) { selectedLeaf = leaf }
    func selectStar(_ star: StarData) { selectedStar = star }
    func clearSelection() { selectedLeaf = nil; selectedStar = nil }

    func getLeafDetail(leaf: LeafData) -> [PrayerItem] {
        sessionService
            .fetchSessions(forMonth: currentMonth)
            .filter { $0.personalItems.contains { $0.objectID == leaf.prayerItem.objectID } }
            .flatMap { $0.personalItems }
    }
}

// MARK: - Simple seeded RNG

private struct SeededRNG {
    var state: UInt64
    mutating func nextDouble() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 33) / Double(UInt64(1) << 31)
    }
}

private func seededRNG(seed: Int) -> SeededRNG {
    SeededRNG(state: UInt64(bitPattern: Int64(seed)))
}

import CoreData
