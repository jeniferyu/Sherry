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
            if isAssetImage {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundColor(Color.appTextTertiary)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(Color.appTextTertiary)
            }

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.title2())
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
                .frame(width: 200)
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
