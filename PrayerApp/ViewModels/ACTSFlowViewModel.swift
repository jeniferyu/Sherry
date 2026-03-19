import Foundation
import Combine

// MARK: - Flow Mode & Screen

enum FlowMode {
    case acts
    case single
}

enum FlowScreen: Equatable {
    case styleSelection
    case actsStep(PrayerCategory)
    case actsReview
    case singleCategoryPick
    case singleEntry(PrayerCategory)
}

// MARK: - Entry Step Kind

enum EntryStepKind: Equatable {
    case title
    case description
    case forWhom
    case tags
}

// MARK: - ACTSFlowViewModel

final class ACTSFlowViewModel: ObservableObject {

    // MARK: - Dependencies
    private let prayerService: PrayerService
    private let sessionService: SessionService

    // MARK: - Navigation State
    @Published var currentScreen: FlowScreen = .styleSelection

    // MARK: - Collected Drafts
    @Published var collectedDrafts: [PrayerCategory: [PrayerItemDraft]] = [:]

    // MARK: - Conversational Entry State
    @Published var entryStep: Int = 0
    @Published var showCollectedSummary: Bool = false

    // MARK: - Current Form Fields
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var tags: String = ""
    @Published var isForOthers: Bool = false
    @Published var intercessoryGroup: IntercessoryGroup = .family

    // MARK: - Review Screen
    @Published var todayPrayers: [PrayerItem] = []
    @Published var includeTodayPrayers: Bool = false

    var isFormValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Init
    init(
        prayerService: PrayerService = PrayerService(),
        sessionService: SessionService = SessionService()
    ) {
        self.prayerService = prayerService
        self.sessionService = sessionService
    }

    // MARK: - Navigation

    func selectACTS() {
        collectedDrafts = [:]
        currentScreen = .actsStep(.adoration)
    }

    func selectSingle() {
        collectedDrafts = [:]
        currentScreen = .singleCategoryPick
    }

    func selectSingleCategory(_ category: PrayerCategory) {
        clearForm()
        currentScreen = .singleEntry(category)
    }

    func skipStep() {
        guard case .actsStep(let category) = currentScreen else { return }
        advance(from: category)
    }

    func nextStep() {
        guard case .actsStep(let category) = currentScreen else { return }
        advance(from: category)
    }

    private func advance(from category: PrayerCategory) {
        clearForm()
        switch category {
        case .adoration:    currentScreen = .actsStep(.confession)
        case .confession:   currentScreen = .actsStep(.thanksgiving)
        case .thanksgiving: currentScreen = .actsStep(.supplication)
        case .supplication:
            loadTodayPrayers()
            currentScreen = .actsReview
        }
    }

    func goBackToStyleSelection() {
        collectedDrafts = [:]
        clearForm()
        currentScreen = .styleSelection
    }

    // MARK: - Draft Management

    /// Appends the current form as a draft for the given category. Clears form on success.
    @discardableResult
    func addCurrentDraft(for category: PrayerCategory) -> Bool {
        guard isFormValid else { return false }
        let tagList = tags
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let draft = PrayerItemDraft(
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.isEmpty ? nil : content,
            tags: tagList,
            category: category,
            isIntercessory: (category == .supplication) && isForOthers,
            intercessoryGroup: (category == .supplication && isForOthers) ? intercessoryGroup : nil
        )
        collectedDrafts[category, default: []].append(draft)
        clearForm()
        showCollectedSummary = true
        return true
    }

    func removeDraft(id: UUID, category: PrayerCategory) {
        collectedDrafts[category]?.removeAll { $0.id == id }
    }

    var totalDraftCount: Int {
        collectedDrafts.values.reduce(0) { $0 + $1.count }
    }

    // MARK: - Review

    private func loadTodayPrayers() {
        todayPrayers = prayerService.fetchTodayPrayers()
    }

    // MARK: - Start Session

    /// Persists all collected drafts (+ optional today prayers) and creates a PrayerSession.
    /// Returns the session items ready for `PrayerSessionViewModel.startSession(items:)`.
    func buildSessionItems() -> [PrayerItem] {
        // Persist drafts in ACTS order
        let orderedCategories: [PrayerCategory] = [.adoration, .confession, .thanksgiving, .supplication]
        var items: [PrayerItem] = []

        for category in orderedCategories {
            for draft in collectedDrafts[category] ?? [] {
                let item = prayerService.createPrayer(
                    title: draft.title,
                    content: draft.content,
                    category: draft.category,
                    isIntercessory: draft.isIntercessory,
                    intercessoryGroup: draft.intercessoryGroup,
                    tags: draft.tags
                )
                items.append(item)
            }
        }

        // Append today's saved prayers if the user chose to include them
        if includeTodayPrayers {
            items.append(contentsOf: todayPrayers)
        }

        return items
    }

    /// Builds a single-prayer session item from the current form (Single Prayer flow).
    func buildSingleSessionItem(category: PrayerCategory) -> PrayerItem {
        let tagList = tags
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return prayerService.createPrayer(
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.isEmpty ? nil : content,
            category: category,
            isIntercessory: (category == .supplication) && isForOthers,
            intercessoryGroup: (category == .supplication && isForOthers) ? intercessoryGroup : nil,
            tags: tagList
        )
    }

    // MARK: - Conversational Entry Navigation

    func entrySteps(for category: PrayerCategory) -> [EntryStepKind] {
        if category == .supplication {
            return [.title, .description, .forWhom, .tags]
        }
        return [.title, .description, .tags]
    }

    func currentEntryStep(for category: PrayerCategory) -> EntryStepKind {
        let steps = entrySteps(for: category)
        let index = min(entryStep, steps.count - 1)
        return steps[index]
    }

    func advanceEntryStep(for category: PrayerCategory) {
        let steps = entrySteps(for: category)
        if entryStep < steps.count - 1 {
            entryStep += 1
        }
    }

    func goBackEntryStep() {
        if entryStep > 0 {
            entryStep -= 1
        }
    }

    func isLastEntryStep(for category: PrayerCategory) -> Bool {
        entryStep >= entrySteps(for: category).count - 1
    }

    // MARK: - Helpers

    func clearForm() {
        title = ""
        content = ""
        tags = ""
        isForOthers = false
        intercessoryGroup = .family
        entryStep = 0
        showCollectedSummary = false
    }

    var actsStepOrder: [PrayerCategory] { [.adoration, .confession, .thanksgiving, .supplication] }

    func nextCategoryLabel(after category: PrayerCategory) -> String {
        switch category {
        case .adoration:    return "Confession"
        case .confession:   return "Thanksgiving"
        case .thanksgiving: return "Supplication"
        case .supplication: return "Review"
        }
    }

    func stepPrompt(for category: PrayerCategory) -> String {
        switch category {
        case .adoration:    return "What would you like to praise God for today?"
        case .confession:   return "What would you like to confess before God?"
        case .thanksgiving: return "What are you thankful for today?"
        case .supplication: return "What would you like to ask God for?"
        }
    }

    func descriptionPrompt(for category: PrayerCategory) -> String {
        switch category {
        case .adoration:    return "Would you like to share why this moves your heart?"
        case .confession:   return "Take a moment — anything more you'd like to express?"
        case .thanksgiving: return "What makes this feel especially meaningful to you?"
        case .supplication: return "Would you like to add more details about this request?"
        }
    }

    func tagsPrompt() -> String {
        return "Any tags to help you find this prayer later?"
    }
}
