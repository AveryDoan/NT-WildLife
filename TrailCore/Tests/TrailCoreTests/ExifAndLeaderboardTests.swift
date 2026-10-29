import XCTest
@testable import TrailCore

final class ExifDateTests: XCTestCase {
    private let darwin = TimeZone(identifier: "Australia/Darwin")!

    func testParsesInAssumedZone() throws {
        let date = try XCTUnwrap(ExifDate.parse("2026:10:29 14:05:09", assumedZone: darwin))
        // 14:05:09 at UTC+9:30 is 04:35:09 UTC.
        XCTAssertEqual(date, ISO8601DateFormatter().date(from: "2026-10-29T04:35:09Z"))
    }

    func testOffsetOverridesAssumedZone() throws {
        let date = try XCTUnwrap(ExifDate.parse("2026:10:29 14:05:09", offset: "+10:00", assumedZone: darwin))
        XCTAssertEqual(date, ISO8601DateFormatter().date(from: "2026-10-29T04:05:09Z"))
    }

    func testBadInputGivesNil() {
        XCTAssertNil(ExifDate.parse(nil, assumedZone: darwin))
        XCTAssertNil(ExifDate.parse("", assumedZone: darwin))
        XCTAssertNil(ExifDate.parse("0000:00:00 00:00:00", assumedZone: darwin))
        XCTAssertNil(ExifDate.parse("yesterday", assumedZone: darwin))
    }

    func testBadOffsetFallsBackToAssumedZone() throws {
        let a = try XCTUnwrap(ExifDate.parse("2026:10:29 14:05:09", offset: "bogus", assumedZone: darwin))
        let b = try XCTUnwrap(ExifDate.parse("2026:10:29 14:05:09", assumedZone: darwin))
        XCTAssertEqual(a, b)
    }
}

final class LeaderboardTests: XCTestCase {
    func testPlayerIsRankedAmongSamplesAndSamplesAreFlagged() async throws {
        let service = LocalLeaderboardService()
        let me = PlayerScore(nickname: "Quokka", weekPoints: 100, allTimePoints: 0)
        let entries = try await service.entries(for: .thisWeek, player: me)
        XCTAssertEqual(entries.count, LocalLeaderboardService.defaultSamples.count + 1)
        let mine = try XCTUnwrap(entries.first(where: \.isCurrentPlayer))
        XCTAssertEqual(mine.rank, 2) // 142 first, then 100, then 96
        XCTAssertTrue(entries.filter { !$0.isCurrentPlayer }.allSatisfy(\.isSample))
        XCTAssertFalse(mine.isSample)
    }

    func testTiesShareARank() async throws {
        let service = LocalLeaderboardService(samples: [
            .init(nickname: "A", weekPoints: 50, allTimePoints: 50),
            .init(nickname: "B", weekPoints: 50, allTimePoints: 50),
        ])
        let entries = try await service.entries(for: .allTime, player: PlayerScore(nickname: "Me", weekPoints: 0, allTimePoints: 10))
        XCTAssertEqual(entries.map(\.rank), [1, 1, 3])
    }

    func testAllTimeUsesAllTimePoints() async throws {
        let service = LocalLeaderboardService(samples: [])
        let entries = try await service.entries(for: .allTime, player: PlayerScore(nickname: "Me", weekPoints: 1, allTimePoints: 99))
        XCTAssertEqual(entries.first?.points, 99)
    }
}
