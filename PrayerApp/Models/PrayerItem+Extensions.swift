import Foundation
import CoreData

extension PrayerItem {

    // MARK: - Typed Accessors

    var categoryEnum: PrayerCategory {
        get { PrayerCategory(rawValue: category ?? "supplication") ?? .supplication }
        set { category = newValue.rawValue }
    }

    var statusEnum: PrayerStatus {
        get { PrayerStatus(rawValue: status ?? "ongoing") ?? .ongoing }
        set { status = newValue.rawValue }
    }

    var intercessoryGroupEnum: IntercessoryGroup? {
        get {
            guard let g = intercessoryGroup else { return nil }
            return IntercessoryGroup(rawValue: g)
        }
        set { intercessoryGroup = newValue?.rawValue }
    }

    var tagList: [String] {
        get { tags?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } ?? [] }
        set { tags = newValue.joined(separator: ",") }
    }

    var sessionList: [PrayerSession] {
        (sessions as? Set<PrayerSession>)?.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) } ?? []
    }

    // MARK: - Computed Properties

    var isAnswered: Bool { statusEnum == .answered }
    var isActive: Bool   { statusEnum.isActive }

    var formattedCreatedDate: String {
        guard let d = createdDate else { return "" }
        return DateFormatter.mediumDate.string(from: d)
    }

    var formattedLastPrayedDate: String? {
        guard let d = lastPrayedDate else { return nil }
        return DateFormatter.mediumDate.string(from: d)
    }

    // MARK: - Convenience Init

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        title: String,
        content: String? = nil,
        category: PrayerCategory = .supplication,
        isIntercessory: Bool = false,
        intercessoryGroup: IntercessoryGroup? = nil,
        tags: [String] = []
    ) -> PrayerItem {
        let item = PrayerItem(context: context)
        item.id = UUID()
        item.title = title
        item.content = content
        item.categoryEnum = category
        item.statusEnum = .ongoing
        item.isIntercessory = isIntercessory
        item.intercessoryGroupEnum = intercessoryGroup
        item.tagList = tags
        item.createdDate = Date()
        item.prayedCount = 0
        return item
    }
}

// MARK: - Identifiable
extension PrayerItem: Identifiable {}

// MARK: - DateFormatter Helper
extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}
