import XCTest
@testable import TrailCore

final class SpeciesCatalogueTests: XCTestCase {
    func testBundledSeedLoads() throws {
        let species = try SpeciesCatalogue.bundled()
        XCTAssertFalse(species.isEmpty)
    }

    func testIDsAndCatalogueNumbersAreUnique() throws {
        let species = try SpeciesCatalogue.bundled()
        XCTAssertEqual(Set(species.map(\.id)).count, species.count)
        XCTAssertEqual(Set(species.map(\.catalogueNumber)).count, species.count)
    }

    func testVerifiedSpeciesHaveASourceAndAFact() throws {
        for species in try SpeciesCatalogue.bundled() where species.verified {
            XCTAssertNotNil(species.sourceURL.flatMap(URL.init(string:)), "\(species.id) needs a valid sourceURL")
            XCTAssertFalse((species.funFact ?? "").isEmpty, "\(species.id) is verified but has no fact")
        }
    }

    func testSourceURLsParse() throws {
        for species in try SpeciesCatalogue.bundled() {
            if let raw = species.sourceURL {
                XCTAssertNotNil(URL(string: raw), "\(species.id) has a bad sourceURL")
            }
        }
    }

    func testNoPhotoCreditsWhileWeShipSilhouettesOnly() throws {
        for species in try SpeciesCatalogue.bundled() {
            XCTAssertNil(species.photoCredit, "\(species.id) lists a photo credit but we ship no photos")
        }
    }
}
