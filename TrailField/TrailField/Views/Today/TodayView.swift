import SwiftData
import SwiftUI
import TrailCore

struct TodayView: View {
    @Binding var selectedTab: AppTab
    @AppStorage("nickname") private var nickname = ""
    @Environment(SpeciesStore.self) private var store
    @Query(sort: \Sighting.loggedAt, order: .reverse) private var sightings: [Sighting]
    @State private var showSettings = false

    private var stats: PlayerStats { PlayerStats(sightings: sightings) }

    /// Same pick all day, changes at midnight. Stable and needs no network.
    private var lookout: SpeciesInfo? {
        guard !store.all.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return store.all[day % store.all.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if stats.hasDemoData {
                        HStack {
                            SampleTag(kind: .demo)
                            Text("Demo mode is on: sample finds are included.")
                                .font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk)
                        }
                    }

                    SpecimenCard(caption: "Your field journal") {
                        Text(nickname.isEmpty ? "G'day!" : "G'day, \(nickname)")
                            .font(TFFont.heading(.title))
                            .foregroundStyle(Color.tfInk)
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(stats.totalPoints)")
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(Color.tfMoss)
                            Text("points").font(TFFont.body()).foregroundStyle(Color.tfInk)
                            Spacer()
                            Tag(text: stats.streak == 1 ? "1 day streak" : "\(stats.streak) day streak", symbol: "flame", fill: .tfSage)
                        }
                        .accessibilityElement(children: .combine)
                        Text("\(stats.todayPoints) today · \(stats.speciesFound.count) of \(store.all.count) species found")
                            .font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.85))
                    }

                    if let lookout {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Today's lookout")
                            SpecimenCard(catalogueNumber: lookout.catalogueNumber) {
                                HStack(spacing: 12) {
                                    SilhouetteView(group: lookout.group).frame(width: 56, height: 56)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lookout.commonName).font(TFFont.heading(.headline)).foregroundStyle(Color.tfInk)
                                        Text("Find difficulty: \(lookout.findDifficulty.rawValue)")
                                            .font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.85))
                                    }
                                }
                                if !lookout.verified { UnverifiedTag() }
                                Button { selectedTab = .capture } label: {
                                    Label("Open Capture", systemImage: "camera")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }
                    }

                    SafetyBanner(message: "Daylight only, on marked tracks. Keep well back from water edges (crocodiles) and never touch insects, snakes or spiders.")

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Recent finds")
                        if sightings.isEmpty {
                            EmptyState(symbol: "leaf", title: "No finds yet",
                                       message: "Photograph an insect from a safe distance to start your field guide.")
                                .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
                        } else {
                            ForEach(sightings.prefix(3)) { sighting in
                                SpecimenCard { SightingRow(sighting: sighting) }
                            }
                        }
                    }
                }
                .padding(TFLayout.screenPadding)
            }
            .paperBackground()
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSettings = true } label: {
                        Image(systemName: "person.crop.circle")
                            .frame(minWidth: TFLayout.minTarget, minHeight: TFLayout.minTarget)
                    }
                    .accessibilityLabel("Profile and settings")
                }
            }
            .sheet(isPresented: $showSettings) { ProfileView() }
        }
    }
}
