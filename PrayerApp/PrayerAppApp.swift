import SwiftUI

@main
struct PrayerAppApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Seed default decorations on first launch
        DecorationService(persistence: persistenceController).seedDefaultDecorationsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                // Light scheme → dark status-bar content (time, battery) on mint backgrounds.
                .preferredColorScheme(.light)
                .background(gameRootBackground.ignoresSafeArea())
        }
    }

    /// Fills the safe area behind the status bar so it matches list/tree/calendar screens.
    private var gameRootBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 0.96),
                Color.appBackground,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
