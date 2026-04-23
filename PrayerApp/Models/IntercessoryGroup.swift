import SwiftUI

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

    /// Vibrant card-ready accent color, used as the background of game-style
    /// intercession rows and filter chips.
    var accentColor: Color {
        switch self {
        case .family:    return Color(red: 0.97, green: 0.66, blue: 0.44)   // Warm coral
        case .friends:   return Color(red: 0.50, green: 0.72, blue: 0.93)   // Sky blue
        case .church:    return Color(red: 0.68, green: 0.55, blue: 0.86)   // Violet
        case .community: return Color(red: 0.46, green: 0.78, blue: 0.58)   // Mint
        case .other:     return Color(red: 0.80, green: 0.60, blue: 0.65)   // Dusty rose
        }
    }
}
