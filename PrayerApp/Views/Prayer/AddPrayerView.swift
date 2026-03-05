import SwiftUI

struct AddPrayerView: View {
    @StateObject private var captureVM = PrayerCaptureViewModel()
    @StateObject private var sessionVM = PrayerSessionViewModel()

    @State private var showingCaptureForm = false
    @State private var showingSession = false
    @State private var activeSession: PrayerSession?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.appPrimary)
                        .padding(.top, AppSpacing.xxl)

                    Text("Prayer Time")
                        .font(AppFont.largeTitle())
                        .foregroundColor(Color.appTextPrimary)

                    Text("What would you like to do?")
                        .font(AppFont.body())
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.bottom, AppSpacing.xxl)

                // Action Cards
                VStack(spacing: AppSpacing.md) {
                    actionCard(
                        icon: "hands.sparkles.fill",
                        title: "Start Praying Now",
                        subtitle: "Begin a focused prayer session with your saved items",
                        color: Color.appPrimary
                    ) {
                        showingSession = true
                    }

                    actionCard(
                        icon: "plus.circle.fill",
                        title: "Add a Prayer Item",
                        subtitle: "Write down a new prayer to save or pray immediately",
                        color: Color.appAccent
                    ) {
                        showingCaptureForm = true
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
        .sheet(isPresented: $showingCaptureForm) {
            PrayerCaptureFormView(
                viewModel: captureVM,
                onSaveForLater: { showingCaptureForm = false },
                onPrayNow: { session in
                    showingCaptureForm = false
                    activeSession = session
                    sessionVM.startSession(items: session.itemList)
                    showingSession = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingSession) {
            if sessionVM.isFinished, let finished = sessionVM.finishedSession {
                SessionCompleteView(
                    session: finished,
                    newlyUnlocked: sessionVM.newlyUnlockedDecorations,
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

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.12))
                    .cornerRadius(AppRadius.md)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppFont.headline())
                        .foregroundColor(Color.appTextPrimary)
                    Text(subtitle)
                        .font(AppFont.subheadline())
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.leading)
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
}

#Preview {
    AddPrayerView()
}
