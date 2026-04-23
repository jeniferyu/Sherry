import Foundation
import Combine

enum ListTab: String, CaseIterable {
    case today = "Today"
    case month = "Month"
}

final class PrayerListViewModel: ObservableObject {

    // MARK: - Dependencies
    private let prayerService: PrayerService

    // MARK: - Published State
    @Published var prayers: [PrayerItem] = []
    @Published var selectedTab: ListTab = .today
    @Published var statusFilter: PrayerStatus? = nil
    @Published var categoryFilter: PrayerCategory? = nil
    @Published var searchText: String = ""
    @Published var currentMonth: Date = Date()
    @Published var selectedPrayers: Set<NSManagedObjectID> = []
    @Published var isSelectMode: Bool = false
    var isSearchMode: Bool = false

    // MARK: - Init
    init(prayerService: PrayerService = PrayerService()) {
        self.prayerService = prayerService
    }

    // MARK: - Fetch

    func fetchPrayers() {
        switch selectedTab {
        case .today:
            prayers = applyFilters(to: prayerService.fetchTodayPrayers())
        case .month:
            prayers = applyFilters(to: prayerService.fetchMonthPrayers(month: currentMonth))
        }
    }

    private func applyFilters(to items: [PrayerItem]) -> [PrayerItem] {
        var result = items

        if let status = statusFilter {
            result = result.filter { $0.statusEnum == status }
        }

        if let category = categoryFilter {
            result = result.filter { $0.categoryEnum == category }
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

    // MARK: - Search (all prayers, no date scope)

    /// Loads personal (non-intercessory) prayers, filtered by optional text, status, and category.
    /// When everything is empty / "All", shows the full list—same idea as the Intercession search screen.
    func searchAllPrayers() {
        var filters = FilterCriteria()
        filters.statusFilter = statusFilter
        filters.categoryFilter = categoryFilter
        filters.isIntercessory = false
        prayers = prayerService.searchPrayers(query: searchText, filters: filters)
    }

    // MARK: - Filters

    func filterByStatus(_ status: PrayerStatus?) {
        statusFilter = (statusFilter == status) ? nil : status
        fetchPrayers()
    }

    func filterByCategory(_ category: PrayerCategory?) {
        categoryFilter = (categoryFilter == category) ? nil : category
        fetchPrayers()
    }

    func clearFilters() {
        statusFilter = nil
        categoryFilter = nil
        searchText = ""
        fetchPrayers()
    }

    // MARK: - Status Actions

    func updateStatus(_ prayer: PrayerItem, status: PrayerStatus) {
        prayerService.updatePrayerStatus(prayer, status: status)
        isSearchMode ? searchAllPrayers() : fetchPrayers()
    }

    func addPersonalPrayerToToday(_ prayer: PrayerItem) {
        prayerService.addPersonalPrayerToToday(prayer)
        isSearchMode ? searchAllPrayers() : fetchPrayers()
    }

    func deletePrayer(_ prayer: PrayerItem) {
        prayerService.deletePrayer(prayer)
        selectedPrayers.remove(prayer.objectID)
        isSearchMode ? searchAllPrayers() : fetchPrayers()
    }

    // MARK: - Selection

    func toggleSelection(for prayer: PrayerItem) {
        if selectedPrayers.contains(prayer.objectID) {
            selectedPrayers.remove(prayer.objectID)
        } else {
            selectedPrayers.insert(prayer.objectID)
        }
    }

    func selectedItems() -> [PrayerItem] {
        prayers.filter { selectedPrayers.contains($0.objectID) }
    }

    func clearSelection() {
        selectedPrayers.removeAll()
        isSelectMode = false
    }
}

// Forward CoreData import
import CoreData
