import Foundation

/// A sighting reduced to what challenges and badges need.
public struct ChallengeSighting: Equatable, Sendable {
    public var loggedAt: Date
    public var speciesID: String?
    /// Browsing group key (for example "ants"), used for "different groups".
    public var groupKey: String
    /// Only scoring sightings count for challenges.
    public var scored: Bool
    public var isFirstFind: Bool

    public init(loggedAt: Date, speciesID: String?, groupKey: String, scored: Bool, isFirstFind: Bool = false) {
        self.loggedAt = loggedAt
        self.speciesID = speciesID
        self.groupKey = groupKey
        self.scored = scored
        self.isFirstFind = isFirstFind
    }
}

public enum ChallengeKind: String, Codable, CaseIterable, Sendable {
    case distinctSpecies
    case distinctGroups
    case scoringDays
    case speciesLevelFinds
    case newSpecies
}

public struct Challenge: Identifiable, Equatable, Sendable {
    public let kind: ChallengeKind
    public let target: Int
    public let title: String
    public let detail: String
    public var id: String { "\(kind.rawValue)-\(target)" }
}

public struct ChallengeProgress: Equatable, Sendable {
    public let challenge: Challenge
    public let current: Int
    public var isComplete: Bool { current >= challenge.target }
    public var fraction: Double { min(1, Double(current) / Double(max(challenge.target, 1))) }
}

/// Weekly challenges, seeded by ISO week so every phone shows the same three.
/// Every challenge is safe by construction: just photographing from a distance in daylight.
/// None needs water edges, night-time, collecting, or national-park restricted areas.
public enum ChallengeEngine {
    public static let perWeek = 3

    static let pool: [Challenge] = [
        Challenge(kind: .distinctSpecies, target: 2, title: "Two different species",
                  detail: "Score finds of 2 different species this week."),
        Challenge(kind: .distinctSpecies, target: 3, title: "Three different species",
                  detail: "Score finds of 3 different species this week."),
        Challenge(kind: .distinctGroups, target: 2, title: "Spread your search",
                  detail: "Score finds from 2 different groups, like ants and butterflies."),
        Challenge(kind: .scoringDays, target: 3, title: "Three days out",
                  detail: "Score on 3 different days this week."),
        Challenge(kind: .speciesLevelFinds, target: 3, title: "Sharp eyes",
                  detail: "Identify 3 finds all the way to species."),
        Challenge(kind: .newSpecies, target: 1, title: "Something new",
                  detail: "Add a species to your field guide for the first time."),
    ]

    /// ISO year and week number for a date.
    public static func isoWeek(of date: Date, timeZone: TimeZone) -> (year: Int, week: Int) {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        return (calendar.component(.yearForWeekOfYear, from: date), calendar.component(.weekOfYear, from: date))
    }

    public static func challenges(year: Int, week: Int) -> [Challenge] {
        var state = UInt64(year * 100 + week)
        var picks: [Int] = []
        while picks.count < perWeek {
            state = (state &* 6364136223846793005 &+ 1442695040888963407)
            let index = Int((state >> 33) % UInt64(pool.count))
            if !picks.contains(index) { picks.append(index) }
        }
        return picks.map { pool[$0] }
    }

    public static func progress(
        for challenge: Challenge,
        sightings: [ChallengeSighting],
        year: Int,
        week: Int,
        timeZone: TimeZone
    ) -> ChallengeProgress {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        let thisWeek = sightings.filter {
            $0.scored
                && calendar.component(.yearForWeekOfYear, from: $0.loggedAt) == year
                && calendar.component(.weekOfYear, from: $0.loggedAt) == week
        }
        let current: Int
        switch challenge.kind {
        case .distinctSpecies: current = Set(thisWeek.compactMap(\.speciesID)).count
        case .distinctGroups: current = Set(thisWeek.map(\.groupKey)).count
        case .scoringDays: current = Set(thisWeek.map { calendar.startOfDay(for: $0.loggedAt) }).count
        case .speciesLevelFinds: current = thisWeek.filter { $0.speciesID != nil }.count
        case .newSpecies: current = thisWeek.filter(\.isFirstFind).count
        }
        return ChallengeProgress(challenge: challenge, current: current)
    }
}
