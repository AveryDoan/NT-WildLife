import Foundation

/// A sighting already saved in the player's field guide, reduced to what scoring needs.
public struct SightingRecord: Equatable, Sendable {
    public var taxon: Taxon
    public var loggedAt: Date
    public var photoHash: UInt64?
    /// True if this sighting earned points.
    public var scored: Bool

    public init(taxon: Taxon, loggedAt: Date, photoHash: UInt64? = nil, scored: Bool) {
        self.taxon = taxon
        self.loggedAt = loggedAt
        self.photoHash = photoHash
        self.scored = scored
    }
}

/// A sighting about to be saved.
public struct SightingCandidate: Sendable {
    public var taxon: Taxon
    public var difficulty: FindDifficulty?
    /// Photo capture time, `nil` if unreadable.
    public var capturedAt: Date?
    public var loggedAt: Date
    public var photoHash: UInt64?
    public var hadFace: Bool

    public init(
        taxon: Taxon,
        difficulty: FindDifficulty? = nil,
        capturedAt: Date?,
        loggedAt: Date,
        photoHash: UInt64? = nil,
        hadFace: Bool = false
    ) {
        self.taxon = taxon
        self.difficulty = difficulty
        self.capturedAt = capturedAt
        self.loggedAt = loggedAt
        self.photoHash = photoHash
        self.hadFace = hadFace
    }
}

public enum StreakCalculator {
    /// Consecutive days, ending on `today`, that each have a scoring sighting.
    /// `today` always counts (the caller is about to score or has scored today).
    public static func currentStreak(scoringDays: Set<Date>, today: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: today)
        var days = Set(scoringDays.map { calendar.startOfDay(for: $0) })
        days.insert(start)
        var streak = 0
        var cursor = start
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Streak as shown on the Today tab: 0 if nothing has scored today or yesterday.
    public static func displayedStreak(scoringDays: Set<Date>, now: Date, calendar: Calendar) -> Int {
        let days = Set(scoringDays.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        guard days.contains(today) || days.contains(yesterday) else { return 0 }
        let anchor = days.contains(today) ? today : yesterday
        return currentStreak(scoringDays: days, today: anchor, calendar: calendar)
    }
}

/// Builds a `SightingInput` from the player's history and runs the score rules.
public enum SightingEvaluator {
    public static func evaluate(
        _ candidate: SightingCandidate,
        history: [SightingRecord],
        calendar: Calendar
    ) -> ScoreBreakdown {
        let freshness = PhotoFreshness.classify(capturedAt: candidate.capturedAt, now: candidate.loggedAt)

        let isDuplicate: Bool = {
            guard let hash = candidate.photoHash else { return false }
            return DHash.isDuplicate(hash, of: history.compactMap(\.photoHash))
        }()

        let day = calendar.startOfDay(for: candidate.loggedAt)
        let alreadyScoredToday: Bool = {
            guard let key = candidate.taxon.dailyKey else { return false }
            return history.contains {
                $0.scored && $0.taxon.dailyKey == key && calendar.startOfDay(for: $0.loggedAt) == day
            }
        }()

        let isFirstFind: Bool = {
            guard case .species(let id) = candidate.taxon else { return false }
            return !history.contains { $0.taxon == .species(id: id) }
        }()

        let scoringDays = Set(history.filter(\.scored).map(\.loggedAt))
        let streak = StreakCalculator.currentStreak(
            scoringDays: scoringDays, today: candidate.loggedAt, calendar: calendar
        )

        return ScoreCalculator.score(SightingInput(
            taxon: candidate.taxon,
            difficulty: candidate.difficulty,
            freshness: freshness,
            isDuplicatePhoto: isDuplicate,
            hadFace: candidate.hadFace,
            isFirstFindOfSpecies: isFirstFind,
            streakDays: streak,
            alreadyScoredTodayForTaxon: alreadyScoredToday
        ))
    }
}
