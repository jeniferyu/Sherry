import SwiftUI

// MARK: - Color Palette

extension Color {
    // Background tones (from wireframe: warm off-white/cream with soft pink tint)
    static let appBackground     = Color(red: 0.97, green: 0.95, blue: 0.94)
    static let appSurface        = Color(red: 0.99, green: 0.97, blue: 0.96)
    static let appSurfaceSecond  = Color(red: 0.93, green: 0.91, blue: 0.90)

    // Brand
    static let appPrimary        = Color(red: 0.45, green: 0.40, blue: 0.55)   // Muted purple
    static let appAccent         = Color(red: 0.80, green: 0.60, blue: 0.65)   // Dusty rose
    static let appTextPrimary    = Color(red: 0.20, green: 0.18, blue: 0.22)
    static let appTextSecondary  = Color(red: 0.55, green: 0.52, blue: 0.56)
    static let appTextTertiary   = Color(red: 0.75, green: 0.72, blue: 0.76)

    // Semantic
    static let appAnswered       = Color(red: 0.95, green: 0.80, blue: 0.30)   // Gold / star
    static let appOngoing        = Color(red: 0.55, green: 0.70, blue: 0.85)   // Soft blue
    static let appArchived       = Color(red: 0.70, green: 0.70, blue: 0.70)   // Neutral gray

    // ACTS category colors
    static let adorationColor    = Color(red: 0.90, green: 0.60, blue: 0.70)
    static let confessionColor   = Color(red: 0.75, green: 0.65, blue: 0.85)
    static let thanksgivingColor = Color(red: 0.60, green: 0.80, blue: 0.65)
    static let supplicationColor = Color(red: 0.65, green: 0.75, blue: 0.90)
}

// MARK: - Typography

struct AppFont {
    static func largeTitle()  -> Font { .system(size: 28, weight: .semibold, design: .rounded) }
    static func title()       -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func title2()      -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func headline()    -> Font { .system(size: 16, weight: .semibold, design: .rounded) }
    static func body()        -> Font { .system(size: 15, weight: .regular,  design: .rounded) }
    static func subheadline() -> Font { .system(size: 14, weight: .regular,  design: .rounded) }
    static func caption()     -> Font { .system(size: 12, weight: .regular,  design: .rounded) }
    static func caption2()    -> Font { .system(size: 11, weight: .regular,  design: .rounded) }
}

// MARK: - Spacing

struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

struct AppRadius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadow

struct AppShadow {
    static let cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        color: Color.black.opacity(0.06),
        radius: 8,
        x: 0,
        y: 2
    )
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .cornerRadius(AppRadius.lg)
            .shadow(
                color: AppShadow.cardShadow.color,
                radius: AppShadow.cardShadow.radius,
                x: AppShadow.cardShadow.x,
                y: AppShadow.cardShadow.y
            )
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appPrimary)
            .cornerRadius(AppRadius.lg)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundColor(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appSurfaceSecond)
            .cornerRadius(AppRadius.lg)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func primaryButtonStyle() -> some View {
        self.buttonStyle(AppPrimaryButtonStyle())
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(AppSecondaryButtonStyle())
    }
}
