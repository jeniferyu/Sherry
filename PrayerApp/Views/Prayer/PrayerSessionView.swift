import SwiftUI

struct PrayerSessionView: View {
    @ObservedObject var viewModel: PrayerSessionViewModel
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            sessionBackground
                .ignoresSafeArea()

            if viewModel.isFinished, let session = viewModel.finishedSession {
                SessionCompleteView(
                    session: session,
                    newlyUnlocked: viewModel.newlyAvailableDecorations,
                    onDismiss: onDismiss
                )
                .transition(.opacity.combined(with: .scale))
            } else {
                sessionContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isFinished)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var sessionContent: some View {
        VStack(spacing: 0) {
            navBar
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.sm)

            progressBar
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.md)

            Spacer()

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

            actionButtons
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: onDismiss) {
                Image(systemName: AppIcons.close)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white))
                    .overlay(
                        Circle().strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            }

            Spacer()

            // Timer pill — game-style, matches the stats banner.
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(timerString)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color.appGameDark)
            )
            .overlay(
                Capsule().strokeBorder(Color.appGameDarkStroke, lineWidth: 1.5)
            )

            Spacer()

            // Progress pill — gold with star icon, echoing XP badges.
            GoldCountPill(
                icon: "sparkles",
                text: "\(viewModel.prayedItems.count)/\(viewModel.sessionItems.count)"
            )
            .scaleEffect(1.15)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white)
                    .overlay(
                        Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appGameXPFill, Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * CGFloat(viewModel.progress)))
                    .shadow(color: Color.appGameXPFill.opacity(0.4), radius: 6, y: 2)
            }
        }
        .frame(height: 12)
        .animation(.easeInOut(duration: 0.25), value: viewModel.progress)
    }

    // MARK: - Current Prayer Card

    private func currentPrayerCard(_ item: PrayerItem) -> some View {
        let color = item.categoryEnum.fallbackColor
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                categoryAvatar(for: item)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.categoryEnum.displayName.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(Color.white.opacity(0.8))

                    if item.isIntercessory, let group = item.intercessoryGroupEnum {
                        HStack(spacing: 4) {
                            Image(systemName: group.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text("For \(group.displayName)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color.white.opacity(0.9))
                    }
                }

                Spacer()
            }

            Text(item.title ?? "")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(AppFont.body())
                    .foregroundColor(Color.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .overlay(Color.white.opacity(0.25))

            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.7))
                Text("Take a moment to bring this prayer before God...")
                    .font(AppFont.subheadline())
                    .italic()
                    .foregroundColor(Color.white.opacity(0.85))
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameCardStyle(color: color)
    }

    private func categoryAvatar(for item: PrayerItem) -> some View {
        let cat = item.categoryEnum
        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            if cat.isAssetIcon {
                Image(cat.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(cat.fallbackColor)
            } else {
                Image(systemName: cat.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(cat.fallbackColor)
            }
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - Action Buttons

    /// One prayer in the session — nothing to skip to; only **Finish** below **Prayed**.
    private var isSingleItemSession: Bool {
        viewModel.sessionItems.count == 1
    }

    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            if viewModel.currentItem != nil {
                Button {
                    withAnimation {
                        if let item = viewModel.currentItem {
                            viewModel.markItemPrayed(item)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text("Prayed")
                    }
                }
                .gameCTAButtonStyle(color: .thanksgivingColor)
            }

            if isSingleItemSession {
                singleItemFinishButton
            } else {
                HStack(spacing: AppSpacing.sm) {
                    secondaryActionButton(
                        label: "Skip",
                        systemImage: "arrow.right.circle.fill",
                        tint: Color.appTextSecondary
                    ) {
                        withAnimation { viewModel.skipItem() }
                    }

                    secondaryActionButton(
                        label: "Finish",
                        systemImage: "checkmark.seal.fill",
                        tint: Color.appPrimary
                    ) {
                        _ = viewModel.finishSession()
                    }
                }
            }
        }
    }

    /// Full-width **Finish** for single-prayer sessions (replaces the Skip + Finish row).
    private var singleItemFinishButton: some View {
        Button {
            _ = viewModel.finishSession()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Finish")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: Color.appPrimary.opacity(0.1), radius: 12, y: 4)
            .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func secondaryActionButton(
        label: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var timerString: String {
        let minutes = Int(viewModel.elapsedTime) / 60
        let seconds = Int(viewModel.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

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
