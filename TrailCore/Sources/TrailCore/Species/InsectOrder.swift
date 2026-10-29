import Foundation

/// Insect orders offered for "I only know the group" answers (5 points).
/// Standard taxonomy only: no regional claims are made here.
/// Termites sit inside Blattodea in current classifications.
public enum InsectOrder: String, CaseIterable, Codable, Sendable {
    case coleoptera = "Coleoptera"
    case lepidoptera = "Lepidoptera"
    case hymenoptera = "Hymenoptera"
    case blattodea = "Blattodea"
    case orthoptera = "Orthoptera"
    case hemiptera = "Hemiptera"
    case odonata = "Odonata"
    case diptera = "Diptera"
    case mantodea = "Mantodea"

    public var scientificName: String { rawValue }

    public var displayName: String {
        switch self {
        case .coleoptera: return "Beetles"
        case .lepidoptera: return "Butterflies and moths"
        case .hymenoptera: return "Ants, bees and wasps"
        case .blattodea: return "Termites and cockroaches"
        case .orthoptera: return "Grasshoppers and crickets"
        case .hemiptera: return "True bugs and cicadas"
        case .odonata: return "Dragonflies and damselflies"
        case .diptera: return "Flies"
        case .mantodea: return "Mantises"
        }
    }

    /// Silhouette used for this order.
    public var group: SpeciesGroup {
        switch self {
        case .coleoptera: return .beetles
        case .lepidoptera: return .butterfliesAndMoths
        case .hymenoptera: return .beesAndWasps
        case .blattodea: return .termites
        case .orthoptera: return .grasshoppers
        case .hemiptera: return .bugs
        case .odonata: return .dragonflies
        case .diptera: return .flies
        case .mantodea: return .other
        }
    }

    public init?(scientificName: String) {
        self.init(rawValue: scientificName)
    }
}
