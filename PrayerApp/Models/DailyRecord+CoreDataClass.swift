import Foundation
import CoreData

@objc(DailyRecord)
public class DailyRecord: NSManagedObject {
    @NSManaged public var date: Date?
    @NSManaged public var hasFootprint: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var intercessoryItemCount: Int16
    @NSManaged public var personalSessionCount: Int16
    @NSManaged public var sessions: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyRecord> {
        return NSFetchRequest<DailyRecord>(entityName: "DailyRecord")
    }
}

// MARK: Generated accessors for sessions
extension DailyRecord {
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: PrayerSession)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: PrayerSession)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)
}
