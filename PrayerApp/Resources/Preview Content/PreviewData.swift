import Foundation
import CoreData

struct PreviewData {

    /// Populates the in-memory store with sample data for SwiftUI Previews.
    static func populate(in context: NSManagedObjectContext) {
        let calendar = Calendar.current

        // MARK: - Prayer Items

        let p1 = PrayerItem.create(
            in: context,
            title: "Gratitude for family",
            content: "Lord, thank you for the gift of my family. Help me cherish each moment.",
            category: .thanksgiving,
            isIntercessory: false,
            tags: ["family", "gratitude"]
        )
        p1.prayedCount = 5
        p1.statusEnum = .prayed

        let p2 = PrayerItem.create(
            in: context,
            title: "Strength for the week",
            content: "Give me strength and focus for the challenges ahead.",
            category: .supplication,
            isIntercessory: false,
            tags: ["work", "strength"]
        )

        let p3 = PrayerItem.create(
            in: context,
            title: "Forgiveness and renewal",
            content: "Lord, forgive me for my shortcomings and renew a right spirit within me.",
            category: .confession,
            isIntercessory: false
        )
        p3.prayedCount = 2
        p3.statusEnum = .prayed

        let p4 = PrayerItem.create(
            in: context,
            title: "Praise for creation",
            content: "How great is our God! Thank you for the beauty of this world.",
            category: .adoration,
            isIntercessory: false,
            tags: ["praise", "worship"]
        )

        // Answered prayer
        let p5 = PrayerItem.create(
            in: context,
            title: "Job interview",
            content: "Lord, please guide me through this job interview.",
            category: .supplication,
            isIntercessory: false,
            tags: ["work", "guidance"]
        )
        p5.prayedCount = 8
        p5.statusEnum = .answered
        p5.lastPrayedDate = calendar.date(byAdding: .day, value: -2, to: Date())

        // Intercessory items
        let i1 = PrayerItem.create(
            in: context,
            title: "Mom's recovery",
            content: "Please heal and strengthen my mother as she recovers from surgery.",
            category: .supplication,
            isIntercessory: true,
            intercessoryGroup: .family,
            tags: ["health", "healing"]
        )
        i1.prayedCount = 12

        let i2 = PrayerItem.create(
            in: context,
            title: "James's faith journey",
            content: "Pray that James would encounter the living God in a powerful way.",
            category: .supplication,
            isIntercessory: true,
            intercessoryGroup: .friends
        )

        let i3 = PrayerItem.create(
            in: context,
            title: "Church building project",
            content: "Lord provide the resources and guidance for our church's new building.",
            category: .supplication,
            isIntercessory: true,
            intercessoryGroup: .church
        )
        i3.prayedCount = 3
        i3.statusEnum = .answered

        // MARK: - Sessions (past 5 days)

        let allPersonal = [p1, p2, p3, p4, p5]
        let allIntercessory = [i1, i2, i3]

        for daysAgo in 0..<5 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }

            let sessionItems: [PrayerItem]
            switch daysAgo {
            case 0: sessionItems = [p1, p2, i1]
            case 1: sessionItems = [p3, p4, i2]
            case 2: sessionItems = [p5, i1, i3]
            case 3: sessionItems = [p1, p3, i2]
            default: sessionItems = [p2, p4]
            }

            let session = PrayerSession(context: context)
            session.id = UUID()
            session.date = date
            session.duration = Float.random(in: 180...900)
            session.items = NSSet(array: sessionItems)

            // Daily record
            let record = DailyRecord.findOrCreate(for: date, in: context)
            record.hasFootprint = true
            record.personalSessionCount += 1
            record.intercessoryItemCount += Int16(sessionItems.filter { $0.isIntercessory }.count)
            session.dailyRecord = record
        }

        // MARK: - Decorations

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
            let d = Decoration.create(in: context, name: name, type: type, unlockCondition: condition)
            // Unlock first two as examples
            if name == "Golden Leaves" || name == "Wildflowers" {
                d.isUnlocked = true
                d.unlockedDate = Date()
            }
        }

        // Save
        try? context.save()
    }
}
