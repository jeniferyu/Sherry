import SwiftUI

struct PrayerDetailView: View {
    let prayer: PrayerItem
    var onStatusChange: ((PrayerStatus) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                // Hero header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        CategoryBadge(category: prayer.categoryEnum)
                        if prayer.isIntercessory {
                            HStack(spacing: AppSpacing.xxs) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption)
                                Text("Intercession")
                                    .font(AppFont.caption())
                            }
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

                // Stats
                HStack(spacing: AppSpacing.md) {
                    metaItem(icon: "clock", label: "Created", value: prayer.formattedCreatedDate)
                    if let lastPrayed = prayer.formattedLastPrayedDate {
                        metaItem(icon: "checkmark.circle", label: "Last Prayed", value: lastPrayed)
                    }
                    metaItem(icon: "hands.sparkles", label: "Times Prayed", value: "\(prayer.prayedCount)")
                }
                .padding(.horizontal, AppSpacing.lg)

                // Tags
                if !prayer.tagList.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Tags")
                            .font(AppFont.caption())
                            .foregroundColor(Color.appTextSecondary)
                        FlowLayout(spacing: AppSpacing.xs) {
                            ForEach(prayer.tagList, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(AppFont.caption())
                                    .foregroundColor(Color.appTextTertiary)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xxs)
                                    .background(Color.appSurfaceSecond)
                                    .cornerRadius(AppRadius.full)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                // Status actions
                if let onStatusChange {
                    VStack(spacing: AppSpacing.sm) {
                        if prayer.statusEnum != .answered {
                            Button {
                                onStatusChange(.answered)
                                dismiss()
                            } label: {
                                Label("Mark as Answered", systemImage: AppIcons.markAnswered)
                            }
                            .primaryButtonStyle()
                        }

                        if prayer.statusEnum != .archived {
                            Button {
                                onStatusChange(.archived)
                                dismiss()
                            } label: {
                                Label("Archive", systemImage: AppIcons.archive)
                            }
                            .secondaryButtonStyle()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Prayer Detail")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Simple flow layout for tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
