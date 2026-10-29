import Foundation

/// What the user said they found. Rank-level answers are allowed and score less.
public enum Taxon: Equatable, Hashable, Codable, Sendable {
    case species(id: String)
    case genus(String)
    case family(String)
    case order(String)
    case notSure

    /// Base points by how precise the answer is.
    public var basePoints: Int {
        switch self {
        case .species: return 20
        case .genus: return 15
        case .family: return 10
        case .order: return 5
        case .notSure: return 0
        }
    }

    /// Key for "one scoring sighting per taxon per day". `nil` for "Not sure".
    public var dailyKey: String? {
        switch self {
        case .species(let id): return "species:\(id)"
        case .genus(let name): return "genus:\(name.lowercased())"
        case .family(let name): return "family:\(name.lowercased())"
        case .order(let name): return "order:\(name.lowercased())"
        case .notSure: return nil
        }
    }
}
