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

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        type: DecorationType,
        unlockCondition: String? = nil
    ) -> Decoration {
        let decoration = Decoration(context: context)
        decoration.id = UUID()
        decoration.name = name
        decoration.decorationType = type.rawValue
        decoration.isUnlocked = false
        decoration.unlockCondition = unlockCondition
        return decoration
    }
}

extension Decoration: Identifiable {}
