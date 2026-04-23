import SwiftUI

enum PrayerCategory: String, CaseIterable, Codable {
    case adoration = "adoration"
    case confession = "confession"
    case thanksgiving = "thanksgiving"
    case supplication = "supplication"

    var displayName: String {
        switch self {
        case .adoration:    return "Adoration"
        case .confession:   return "Confession"
        case .thanksgiving: return "Thanksgiving"
        case .supplication: return "Supplication"
        }
    }

    var iconName: String {
        switch self {
        case .adoration:    return "heart.fill"
        case .confession:   return "exclamationmark.bubble.fill"
        case .thanksgiving: return "leaf.fill"
        case .supplication: return "prayingHands"
        }
    }

    /// True when `iconName` refers to an asset catalog image rather than an SF Symbol.
    var isAssetIcon: Bool {
        switch self {
        case .supplication: return true
        default:            return false
        }
    }

    var color: Color {
        switch self {
        case .adoration:    return Color("AdorationColor")
        case .confession:   return Color("ConfessionColor")
        case .thanksgiving: return Color("ThanksgivingColor")
        case .supplication: return Color("SupplicationColor")
        }
    }

    /// Vibrant card-ready color, used as the fill for game-style list cards.
    /// Mirrors the palette defined in `AppTheme.swift` so the whole UI stays
    /// in sync if those tokens are re-tuned.
    var fallbackColor: Color {
        switch self {
        case .adoration:    return .adorationColor
        case .confession:   return .confessionColor
        case .thanksgiving: return .thanksgivingColor
        case .supplication: return .supplicationColor
        }
    }
}
