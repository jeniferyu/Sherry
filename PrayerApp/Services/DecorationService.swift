import Foundation
import CoreData

final class DecorationService: ObservableObject {

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    private var context: NSManagedObjectContext { persistence.viewContext }

    // MARK: - Fetch

    func fetchAllDecorations() -> [Decoration] {
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Decoration.name, ascending: true)]
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
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Decoration.name, ascending: true)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Mutate

    func unlockDecoration(_ decoration: Decoration) {
        decoration.isUnlocked = true
        decoration.unlockedDate = Date()
        persistence.save()
    }

    func applyDecoration(_ decoration: Decoration) {
        // In a full implementation this would track "applied" state.
        // For now we just ensure it's unlocked.
        guard decoration.isUnlocked else { return }
        persistence.save()
    }

    // MARK: - Seed Default Decorations

    func seedDefaultDecorationsIfNeeded() {
        let request: NSFetchRequest<Decoration> = Decoration.fetchRequest()
        guard (try? context.count(for: request)) == 0 else { return }

        let defaults: [(String, DecorationType, String)] = [
            ("Golden Leaves",    .tree,       "streak_3"),
            ("Autumn Palette",   .tree,       "streak_7"),
            ("Winter Frost",     .tree,       "streak_30"),
            ("Sunrise Sky",      .sky,        "sessions_5"),
            ("Starry Night",     .sky,        "sessions_10"),
            ("Aurora",           .sky,        "sessions_50"),
            ("Wildflowers",      .background, "answered_1"),
            ("Meadow Path",      .background, "answered_5"),
        ]

        for (name, type, condition) in defaults {
            Decoration.create(in: context, name: name, type: type, unlockCondition: condition)
        }
        persistence.save()
    }
}
