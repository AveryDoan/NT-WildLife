import Foundation
import TrailCore

/// Everything the Today and Ranks tabs show, computed from saved sightings.
struct PlayerStats {
    let totalPoints: Int
    let todayPoints: Int
    let weekPoints: Int
    let streak: Int
    let speciesFound: Set<String>
    let scoringSightings: Int
    let hasDemoData: Bool

    init(sightings: [Sighting], now: Date = .now, calendar: Calendar = .current) {
        totalPoints = sightings.reduce(0) { $0 + $1.points }
        todayPoints = sightings
            .filter { calendar.isDate($0.loggedAt, inSameDayAs: now) }
            .reduce(0) { $0 + $1.points }

        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        let weekInterval = iso.dateInterval(of: .weekOfYear, for: now)
        weekPoints = sightings
            .filter { weekInterval?.contains($0.loggedAt) ?? false }
            .reduce(0) { $0 + $1.points }

        streak = StreakCalculator.displayedStreak(
            scoringDays: Set(sightings.filter(\.scored).map(\.loggedAt)), now: now, calendar: calendar
        )
        speciesFound = Set(sightings.compactMap(\.speciesID))
        scoringSightings = sightings.filter(\.scored).count
        hasDemoData = sightings.contains(where: \.isDemo)
    }
}
