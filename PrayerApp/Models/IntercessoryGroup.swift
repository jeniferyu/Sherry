import Foundation

enum IntercessoryGroup: String, CaseIterable, Codable {
    case family    = "family"
    case friends   = "friends"
    case church    = "church"
    case community = "community"
    case other     = "other"

    var displayName: String {
        switch self {
        case .family:    return "Family"
        case .friends:   return "Friends"
        case .church:    return "Church"
        case .community: return "Community"
        case .other:     return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .family:    return "house.fill"
        case .friends:   return "person.2.fill"
        case .church:    return "building.columns.fill"
        case .community: return "globe.americas.fill"
        case .other:     return "ellipsis.circle.fill"
        }
    }
}
