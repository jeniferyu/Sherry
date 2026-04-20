import Foundation
import Combine

final class PrayerSessionViewModel: ObservableObject {

    // MARK: - Dependencies
    private let prayerService: PrayerService
    private let sessionService: SessionService
    private let gamificationService: GamificationService

    // MARK: - Published State
    @Published var sessionItems: [PrayerItem] = []
    @Published var prayedItems: [PrayerItem] = []
    @Published var currentItemIndex: Int = 0
    @Published var isInSession: Bool = false
    @Published var isFinished: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var finishedSession: PrayerSession?

    /// Reward breakdown for the session the user just finished. Used by the
    /// end-of-session screen to show per-component earnings.
    @Published var lastSessionReward: SessionRewardBreakdown?

    /// Challenge completion + perfect bonus applied as a side effect of this
    /// session, if the session completed an active challenge. `nil` otherwise.
    @Published var lastChallengeReward: ChallengeCompletionReward?

    /// Decorations that just became available to purchase as a result of the
    /// level-up triggered by this session. Empty when nothing newly unlocked.
    @Published var newlyAvailableDecorations: [Decoration] = []

    private var timer: Timer?
    private var sessionStartDate: Date?

    var currentItem: PrayerItem? {
        guard currentItemIndex < sessionItems.count else { return nil }
        return sessionItems[currentItemIndex]
    }

    var progress: Double {
        guard !sessionItems.isEmpty else { return 0 }
        return Double(prayedItems.count) / Double(sessionItems.count)
    }

    var isLastItem: Bool { currentItemIndex >= sessionItems.count - 1 }

    // MARK: - Init
    init(
        prayerService: PrayerService = PrayerService(),
        sessionService: SessionService = SessionService(),
        gamificationService: GamificationService = GamificationService()
    ) {
        self.prayerService = prayerService
        self.sessionService = sessionService
        self.gamificationService = gamificationService
    }

    // MARK: - Session Lifecycle

    func startSession(items: [PrayerItem]) {
        guard !items.isEmpty else { return }
        sessionItems = items
        prayedItems = []
        currentItemIndex = 0
        elapsedTime = 0
        isFinished = false
        isInSession = true
        sessionStartDate = Date()
        startTimer()
    }

    func markItemPrayed(_ item: PrayerItem) {
        prayerService.incrementPrayedCount(item)
        if !prayedItems.contains(where: { $0.objectID == item.objectID }) {
            prayedItems.append(item)
        }
        advanceToNext()
    }

    func skipItem() {
        advanceToNext()
    }

    private func advanceToNext() {
        if currentItemIndex < sessionItems.count - 1 {
            currentItemIndex += 1
        }
    }

    @discardableResult
    func finishSession() -> PrayerSession? {
        stopTimer()
        isInSession = false
        isFinished = true

        let duration = Float(elapsedTime)
        let itemsToSave = prayedItems.isEmpty ? sessionItems : prayedItems
        let session = sessionService.createSession(items: itemsToSave, duration: duration)

        // 1. Footprint for streaks / challenges / tree.
        gamificationService.recordDailyActivity(session: session)

        // 2. Per-session reward. The road-map view model knows whether a
        //    challenge is currently in progress and which tier is active; we
        //    snapshot that state here so this view model stays self-contained.
        let tierState = RoadMapViewModel.currentTierState()
        let breakdown = gamificationService.applySessionReward(
            session,
            tier: tierState.tier,
            isChallengeInProgress: tierState.isInProgress
        )
        lastSessionReward = breakdown

        // 3. Evaluate challenge completion (which may also grant a perfect bonus).
        if let tier = tierState.tier {
            lastChallengeReward = RoadMapViewModel.finalizeIfCompleted(
                tier: tier,
                gamificationService: gamificationService
            )
        } else {
            lastChallengeReward = nil
        }

        // 4. Refresh "what can I buy now?" for the results screen.
        newlyAvailableDecorations = gamificationService.availableDecorationsForPurchase()

        finishedSession = session
        return session
    }

    func reset() {
        stopTimer()
        sessionItems = []
        prayedItems = []
        currentItemIndex = 0
        isInSession = false
        isFinished = false
        elapsedTime = 0
        finishedSession = nil
        lastSessionReward = nil
        lastChallengeReward = nil
        newlyAvailableDecorations = []
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit { stopTimer() }
}
