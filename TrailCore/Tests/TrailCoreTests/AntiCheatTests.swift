import XCTest
@testable import TrailCore

final class AntiCheatTests: XCTestCase {
    /// 9x8 image that gets brighter left to right: every comparison is "left <= right", so hash 0.
    private func rising() -> [UInt8] {
        (0..<8).flatMap { _ in (0..<9).map { UInt8($0 * 20) } }
    }

    private func falling() -> [UInt8] {
        (0..<8).flatMap { _ in (0..<9).map { UInt8(200 - $0 * 20) } }
    }

    func testHashRejectsWrongSize() {
        XCTAssertNil(DHash.hash(grayscale: []))
        XCTAssertNil(DHash.hash(grayscale: [UInt8](repeating: 0, count: 71)))
    }

    func testHashIsStableAndDirectional() {
        XCTAssertEqual(DHash.hash(grayscale: rising()), 0)
        XCTAssertEqual(DHash.hash(grayscale: falling()), UInt64.max)
        XCTAssertEqual(DHash.hash(grayscale: falling()), DHash.hash(grayscale: falling()))
    }

    func testOppositeImagesAreFarApart() {
        guard let a = DHash.hash(grayscale: rising()), let b = DHash.hash(grayscale: falling()) else {
            return XCTFail("hash should not be nil for 72 pixels")
        }
        XCTAssertEqual(DHash.hammingDistance(a, b), 64)
    }

    func testDuplicateThresholdIsSixInclusive() {
        let base: UInt64 = 0
        let six: UInt64 = 0b111111
        let seven: UInt64 = 0b1111111
        XCTAssertTrue(DHash.isDuplicate(six, of: [base]))
        XCTAssertFalse(DHash.isDuplicate(seven, of: [base]))
        XCTAssertFalse(DHash.isDuplicate(seven, of: []))
    }

    func testFreshnessWindowIs72Hours() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let hour: TimeInterval = 3600
        XCTAssertEqual(PhotoFreshness.classify(capturedAt: now.addingTimeInterval(-71 * hour), now: now), .recent)
        XCTAssertEqual(PhotoFreshness.classify(capturedAt: now.addingTimeInterval(-72 * hour), now: now), .recent)
        XCTAssertEqual(PhotoFreshness.classify(capturedAt: now.addingTimeInterval(-73 * hour), now: now), .stale)
    }

    func testMissingOrFutureDatesAreUnknown() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(PhotoFreshness.classify(capturedAt: nil, now: now), .unknown)
        XCTAssertEqual(PhotoFreshness.classify(capturedAt: now.addingTimeInterval(3600), now: now), .unknown)
        XCTAssertEqual(PhotoFreshness.classify(capturedAt: now.addingTimeInterval(60), now: now), .recent)
    }
}
