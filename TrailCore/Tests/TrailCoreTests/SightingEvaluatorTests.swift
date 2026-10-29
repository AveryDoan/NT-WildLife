import XCTest
@testable import TrailCore

final class SightingEvaluatorTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Australia/Darwin")!
        return c
    }()

    private func date(_ day: Int, hour: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    private func candidate(
        _ taxon: Taxon = .species(id: "magnetic-termite"),
        captured: Date? = nil,
        logged: Date? = nil,
        hash: UInt64? = nil,
        difficulty: FindDifficulty = .easy,
        face: Bool = false
    ) -> SightingCandidate {
        let loggedAt = logged ?? date(29)
        return SightingCandidate(
            taxon: taxon, difficulty: difficulty,
            capturedAt: captured ?? loggedAt.addingTimeInterval(-600),
            loggedAt: loggedAt, photoHash: hash, hadFace: face
        )
    }

    func testFirstEverSpeciesSightingGetsBaseFirstFindAndStreakOfOneDay() {
        let result = SightingEvaluator.evaluate(candidate(), history: [], calendar: calendar)
        XCTAssertEqual(result.outcome, .scored)
        XCTAssertEqual(result.base, 20)
        XCTAssertEqual(result.firstFindBonus, 10)
        XCTAssertEqual(result.streakBonus, 2)
        XCTAssertEqual(result.total, 32)
    }

    func testSecondSightingOfSameSpeciesIsNotAFirstFind() {
        let history = [SightingRecord(taxon: .species(id: "magnetic-termite"), loggedAt: date(27), scored: true)]
        let result = SightingEvaluator.evaluate(candidate(), history: history, calendar: calendar)
        XCTAssertEqual(result.firstFindBonus, 0)
    }

    func testGuideOnlySightingStillMeansSpeciesIsInTheGuide() {
        let history = [SightingRecord(taxon: .species(id: "magnetic-termite"), loggedAt: date(20), scored: false)]
        let result = SightingEvaluator.evaluate(candidate(), history: history, calendar: calendar)
        XCTAssertEqual(result.firstFindBonus, 0)
    }

    func testSameTaxonTwiceInADayScoresOnce() {
        let history = [SightingRecord(taxon: .species(id: "magnetic-termite"), loggedAt: date(29, hour: 8), scored: true)]
        let result = SightingEvaluator.evaluate(candidate(logged: date(29, hour: 15)), history: history, calendar: calendar)
        XCTAssertEqual(result.outcome, .guideOnly(.alreadyScoredToday))
        XCTAssertEqual(result.total, 0)
    }

    func testSameTaxonOnANewDayScoresAgain() {
        let history = [SightingRecord(taxon: .species(id: "magnetic-termite"), loggedAt: date(28), scored: true)]
        let result = SightingEvaluator.evaluate(candidate(), history: history, calendar: calendar)
        XCTAssertEqual(result.outcome, .scored)
    }

    func testDifferentTaxonSameDayStillScores() {
        let history = [SightingRecord(taxon: .species(id: "green-tree-ant"), loggedAt: date(29, hour: 8), scored: true)]
        let result = SightingEvaluator.evaluate(candidate(), history: history, calendar: calendar)
        XCTAssertEqual(result.outcome, .scored)
    }

    func testDuplicatePhotoIsDetectedWithinHammingSix() {
        let known: UInt64 = 0b1010_1010
        let near: UInt64 = known ^ 0b0011_1111 // 6 bits differ
        let far: UInt64 = known ^ 0b0111_1111  // 7 bits differ
        let history = [SightingRecord(taxon: .species(id: "green-tree-ant"), loggedAt: date(28), photoHash: known, scored: true)]
        XCTAssertEqual(
            SightingEvaluator.evaluate(candidate(hash: near), history: history, calendar: calendar).outcome,
            .guideOnly(.duplicatePhoto)
        )
        XCTAssertEqual(
            SightingEvaluator.evaluate(candidate(hash: far), history: history, calendar: calendar).outcome,
            .scored
        )
    }

    func testStaleAndUndatedPhotosAreGuideOnly() {
        let stale = candidate(captured: date(29).addingTimeInterval(-73 * 3600))
        XCTAssertEqual(SightingEvaluator.evaluate(stale, history: [], calendar: calendar).outcome, .guideOnly(.photoTooOld))
        let undated = SightingCandidate(taxon: .species(id: "a"), capturedAt: nil, loggedAt: date(29))
        XCTAssertEqual(SightingEvaluator.evaluate(undated, history: [], calendar: calendar).outcome, .guideOnly(.photoDateUnknown))
    }

    func testFaceIsRejected() {
        let result = SightingEvaluator.evaluate(candidate(face: true), history: [], calendar: calendar)
        XCTAssertEqual(result.outcome, .rejected(.containsPerson))
        XCTAssertFalse(result.savesToGuide)
    }

    func testStreakCountsConsecutiveScoringDaysOnly() {
        let history = [
            SightingRecord(taxon: .order("Coleoptera"), loggedAt: date(28), scored: true),
            SightingRecord(taxon: .order("Coleoptera"), loggedAt: date(27), scored: true),
            SightingRecord(taxon: .order("Coleoptera"), loggedAt: date(25), scored: true), // gap on 26
            SightingRecord(taxon: .notSure, loggedAt: date(26), scored: false),            // guide-only does not count
        ]
        let result = SightingEvaluator.evaluate(candidate(), history: history, calendar: calendar)
        XCTAssertEqual(result.streakBonus, 6) // 29, 28, 27 = 3 days
    }
}

final class StreakCalculatorTests: XCTestCase {
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Australia/Darwin")!
        return c
    }()

    private func day(_ d: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d, hour: 12))!
    }

    func testDisplayedStreakKeepsYesterdaysRunAlive() {
        let days: Set<Date> = [day(27), day(28)]
        XCTAssertEqual(StreakCalculator.displayedStreak(scoringDays: days, now: day(29), calendar: calendar), 2)
    }

    func testDisplayedStreakIsZeroAfterAMissedDay() {
        let days: Set<Date> = [day(26), day(27)]
        XCTAssertEqual(StreakCalculator.displayedStreak(scoringDays: days, now: day(29), calendar: calendar), 0)
    }

    func testDisplayedStreakIncludesToday() {
        let days: Set<Date> = [day(28), day(29)]
        XCTAssertEqual(StreakCalculator.displayedStreak(scoringDays: days, now: day(29), calendar: calendar), 2)
    }

    func testDarwinMidnightBoundary() {
        // 23:30 and 00:30 Darwin time are different days even though they are an hour apart.
        let late = calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 23, minute: 30))!
        let early = calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 0, minute: 30))!
        XCTAssertEqual(StreakCalculator.currentStreak(scoringDays: [late], today: early, calendar: calendar), 2)
    }
}

final class LocationPrivacyTests: XCTestCase {
    func testNormalRoundingIsTwoDecimals() throws {
        let r = try XCTUnwrap(LocationPrivacy.round(latitude: -12.463712, longitude: 130.841577, sensitive: false))
        XCTAssertEqual(r.latitude, -12.46, accuracy: 1e-9)
        XCTAssertEqual(r.longitude, 130.84, accuracy: 1e-9)
    }

    func testSensitiveSpeciesAreRoundedMoreCoarsely() throws {
        let r = try XCTUnwrap(LocationPrivacy.round(latitude: -12.463712, longitude: 130.841577, sensitive: true))
        XCTAssertEqual(r.latitude, -12.5, accuracy: 1e-9)
        XCTAssertEqual(r.longitude, 130.8, accuracy: 1e-9)
    }

    func testInvalidCoordinatesAreRejected() {
        XCTAssertNil(LocationPrivacy.round(latitude: 91, longitude: 0, sensitive: false))
        XCTAssertNil(LocationPrivacy.round(latitude: .nan, longitude: 0, sensitive: false))
    }
}

final class InsectOrderAndTaxonStorageTests: XCTestCase {
    func testEveryOrderHasANameAndRoundTripsByScientificName() {
        for order in InsectOrder.allCases {
            XCTAssertFalse(order.displayName.isEmpty)
            XCTAssertEqual(InsectOrder(scientificName: order.scientificName), order)
        }
    }

    func testSeededOrdersAreAllOfferedForOrderLevelAnswers() throws {
        for species in try SpeciesCatalogue.bundled() {
            if let order = species.order {
                XCTAssertNotNil(InsectOrder(scientificName: order), "\(species.id) has an order the app does not offer")
            }
        }
    }

    func testTaxonStorageRoundTrips() {
        let all: [Taxon] = [.species(id: "x"), .genus("Oecophylla"), .family("Formicidae"), .order("Hymenoptera"), .notSure]
        for taxon in all {
            let stored = taxon.storage
            XCTAssertEqual(Taxon(kind: stored.kind, value: stored.value), taxon)
        }
        XCTAssertNil(Taxon(kind: "nonsense", value: ""))
    }
}
