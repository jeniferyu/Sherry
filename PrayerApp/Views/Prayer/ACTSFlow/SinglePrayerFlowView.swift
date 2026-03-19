import SwiftUI

struct SinglePrayerFlowView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    var onStartSession: ([PrayerItem]) -> Void

    var body: some View {
        switch viewModel.currentScreen {
        case .singleCategoryPick:
            categoryPickScreen
        case .singleEntry(let category):
            singleEntryScreen(category: category)
        default:
            categoryPickScreen
        }
    }

    // MARK: - Category Picker

    private var categoryPickScreen: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.xs) {
                    Text("What type of prayer is this?")
                        .font(AppFont.title())
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.xl)

                    Text("Choose the category that fits your prayer")
                        .font(AppFont.subheadline())
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.horizontal, AppSpacing.lg)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(PrayerCategory.allCases, id: \.self) { category in
                        categoryCard(category)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer(minLength: AppSpacing.xl)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func categoryCard(_ category: PrayerCategory) -> some View {
        Button {
            viewModel.selectSingleCategory(category)
        } label: {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(category.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(AppFont.headline())
                        .foregroundColor(Color.appTextPrimary)
                    Text(categoryDescription(category))
                        .font(AppFont.subheadline())
                        .foregroundColor(Color.appTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Color.appTextTertiary)
            }
            .padding(AppSpacing.lg)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Single Entry Screen

    private func singleEntryScreen(category: PrayerCategory) -> some View {
        VStack(spacing: 0) {
            categoryBadge(for: category)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xs)

            ConversationalPrayerEntryView(
                viewModel: viewModel,
                mode: .single(category, onStartSession: {
                    let item = viewModel.buildSingleSessionItem(category: category)
                    onStartSession([item])
                })
            )
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func categoryBadge(for category: PrayerCategory) -> some View {
        HStack {
            HStack(spacing: AppSpacing.xxs) {
                Circle()
                    .fill(category.color)
                    .frame(width: 10, height: 10)
                Text(category.displayName.uppercased())
                    .font(AppFont.caption())
                    .foregroundColor(category.color)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(category.color.opacity(0.12))
            .cornerRadius(AppRadius.full)

            Spacer()

            Button {
                viewModel.currentScreen = .singleCategoryPick
                viewModel.clearForm()
            } label: {
                Text("Change")
                    .font(AppFont.caption())
                    .foregroundColor(Color.appPrimary)
            }
        }
    }

    // MARK: - Helpers

    private func categoryDescription(_ category: PrayerCategory) -> String {
        switch category {
        case .adoration:    return "Praise and worship God"
        case .confession:   return "Confess and seek forgiveness"
        case .thanksgiving: return "Give thanks for blessings"
        case .supplication: return "Make requests and intercede"
        }
    }
}

#Preview {
    SinglePrayerFlowView(viewModel: ACTSFlowViewModel(), onStartSession: { _ in })
}
