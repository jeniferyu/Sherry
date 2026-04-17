import SwiftUI

// MARK: - Inventory (Backpack) Overlay

struct InventoryView: View {
    @Binding var isPresented: Bool
    @State private var selectedTab: DecorationType = .tree
    @State private var selectedTreeAssetName: String? = nil
    @State private var selectedGroundAssetName: String? = nil
    @State private var selectedSkyAssetName: String? = nil

    private static let treeTabAssetNames = ["lights_on_wire", "birdhouse"]
    private static let groundTabAssetNames = ["squirrel"]
    private static let skyTabAssetNames = ["pink_bird"]

    // ── Warm “cozy game” palette (cream / tan / soft brown) ───────────────
    private let panelBody      = Color(red: 0.82, green: 0.71, blue: 0.55) // ~#D2B48C tan
    private let headerCream    = Color(red: 0.96, green: 0.90, blue: 0.80) // ~#F5E6CC
    private let outerBorder    = Color(red: 0.36, green: 0.25, blue: 0.20) // dark brown frame
    private let innerBorder    = Color(red: 0.98, green: 0.95, blue: 0.88) // cream inner rim
    private let accentBrown    = Color(red: 0.45, green: 0.32, blue: 0.24)
    /// Inactive segments sit slightly below the panel surface (like the reference purple tabs).
    private let tabInactiveBg  = Color(red: 0.72, green: 0.62, blue: 0.50)
    /// Solid gold segment for the active tab (matches “bright gold” in the reference layout).
    private let tabActiveBg    = Color(red: 0.91, green: 0.76, blue: 0.38)
    private let tabInactiveText = Color(red: 0.58, green: 0.50, blue: 0.42)
    private let gridBg         = Color(red: 0.78, green: 0.67, blue: 0.52) // grid well, slightly deeper
    private let slotBase       = Color(red: 0.72, green: 0.60, blue: 0.48) // ~#A68B6D recessed slot
    private let slotHighlight  = Color(red: 0.84, green: 0.76, blue: 0.64)
    private let cellLockedFill = Color(red: 0.62, green: 0.52, blue: 0.42)
    private let titleText      = Color(red: 0.32, green: 0.22, blue: 0.16)
    private let subtleText     = Color(red: 0.45, green: 0.36, blue: 0.28)
    private let selectionRing  = Color(red: 0.99, green: 0.96, blue: 0.88) // warm cream highlight

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
    /// Max panel height as a fraction of screen height (30–40% reads as a compact floating dialog).
    private let panelMaxHeightFraction: CGFloat = 0.35
    /// Extra space below the outer brown frame (gap above the main tab bar / bottom safe area).
    private let panelBottomMargin: CGFloat = 28
    // Minimum total cells shown — fills the grid so it never looks sparse.
    private let minCells = 15

    var body: some View {
        ZStack {
            // No dimming scrim — the tree scene stays fully visible behind the panel.
            VStack(spacing: 0) {
                panelHeader
                tabPicker
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                itemGrid
                applyFooter
            }
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(outerBorder, lineWidth: 2.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(innerBorder, lineWidth: 2)
                    .padding(5)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, panelBottomMargin)
            .frame(maxHeight: UIScreen.main.bounds.height * panelMaxHeightFraction)
            .shadow(color: Color(red: 0.25, green: 0.18, blue: 0.12).opacity(0.28), radius: 18, y: 8)
        }
        .onChange(of: selectedTab) { _ in
            selectedTreeAssetName = nil
            selectedGroundAssetName = nil
            selectedSkyAssetName = nil
        }
    }

    // MARK: - Header

    private var panelHeader: some View {
        ZStack(alignment: .trailing) {
            // Decorative title row with flanking lines
            HStack(spacing: 10) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentBrown.opacity(0), accentBrown.opacity(0.55)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text("Backpack")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(titleText)
                    .fixedSize()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentBrown.opacity(0.55), accentBrown.opacity(0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, 50)

            // Close — soft terracotta, warm frame
            Button(action: dismissPanel) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.78, green: 0.48, blue: 0.38))
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(Color(red: 0.55, green: 0.38, blue: 0.28), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.98, green: 0.95, blue: 0.90))
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
        }
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(headerCream)
    }

    // MARK: - Tab Picker (Tree / Ground / Sky)

    /// Single pill-shaped bar: adjacent segments, gold active slice, no dividers or notch (classic HUD style).
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DecorationType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = type }
                } label: {
                    let active = selectedTab == type
                    Text(tabLabel(type))
                        .font(.system(size: 13, weight: active ? .bold : .medium, design: .rounded))
                        .foregroundColor(active ? titleText : tabInactiveText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(active ? tabActiveBg : tabInactiveBg)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(accentBrown.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Item Grid

    private var assetNamesForSelectedTab: [String] {
        switch selectedTab {
        case .tree:       return Self.treeTabAssetNames
        case .background: return Self.groundTabAssetNames
        case .sky:        return Self.skyTabAssetNames
        }
    }

    private var itemGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 6) {
                let cells = paddedInventoryAssetCells(assetNamesForSelectedTab)
                ForEach(0..<cells.count, id: \.self) { idx in
                    if let name = cells[idx] {
                        inventoryAssetCell(imageName: name, selection: selectionBinding(for: selectedTab))
                    } else {
                        emptyCell
                    }
                }
            }
            .padding(10)
        }
        .background(gridBg)
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private func selectionBinding(for tab: DecorationType) -> Binding<String?> {
        switch tab {
        case .tree:       return $selectedTreeAssetName
        case .background: return $selectedGroundAssetName
        case .sky:        return $selectedSkyAssetName
        }
    }

    /// Bundled artwork only (no Core Data `Decoration` rows).
    private func paddedInventoryAssetCells(_ names: [String]) -> [String?] {
        var result: [String?] = names
        let n = result.count
        let target = max(minCells, n + (5 - n % 5) % 5)
        while result.count < target { result.append(nil) }
        return result
    }

    @ViewBuilder
    private func inventoryAssetCell(imageName: String, selection: Binding<String?>) -> some View {
        let isSelected = selection.wrappedValue == imageName
        Button {
            if selection.wrappedValue == imageName {
                selection.wrappedValue = nil
            } else {
                selection.wrappedValue = imageName
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [slotHighlight, slotBase],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                Color(red: 0.42, green: 0.32, blue: 0.24).opacity(0.45),
                                lineWidth: 1
                            )
                    )

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? selectionRing : Color.clear, lineWidth: isSelected ? 3.5 : 0)
            )
            .shadow(
                color: isSelected ? selectionRing.opacity(0.55) : .clear,
                radius: isSelected ? 8 : 0,
                y: 1
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyCell: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [slotBase.opacity(0.85), cellLockedFill.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(red: 0.38, green: 0.28, blue: 0.20).opacity(0.35), lineWidth: 1)
            )
    }

    // MARK: - Apply Footer

    @ViewBuilder
    private var applyFooter: some View {
        if let payload = applyFooterPayload() {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [slotHighlight, slotBase],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(accentBrown.opacity(0.25), lineWidth: 1)
                        )
                    Image(payload.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(titleText)
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.40, green: 0.70, blue: 0.95))
                        Text("\(payload.dropCount)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(subtleText)
                    }
                }

                Spacer()

                Button {
                    payload.clearSelection()
                    dismissPanel()
                } label: {
                    Text("Apply")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(titleText)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.88, green: 0.72, blue: 0.48),
                                    Color(red: 0.76, green: 0.58, blue: 0.38)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(accentBrown.opacity(0.45), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                headerCream
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(accentBrown.opacity(0.12))
                            .frame(height: 1)
                    }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func applyFooterPayload() -> (
        imageName: String,
        title: String,
        dropCount: Int,
        clearSelection: () -> Void
    )? {
        switch selectedTab {
        case .tree:
            guard let n = selectedTreeAssetName, let d = inventoryAssetDropCount(for: n) else { return nil }
            return (n, inventoryAssetDisplayTitle(n), d, { selectedTreeAssetName = nil })
        case .background:
            guard let n = selectedGroundAssetName, let d = inventoryAssetDropCount(for: n) else { return nil }
            return (n, inventoryAssetDisplayTitle(n), d, { selectedGroundAssetName = nil })
        case .sky:
            guard let n = selectedSkyAssetName, let d = inventoryAssetDropCount(for: n) else { return nil }
            return (n, inventoryAssetDisplayTitle(n), d, { selectedSkyAssetName = nil })
        }
    }

    // MARK: - Panel Background

    private var panelBackground: some View {
        ZStack {
            panelBody
            // Soft top highlight (paper / panel sheen)
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.22), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 48)
                Spacer()
            }
            // Decorative corner ornaments — all four corners
            VStack {
                HStack {
                    cornerOrnament()
                    Spacer()
                    cornerOrnament()
                }
                Spacer()
                HStack {
                    cornerOrnament()
                    Spacer()
                    cornerOrnament()
                }
            }
            .padding(14)
        }
    }

    private func cornerOrnament() -> some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: 8))
            .foregroundColor(accentBrown.opacity(0.35))
    }

    // MARK: - Helpers

    private func dismissPanel() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            isPresented = false
        }
    }

    private func inventoryAssetDisplayTitle(_ assetName: String) -> String {
        switch assetName {
        case "lights_on_wire": return "Lights on wire"
        case "birdhouse": return "Birdhouse"
        case "squirrel": return "Squirrel"
        case "pink_bird": return "Pink bird"
        default: return assetName.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func inventoryAssetDropCount(for assetName: String) -> Int? {
        switch assetName {
        case "lights_on_wire": return 5
        case "birdhouse": return 10
        case "squirrel": return 30
        case "pink_bird": return 40
        default: return nil
        }
    }

    private func tabLabel(_ type: DecorationType) -> String {
        switch type {
        case .tree:       return "Tree"
        case .background: return "Ground"
        case .sky:        return "Sky"
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.78, blue: 0.95),
                Color(red: 0.45, green: 0.68, blue: 0.40)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        InventoryView(isPresented: .constant(true))
    }
}
