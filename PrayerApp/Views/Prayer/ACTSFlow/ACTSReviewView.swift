import SwiftUI

struct ACTSReviewView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    /// Called when user taps "Start Prayer Session" with the items to pray over.
    var onStartSession: ([PrayerItem]) -> Void

    @State private var showEmptySessionCard = false

    var body: some View {
        ZStack {
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

                    // Start Session — enabled when there is real content; tap when empty shows a card (not `include` alone).
                    let canStart = viewModel.hasSessionContentToStart
                    Button {
                        if canStart {
                            onStartSession(viewModel.buildSessionItems())
                        } else {
                            showEmptySessionCard = true
                        }
                    } label: {
                        Text("Start Prayer Session")
                    }
                    .primaryButtonStyle()
                    .opacity(canStart ? 1 : 0.48)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
                .padding(.top, AppSpacing.md)
            }
            .background(Color.appBackground.ignoresSafeArea())

            if showEmptySessionCard {
                emptySessionBlockCard
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(50)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: showEmptySessionCard)
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
                                if item.isIntercessory, let group = item.intercessoryGroupEnum {
                                    IntercessoryGroupBadge(group: group, compact: true)
                                } else {
                                    CategoryBadge(category: item.categoryEnum, compact: true)
                                }
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

    // MARK: - Empty session (no drafts, today not included)

    private var emptySessionBlockCard: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { withAnimation { showEmptySessionCard = false } }

            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.14))
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color.appPrimary)
                }
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(0.2), radius: 8, y: 3)

                Text("Add a prayer to start")
                    .font(AppFont.title2())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.appTextPrimary)

                Text("There are no items in this session yet. Go back to any ACTS step and add at least one prayer, or turn on “Include Today’s Saved Prayers” to bring in what you already saved for today.")
                    .font(AppFont.subheadline())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    withAnimation { showEmptySessionCard = false }
                } label: {
                    Text("OK")
                }
                .primaryButtonStyle()
                .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(
                color: AppShadow.gameCardShadow.color,
                radius: 20,
                x: 0,
                y: 10
            )
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
