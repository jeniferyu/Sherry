import XCTest
import CoreData
@testable import PrayerApp

final class GamificationServiceTests: XCTestCase {

    var persistence: PersistenceController!
    var prayerService: PrayerService!
    var sessionService: SessionService!
    var gamificationService: GamificationService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        prayerService = PrayerService(persistence: persistence)
        sessionService = SessionService(persistence: persistence)
        gamificationService = GamificationService(persistence: persistence)
    }

    override func tearDown() {
        persistence = nil
        prayerService = nil
        sessionService = nil
        gamificationService = nil
        super.tearDown()
    }

    func testRecordDailyActivity() {
        let item = prayerService.createPrayer(title: "Prayer")
        let session = sessionService.createSession(items: [item])

        let record = gamificationService.recordDailyActivity(session: session)

        XCTAssertTrue(record.hasFootprint)
        XCTAssertEqual(record.personalSessionCount, 1)
    }

    func testStreakCountSingleDay() {
        let item = prayerService.createPrayer(title: "Prayer")
        let session = sessionService.createSession(items: [item])
        gamificationService.recordDailyActivity(session: session)

        XCTAssertEqual(gamificationService.getStreakCount(), 1)
    }

    func testTotalSessionCount() {
        let item = prayerService.createPrayer(title: "Prayer")
        _ = sessionService.createSession(items: [item])
        _ = sessionService.createSession(items: [item])

        XCTAssertEqual(gamificationService.getTotalSessionCount(), 2)
    }
}
