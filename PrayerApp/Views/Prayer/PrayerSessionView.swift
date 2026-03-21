import SwiftUI

struct PrayerSessionView: View {
    @ObservedObject var viewModel: PrayerSessionViewModel
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if viewModel.isFinished, let session = viewModel.finishedSession {
                SessionCompleteView(
                    session: session,
                    newlyUnlocked: viewModel.newlyUnlockedDecorations,
                    onDismiss: onDismiss
                )
                .transition(.opacity.combined(with: .scale))
            } else {
                sessionContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isFinished)
    }

    @ViewBuilder
    private var sessionContent: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: AppIcons.close)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.appTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.appSurfaceSecond)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }

                Spacer()

                Text(timerString)
                    .font(AppFont.headline())
                    .foregroundColor(Color.appTextSecondary)
                    .monospacedDigit()

                Spacer()

                // Progress badge
                Text("\(viewModel.prayedItems.count)/\(viewModel.sessionItems.count)")
                    .font(AppFont.caption())
                    .foregroundColor(Color.appPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(Color.appPrimary.opacity(0.12))
                    .cornerRadius(AppRadius.full)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurfaceSecond)
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.appPrimary)
                        .frame(width: geo.size.width * viewModel.progress, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, AppSpacing.lg)
            .animation(.easeInOut, value: viewModel.progress)

            Spacer()

            // Current prayer card
            if let item = viewModel.currentItem {
                currentPrayerCard(item)
                    .padding(.horizontal, AppSpacing.lg)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(item.objectID)
            }

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.sm) {
                if let item = viewModel.currentItem {
                    Button {
                        withAnimation {
                            viewModel.markItemPrayed(item)
                        }
                    } label: {
                        Label("Prayed", systemImage: "checkmark.circle.fill")
                    }
                    .primaryButtonStyle()
                    .padding(.horizontal, AppSpacing.lg)
                }

                HStack(spacing: AppSpacing.md) {
                    Button {
                        withAnimation { viewModel.skipItem() }
                    } label: {
                        Label("Skip", systemImage: "arrow.right.circle")
                            .font(AppFont.subheadline())
                            .foregroundColor(Color.appTextSecondary)
                    }

                    Spacer()

                    Button {
                        _ = viewModel.finishSession()
                    } label: {
                        Label("Finish Session", systemImage: "checkmark.seal")
                            .font(AppFont.subheadline())
                            .foregroundColor(Color.appPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private func currentPrayerCard(_ item: PrayerItem) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Category
            CategoryBadge(category: item.categoryEnum)

            // Title
            Text(item.title ?? "")
                .font(AppFont.title())
                .foregroundColor(Color.appTextPrimary)

            // Content
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(AppFont.body())
                    .foregroundColor(Color.appTextSecondary)
            }

            if item.isIntercessory, let group = item.intercessoryGroupEnum {
                HStack {
                    Image(systemName: group.iconName)
                    Text("Praying for \(group.displayName)")
                }
                .font(AppFont.subheadline())
                .foregroundColor(Color.appTextSecondary)
            }

            Divider()

            // Prompt text
            Text("Take a moment to bring this prayer before God...")
                .font(AppFont.subheadline())
                .foregroundColor(Color.appTextTertiary)
                .italic()
        }
        .padding(AppSpacing.xl)
        .cardStyle()
    }

    private var timerString: String {
        let minutes = Int(viewModel.elapsedTime) / 60
        let seconds = Int(viewModel.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
