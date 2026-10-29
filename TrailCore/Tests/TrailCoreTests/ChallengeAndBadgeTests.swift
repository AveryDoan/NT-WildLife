import XCTest
@testable import TrailCore

final class ChallengeTests: XCTestCase {
    private let zone = TimeZone(identifier: "Australia/Darwin")!
    private var calendar: Calendar {
        var c = Calendar(identifier: .iso8601)
        c.timeZone = zone
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func testSameWeekAlwaysGivesTheSameThreeDistinctChallenges() {
        let a = ChallengeEngine.challenges(year: 2026, week: 44)
        let b = ChallengeEngine.challenges(year: 2026, week: 44)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, ChallengeEngine.perWeek)
        XCTAssertEqual(Set(a.map(\.id)).count, ChallengeEngine.perWeek)
    }

    func testDifferentWeeksVary() {
        let sets = (1...20).map { Set(ChallengeEngine.challenges(year: 2026, week: $0).map(\.id)) }
        XCTAssertGreaterThan(Set(sets).count, 1)
    }

    func testIsoWeekOfKnownDates() {
        // Thu 29 Oct 2026 is ISO week 44; 1 Jan 2027 (Friday) still belongs to week 53 of 2026.
        let w = ChallengeEngine.isoWeek(of: date(2026, 10, 29), timeZone: zone)
        XCTAssertEqual(w.year, 2026)
        XCTAssertEqual(w.week, 44)
        let ny = ChallengeEngine.isoWeek(of: date(2027, 1, 1), timeZone: zone)
        XCTAssertEqual(ny.year, 2026)
        XCTAssertEqual(ny.week, 53)
    }

    func testProgressCountsOnlyScoringSightingsInThatWeek() {
        let challenge = Challenge(kind: .distinctSpecies, target: 2, title: "t", detail: "d")
        let sightings = [
            ChallengeSighting(loggedAt: date(2026, 10, 27), speciesID: "a", groupKey: "ants", scored: true),
            ChallengeSighting(loggedAt: date(2026, 10, 28), speciesID: "a", groupKey: "ants", scored: true),   // same species
            ChallengeSighting(loggedAt: date(2026, 10, 28), speciesID: "b", groupKey: "bugs", scored: false),  // guide-only
            ChallengeSighting(loggedAt: date(2026, 10, 20), speciesID: "c", groupKey: "bugs", scored: true),   // last week
        ]
        let p = ChallengeEngine.progress(for: challenge, sightings: sightings, year: 2026, week: 44, timeZone: zone)
        XCTAssertEqual(p.current, 1)
        XCTAssertFalse(p.isComplete)
    }

    func testEachKindOfProgress() {
        let s = [
            ChallengeSighting(loggedAt: date(2026, 10, 26), speciesID: "a", groupKey: "ants", scored: true, isFirstFind: true),
            ChallengeSighting(loggedAt: date(2026, 10, 27), speciesID: nil, groupKey: "beetles", scored: true),
            ChallengeSighting(loggedAt: date(2026, 10, 27), speciesID: "b", groupKey: "ants", scored: true),
        ]
        func current(_ kind: ChallengeKind) -> Int {
            ChallengeEngine.progress(
                for: Challenge(kind: kind, target: 9, title: "", detail: ""),
                sightings: s, year: 2026, week: 44, timeZone: zone
            ).current
        }
        XCTAssertEqual(current(.distinctSpecies), 2)
        XCTAssertEqual(current(.distinctGroups), 2)
        XCTAssertEqual(current(.scoringDays), 2)
        XCTAssertEqual(current(.speciesLevelFinds), 2)
        XCTAssertEqual(current(.newSpecies), 1)
    }

    func testNoChallengeMentionsUnsafeActivities() {
        let banned = ["water", "night", "collect", "catch", "swim", "dark"]
        for challenge in ChallengeEngine.pool {
            let text = (challenge.title + " " + challenge.detail).lowercased()
            for word in banned { XCTAssertFalse(text.contains(word), "\(challenge.id) mentions \(word)") }
        }
    }
}

final class BadgeTests: XCTestCase {
    func testNothingEarnedAtStart() {
        XCTAssertTrue(BadgeEngine.earned(BadgeStats()).isEmpty)
    }

    func testEarnedThresholds() {
        let stats = BadgeStats(scoredSightings: 1, longestStreak: 3, groupsWithASpecies: 3,
                               foundHardSpecies: true, speciesLevelSightings: 5, notSureSightings: 1)
        XCTAssertEqual(BadgeEngine.earned(stats), Set(BadgeEngine.all.map(\.id)))
        XCTAssertEqual(BadgeEngine.earned(BadgeStats(scoredSightings: 1)), ["first-find"])
        XCTAssertEqual(BadgeEngine.earned(BadgeStats(longestStreak: 2)), [])
    }

    func testLongestStreak() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Australia/Darwin")!
        func d(_ day: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 9))! }
        XCTAssertEqual(StreakCalculator.longestStreak(scoringDays: [], calendar: cal), 0)
        XCTAssertEqual(StreakCalculator.longestStreak(scoringDays: [d(1), d(2), d(3), d(5), d(6)], calendar: cal), 3)
        XCTAssertEqual(StreakCalculator.longestStreak(scoringDays: [d(1), d(3), d(5)], calendar: cal), 1)
    }
}
