import SwiftUI

struct DayDetailSheet: View {
    let record: DailyRecord
    let sessions: [PrayerSession]
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: AppIcons.footprint)
                            .font(.system(size: 40))
                            .foregroundColor(Color.appPrimary)

                        Text(record.formattedDate)
                            .font(AppFont.title2())
                            .foregroundColor(Color.appTextPrimary)
                    }
                    .padding(.top, AppSpacing.lg)

                    // Stats
                    HStack(spacing: AppSpacing.md) {
                        statCard(icon: "figure.walk.motion", value: "\(record.personalSessionCount)", label: "Sessions")
                        statCard(icon: "person.2.fill", value: "\(record.intercessoryItemCount)", label: "Intercessions")
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Sessions list
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Sessions")
                                .font(AppFont.headline())
                                .foregroundColor(Color.appTextPrimary)
                                .padding(.horizontal, AppSpacing.lg)

                            ForEach(sessions) { session in
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(Color.appPrimary)
                                        Text(session.formattedDuration)
                                            .font(AppFont.subheadline())
                                            .foregroundColor(Color.appTextPrimary)
                                        Spacer()
                                        Text("\(session.itemList.count) prayers")
                                            .font(AppFont.caption())
                                            .foregroundColor(Color.appTextSecondary)
                                    }

                                    ForEach(session.itemList.prefix(3)) { item in
                                        HStack(spacing: AppSpacing.xs) {
                                            CategoryBadge(category: item.categoryEnum, compact: true)
                                            Text(item.title ?? "")
                                                .font(AppFont.caption())
                                                .foregroundColor(Color.appTextSecondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    if session.itemList.count > 3 {
                                        Text("+ \(session.itemList.count - 3) more...")
                                            .font(AppFont.caption2())
                                            .foregroundColor(Color.appTextTertiary)
                                    }
                                }
                                .padding(AppSpacing.md)
                                .cardStyle()
                                .padding(.horizontal, AppSpacing.lg)
                            }
                        }
                    }
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Day Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color.appPrimary)
            Text(value)
                .font(AppFont.title2())
                .foregroundColor(Color.appTextPrimary)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .cardStyle()
    }
}
