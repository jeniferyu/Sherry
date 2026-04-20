import SwiftUI

enum PrayerStatus: String, CaseIterable, Codable {
    case ongoing  = "ongoing"
    case prayed   = "prayed"
    case answered = "answered"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .ongoing:  return "Unprayed"
        case .prayed:   return "Prayed"
        case .answered: return "Answered"
        case .archived: return "Archived"
        }
    }

    var iconName: String {
        switch self {
        case .ongoing:  return "clock.fill"
        case .prayed:   return "checkmark.circle.fill"
        case .answered: return "sparkles"
        case .archived: return "archivebox.fill"
        }
    }

    var color: Color {
        switch self {
        case .ongoing:  return .orange
        case .prayed:   return .blue
        case .answered: return .yellow
        case .archived: return .gray
        }
    }

    /// Returns true when the item should appear in the active Today list
    var isActive: Bool {
        self == .ongoing || self == .prayed
    }
}
