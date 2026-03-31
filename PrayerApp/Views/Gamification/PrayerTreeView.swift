import SwiftUI

struct PrayerTreeView: View {
    @StateObject private var viewModel = PrayerTreeViewModel()
    @State private var showingStarDetail = false
    @State private var showingDecorationLibrary = false

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack {
                        // Full scene canvas (sky, clouds, hills, tree, ground)
                        sceneCanvas(growth: viewModel.treeGrowthFraction)
                            .frame(width: w, height: h)

                        // Stars in the sky region
                        ForEach(viewModel.stars) { star in
                            StarNodeView(star: star) {
                                viewModel.selectStar(star)
                                showingStarDetail = true
                            }
                            .position(
                                x: star.position.x * w,
                                y: star.position.y * h * 0.30
                            )
                        }
                    }
                }
                .ignoresSafeArea()

                // Stats pill
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: AppSpacing.md) {
                            Label("\(viewModel.yearSessionCount)", systemImage: "figure.walk.motion")
                                .font(AppFont.caption())
                            Label("\(viewModel.stars.count)", systemImage: AppIcons.star)
                                .font(AppFont.caption())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(.ultraThinMaterial)
                        .cornerRadius(AppRadius.full)
                        .padding(.trailing, AppSpacing.lg)
                    }
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationTitle("Prayer Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDecorationLibrary = true
                    } label: {
                        Image(systemName: AppIcons.decoration)
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .onAppear { viewModel.fetchTreeData() }
        .sheet(isPresented: $showingStarDetail) {
            if let star = viewModel.selectedStar {
                StarDetailSheet(star: star, onDismiss: {
                    showingStarDetail = false
                    viewModel.clearSelection()
                })
                .presentationDetents([.medium])
            }
        }
        .navigationDestination(isPresented: $showingDecorationLibrary) {
            DecorationLibraryView()
        }
    }

    // MARK: - Full Scene Canvas

    private func sceneCanvas(growth: Double) -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let g = max(0.02, growth)

            drawSky(ctx: ctx, w: w, h: h)
            drawClouds(ctx: ctx, w: w, h: h)
            drawForeground(ctx: ctx, w: w, h: h)
            drawTree(ctx: ctx, w: w, h: h, g: g)
        }
    }

    // MARK: - Sky

    private func drawSky(ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let skyRect = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.fill(Path(skyRect), with: .linearGradient(
            Gradient(colors: [
                Color(red: 0.45, green: 0.72, blue: 0.95),
                Color(red: 0.60, green: 0.82, blue: 0.96),
                Color(red: 0.75, green: 0.90, blue: 0.97),
            ]),
            startPoint: CGPoint(x: w / 2, y: 0),
            endPoint: CGPoint(x: w / 2, y: h * 0.55)
        ))
    }

    // MARK: - Clouds

    private func drawClouds(ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let cloudColor = Color.white.opacity(0.85)

        drawCloudBlob(ctx: ctx, cx: w * 0.20, cy: h * 0.10, rw: 50, rh: 22, color: cloudColor)
        drawCloudBlob(ctx: ctx, cx: w * 0.75, cy: h * 0.08, rw: 60, rh: 25, color: cloudColor)
        drawCloudBlob(ctx: ctx, cx: w * 0.50, cy: h * 0.18, rw: 45, rh: 18, color: cloudColor)
        drawCloudBlob(ctx: ctx, cx: w * 0.88, cy: h * 0.22, rw: 38, rh: 16, color: cloudColor)
        drawCloudBlob(ctx: ctx, cx: w * 0.12, cy: h * 0.25, rw: 42, rh: 18, color: cloudColor)
    }

    private func drawCloudBlob(ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                                rw: CGFloat, rh: CGFloat, color: Color) {
        let offsets: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 1.0, 1.0),
            (-0.6, -0.15, 0.75, 0.80),
            (0.55, -0.10, 0.80, 0.85),
            (-0.25, -0.35, 0.60, 0.65),
            (0.30, -0.30, 0.65, 0.70),
        ]
        for (dx, dy, sw, sh) in offsets {
            let rect = CGRect(
                x: cx + dx * rw - rw * sw / 2,
                y: cy + dy * rh - rh * sh / 2,
                width: rw * sw,
                height: rh * sh
            )
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    // MARK: - Foreground Ground

    private func drawForeground(ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let grassColor = Color(red: 0.42, green: 0.65, blue: 0.35)
        let grassDark = Color(red: 0.35, green: 0.55, blue: 0.28)

        var path = Path()
        let baseY = h * 0.68
        path.move(to: CGPoint(x: 0, y: baseY + h * 0.03))
        path.addQuadCurve(to: CGPoint(x: w * 0.30, y: baseY),
                          control: CGPoint(x: w * 0.15, y: baseY - h * 0.02))
        path.addQuadCurve(to: CGPoint(x: w * 0.55, y: baseY + h * 0.01),
                          control: CGPoint(x: w * 0.42, y: baseY - h * 0.01))
        path.addQuadCurve(to: CGPoint(x: w, y: baseY),
                          control: CGPoint(x: w * 0.80, y: baseY - h * 0.02))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        ctx.fill(path, with: .linearGradient(
            Gradient(colors: [grassColor, grassDark]),
            startPoint: CGPoint(x: w / 2, y: baseY),
            endPoint: CGPoint(x: w / 2, y: h)
        ))
    }

    // MARK: - Tree

    private func drawTree(ctx: GraphicsContext, w: CGFloat, h: CGFloat, g: Double) {
        let centerX = w / 2
        let groundY = h * 0.70

        // Trunk
        let maxTrunkH = h * 0.32
        let maxTrunkW = w * 0.07
        let trunkH = maxTrunkH * lerp(0.18, 1.0, g)
        let trunkW = maxTrunkW * lerp(0.35, 1.0, g)
        let trunkBottom = groundY
        let trunkTop = trunkBottom - trunkH

        let trunkColor = Color(red: 0.52, green: 0.36, blue: 0.20)
        let trunkDark = Color(red: 0.40, green: 0.28, blue: 0.15)

        // Main trunk (tapered)
        var trunk = Path()
        let topTaper: CGFloat = 0.35
        trunk.move(to: CGPoint(x: centerX - trunkW / 2, y: trunkBottom))
        trunk.addLine(to: CGPoint(x: centerX - trunkW * topTaper / 2, y: trunkTop))
        trunk.addLine(to: CGPoint(x: centerX + trunkW * topTaper / 2, y: trunkTop))
        trunk.addLine(to: CGPoint(x: centerX + trunkW / 2, y: trunkBottom))
        trunk.closeSubpath()
        ctx.fill(trunk, with: .color(trunkColor))

        // Trunk shading (right side darker)
        var trunkShade = Path()
        trunkShade.move(to: CGPoint(x: centerX, y: trunkBottom))
        trunkShade.addLine(to: CGPoint(x: centerX, y: trunkTop))
        trunkShade.addLine(to: CGPoint(x: centerX + trunkW * topTaper / 2, y: trunkTop))
        trunkShade.addLine(to: CGPoint(x: centerX + trunkW / 2, y: trunkBottom))
        trunkShade.closeSubpath()
        ctx.fill(trunkShade, with: .color(trunkDark.opacity(0.3)))

        // Branches (when growth > 0.3)
        if g > 0.3 {
            let branchY = trunkTop + trunkH * 0.35
            let branchLen = trunkW * lerp(1.0, 3.0, g)
            let branchThick: CGFloat = lerp(1.5, 3.5, g)

            // Left branch
            var lb = Path()
            lb.move(to: CGPoint(x: centerX - trunkW * 0.15, y: branchY))
            lb.addLine(to: CGPoint(x: centerX - branchLen, y: branchY - trunkH * 0.12))
            ctx.stroke(lb, with: .color(trunkColor), lineWidth: branchThick)

            // Right branch
            var rb = Path()
            rb.move(to: CGPoint(x: centerX + trunkW * 0.15, y: branchY + trunkH * 0.05))
            rb.addLine(to: CGPoint(x: centerX + branchLen * 0.8, y: branchY - trunkH * 0.08))
            ctx.stroke(rb, with: .color(trunkColor), lineWidth: branchThick)
        }

        // Canopy -- puffy overlapping circles like the reference image
        let scale = lerp(0.25, 1.0, g)

        let mainGreen = Color(red: 0.32, green: 0.62, blue: 0.30)
        let lightGreen = Color(red: 0.40, green: 0.72, blue: 0.38)
        let darkGreen = Color(red: 0.22, green: 0.48, blue: 0.22)

        struct Blob {
            let dx: CGFloat; let dy: CGFloat; let r: CGFloat; let color: Color
            let minGrowth: Double
        }

        let canopyCenterY = trunkTop - h * 0.02 * scale

        let blobs: [Blob] = [
            // Bottom wide blobs
            Blob(dx: -0.08, dy: 0.04, r: 0.14, color: mainGreen, minGrowth: 0.0),
            Blob(dx: 0.09, dy: 0.05, r: 0.13, color: darkGreen, minGrowth: 0.0),
            Blob(dx: 0.0, dy: 0.02, r: 0.12, color: lightGreen, minGrowth: 0.0),
            // Middle blobs
            Blob(dx: -0.06, dy: -0.04, r: 0.12, color: mainGreen, minGrowth: 0.15),
            Blob(dx: 0.07, dy: -0.03, r: 0.11, color: lightGreen, minGrowth: 0.15),
            Blob(dx: -0.11, dy: 0.0, r: 0.10, color: darkGreen, minGrowth: 0.25),
            Blob(dx: 0.12, dy: 0.01, r: 0.10, color: mainGreen, minGrowth: 0.25),
            // Upper blobs
            Blob(dx: 0.0, dy: -0.08, r: 0.10, color: lightGreen, minGrowth: 0.35),
            Blob(dx: -0.04, dy: -0.11, r: 0.08, color: mainGreen, minGrowth: 0.50),
            Blob(dx: 0.05, dy: -0.10, r: 0.09, color: darkGreen, minGrowth: 0.45),
            // Top crown
            Blob(dx: 0.0, dy: -0.14, r: 0.07, color: lightGreen, minGrowth: 0.65),
            Blob(dx: -0.02, dy: -0.17, r: 0.05, color: mainGreen, minGrowth: 0.80),
        ]

        for blob in blobs where g >= blob.minGrowth {
            let bx = centerX + w * blob.dx * scale
            let by = canopyCenterY + h * blob.dy * scale
            let br = w * blob.r * scale

            let rect = CGRect(x: bx - br, y: by - br, width: br * 2, height: br * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(blob.color))

            // Highlight on top-left
            let hlRect = CGRect(x: bx - br * 0.5, y: by - br * 0.6, width: br * 0.8, height: br * 0.6)
            ctx.fill(Path(ellipseIn: hlRect), with: .color(lightGreen.opacity(0.25)))
        }

        // Small ground shadow under tree
        let shadowW = trunkW * 3.0 * scale
        let shadowRect = CGRect(x: centerX - shadowW / 2, y: groundY - 3, width: shadowW, height: 8)
        ctx.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.08)))
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> CGFloat {
        CGFloat(a + (b - a) * t)
    }
}

// MARK: - Star Node

struct StarNodeView: View {
    let star: StarData
    let onTap: () -> Void

    @State private var twinkle = false

    var body: some View {
        Button(action: onTap) {
            Image(systemName: star.prayerItem.statusEnum == .answered ? "star.fill" : "star")
                .font(.system(size: 14))
                .foregroundColor(star.prayerItem.statusEnum == .answered ? .appAnswered : .white.opacity(0.85))
                .scaleEffect(twinkle ? 1.2 : 0.9)
                .opacity(twinkle ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.0...2.0))
                .repeatForever(autoreverses: true)
            ) {
                twinkle = true
            }
        }
    }
}

// MARK: - Star Detail Sheet

struct StarDetailSheet: View {
    let star: StarData
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.appAnswered.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.appAnswered)
                }
                .padding(.top, AppSpacing.lg)

                VStack(spacing: AppSpacing.sm) {
                    Text(star.prayerItem.title ?? "")
                        .font(AppFont.title2())
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)

                    if let content = star.prayerItem.content, !content.isEmpty {
                        Text(content)
                            .font(AppFont.body())
                            .foregroundColor(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }

                    if let group = star.prayerItem.intercessoryGroupEnum {
                        HStack {
                            Image(systemName: group.iconName)
                            Text("Praying for \(group.displayName)")
                        }
                        .font(AppFont.subheadline())
                        .foregroundColor(Color.appTextSecondary)
                    }

                    StatusIndicator(status: star.prayerItem.statusEnum)
                }

                Spacer()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Intercession Star")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

#Preview {
    PrayerTreeView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
