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
        }
    }
}
