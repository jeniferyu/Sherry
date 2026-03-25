import Foundation
import CoreData

struct FilterCriteria {
    var statusFilter: PrayerStatus?
    var categoryFilter: PrayerCategory?
    var isIntercessory: Bool?
    var startDate: Date?
    var endDate: Date?
}

final class PrayerService: ObservableObject {

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - Create

    @discardableResult
    func createPrayer(
        title: String,
        content: String? = nil,
        category: PrayerCategory = .supplication,
        isIntercessory: Bool = false,
        intercessoryGroup: IntercessoryGroup? = nil,
        tags: [String] = []
    ) -> PrayerItem {
        let item = PrayerItem.create(
            in: context,
            title: title,
            content: content,
            category: category,
            isIntercessory: isIntercessory,
            intercessoryGroup: intercessoryGroup,
            tags: tags
        )
        persistence.save()
        return item
    }

    // MARK: - Fetch

    /// Returns non-archived personal prayer items created today, sorted newest first.
    func fetchTodayPrayers() -> [PrayerItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "isIntercessory == NO AND status != %@ AND createdDate >= %@ AND createdDate < %@",
            PrayerStatus.archived.rawValue,
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerItem.createdDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Returns personal (non-intercessory) prayer items created in the given calendar month.
    func fetchMonthPrayers(month: Date) -> [PrayerItem] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: comps),
              let end   = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }

        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "isIntercessory == NO AND createdDate >= %@ AND createdDate < %@",
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerItem.createdDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Returns intercessory items, optionally filtered by status.
    func fetchIntercessoryItems(status: PrayerStatus? = nil) -> [PrayerItem] {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        if let status {
            request.predicate = NSPredicate(
                format: "isIntercessory == YES AND status == %@", status.rawValue
            )
        } else {
            request.predicate = NSPredicate(format: "isIntercessory == YES")
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerItem.createdDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Full-text + filter search across all prayer items.
    func searchPrayers(query: String, filters: FilterCriteria = FilterCriteria()) -> [PrayerItem] {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()

        var predicates: [NSPredicate] = []

        if !query.isEmpty {
            let titlePred   = NSPredicate(format: "title CONTAINS[cd] %@", query)
            let contentPred = NSPredicate(format: "content CONTAINS[cd] %@", query)
            let tagPred     = NSPredicate(format: "tags CONTAINS[cd] %@", query)
            predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [titlePred, contentPred, tagPred]))
        }

        if let status = filters.statusFilter {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }
        if let category = filters.categoryFilter {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        if let isIntercessory = filters.isIntercessory {
            predicates.append(NSPredicate(format: "isIntercessory == %@", NSNumber(value: isIntercessory)))
        }
        if let start = filters.startDate {
            predicates.append(NSPredicate(format: "createdDate >= %@", start as CVarArg))
        }
        if let end = filters.endDate {
            predicates.append(NSPredicate(format: "createdDate <= %@", end as CVarArg))
        }

        request.predicate = predicates.isEmpty
            ? nil
            : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerItem.createdDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Update

    func updatePrayerStatus(_ prayer: PrayerItem, status: PrayerStatus) {
        prayer.statusEnum = status
        if status == .answered || status == .prayed {
            prayer.lastPrayedDate = Date()
        }
        persistence.save()
    }

    func incrementPrayedCount(_ prayer: PrayerItem) {
        prayer.prayedCount += 1
        prayer.lastPrayedDate = Date()
        // Automatically move to "prayed" if still ongoing
        if prayer.statusEnum == .ongoing {
            prayer.statusEnum = .prayed
        }
        persistence.save()
    }

    func updatePrayer(
        _ prayer: PrayerItem,
        title: String? = nil,
        content: String? = nil,
        category: PrayerCategory? = nil,
        tags: [String]? = nil
    ) {
        if let title    { prayer.title = title }
        if let content  { prayer.content = content }
        if let category { prayer.categoryEnum = category }
        if let tags     { prayer.tagList = tags }
        persistence.save()
    }

    // MARK: - Delete

    func deletePrayer(_ prayer: PrayerItem) {
        context.delete(prayer)
        persistence.save()
    }
}
