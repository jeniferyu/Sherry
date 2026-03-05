import SwiftUI

struct StatusIndicator: View {
    let status: PrayerStatus
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: status.iconName)
                .font(.system(size: 11))
            if showLabel {
                Text(status.displayName)
                    .font(AppFont.caption())
            }
        }
        .foregroundColor(status.color)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
        .background(status.color.opacity(0.12))
        .cornerRadius(AppRadius.full)
    }
}

#Preview {
    VStack(spacing: 8) {
        StatusIndicator(status: .ongoing)
        StatusIndicator(status: .prayed)
        StatusIndicator(status: .answered)
        StatusIndicator(status: .archived)
    }
    .padding()
}
