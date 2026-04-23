import Foundation
import Combine

final class PrayerCaptureViewModel: ObservableObject {

    // MARK: - Dependencies
    private let prayerService: PrayerService
    private let sessionService: SessionService

    // MARK: - Form State
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var selectedCategory: PrayerCategory = .adoration
    @Published var isIntercessory: Bool = false
    @Published var selectedIntercessoryGroup: IntercessoryGroup = .family
    @Published var tags: String = ""

    // MARK: - UI State
    @Published var isSaving: Bool = false
    @Published var savedItem: PrayerItem?
    @Published var startedSession: PrayerSession?

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Init
    init(
        prayerService: PrayerService = PrayerService(),
        sessionService: SessionService = SessionService()
    ) {
        self.prayerService = prayerService
        self.sessionService = sessionService
    }

    // MARK: - Actions

    /// Creates a PrayerItem and saves it to the Today list without starting a session.
    func saveForLater() {
        guard isValid else { return }
        isSaving = true
        let tagList = tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let item = prayerService.createPrayer(
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.isEmpty ? nil : content,
            category: isIntercessory ? .supplication : selectedCategory,
            isIntercessory: isIntercessory,
            intercessoryGroup: isIntercessory ? selectedIntercessoryGroup : nil,
            tags: tagList
        )
        savedItem = item
        isSaving = false
        resetForm()
    }

    /// Creates a PrayerItem and immediately begins a session with it.
    func prayNow() -> PrayerSession? {
        guard isValid else { return nil }
        isSaving = true
        let tagList = tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let item = prayerService.createPrayer(
            title: title.trimmingCharacters(in: .whitespaces),
            content: content.isEmpty ? nil : content,
            category: isIntercessory ? .supplication : selectedCategory,
            isIntercessory: isIntercessory,
            intercessoryGroup: isIntercessory ? selectedIntercessoryGroup : nil,
            tags: tagList
        )
        let session = sessionService.createSession(items: [item])
        startedSession = session
        isSaving = false
        resetForm()
        return session
    }

    func saveVoiceRecording(url: URL) {
        // Placeholder: store the URL path as audioURL on the next saved item.
        // Full implementation would handle AVFoundation recording.
        print("Voice recording saved at: \(url)")
    }

    func resetForm() {
        title = ""
        content = ""
        selectedCategory = .adoration
        isIntercessory = false
        selectedIntercessoryGroup = .family
        tags = ""
    }
}
