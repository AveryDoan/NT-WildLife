import XCTest
@testable import TrailCore

final class ScoreCalculatorTests: XCTestCase {
    private func input(
        _ taxon: Taxon,
        difficulty: FindDifficulty? = nil,
        freshness: PhotoFreshness = .recent,
        duplicate: Bool = false,
        face: Bool = false,
        first: Bool = false,
        streak: Int = 0,
        scoredToday: Bool = false
    ) -> SightingInput {
        SightingInput(
            taxon: taxon, difficulty: difficulty, freshness: freshness,
            isDuplicatePhoto: duplicate, hadFace: face, isFirstFindOfSpecies: first,
            streakDays: streak, alreadyScoredTodayForTaxon: scoredToday
        )
    }

    func testBasePointsByPrecision() {
        XCTAssertEqual(ScoreCalculator.score(input(.order("Coleoptera"))).total, 5)
        XCTAssertEqual(ScoreCalculator.score(input(.family("Formicidae"))).total, 10)
        XCTAssertEqual(ScoreCalculator.score(input(.genus("Iridomyrmex"))).total, 15)
        XCTAssertEqual(ScoreCalculator.score(input(.species(id: "meat-ant"), difficulty: .easy)).total, 20)
    }

    func testDifficultyBonus() {
        XCTAssertEqual(ScoreCalculator.score(input(.species(id: "a"), difficulty: .easy)).difficultyBonus, 0)
        XCTAssertEqual(ScoreCalculator.score(input(.species(id: "a"), difficulty: .medium)).difficultyBonus, 5)
        XCTAssertEqual(ScoreCalculator.score(input(.species(id: "a"), difficulty: .hard)).difficultyBonus, 15)
    }

    func testRankLevelAnswersGetNoSpeciesBonuses() {
        let result = ScoreCalculator.score(input(.family("Formicidae"), difficulty: .hard, first: true))
        XCTAssertEqual(result.difficultyBonus, 0)
        XCTAssertEqual(result.firstFindBonus, 0)
        XCTAssertEqual(result.total, 10)
    }

    func testFirstFindBonus() {
        let result = ScoreCalculator.score(input(.species(id: "a"), difficulty: .easy, first: true))
        XCTAssertEqual(result.firstFindBonus, 10)
        XCTAssertEqual(result.total, 30)
    }

    func testStreakBonusIsTwoPerDayCappedAtTen() {
        XCTAssertEqual(ScoreCalculator.streakBonus(days: 0), 0)
        XCTAssertEqual(ScoreCalculator.streakBonus(days: 1), 2)
        XCTAssertEqual(ScoreCalculator.streakBonus(days: 4), 8)
        XCTAssertEqual(ScoreCalculator.streakBonus(days: 5), 10)
        XCTAssertEqual(ScoreCalculator.streakBonus(days: 30), 10)
        XCTAssertEqual(ScoreCalculator.streakBonus(days: -3), 0)
    }

    func testFullStack() {
        // species 20 + hard 15 + first 10 + streak capped 10
        let result = ScoreCalculator.score(input(.species(id: "a"), difficulty: .hard, first: true, streak: 9))
        XCTAssertEqual(result.total, 55)
        XCTAssertEqual(result.outcome, .scored)
        XCTAssertTrue(result.countsForChallenges)
    }

    func testNotSureScoresNothingButSaves() {
        let result = ScoreCalculator.score(input(.notSure))
        XCTAssertEqual(result.outcome, .guideOnly(.notSure))
        XCTAssertEqual(result.total, 0)
        XCTAssertTrue(result.savesToGuide)
        XCTAssertFalse(result.countsForChallenges)
    }

    func testDuplicatePhotoIsGuideOnly() {
        let result = ScoreCalculator.score(input(.species(id: "a"), difficulty: .hard, duplicate: true))
        XCTAssertEqual(result.outcome, .guideOnly(.duplicatePhoto))
        XCTAssertEqual(result.total, 0)
    }

    func testOldAndUndatedPhotosAreGuideOnly() {
        XCTAssertEqual(ScoreCalculator.score(input(.order("x"), freshness: .stale)).outcome, .guideOnly(.photoTooOld))
        XCTAssertEqual(ScoreCalculator.score(input(.order("x"), freshness: .unknown)).outcome, .guideOnly(.photoDateUnknown))
        XCTAssertFalse(ScoreCalculator.score(input(.order("x"), freshness: .stale)).countsForChallenges)
    }

    func testSecondSightingOfSameTaxonTodayIsGuideOnly() {
        let result = ScoreCalculator.score(input(.species(id: "a"), difficulty: .easy, scoredToday: true))
        XCTAssertEqual(result.outcome, .guideOnly(.alreadyScoredToday))
        XCTAssertEqual(result.total, 0)
    }

    func testFaceIsRejectedAndNotSaved() {
        let result = ScoreCalculator.score(input(.species(id: "a"), difficulty: .easy, face: true))
        XCTAssertEqual(result.outcome, .rejected(.containsPerson))
        XCTAssertFalse(result.savesToGuide)
        XCTAssertEqual(result.total, 0)
    }

    func testDailyKeys() {
        XCTAssertEqual(Taxon.species(id: "meat-ant").dailyKey, "species:meat-ant")
        XCTAssertEqual(Taxon.order("Coleoptera").dailyKey, Taxon.order("coleoptera").dailyKey)
        XCTAssertNil(Taxon.notSure.dailyKey)
    }
}
