import Foundation
import Combine

final class DecorationViewModel: ObservableObject {

    // MARK: - Dependencies
    private let decorationService: DecorationService

    // MARK: - Published State
    @Published var unlockedDecorations: [Decoration] = []
    @Published var lockedDecorations: [Decoration] = []

    // MARK: - Init
    init(decorationService: DecorationService = DecorationService()) {
        self.decorationService = decorationService
    }

    // MARK: - Fetch

    func fetchDecorations() {
        unlockedDecorations = decorationService.fetchUnlockedDecorations()
        lockedDecorations   = decorationService.fetchLockedDecorations()
    }

    // MARK: - Actions

    func applyDecoration(_ decoration: Decoration) {
        decorationService.applyDecoration(decoration)
        fetchDecorations()
    }

    func removeDecoration(_ decoration: Decoration) {
        // Removing a decoration from the applied state
        // In a full implementation, a separate "applied" flag would be cleared here.
        fetchDecorations()
    }
}
