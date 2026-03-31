import Foundation
import CoreData

final class SessionService: ObservableObject {

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - Create

    @discardableResult
    func createSession(items: [PrayerItem], duration: Float = 0) -> PrayerSession {
        let session = PrayerSession.create(in: context, items: items, duration: duration)
        persistence.save()
        return session
    }

    // MARK: - Fetch

    /// Returns all sessions for a given calendar day.
    func fetchSessions(for date: Date) -> [PrayerSession] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end   = calendar.date(byAdding: .day, value: 1, to: start)!

        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerSession.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Returns all sessions for a given calendar month, sorted newest first.
    func fetchSessions(forMonth month: Date) -> [PrayerSession] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: comps),
              let end   = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }

        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerSession.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Returns all sessions for a given calendar year, sorted newest first.
    func fetchSessions(forYear year: Int) -> [PrayerSession] {
        var comps = DateComponents()
        comps.year = year
        comps.month = 1
        comps.day = 1
        let calendar = Calendar.current
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .year, value: 1, to: start) else { return [] }

        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            start as CVarArg, end as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PrayerSession.date, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Returns prayer items that belong to a specific session.
    func fetchPrayerItems(session: PrayerSession) -> [PrayerItem] {
        session.itemList
    }

    // MARK: - Mutate

    func addItemToSession(item: PrayerItem, session: PrayerSession) {
        session.addToItems(item)
        persistence.save()
    }

    func updateDuration(_ session: PrayerSession, duration: Float) {
        session.duration = duration
        persistence.save()
    }

    // MARK: - Stats

    func totalSessionCount() -> Int {
        let request: NSFetchRequest<PrayerSession> = PrayerSession.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
}
