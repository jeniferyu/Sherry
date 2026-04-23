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
    /// Also includes non-intercessory items explicitly queued for today via
    /// `addPersonalPrayerToToday` (from any `Prayed` / `Archived` / `Ongoing` source date).
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
        let createdToday = (try? context.fetch(request)) ?? []

        let queued = fetchPersonalPrayersQueued(
            ids: PersonalTodayQueueTracker.queuedIdUUIDsAfterRevertingStale(using: self)
        )
        let merged = mergePrayerItems(createdToday, queued)
        return merged
    }

    /// Puts a **personal** prayer on the Today list: status becomes `ongoing` (Unprayed), `prayedCount` unchanged.
    /// Stashes the previous status; if the day ends while still `ongoing`, that status is restored
    /// (see `PersonalTodayQueueTracker.processExpiredReverts`).
    func addPersonalPrayerToToday(_ prayer: PrayerItem) {
        guard !prayer.isIntercessory, prayer.statusEnum != .answered else { return }
        if PersonalTodayQueueTracker.isPersonalItemOnTodayList(prayer) { return }
        let previous = prayer.statusEnum
        prayer.statusEnum = .ongoing
        if let id = prayer.id {
            PersonalTodayQueueTracker.mark(id, previousStatus: previous)
        }
        persistence.save()
    }

    func prayerItem(withId id: UUID) -> PrayerItem? {
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    fileprivate func fetchPersonalPrayersQueued(ids: [UUID]) -> [PrayerItem] {
        guard !ids.isEmpty else { return [] }
        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "isIntercessory == NO AND id IN %@",
            NSSet(array: ids)
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerItem.createdDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    fileprivate func mergePrayerItems(_ a: [PrayerItem], _ b: [PrayerItem]) -> [PrayerItem] {
        var seen = Set<NSManagedObjectID>()
        var out: [PrayerItem] = []
        for item in a + b where !seen.contains(item.objectID) {
            seen.insert(item.objectID)
            out.append(item)
        }
        return out.sorted { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
    }

    fileprivate func applyQueuedStatusRevert(_ prayer: PrayerItem, to status: PrayerStatus) {
        prayer.statusEnum = status
        persistence.save()
    }

    /// Returns personal (non-intercessory) prayer items created in the given calendar month.
    /// Archived items are excluded (Month list); use `searchPrayers` to find them in Search.
    func fetchMonthPrayers(month: Date) -> [PrayerItem] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: comps),
              let end   = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }

        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "isIntercessory == NO AND status != %@ AND createdDate >= %@ AND createdDate < %@",
            PrayerStatus.archived.rawValue,
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerItem.createdDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Intercessory prayers the user explicitly added to today's session.
    /// Filtering by today happens in `TodaySessionTracker`, which automatically drops
    /// stale entries (yesterday or earlier) so the items reappear as addable again.
    func fetchIntercessoryItemsAddedToday() -> [PrayerItem] {
        let ids = TodaySessionTracker.addedIDsToday()
        guard !ids.isEmpty else { return [] }

        let request: NSFetchRequest<PrayerItem> = PrayerItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "isIntercessory == YES AND status != %@ AND id IN %@",
            PrayerStatus.archived.rawValue,
            NSSet(array: Array(ids))
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
        if status != .ongoing, let id = prayer.id, !prayer.isIntercessory {
            PersonalTodayQueueTracker.remove(id)
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
        if let id = prayer.id, !prayer.isIntercessory {
            PersonalTodayQueueTracker.remove(id)
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
        if let id = prayer.id {
            if prayer.isIntercessory {
                TodaySessionTracker.remove(id)
            } else {
                PersonalTodayQueueTracker.remove(id)
            }
        }
        context.delete(prayer)
        persistence.save()
    }
}

// MARK: - Personal prayer → Today list queue
//
// When a personal prayer (non-intercessory) is added to Today, we set status to `ongoing`
// and record the previous status. If the new day begins while the item is still `ongoing` and
// the user has not actually prayed in session, we restore the previous status (often `prayed` or
// `archived`); if they have prayed, `incrementPrayedCount` / `updatePrayerStatus` already cleared the entry.
enum PersonalTodayQueueTracker {
    private static let key = "personalPrayerTodayQueue.v1"

    private static var calendar: Calendar { Calendar.current }

    private static func startOfDay(_ d: Date) -> Date { calendar.startOfDay(for: d) }

    private static func load() -> [String: String] {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: String]) ?? [:]
    }

    private static func save(_ dict: [String: String]) {
        UserDefaults.standard.set(dict, forKey: key)
    }

    private static func parse(_ raw: String) -> (queueDay: Date, previous: PrayerStatus)? {
        let parts = raw.split(separator: "|", maxSplits: 1).map { String($0) }
        guard parts.count == 2,
              let time = TimeInterval(parts[0]),
              let prev = PrayerStatus(rawValue: parts[1]) else { return nil }
        return (Date(timeIntervalSince1970: time), prev)
    }

    static func mark(_ id: UUID, previousStatus: PrayerStatus) {
        var d = load()
        let t = startOfDay(Date()).timeIntervalSince1970
        d[id.uuidString] = "\(t)|\(previousStatus.rawValue)"
        save(d)
    }

    static func remove(_ id: UUID) {
        var d = load()
        d.removeValue(forKey: id.uuidString)
        save(d)
    }

    /// `true` if this personal prayer is already on the Today tab (created today, or explicit queue for today).
    static func isPersonalItemOnTodayList(_ item: PrayerItem) -> Bool {
        guard !item.isIntercessory, item.id != nil else { return false }
        if let created = item.createdDate, calendar.isDateInToday(created) { return true }
        if let id = item.id, let raw = load()[id.uuidString], let (qDay, _) = parse(raw) {
            if calendar.isDateInToday(qDay) { return true }
        }
        return false
    }

    static func queuedIdUUIDsAfterRevertingStale(using service: PrayerService) -> [UUID] {
        processExpiredReverts(using: service)
        return load().keys.compactMap { UUID(uuidString: $0) }
    }

    fileprivate static func processExpiredReverts(using service: PrayerService) {
        var d = load()
        let startOfNow = startOfDay(Date())
        for k in Array(d.keys) {
            guard let v = d[k], let (qStart, previous) = parse(v) else {
                d.removeValue(forKey: k)
                continue
            }
            if startOfDay(qStart) < startOfNow, let id = UUID(uuidString: k), let p = service.prayerItem(withId: id) {
                if p.statusEnum == .ongoing, !p.isIntercessory {
                    service.applyQueuedStatusRevert(p, to: previous)
                }
                d.removeValue(forKey: k)
            }
        }
        save(d)
    }
}

// MARK: - Intercession → "Today's Session" tracker
//
// Persists (in `UserDefaults`) which intercessory items the user explicitly added
// to today's prayer session. Entries are filtered to today's date on every read,
// so once the calendar day rolls over an item becomes addable again and stops
// appearing in `fetchIntercessoryItemsAddedToday()` / the review toggle.
enum TodaySessionTracker {
    private static let storageKey = "intercessoryAddedToTodaySession.v1"
    private static let isoFormatter = ISO8601DateFormatter()

    /// Marks an intercessory item as added to today's session.
    static func markAdded(_ id: UUID?) {
        guard let id else { return }
        var dict = prunedStorage()
        dict[id.uuidString] = isoFormatter.string(from: Date())
        UserDefaults.standard.set(dict, forKey: storageKey)
    }

    /// `true` when the given item id was added to today's session (and the day hasn't rolled over).
    static func isAddedToday(_ id: UUID?) -> Bool {
        guard let id else { return false }
        return addedIDsToday().contains(id)
    }

    /// Ids that are currently "added today". Callers typically pass these into a Core Data fetch.
    static func addedIDsToday() -> Set<UUID> {
        var ids = Set<UUID>()
        for (key, _) in prunedStorage() {
            if let uuid = UUID(uuidString: key) {
                ids.insert(uuid)
            }
        }
        return ids
    }

    /// Reads storage and removes any stale entries (not from today). Writes back if pruning happened.
    static func remove(_ id: UUID) {
        var dict = prunedStorage()
        dict.removeValue(forKey: id.uuidString)
        UserDefaults.standard.set(dict, forKey: storageKey)
    }

    @discardableResult
    private static func prunedStorage() -> [String: String] {
        let raw = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] ?? [:]
        let calendar = Calendar.current
        var pruned: [String: String] = [:]
        for (key, dateStr) in raw {
            guard let date = isoFormatter.date(from: dateStr),
                  calendar.isDateInToday(date) else { continue }
            pruned[key] = dateStr
        }
        if pruned.count != raw.count {
            UserDefaults.standard.set(pruned, forKey: storageKey)
        }
        return pruned
    }
}
