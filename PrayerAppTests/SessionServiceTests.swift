import XCTest
import CoreData
@testable import PrayerApp

final class SessionServiceTests: XCTestCase {

    var persistence: PersistenceController!
    var prayerService: PrayerService!
    var sessionService: SessionService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        prayerService = PrayerService(persistence: persistence)
        sessionService = SessionService(persistence: persistence)
    }

    override func tearDown() {
        persistence = nil
        prayerService = nil
        sessionService = nil
        super.tearDown()
    }

    func testCreateSession() {
        let item1 = prayerService.createPrayer(title: "Prayer A", category: .adoration)
        let item2 = prayerService.createPrayer(title: "Prayer B", category: .supplication)

        let session = sessionService.createSession(items: [item1, item2], duration: 300)

        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.duration, 300)
        XCTAssertEqual(session.itemList.count, 2)
    }

    func testFetchSessionsForDate() {
        let item = prayerService.createPrayer(title: "Prayer")
        _ = sessionService.createSession(items: [item])

        let sessions = sessionService.fetchSessions(for: Date())
        XCTAssertGreaterThanOrEqual(sessions.count, 1)
    }

    func testAddItemToSession() {
        let item1 = prayerService.createPrayer(title: "Prayer A")
        let item2 = prayerService.createPrayer(title: "Prayer B")
        let session = sessionService.createSession(items: [item1])

        sessionService.addItemToSession(item: item2, session: session)
        XCTAssertEqual(session.itemList.count, 2)
    }
}
