import SwiftUI

struct IntercessoryDetailView: View {
    @ObservedObject var prayer: PrayerItem
    var onMarkAnswered: (() -> Void)?
    var onArchive: (() -> Void)?
    var onAddToToday: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    /// Recomputed each body pass so the button reflects tracker state on next open.
    private var isAddedToTodaySession: Bool {
        TodaySessionTracker.isAddedToday(prayer.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                // Header card
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        if let group = prayer.intercessoryGroupEnum {
                            HStack(spacing: AppSpacing.xxs) {
                                Image(systemName: group.iconName)
                                Text(group.displayName)
                            }
                            .font(AppFont.caption())
                            .foregroundColor(Color.appPrimary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(Color.appPrimary.opacity(0.12))
                            .cornerRadius(AppRadius.full)
                        }
                        Spacer()
                        StatusIndicator(status: prayer.statusEnum)
                    }

                    Text(prayer.title ?? "")
                        .font(AppFont.title())
                        .foregroundColor(Color.appTextPrimary)

                    if let content = prayer.content, !content.isEmpty {
                        Text(content)
                            .font(AppFont.body())
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
                .padding(AppSpacing.lg)
                .cardStyle()
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)

                // Stats row
                HStack(spacing: AppSpacing.md) {
                    metaItem(icon: "clock", label: "Added", value: prayer.formattedCreatedDate)
                    if let lastPrayed = prayer.formattedLastPrayedDate {
                        metaItem(icon: AppIcons.statLastPrayed, label: "Last Prayed", value: lastPrayed)
                    }
                    metaItem(icon: AppIcons.statTimesPrayed, label: "Times Prayed", value: "\(prayer.prayedCount)")
                }
                .padding(.horizontal, AppSpacing.lg)

                // Session history
                if !prayer.sessionList.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Prayer History")
                            .font(AppFont.headline())
                            .foregroundColor(Color.appTextPrimary)
                            .padding(.horizontal, AppSpacing.lg)

                        ForEach(prayer.sessionList.prefix(5)) { session in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(session.formattedDate)
                                    .font(AppFont.subheadline())
                                    .foregroundColor(Color.appTextSecondary)
                                Spacer()
                                Text(session.formattedDuration)
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.appTextTertiary)
                            }
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }

                // Action buttons
                VStack(spacing: AppSpacing.sm) {
                    if prayer.statusEnum != .answered {
                        Button {
                            onMarkAnswered?()
                            dismiss()
                        } label: {
                            Label("Mark as Answered \u{2728}", systemImage: AppIcons.markAnswered)
                        }
                        .primaryButtonStyle()

                        Button {
                            onAddToToday?()
                            dismiss()
                        } label: {
                            Label(
                                isAddedToTodaySession
                                    ? "Already Added to Today's Session"
                                    : "Add to Today's Session",
                                systemImage: isAddedToTodaySession ? "checkmark.circle.fill" : AppIcons.addToToday
                            )
                        }
                        .secondaryButtonStyle()
                        .disabled(isAddedToTodaySession)
                    }

                    if prayer.statusEnum != .archived, prayer.statusEnum != .answered {
                        Button {
                            onArchive?()
                            dismiss()
                        } label: {
                            Label("Archive", systemImage: AppIcons.archive)
                        }
                        .secondaryButtonStyle()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Intercession Detail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarPlainBackButton()
    }

    private func metaItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.appPrimary)
            Text(value)
                .font(AppFont.caption())
                .fontWeight(.semibold)
                .foregroundColor(Color.appTextPrimary)
            Text(label)
                .font(AppFont.caption2())
                .foregroundColor(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.sm)
        .cardStyle()
    }
}
