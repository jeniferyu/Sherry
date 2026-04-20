import SwiftUI
import UIKit

struct RoadMapView: View {
    @StateObject private var viewModel = RoadMapViewModel()

    private let nodeSpacingY: CGFloat = 140
    /// Desired number of nodes visible per screen height on multi-day challenges.
    private let nodesPerScreen: CGFloat = 3.0

    /// 0 = top (challenge picker), 1 = main (road map), 2 = bottom (summary)
    @State private var currentPage: Int = 1
    @State private var dragOffset: CGFloat = 0
    private let snapThreshold: CGFloat = 50

    /// How far the map must be dragged beyond its top/bottom boundary before the
    /// outer section transition takes over.
    private let mapBoundaryDragTrigger: CGFloat = 44

    /// Soft mint panel behind “Choose Your Next Challenge” and “Your Journey” (lighter than the main green).
    private var challengesLightSectionBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.91, green: 0.97, blue: 0.93),
                Color(red: 0.85, green: 0.95, blue: 0.89),
                Color(red: 0.80, green: 0.93, blue: 0.86),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private let challengesAccentGreen = Color(red: 0.28, green: 0.48, blue: 0.32)

    /// Distance from node center upward to the arrow image center (arrow points down at the node).
    private let currentStepArrowOffsetFromNodeCenter: CGFloat = 76

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let pageHeight = geo.size.height
                // Each page slot = pageHeight + one 1.5pt divider; stride must match
                // so page 1 and page 2 align precisely to viewport boundaries.
                let pageStride = pageHeight + 1.5

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

                    let mHeight = mapContentHeight(pageHeight: pageHeight)

                    VStack(spacing: 0) {
                        // Page 0: Top
                        challengePickerPage(height: pageHeight)
                            .frame(height: pageHeight)

                        roadSectionDivider(topPadding: 0, bottomPadding: 0)

                        // Page 1: Main map
                        mainMapPage(height: pageHeight, mapHeight: mHeight)
                            .frame(height: pageHeight)

                        roadSectionDivider(topPadding: 0, bottomPadding: 0)

                        // Page 2: Bottom
                        progressSummaryPage(height: pageHeight)
                            .frame(height: pageHeight)
                    }
                    .offset(y: -CGFloat(currentPage) * pageStride + dragOffset)
                    .animation(.spring(response: 0.45, dampingFraction: 0.86), value: currentPage)
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .onChanged { value in
                                dragOffset = value.translation.height
                            }
                            .onEnded { value in
                                let drag = value.translation.height
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                    if drag < -snapThreshold && currentPage < 2 {
                                        currentPage += 1
                                    } else if drag > snapThreshold && currentPage > 0 {
                                        currentPage -= 1
                                    }
                                    dragOffset = 0
                                }
                            },
                        // Disable inter-section snap when on the scrollable map so the
                        // inner ScrollView receives vertical drag events instead.
                        including: (currentPage == 1 && mapNeedsScroll) ? .none : .all
                    )

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

                    // Page indicator
                    VStack {
                        Spacer()
                        pageIndicator
                            .padding(.bottom, 90)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { viewModel.fetchRecords() }
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        currentPage = i
                    }
                } label: {
                    Circle()
                        .fill(i == currentPage ? challengesAccentGreen : Color.black.opacity(0.12))
                        .frame(width: i == currentPage ? 8 : 6, height: i == currentPage ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Full-Page Wrappers

    private func challengePickerPage(height: CGFloat) -> some View {
        challengePickerSection
            .frame(maxWidth: .infinity, minHeight: height, alignment: .top)
            .background(challengesLightSectionBackground)
            .clipped()
    }

    private func mainMapPage(height: CGFloat, mapHeight: CGFloat) -> some View {
        GeometryReader { inner in
            let w = inner.size.width
            if mapHeight > height {
                boundaryAwareScrollableMap(w: w, height: height, mapHeight: mapHeight)
            } else {
                mapCanvas(w: w, h: height, pageHeight: height)
                    .clipped()
            }
        }
        .background(Color.white)
    }

    private func progressSummaryPage(height: CGFloat) -> some View {
        progressSummarySection
            .frame(maxWidth: .infinity, minHeight: height, alignment: .top)
            .background(challengesLightSectionBackground)
            .clipped()
    }

    // MARK: - Challenge Picker (Top Section)

    private var challengePickerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer().frame(maxHeight: 100)

            Text("UP NEXT")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(challengesAccentGreen.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.65)))

            Text("Choose Your Next Challenge")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
                .minimumScaleFactor(0.85)
                .lineLimit(2)

            if viewModel.currentChallengeInProgress {
                Text("Complete your current challenge to unlock choices")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.appTextSecondary)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.challengeTiers) { tier in
                    challengeTierCard(tier)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .layoutPriority(1)
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private func challengeTierCard(_ tier: ChallengeTier) -> some View {
        Button {
            viewModel.selectChallenge(tier.totalDays)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                currentPage = 1
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(tier.isUnlocked
                              ? Color(red: 0.40, green: 0.62, blue: 0.44)
                              : Color(red: 0.82, green: 0.84, blue: 0.82))
                        .frame(width: 44, height: 44)

                    if tier.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else if !tier.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appTextTertiary)
                    } else {
                        Text("\(tier.totalDays)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(tier.isUnlocked ? Color.appTextPrimary : Color.appTextTertiary)

                    Text(tierSubtitle(tier))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(tier.isUnlocked ? Color.appTextSecondary : Color.appTextTertiary)
                }

                Spacer()

                if tier.isCompleted {
                    Image("shined_star")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
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

    // MARK: - Map Canvas (shared by static and scrollable paths)

    private func mapCanvas(w: CGFloat, h: CGFloat, pageHeight: CGFloat) -> some View {
        ZStack {
            Color.white
            groundDecor(w: w, h: h)

            roadSideTreeDecorations(w: w, h: h)

            dynamicWindingPath(w: w, h: h, pageHeight: pageHeight)
                .stroke(
                    Color(red: 0.75, green: 0.65, blue: 0.50),
                    style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round)
                )

            dynamicWindingPath(w: w, h: h, pageHeight: pageHeight)
                .stroke(
                    Color(red: 0.85, green: 0.78, blue: 0.62),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                )

            let positions = dynamicNodePositions(w: w, h: h, pageHeight: pageHeight)
            let days = viewModel.challenge.days

            ForEach(days) { day in
                if day.id < positions.count {
                    let pos = positions[day.id]

                    nodeView(day: day)
                        .id("day_\(day.id)")
                        .position(pos)

                    starsArcAroundNode(count: day.starRating, center: pos)
                }
            }

            if positions.indices.contains(viewModel.focusDayIndex) {
                let idx = viewModel.focusDayIndex
                let p = positions[idx]
                currentStepArrowImage()
                    .position(
                        x: p.x,
                        y: p.y - currentStepArrowOffsetFromNodeCenter
                    )
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: viewModel.focusDayIndex)
                    .zIndex(50)
            }
        }
        .frame(width: w, height: h)
    }

    private func currentStepArrowImage() -> some View {
        Image("arrow")
            .resizable()
            .scaledToFit()
            .frame(width: 52, height: 60)
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            .accessibilityLabel("Current challenge day")
    }

    // MARK: - Road-side tree decorations

    private struct RoadTreePlacement: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let imageName: String
        let flip: Bool
        let width: CGFloat
        let height: CGFloat
    }

    /// Sparse trees alternating left / right down the canvas; spacing scales with map height.
    private func roadSideTreePlacements(w: CGFloat, h: CGFloat) -> [RoadTreePlacement] {
        let treeW = min(w * 0.165, 94)
        let treeH = treeW * 1.18
        let xLeft = w * 0.052
        let xRight = w * 0.948

        let strideTarget = max(195, min(370, h * 0.245))
        var y = h * 0.11
        var index = 0
        var placements: [RoadTreePlacement] = []

        while y < h - h * 0.065 {
            let left = index % 2 == 0
            let imageName = index % 2 == 0 ? "road_tree_1" : "road_tree_2"
            let xBase = left ? xLeft : xRight
            let jitter = CGFloat((index % 5) - 2) * 4
            let x = min(max(xBase + (left ? jitter : -jitter), treeW * 0.45), w - treeW * 0.45)
            let flip = !left

            placements.append(
                RoadTreePlacement(
                    id: index,
                    x: x,
                    y: y,
                    imageName: imageName,
                    flip: flip,
                    width: treeW,
                    height: treeH
                )
            )

            y += strideTarget * (0.90 + 0.035 * CGFloat(index % 4))
            index += 1
            if index > 22 { break }
        }

        return placements
    }

    private func roadSideTreeDecorations(w: CGFloat, h: CGFloat) -> some View {
        let placements = roadSideTreePlacements(w: w, h: h)
        return ZStack {
            ForEach(placements) { p in
                Image(p.imageName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: p.width, height: p.height)
                    .scaleEffect(x: p.flip ? -1 : 1, y: 1)
                    .position(x: p.x, y: p.y)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Scrollable Map

    /// True whenever the challenge has more days than can comfortably fit on one screen.
    private var mapNeedsScroll: Bool {
        viewModel.challenge.days.count > 3
    }

    /// Total canvas height for the map, accounting for fixed per-node spacing on long challenges.
    private func mapContentHeight(pageHeight: CGFloat) -> CGFloat {
        let count = viewModel.challenge.days.count
        guard count > 3 else { return pageHeight }
        let spacing = pageHeight / nodesPerScreen
        // top padding + (count-1) gaps + bottom padding
        return spacing * 0.8 + CGFloat(count - 1) * spacing + spacing * 0.9
    }

    private func boundaryAwareScrollableMap(w: CGFloat, height: CGFloat, mapHeight: CGFloat) -> some View {
        let focusOffset = mapFocusOffset(pageHeight: height, mapHeight: mapHeight)
        let scrollResetID = viewModel.challenge.totalDays * 1_000 + viewModel.focusDayIndex

        return BoundaryAwareMapScrollView(
            contentHeight: mapHeight,
            targetOffsetY: focusOffset,
            resetID: scrollResetID,
            transitionThreshold: mapBoundaryDragTrigger,
            onPullPastTop: {
                guard currentPage > 0 else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    currentPage -= 1
                }
            },
            onPullPastBottom: {
                guard currentPage < 2 else { return }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    currentPage += 1
                }
            }
        ) {
            mapCanvas(w: w, h: mapHeight, pageHeight: height)
        }
    }

    private func mapFocusOffset(pageHeight: CGFloat, mapHeight: CGFloat) -> CGFloat {
        let positions = dynamicNodePositions(w: 1, h: mapHeight, pageHeight: pageHeight)
        guard positions.indices.contains(viewModel.focusDayIndex) else { return 0 }

        let centeredOffset = positions[viewModel.focusDayIndex].y - pageHeight / 2
        return min(max(centeredOffset, 0), max(mapHeight - pageHeight, 0))
    }

    // MARK: - Dynamic Node Positions

    private func dynamicNodePositions(w: CGFloat, h: CGFloat, pageHeight: CGFloat) -> [CGPoint] {
        let count = viewModel.challenge.days.count
        guard count > 0 else { return [] }

        var positions: [CGPoint] = []
        let xCenter = w * 0.5
        let xAmplitude = w * 0.20

        if count <= 3 {
            // Proportional layout: spread nodes across the full page height.
            let topPadding: CGFloat = h * 0.22
            let bottomPadding: CGFloat = h * 0.25
            for i in 0..<count {
                let progress = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
                let y = h - bottomPadding - progress * (h - topPadding - bottomPadding)
                let x = xCenter + xAmplitude * (i % 2 == 0 ? -1 : 1)
                positions.append(CGPoint(x: x, y: y))
            }
        } else {
            // Fixed spacing: one node slot per (pageHeight / nodesPerScreen).
            // i=0 → Day 1 near the bottom of the canvas; i=count-1 → Day N near the top.
            let spacing = pageHeight / nodesPerScreen
            let bottomPad = spacing * 0.9
            for i in 0..<count {
                let y = h - bottomPad - CGFloat(i) * spacing
                let x = xCenter + xAmplitude * (i % 2 == 0 ? -1 : 1)
                positions.append(CGPoint(x: x, y: y))
            }
        }
        return positions
    }

    // MARK: - Dynamic Winding Path

    /// Handle length as a fraction of segment length (higher = rounder bends near nodes).
    private let roadCurveHandleFraction: CGFloat = 0.42
    private let roadCurveHandleMax: CGFloat = 100

    private func dynamicWindingPath(w: CGFloat, h: CGFloat, pageHeight: CGFloat) -> Path {
        let pts = dynamicNodePositions(w: w, h: h, pageHeight: pageHeight)
        var path = Path()
        guard !pts.isEmpty else { return path }

        let center = w * 0.5
        let entry = CGPoint(x: center, y: h + 30)
        let exit = CGPoint(x: center, y: -30)
        let waypoints: [CGPoint] = [entry] + pts + [exit]

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
        Image(filled ? "shined_star" : "unshined_star")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: 22, height: 22)
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
            .fill(Color.black.opacity(0.08))
            .frame(height: 1.5)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
    }

    // MARK: - Progress Summary (Bottom Section)

    private var progressSummarySection: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer().frame(maxHeight: 100)
            Text("YOUR JOURNEY")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(challengesAccentGreen.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.65)))

            VStack(spacing: AppSpacing.md) {
                summaryStatRow(icon: "star.fill", color: .appAnswered,
                               label: "Stars Collected",
                               value: "\(viewModel.totalStarsEarned)",
                               rowIconAsset: "shined_star")

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
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.lg)
            .layoutPriority(1)

            Text("Keep praying — your journey continues!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, AppSpacing.sm)

            Spacer(minLength: 0)
        }
    }

    private func summaryStatRow(icon: String, color: Color, label: String, value: String, rowIconAsset: String? = nil) -> some View {
        HStack(spacing: AppSpacing.md) {
            Group {
                if let assetName = rowIconAsset {
                    Image(assetName)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
            }
            .frame(width: 36, height: 36)
            .background(Circle().fill(color.opacity(0.15)))

            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
        }
    }
}

// MARK: - UIKit-backed nested scroll handoff

private struct BoundaryAwareMapScrollView<Content: View>: UIViewRepresentable {
    let contentHeight: CGFloat
    let targetOffsetY: CGFloat
    let resetID: Int
    let transitionThreshold: CGFloat
    let onPullPastTop: () -> Void
    let onPullPastBottom: () -> Void
    let content: Content

    init(
        contentHeight: CGFloat,
        targetOffsetY: CGFloat,
        resetID: Int,
        transitionThreshold: CGFloat,
        onPullPastTop: @escaping () -> Void,
        onPullPastBottom: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.contentHeight = contentHeight
        self.targetOffsetY = targetOffsetY
        self.resetID = resetID
        self.transitionThreshold = transitionThreshold
        self.onPullPastTop = onPullPastTop
        self.onPullPastBottom = onPullPastBottom
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            threshold: transitionThreshold,
            onPullPastTop: onPullPastTop,
            onPullPastBottom: onPullPastBottom
        )
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.bounces = true
        scrollView.backgroundColor = .white
        scrollView.contentInsetAdjustmentBehavior = .never

        let hostView = context.coordinator.hostingController.view!
        hostView.backgroundColor = .clear
        hostView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostView)

        NSLayoutConstraint.activate([
            hostView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.heightConstraint = hostView.heightAnchor.constraint(equalToConstant: contentHeight)
        context.coordinator.heightConstraint?.isActive = true

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.threshold = transitionThreshold
        context.coordinator.onPullPastTop = onPullPastTop
        context.coordinator.onPullPastBottom = onPullPastBottom
        context.coordinator.hostingController.rootView = AnyView(content)
        context.coordinator.heightConstraint?.constant = contentHeight

        if context.coordinator.lastAppliedResetID != resetID {
            context.coordinator.lastAppliedResetID = resetID
            context.coordinator.setProgrammaticOffset(targetOffsetY, on: scrollView)
        } else {
            context.coordinator.refreshContentSize(on: scrollView)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        var heightConstraint: NSLayoutConstraint?
        var threshold: CGFloat
        var onPullPastTop: () -> Void
        var onPullPastBottom: () -> Void
        var didTriggerBoundaryTransition = false
        var isProgrammaticScroll = false
        var lastAppliedResetID: Int?

        init(
            threshold: CGFloat,
            onPullPastTop: @escaping () -> Void,
            onPullPastBottom: @escaping () -> Void
        ) {
            self.threshold = threshold
            self.onPullPastTop = onPullPastTop
            self.onPullPastBottom = onPullPastBottom
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard scrollView.isDragging, !didTriggerBoundaryTransition, !isProgrammaticScroll else {
                return
            }

            let topLimit = -scrollView.adjustedContentInset.top
            let bottomLimit = max(
                scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom,
                topLimit
            )
            let translationY = scrollView.panGestureRecognizer.translation(in: scrollView).y

            if scrollView.contentOffset.y <= topLimit, translationY > threshold {
                scrollView.contentOffset.y = topLimit
                didTriggerBoundaryTransition = true
                onPullPastTop()
            } else if scrollView.contentOffset.y >= bottomLimit, translationY < -threshold {
                scrollView.contentOffset.y = bottomLimit
                didTriggerBoundaryTransition = true
                onPullPastBottom()
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                didTriggerBoundaryTransition = false
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            didTriggerBoundaryTransition = false
        }

        func setProgrammaticOffset(_ y: CGFloat, on scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.refreshContentSize(on: scrollView)
                let maxOffsetY = max(scrollView.contentSize.height - scrollView.bounds.height, 0)
                let clampedY = min(max(y, 0), maxOffsetY)
                self.isProgrammaticScroll = true
                scrollView.setContentOffset(CGPoint(x: 0, y: clampedY), animated: false)
                self.didTriggerBoundaryTransition = false
                DispatchQueue.main.async {
                    self.isProgrammaticScroll = false
                }
            }
        }

        func refreshContentSize(on scrollView: UIScrollView) {
            hostingController.view.invalidateIntrinsicContentSize()
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            scrollView.setNeedsLayout()
            scrollView.layoutIfNeeded()
        }
    }
}

#Preview {
    RoadMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
