import SwiftUI

/// A reusable conversational prayer entry flow that presents one question per screen.
/// Used by both ACTSStepView (mode: .acts) and SinglePrayerFlowView (mode: .single).
struct ConversationalPrayerEntryView: View {

    enum Mode {
        case acts(PrayerCategory, onComplete: () -> Void)
        case single(PrayerCategory, onStartSession: () -> Void)
    }

    @ObservedObject var viewModel: ACTSFlowViewModel
    let mode: Mode

    private var category: PrayerCategory {
        switch mode {
        case .acts(let cat, _):    return cat
        case .single(let cat, _): return cat
        }
    }

    private var steps: [EntryStepKind] {
        viewModel.entrySteps(for: category)
    }

    private var currentStep: EntryStepKind {
        steps[min(viewModel.entryStep, steps.count - 1)]
    }

    private var isLastStep: Bool {
        viewModel.entryStep >= steps.count - 1
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)

                stepContent
                    .id(viewModel.entryStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.entryStep ? category.color : Color.appSurfaceSecond)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.entryStep)
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .title:
            titleStepView
        case .description:
            descriptionStepView
        case .forWhom:
            forWhomStepView
        case .tags:
            tagsStepView
        }
    }

    // MARK: - Title Step

    private var titleStepView: some View {
        ConversationalStepContainer(
            prompt: viewModel.stepPrompt(for: category),
            subtitle: "Just a short phrase is enough.",
            category: category
        ) {
            VStack(spacing: AppSpacing.lg) {
                TextField("", text: $viewModel.title, prompt: Text("Write something...").foregroundColor(Color.appTextTertiary))
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .padding(AppSpacing.md)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.md)

                nextButton(label: "Next", enabled: viewModel.isFormValid) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.advanceEntryStep(for: category)
                    }
                }
            }
        }
    }

    // MARK: - Description Step

    private var descriptionStepView: some View {
        ConversationalStepContainer(
            prompt: viewModel.descriptionPrompt(for: category),
            subtitle: "Feel free to skip if you'd like to keep it brief.",
            category: category
        ) {
            VStack(spacing: AppSpacing.lg) {
                TextField("", text: $viewModel.content, prompt: Text("Share more here...").foregroundColor(Color.appTextTertiary), axis: .vertical)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(5, reservesSpace: true)
                    .padding(AppSpacing.md)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.md)

                VStack(spacing: AppSpacing.sm) {
                    nextButton(label: "Next", enabled: true) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.advanceEntryStep(for: category)
                        }
                    }

                    skipButton {
                        viewModel.content = ""
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.advanceEntryStep(for: category)
                        }
                    }
                }
            }
        }
    }

    // MARK: - For Whom Step (Supplication only)

    private var forWhomStepView: some View {
        ConversationalStepContainer(
            prompt: "Is this prayer for yourself or for someone else?",
            subtitle: nil,
            category: category
        ) {
            VStack(spacing: AppSpacing.lg) {
                HStack(spacing: AppSpacing.sm) {
                    toggleChip(label: "For myself", selected: !viewModel.isForOthers) {
                        viewModel.isForOthers = false
                    }
                    toggleChip(label: "For someone else", selected: viewModel.isForOthers) {
                        viewModel.isForOthers = true
                    }
                }

                if viewModel.isForOthers {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("Which group?")
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
                        .cornerRadius(AppRadius.md)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isForOthers)
                }

                nextButton(label: "Next", enabled: true) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.advanceEntryStep(for: category)
                    }
                }
            }
        }
    }

    // MARK: - Tags Step

    private var tagsStepView: some View {
        ConversationalStepContainer(
            prompt: viewModel.tagsPrompt(),
            subtitle: "e.g. health, family, gratitude",
            category: category
        ) {
            VStack(spacing: AppSpacing.lg) {
                TextField("", text: $viewModel.tags, prompt: Text("Add tags...").foregroundColor(Color.appTextTertiary))
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .padding(AppSpacing.md)
                    .background(Color.appSurfaceSecond)
                    .cornerRadius(AppRadius.md)

                finalActionButton
            }
        }
    }

    // MARK: - Final Action Button

    @ViewBuilder
    private var finalActionButton: some View {
        switch mode {
        case .acts(_, let onComplete):
            VStack(spacing: AppSpacing.sm) {
                nextButton(label: "Add Prayer", enabled: true) {
                    onComplete()
                }
                skipButton {
                    viewModel.tags = ""
                    onComplete()
                }
            }
        case .single(_, let onStartSession):
            VStack(spacing: AppSpacing.sm) {
                nextButton(label: "Start Prayer Session", enabled: true) {
                    onStartSession()
                }
                skipButton {
                    viewModel.tags = ""
                    onStartSession()
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func nextButton(label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
        }
        .primaryButtonStyle()
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }

    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Skip")
                .font(AppFont.subheadline())
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .contentShape(Rectangle())
    }

    private func toggleChip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.subheadline())
                .foregroundColor(selected ? .white : Color.appTextSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(selected ? category.color : Color.appSurfaceSecond)
                .cornerRadius(AppRadius.md)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }
}

// MARK: - Step Container

/// A full-screen layout for a single conversational question.
private struct ConversationalStepContainer<Content: View>: View {
    let prompt: String
    let subtitle: String?
    let category: PrayerCategory
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(prompt)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.subheadline())
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
                .padding(.top, AppSpacing.xl)

                content()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxl)
        }
    }
}

#Preview {
    let vm = ACTSFlowViewModel()
    vm.currentScreen = .actsStep(.adoration)
    return ConversationalPrayerEntryView(
        viewModel: vm,
        mode: .acts(.adoration, onComplete: {})
    )
}
