import SwiftUI

/// List row for personal prayers — matches the layout of `IntercessoryListView.intercessoryRow`.
struct PrayerCardView: View {
    let prayer: PrayerItem
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            categoryIconCircle

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(prayer.title ?? "")
                    .font(AppFont.headline())
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)

                if let content = prayer.content, !content.isEmpty {
                    Text(content)
                        .font(AppFont.caption())
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: AppSpacing.xs) {
                    Text(prayer.categoryEnum.displayName)
                        .font(AppFont.caption2())
                        .foregroundColor(Color.appTextTertiary)
                    Text("\u{2022}")
                        .foregroundColor(Color.appTextTertiary)
                        .font(AppFont.caption2())
                    Text("\(prayer.prayedCount)x prayed")
                        .font(AppFont.caption2())
                        .foregroundColor(Color.appTextTertiary)
                }
            }

            Spacer()

            StatusIndicator(status: prayer.statusEnum, showLabel: false)
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
        )
    }

    private var categoryIconCircle: some View {
        let cat = prayer.categoryEnum
        return Group {
            if cat.isAssetIcon {
                Image(cat.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: cat.iconName)
                    .font(.system(size: 18))
            }
        }
        .foregroundColor(Color.appPrimary)
        .frame(width: 40, height: 40)
        .background(Color.appPrimary.opacity(0.12))
        .clipShape(Circle())
    }
}
