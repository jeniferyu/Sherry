import SwiftUI

/// Top stats strip on Challenge / Tree — uses the same dark panel + stroke tokens as
/// `gameDarkPanel`, with colorful stat glyphs like the rest of the game UI.
struct GameStatsBannerView: View {
    let level: Int
    let xpProgress: Double
    let prayedItemCount: Int
    let intercessionPrayedCount: Int
    let dropletCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            avatarBadge

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "leaf.fill", color: .thanksgivingColor, value: prayedItemCount)

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "sparkles", color: Color.appAnswered, value: intercessionPrayedCount)

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "drop.fill", color: Color.supplicationColor, value: dropletCount)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appGameDark.opacity(0.88),
                            Color.appGameDark,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .strokeBorder(Color.appGameDarkStroke, lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.04),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
    }

    private var avatarBadge: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: CGFloat(xpProgress))
                    .stroke(Color.appGameGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: xpProgress)

                Image("sheep")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            }

            Text("Lv.\(level)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
    }

    private func statItem(icon: String, color: Color, value: Int) -> some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.45), radius: 3, y: 1)
            }

            Text(formattedStat(value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(minWidth: 44)
    }

    private func formattedStat(_ value: Int) -> String {
        if value >= 10_000 { return String(format: "%.1fk", Double(value) / 1000.0) }
        return "\(value)"
    }
}
