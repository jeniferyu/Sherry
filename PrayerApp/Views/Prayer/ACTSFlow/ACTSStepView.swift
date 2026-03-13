import SwiftUI

struct ACTSStepView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    let category: PrayerCategory

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Step header
                stepHeader

                // Collected items list
                if let drafts = viewModel.collectedDrafts[category], !drafts.isEmpty {
                    collectedSection(drafts: drafts)
                }

                // Entry form
                formSection

                // Action buttons
                actionButtons
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Header

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                // Step badge
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

            Text(viewModel.stepPrompt(for: category))
                .font(AppFont.title2())
                .foregroundColor(Color.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Collected Items

    private func collectedSection(drafts: [PrayerItemDraft]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Added so far")
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
                .padding(.leading, AppSpacing.xs)

            VStack(spacing: AppSpacing.xs) {
                ForEach(drafts) { draft in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.title)
                                .font(AppFont.subheadline())
                                .foregroundColor(Color.appTextPrimary)
                            if draft.isIntercessory, let grp = draft.intercessoryGroup {
                                Text("For \(grp.displayName)")
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.appTextSecondary)
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
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Title (required)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Title")
                    .font(AppFont.caption())
                    .foregroundColor(Color.appTextSecondary)
                TextField("Enter a title...", text: $viewModel.title)
                    .font(AppFont.body())
                    .padding(AppSpacing.sm)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.sm)
            }

            // Description (optional)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Description (optional)")
                    .font(AppFont.caption())
                    .foregroundColor(Color.appTextSecondary)
                TextField("Add more details...", text: $viewModel.content, axis: .vertical)
                    .font(AppFont.body())
                    .lineLimit(3, reservesSpace: true)
                    .padding(AppSpacing.sm)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.sm)
            }

            // Tags (optional)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Tags (optional, comma-separated)")
                    .font(AppFont.caption())
                    .foregroundColor(Color.appTextSecondary)
                TextField("e.g. family, healing", text: $viewModel.tags)
                    .font(AppFont.body())
                    .padding(AppSpacing.sm)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.sm)
            }

            // Supplication extra: for myself / others
            if category == .supplication {
                supplicationToggle
            }

            // Add Prayer button
            Button {
                viewModel.addCurrentDraft(for: category)
            } label: {
                Text("Add Prayer")
            }
            .primaryButtonStyle()
            .disabled(!viewModel.isFormValid)
            .opacity(viewModel.isFormValid ? 1 : 0.5)
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    private var supplicationToggle: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("This prayer is for:")
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)

            HStack(spacing: AppSpacing.sm) {
                toggleButton(label: "Myself", selected: !viewModel.isForOthers) {
                    viewModel.isForOthers = false
                }
                toggleButton(label: "Someone else", selected: viewModel.isForOthers) {
                    viewModel.isForOthers = true
                }
            }

            if viewModel.isForOthers {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Group (optional)")
                        .font(AppFont.caption())
                        .foregroundColor(Color.appTextSecondary)
                    Picker("Group", selection: $viewModel.intercessoryGroup) {
                        ForEach(IntercessoryGroup.allCases, id: \.self) { grp in
                            Label(grp.displayName, systemImage: grp.iconName).tag(grp)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.sm)
                }
            }
        }
    }

    private func toggleButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.subheadline())
                .foregroundColor(selected ? .white : Color.appTextSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(selected ? Color.appPrimary : Color.appSurfaceSecond)
                .cornerRadius(AppRadius.full)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        let hasDrafts = !(viewModel.collectedDrafts[category] ?? []).isEmpty
        let nextLabel = viewModel.nextCategoryLabel(after: category)
        let isLast = (category == .supplication)

        return VStack(spacing: AppSpacing.sm) {
            if hasDrafts {
                // "Add Another" secondary button
                Button {
                    // Form is already cleared after addCurrentDraft; just keep showing form
                } label: {
                    Text("Add Another \(category.displayName)")
                }
                .secondaryButtonStyle()

                // "Next" or "Review" primary button
                Button {
                    viewModel.nextStep()
                } label: {
                    Text(isLast ? "Review Prayers" : "Next: \(nextLabel)")
                }
                .primaryButtonStyle()
            }
        }
    }
}

#Preview {
    let vm = ACTSFlowViewModel()
    vm.currentScreen = .actsStep(.adoration)
    return ACTSStepView(viewModel: vm, category: .adoration)
}
