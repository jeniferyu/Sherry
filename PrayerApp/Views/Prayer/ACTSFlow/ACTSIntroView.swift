import SwiftUI

/// Short introduction to the ACTS prayer model for the guided flow.
struct ACTSIntroView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("ACTS is a simple way to shape your time with God. Each letter is a movement of the heart—not a rigid checklist.")
                        .font(AppFont.body())
                        .foregroundColor(Color.appTextPrimary)

                    actsSection(
                        letter: "A",
                        name: "Adoration",
                        color: Color.adorationColor,
                        text: "Turn your attention toward God and praise him for who he is—his character, holiness, and love—before you bring requests."
                    )

                    actsSection(
                        letter: "C",
                        name: "Confession",
                        color: Color.confessionColor,
                        text: "Honestly bring sins and regrets to God, agree with him about what is wrong, and receive his forgiveness in Christ."
                    )

                    actsSection(
                        letter: "T",
                        name: "Thanksgiving",
                        color: Color.thanksgivingColor,
                        text: "Thank God for specific gifts, answers, people, and moments—training your heart to notice his kindness."
                    )

                    actsSection(
                        letter: "S",
                        name: "Supplication",
                        color: Color.supplicationColor,
                        text: "Pray for needs—your own and others’—with humility, trusting God’s wisdom and timing."
                    )

                    Text("This app walks you through each part in order. You can take your time; the goal is honest conversation with God, not finishing quickly.")
                        .font(AppFont.subheadline())
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("What is ACTS?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }

    private func actsSection(letter: String, name: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                Text(letter)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(color))
                Text(name)
                    .font(AppFont.title2())
                    .foregroundColor(Color.appTextPrimary)
            }

            Text(text)
                .font(AppFont.body())
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(color.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
    }
}

#Preview {
    ACTSIntroView()
}
