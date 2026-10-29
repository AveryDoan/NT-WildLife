import Foundation

public struct SightingInput: Sendable {
    public var taxon: Taxon
    /// Only set for species-level answers.
    public var difficulty: FindDifficulty?
    public var freshness: PhotoFreshness
    public var isDuplicatePhoto: Bool
    public var hadFace: Bool
    /// True if this species is not yet in the player's field guide.
    public var isFirstFindOfSpecies: Bool
    /// Consecutive days with a scoring sighting, counting today.
    public var streakDays: Int
    public var alreadyScoredTodayForTaxon: Bool

    public init(
        taxon: Taxon,
        difficulty: FindDifficulty? = nil,
        freshness: PhotoFreshness,
        isDuplicatePhoto: Bool = false,
        hadFace: Bool = false,
        isFirstFindOfSpecies: Bool = false,
        streakDays: Int = 1,
        alreadyScoredTodayForTaxon: Bool = false
    ) {
        self.taxon = taxon
        self.difficulty = difficulty
        self.freshness = freshness
        self.isDuplicatePhoto = isDuplicatePhoto
        self.hadFace = hadFace
        self.isFirstFindOfSpecies = isFirstFindOfSpecies
        self.streakDays = streakDays
        self.alreadyScoredTodayForTaxon = alreadyScoredTodayForTaxon
    }
}

public enum GuideOnlyReason: Equatable, Sendable {
    case notSure
    case duplicatePhoto
    case photoTooOld
    case photoDateUnknown
    case alreadyScoredToday
}

public enum RejectionReason: Equatable, Sendable {
    case containsPerson
}

public enum ScoreOutcome: Equatable, Sendable {
    /// Points awarded and the sighting counts for challenges.
    case scored
    /// Saved to the field guide, but no points and no challenge credit.
    case guideOnly(GuideOnlyReason)
    /// Not saved at all.
    case rejected(RejectionReason)
}

public struct ScoreBreakdown: Equatable, Sendable {
    public let outcome: ScoreOutcome
    public let base: Int
    public let difficultyBonus: Int
    public let firstFindBonus: Int
    public let streakBonus: Int

    public var total: Int { base + difficultyBonus + firstFindBonus + streakBonus }
    public var countsForChallenges: Bool { outcome == .scored }
    public var savesToGuide: Bool {
        if case .rejected = outcome { return false }
        return true
    }
}

public enum ScoreCalculator {
    public static let streakBonusPerDay = 2
    public static let streakBonusCap = 10
    public static let firstFindBonus = 10

    public static func difficultyBonus(_ difficulty: FindDifficulty) -> Int {
        switch difficulty {
        case .easy: return 0
        case .medium: return 5
        case .hard: return 15
        }
    }

    public static func streakBonus(days: Int) -> Int {
        min(max(days, 0) * streakBonusPerDay, streakBonusCap)
    }

    public static func score(_ input: SightingInput) -> ScoreBreakdown {
        func none(_ outcome: ScoreOutcome) -> ScoreBreakdown {
            ScoreBreakdown(outcome: outcome, base: 0, difficultyBonus: 0, firstFindBonus: 0, streakBonus: 0)
        }

        if input.hadFace { return none(.rejected(.containsPerson)) }
        if input.taxon == .notSure { return none(.guideOnly(.notSure)) }
        if input.isDuplicatePhoto { return none(.guideOnly(.duplicatePhoto)) }
        switch input.freshness {
        case .stale: return none(.guideOnly(.photoTooOld))
        case .unknown: return none(.guideOnly(.photoDateUnknown))
        case .recent: break
        }
        if input.alreadyScoredTodayForTaxon { return none(.guideOnly(.alreadyScoredToday)) }

        var difficultyBonus = 0
        var firstFind = 0
        if case .species = input.taxon {
            difficultyBonus = input.difficulty.map(Self.difficultyBonus) ?? 0
            firstFind = input.isFirstFindOfSpecies ? Self.firstFindBonus : 0
        }

        return ScoreBreakdown(
            outcome: .scored,
            base: input.taxon.basePoints,
            difficultyBonus: difficultyBonus,
            firstFindBonus: firstFind,
            streakBonus: streakBonus(days: input.streakDays)
        )
    }
}
