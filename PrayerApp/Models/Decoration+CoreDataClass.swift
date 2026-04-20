import Foundation
import CoreData

@objc(Decoration)
public class Decoration: NSManagedObject {
    @NSManaged public var decorationType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isUnlocked: Bool
    @NSManaged public var levelRequirement: Int16
    @NSManaged public var dropCost: Int16
    @NSManaged public var name: String?
    @NSManaged public var unlockCondition: String?
    @NSManaged public var unlockedDate: Date?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Decoration> {
        return NSFetchRequest<Decoration>(entityName: "Decoration")
    }
}
