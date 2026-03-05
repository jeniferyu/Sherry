import Foundation
import CoreData

extension DailyRecord {

    var sessionList: [PrayerSession] {
        (sessions as? Set<PrayerSession>)?.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) } ?? []
    }

    var formattedDate: String {
        guard let d = date else { return "" }
        return DateFormatter.mediumDate.string(from: d)
    }

    var dayOfMonth: Int {
        guard let d = date else { return 0 }
        return Calendar.current.component(.day, from: d)
    }

    var totalSessionCount: Int {
        Int(personalSessionCount)
    }

    @discardableResult
    static func findOrCreate(for date: Date, in context: NSManagedObjectContext) -> DailyRecord {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<DailyRecord> = DailyRecord.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let record = DailyRecord(context: context)
        record.id = UUID()
        record.date = startOfDay
        record.personalSessionCount = 0
        record.intercessoryItemCount = 0
        record.hasFootprint = false
        return record
    }
}

extension DailyRecord: Identifiable {}
