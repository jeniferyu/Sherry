import Foundation
import CoreData

extension PrayerSession {

    // MARK: - Typed Accessors

    var itemList: [PrayerItem] {
        (items as? Set<PrayerItem>)?.sorted { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) } ?? []
    }

    var personalItems: [PrayerItem] {
        itemList.filter { !$0.isIntercessory }
    }

    var intercessoryItems: [PrayerItem] {
        itemList.filter { $0.isIntercessory }
    }

    var formattedDate: String {
        guard let d = date else { return "" }
        return DateFormatter.mediumDate.string(from: d)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    // MARK: - Convenience Init

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        items: [PrayerItem],
        duration: Float = 0
    ) -> PrayerSession {
        let session = PrayerSession(context: context)
        session.id = UUID()
        session.date = Date()
        session.duration = duration
        session.items = NSSet(array: items)
        return session
    }
}

extension PrayerSession: Identifiable {}
