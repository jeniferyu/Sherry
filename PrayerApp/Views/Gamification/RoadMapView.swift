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

    /// Soft mint — aligned with `appBackground` / list screens; lower chroma than the old roadmap green.
    private var challengesLightSectionBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 0.96),
                Color(red: 0.93, green: 0.97, blue: 0.94),
                Color.appBackground,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Muted sage (less saturated than before) for labels and page dots.
    private let challengesAccentGreen = Color(red: 0.36, green: 0.48, blue: 0.42)

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
                            Color(red: 0.86, green: 0.93, blue: 0.89),
                            Color(red: 0.90, green: 0.95, blue: 0.91),
                            Color.appBackground,
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
        .onReceive(NotificationCenter.default.publisher(for: .gamificationProgressDidUpdate)) { _ in
            viewModel.fetchRecords()
        }
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
        .background(Color.appSurface)
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
                              ? Color(red: 0.44, green: 0.60, blue: 0.50)
                              : Color(red: 0.84, green: 0.86, blue: 0.85))
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
            Color.appSurface
            groundDecor(w: w, h: h)

            roadSideTreeDecorations(w: w, h: h, pageHeight: pageHeight)

            // Winding road — desaturated warm stone (less yellow / less contrast vs mint world).
            dynamicWindingPath(w: w, h: h, pageHeight: pageHeight)
                .stroke(
                    Color(red: 0.76, green: 0.72, blue: 0.66),
                    style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round)
                )

            dynamicWindingPath(w: w, h: h, pageHeight: pageHeight)
                .stroke(
                    Color(red: 0.88, green: 0.85, blue: 0.78),
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

    /// Pushes a point further toward the left or right screen edge (away from center), for landmark trees.
    private func xOutsidePath(nodeX: CGFloat, margin: CGFloat, w: CGFloat) -> CGFloat {
        let c = w * 0.5
        if nodeX < c {
            return nodeX - margin
        }
        return nodeX + margin
    }

    /// Sparse trees alternating left / right down the canvas; spacing scales with map height.
    /// For 14- and 21-day challenges, adds the farmland tree asset beside the first and last day nodes.
    private func roadSideTreePlacements(w: CGFloat, h: CGFloat, pageHeight: CGFloat) -> [RoadTreePlacement] {
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

        let days = viewModel.challenge.totalDays
        if days == 14 || days == 21 {
            let positions = dynamicNodePositions(w: w, h: h, pageHeight: pageHeight)
            if positions.count >= 2 {
                let mTreeW = min(w * 0.19, 100)
                let mTreeH = mTreeW * 1.18
                let margin = w * 0.2
                let first = positions[0]
                let last = positions[positions.count - 1]
                let x0 = xOutsidePath(nodeX: first.x, margin: margin, w: w)
                let x1 = xOutsidePath(nodeX: last.x, margin: margin, w: w)
                let clamp: (CGFloat) -> CGFloat = { x in
                    min(max(x, mTreeW * 0.5), w - mTreeW * 0.5)
                }
                placements.append(
                    RoadTreePlacement(
                        id: 10_000,
                        x: clamp(x0),
                        y: first.y,
                        imageName: "road_tree_farmland",
                        flip: x0 > w * 0.5,
                        width: mTreeW,
                        height: mTreeH
                    )
                )
                placements.append(
                    RoadTreePlacement(
                        id: 10_001,
                        x: clamp(x1),
                        y: last.y,
                        imageName: "road_tree_farmland",
                        flip: x1 > w * 0.5,
                        width: mTreeW,
                        height: mTreeH
                    )
                )
            }
        }

        return placements
    }

    private func roadSideTreeDecorations(w: CGFloat, h: CGFloat, pageHeight: CGFloat) -> some View {
        let placements = roadSideTreePlacements(w: w, h: h, pageHeight: pageHeight)
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

    private struct GroundGrassPlacement: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let opacity: Double
        let flip: Bool
    }

    /// Base grass + optional extra clumps for the long 21-day scroll.
    private func groundGrassPlacements(w: CGFloat, h: CGFloat) -> [GroundGrassPlacement] {
        var items: [GroundGrassPlacement] = []

        let patchPositions: [(CGFloat, CGFloat, CGFloat, CGFloat, Double, Bool)] = [
            (0.10, 0.85, 60, 30, 0.52, true),
            (0.80, 0.70, 50, 25, 0.50, false),
            (0.15, 0.40, 45, 22, 0.50, true),
            (0.85, 0.30, 55, 28, 0.50, false),
            (0.60, 0.90, 40, 20, 0.52, false),
            (0.25, 0.60, 35, 18, 0.50, true),
            (0.75, 0.15, 50, 25, 0.50, true),
        ]
        for (i, row) in patchPositions.enumerated() {
            let (px, py, pw, ph, o, flip) = row
            items.append(
                GroundGrassPlacement(
                    id: i,
                    x: w * px,
                    y: h * py,
                    width: pw,
                    height: ph,
                    opacity: o,
                    flip: flip
                )
            )
        }

        let shrubPos: [(CGFloat, CGFloat, CGFloat, Double, Bool)] = [
            (0.08, 0.72, 18, 0.62, false),
            (0.92, 0.45, 22, 0.64, true),
            (0.05, 0.25, 16, 0.60, true),
            (0.88, 0.82, 20, 0.62, false),
            (0.50, 0.12, 15, 0.60, true),
            (0.15, 0.92, 14, 0.62, false),
            (0.78, 0.20, 17, 0.60, true),
            (0.55, 0.65, 13, 0.58, false),
        ]
        for (i, row) in shrubPos.enumerated() {
            let (sx, sy, sr, o, flip) = row
            let d = sr * 2
            items.append(
                GroundGrassPlacement(
                    id: 1_000 + i,
                    x: w * sx,
                    y: h * sy,
                    width: d,
                    height: d,
                    opacity: o,
                    flip: flip
                )
            )
        }

        if viewModel.challenge.totalDays == 21 {
            // Denser decoration along the tall map: more patches + shrubs between / beside the path.
            let extraPatches: [(CGFloat, CGFloat, CGFloat, CGFloat, Double, Bool)] = [
                (0.12, 0.94, 48, 24, 0.48, true),
                (0.88, 0.86, 44, 22, 0.48, false),
                (0.22, 0.78, 38, 19, 0.46, false),
                (0.78, 0.70, 50, 26, 0.48, true),
                (0.14, 0.62, 42, 21, 0.47, true),
                (0.86, 0.54, 46, 23, 0.47, false),
                (0.30, 0.46, 40, 20, 0.46, false),
                (0.70, 0.38, 44, 22, 0.48, true),
                (0.10, 0.30, 36, 18, 0.45, true),
                (0.90, 0.22, 48, 24, 0.48, false),
                (0.20, 0.14, 42, 21, 0.46, false),
                (0.80, 0.08, 46, 23, 0.46, true),
                (0.50, 0.50, 52, 28, 0.49, true),
                (0.42, 0.72, 40, 20, 0.46, false),
                (0.58, 0.30, 42, 21, 0.47, false),
            ]
            for (i, row) in extraPatches.enumerated() {
                let (px, py, pw, ph, o, flip) = row
                items.append(
                    GroundGrassPlacement(
                        id: 5_000 + i,
                        x: w * px,
                        y: h * py,
                        width: pw,
                        height: ph,
                        opacity: o,
                        flip: flip
                    )
                )
            }

            let extraShrubs: [(CGFloat, CGFloat, CGFloat, Double, Bool)] = [
                (0.32, 0.90, 16, 0.58, true),
                (0.68, 0.82, 15, 0.56, false),
                (0.08, 0.74, 14, 0.55, false),
                (0.92, 0.66, 17, 0.58, true),
                (0.45, 0.58, 16, 0.57, true),
                (0.55, 0.50, 15, 0.56, false),
                (0.12, 0.42, 16, 0.57, false),
                (0.88, 0.34, 15, 0.55, true),
                (0.38, 0.26, 14, 0.54, true),
                (0.62, 0.18, 16, 0.57, false),
                (0.25, 0.96, 15, 0.56, false),
                (0.75, 0.10, 16, 0.57, true),
                (0.50, 0.66, 15, 0.55, true),
                (0.33, 0.38, 14, 0.54, false),
                (0.66, 0.46, 15, 0.56, true),
            ]
            for (i, row) in extraShrubs.enumerated() {
                let (sx, sy, sr, o, flip) = row
                let d = sr * 2
                items.append(
                    GroundGrassPlacement(
                        id: 6_000 + i,
                        x: w * sx,
                        y: h * sy,
                        width: d,
                        height: d,
                        opacity: o,
                        flip: flip
                    )
                )
            }
        }

        return items
    }

    private func groundDecor(w: CGFloat, h: CGFloat) -> some View {
        let placements = groundGrassPlacements(w: w, h: h)
        return ZStack {
            ForEach(placements) { p in
                Image("map_grass")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
                    .frame(width: p.width, height: p.height)
                    .clipShape(Ellipse())
                    .opacity(p.opacity)
                    .scaleEffect(x: p.flip ? -1 : 1, y: 1)
                    .position(x: p.x, y: p.y)
            }
        }
        .allowsHitTesting(false)
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
