import SwiftUI

struct PrayerTreeView: View {
    @StateObject private var viewModel = PrayerTreeViewModel()
    @State private var showingStarDetail = false
    @State private var showingInventory = false
    @State private var showingOrchard = false
    /// Oak growth showcase on the Tree tab: sprout → … → stage_5 (persisted).
    @AppStorage("oakTreeShowcaseStage") private var oakShowcaseStageStored: Int = 1

    private static let oakStageImageNames = ["sprout", "stage_2", "stage_3", "stage_4", "stage_5"]

    /// Bottom gap below tree + buttons, as a fraction of screen height **per stage**.
    /// Larger → tree sits higher; smaller → tree sits lower. Tune each index (stages 1…5) independently.
    private static let oakShowcaseBottomReserveHeightFractionByStage: [CGFloat] = [
        0.32, 0.31, 0.29, 0.27, 0.26
    ]

    /// Matches `padding(.bottom, …)` on Decoration / Orchard corner badges.
    private static let treeCornerIconBottomPadding: CGFloat = 80
    /// Extra lift so Grow / Reset sit slightly **above** the corner row (fixed position).
    private static let oakGrowResetLiftAboveCorners: CGFloat = 56

    private var oakShowcaseStage: Int {
        min(5, max(1, oakShowcaseStageStored))
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height

                        ZStack {
                            treeBackgroundImage(w: w, h: h)

                            oakTreeShowcaseLayer(w: w, h: h)

                            treeMaturityBar(h: h)
                                .position(x: 28, y: h * 0.50)

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
                    .padding(.bottom, Self.treeCornerIconBottomPadding)
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
                    .padding(.bottom, Self.treeCornerIconBottomPadding)
                }
                .overlay(alignment: .bottom) {
                    oakGrowResetButtons(stage: oakShowcaseStage)
                        .padding(.bottom, Self.treeCornerIconBottomPadding + Self.oakGrowResetLiftAboveCorners)
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                viewModel.fetchTreeData()
                oakShowcaseStageStored = min(5, max(1, oakShowcaseStageStored))
            }
            .onReceive(NotificationCenter.default.publisher(for: .gamificationProgressDidUpdate)) { _ in
                viewModel.fetchTreeData()
            }
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

    // MARK: - Maturity Bar

    /// Stage → fill fraction mapping.
    private func maturityFraction(for stage: Int) -> Double {
        switch stage {
        case 1: return 0.10
        case 2: return 0.25
        case 3: return 0.50
        case 4: return 0.75
        default: return 1.00
        }
    }

    private func treeMaturityBar(h: CGFloat) -> some View {
        let barH: CGFloat = h * 0.38
        let barW: CGFloat = 10
        let fraction = maturityFraction(for: oakShowcaseStage)

        return VStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.22, green: 0.65, blue: 0.28))

            ZStack(alignment: .bottom) {
                // Track
                RoundedRectangle(cornerRadius: barW / 2)
                    .fill(Color.white.opacity(0.30))
                    .frame(width: barW, height: barH)
                    .overlay(
                        RoundedRectangle(cornerRadius: barW / 2)
                            .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                    )

                // Fill
                RoundedRectangle(cornerRadius: barW / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.28, green: 0.78, blue: 0.38),
                                Color(red: 0.60, green: 0.92, blue: 0.45)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barW, height: barH * fraction)
                    .animation(.easeInOut(duration: 0.4), value: fraction)
            }

            Text("\(Int(fraction * 100))%")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        .accessibilityLabel("Tree maturity \(Int(fraction * 100)) percent")
    }

    // MARK: - Background

    private func treeBackgroundImage(w: CGFloat, h: CGFloat) -> some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .frame(width: w, height: h)
            .clipped()
            .allowsHitTesting(false)
    }

    // MARK: - Oak tree showcase (5 stages)


    /// Flexible top spacer + fixed bottom gap positions the tree. Grow / Reset are overlaid separately.
    private func oakTreeShowcaseLayer(w: CGFloat, h: CGFloat) -> some View {
        let stage = oakShowcaseStage
        let idx = stage - 1
        let imageName = Self.oakStageImageNames[idx]
        let maxW = w * oakTreeMaxWidthFraction(for: stage)

        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                oakTreeStageImage(
                    imageName: imageName,
                    stage: stage,
                    maxWidth: maxW,
                    screenWidth: w
                )
            }
            Spacer()
                .frame(height: h * oakShowcaseBottomReserveHeightFraction(for: stage))
        }
        .frame(width: w, height: h)
    }

    private func oakShowcaseBottomReserveHeightFraction(for stage: Int) -> CGFloat {
        let idx = stage - 1
        guard idx >= 0,
              idx < Self.oakShowcaseBottomReserveHeightFractionByStage.count
        else { return Self.oakShowcaseBottomReserveHeightFractionByStage.first ?? 0.22 }
        return Self.oakShowcaseBottomReserveHeightFractionByStage[idx]
    }

    private func oakGrowResetButtons(stage: Int) -> some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            Button {
                growOakStage()
            } label: {
                Text("Grow")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.18, green: 0.28, blue: 0.18))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.72, green: 0.88, blue: 0.62))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(stage >= 5)
            .opacity(stage >= 5 ? 0.45 : 1)

            Button {
                resetOakStage()
            } label: {
                Text("Reset")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.24, blue: 0.20))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.92, green: 0.82, blue: 0.70))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    /// Like the original sprout: `scaledToFit` + `maxWidth` only. Final stage floor ~62% screen width.
    private func oakTreeStageImage(imageName: String, stage: Int, maxWidth: CGFloat, screenWidth: CGFloat) -> some View {
        let isFinalStage = stage == 5
        let cappedWidth = isFinalStage ? max(maxWidth, screenWidth * 0.62) : maxWidth

        return Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: cappedWidth)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            .animation(.easeInOut(duration: 0.28), value: imageName)
            .accessibilityLabel("Oak tree, stage \(stage) of 5")
    }

    private func oakTreeMaxWidthFraction(for stage: Int) -> CGFloat {
        if stage <= 1 { return 0.16 }
        let t = Double(stage - 2) / 3.0
        let base = lerp(0.38, 0.58, t)
        switch stage {
        case 4: return max(base, 0.64)
        case 5: return max(base, 0.78)
        default: return base
        }
    }

    private func growOakStage() {
        guard oakShowcaseStage < 5 else { return }
        withAnimation(.easeInOut(duration: 0.28)) {
            oakShowcaseStageStored = oakShowcaseStage + 1
        }
    }

    private func resetOakStage() {
        withAnimation(.easeInOut(duration: 0.28)) {
            oakShowcaseStageStored = 1
        }
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
