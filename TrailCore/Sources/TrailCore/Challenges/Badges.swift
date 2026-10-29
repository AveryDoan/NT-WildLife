import Foundation

public struct BadgeStats: Equatable, Sendable {
    public var scoredSightings: Int
    public var longestStreak: Int
    public var groupsWithASpecies: Int
    public var foundHardSpecies: Bool
    public var speciesLevelSightings: Int
    public var notSureSightings: Int

    public init(
        scoredSightings: Int = 0, longestStreak: Int = 0, groupsWithASpecies: Int = 0,
        foundHardSpecies: Bool = false, speciesLevelSightings: Int = 0, notSureSightings: Int = 0
    ) {
        self.scoredSightings = scoredSightings
        self.longestStreak = longestStreak
        self.groupsWithASpecies = groupsWithASpecies
        self.foundHardSpecies = foundHardSpecies
        self.speciesLevelSightings = speciesLevelSightings
        self.notSureSightings = notSureSightings
    }
}

public struct BadgeDefinition: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let symbol: String
    public let detail: String
    let isEarned: @Sendable (BadgeStats) -> Bool

    public static func == (lhs: BadgeDefinition, rhs: BadgeDefinition) -> Bool { lhs.id == rhs.id }
}

public enum BadgeEngine {
    public static let all: [BadgeDefinition] = [
        BadgeDefinition(id: "first-find", title: "First find", symbol: "leaf",
                        detail: "Score your first sighting.") { $0.scoredSightings >= 1 },
        BadgeDefinition(id: "three-day-streak", title: "Three in a row", symbol: "flame",
                        detail: "Score on 3 days in a row.") { $0.longestStreak >= 3 },
        BadgeDefinition(id: "group-collector", title: "Variety", symbol: "square.grid.2x2",
                        detail: "Find species from 3 different groups.") { $0.groupsWithASpecies >= 3 },
        BadgeDefinition(id: "tough-find", title: "Tough find", symbol: "binoculars",
                        detail: "Find a species rated hard to find.") { $0.foundHardSpecies },
        BadgeDefinition(id: "sharp-eyes", title: "Sharp eyes", symbol: "eye",
                        detail: "Identify 5 finds to species.") { $0.speciesLevelSightings >= 5 },
        BadgeDefinition(id: "honest-explorer", title: "Honest explorer", symbol: "questionmark.bubble",
                        detail: "Say \"Not sure\" when you weren't. That's good science.") { $0.notSureSightings >= 1 },
    ]

    public static func earned(_ stats: BadgeStats) -> Set<String> {
        Set(all.filter { $0.isEarned(stats) }.map(\.id))
    }
}

extension StreakCalculator {
    /// Longest run of consecutive days with a scoring sighting.
    public static func longestStreak(scoringDays: Set<Date>, calendar: Calendar) -> Int {
        let days = Set(scoringDays.map { calendar.startOfDay(for: $0) })
        var best = 0
        for day in days {
            // Only start counting at the first day of a run.
            if let previous = calendar.date(byAdding: .day, value: -1, to: day), days.contains(previous) { continue }
            var length = 0
            var cursor = day
            while days.contains(cursor) {
                length += 1
                guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = next
            }
            best = max(best, length)
        }
        return best
    }
}
