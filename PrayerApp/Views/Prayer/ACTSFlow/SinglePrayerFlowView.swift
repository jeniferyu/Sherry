import SwiftUI

struct SinglePrayerFlowView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    /// Called when user taps "Start Prayer Session" with the single item.
    var onStartSession: ([PrayerItem]) -> Void

    @State private var selectedCategory: PrayerCategory? = nil

    var body: some View {
        if let category = selectedCategory {
            singleEntryForm(category: category)
        } else {
            categoryPickScreen
        }
    }

    // MARK: - Category Picker

    private var categoryPickScreen: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
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

                // Category cards
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
            viewModel.title = ""
            viewModel.content = ""
            viewModel.tags = ""
            viewModel.isForOthers = false
            viewModel.intercessoryGroup = .family
            selectedCategory = category
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

    // MARK: - Entry Form

    private func singleEntryForm(category: PrayerCategory) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Step header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
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
                            selectedCategory = nil
                        } label: {
                            Text("Change")
                                .font(AppFont.caption())
                                .foregroundColor(Color.appPrimary)
                        }
                    }

                    Text(viewModel.stepPrompt(for: category))
                        .font(AppFont.title2())
                        .foregroundColor(Color.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.lg)
                .cardStyle()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)

                // Form
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    formField(label: "Title", placeholder: "Enter a title...", text: $viewModel.title)

                    formFieldMultiline(label: "Description (optional)", placeholder: "Add more details...", text: $viewModel.content)

                    formField(label: "Tags (optional, comma-separated)", placeholder: "e.g. family, healing", text: $viewModel.tags)

                    // Supplication: myself / others
                    if category == .supplication {
                        supplicationToggle
                    }
                }
                .padding(AppSpacing.lg)
                .cardStyle()
                .padding(.horizontal, AppSpacing.lg)

                // Start Session button
                Button {
                    if viewModel.isFormValid {
                        let item = viewModel.buildSingleSessionItem(category: category)
                        onStartSession([item])
                    }
                } label: {
                    Text("Start Prayer Session")
                }
                .primaryButtonStyle()
                .disabled(!viewModel.isFormValid)
                .opacity(viewModel.isFormValid ? 1 : 0.5)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Supplication Toggle

    private var supplicationToggle: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("This prayer is for:")
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)

            HStack(spacing: AppSpacing.sm) {
                toggleChip(label: "Myself", selected: !viewModel.isForOthers) {
                    viewModel.isForOthers = false
                }
                toggleChip(label: "Someone else", selected: viewModel.isForOthers) {
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

    private func toggleChip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
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

    // MARK: - Helpers

    private func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
            TextField(placeholder, text: text)
                .font(AppFont.body())
                .padding(AppSpacing.sm)
                .background(Color.appSurfaceSecond)
                .cornerRadius(AppRadius.sm)
        }
    }

    private func formFieldMultiline(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
            TextField(placeholder, text: text, axis: .vertical)
                .font(AppFont.body())
                .lineLimit(3, reservesSpace: true)
                .padding(AppSpacing.sm)
                .background(Color.appSurfaceSecond)
                .cornerRadius(AppRadius.sm)
        }
    }

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
