import SwiftUI

struct SessionCompleteView: View {
    let session: PrayerSession
    let newlyUnlocked: [Decoration]
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                // Hero
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.thanksgivingColor)
                        .shadow(color: Color.thanksgivingColor.opacity(0.3), radius: 12)

                    Text("Prayer Complete!")
                        .font(AppFont.largeTitle())
                        .foregroundColor(Color.appTextPrimary)

                    Text("A new leaf has been added to your prayer tree.")
                        .font(AppFont.body())
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xxl)

                // Stats
                HStack(spacing: AppSpacing.lg) {
                    statCard(
                        icon: "checkmark.circle.fill",
                        value: "\(session.itemList.count)",
                        label: "Prayed",
                        color: .appOngoing
                    )
                    statCard(
                        icon: "clock.fill",
                        value: session.formattedDuration,
                        label: "Duration",
                        color: .appPrimary
                    )
                    statCard(
                        icon: "star.fill",
                        value: "\(session.intercessoryItems.count)",
                        label: "Intercessions",
                        color: .appAnswered
                    )
                }

                // Newly unlocked decorations
                if !newlyUnlocked.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("New Unlocks!", systemImage: AppIcons.decoration)
                            .font(AppFont.headline())
                            .foregroundColor(Color.appTextPrimary)

                        ForEach(newlyUnlocked) { decoration in
                            HStack {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.appAccent)
                                Text(decoration.name ?? "")
                                    .font(AppFont.body())
                                    .foregroundColor(Color.appTextPrimary)
                            }
                            .padding(AppSpacing.md)
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }

                // Items prayed
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Prayers Offered")
                        .font(AppFont.headline())
                        .foregroundColor(Color.appTextPrimary)
                        .padding(.horizontal, AppSpacing.md)

                    ForEach(session.itemList) { item in
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: item.categoryEnum.iconName)
                                .foregroundColor(item.categoryEnum.fallbackColor)
                                .frame(width: 24)
                            Text(item.title ?? "")
                                .font(AppFont.body())
                                .foregroundColor(Color.appTextPrimary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                    }
                }

                // Done button
                Button("Done", action: onDismiss)
                    .primaryButtonStyle()
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .font(AppFont.title2())
                .foregroundColor(Color.appTextPrimary)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .cardStyle()
    }
}
