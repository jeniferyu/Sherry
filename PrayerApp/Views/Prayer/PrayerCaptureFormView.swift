import SwiftUI

struct PrayerCaptureFormView: View {
    @ObservedObject var viewModel: PrayerCaptureViewModel
    var onSaveForLater: (() -> Void)?
    var onPrayNow: ((PrayerSession) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {

                    // Title
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Prayer Title")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextSecondary)
                        TextField("What's on your heart?", text: $viewModel.title)
                            .font(AppFont.body())
                            .padding(AppSpacing.md)
                            .background(Color.appSurfaceSecond)
                            .cornerRadius(AppRadius.md)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Notes (Optional)")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextSecondary)
                        TextEditor(text: $viewModel.content)
                            .font(AppFont.body())
                            .frame(minHeight: 80)
                            .padding(AppSpacing.sm)
                            .background(Color.appSurfaceSecond)
                            .cornerRadius(AppRadius.md)
                    }

                    // Intercessory toggle
                    Toggle(isOn: $viewModel.isIntercessory) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(Color.appPrimary)
                            Text("Praying for someone else")
                                .font(AppFont.body())
                                .foregroundColor(Color.appTextPrimary)
                        }
                    }
                    .tint(Color.appPrimary)

                    // Category (only for personal prayers)
                    if !viewModel.isIntercessory {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("ACTS Category")
                                .font(AppFont.caption())
                                .foregroundColor(Color.appTextSecondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xs) {
                                ForEach(PrayerCategory.allCases, id: \.self) { category in
                                    categoryButton(category)
                                }
                            }
                        }
                    } else {
                        // Intercessory group
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Who are you praying for?")
                                .font(AppFont.caption())
                                .foregroundColor(Color.appTextSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.xs) {
                                    ForEach(IntercessoryGroup.allCases, id: \.self) { group in
                                        groupChip(group)
                                    }
                                }
                            }
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Tags (comma separated)")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextSecondary)
                        TextField("e.g. health, family, work", text: $viewModel.tags)
                            .font(AppFont.body())
                            .padding(AppSpacing.md)
                            .background(Color.appSurfaceSecond)
                            .cornerRadius(AppRadius.md)
                    }

                    // Action Buttons
                    VStack(spacing: AppSpacing.sm) {
                        Button {
                            if let session = viewModel.prayNow() {
                                onPrayNow?(session)
                            }
                        } label: {
                            Label("Start Praying Now", systemImage: AppIcons.startPraying)
                        }
                        .primaryButtonStyle()
                        .disabled(!viewModel.isValid)

                        Button {
                            viewModel.saveForLater()
                            onSaveForLater?()
                        } label: {
                            Text("Save for Later")
                        }
                        .secondaryButtonStyle()
                        .disabled(!viewModel.isValid)
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .padding(AppSpacing.lg)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("New Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }

    private func categoryButton(_ category: PrayerCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectedCategory = category
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: category.iconName)
                Text(category.displayName)
                    .font(AppFont.subheadline())
            }
            .foregroundColor(isSelected ? .white : category.fallbackColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? category.fallbackColor : category.fallbackColor.opacity(0.15))
            .cornerRadius(AppRadius.md)
        }
    }

    private func groupChip(_ group: IntercessoryGroup) -> some View {
        let isSelected = viewModel.selectedIntercessoryGroup == group
        return Button {
            viewModel.selectedIntercessoryGroup = group
        } label: {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: group.iconName)
                Text(group.displayName)
                    .font(AppFont.subheadline())
            }
            .foregroundColor(isSelected ? .white : Color.appPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? Color.appPrimary : Color.appPrimary.opacity(0.12))
            .cornerRadius(AppRadius.full)
        }
    }
}
