import SwiftUI

// MARK: - Orchard Panel (mirrors Backpack / Inventory layout)

private enum OrchardTab: Int, CaseIterable {
    case treeSpecies
    case pastTrees

    var title: String {
        switch self {
        case .treeSpecies: return "Tree Species"
        case .pastTrees:   return "Past Trees"
        }
    }
}

struct OrchardView: View {
    @Binding var isPresented: Bool
    @State private var selectedTab: OrchardTab = .treeSpecies
    @State private var selectedTreeSpeciesAsset: String? = nil

    private static let treeSpeciesAssetNames = ["oak", "pine", "willow"]
    /// Past trees: placeholder grid (no items yet).
    private static let pastTreesAssetNames: [String] = []

    // Fewer columns + tighter min count → visibly larger cells than the backpack grid.
    private let columnCount = 4
    private let gridSpacing: CGFloat = 8
    private let cellImagePadding: CGFloat = 10
    private let cellCornerRadius: CGFloat = 10

    // ── Same palette as InventoryView ──────────────────────────────────────
    private let panelBody      = Color(red: 0.82, green: 0.71, blue: 0.55)
    private let headerCream    = Color(red: 0.96, green: 0.90, blue: 0.80)
    private let outerBorder    = Color(red: 0.36, green: 0.25, blue: 0.20)
    private let innerBorder    = Color(red: 0.98, green: 0.95, blue: 0.88)
    private let accentBrown    = Color(red: 0.45, green: 0.32, blue: 0.24)
    private let tabInactiveBg  = Color(red: 0.72, green: 0.62, blue: 0.50)
    private let tabActiveBg    = Color(red: 0.91, green: 0.76, blue: 0.38)
    private let tabInactiveText = Color(red: 0.58, green: 0.50, blue: 0.42)
    private let gridBg         = Color(red: 0.78, green: 0.67, blue: 0.52)
    private let slotBase       = Color(red: 0.72, green: 0.60, blue: 0.48)
    private let slotHighlight  = Color(red: 0.84, green: 0.76, blue: 0.64)
    private let cellLockedFill = Color(red: 0.62, green: 0.52, blue: 0.42)
    private let titleText      = Color(red: 0.32, green: 0.22, blue: 0.16)
    private let selectionRing  = Color(red: 0.99, green: 0.96, blue: 0.88)

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnCount)
    }

    private let panelMaxHeightFraction: CGFloat = 0.41
    private let panelBottomMargin: CGFloat = 28
    private let minCells = 12

    var body: some View {
        ZStack {
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
            selectedTreeSpeciesAsset = nil
        }
    }

    // MARK: - Header

    private var panelHeader: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentBrown.opacity(0), accentBrown.opacity(0.55)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Text("Orchard")
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

    // MARK: - Tabs

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(OrchardTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab }
                } label: {
                    let active = selectedTab == tab
                    Text(tab.title)
                        .font(.system(size: 12, weight: active ? .bold : .medium, design: .rounded))
                        .foregroundColor(active ? titleText : tabInactiveText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
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

    // MARK: - Grid

    private var assetNamesForTab: [String] {
        switch selectedTab {
        case .treeSpecies: return Self.treeSpeciesAssetNames
        case .pastTrees:   return Self.pastTreesAssetNames
        }
    }

    private var itemGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                let cells = paddedAssetCells(assetNamesForTab)
                ForEach(0..<cells.count, id: \.self) { idx in
                    if let name = cells[idx] {
                        orchardAssetCell(imageName: name)
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

    private func paddedAssetCells(_ names: [String]) -> [String?] {
        var result: [String?] = names
        let n = result.count
        let pad = columnCount
        let target = max(minCells, n + (pad - n % pad) % pad)
        while result.count < target { result.append(nil) }
        return result
    }

    @ViewBuilder
    private func orchardAssetCell(imageName: String) -> some View {
        let isSelected = selectedTreeSpeciesAsset == imageName
        Button {
            guard selectedTab == .treeSpecies else { return }
            if selectedTreeSpeciesAsset == imageName {
                selectedTreeSpeciesAsset = nil
            } else {
                selectedTreeSpeciesAsset = imageName
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [slotHighlight, slotBase],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                            .strokeBorder(
                                Color(red: 0.42, green: 0.32, blue: 0.24).opacity(0.45),
                                lineWidth: 1
                            )
                    )

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(cellImagePadding)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
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
        RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [slotBase.opacity(0.85), cellLockedFill.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                    .strokeBorder(Color(red: 0.38, green: 0.28, blue: 0.20).opacity(0.35), lineWidth: 1)
            )
    }

    // MARK: - Apply Footer

    @ViewBuilder
    private var applyFooter: some View {
        if selectedTab == .treeSpecies,
           let name = selectedTreeSpeciesAsset {
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
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                }

                Text(orchardAssetDisplayTitle(name))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(titleText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    selectedTreeSpeciesAsset = nil
                    dismissPanel()
                } label: {
                    Text("Plant")
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

    private var panelBackground: some View {
        ZStack {
            panelBody
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.22), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 48)
                Spacer()
            }
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

    private func dismissPanel() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            isPresented = false
        }
    }

    private func orchardAssetDisplayTitle(_ assetName: String) -> String {
        switch assetName {
        case "oak": return "Oak"
        case "pine": return "Pine"
        case "willow": return "Willow"
        default: return assetName.replacingOccurrences(of: "_", with: " ").capitalized
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
        OrchardView(isPresented: .constant(true))
    }
}
