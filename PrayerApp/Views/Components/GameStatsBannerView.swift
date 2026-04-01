import SwiftUI

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

            statItem(icon: "leaf.fill", color: .green, value: prayedItemCount)

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "sparkles", color: Color.appAnswered, value: intercessionPrayedCount)

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "drop.fill", color: Color(red: 0.40, green: 0.70, blue: 0.95), value: dropletCount)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Color(red: 0.22, green: 0.18, blue: 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(Color(red: 0.45, green: 0.38, blue: 0.28), lineWidth: 2)
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
    }

    private var avatarBadge: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: CGFloat(xpProgress))
                    .stroke(Color.appAnswered, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Image("sheep")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            }

            Text("Lv.\(level)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
    }

    private func statItem(icon: String, color: Color, value: Int) -> some View {
        HStack(spacing: 2.5) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .shadow(color: color.opacity(0.5), radius: 3)

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
