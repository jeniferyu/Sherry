import SwiftUI

/// Game-style list row for personal prayers. The card is filled with the prayer's
/// ACTS category color (coral / violet / mint / sky) and uses white content on top
/// so the whole screen reads as a stack of vibrant quest cards — intentionally
/// aligned with the Challenge and Tree tabs.
struct PrayerCardView: View {
    @ObservedObject var prayer: PrayerItem
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            categoryAvatar

            VStack(alignment: .leading, spacing: 6) {
                Text(prayer.title ?? "")
                    .font(AppFont.headline())
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let content = prayer.content, !content.isEmpty {
                    Text(content)
                        .font(AppFont.caption())
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    statusChip
                    GoldCountPill(
                        icon: AppIcons.star,
                        text: "\(prayer.prayedCount)"
                    )
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .gameCardStyle(color: prayer.categoryEnum.fallbackColor)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(isSelected ? Color.appGameDark : Color.clear, lineWidth: 3)
        )
    }

    // MARK: - Subviews

    private var categoryAvatar: some View {
        let cat = prayer.categoryEnum
        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
            if cat.isAssetIcon {
                Image(cat.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(cat.fallbackColor)
            } else {
                Image(systemName: cat.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(cat.fallbackColor)
            }
        }
        .frame(width: 48, height: 48)
    }

    private var statusChip: some View {
        HStack(spacing: 3) {
            Image(systemName: prayer.statusEnum.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(prayer.statusEnum.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(Color.white.opacity(0.22))
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        // Preview requires Core Data; rely on the list views for a full preview.
        Text("PrayerCardView preview — see PrayerListView")
            .font(AppFont.caption())
    }
    .padding()
}
