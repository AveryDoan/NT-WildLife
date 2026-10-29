import Foundation
import SwiftData
import TrailCore

/// One saved find. Everything stays on the device. Locations are stored already rounded.
@Model
final class Sighting {
    @Attribute(.unique) var id: UUID
    var taxonKind: String
    var taxonValue: String
    var loggedAt: Date
    /// When the photo was taken, if we could read it. `nil` means unknown.
    var capturedAt: Date?
    /// Rounded (about 1 km, or about 11 km for sensitive species). Never precise.
    var latitude: Double?
    var longitude: Double?
    var isSensitive: Bool

    var points: Int
    var basePoints: Int
    var difficultyBonus: Int
    var firstFindBonus: Int
    var streakBonus: Int
    /// "scored" or "guideOnly".
    var outcomeKind: String
    var guideOnlyReason: String?

    /// Downsized JPEG with no EXIF or GPS. `nil` for demo data.
    @Attribute(.externalStorage) var photoData: Data?
    /// dHash as the same 64 bits stored signed.
    var photoHash: Int64?

    var isDemo: Bool
    /// "manual" or "suggestion" (the player accepted the Vision hint's group).
    var identifiedWith: String
    var suggestionLabel: String?
    var suggestionConfidence: Double?

    init(
        taxon: Taxon,
        loggedAt: Date,
        capturedAt: Date?,
        coordinate: RoundedCoordinate?,
        isSensitive: Bool,
        breakdown: ScoreBreakdown,
        photoData: Data?,
        photoHash: UInt64?,
        isDemo: Bool = false,
        identifiedWith: String = "manual",
        suggestionLabel: String? = nil,
        suggestionConfidence: Double? = nil
    ) {
        let stored = taxon.storage
        self.id = UUID()
        self.taxonKind = stored.kind
        self.taxonValue = stored.value
        self.loggedAt = loggedAt
        self.capturedAt = capturedAt
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
        self.isSensitive = isSensitive
        self.points = breakdown.total
        self.basePoints = breakdown.base
        self.difficultyBonus = breakdown.difficultyBonus
        self.firstFindBonus = breakdown.firstFindBonus
        self.streakBonus = breakdown.streakBonus
        switch breakdown.outcome {
        case .scored:
            self.outcomeKind = "scored"
            self.guideOnlyReason = nil
        case .guideOnly(let reason):
            self.outcomeKind = "guideOnly"
            self.guideOnlyReason = reason.storageKey
        case .rejected:
            // Rejected photos are never saved; callers must not construct a Sighting for them.
            self.outcomeKind = "guideOnly"
            self.guideOnlyReason = nil
        }
        self.photoData = photoData
        self.photoHash = photoHash.map { Int64(bitPattern: $0) }
        self.isDemo = isDemo
        self.identifiedWith = identifiedWith
        self.suggestionLabel = suggestionLabel
        self.suggestionConfidence = suggestionConfidence
    }

    var taxon: Taxon { Taxon(kind: taxonKind, value: taxonValue) ?? .notSure }
    var scored: Bool { outcomeKind == "scored" }
    var speciesID: String? {
        if case .species(let id) = taxon { return id }
        return nil
    }
    var hash: UInt64? { photoHash.map { UInt64(bitPattern: $0) } }
    var record: SightingRecord {
        SightingRecord(taxon: taxon, loggedAt: loggedAt, photoHash: hash, scored: scored)
    }
    var coordinate: RoundedCoordinate? {
        guard let latitude, let longitude else { return nil }
        return RoundedCoordinate(latitude: latitude, longitude: longitude)
    }
    var guideReason: GuideOnlyReason? {
        guideOnlyReason.flatMap(GuideOnlyReason.init(storageKey:))
    }
}

extension GuideOnlyReason {
    nonisolated var storageKey: String {
        switch self {
        case .notSure: return "notSure"
        case .duplicatePhoto: return "duplicatePhoto"
        case .photoTooOld: return "photoTooOld"
        case .photoDateUnknown: return "photoDateUnknown"
        case .alreadyScoredToday: return "alreadyScoredToday"
        }
    }

    nonisolated init?(storageKey: String) {
        switch storageKey {
        case "notSure": self = .notSure
        case "duplicatePhoto": self = .duplicatePhoto
        case "photoTooOld": self = .photoTooOld
        case "photoDateUnknown": self = .photoDateUnknown
        case "alreadyScoredToday": self = .alreadyScoredToday
        default: return nil
        }
    }

    /// Plain-English reason shown on the Result screen.
    var explanation: String {
        switch self {
        case .notSure:
            return "No problem. It's on your \"To identify\" shelf and scores no points."
        case .duplicatePhoto:
            return "We've seen this photo (or a very similar one) before, so it's saved to your guide without points."
        case .photoTooOld:
            return "This photo is more than 72 hours old, so it counts in your guide only: no points or challenge credit."
        case .photoDateUnknown:
            return "We couldn't read when this photo was taken, so it counts in your guide only: no points or challenge credit."
        case .alreadyScoredToday:
            return "You've already scored for this one today. Saved to your guide; come back tomorrow for more points."
        }
    }
}
