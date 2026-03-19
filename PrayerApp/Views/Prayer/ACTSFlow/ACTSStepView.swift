import SwiftUI

struct ACTSStepView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    let category: PrayerCategory

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if viewModel.showCollectedSummary {
                collectedSummaryView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 0) {
                    categoryBadge
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xs)

                    ConversationalPrayerEntryView(
                        viewModel: viewModel,
                        mode: .acts(category, onComplete: {
                            viewModel.addCurrentDraft(for: category)
                        })
                    )
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showCollectedSummary)
    }

    // MARK: - Category Badge

    private var categoryBadge: some View {
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
        }
    }

    // MARK: - Collected Summary

    private var collectedSummaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
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

                    Text("Added to your prayers")
                        .font(AppFont.title2())
                        .foregroundColor(Color.appTextPrimary)
                }
                .padding(.top, AppSpacing.md)

                if let drafts = viewModel.collectedDrafts[category], !drafts.isEmpty {
                    VStack(spacing: AppSpacing.xs) {
                        ForEach(drafts) { draft in
                            draftRow(draft)
                        }
                    }
                }

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.showCollectedSummary = false
                        }
                    } label: {
                        Text("Add Another \(category.displayName)")
                    }
                    .secondaryButtonStyle()

                    let isLast = category == .supplication
                    Button {
                        withAnimation {
                            viewModel.nextStep()
                        }
                    } label: {
                        Text(isLast ? "Review Prayers" : "Next: \(viewModel.nextCategoryLabel(after: category))")
                    }
                    .primaryButtonStyle()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
    }

    private func draftRow(_ draft: PrayerItemDraft) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.title)
                    .font(AppFont.subheadline())
                    .foregroundColor(Color.appTextPrimary)
                if draft.isIntercessory, let grp = draft.intercessoryGroup {
                    Text("For \(grp.displayName)")
                        .font(AppFont.caption())
                        .foregroundColor(Color.appTextSecondary)
                } else if let desc = draft.content, !desc.isEmpty {
                    Text(desc)
                        .font(AppFont.caption())
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button {
                viewModel.removeDraft(id: draft.id, category: category)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.appTextTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(category.color.opacity(0.08))
        .cornerRadius(AppRadius.sm)
    }
}

#Preview {
    let vm = ACTSFlowViewModel()
    vm.currentScreen = .actsStep(.adoration)
    return ACTSStepView(viewModel: vm, category: .adoration)
}
