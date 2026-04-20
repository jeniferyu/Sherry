import Foundation
import CoreData

enum DecorationType: String, CaseIterable {
    case tree       = "tree"
    case background = "background"
    case sky        = "sky"

    var displayName: String {
        switch self {
        case .tree:       return "Tree Decoration"
        case .background: return "Background"
        case .sky:        return "Sky Element"
        }
    }
}

extension Decoration {

    var decorationTypeEnum: DecorationType {
        DecorationType(rawValue: decorationType ?? "tree") ?? .tree
    }

    /// Whether this decoration is available for the given user level.
    /// Availability only gates purchase; actual unlock still requires
    /// spending `dropCost` via `DecorationService.purchase(_:)`.
    func isAvailable(atLevel level: Int) -> Bool {
        level >= Int(levelRequirement)
    }

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        type: DecorationType,
        levelRequirement: Int,
        dropCost: Int,
        unlockCondition: String? = nil
    ) -> Decoration {
        let decoration = Decoration(context: context)
        decoration.id = UUID()
        decoration.name = name
        decoration.decorationType = type.rawValue
        decoration.isUnlocked = false
        decoration.levelRequirement = Int16(levelRequirement)
        decoration.dropCost = Int16(dropCost)
        decoration.unlockCondition = unlockCondition
        return decoration
    }
}

extension Decoration: Identifiable {}
