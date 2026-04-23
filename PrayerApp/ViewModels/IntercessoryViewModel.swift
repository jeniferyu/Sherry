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

    /// Set while `IntercessorySearchView` is presented so list refreshes go to the search fetch path.
    var intercessorySearchContextActive = false

    // Search screen only (cleared when leaving `IntercessorySearchView`):
    @Published var searchStatusFilter: PrayerStatus? = nil
    @Published var searchGroupFilter: IntercessoryGroup? = nil

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

    /// Intercession search: all groups + text + optional status, split into the same three buckets.
    func fetchIntercessorySearchItems() {
        let allActive = prayerService.fetchIntercessoryItems(status: .ongoing) +
            prayerService.fetchIntercessoryItems(status: .prayed)
        let allAnswered = prayerService.fetchIntercessoryItems(status: .answered)
        let allArchived = prayerService.fetchIntercessoryItems(status: .archived)

        activeItems = applyIntercessorySearchFilters(to: allActive)
        answeredItems = applyIntercessorySearchFilters(to: allAnswered)
        archivedItems = applyIntercessorySearchFilters(to: allArchived)
    }

    private func applyIntercessorySearchFilters(to items: [PrayerItem]) -> [PrayerItem] {
        var result = items

        if let group = searchGroupFilter {
            result = result.filter { $0.intercessoryGroupEnum == group }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                ($0.title ?? "").lowercased().contains(q) ||
                ($0.content ?? "").lowercased().contains(q)
            }
        }

        if let s = searchStatusFilter {
            result = result.filter { $0.statusEnum == s }
        }

        return result
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
        TodaySessionTracker.markAdded(item.id)
        refreshIntercessoryData()
    }

    func markAnswered(_ item: PrayerItem) {
        prayerService.updatePrayerStatus(item, status: .answered)
        refreshIntercessoryData()
    }

    func archiveItem(_ item: PrayerItem) {
        prayerService.updatePrayerStatus(item, status: .archived)
        refreshIntercessoryData()
    }

    func deleteItem(_ item: PrayerItem) {
        prayerService.deletePrayer(item)
        refreshIntercessoryData()
    }

    private func refreshIntercessoryData() {
        if intercessorySearchContextActive {
            fetchIntercessorySearchItems()
        } else {
            fetchIntercessoryItems()
        }
    }

    func filterByGroup(_ group: IntercessoryGroup?) {
        selectedGroup = (selectedGroup == group) ? nil : group
        fetchIntercessoryItems()
    }
}
