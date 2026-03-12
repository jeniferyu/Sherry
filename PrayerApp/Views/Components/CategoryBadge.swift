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
                    .frame(width: compact ? 10 : 12, height: compact ? 10 : 12)
            } else {
                Image(systemName: category.iconName)
                    .font(.system(size: compact ? 10 : 12))
            }
            if !compact {
                Text(category.displayName)
                    .font(AppFont.caption())
            } else {
                Text(category.shortName)
                    .font(AppFont.caption())
                    .fontWeight(.bold)
            }
        }
        .foregroundColor(category.fallbackColor)
        .padding(.horizontal, compact ? AppSpacing.xs : AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(category.fallbackColor.opacity(0.15))
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
