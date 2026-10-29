import Foundation

/// The browsing groups shown in the Identify list and Field Guide.
/// These are app groupings, not strict scientific orders (termites, for example,
/// sit inside Blattodea). The scientific order lives in `SpeciesInfo.order`.
public enum SpeciesGroup: String, Codable, CaseIterable, Sendable {
    case beetles
    case butterfliesAndMoths
    case ants
    case termites
    case beesAndWasps
    case grasshoppers
    case bugs
    case dragonflies
    case flies
    case other

    public var displayName: String {
        switch self {
        case .beetles: return "Beetles"
        case .butterfliesAndMoths: return "Butterflies and moths"
        case .ants: return "Ants"
        case .termites: return "Termites"
        case .beesAndWasps: return "Bees and wasps"
        case .grasshoppers: return "Grasshoppers"
        case .bugs: return "Bugs"
        case .dragonflies: return "Dragonflies"
        case .flies: return "Flies"
        case .other: return "Other insects"
        }
    }
}

public enum Season: String, Codable, Sendable {
    case wet
    case dry
    case both
}

/// An in-game rating of how hard a species is to find. NOT a conservation status.
public enum FindDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}

public struct SpeciesInfo: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let catalogueNumber: Int
    public let commonName: String
    public let scientificName: String
    public let group: SpeciesGroup
    /// Scientific order, only when a source confirms it.
    public let order: String?
    public let family: String?
    public let habitat: String?
    public let bestSeason: Season?
    public let findDifficulty: FindDifficulty
    public let funFact: String?
    public let safetyNote: String?
    public let sourceURL: String?
    /// True only when every filled field was checked against a source we read.
    public let verified: Bool
    public let photoCredit: String?
    /// Sensitive species get coarser map locations (mode built later).
    public let isSensitive: Bool

    public init(
        id: String,
        catalogueNumber: Int,
        commonName: String,
        scientificName: String,
        group: SpeciesGroup,
        order: String? = nil,
        family: String? = nil,
        habitat: String? = nil,
        bestSeason: Season? = nil,
        findDifficulty: FindDifficulty,
        funFact: String? = nil,
        safetyNote: String? = nil,
        sourceURL: String? = nil,
        verified: Bool,
        photoCredit: String? = nil,
        isSensitive: Bool = false
    ) {
        self.id = id
        self.catalogueNumber = catalogueNumber
        self.commonName = commonName
        self.scientificName = scientificName
        self.group = group
        self.order = order
        self.family = family
        self.habitat = habitat
        self.bestSeason = bestSeason
        self.findDifficulty = findDifficulty
        self.funFact = funFact
        self.safetyNote = safetyNote
        self.sourceURL = sourceURL
        self.verified = verified
        self.photoCredit = photoCredit
        self.isSensitive = isSensitive
    }
}

public enum SpeciesCatalogueError: Error, Equatable {
    case resourceMissing
}

public enum SpeciesCatalogue {
    public static func decode(from data: Data) throws -> [SpeciesInfo] {
        try JSONDecoder().decode([SpeciesInfo].self, from: data)
    }

    /// Loads the seeded `species.json` bundled with TrailCore.
    public static func bundled() throws -> [SpeciesInfo] {
        guard let url = Bundle.module.url(forResource: "species", withExtension: "json") else {
            throw SpeciesCatalogueError.resourceMissing
        }
        return try decode(from: Data(contentsOf: url))
    }
}
