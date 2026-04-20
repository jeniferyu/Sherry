import Foundation

// MARK: - Reward Breakdown

/// A structured breakdown of the XP and drops awarded for a single prayer session.
///
/// The breakdown mirrors §3.5.1 of the system design:
/// base + content + variety + duration + optional challenge-daily bonus.
/// Totals are derived so callers never have to sum the components by hand.
struct SessionRewardBreakdown: Equatable {
    var baseXP: Int = 0
    var baseDrops: Int = 0

    var contentXP: Int = 0
    var contentDrops: Int = 0

    var varietyXP: Int = 0
    var varietyDrops: Int = 0

    var durationXP: Int = 0

    var challengeDailyXP: Int = 0
    var challengeDailyDrops: Int = 0

    var totalXP: Int {
        baseXP + contentXP + varietyXP + durationXP + challengeDailyXP
    }

    var totalDrops: Int {
        baseDrops + contentDrops + varietyDrops + challengeDailyDrops
    }
}

/// A structured breakdown of the rewards granted when a challenge finishes.
struct ChallengeCompletionReward: Equatable {
    var completionXP: Int = 0
    var completionDrops: Int = 0
    var perfectXP: Int = 0
    var perfectDrops: Int = 0

    var totalXP: Int { completionXP + perfectXP }
    var totalDrops: Int { completionDrops + perfectDrops }
}

/// A progress snapshot for the current level, used to drive the stats banner.
struct LevelProgress: Equatable {
    let level: Int
    let xpIntoLevel: Int
    let xpForNextLevel: Int

    var fraction: Double {
        guard xpForNextLevel > 0 else { return 0 }
        return min(1.0, Double(xpIntoLevel) / Double(xpForNextLevel))
    }
}

// MARK: - Calculator

/// Pure, stateless calculator for all XP/drop rules in the design document.
///
/// Implements §3.5.1 (session rewards), §3.5.2 (challenge rewards),
/// §3.5.3 (break-handling costs and recovery rewards), and §3.5.4
/// (level progression and drop usage helpers). Having this in one place
/// keeps the reward policy easy to audit and adjust without touching
/// persistence or view logic.
enum RewardCalculator {

    // MARK: Session Reward (§3.5.1)

    /// Computes the reward breakdown for one completed prayer session.
    ///
    /// - Parameters:
    ///   - itemCount: Number of prayer items written or completed in the session.
    ///                Counted contribution is capped at 4.
    ///   - categories: Distinct `PrayerCategory` values covered by the session.
    ///                 Drives the variety reward.
    ///   - durationSeconds: Session duration, in seconds.
    ///   - isChallengeDailyBonusEligible: Whether this session qualifies for the
    ///                                    daily challenge bonus (+3 XP, +2 drops).
    ///                                    The caller is responsible for ensuring
    ///                                    the bonus is only granted once per day.
    /// - Returns: The component-wise reward breakdown for the session.
    static func sessionReward(
        itemCount: Int,
        categories: Set<PrayerCategory>,
        durationSeconds: Double,
        isChallengeDailyBonusEligible: Bool
    ) -> SessionRewardBreakdown {
        var reward = SessionRewardBreakdown()

        // Base reward: 10 XP + 1 drop for any valid session.
        reward.baseXP = 10
        reward.baseDrops = 1

        // Content reward: 3 XP per item (cap 4), +1 drop at 2 items, +1 more at 4.
        let countedItems = max(0, min(itemCount, 4))
        reward.contentXP = countedItems * 3
        var extraDrops = 0
        if countedItems >= 2 { extraDrops += 1 }
        if countedItems >= 4 { extraDrops += 1 }
        reward.contentDrops = extraDrops

        // Variety reward: XP scales with ACTS coverage, full coverage adds drops.
        switch categories.count {
        case 0, 1:
            reward.varietyXP = 0
            reward.varietyDrops = 0
        case 2:
            reward.varietyXP = 2
        case 3:
            reward.varietyXP = 4
        default:
            reward.varietyXP = 6
            reward.varietyDrops = 2
        }

        // Duration reward: XP only, modest weighting so it can't dominate.
        reward.durationXP = durationXP(forSeconds: durationSeconds)

        // Daily challenge bonus layered on top when eligible.
        if isChallengeDailyBonusEligible {
            reward.challengeDailyXP = 3
            reward.challengeDailyDrops = 2
        }

        return reward
    }

    /// Maps a session's duration in seconds to its duration-reward XP.
    static func durationXP(forSeconds seconds: Double) -> Int {
        if seconds < 120 { return 1 }
        if seconds < 300 { return 2 }
        if seconds < 600 { return 4 }
        return 5
    }

    // MARK: Challenge Rewards (§3.5.2)

    /// Completion XP for finishing a challenge of the given length.
    static func challengeCompletionXP(totalDays: Int) -> Int {
        switch totalDays {
        case 3:  return 20
        case 7:  return 45
        case 14: return 90
        case 21: return 150
        default: return 0
        }
    }

    /// Completion drops for finishing a challenge of the given length.
    static func challengeCompletionDrops(totalDays: Int) -> Int {
        switch totalDays {
        case 3:  return 5
        case 7:  return 10
        case 14: return 18
        case 21: return 30
        default: return 0
        }
    }

    /// Perfect-completion XP (uninterrupted challenge run).
    static func perfectBonusXP(totalDays: Int) -> Int {
        switch totalDays {
        case 3:  return 5
        case 7:  return 10
        case 14: return 20
        case 21: return 30
        default: return 0
        }
    }

    /// Perfect-completion drops (uninterrupted challenge run).
    static func perfectBonusDrops(totalDays: Int) -> Int {
        switch totalDays {
        case 3:  return 3
        case 7:  return 7
        case 14: return 14
        case 21: return 21
        default: return 0
        }
    }

    /// Combined challenge-end reward, with the perfect bonus conditionally applied.
    static func challengeCompletionReward(
        totalDays: Int,
        isPerfect: Bool
    ) -> ChallengeCompletionReward {
        var reward = ChallengeCompletionReward()
        reward.completionXP    = challengeCompletionXP(totalDays: totalDays)
        reward.completionDrops = challengeCompletionDrops(totalDays: totalDays)
        if isPerfect {
            reward.perfectXP    = perfectBonusXP(totalDays: totalDays)
            reward.perfectDrops = perfectBonusDrops(totalDays: totalDays)
        }
        return reward
    }

    // MARK: Break Handling (§3.5.3)

    /// Drop cost to preserve continuity after a missed day for a given challenge length.
    static func continuityRecoveryCost(totalDays: Int) -> Int {
        switch totalDays {
        case 3:  return 2
        case 7:  return 5
        case 14: return 10
        case 21: return 12
        default: return 0
        }
    }

    /// Fixed reward granted when the user completes a full-ACTS recovery prayer.
    /// Intentionally more favourable than paying drops, so effortful recovery is
    /// rewarded more than pure resource expenditure.
    static let actsRecoveryReward: (xp: Int, drops: Int) = (xp: 8, drops: 2)

    // MARK: Level Progression (§3.5.4)

    /// XP required to advance from `currentLevel` to `currentLevel + 1`.
    /// Formula from the design document: `50 + 25 × current_level`.
    static func xpToNextLevel(currentLevel: Int) -> Int {
        50 + 25 * max(currentLevel, 1)
    }

    /// Cumulative XP required to have *reached* a given level (1-indexed).
    /// Level 1 requires 0 XP; Level 2 requires `xpToNextLevel(1)`; and so on.
    static func cumulativeXPForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for l in 1..<level { total += xpToNextLevel(currentLevel: l) }
        return total
    }

    /// Derives the current level and progress into it from a total XP value.
    static func levelProgress(forTotalXP totalXP: Int) -> LevelProgress {
        let xp = max(0, totalXP)
        var level = 1
        var needed = xpToNextLevel(currentLevel: level)
        var intoLevel = xp
        while intoLevel >= needed {
            intoLevel -= needed
            level += 1
            needed = xpToNextLevel(currentLevel: level)
        }
        return LevelProgress(level: level, xpIntoLevel: intoLevel, xpForNextLevel: needed)
    }
}
