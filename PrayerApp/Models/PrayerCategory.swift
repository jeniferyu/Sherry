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

    var shortName: String {
        switch self {
        case .adoration:    return "A"
        case .confession:   return "C"
        case .thanksgiving: return "T"
        case .supplication: return "S"
        }
    }

    var iconName: String {
        switch self {
        case .adoration:    return "heart.fill"
        case .confession:   return "exclamationmark.bubble.fill"
        case .thanksgiving: return "leaf.fill"
        case .supplication: return "hands.sparkles.fill"
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

    var fallbackColor: Color {
        switch self {
        case .adoration:    return Color(red: 0.90, green: 0.60, blue: 0.70)
        case .confession:   return Color(red: 0.75, green: 0.65, blue: 0.85)
        case .thanksgiving: return Color(red: 0.60, green: 0.80, blue: 0.65)
        case .supplication: return Color(red: 0.65, green: 0.75, blue: 0.90)
        }
    }
}
