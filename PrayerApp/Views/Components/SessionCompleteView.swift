import SwiftUI

struct SessionCompleteView: View {
    let session: PrayerSession
    let newlyUnlocked: [Decoration]
    /// Set to `true` to show the "Newly Available" list (hidden by default on all session summaries).
    var showNewlyUnlockedDecorations: Bool = false
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 0.96),
                    Color.appBackground,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    hero

                    rewardCard

                    statsRow

                    if showNewlyUnlockedDecorations && !newlyUnlocked.isEmpty {
                        unlocksCard
                    }

                    itemsCard

                    Button("Done", action: onDismiss)
                        .primaryButtonStyle()
                        .padding(.top, AppSpacing.sm)
                        .padding(.bottom, AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.xl)
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.thanksgivingColor, Color.thanksgivingColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 108, height: 108)
                    .shadow(color: Color.thanksgivingColor.opacity(0.4), radius: 16, y: 6)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Prayer Complete!")
                .font(AppFont.largeTitle())
                .foregroundColor(Color.appTextPrimary)

            Text("A new leaf has been added to your prayer tree.")
                .font(AppFont.body())
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Reward Card

    /// XP + drops summary pulled straight from the session. The values are stored
    /// on `PrayerSession` by `GamificationService.applySessionReward`.
    private var rewardCard: some View {
        HStack(spacing: AppSpacing.md) {
            rewardChip(
                icon: "bolt.fill",
                value: "+\(session.xpEarned)",
                label: "XP",
                tint: Color.appGameXPFill
            )

            rewardChip(
                icon: "drop.fill",
                value: "+\(session.dropsEarned)",
                label: "Drops",
                tint: Color.appOngoing
            )
        }
    }

    private func rewardChip(icon: String, value: String, label: String, tint: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle().fill(tint.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(tint)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                Text(label)
                    .font(AppFont.caption())
                    .foregroundColor(Color.appTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
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
                label: "For Others",
                color: .appAnswered
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle().fill(color.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(width: 38, height: 38)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Unlocks

    private var unlocksCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: AppIcons.decoration)
                    .font(.system(size: 14, weight: .bold))
                Text("Newly Available")
                    .font(AppFont.headline())
            }
            .foregroundColor(Color.appTextPrimary)

            ForEach(newlyUnlocked) { decoration in
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle().fill(Color.appAccent.opacity(0.2))
                        Image(systemName: "gift.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appAccent)
                    }
                    .frame(width: 34, height: 34)

                    Text(decoration.name ?? "")
                        .font(AppFont.body())
                        .foregroundColor(Color.appTextPrimary)

                    Spacer()

                    GoldCountPill(
                        icon: "drop.fill",
                        text: "\(decoration.dropCost)"
                    )
                }
                .padding(AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(Color.appAccent.opacity(0.08))
                )
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Items

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Prayers Offered")
                .font(AppFont.headline())
                .foregroundColor(Color.appTextPrimary)

            ForEach(session.itemList) { item in
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle().fill(item.categoryEnum.fallbackColor.opacity(0.2))
                        if item.categoryEnum.isAssetIcon {
                            Image(item.categoryEnum.iconName)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(item.categoryEnum.fallbackColor)
                        } else {
                            Image(systemName: item.categoryEnum.iconName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(item.categoryEnum.fallbackColor)
                        }
                    }
                    .frame(width: 30, height: 30)

                    Text(item.title ?? "")
                        .font(AppFont.body())
                        .foregroundColor(Color.appTextPrimary)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.thanksgivingColor)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}
