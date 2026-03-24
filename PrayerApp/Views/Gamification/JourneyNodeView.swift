import SwiftUI

struct JourneyNodeView: View {
    let node: JourneyNode
    let onTap: ((DailyRecord) -> Void)?

    private let diameter: CGFloat = 56

    var body: some View {
        Button {
            if let record = node.record {
                onTap?(record)
            }
        } label: {
            ZStack {
                nodeBackground
                nodeIcon
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isTappable)
    }

    // MARK: - Subviews

    private var nodeBackground: some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .shadow(color: shadowColor, radius: 4, y: 2)

            if node.state == .missed {
                Circle()
                    .stroke(Color.appTextTertiary.opacity(0.5), lineWidth: 2)
            } else if node.state == .today {
                Circle()
                    .stroke(Color.appAccent, lineWidth: 3)
            }
        }
    }

    private var nodeIcon: some View {
        Group {
            switch node.state {
            case .completed:
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            case .answered:
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            case .missed:
                Text(dayLabel)
                    .font(AppFont.caption())
                    .foregroundColor(Color.appTextTertiary)
            case .today:
                Text(dayLabel)
                    .font(AppFont.headline())
                    .foregroundColor(Color.appTextPrimary)
            case .locked:
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appTextTertiary)
            }
        }
    }

    // MARK: - Helpers

    private var isTappable: Bool {
        switch node.state {
        case .completed, .answered: return true
        case .today: return node.record != nil
        case .missed, .locked: return false
        }
    }

    private var fillColor: Color {
        switch node.state {
        case .completed: return Color.appPrimary
        case .answered:  return Color.appAnswered
        case .missed:    return Color.appSurface.opacity(0.85)
        case .today:     return Color.appSurface
        case .locked:    return Color(white: 0.80).opacity(0.80)
        }
    }

    private var shadowColor: Color {
        switch node.state {
        case .completed: return Color.appPrimary.opacity(0.40)
        case .answered:  return Color.appAnswered.opacity(0.40)
        case .today:     return Color.appAccent.opacity(0.30)
        default:         return Color.black.opacity(0.12)
        }
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: node.date)
    }
}
