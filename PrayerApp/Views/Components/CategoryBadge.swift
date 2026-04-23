import SwiftUI

struct CategoryBadge: View {
    let category: PrayerCategory
    var compact: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            if category.isAssetIcon {
                Image(category.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: 12))
            }
            if !compact {
                Text(category.displayName)
                    .font(AppFont.caption())
            }
        }
        .foregroundColor(category.fallbackColor)
        .padding(.horizontal, compact ? AppSpacing.xs : AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(category.fallbackColor.opacity(0.15))
        .cornerRadius(AppRadius.full)
    }
}

// MARK: - Intercession (Today's saved from Others tab)

struct IntercessoryGroupBadge: View {
    let group: IntercessoryGroup
    var compact: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: group.iconName)
                .font(.system(size: 12))
            if !compact {
                Text(group.displayName)
                    .font(AppFont.caption())
            }
        }
        .foregroundColor(group.accentColor)
        .padding(.horizontal, compact ? AppSpacing.xs : AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(group.accentColor.opacity(0.15))
        .cornerRadius(AppRadius.full)
    }
}

#Preview {
    HStack {
        CategoryBadge(category: .adoration)
        CategoryBadge(category: .confession)
        CategoryBadge(category: .thanksgiving)
        CategoryBadge(category: .supplication)
    }
    .padding()
}
