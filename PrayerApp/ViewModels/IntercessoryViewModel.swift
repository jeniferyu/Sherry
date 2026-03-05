import Foundation
import Combine

enum IntercessoryTab: String, CaseIterable {
    case current = "Current"
    case history = "History"
}

final class IntercessoryViewModel: ObservableObject {

    // MARK: - Dependencies
    private let prayerService: PrayerService

    // MARK: - Published State
    @Published var activeItems: [PrayerItem] = []
    @Published var answeredItems: [PrayerItem] = []
    @Published var archivedItems: [PrayerItem] = []
    @Published var selectedTab: IntercessoryTab = .current
    @Published var searchText: String = ""
    @Published var selectedGroup: IntercessoryGroup? = nil

    // MARK: - Init
    init(prayerService: PrayerService = PrayerService()) {
        self.prayerService = prayerService
    }

    // MARK: - Fetch

    func fetchIntercessoryItems() {
        let allActive    = prayerService.fetchIntercessoryItems(status: .ongoing) +
                           prayerService.fetchIntercessoryItems(status: .prayed)
        let allAnswered  = prayerService.fetchIntercessoryItems(status: .answered)
        let allArchived  = prayerService.fetchIntercessoryItems(status: .archived)

        activeItems   = applySearch(allActive)
        answeredItems = applySearch(allAnswered)
        archivedItems = applySearch(allArchived)
    }

    private func applySearch(_ items: [PrayerItem]) -> [PrayerItem] {
        var result = items

        if let group = selectedGroup {
            result = result.filter { $0.intercessoryGroupEnum == group }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                ($0.title ?? "").lowercased().contains(q) ||
                ($0.content ?? "").lowercased().contains(q)
            }
        }

        return result
    }

    // MARK: - Actions

    func addToTodaySession(_ item: PrayerItem) {
        prayerService.updatePrayerStatus(item, status: .ongoing)
        fetchIntercessoryItems()
    }

    func markAnswered(_ item: PrayerItem) {
        prayerService.updatePrayerStatus(item, status: .answered)
        fetchIntercessoryItems()
    }

    func archiveItem(_ item: PrayerItem) {
        prayerService.updatePrayerStatus(item, status: .archived)
        fetchIntercessoryItems()
    }

    func filterByGroup(_ group: IntercessoryGroup?) {
        selectedGroup = (selectedGroup == group) ? nil : group
        fetchIntercessoryItems()
    }
}
