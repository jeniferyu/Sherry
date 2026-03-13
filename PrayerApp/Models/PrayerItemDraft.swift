import Foundation

/// Lightweight in-memory representation of a prayer item during the guided ACTS flow.
/// Drafts are collected in `ACTSFlowViewModel` and persisted to Core Data only when
/// the user taps "Start Prayer Session."
struct PrayerItemDraft: Identifiable {
    let id: UUID = UUID()
    var title: String
    var content: String?
    var tags: [String]
    var category: PrayerCategory
    var isIntercessory: Bool
    var intercessoryGroup: IntercessoryGroup?
}
