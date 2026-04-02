import SwiftUI

struct RoadMapView: View {
    @StateObject private var viewModel = RoadMapViewModel()

    private let mapHeight: CGFloat = 650
    private let nodeSpacingY: CGFloat = 140

    var body: some View {
        NavigationStack {
            ZStack {
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

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // --- TOP: Choose Your Next Challenge ---
                            challengePickerSection
                                .id("top")

                            roadSectionDivider(topPadding: 20, bottomPadding: 0)

                            // --- MIDDLE: Current Challenge Map ---
                            currentChallengeMap
                                .id("map")

                            roadSectionDivider(topPadding: 0, bottomPadding: 20)

                            // --- BOTTOM: Progress Summary ---
                            progressSummarySection
                                .id("bottom")
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            proxy.scrollTo("map", anchor: .center)
                        }
                    }
                }

                // Stats banner pinned at top
                VStack {
                    GameStatsBannerView(
                        level: viewModel.level,
                        xpProgress: viewModel.xpProgress,
                        prayedItemCount: viewModel.prayedItemCount,
                        intercessionPrayedCount: viewModel.intercessionPrayedCount,
                        dropletCount: viewModel.dropletCount
                    )
                    Spacer()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel.fetchRecords() }
    }

    // MARK: - Challenge Picker (Top Section)

    private var challengePickerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer().frame(height: 80) //80

            Text("UP NEXT")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.12)))

            Text("Choose Your Next Challenge")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if viewModel.currentChallengeInProgress {
                Text("Complete your current challenge to unlock choices")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.challengeTiers) { tier in
                    challengeTierCard(tier)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private func challengeTierCard(_ tier: ChallengeTier) -> some View {
        Button {
            viewModel.selectChallenge(tier.totalDays)
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(tier.isUnlocked
                              ? Color.appPrimary.opacity(0.5)
                              : Color(red: 0.60, green: 0.60, blue: 0.60))
                        .frame(width: 44, height: 44)

                    if tier.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else if !tier.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("\(tier.totalDays)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(tier.isUnlocked ? .white : .white.opacity(0.45))

                    Text(tierSubtitle(tier))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(tier.isUnlocked ? .white.opacity(0.7) : .white.opacity(0.3))
                }

                Spacer()

                if tier.isCompleted {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.appAnswered)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
            )
        }
        .disabled(!tier.isUnlocked)
        .buttonStyle(.plain)
    }

    private func tierSubtitle(_ tier: ChallengeTier) -> String {
        if tier.isCompleted && tier.isUnlocked { return "Completed ✓ — Tap to repeat" }
        if tier.isCompleted { return "Completed ✓" }
        if !tier.isUnlocked && viewModel.currentChallengeInProgress {
            return "Finish current challenge first"
        }
        if !tier.isUnlocked { return "Complete previous challenge to unlock" }
        return "Tap to start this challenge"
    }

    // MARK: - Current Challenge Map (Middle Section)

    private var dynamicMapHeight: CGFloat {
        let count = max(viewModel.challenge.days.count, 3)
        return CGFloat(count) * nodeSpacingY + 315
    }

    private var currentChallengeMap: some View {
        ZStack {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    groundDecor(w: w, h: h)

                    dynamicWindingPath(w: w, h: h)
                        .stroke(
                            Color(red: 0.75, green: 0.65, blue: 0.50),
                            style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round)
                        )

                    dynamicWindingPath(w: w, h: h)
                        .stroke(
                            Color(red: 0.85, green: 0.78, blue: 0.62),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                        )

                    let positions = dynamicNodePositions(w: w, h: h)
                    let days = viewModel.challenge.days

                    ForEach(days) { day in
                        if day.id < positions.count {
                            let pos = positions[day.id]

                            nodeView(day: day)
                                .position(pos)

                            starsArcAroundNode(count: day.starRating, center: pos)
                        }
                    }
                }
            }
        }
        .frame(height: dynamicMapHeight)
        .clipped()
    }

    // MARK: - Dynamic Node Positions

    private func dynamicNodePositions(w: CGFloat, h: CGFloat) -> [CGPoint] {
        let count = viewModel.challenge.days.count
        guard count > 0 else { return [] }

        var positions: [CGPoint] = []
        let topPadding: CGFloat = 170
        let bottomPadding: CGFloat = 150

        for i in 0..<count {
            let progress = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
            let y = h - bottomPadding - progress * (h - topPadding - bottomPadding)
            let xCenter = w * 0.5
            let xAmplitude = w * 0.20
            let x = xCenter + xAmplitude * (i % 2 == 0 ? -1 : 1)
            positions.append(CGPoint(x: x, y: y))
        }
        return positions
    }

    // MARK: - Dynamic Winding Path

    /// Handle length as a fraction of segment length (higher = rounder bends near nodes).
    private let roadCurveHandleFraction: CGFloat = 0.42
    private let roadCurveHandleMax: CGFloat = 100

    private func dynamicWindingPath(w: CGFloat, h: CGFloat) -> Path {
        let pts = dynamicNodePositions(w: w, h: h)
        var path = Path()
        guard !pts.isEmpty else { return path }

        let center = w * 0.5
        let entry = CGPoint(x: center, y: h + 30)
        let exit = CGPoint(x: center, y: -30)
        var waypoints: [CGPoint] = [entry] + pts + [exit]

        path.move(to: waypoints[0])

        let n = waypoints.count
        for i in 0..<(n - 1) {
            let p0 = waypoints[i]
            let p3 = waypoints[i + 1]
            let prev = i > 0 ? waypoints[i - 1] : nil
            let next = i + 2 < n ? waypoints[i + 2] : nil
            let (c1, c2) = smoothRoadControlPoints(
                from: p0,
                to: p3,
                previous: prev,
                next: next
            )
            path.addCurve(to: p3, control1: c1, control2: c2)
        }

        return path
    }

    /// Cubic Bézier controls from tangents implied by neighbors (C¹-style smoothness at nodes).
    private func smoothRoadControlPoints(
        from p0: CGPoint,
        to p3: CGPoint,
        previous: CGPoint?,
        next: CGPoint?
    ) -> (CGPoint, CGPoint) {
        let dx = p3.x - p0.x
        let dy = p3.y - p0.y
        let dist = max(hypot(dx, dy), 1)
        let handle = min(dist * roadCurveHandleFraction, roadCurveHandleMax)

        let m0 = CGPoint(x: p3.x - (previous?.x ?? p0.x), y: p3.y - (previous?.y ?? p0.y))
        let m1 = CGPoint(x: (next?.x ?? p3.x) - p0.x, y: (next?.y ?? p3.y) - p0.y)

        let len0 = max(hypot(m0.x, m0.y), 0.001)
        let len1 = max(hypot(m1.x, m1.y), 0.001)

        let c1 = CGPoint(x: p0.x + m0.x / len0 * handle, y: p0.y + m0.y / len0 * handle)
        let c2 = CGPoint(x: p3.x - m1.x / len1 * handle, y: p3.y - m1.y / len1 * handle)
        return (c1, c2)
    }

    // MARK: - Ground Decoration

    private func groundDecor(w: CGFloat, h: CGFloat) -> some View {
        Canvas { ctx, size in
            let grassDark = Color(red: 0.32, green: 0.50, blue: 0.30)
            let grassLight = Color(red: 0.50, green: 0.72, blue: 0.44)

            let patches: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (0.10, 0.85, 60, 30), (0.80, 0.70, 50, 25),
                (0.15, 0.40, 45, 22), (0.85, 0.30, 55, 28),
                (0.60, 0.90, 40, 20), (0.25, 0.60, 35, 18),
                (0.75, 0.15, 50, 25),
            ]
            for (px, py, pw, ph) in patches {
                let rect = CGRect(x: w * px - pw / 2, y: h * py - ph / 2, width: pw, height: ph)
                ctx.fill(Path(ellipseIn: rect), with: .color(grassDark.opacity(0.3)))
            }

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
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: 68, height: 68)
                .offset(y: 4)

            Circle()
                .fill(nodeOuterColor(day))
                .frame(width: 64, height: 64)

            Circle()
                .fill(nodeInnerColor(day))
                .frame(width: 52, height: 52)

            Circle()
                .trim(from: 0.05, to: 0.35)
                .stroke(Color.white.opacity(0.4), lineWidth: 3)
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(-90))

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

    // MARK: - Road Section Divider

    /// Full-width horizontal accent line separating the map from adjacent sections.
    /// Padding pushes spacing toward the section side, keeping the line flush with the map.
    private func roadSectionDivider(topPadding: CGFloat, bottomPadding: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(height: 1.5)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
    }

    // MARK: - Progress Summary (Bottom Section)

    private var progressSummarySection: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("YOUR JOURNEY")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.12)))

            VStack(spacing: AppSpacing.md) {
                summaryStatRow(icon: "star.fill", color: .appAnswered,
                               label: "Stars Collected",
                               value: "\(viewModel.totalStarsEarned)")

                summaryStatRow(icon: "checkmark.seal.fill", color: Color(red: 0.40, green: 0.72, blue: 0.95),
                               label: "Challenges Completed",
                               value: "\(viewModel.totalChallengesCompleted)")

                summaryStatRow(icon: "calendar", color: .green,
                               label: "Total Prayer Days",
                               value: "\(viewModel.totalPrayerDays)")

                summaryStatRow(icon: "flame.fill", color: .orange,
                               label: "Current Streak",
                               value: "\(viewModel.streakCount) days")
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.lg)

            Text("Keep praying — your journey continues!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, AppSpacing.sm)

            Spacer().frame(height: 100)
        }
        .padding(.top, AppSpacing.lg)
    }

    private func summaryStatRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color.opacity(0.15)))

            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    RoadMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
