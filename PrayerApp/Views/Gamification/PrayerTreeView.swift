import SwiftUI

struct PrayerTreeView: View {
    @StateObject private var viewModel = PrayerTreeViewModel()
    @State private var showingLeafDetail = false
    @State private var showingStarDetail = false
    @State private var showingDecorationLibrary = false
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                // Sky gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.53, green: 0.70, blue: 0.90),
                        Color(red: 0.75, green: 0.88, blue: 0.95),
                        Color.appBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geo in
                    ZStack {
                        // Stars (top sky area)
                        ForEach(viewModel.stars) { star in
                            StarNodeView(star: star) {
                                viewModel.selectStar(star)
                                showingStarDetail = true
                            }
                            .position(
                                x: star.position.x * geo.size.width,
                                y: star.position.y * geo.size.height * 0.35
                            )
                        }

                        // Tree image / illustration
                        treeIllustration
                            .frame(width: geo.size.width, height: geo.size.height * 0.75)
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.60)

                        // Leaves (on tree canopy area)
                        ForEach(viewModel.leaves) { leaf in
                            LeafNodeView(leaf: leaf) {
                                viewModel.selectLeaf(leaf)
                                showingLeafDetail = true
                            }
                            .position(
                                x: leaf.position.x * geo.size.width,
                                y: 0.25 * geo.size.height + leaf.position.y * geo.size.height * 0.45
                            )
                        }
                    }
                    .onAppear { canvasSize = geo.size }
                }

                // Leaf/Star count pill
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: AppSpacing.md) {
                            Label("\(viewModel.leaves.count)", systemImage: AppIcons.leaf)
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
                .padding(.top, AppSpacing.md)
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
        .sheet(isPresented: $showingLeafDetail) {
            if let leaf = viewModel.selectedLeaf {
                LeafDetailSheet(leaf: leaf, onDismiss: {
                    showingLeafDetail = false
                    viewModel.clearSelection()
                })
                .presentationDetents([.medium])
            }
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
        .navigationDestination(isPresented: $showingDecorationLibrary) {
            DecorationLibraryView()
        }
    }

    // MARK: - Tree Illustration

    private var treeIllustration: some View {
        Canvas { context, size in
            let trunkWidth: CGFloat = size.width * 0.06
            let trunkHeight: CGFloat = size.height * 0.45
            let trunkX: CGFloat = size.width / 2
            let trunkTop: CGFloat = size.height * 0.55

            // Trunk
            var trunk = Path()
            trunk.move(to: CGPoint(x: trunkX - trunkWidth / 2, y: size.height))
            trunk.addLine(to: CGPoint(x: trunkX - trunkWidth / 4, y: trunkTop))
            trunk.addLine(to: CGPoint(x: trunkX + trunkWidth / 4, y: trunkTop))
            trunk.addLine(to: CGPoint(x: trunkX + trunkWidth / 2, y: size.height))
            context.fill(trunk, with: .color(Color(red: 0.55, green: 0.38, blue: 0.22)))

            // Canopy layers (3 ellipses)
            let canopyColor = Color(red: 0.35, green: 0.60, blue: 0.38)
            let darkCanopy  = Color(red: 0.28, green: 0.50, blue: 0.30)

            let layers: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                // (centerY ratio, width ratio, height ratio, darkness)
                (0.62, 0.70, 0.28, 1.0),
                (0.45, 0.55, 0.28, 0.85),
                (0.28, 0.40, 0.28, 0.70),
            ]

            for (cy, w, h, _) in layers {
                let rect = CGRect(
                    x: trunkX - size.width * w / 2,
                    y: size.height * cy - size.height * h / 2,
                    width: size.width * w,
                    height: size.height * h
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(canopyColor)
                )
                // Slight shadow layer
                let shadowRect = rect.insetBy(dx: 8, dy: 4).offsetBy(dx: 4, dy: 8)
                context.fill(
                    Path(ellipseIn: shadowRect),
                    with: .color(darkCanopy.opacity(0.35))
                )
            }

            // Ground
            let groundRect = CGRect(x: 0, y: size.height * 0.92, width: size.width, height: size.height * 0.08)
            context.fill(
                Path(roundedRect: groundRect, cornerRadius: 0),
                with: .color(Color(red: 0.55, green: 0.72, blue: 0.42).opacity(0.5))
            )
        }
    }
}

// MARK: - Leaf Node

struct LeafNodeView: View {
    let leaf: LeafData
    let onTap: () -> Void

    @State private var animate = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if leaf.isAnswered {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(Color.appAnswered)
                        .shadow(color: Color.appAnswered.opacity(0.5), radius: 4)
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.thanksgivingColor)
                        .rotationEffect(.degrees(Double.random(in: -30...30)))
                        .scaleEffect(animate ? 1.05 : 0.95)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: Double.random(in: 1.5...2.5))
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
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
                .foregroundColor(star.prayerItem.statusEnum == .answered ? .appAnswered : .white.opacity(0.8))
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
                // Star icon
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
