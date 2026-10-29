import Foundation
import SwiftData
import TrailCore

/// Sample sightings so the guide, map and Today screen look populated for a demo.
/// Every one is flagged `isDemo` and shown with a "Demo" tag. Turning demo mode off removes them.
enum DemoData {
    private struct Entry {
        let daysAgo: Int
        let taxon: Taxon
        let latitude: Double
        let longitude: Double
    }

    private static let entries: [Entry] = [
        Entry(daysAgo: 3, taxon: .species(id: "magnetic-termite"), latitude: -12.4634, longitude: 130.8456),
        Entry(daysAgo: 2, taxon: .species(id: "green-tree-ant"), latitude: -12.3721, longitude: 130.8712),
        Entry(daysAgo: 1, taxon: .species(id: "leichhardts-grasshopper"), latitude: -13.0412, longitude: 132.4219),
        Entry(daysAgo: 1, taxon: .notSure, latitude: -12.4011, longitude: 130.9120),
    ]

    @MainActor
    static func enable(species: SpeciesStore, context: ModelContext, now: Date = .now, calendar: Calendar = .current) {
        disable(context: context)
        var history = (try? context.fetch(FetchDescriptor<Sighting>())) ?? []

        for entry in entries {
            guard let base = calendar.date(byAdding: .day, value: -entry.daysAgo, to: now),
                  let loggedAt = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: base) else { continue }
            let info: SpeciesInfo? = {
                if case .species(let id) = entry.taxon { return species.species(id: id) }
                return nil
            }()
            if case .species = entry.taxon, info == nil { continue }

            let candidate = SightingCandidate(
                taxon: entry.taxon, difficulty: info?.findDifficulty,
                capturedAt: loggedAt.addingTimeInterval(-600), loggedAt: loggedAt
            )
            let breakdown = SightingEvaluator.evaluate(candidate, history: history.map(\.record), calendar: calendar)
            let sensitive = info?.isSensitive ?? false
            let sighting = Sighting(
                taxon: entry.taxon, loggedAt: loggedAt, capturedAt: candidate.capturedAt,
                coordinate: LocationPrivacy.round(latitude: entry.latitude, longitude: entry.longitude, sensitive: sensitive),
                isSensitive: sensitive, breakdown: breakdown, photoData: nil, photoHash: nil, isDemo: true
            )
            context.insert(sighting)
            history.append(sighting)
        }
        try? context.save()
    }

    @MainActor
    static func disable(context: ModelContext) {
        try? context.delete(model: Sighting.self, where: #Predicate { $0.isDemo })
        try? context.save()
    }
}
