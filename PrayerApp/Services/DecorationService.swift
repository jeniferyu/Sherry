import Foundation
import CoreData

/// Manages decorative items: their catalogue, availability, and purchase.
///
/// Matches the two-part unlock logic from §3.5.4 of the system design:
///   1. A decoration is *available* when the user's level meets its level requirement.
///   2. The user then *spends drops* (the consumable currency) to actually unlock it.
final class DecorationService: ObservableObject {

    private let persistence: PersistenceController
    private let gamificationService: GamificationService

    init(
        persistence: PersistenceController = .shared,
        gamificationService: GamificationService = GamificationService()
    ) {
        self.persistence = persistence
        self.gamificationService = gamificationService
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - Fetch

    func fetchAllDecorations() -> [Decoration] {
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Decoration.levelRequirement, ascending: true),
            NSSortDescriptor(keyPath: \Decoration.name, ascending: true),
        ]
        return (try? context.fetch(request)) ?? []
    }

    func fetchUnlockedDecorations() -> [Decoration] {
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        request.predicate = NSPredicate(format: "isUnlocked == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Decoration.unlockedDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func fetchLockedDecorations() -> [Decoration] {
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        request.predicate = NSPredicate(format: "isUnlocked == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Decoration.levelRequirement, ascending: true),
            NSSortDescriptor(keyPath: \Decoration.name, ascending: true),
        ]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Purchase / Unlock

    /// Attempts to purchase a locked decoration. Succeeds only when the user's
    /// level meets the requirement and they have enough drops. On success the
    /// drop balance is debited and the decoration is marked unlocked.
    @discardableResult
    func purchase(_ decoration: Decoration) -> Bool {
        guard !decoration.isUnlocked else { return false }
        let level = gamificationService.calculateLevel()
        guard decoration.isAvailable(atLevel: level) else { return false }
        guard gamificationService.spendDrops(Int(decoration.dropCost)) else { return false }

        decoration.isUnlocked = true
        decoration.unlockedDate = Date()
        persistence.save()
        return true
    }

    /// Development / admin helper — bypasses level and drop checks.
    func unlockDecoration(_ decoration: Decoration) {
        decoration.isUnlocked = true
        decoration.unlockedDate = Date()
        persistence.save()
    }

    func applyDecoration(_ decoration: Decoration) {
        guard decoration.isUnlocked else { return }
        persistence.save()
    }

    // MARK: - Seed Default Decorations

    /// Seeds a default catalogue aligned with §3.5.4:
    /// level gates availability, drops are spent to unlock.
    /// Early items come online around Levels 2–4, with seasonal / rare items
    /// reserved for higher levels.
    func seedDefaultDecorationsIfNeeded() {
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        guard (try? context.count(for: request)) == 0 else { return }

        // (name, type, levelRequirement, dropCost)
        let defaults: [(String, DecorationType, Int, Int)] = [
            ("Small Plant",      .tree,        2,  10),
            ("Golden Leaves",    .tree,        3,  15),
            ("New Tree Skin",    .tree,        4,  25),
            ("Autumn Palette",   .tree,        6,  40),
            ("Winter Frost",     .tree,        8,  60),

            ("Sunrise Sky",      .sky,         2,  12),
            ("Starry Night",     .sky,         5,  30),
            ("Aurora",           .sky,         8,  60),

            ("Wildflowers",      .background,  3,  20),
            ("Meadow Path",      .background,  5,  35),
            ("Seasonal Bloom",   .background,  8,  55),
        ]

        for (name, type, level, cost) in defaults {
            Decoration.create(
                in: context,
                name: name,
                type: type,
                levelRequirement: level,
                dropCost: cost
            )
        }
        persistence.save()
    }
}
