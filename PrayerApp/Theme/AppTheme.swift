import CoreData
import SwiftUI

// MARK: - Color Palette

extension Color {
    // Background tones (game-style: pale mint cream, matches Challenge/Tree pages).
    static let appBackground     = Color(red: 0.94, green: 0.97, blue: 0.94)
    static let appSurface        = Color(red: 0.99, green: 1.00, blue: 0.99)
    static let appSurfaceSecond  = Color(red: 0.90, green: 0.95, blue: 0.91)

    // Brand — lavender from the header “+” gradient (~#A88BEB, top-leading stop) so
    // chips, buttons, and tab accents match that control.
    static let appPrimary        = Color(red: 168.0 / 255.0, green: 139.0 / 255.0, blue: 235.0 / 255.0)
    static let appAccent         = Color(red: 0.80, green: 0.60, blue: 0.65)   // Dusty rose
    static let appTextPrimary    = Color(red: 0.18, green: 0.18, blue: 0.22)
    static let appTextSecondary  = Color(red: 0.48, green: 0.48, blue: 0.54)
    static let appTextTertiary   = Color(red: 0.68, green: 0.68, blue: 0.72)

    // Semantic
    static let appAnswered       = Color(red: 0.98, green: 0.82, blue: 0.28)   // Gold / star
    static let appOngoing        = Color(red: 0.55, green: 0.70, blue: 0.85)   // Soft blue
    static let appArchived       = Color(red: 0.70, green: 0.70, blue: 0.70)   // Neutral gray

    // ACTS category colors (vibrant, card-ready)
    static let adorationColor    = Color(red: 0.97, green: 0.66, blue: 0.44)   // Coral / amber
    static let confessionColor   = Color(red: 0.68, green: 0.55, blue: 0.86)   // Soft violet
    static let thanksgivingColor = Color(red: 0.46, green: 0.78, blue: 0.58)   // Fresh mint
    static let supplicationColor = Color(red: 0.50, green: 0.72, blue: 0.93)   // Sky blue

    // Game-style tokens
    /// Dark chocolate/navy used by the stats banner, tab bar, and hero panels.
    static let appGameDark       = Color(red: 0.22, green: 0.18, blue: 0.13)
    /// Warm outline / stroke that pairs with `appGameDark`.
    static let appGameDarkStroke = Color(red: 0.45, green: 0.38, blue: 0.28)
    /// Gold used for XP/level/star pills.
    static let appGameGold       = Color(red: 0.98, green: 0.82, blue: 0.28)
    /// Purple used for XP progress fills.
    static let appGameXPFill     = Color(red: 0.56, green: 0.42, blue: 0.85)
    /// Soft surface used for chips and filter pills over the game background.
    static let appGameChipBg     = Color.white.opacity(0.80)
}

// MARK: - Typography

struct AppFont {
    static func largeTitle()  -> Font { .system(size: 28, weight: .bold,     design: .rounded) }
    static func title()       -> Font { .system(size: 22, weight: .bold,     design: .rounded) }
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
    static let xl:  CGFloat = 22
    static let xxl: CGFloat = 28
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

    /// Heavier shadow used beneath vibrant game-style cards so they "pop".
    static let gameCardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
        color: Color.black.opacity(0.14),
        radius: 12,
        x: 0,
        y: 6
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

/// Vibrant card background used across the game-style list rows and action cards.
/// Applies a soft top-to-bottom gradient for a little depth and a strong shadow.
struct GameCardModifier: ViewModifier {
    let baseColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        baseColor,
                        baseColor.opacity(0.88),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(AppRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(
                color: AppShadow.gameCardShadow.color,
                radius: AppShadow.gameCardShadow.radius,
                x: AppShadow.gameCardShadow.x,
                y: AppShadow.gameCardShadow.y
            )
    }
}

/// Dark rounded-rectangle surface used by the stats banner, tab bar, and
/// section headers — matches the visual language of the Challenge / Tree tabs.
struct GameDarkPanelModifier: ViewModifier {
    var radius: CGFloat = AppRadius.xl

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.appGameDark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.appGameDarkStroke, lineWidth: 2)
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
            .background(
                LinearGradient(
                    colors: [Color.appPrimary, Color.appPrimary.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(AppRadius.xl)
            .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, y: 4)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundColor(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.white)
            .cornerRadius(AppRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

/// Vibrant "play" style CTA — used for the bright green "Prayed" button in the session.
struct AppGameCTAButtonStyle: ButtonStyle {
    var color: Color = .thanksgivingColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(AppRadius.xxl)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.45), radius: 10, y: 5)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    /// Vibrant game-style card background. Pass the dominant category color.
    func gameCardStyle(color: Color) -> some View {
        modifier(GameCardModifier(baseColor: color))
    }

    /// Dark rounded-rectangle panel used by the tab bar and stats banner.
    func gameDarkPanel(radius: CGFloat = AppRadius.xl) -> some View {
        modifier(GameDarkPanelModifier(radius: radius))
    }

    func primaryButtonStyle() -> some View {
        self.buttonStyle(AppPrimaryButtonStyle())
    }

    func secondaryButtonStyle() -> some View {
        self.buttonStyle(AppSecondaryButtonStyle())
    }

    func gameCTAButtonStyle(color: Color = .thanksgivingColor) -> some View {
        self.buttonStyle(AppGameCTAButtonStyle(color: color))
    }
}

// MARK: - Game Filter Chips

/// Pill filter chip used by list filter bars and the search screen. Optional
/// `systemIcon` / `assetIconName` keep ACTS category assets (e.g. praying hands)
/// working alongside SF Symbols.
struct GameFilterChip: View {
    let label: String
    let tint: Color
    let isActive: Bool
    var systemIcon: String? = nil
    /// When set, shows a template asset catalog image instead of `systemIcon`.
    var assetIconName: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let assetIconName {
                    Image(assetIconName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                } else if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isActive ? .white : tint)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isActive ? tint : Color.white)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? Color.clear : tint.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: isActive ? tint.opacity(0.3) : .clear, radius: 5, y: 2)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Pill Badges

/// Compact gold pill used for "prayed N times" or "XP" style counts, inspired
/// by the Duolingo-style game UIs and the stats banner on the Challenge tab.
struct GoldCountPill: View {
    let icon: String
    let text: String
    var isSystemImage: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if isSystemImage {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
            } else {
                Image(icon)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(Color.appGameDark)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(Color.appGameGold)
        )
        .overlay(
            Capsule().strokeBorder(Color.appGameDark.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Navigation (plain Back, matches ACTS “Close”)

extension View {
    /// Hides the system blue back control; shows **‹** + label in `appPrimary` (no separate blue chevron).
    func navigationBarPlainBackButton(_ title: String = "Back") -> some View {
        modifier(PlainNavigationBackButtonModifier(title: title))
    }
}

private struct PlainNavigationBackButtonModifier: ViewModifier {
    let title: String
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text(title)
                                .font(.body)
                        }
                        .foregroundColor(Color.appPrimary)
                    }
                }
            }
    }
}

// MARK: - Delete prayer (Core Data) confirmation — game-style card

extension View {
    /// Presents a card-style confirmation before `PrayerItem` deletion. Pass `prayer.objectID` to trigger.
    func deletePrayerConfirmation(
        pendingID: Binding<NSManagedObjectID?>,
        onDelete: @escaping (PrayerItem) -> Void
    ) -> some View {
        modifier(DeletePrayerCardModifier(pendingID: pendingID, onDelete: onDelete))
    }
}

private struct DeletePrayerCardModifier: ViewModifier {
    @Binding var pendingID: NSManagedObjectID?
    let onDelete: (PrayerItem) -> Void

    func body(content: Content) -> some View {
        ZStack {
            content

            if pendingID != nil {
                DeletePrayerCardOverlay(
                    pendingID: $pendingID,
                    onDelete: onDelete
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(900)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: pendingID == nil)
    }
}

/// Full-screen dim + centered card; aligns with `CardModifier` / game pill buttons.
private struct DeletePrayerCardOverlay: View {
    @Binding var pendingID: NSManagedObjectID?
    let onDelete: (PrayerItem) -> Void
    @Environment(\.managedObjectContext) private var moc

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation { pendingID = nil }
                }

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.14))
                    Image(systemName: AppIcons.delete)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(Color.red.opacity(0.9))
                }
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.red.opacity(0.2), radius: 8, y: 3)

                Text("Delete this prayer?")
                    .font(AppFont.title2())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.appTextPrimary)

                Text("This can’t be undone. It will be removed from your lists and from session details.")
                    .font(AppFont.subheadline())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        if let id = pendingID,
                           let object = try? moc.existingObject(with: id) as? PrayerItem {
                            onDelete(object)
                        }
                        withAnimation { pendingID = nil }
                    } label: {
                        Label("Delete", systemImage: AppIcons.delete)
                            .labelStyle(.titleAndIcon)
                            .font(AppFont.headline())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color(red: 0.86, green: 0.28, blue: 0.34))
                    .cornerRadius(AppRadius.xl)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: Color.red.opacity(0.35), radius: 10, y: 4)
                    .buttonStyle(.plain)

                    Button {
                        withAnimation { pendingID = nil }
                    } label: {
                        Text("Cancel")
                    }
                    .secondaryButtonStyle()
                }
                .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(
                color: AppShadow.gameCardShadow.color,
                radius: 20,
                x: 0,
                y: 10
            )
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}
