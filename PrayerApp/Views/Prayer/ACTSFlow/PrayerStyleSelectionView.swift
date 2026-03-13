import SwiftUI

struct PrayerStyleSelectionView: View {
    @ObservedObject var viewModel: ACTSFlowViewModel

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
                        title: "Complete ACTS Prayer",
                        subtitle: "Follow the full Adoration, Confession,\nThanksgiving & Supplication structure",
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

                Spacer(minLength: AppSpacing.xl)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
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
