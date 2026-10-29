import Foundation

public enum LeaderboardPeriod: String, CaseIterable, Sendable {
    case thisWeek
    case allTime

    public var displayName: String {
        switch self {
        case .thisWeek: return "This week"
        case .allTime: return "All time"
        }
    }
}

public struct PlayerScore: Equatable, Sendable {
    public var nickname: String
    public var weekPoints: Int
    public var allTimePoints: Int

    public init(nickname: String, weekPoints: Int, allTimePoints: Int) {
        self.nickname = nickname
        self.weekPoints = weekPoints
        self.allTimePoints = allTimePoints
    }

    func points(for period: LeaderboardPeriod) -> Int {
        period == .thisWeek ? weekPoints : allTimePoints
    }
}

public struct LeaderboardEntry: Identifiable, Equatable, Sendable {
    public let id: String
    public let rank: Int
    public let nickname: String
    public let points: Int
    public let isCurrentPlayer: Bool
    /// True for made-up players. The UI must always label these "Sample player".
    public let isSample: Bool
}

/// Where ranks come from. A real backend (accounts, moderation, anti-cheat on the server)
/// would replace `LocalLeaderboardService`; the screens only know this protocol.
public protocol LeaderboardService: Sendable {
    func entries(for period: LeaderboardPeriod, player: PlayerScore) async throws -> [LeaderboardEntry]
}

/// On-device leaderboard: the player plus clearly labelled sample players.
public struct LocalLeaderboardService: LeaderboardService {
    public struct Sample: Sendable {
        public let nickname: String
        public let weekPoints: Int
        public let allTimePoints: Int
        public init(nickname: String, weekPoints: Int, allTimePoints: Int) {
            self.nickname = nickname
            self.weekPoints = weekPoints
            self.allTimePoints = allTimePoints
        }
    }

    public static let defaultSamples: [Sample] = [
        Sample(nickname: "Wattle", weekPoints: 142, allTimePoints: 512),
        Sample(nickname: "Barra", weekPoints: 96, allTimePoints: 430),
        Sample(nickname: "Stringybark", weekPoints: 64, allTimePoints: 305),
        Sample(nickname: "Mangrove", weekPoints: 35, allTimePoints: 190),
        Sample(nickname: "Spinifex", weekPoints: 12, allTimePoints: 88),
    ]

    private let samples: [Sample]

    public init(samples: [Sample] = LocalLeaderboardService.defaultSamples) {
        self.samples = samples
    }

    public func entries(for period: LeaderboardPeriod, player: PlayerScore) async throws -> [LeaderboardEntry] {
        struct Row { let id: String; let nickname: String; let points: Int; let isMe: Bool; let isSample: Bool }
        var rows = samples.map { s in
            Row(id: "sample-\(s.nickname)", nickname: s.nickname,
                points: period == .thisWeek ? s.weekPoints : s.allTimePoints, isMe: false, isSample: true)
        }
        rows.append(Row(id: "me", nickname: player.nickname, points: player.points(for: period), isMe: true, isSample: false))
        rows.sort { ($0.points, $1.nickname) > ($1.points, $0.nickname) }

        var result: [LeaderboardEntry] = []
        for (index, row) in rows.enumerated() {
            // Ties share a rank.
            let rank = (index > 0 && rows[index - 1].points == row.points) ? result[index - 1].rank : index + 1
            result.append(LeaderboardEntry(
                id: row.id, rank: rank, nickname: row.nickname, points: row.points,
                isCurrentPlayer: row.isMe, isSample: row.isSample
            ))
        }
        return result
    }
}
