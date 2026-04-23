import SwiftUI

struct AddPrayerView: View {
    /// When `true`, opens the New Prayer form immediately (skips the Prayer Time hub).
    var startWithCaptureForm: Bool = false

    @StateObject private var captureVM = PrayerCaptureViewModel()
    @StateObject private var sessionVM = PrayerSessionViewModel()

    @State private var showingCaptureForm = false
    @State private var showingSession = false
    @State private var showingPrayerFlow = false
    @State private var activeSession: PrayerSession?
    @State private var pendingSessionStart = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if startWithCaptureForm {
                captureFormContent
            } else {
                prayerTimeHub
            }
        }
        .sheet(isPresented: $showingCaptureForm, onDismiss: {
            if pendingSessionStart {
                pendingSessionStart = false
                showingSession = true
            }
        }) {
            PrayerCaptureFormView(
                viewModel: captureVM,
                onSaveForLater: {
                    showingCaptureForm = false
                    dismiss()
                },
                onPrayNow: { session in
                    activeSession = session
                    sessionVM.startSession(items: session.itemList)
                    pendingSessionStart = true
                    showingCaptureForm = false
                }
            )
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
        .fullScreenCover(isPresented: $showingPrayerFlow) {
            PrayerFlowContainerView()
        }
    }

    // MARK: - Prayer Time hub (FAB & default entry)

    private var prayerTimeHub: some View {
        NavigationStack {
            ZStack {
                sessionBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    customNavBar

                    hero
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)

                    VStack(spacing: AppSpacing.md) {
                        gameActionCard(
                            title: "Start Praying Now",
                            accent: Color.thanksgivingColor,
                            iconContent: {
                                Image("prayingHands")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 34, height: 34)
                                    .foregroundColor(Color.thanksgivingColor)
                            },
                            action: { showingPrayerFlow = true }
                        )

                        gameActionCard(
                            title: "Add a Prayer Item",
                            accent: Color.adorationColor,
                            iconContent: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(Color.adorationColor)
                            },
                            action: { showingCaptureForm = true }
                        )
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - New Prayer (no Prayer Time hub)

    private var captureFormContent: some View {
        PrayerCaptureFormView(
            viewModel: captureVM,
            onSaveForLater: { dismiss() },
            onPrayNow: { session in
                activeSession = session
                sessionVM.startSession(items: session.itemList)
                showingSession = true
            }
        )
    }

    // MARK: - Nav Bar

    private var customNavBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: AppIcons.close)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 12, y: 6)

                Image("prayingHands")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.white)
            }

            Text("Prayer Time")
                .font(AppFont.largeTitle())
                .foregroundColor(Color.appTextPrimary)

            Text("What would you like to say to God?")
                .font(AppFont.body())
                .foregroundColor(Color.appTextSecondary)
        }
    }

    // MARK: - Action Card

    /// Vibrant action card styled like a quest tile: icon badge, title, chevron.
    private func gameActionCard<IconContent: View>(
        title: String,
        accent: Color,
        @ViewBuilder iconContent: () -> IconContent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(accent.opacity(0.18))
                    iconContent()
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 32, height: 32)
                .shadow(color: accent.opacity(0.4), radius: 5, y: 2)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background

    private var sessionBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 0.96),
                Color.appBackground,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    AddPrayerView()
}
