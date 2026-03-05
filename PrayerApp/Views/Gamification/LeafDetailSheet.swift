import SwiftUI

struct LeafDetailSheet: View {
    let leaf: LeafData
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // Leaf icon
                ZStack {
                    Circle()
                        .fill(leaf.isAnswered ? Color.appAnswered.opacity(0.15) : Color.thanksgivingColor.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: leaf.isAnswered ? "sparkles" : "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(leaf.isAnswered ? .appAnswered : .thanksgivingColor)
                }
                .padding(.top, AppSpacing.lg)

                // Prayer info
                VStack(spacing: AppSpacing.sm) {
                    Text(leaf.prayerItem.title ?? "")
                        .font(AppFont.title2())
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)

                    if let content = leaf.prayerItem.content, !content.isEmpty {
                        Text(content)
                            .font(AppFont.body())
                            .foregroundColor(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }

                    StatusIndicator(status: leaf.prayerItem.statusEnum)
                }

                // Stats
                HStack(spacing: AppSpacing.md) {
                    VStack(spacing: AppSpacing.xxs) {
                        Text("\(leaf.prayerItem.prayedCount)")
                            .font(AppFont.title2())
                        Text("Times Prayed")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .cardStyle()

                    VStack(spacing: AppSpacing.xxs) {
                        CategoryBadge(category: leaf.prayerItem.categoryEnum)
                        Text("Category")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .cardStyle()
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Leaf Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}
