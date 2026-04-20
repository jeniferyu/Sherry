import SwiftUI

/// Full-screen container that owns `ACTSFlowViewModel` and routes between all
/// screens in the guided prayer flow (style selection → ACTS steps / single prayer → review → session).
struct PrayerFlowContainerView: View {
    @StateObject private var flowVM = ACTSFlowViewModel()
    @StateObject private var sessionVM = PrayerSessionViewModel()

    @State private var showingSession = false
    @State private var pendingItems: [PrayerItem] = []
    @State private var showSkipBlockedAlert = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                currentScreenView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .alert("Add a Prayer First", isPresented: $showSkipBlockedAlert) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("You haven't added any prayers yet. Add at least one before you can start a session.")
        }
        .fullScreenCover(isPresented: $showingSession) {
            if sessionVM.isFinished, let finished = sessionVM.finishedSession {
                SessionCompleteView(
                    session: finished,
                    newlyUnlocked: sessionVM.newlyAvailableDecorations,
                    onDismiss: {
                        showingSession = false
                        sessionVM.reset()
                        dismiss()
                    }
                )
            } else {
                PrayerSessionView(viewModel: sessionVM, onDismiss: {
                    showingSession = false
                    sessionVM.reset()
                })
            }
        }
    }

    // MARK: - Screen Router

    @ViewBuilder
    private var currentScreenView: some View {
        switch flowVM.currentScreen {
        case .styleSelection:
            PrayerStyleSelectionView(viewModel: flowVM)
                .transition(.opacity)

        case .actsStep(let category):
            ACTSStepView(viewModel: flowVM, category: category)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(category)

        case .actsReview:
            ACTSReviewView(viewModel: flowVM, onStartSession: startSession)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .singleCategoryPick:
            SinglePrayerFlowView(viewModel: flowVM, onStartSession: startSession)
                .transition(.opacity)

        case .singleEntry(let category):
            SinglePrayerFlowView(viewModel: flowVM, onStartSession: startSession)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(category)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Close button
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
                .foregroundColor(Color.appPrimary)
        }

        // Skip button — only visible on ACTS steps when in conversational entry (not summary)
        ToolbarItem(placement: .primaryAction) {
            if case .actsStep(_) = flowVM.currentScreen, !flowVM.showCollectedSummary {
                Button("Skip") {
                    if flowVM.canSkipCurrentStep {
                        withAnimation {
                            flowVM.skipStep()
                        }
                    } else {
                        showSkipBlockedAlert = true
                    }
                }
                .foregroundColor(flowVM.canSkipCurrentStep ? Color.appTextSecondary : Color.appTextTertiary)
            }
        }

        // Back button
        ToolbarItem(placement: .navigation) {
            if shouldShowBackButton {
                Button {
                    withAnimation { navigateBack() }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }

    private var shouldShowBackButton: Bool {
        switch flowVM.currentScreen {
        case .styleSelection:   return false
        default:                return true
        }
    }

    private func navigateBack() {
        switch flowVM.currentScreen {
        case .actsStep(let category):
            // If showing collected summary, go back to entry form
            if flowVM.showCollectedSummary {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flowVM.showCollectedSummary = false
                }
                return
            }
            // If mid-entry sub-steps, go back one sub-step
            if flowVM.entryStep > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flowVM.goBackEntryStep()
                }
                return
            }
            // Otherwise go back to the previous ACTS step or style selection
            switch category {
            case .adoration:    flowVM.goBackToStyleSelection()
            case .confession:   flowVM.currentScreen = .actsStep(.adoration)
            case .thanksgiving: flowVM.currentScreen = .actsStep(.confession)
            case .supplication: flowVM.currentScreen = .actsStep(.thanksgiving)
            }
        case .actsReview:
            flowVM.currentScreen = .actsStep(.supplication)
        case .singleCategoryPick:
            flowVM.goBackToStyleSelection()
        case .singleEntry(_):
            // If mid-entry sub-steps, go back one sub-step; otherwise go to category pick
            if flowVM.entryStep > 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    flowVM.goBackEntryStep()
                }
            } else {
                flowVM.currentScreen = .singleCategoryPick
                flowVM.clearForm()
            }
        default:
            break
        }
    }

    // MARK: - Start Session

    private func startSession(items: [PrayerItem]) {
        guard !items.isEmpty else { return }
        sessionVM.startSession(items: items)
        showingSession = true
    }
}

#Preview {
    PrayerFlowContainerView()
}
