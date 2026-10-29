import Foundation
import Observation
import TrailCore

/// The seeded species list, loaded once from TrailCore's bundled species.json.
@Observable
final class SpeciesStore {
    private(set) var all: [SpeciesInfo] = []
    private(set) var loadError: String?

    init() {
        do {
            all = try SpeciesCatalogue.bundled().sorted { $0.catalogueNumber < $1.catalogueNumber }
        } catch {
            loadError = "Couldn't load the species list."
        }
    }

    init(species: [SpeciesInfo]) {
        all = species
    }

    func species(id: String) -> SpeciesInfo? {
        all.first { $0.id == id }
    }

    /// Groups that have at least one species, in a stable order.
    var groups: [SpeciesGroup] {
        SpeciesGroup.allCases.filter { group in all.contains { $0.group == group } }
    }

    func species(in group: SpeciesGroup) -> [SpeciesInfo] {
        all.filter { $0.group == group }
    }

    /// Display name for any taxon.
    func title(for taxon: Taxon) -> String {
        switch taxon {
        case .species(let id): return species(id: id)?.commonName ?? "Unknown species"
        case .genus(let name), .family(let name): return name
        case .order(let name): return InsectOrder(scientificName: name)?.displayName ?? name
        case .notSure: return "Not sure"
        }
    }

    func group(for taxon: Taxon) -> SpeciesGroup {
        switch taxon {
        case .species(let id): return species(id: id)?.group ?? .other
        case .order(let name): return InsectOrder(scientificName: name)?.group ?? .other
        default: return .other
        }
    }
}
