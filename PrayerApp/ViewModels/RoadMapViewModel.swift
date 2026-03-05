import Foundation
import Combine

final class RoadMapViewModel: ObservableObject {

    // MARK: - Dependencies
    private let gamificationService: GamificationService
    private let sessionService: SessionService

    // MARK: - Published State
    @Published var dailyRecords: [DailyRecord] = []
    @Published var currentMonth: Date = Date()
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

    func fetchRecords(for month: Date? = nil) {
        let target = month ?? currentMonth
        dailyRecords = gamificationService.fetchDailyRecords(month: target)
        streakCount = gamificationService.getStreakCount()
        totalSessionCount = gamificationService.getTotalSessionCount()
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

    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        fetchRecords()
    }

    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        fetchRecords()
    }

    // MARK: - Helpers

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    /// Returns a grid of (day number, DailyRecord?) for the current month, padded by weekday offset.
    var calendarGrid: [(Int, DailyRecord?)] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDay = calendar.date(from: comps) else { return [] }

        let weekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let range = calendar.range(of: .day, in: .month, for: firstDay)!
        let dayCount = range.count

        var grid: [(Int, DailyRecord?)] = []

        // Padding
        for _ in 0..<weekdayOffset { grid.append((0, nil)) }

        // Days
        for day in 1...dayCount {
            var comps2 = comps
            comps2.day = day
            if let date = calendar.date(from: comps2) {
                let record = dailyRecords.first { r in
                    guard let rd = r.date else { return false }
                    return calendar.isDate(rd, inSameDayAs: date)
                }
                grid.append((day, record))
            }
        }

        return grid
    }
}
