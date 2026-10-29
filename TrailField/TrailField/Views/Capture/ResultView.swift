import SwiftUI
import TrailCore

struct ResultView: View {
    let result: CaptureFlowView.SaveResult
    let onFinish: (AppTab?) -> Void

    @Environment(SpeciesStore.self) private var store

    private var species: SpeciesInfo? {
        result.sighting?.speciesID.flatMap { store.species(id: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headline

                if let sighting = result.sighting {
                    if let species {
                        SpecimenCard(catalogueNumber: species.catalogueNumber, caption: "Added to your guide") {
                            HStack(spacing: 12) {
                                SilhouetteView(group: species.group).frame(width: 56, height: 56)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(species.commonName).font(TFFont.heading(.title3)).foregroundStyle(Color.tfInk)
                                    Text(species.scientificName).font(TFFont.body(.subheadline)).italic().foregroundStyle(Color.tfInk.opacity(0.85))
                                }
                            }
                            if !species.verified { UnverifiedTag() }
                            if let fact = species.funFact {
                                Text(fact).font(TFFont.body()).foregroundStyle(Color.tfInk)
                            }
                        }
                        if let note = species.safetyNote {
                            SafetyBanner(message: note)
                        }
                    } else {
                        SpecimenCard(caption: sighting.taxon == .notSure ? "To identify" : "Added to your guide") {
                            Text(store.title(for: sighting.taxon))
                                .font(TFFont.heading(.title3))
                                .foregroundStyle(Color.tfInk)
                        }
                    }

                    Label(
                        result.pinned
                            ? "Pinned on the map near here (rounded to about \(sighting.isSensitive ? "11" : "1") km)."
                            : "No location saved, so there's no map pin for this one.",
                        systemImage: result.pinned ? "mappin.and.ellipse" : "mappin.slash"
                    )
                    .font(TFFont.body(.footnote))
                    .foregroundStyle(Color.tfInk)
                }

                VStack(spacing: 12) {
                    Button("See it in my field guide") { onFinish(.guide) }
                        .buttonStyle(PrimaryButtonStyle())
                    if result.pinned {
                        Button("See it on the map") { onFinish(.map) }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    Button("Done") { onFinish(nil) }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: result.breakdown.countsForChallenges)
    }

    @ViewBuilder
    private var headline: some View {
        let breakdown = result.breakdown
        switch breakdown.outcome {
        case .scored:
            VStack(alignment: .leading, spacing: 12) {
                Text("Nice find!").font(TFFont.heading(.largeTitle)).foregroundStyle(Color.tfInk)
                PointsChip(points: breakdown.total)
                SpecimenCard(caption: "How you scored") {
                    breakdownRow("Identified to \(rankName)", breakdown.base)
                    if breakdown.difficultyBonus > 0 { breakdownRow("Hard-to-find bonus", breakdown.difficultyBonus) }
                    if breakdown.firstFindBonus > 0 { breakdownRow("First time finding this", breakdown.firstFindBonus) }
                    if breakdown.streakBonus > 0 { breakdownRow("Streak bonus", breakdown.streakBonus) }
                }
            }
        case .guideOnly(let reason):
            VStack(alignment: .leading, spacing: 8) {
                Text(reason == .notSure ? "Saved for later" : "Saved to your guide")
                    .font(TFFont.heading(.largeTitle)).foregroundStyle(Color.tfInk)
                Text(reason.explanation).font(TFFont.body()).foregroundStyle(Color.tfInk)
            }
        case .rejected:
            Text("Not saved").font(TFFont.heading(.largeTitle)).foregroundStyle(Color.tfInk)
        }
    }

    private var rankName: String {
        switch result.sighting?.taxon {
        case .species: return "species"
        case .genus: return "genus"
        case .family: return "family"
        case .order: return "group"
        default: return "group"
        }
    }

    private func breakdownRow(_ title: String, _ points: Int) -> some View {
        HStack {
            Text(title).font(TFFont.body()).foregroundStyle(Color.tfInk)
            Spacer()
            Text("+\(points)").font(TFFont.body().weight(.semibold)).monospacedDigit().foregroundStyle(Color.tfInk)
        }
        .accessibilityElement(children: .combine)
    }
}
