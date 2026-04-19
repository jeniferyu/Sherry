import SwiftUI

struct PrayerTreeView: View {
    @StateObject private var viewModel = PrayerTreeViewModel()
    @State private var showingStarDetail = false
    @State private var showingInventory = false
    @State private var showingOrchard = false

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height

                        ZStack {
                            // Sky + ground (tree is sprout asset)
                            sceneCanvas()
                                .frame(width: w, height: h)

                            cloudImageLayer(w: w, h: h)

                            sproutTreeLayer(w: w, h: h, growth: viewModel.treeGrowthFraction)

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

                    // Stats banner at top
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
                .overlay(alignment: .bottomLeading) {
                    Button {
                        showingOrchard = false
                        showingInventory = true
                    } label: {
                        cornerIconBadge(
                            imageName: "treasure_chest",
                            caption: "Decoration",
                            accessibilityLabel: "Decoration library"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, AppSpacing.lg)
                    .padding(.bottom, 80)
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        showingInventory = false
                        showingOrchard = true
                    } label: {
                        cornerIconBadge(
                            imageName: "orchard_forest",
                            caption: "Orchard",
                            accessibilityLabel: "Orchard"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.bottom, 80)
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
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

            // ── Backpack & Orchard overlays (above navigation chrome) ───
            if showingInventory {
                InventoryView(isPresented: $showingInventory)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(10)
            }
            if showingOrchard {
                OrchardView(isPresented: $showingOrchard)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: showingInventory || showingOrchard)
    }

    /// White ring + asset image; mint pill overlaps the bottom of the ring (matches treasure / orchard corners).
    private func cornerIconBadge(imageName: String, caption: String, accessibilityLabel: String) -> some View {
        VStack(spacing: -10) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.95), lineWidth: 2.5)
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.white.opacity(0.55), radius: 4, y: 0)
                    .shadow(color: Color.white.opacity(0.3), radius: 10, y: 0)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55, height: 55)
            }

            Text(caption)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.14, green: 0.30, blue: 0.20))
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(red: 0.70, green: 0.91, blue: 0.76).opacity(0.98))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Full Scene Canvas

    private func sceneCanvas() -> some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            drawSky(ctx: ctx, w: w, h: h)
            drawForeground(ctx: ctx, w: w, h: h)
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

    // MARK: - Clouds (asset)

    private func cloudImageLayer(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            cloudAsset(width: w * 0.28, x: w * 0.20, y: h * 0.10, opacity: 0.92)
            cloudAsset(width: w * 0.30, x: w * 0.50, y: h * 0.18, opacity: 0.88)
            cloudAsset(width: w * 0.22, x: w * 0.88, y: h * 0.22, opacity: 0.90)
            cloudAsset(width: w * 0.26, x: w * 0.12, y: h * 0.25, opacity: 0.85)
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    private func cloudAsset(width: CGFloat, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Image("cloud")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .opacity(opacity)
            .position(x: x, y: y)
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

    // MARK: - Sprout tree (asset)

    /// Bottom of sprout aligns with the hill line (`h * 0.70`); width scales with prayer progress.
    private func sproutTreeLayer(w: CGFloat, h: CGFloat, growth: Double) -> some View {
        let g = max(0.02, min(1.0, growth))
        let maxW = w * lerp(0.16, 0.38, g)

        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            Image("sprout")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: maxW)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            Spacer()
                .frame(height: h * 0.30)
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
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
