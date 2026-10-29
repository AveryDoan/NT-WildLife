import SwiftUI
import TrailCore

/// This week's three challenges. Seeded by ISO week, so every phone shows the same ones.
struct ChallengesSection: View {
    let sightings: [Sighting]
    @Environment(SpeciesStore.self) private var store

    private var progress: [ChallengeProgress] {
        let week = ChallengeEngine.isoWeek(of: .now, timeZone: .current)
        let mapped = sightings.map {
            ChallengeSighting(
                loggedAt: $0.loggedAt,
                speciesID: $0.speciesID,
                groupKey: store.group(for: $0.taxon).rawValue,
                scored: $0.scored,
                isFirstFind: $0.firstFindBonus > 0
            )
        }
        return ChallengeEngine.challenges(year: week.year, week: week.week).map {
            ChallengeEngine.progress(for: $0, sightings: mapped, year: week.year, week: week.week, timeZone: .current)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "This week's challenges")
            SpecimenCard(caption: "Resets on Monday") {
                ForEach(progress, id: \.challenge.id) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isComplete ? Color.tfMoss : Color.tfInk.opacity(0.5))
                                .accessibilityHidden(true)
                            Text(item.challenge.title).font(TFFont.body().weight(.semibold)).foregroundStyle(Color.tfInk)
                            Spacer()
                            Text("\(min(item.current, item.challenge.target))/\(item.challenge.target)")
                                .font(TFFont.label(.subheadline)).monospacedDigit().foregroundStyle(Color.tfInk)
                        }
                        Text(item.challenge.detail).font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.85))
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.tfSage)
                                Capsule().fill(Color.tfMoss).frame(width: proxy.size.width * item.fraction)
                            }
                        }
                        .frame(height: 6)
                        .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.challenge.title). \(item.challenge.detail) \(min(item.current, item.challenge.target)) of \(item.challenge.target)\(item.isComplete ? ", complete" : "")")
                    if item.challenge.id != progress.last?.challenge.id { Divider() }
                }
                Text("Only photos taken in the last 72 hours count. Always from a safe distance, in daylight.")
                    .font(TFFont.body(.caption)).foregroundStyle(Color.tfInk.opacity(0.8))
            }
        }
    }
}

struct BadgesSection: View {
    let sightings: [Sighting]
    @Environment(SpeciesStore.self) private var store

    private var earned: Set<String> {
        let speciesFound = sightings.compactMap(\.speciesID)
        let infos = Set(speciesFound).compactMap { store.species(id: $0) }
        let stats = BadgeStats(
            scoredSightings: sightings.filter(\.scored).count,
            longestStreak: StreakCalculator.longestStreak(
                scoringDays: Set(sightings.filter(\.scored).map(\.loggedAt)), calendar: .current
            ),
            groupsWithASpecies: Set(infos.map(\.group)).count,
            foundHardSpecies: infos.contains { $0.findDifficulty == .hard },
            speciesLevelSightings: speciesFound.count,
            notSureSightings: sightings.filter { $0.taxon == .notSure }.count
        )
        return BadgeEngine.earned(stats)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Badges", detail: "\(earned.count) of \(BadgeEngine.all.count)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(BadgeEngine.all) { badge in
                        BadgeView(title: badge.title, symbol: badge.symbol, detail: badge.detail, earned: earned.contains(badge.id))
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
