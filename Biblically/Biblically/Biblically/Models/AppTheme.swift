import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case sepia = "sepia"
    case forest = "forest"
    case midnightBlue = "midnightBlue"

    var displayName: String {
        switch self {
        case .light:        return "Light"
        case .dark:         return "Dark"
        case .sepia:        return "Sepia"
        case .forest:       return "Forest"
        case .midnightBlue: return "Midnight Blue"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .light:        return Color.white
        case .dark:         return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .sepia:        return Color(red: 0.96, green: 0.93, blue: 0.84)
        case .forest:       return Color(red: 0.06, green: 0.16, blue: 0.08)
        case .midnightBlue: return Color(red: 0.05, green: 0.07, blue: 0.18)
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .light:        return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .dark:         return Color.white
        case .sepia:        return Color(red: 0.30, green: 0.20, blue: 0.08)
        case .forest:       return Color(red: 0.85, green: 0.95, blue: 0.85)
        case .midnightBlue: return Color(red: 0.85, green: 0.90, blue: 1.00)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .light:        return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .dark:         return Color(white: 0.65)
        case .sepia:        return Color(red: 0.55, green: 0.42, blue: 0.28)
        case .forest:       return Color(red: 0.55, green: 0.78, blue: 0.58)
        case .midnightBlue: return Color(red: 0.55, green: 0.68, blue: 0.90)
        }
    }

    var accentColor: Color {
        switch self {
        case .light:        return Color(red: 0.25, green: 0.45, blue: 0.85)
        case .dark:         return Color(red: 0.40, green: 0.60, blue: 1.00)
        case .sepia:        return Color(red: 0.65, green: 0.42, blue: 0.18)
        case .forest:       return Color(red: 0.30, green: 0.78, blue: 0.42)
        case .midnightBlue: return Color(red: 0.38, green: 0.58, blue: 0.92)
        }
    }

    /// A representative swatch pair for the theme picker UI
    var swatchColors: (background: Color, text: Color) {
        (backgroundColor, primaryTextColor)
    }
}
