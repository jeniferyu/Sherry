import Foundation
import CoreData

@objc(PrayerSession)
public class PrayerSession: NSManagedObject {
    @NSManaged public var date: Date?
    @NSManaged public var duration: Float
    @NSManaged public var id: UUID?
    @NSManaged public var dailyRecord: DailyRecord?
    @NSManaged public var items: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PrayerSession> {
        return NSFetchRequest<PrayerSession>(entityName: "PrayerSession")
    }
}

// MARK: Generated accessors for items
extension PrayerSession {
    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: PrayerItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: PrayerItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)
}
