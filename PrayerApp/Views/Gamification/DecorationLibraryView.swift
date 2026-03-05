import SwiftUI

struct DecorationLibraryView: View {
    @StateObject private var viewModel = DecorationViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {

                if !viewModel.unlockedDecorations.isEmpty {
                    decorationSection(
                        title: "Unlocked",
                        icon: "gift.fill",
                        items: viewModel.unlockedDecorations,
                        isUnlocked: true
                    )
                }

                if !viewModel.lockedDecorations.isEmpty {
                    decorationSection(
                        title: "Locked",
                        icon: "lock.fill",
                        items: viewModel.lockedDecorations,
                        isUnlocked: false
                    )
                }

                if viewModel.unlockedDecorations.isEmpty && viewModel.lockedDecorations.isEmpty {
                    EmptyStateView(
                        iconName: AppIcons.decoration,
                        title: "No Decorations",
                        message: "Keep praying to unlock tree decorations!"
                    )
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Decorations")
        .onAppear { viewModel.fetchDecorations() }
    }

    private func decorationSection(
        title: String,
        icon: String,
        items: [Decoration],
        isUnlocked: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(title, systemImage: icon)
                .font(AppFont.headline())
                .foregroundColor(Color.appTextPrimary)
                .padding(.horizontal, AppSpacing.lg)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppSpacing.md
            ) {
                ForEach(items) { decoration in
                    decorationCard(decoration, isUnlocked: isUnlocked)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func decorationCard(_ decoration: Decoration, isUnlocked: Bool) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isUnlocked ? Color.appPrimary.opacity(0.12) : Color.appSurfaceSecond)
                    .aspectRatio(1.5, contentMode: .fit)

                Image(systemName: isUnlocked ? "paintbrush.fill" : "lock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isUnlocked ? Color.appPrimary : Color.appTextTertiary)
            }

            VStack(spacing: AppSpacing.xxs) {
                Text(decoration.name ?? "")
                    .font(AppFont.subheadline())
                    .foregroundColor(isUnlocked ? Color.appTextPrimary : Color.appTextTertiary)
                    .lineLimit(1)

                if let condition = decoration.unlockCondition, !isUnlocked {
                    Text(unlockHint(condition))
                        .font(AppFont.caption2())
                        .foregroundColor(Color.appTextTertiary)
                        .multilineTextAlignment(.center)
                }

                Text(decoration.decorationTypeEnum.displayName)
                    .font(AppFont.caption2())
                    .foregroundColor(Color.appTextTertiary)
            }
            .padding(.horizontal, AppSpacing.xs)

            if isUnlocked {
                Button {
                    viewModel.applyDecoration(decoration)
                } label: {
                    Text("Apply")
                        .font(AppFont.caption())
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(Color.appPrimary)
                        .cornerRadius(AppRadius.full)
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .opacity(isUnlocked ? 1.0 : 0.7)
    }

    private func unlockHint(_ condition: String) -> String {
        switch condition {
        case "streak_3":    return "3-day streak"
        case "streak_7":    return "7-day streak"
        case "streak_30":   return "30-day streak"
        case "sessions_5":  return "5 sessions total"
        case "sessions_10": return "10 sessions total"
        case "sessions_50": return "50 sessions total"
        case "answered_1":  return "1 answered prayer"
        case "answered_5":  return "5 answered prayers"
        default:            return "Keep praying!"
        }
    }
}

#Preview {
    NavigationStack {
        DecorationLibraryView()
    }
}
