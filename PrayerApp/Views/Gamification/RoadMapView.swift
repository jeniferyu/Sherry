import SwiftUI

struct RoadMapView: View {
    @StateObject private var viewModel = RoadMapViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.55, blue: 0.35),
                        Color(red: 0.42, green: 0.62, blue: 0.38),
                        Color(red: 0.48, green: 0.68, blue: 0.42),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack {
                        // Decorative ground texture paths
                        groundDecor(w: w, h: h)

                        // Winding path connecting nodes
                        windingPath(w: w, h: h)
                            .stroke(
                                Color(red: 0.75, green: 0.65, blue: 0.50),
                                style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round)
                            )

                        // Inner path (lighter dirt road)
                        windingPath(w: w, h: h)
                            .stroke(
                                Color(red: 0.85, green: 0.78, blue: 0.62),
                                style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                            )

                        // Nodes + stars
                        let positions = nodePositions(w: w, h: h)
                        let days = viewModel.challenge.days

                        ForEach(days) { day in
                            let pos = positions[day.id]

                            // Node circle
                            nodeView(day: day)
                                .position(pos)

                            // Stars on a short arc around the top of the node
                            starsArcAroundNode(count: day.starRating, center: pos)
                        }
                    }
                }

                // Stats banner overlay
                VStack {
                    statsBanner
                    Spacer()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel.fetchRecords() }
    }

    // MARK: - Node Positions (bottom to top, winding)

    private func nodePositions(w: CGFloat, h: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: w * 0.30, y: h * 0.78),
            CGPoint(x: w * 0.70, y: h * 0.52),
            CGPoint(x: w * 0.35, y: h * 0.26),
        ]
    }

    // MARK: - Winding Path

    private func windingPath(w: CGFloat, h: CGFloat) -> Path {
        let pts = nodePositions(w: w, h: h)
        var path = Path()
        guard pts.count >= 3 else { return path }

        path.move(to: CGPoint(x: pts[0].x, y: h * 0.95))

        // Up to node 1
        path.addQuadCurve(
            to: pts[0],
            control: CGPoint(x: pts[0].x - w * 0.05, y: (h * 0.95 + pts[0].y) / 2)
        )

        // Node 1 to Node 2 (curve right)
        path.addCurve(
            to: pts[1],
            control1: CGPoint(x: pts[0].x + w * 0.20, y: pts[0].y - h * 0.08),
            control2: CGPoint(x: pts[1].x - w * 0.10, y: pts[1].y + h * 0.10)
        )

        // Node 2 to Node 3 (curve left)
        path.addCurve(
            to: pts[2],
            control1: CGPoint(x: pts[1].x - w * 0.15, y: pts[1].y - h * 0.08),
            control2: CGPoint(x: pts[2].x + w * 0.15, y: pts[2].y + h * 0.10)
        )

        // Continue upward past node 3
        path.addQuadCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.10),
            control: CGPoint(x: pts[2].x - w * 0.10, y: pts[2].y - h * 0.06)
        )

        return path
    }

    // MARK: - Ground Decoration

    private func groundDecor(w: CGFloat, h: CGFloat) -> some View {
        Canvas { ctx, size in
            let grassDark = Color(red: 0.32, green: 0.50, blue: 0.30)
            let grassLight = Color(red: 0.50, green: 0.72, blue: 0.44)

            // Scattered darker grass patches
            let patches: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (0.10, 0.85, 60, 30),
                (0.80, 0.70, 50, 25),
                (0.15, 0.40, 45, 22),
                (0.85, 0.30, 55, 28),
                (0.60, 0.90, 40, 20),
                (0.25, 0.60, 35, 18),
                (0.75, 0.15, 50, 25),
            ]
            for (px, py, pw, ph) in patches {
                let rect = CGRect(x: w * px - pw / 2, y: h * py - ph / 2, width: pw, height: ph)
                ctx.fill(Path(ellipseIn: rect), with: .color(grassDark.opacity(0.3)))
            }

            // Small bush/shrub circles
            let shrubs: [(CGFloat, CGFloat, CGFloat)] = [
                (0.08, 0.72, 18), (0.92, 0.45, 22), (0.05, 0.25, 16),
                (0.88, 0.82, 20), (0.50, 0.12, 15), (0.15, 0.92, 14),
                (0.78, 0.20, 17), (0.55, 0.65, 13),
            ]
            for (sx, sy, sr) in shrubs {
                let rect = CGRect(x: w * sx - sr, y: h * sy - sr, width: sr * 2, height: sr * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(grassLight.opacity(0.4)))
                let innerRect = rect.insetBy(dx: sr * 0.3, dy: sr * 0.3).offsetBy(dx: -2, dy: -2)
                ctx.fill(Path(ellipseIn: innerRect), with: .color(grassDark.opacity(0.2)))
            }
        }
    }

    // MARK: - Node View

    private func nodeView(day: ChallengeDay) -> some View {
        ZStack {
            // Shadow
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 68, height: 68)
                .offset(y: 4)

            // Outer ring
            Circle()
                .fill(nodeOuterColor(day))
                .frame(width: 64, height: 64)

            // Inner circle
            Circle()
                .fill(nodeInnerColor(day))
                .frame(width: 52, height: 52)

            // Highlight arc
            Circle()
                .trim(from: 0.05, to: 0.35)
                .stroke(Color.white.opacity(0.4), lineWidth: 3)
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(-90))

            // Day number or checkmark
            if day.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(day.dayNumber)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }

    private func nodeOuterColor(_ day: ChallengeDay) -> Color {
        if day.isCompleted { return Color(red: 0.30, green: 0.60, blue: 0.85) }
        if day.isCurrent { return Color.appPrimary }
        return Color(red: 0.60, green: 0.60, blue: 0.60)
    }

    private func nodeInnerColor(_ day: ChallengeDay) -> Color {
        if day.isCompleted { return Color(red: 0.40, green: 0.72, blue: 0.95) }
        if day.isCurrent { return Color.appPrimary.opacity(0.85) }
        return Color(red: 0.72, green: 0.72, blue: 0.72)
    }

    // MARK: - Stars (arc around node)

    /// Places three star slots on a circular arc hugging the top of the node (`center` matches node center).
    private func starsArcAroundNode(count: Int, center: CGPoint) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                nodeStarGlyph(filled: i < count)
                    .offset(starArcOffset(index: i))
            }
        }
        .frame(width: 108, height: 108)
        .position(center)
    }

    private func nodeStarGlyph(filled: Bool) -> some View {
        let goldStar = Color.appAnswered
        let greyStar = Color(red: 0.78, green: 0.76, blue: 0.78)
        return Image(systemName: "star.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(filled ? goldStar : greyStar)
            .shadow(color: filled ? goldStar.opacity(0.75) : .clear, radius: 5, y: 1)
            .shadow(color: filled ? Color.white.opacity(0.55) : .clear, radius: 2, y: -1)
    }

    /// Polar placement on a circle around the node; angles span the upper arc (12 o'clock ± spread).
    private func starArcOffset(index: Int) -> CGSize {
        let radius: CGFloat = 42
        let extraLift: CGFloat = 2
        let mid = -CGFloat.pi / 2
        let span: CGFloat = 1.1
        let start = mid - span / 2
        let angle = start + span * CGFloat(index) / 2
        return CGSize(
            width: radius * cos(angle),
            height: radius * sin(angle) - extraLift
        )
    }

    // MARK: - Game-style Stats Banner
    /// Full-width bar aligned with `MainTabView` custom tab bar (same horizontal inset).

    private var statsBanner: some View {
        HStack(alignment: .center, spacing: 0) {
            avatarBadge

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "leaf.fill", color: .green, value: viewModel.prayedItemCount)

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "sparkles", color: Color.appAnswered, value: viewModel.intercessionPrayedCount)

            Spacer(minLength: AppSpacing.sm)

            statItem(icon: "drop.fill", color: Color(red: 0.40, green: 0.70, blue: 0.95), value: viewModel.dropletCount)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(Color(red: 0.22, green: 0.18, blue: 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(Color(red: 0.45, green: 0.38, blue: 0.28), lineWidth: 2)
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
    }

    private var avatarBadge: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.xpProgress))
                    .stroke(Color.appAnswered, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Image("sheep")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            }

            Text("Lv.\(viewModel.level)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
        }
    }

    private func statItem(icon: String, color: Color, value: Int) -> some View {
        HStack(spacing: 2.5) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .shadow(color: color.opacity(0.5), radius: 3)

            Text(formattedStat(value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(minWidth: 44)
    }

    private func formattedStat(_ value: Int) -> String {
        if value >= 10_000 { return String(format: "%.1fk", Double(value) / 1000.0) }
        return "\(value)"
    }
}

#Preview {
    RoadMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
