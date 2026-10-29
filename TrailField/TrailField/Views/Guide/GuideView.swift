import SwiftData
import SwiftUI
import TrailCore

struct GuideView: View {
    @Environment(SpeciesStore.self) private var store
    @Query(sort: \Sighting.loggedAt, order: .reverse) private var sightings: [Sighting]

    private var foundIDs: Set<String> { Set(sightings.compactMap(\.speciesID)) }
    private var toIdentify: [Sighting] { sightings.filter { $0.taxon == .notSure } }
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summary
                    ringRow
                    ForEach(store.groups, id: \.self) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: group.displayName)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(store.species(in: group)) { species in
                                    NavigationLink(value: species) {
                                        SpeciesTile(species: species, found: foundIDs.contains(species.id))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    shelf
                    otherFinds
                }
                .padding(TFLayout.screenPadding)
            }
            .paperBackground()
            .navigationTitle("Field Guide")
            .navigationDestination(for: SpeciesInfo.self) { SpeciesDetailView(species: $0) }
        }
    }

    private var summary: some View {
        SpecimenCard(caption: "Your collection") {
            Text("\(foundIDs.intersection(Set(store.all.map(\.id))).count) of \(store.all.count) species found")
                .font(TFFont.heading(.title3))
                .foregroundStyle(Color.tfInk)
            Text("The guide is still growing. More species are being checked against trusted sources before they're added.")
                .font(TFFont.body(.footnote))
                .foregroundStyle(Color.tfInk.opacity(0.85))
        }
    }

    private var ringRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(store.groups, id: \.self) { group in
                    let members = store.species(in: group)
                    OrderProgressRing(group: group, found: members.filter { foundIDs.contains($0.id) }.count, total: members.count)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
        }
    }

    @ViewBuilder
    private var shelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "To identify", detail: toIdentify.isEmpty ? nil : "\(toIdentify.count)")
            if toIdentify.isEmpty {
                EmptyState(symbol: "questionmark.folder", title: "Nothing here yet",
                           message: "When you're not sure what you've found, it waits on this shelf.")
                    .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
            } else {
                ForEach(toIdentify) { sighting in
                    SpecimenCard { SightingRow(sighting: sighting) }
                }
            }
        }
    }

    @ViewBuilder
    private var otherFinds: some View {
        let groupOnly = sightings.filter { if case .order = $0.taxon { return true } else { return false } }
        if !groupOnly.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Group-level finds", detail: "\(groupOnly.count)")
                ForEach(groupOnly) { sighting in
                    SpecimenCard { SightingRow(sighting: sighting) }
                }
            }
        }
    }
}

struct SpeciesTile: View {
    let species: SpeciesInfo
    let found: Bool

    var body: some View {
        SpecimenCard(catalogueNumber: species.catalogueNumber) {
            SilhouetteView(group: species.group, tint: found ? .tfMoss : Color.tfInk.opacity(0.35))
                .frame(height: 64)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 2) {
                Text(species.commonName).font(TFFont.body(.subheadline).weight(.semibold)).foregroundStyle(Color.tfInk)
                Text(found ? "Found" : "Not found yet")
                    .font(TFFont.label(.caption))
                    .foregroundStyle(found ? Color.tfMoss : Color.tfInk.opacity(0.75))
            }
            if !species.verified { UnverifiedTag() }
        }
        .frame(minHeight: TFLayout.minTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Number \(species.catalogueNumber), \(species.commonName), \(found ? "found" : "not found yet")\(species.verified ? "" : ", unverified")")
    }
}

struct SpeciesDetailView: View {
    let species: SpeciesInfo
    @Query(sort: \Sighting.loggedAt, order: .reverse) private var sightings: [Sighting]

    private var mine: [Sighting] { sightings.filter { $0.speciesID == species.id } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SpecimenCard(catalogueNumber: species.catalogueNumber, caption: mine.isEmpty ? "Not found yet" : "Found") {
                    SilhouetteView(group: species.group)
                        .frame(height: 110)
                        .frame(maxWidth: .infinity)
                    Text(species.commonName).font(TFFont.heading(.title)).foregroundStyle(Color.tfInk)
                    Text(species.scientificName).font(TFFont.body()).italic().foregroundStyle(Color.tfInk.opacity(0.85))
                    HStack(spacing: 6) {
                        if !species.verified { UnverifiedTag() }
                        Tag(text: "Find difficulty: \(species.findDifficulty.rawValue)", symbol: "binoculars")
                    }
                    if !species.verified {
                        Text("We haven't finished checking the facts for this species, so some details are blank.")
                            .font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.85))
                    }
                }

                if let note = species.safetyNote { SafetyBanner(message: note) }

                SpecimenCard(caption: "Field notes") {
                    fact("Order", species.order)
                    fact("Family", species.family)
                    fact("Habitat", species.habitat)
                    fact("Best season", species.bestSeason.map { $0 == .both ? "Wet and dry" : $0.rawValue.capitalized })
                    if let fun = species.funFact {
                        Text(fun).font(TFFont.body()).foregroundStyle(Color.tfInk)
                    }
                    Divider()
                    Text("Traditional knowledge: to be added with community guidance")
                        .font(TFFont.body(.footnote)).italic().foregroundStyle(Color.tfInk.opacity(0.85))
                    if let source = species.sourceURL, let url = URL(string: source) {
                        Link(destination: url) {
                            Label("Source", systemImage: "link")
                                .font(TFFont.body(.footnote))
                                .frame(minHeight: TFLayout.minTarget, alignment: .leading)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Your sightings", detail: mine.isEmpty ? nil : "\(mine.count)")
                    if mine.isEmpty {
                        EmptyState(symbol: "camera.viewfinder", title: "Not found yet",
                                   message: "Spot one from a safe distance and photograph it.")
                            .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
                    } else {
                        ForEach(mine) { sighting in SpecimenCard { SightingRow(sighting: sighting) } }
                    }
                }
            }
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
        .navigationTitle(species.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func fact(_ label: String, _ value: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(TFFont.label(.subheadline)).foregroundStyle(Color.tfInk.opacity(0.8))
            Spacer()
            Text(value ?? "Not yet checked")
                .font(TFFont.body(.subheadline))
                .foregroundStyle(Color.tfInk.opacity(value == nil ? 0.6 : 1))
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
