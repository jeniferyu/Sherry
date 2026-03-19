import SwiftUI

struct ACTSReviewView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    /// Called when user taps "Start Prayer Session" with the items to pray over.
    var onStartSession: ([PrayerItem]) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                reviewHeader

                // ACTS items per category
                ForEach(orderedCategories, id: \.self) { category in
                    if let drafts = viewModel.collectedDrafts[category], !drafts.isEmpty {
                        categorySection(category: category, drafts: drafts)
                    }
                }

                // Today's Prayers toggle (only if there are saved items)
                if !viewModel.todayPrayers.isEmpty {
                    todayPrayersSection
                }

                // Start Session button
                let hasItems = viewModel.totalDraftCount > 0 || viewModel.includeTodayPrayers
                Button {
                    let items = viewModel.buildSessionItems()
                    onStartSession(items)
                } label: {
                    Text("Start Prayer Session")
                }
                .primaryButtonStyle()
                .disabled(!hasItems)
                .opacity(hasItems ? 1 : 0.45)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Header

    private var reviewHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.appPrimary)

            Text("Your Prayer Items")
                .font(AppFont.title())
                .foregroundColor(Color.appTextPrimary)

            Text("Review what you've gathered before entering prayer")
                .font(AppFont.subheadline())
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Category Section

    private func categorySection(category: PrayerCategory, drafts: [PrayerItemDraft]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Section label
            HStack(spacing: AppSpacing.xxs) {
                Circle()
                    .fill(category.color)
                    .frame(width: 8, height: 8)
                Text(category.displayName)
                    .font(AppFont.caption())
                    .foregroundColor(category.color)
                    .fontWeight(.semibold)
            }
            .padding(.leading, AppSpacing.xs)

            VStack(spacing: AppSpacing.xs) {
                ForEach(drafts) { draft in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.title)
                                .font(AppFont.subheadline())
                                .foregroundColor(Color.appTextPrimary)
                            if draft.isIntercessory, let grp = draft.intercessoryGroup {
                                Text("For \(grp.displayName)")
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.appTextSecondary)
                            }
                            if let content = draft.content, !content.isEmpty {
                                Text(content)
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.appTextTertiary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(category.color.opacity(0.08))
                    .cornerRadius(AppRadius.sm)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Today's Prayers Section

    private var todayPrayersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Divider()
                .padding(.horizontal, AppSpacing.lg)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Toggle(isOn: $viewModel.includeTodayPrayers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Today's Saved Prayers")
                            .font(AppFont.subheadline())
                            .foregroundColor(Color.appTextPrimary)
                        Text("\(viewModel.todayPrayers.count) prayer\(viewModel.todayPrayers.count == 1 ? "" : "s") saved")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.appPrimary))

                if viewModel.includeTodayPrayers {
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(viewModel.todayPrayers, id: \.objectID) { item in
                            HStack {
                                CategoryBadge(category: item.categoryEnum, compact: true)
                                Text(item.title ?? "")
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.appTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .background(Color.appSurfaceSecond)
                            .cornerRadius(AppRadius.sm)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    // MARK: - Helpers

    private let orderedCategories: [PrayerCategory] = [.adoration, .confession, .thanksgiving, .supplication]
}

#Preview {
    let vm = ACTSFlowViewModel()
    vm.collectedDrafts = [
        .adoration: [PrayerItemDraft(title: "God's grace", content: nil, tags: [], category: .adoration, isIntercessory: false)],
        .confession: [PrayerItemDraft(title: "Pride", content: nil, tags: [], category: .confession, isIntercessory: false)],
        .supplication: [PrayerItemDraft(title: "John's job", content: nil, tags: [], category: .supplication, isIntercessory: true, intercessoryGroup: .friends)]
    ]
    return ACTSReviewView(viewModel: vm, onStartSession: { _ in })
}
