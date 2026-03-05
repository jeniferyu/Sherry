import Foundation
import CoreData

@objc(PrayerItem)
public class PrayerItem: NSManagedObject {
    @NSManaged public var audioURL: String?
    @NSManaged public var category: String?
    @NSManaged public var content: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var intercessoryGroup: String?
    @NSManaged public var isIntercessory: Bool
    @NSManaged public var lastPrayedDate: Date?
    @NSManaged public var prayedCount: Int32
    @NSManaged public var status: String?
    @NSManaged public var tags: String?
    @NSManaged public var title: String?
    @NSManaged public var sessions: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PrayerItem> {
        return NSFetchRequest<PrayerItem>(entityName: "PrayerItem")
    }
}

// MARK: Generated accessors for sessions
extension PrayerItem {
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: PrayerSession)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: PrayerSession)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)
}
