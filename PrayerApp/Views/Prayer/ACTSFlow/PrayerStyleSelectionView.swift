import SwiftUI

struct PrayerStyleSelectionView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel
    @State private var showingACTSIntro = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero
                VStack(spacing: AppSpacing.xs) {
                    Image("prayingHands")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(Color.appPrimary)
                        .padding(.top, AppSpacing.xxl)

                    Text("How would you like\nto pray today?")
                        .font(AppFont.largeTitle())
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppSpacing.xl)

                // Cards
                VStack(spacing: AppSpacing.md) {
                    styleCard(
                        icon: "list.bullet.rectangle.portrait",
                        iconColor: Color.appPrimary,
                        title: "ACTS prayer",
                        subtitle: "Begin a guided ACTS prayer session",
                        action: { viewModel.selectACTS() }
                    )

                    styleCard(
                        icon: "bubble.left.fill",
                        iconColor: Color.appAccent,
                        title: "Single Prayer",
                        subtitle: "Pray one specific prayer to God right now",
                        action: { viewModel.selectSingle() }
                    )
                }
                .padding(.horizontal, AppSpacing.lg)

                actsInfoLink
                    .padding(.top, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.lg)

                Spacer(minLength: AppSpacing.md)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showingACTSIntro) {
            ACTSIntroView()
        }
    }

    /// Small, clearly tappable affordance at the bottom of the style screen.
    private var actsInfoLink: some View {
        Button {
            showingACTSIntro = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 15, weight: .semibold))
                Text("What is ACTS?")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color.appPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .background(
                Capsule()
                    .fill(Color.appPrimary.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.appPrimary.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens an introduction to ACTS prayer")
    }

    private func styleCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
                    .frame(width: 60, height: 60)
                    .background(iconColor.opacity(0.12))
                    .cornerRadius(AppRadius.md)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppFont.headline())
                        .foregroundColor(Color.appTextPrimary)
                    Text(subtitle)
                        .font(AppFont.subheadline())
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
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
    PrayerStyleSelectionView(viewModel: ACTSFlowViewModel())
}
