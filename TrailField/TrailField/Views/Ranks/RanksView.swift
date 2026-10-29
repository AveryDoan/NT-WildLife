import SwiftData
import SwiftUI
import TrailCore

struct RanksView: View {
    @AppStorage("nickname") private var nickname = ""
    @Query private var sightings: [Sighting]
    @State private var period: LeaderboardPeriod = .thisWeek
    @State private var entries: [LeaderboardEntry] = []

    /// A real backend would replace this one line.
    private let service: LeaderboardService = LocalLeaderboardService()

    private var player: PlayerScore {
        let stats = PlayerStats(sightings: sightings)
        return PlayerScore(
            nickname: nickname.isEmpty ? "You" : nickname,
            weekPoints: stats.weekPoints,
            allTimePoints: stats.totalPoints
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Period", selection: $period) {
                        ForEach(LeaderboardPeriod.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    SpecimenCard(caption: "Ranks") {
                        ForEach(entries) { entry in
                            row(entry)
                            if entry.id != entries.last?.id { Divider() }
                        }
                    }

                    Text("The other players here are made-up samples so you can see how ranks work. Real friends and classmates need a server, which this version doesn't have: everything stays on your phone.")
                        .font(TFFont.body(.footnote))
                        .foregroundStyle(Color.tfInk.opacity(0.85))
                }
                .padding(TFLayout.screenPadding)
            }
            .paperBackground()
            .navigationTitle("Ranks")
        }
        .task(id: RankKey(period: period, player: player)) {
            entries = (try? await service.entries(for: period, player: player)) ?? []
        }
    }

    private struct RankKey: Equatable {
        let period: LeaderboardPeriod
        let player: PlayerScore
    }

    private func row(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.system(.title3, design: .serif, weight: .bold))
                .monospacedDigit()
                .frame(width: 32)
                .foregroundStyle(Color.tfMoss)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.isCurrentPlayer ? "\(entry.nickname) (you)" : entry.nickname)
                    .font(TFFont.body().weight(entry.isCurrentPlayer ? .bold : .regular))
                    .foregroundStyle(Color.tfInk)
                if entry.isSample { SampleTag(kind: .samplePlayer) }
            }
            Spacer()
            Text("\(entry.points) pts").font(TFFont.body()).monospacedDigit().foregroundStyle(Color.tfInk)
        }
        .frame(minHeight: TFLayout.minTarget)
        .padding(.vertical, 2)
        .background(entry.isCurrentPlayer ? Color.tfSage : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(entry.rank), \(entry.nickname)\(entry.isSample ? ", sample player" : ", you"), \(entry.points) points")
    }
}
