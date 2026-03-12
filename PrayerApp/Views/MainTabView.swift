import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showingAddPrayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                RoadMapView()
                    .tag(0)

                PrayerTreeView()
                    .tag(1)

                // Placeholder for center "+" tab
                Color.clear
                    .tag(2)

                PrayerListView()
                    .tag(3)

                IntercessoryListView()
                    .tag(4)
            }
            // Remove default tab bar
            .toolbar(.hidden, for: .tabBar)

            // Custom tab bar
            customTabBar
        }
        .sheet(isPresented: $showingAddPrayer) {
            AddPrayerView()
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: AppIcons.map, label: "Journey", tag: 0)
            tabButton(icon: AppIcons.tree, label: "Tree", tag: 1)

            // Center FAB
            Button {
                showingAddPrayer = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, y: 4)
                    Image(systemName: AppIcons.add)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -12)
            .frame(maxWidth: .infinity)

            tabButton(label: "Prayers", tag: 3) {
                Image("prayingHands")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            tabButton(icon: AppIcons.intercession, label: "Others", tag: 4)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.md)
        .background(
            Color.appSurface
                .cornerRadius(AppRadius.xl)
                .shadow(color: Color.black.opacity(0.10), radius: 16, y: -4)
        )
        .padding(.horizontal, AppSpacing.md)
    }

    // Convenience overload for SF Symbol tab buttons
    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        tabButton(label: label, tag: tag) {
            Image(systemName: icon)
                .font(.system(size: 22))
        }
    }

    // Base implementation accepting any icon view
    private func tabButton<Icon: View>(label: String, tag: Int, @ViewBuilder icon: () -> Icon) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: AppSpacing.xxs) {
                icon()
                    .foregroundColor(selectedTab == tag ? Color.appPrimary : Color.appTextTertiary)
                Text(label)
                    .font(AppFont.caption2())
                    .foregroundColor(selectedTab == tag ? Color.appPrimary : Color.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
