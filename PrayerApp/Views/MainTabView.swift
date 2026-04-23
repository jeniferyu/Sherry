import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 3
    @State private var showingAddPrayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                RoadMapView()
                    .tag(0)

                PrayerTreeView()
                    .tag(1)

                Color.clear
                    .tag(2)

                PrayerListView()
                    .tag(3)

                IntercessoryListView()
                    .tag(4)
            }
            .toolbar(.hidden, for: .tabBar)

            customTabBar
        }
        .sheet(isPresented: $showingAddPrayer) {
            AddPrayerView()
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Custom Tab Bar
    //
    // White floating bar with soft shadow; active tab uses brand purple. Center FAB
    // stays gold for the “+ Prayer” action.

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(label: "Prayers", tag: 3) {
                Image("prayingHands")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            tabButton(icon: AppIcons.intercession, label: "Others", tag: 4)

            centerFAB
                .frame(maxWidth: .infinity)

            tabButton(icon: AppIcons.challenges, label: "Challenges", tag: 0)
            tabButton(icon: AppIcons.tree, label: "Tree", tag: 1)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(minHeight: 76)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.xxs)
        .shadow(color: Color.black.opacity(0.10), radius: 16, y: 6)
    }

    /// Center “+” button: 20% smaller than the original 64pt circle (icon + ring + shadow scale together).
    private var centerFAB: some View {
        let s: CGFloat = 0.8
        let diameter = 64 * s
        return Button {
            showingAddPrayer = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appGameGold, Color(red: 0.95, green: 0.70, blue: 0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: 3 * s)
                    )
                    .shadow(color: Color.appGameGold.opacity(0.55), radius: 12 * s, y: 5 * s)

                Image(systemName: AppIcons.add)
                    .font(.system(size: 26 * s, weight: .bold))
                    .foregroundColor(Color.appGameDark)
            }
            .contentShape(Circle())
        }
        // Less negative = sits lower on screen (still slightly above tab bar row).
        .offset(y: -8 * s)
    }

    // SF Symbol overload.
    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        tabButton(label: label, tag: tag) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
        }
    }

    private func tabButton<Icon: View>(label: String, tag: Int, @ViewBuilder icon: () -> Icon) -> some View {
        let isActive = selectedTab == tag
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.14))
                            .frame(width: 52, height: 36)
                    }
                    icon()
                        .foregroundColor(isActive ? Color.appPrimary : Color.appTextTertiary)
                }
                .frame(height: 38)

                Text(label)
                    .font(.system(size: 11, weight: isActive ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isActive ? Color.appPrimary : Color.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
