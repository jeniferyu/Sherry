import XCTest
import CoreData
@testable import PrayerApp

final class PrayerServiceTests: XCTestCase {

    var persistence: PersistenceController!
    var prayerService: PrayerService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        prayerService = PrayerService(persistence: persistence)
    }

    override func tearDown() {
        persistence = nil
        prayerService = nil
        super.tearDown()
    }

    func testCreatePrayer() {
        let prayer = prayerService.createPrayer(title: "Test Prayer", category: .adoration)
        XCTAssertEqual(prayer.title, "Test Prayer")
        XCTAssertEqual(prayer.categoryEnum, .adoration)
        XCTAssertEqual(prayer.statusEnum, .ongoing)
        XCTAssertFalse(prayer.isIntercessory)
    }

    func testFetchTodayPrayers() {
        prayerService.createPrayer(title: "Prayer 1", category: .thanksgiving)
        prayerService.createPrayer(title: "Prayer 2", category: .supplication)

        let today = prayerService.fetchTodayPrayers()
        XCTAssertGreaterThanOrEqual(today.count, 2)
    }

    func testUpdatePrayerStatus() {
        let prayer = prayerService.createPrayer(title: "Test")
        XCTAssertEqual(prayer.statusEnum, .ongoing)

        prayerService.updatePrayerStatus(prayer, status: .answered)
        XCTAssertEqual(prayer.statusEnum, .answered)
        XCTAssertNotNil(prayer.lastPrayedDate)
    }

    func testIncrementPrayedCount() {
        let prayer = prayerService.createPrayer(title: "Test")
        XCTAssertEqual(prayer.prayedCount, 0)

        prayerService.incrementPrayedCount(prayer)
        XCTAssertEqual(prayer.prayedCount, 1)
        XCTAssertEqual(prayer.statusEnum, .prayed)
    }

    func testSearchPrayers() {
        prayerService.createPrayer(title: "Healing prayer", content: "Please heal my friend")
        prayerService.createPrayer(title: "Guidance prayer", content: "Lead my steps")

        let results = prayerService.searchPrayers(query: "heal")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Healing prayer")
    }

    func testDeletePrayer() {
        let prayer = prayerService.createPrayer(title: "To Delete")
        let countBefore = prayerService.fetchTodayPrayers().count

        prayerService.deletePrayer(prayer)
        let countAfter = prayerService.fetchTodayPrayers().count

        XCTAssertEqual(countAfter, countBefore - 1)
    }
}
