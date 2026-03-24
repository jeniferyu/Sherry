import Foundation
import Combine

// MARK: - Journey Data Models

enum JourneySeason: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"

    static func from(date: Date) -> JourneySeason {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5:  return .spring
        case 6...8:  return .summer
        case 9...11: return .autumn
        default:     return .winter
        }
    }

    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }
}

enum NodeState {
    case completed   // prayed that day, no answered items
    case answered    // at least one answered prayer that day
    case missed      // past day with no prayer record
    case today       // current calendar day
    case locked      // future day
}

struct JourneyNode: Identifiable {
    let id: UUID
    let dayNumber: Int      // 1-based index in the overall journey
    let date: Date
    let state: NodeState
    let record: DailyRecord?
}

struct JourneyZone: Identifiable {
    let id: UUID
    let season: JourneySeason
    var nodes: [JourneyNode]

    var name: String { season.displayName }
}

// MARK: - ViewModel

final class RoadMapViewModel: ObservableObject {

    // MARK: - Dependencies
    private let gamificationService: GamificationService
    private let sessionService: SessionService

    // MARK: - Published State
    @Published var zones: [JourneyZone] = []
    @Published var todayNodeID: UUID? = nil
    @Published var selectedDay: DailyRecord? = nil
    @Published var selectedDaySessions: [PrayerSession] = []
    @Published var streakCount: Int = 0
    @Published var totalSessionCount: Int = 0

    // MARK: - Init
    init(
        gamificationService: GamificationService = GamificationService(),
        sessionService: SessionService = SessionService()
    ) {
        self.gamificationService = gamificationService
        self.sessionService = sessionService
    }

    // MARK: - Fetch

    func fetchRecords() {
        let allRecords = gamificationService.fetchAllDailyRecords()
        streakCount = gamificationService.getStreakCount()
        totalSessionCount = gamificationService.getTotalSessionCount()
        zones = buildZones(from: allRecords)
        todayNodeID = zones.flatMap(\.nodes).first { $0.state == .today }?.id
    }

    func selectDay(_ record: DailyRecord) {
        selectedDay = record
        if let date = record.date {
            selectedDaySessions = sessionService.fetchSessions(for: date)
        }
    }

    func deselectDay() {
        selectedDay = nil
        selectedDaySessions = []
    }

    // MARK: - Journey Builder

    private func buildZones(from records: [DailyRecord]) -> [JourneyZone] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let startDate: Date
        if let earliest = records.compactMap(\.date).min() {
            startDate = calendar.startOfDay(for: earliest)
        } else {
            startDate = today
        }

        guard let endDate = calendar.date(byAdding: .day, value: 7, to: today) else {
            return []
        }

        let recordsByDay = Dictionary(uniqueKeysWithValues:
            records.compactMap { r -> (Date, DailyRecord)? in
                guard let d = r.date else { return nil }
                return (calendar.startOfDay(for: d), r)
            }
        )

        var nodes: [JourneyNode] = []
        var current = startDate
        var dayNumber = 1

        while current <= endDate {
            let record = recordsByDay[current]
            let state = nodeState(for: current, today: today, record: record)
            nodes.append(JourneyNode(
                id: UUID(),
                dayNumber: dayNumber,
                date: current,
                state: state,
                record: record
            ))
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? endDate.addingTimeInterval(86400)
            dayNumber += 1
        }

        return groupIntoZones(nodes: nodes)
    }

    private func nodeState(for date: Date, today: Date, record: DailyRecord?) -> NodeState {
        if date == today {
            return .today
        } else if date > today {
            return .locked
        } else if let record, record.hasFootprint {
            let hasAnswered = record.sessionList
                .flatMap(\.itemList)
                .contains { $0.statusEnum == .answered }
            return hasAnswered ? .answered : .completed
        } else {
            return .missed
        }
    }

    private func groupIntoZones(nodes: [JourneyNode]) -> [JourneyZone] {
        var zones: [JourneyZone] = []
        var currentSeason: JourneySeason? = nil
        var currentNodes: [JourneyNode] = []

        for node in nodes {
            let season = JourneySeason.from(date: node.date)
            if season != currentSeason {
                if !currentNodes.isEmpty, let cs = currentSeason {
                    zones.append(JourneyZone(id: UUID(), season: cs, nodes: currentNodes))
                }
                currentSeason = season
                currentNodes = [node]
            } else {
                currentNodes.append(node)
            }
        }

        if !currentNodes.isEmpty, let cs = currentSeason {
            zones.append(JourneyZone(id: UUID(), season: cs, nodes: currentNodes))
        }

        return zones
    }
}
