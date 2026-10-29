import CoreLocation
import Foundation
import SwiftData
import TrailCore

/// What the player chose on the Identify screen.
struct IdentifyChoice {
    let taxon: Taxon
    let species: SpeciesInfo?
    let acceptedSuggestion: Bool
}

enum SightingService {
    /// Scores a candidate against the player's history and saves it to the guide
    /// (unless the photo is rejected). Returns the saved sighting.
    @MainActor
    static func save(
        photo: ImportedPhoto,
        faceStatus: FaceStatus,
        choice: IdentifyChoice,
        suggestion: VisionHint?,
        coordinate: CLLocationCoordinate2D?,
        history: [Sighting],
        context: ModelContext,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> (sighting: Sighting?, breakdown: ScoreBreakdown) {
        let candidate = SightingCandidate(
            taxon: choice.taxon,
            difficulty: choice.species?.findDifficulty,
            capturedAt: photo.capturedAt,
            loggedAt: now,
            photoHash: photo.hash,
            hadFace: faceStatus != .clear
        )
        let breakdown = SightingEvaluator.evaluate(candidate, history: history.map(\.record), calendar: calendar)
        guard breakdown.savesToGuide else { return (nil, breakdown) }

        let sensitive = choice.species?.isSensitive ?? false
        let rounded = coordinate.flatMap {
            LocationPrivacy.round(latitude: $0.latitude, longitude: $0.longitude, sensitive: sensitive)
        }

        let sighting = Sighting(
            taxon: choice.taxon,
            loggedAt: now,
            capturedAt: photo.capturedAt,
            coordinate: rounded,
            isSensitive: sensitive,
            breakdown: breakdown,
            photoData: photo.jpegData,
            photoHash: photo.hash,
            identifiedWith: choice.acceptedSuggestion ? "suggestion" : "manual",
            suggestionLabel: suggestion?.label,
            suggestionConfidence: suggestion?.confidence
        )
        context.insert(sighting)
        try? context.save()
        return (sighting, breakdown)
    }

    @MainActor
    static func deleteAllData(context: ModelContext) {
        try? context.delete(model: Sighting.self)
        try? context.save()
    }
}
