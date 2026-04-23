import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    var isAssetImage: Bool = false
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.15), Color.appAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                if isAssetImage {
                    Image(iconName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(Color.appPrimary)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(Color.appPrimary)
                }
            }

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.title2())
                    .fontWeight(.bold)
                    .foregroundColor(Color.appTextPrimary)

                Text(message)
                    .font(AppFont.body())
                    .foregroundColor(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .primaryButtonStyle()
                .frame(width: 220)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}

#Preview {
    EmptyStateView(
        iconName: "prayingHands",
        isAssetImage: true,
        title: "No Prayers Yet",
        message: "Tap the + button to add your first prayer.",
        actionTitle: "Add Prayer",
        action: {}
    )
}
