import XCTest
import CoreData
@testable import PrayerApp

final class GamificationServiceTests: XCTestCase {

    var persistence: PersistenceController!
    var defaults: UserDefaults!
    var prayerService: PrayerService!
    var sessionService: SessionService!
    var gamificationService: GamificationService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        defaults = UserDefaults(suiteName: "GamificationServiceTests-\(UUID().uuidString)")!
        prayerService = PrayerService(persistence: persistence)
        sessionService = SessionService(persistence: persistence)
        gamificationService = GamificationService(persistence: persistence, defaults: defaults)
    }

    override func tearDown() {
        persistence = nil
        defaults = nil
        prayerService = nil
        sessionService = nil
        gamificationService = nil
        super.tearDown()
    }

    // MARK: - Footprint + Streak

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

    // MARK: - Session Reward (§3.5.1)

    func testBaseSessionReward() {
        let item = prayerService.createPrayer(title: "A", category: .adoration)
        let session = sessionService.createSession(items: [item], duration: 60)

        let reward = gamificationService.applySessionReward(
            session, tier: nil, isChallengeInProgress: false
        )

        // Base 10 XP + content 3 (one item) + duration 1 (<2min) + variety 0 = 14 XP
        // Base 1 drop + content 0 + variety 0 = 1 drop
        XCTAssertEqual(reward.baseXP, 10)
        XCTAssertEqual(reward.contentXP, 3)
        XCTAssertEqual(reward.durationXP, 1)
        XCTAssertEqual(reward.totalXP, 14)
        XCTAssertEqual(reward.totalDrops, 1)
        XCTAssertEqual(session.xpEarned, 14)
        XCTAssertEqual(session.dropsEarned, 1)
    }

    func testFullActsSessionRewardWithFourItems() {
        let items = [
            prayerService.createPrayer(title: "A", category: .adoration),
            prayerService.createPrayer(title: "C", category: .confession),
            prayerService.createPrayer(title: "T", category: .thanksgiving),
            prayerService.createPrayer(title: "S", category: .supplication),
        ]
        let session = sessionService.createSession(items: items, duration: 350) // 5–10 min band ⇒ 4 XP

        let reward = gamificationService.applySessionReward(
            session, tier: nil, isChallengeInProgress: false
        )

        // Base 10 + content 12 (4×3) + variety 6 (full ACTS) + duration 4 = 32 XP
        // Base 1 + content 2 (two extra-drop thresholds) + variety 2 = 5 drops
        XCTAssertEqual(reward.totalXP, 32)
        XCTAssertEqual(reward.totalDrops, 5)
    }

    func testContentRewardIsCappedAtFourItems() {
        let items = (0..<6).map { prayerService.createPrayer(title: "P\($0)", category: .supplication) }
        let session = sessionService.createSession(items: items, duration: 30)

        let reward = gamificationService.applySessionReward(
            session, tier: nil, isChallengeInProgress: false
        )

        // Content should cap at 4 items = 12 XP, not 18. Same single category ⇒ no variety bonus.
        XCTAssertEqual(reward.contentXP, 12)
        XCTAssertEqual(reward.contentDrops, 2)
        XCTAssertEqual(reward.varietyXP, 0)
    }

    func testDailyChallengeBonusAwardedOncePerDay() {
        let item = prayerService.createPrayer(title: "Prayer", category: .supplication)

        let s1 = sessionService.createSession(items: [item], duration: 60)
        let r1 = gamificationService.applySessionReward(s1, tier: 3, isChallengeInProgress: true)
        XCTAssertEqual(r1.challengeDailyXP, 3)
        XCTAssertEqual(r1.challengeDailyDrops, 2)

        let s2 = sessionService.createSession(items: [item], duration: 60)
        let r2 = gamificationService.applySessionReward(s2, tier: 3, isChallengeInProgress: true)
        XCTAssertEqual(r2.challengeDailyXP, 0, "Daily bonus must only be granted once per day")
        XCTAssertEqual(r2.challengeDailyDrops, 0)
    }

    // MARK: - Level Progression (§3.5.4)

    func testLevelFormulaMatchesDesignDocument() {
        // Design spec: L1→L2 = 75, L2→L3 = 100, L3→L4 = 125, L4→L5 = 150, L5→L6 = 175
        XCTAssertEqual(RewardCalculator.xpToNextLevel(currentLevel: 1), 75)
        XCTAssertEqual(RewardCalculator.xpToNextLevel(currentLevel: 2), 100)
        XCTAssertEqual(RewardCalculator.xpToNextLevel(currentLevel: 3), 125)
        XCTAssertEqual(RewardCalculator.xpToNextLevel(currentLevel: 4), 150)
        XCTAssertEqual(RewardCalculator.xpToNextLevel(currentLevel: 5), 175)
    }

    func testLevelProgressRollsOverCorrectly() {
        // 74 XP → still Level 1 with 74 into level, needing 75 to advance
        let p1 = RewardCalculator.levelProgress(forTotalXP: 74)
        XCTAssertEqual(p1.level, 1)
        XCTAssertEqual(p1.xpIntoLevel, 74)
        XCTAssertEqual(p1.xpForNextLevel, 75)

        // 75 XP → Level 2 with 0 into level, needing 100
        let p2 = RewardCalculator.levelProgress(forTotalXP: 75)
        XCTAssertEqual(p2.level, 2)
        XCTAssertEqual(p2.xpIntoLevel, 0)
        XCTAssertEqual(p2.xpForNextLevel, 100)

        // 175 XP → Level 3 (75 + 100), with 0 into level, needing 125
        let p3 = RewardCalculator.levelProgress(forTotalXP: 175)
        XCTAssertEqual(p3.level, 3)
        XCTAssertEqual(p3.xpIntoLevel, 0)
        XCTAssertEqual(p3.xpForNextLevel, 125)
    }

    // MARK: - Challenge Completion (§3.5.2)

    func testChallengeCompletionRewardScalesWithTier() {
        let r3  = RewardCalculator.challengeCompletionReward(totalDays: 3,  isPerfect: false)
        let r21 = RewardCalculator.challengeCompletionReward(totalDays: 21, isPerfect: false)

        XCTAssertEqual(r3.totalXP, 20)
        XCTAssertEqual(r3.totalDrops, 5)
        XCTAssertEqual(r21.totalXP, 150)
        XCTAssertEqual(r21.totalDrops, 30)
    }

    func testPerfectBonusOnlyAppliesWhenPerfect() {
        let withBonus = RewardCalculator.challengeCompletionReward(totalDays: 7, isPerfect: true)
        let without   = RewardCalculator.challengeCompletionReward(totalDays: 7, isPerfect: false)

        XCTAssertEqual(withBonus.totalXP, 45 + 10)
        XCTAssertEqual(withBonus.totalDrops, 10 + 7)
        XCTAssertEqual(without.totalXP, 45)
        XCTAssertEqual(without.totalDrops, 10)
    }

    func testChallengeCompletionIsIdempotent() {
        let first  = gamificationService.awardChallengeCompletionIfNeeded(tier: 3, isPerfect: true)
        let second = gamificationService.awardChallengeCompletionIfNeeded(tier: 3, isPerfect: true)

        XCTAssertEqual(first.completionXP, 20)
        XCTAssertEqual(first.perfectXP, 5)
        XCTAssertEqual(second.totalXP, 0, "Completion bonus must only be granted once per tier run")
        XCTAssertEqual(second.totalDrops, 0)
    }

    // MARK: - Break Handling (§3.5.3)

    func testContinuityRecoveryCostsMatchSpec() {
        XCTAssertEqual(RewardCalculator.continuityRecoveryCost(totalDays: 3),  2)
        XCTAssertEqual(RewardCalculator.continuityRecoveryCost(totalDays: 7),  5)
        XCTAssertEqual(RewardCalculator.continuityRecoveryCost(totalDays: 14), 10)
        XCTAssertEqual(RewardCalculator.continuityRecoveryCost(totalDays: 21), 12)
    }

    func testSpendDropsFailsWhenInsufficient() {
        // No drops earned yet, so any spend should fail.
        XCTAssertEqual(gamificationService.getTotalDrops(), 0)
        XCTAssertFalse(gamificationService.spendDropsToPreserveContinuity(tier: 3))
    }

    func testActsRecoveryBonusAddsToBalance() {
        let before = gamificationService.getTotalDrops()
        let reward = gamificationService.awardActsRecoveryBonus()
        XCTAssertEqual(reward.xp, 8)
        XCTAssertEqual(reward.drops, 2)
        XCTAssertEqual(gamificationService.getTotalDrops(), before + 2)
        XCTAssertEqual(gamificationService.getTotalXP(), 8)
    }

    // MARK: - Drop Spending

    func testResetChallengeStateAllowsBonusToBeEarnedAgain() {
        _ = gamificationService.awardChallengeCompletionIfNeeded(tier: 3, isPerfect: false)
        gamificationService.resetChallengeState(tier: 3)
        let second = gamificationService.awardChallengeCompletionIfNeeded(tier: 3, isPerfect: false)
        XCTAssertEqual(second.completionXP, 20)
    }
}
