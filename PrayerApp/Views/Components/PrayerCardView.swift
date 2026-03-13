import SwiftUI

struct PrayerCardView: View {
    let prayer: PrayerItem
    var isSelected: Bool = false
    var onStatusChange: ((PrayerStatus) -> Void)? = nil

    @State private var showingMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {

            // Header Row
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                // Category indicator line
                RoundedRectangle(cornerRadius: 2)
                    .fill(prayer.categoryEnum.fallbackColor)
                    .frame(width: 3)
                    .frame(minHeight: 40)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    // Title
                    Text(prayer.title ?? "")
                        .font(AppFont.headline())
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(2)

                    // Content preview
                    if let content = prayer.content, !content.isEmpty {
                        Text(content)
                            .font(AppFont.subheadline())
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Status / Action button
                if let onStatusChange {
                    Menu {
                        Button {
                            onStatusChange(.prayed)
                        } label: {
                            Label("Mark Prayed", systemImage: PrayerStatus.prayed.iconName)
                        }

                        Button {
                            onStatusChange(.answered)
                        } label: {
                            Label("Mark Answered", systemImage: PrayerStatus.answered.iconName)
                        }

                        Button {
                            onStatusChange(.archived)
                        } label: {
                            Label("Archive", systemImage: PrayerStatus.archived.iconName)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appTextTertiary)
                    }
                }
            }

            // Tags
            if !prayer.tagList.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.xxs) {
                        ForEach(prayer.tagList, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(AppFont.caption2())
                                .foregroundColor(Color.appTextTertiary)
                                .padding(.horizontal, AppSpacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.appSurfaceSecond)
                                .cornerRadius(AppRadius.full)
                        }
                    }
                }
            }

            // Footer Row
            HStack(spacing: AppSpacing.xs) {
                CategoryBadge(category: prayer.categoryEnum, compact: true)

                if prayer.isIntercessory, let group = prayer.intercessoryGroupEnum {
                    HStack(spacing: 3) {
                        Image(systemName: group.iconName)
                            .font(.system(size: 10))
                        Text(group.displayName)
                            .font(AppFont.caption2())
                    }
                    .foregroundColor(Color.appTextTertiary)
                }

                Spacer()

                StatusIndicator(status: prayer.statusEnum)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(isSelected ? Color.appPrimary.opacity(0.08) : Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
                )
        )
        .shadow(
            color: AppShadow.cardShadow.color,
            radius: AppShadow.cardShadow.radius,
            x: AppShadow.cardShadow.x,
            y: AppShadow.cardShadow.y
        )
    }
}
