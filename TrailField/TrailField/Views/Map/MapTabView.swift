import MapKit
import SwiftData
import SwiftUI
import TrailCore

struct MapTabView: View {
    @Environment(SpeciesStore.self) private var store
    @Query(sort: \Sighting.loggedAt, order: .reverse) private var sightings: [Sighting]
    @State private var selected: Sighting?
    @State private var position: MapCameraPosition = .region(Self.topEnd)

    /// Darwin and the Top End.
    private static let topEnd = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -12.9, longitude: 131.5),
        span: MKCoordinateSpan(latitudeDelta: 3.2, longitudeDelta: 3.2)
    )

    private var pinned: [Sighting] { sightings.filter { $0.coordinate != nil } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $position) {
                    ForEach(pinned) { sighting in
                        if let c = sighting.coordinate {
                            let center = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
                            MapCircle(center: center, radius: LocationPrivacy.displayRadiusMetres(sensitive: sighting.isSensitive))
                                .foregroundStyle(Color.tfMoss.opacity(0.18))
                                .stroke(Color.tfMoss, lineWidth: 1)
                            Annotation(store.title(for: sighting.taxon), coordinate: center, anchor: .bottom) {
                                Button { selected = sighting } label: {
                                    SilhouetteView(group: store.group(for: sighting.taxon), tint: .tfPaper)
                                        .padding(7)
                                        .frame(width: 44, height: 44)
                                        .background(Color.tfMoss, in: Circle())
                                        .overlay(Circle().stroke(Color.tfPaper, lineWidth: 2))
                                }
                                .accessibilityLabel("\(store.title(for: sighting.taxon)), approximate location")
                            }
                        }
                    }
                }
                .mapControls { MapScaleView() }

                VStack(spacing: 8) {
                    if pinned.isEmpty {
                        EmptyState(symbol: "mappin.slash", title: "No pins yet",
                                   message: "Finds with a location appear here. Turn on demo mode in Settings to preview.")
                            .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
                    }
                    Label("Locations are rounded to about 1 km. Rare species are hidden further.", systemImage: "eye.slash")
                        .font(TFFont.body(.caption))
                        .foregroundStyle(Color.tfInk)
                        .padding(8)
                        .background(Color.tfCard, in: Capsule())
                        .overlay(Capsule().stroke(Color.tfInk.opacity(0.28), lineWidth: 0.5))
                }
                .padding(TFLayout.screenPadding)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selected) { sighting in
                SightingSheet(sighting: sighting)
                    .presentationDetents([.medium])
            }
        }
    }
}

struct SightingSheet: View {
    let sighting: Sighting
    @Environment(SpeciesStore.self) private var store

    private var species: SpeciesInfo? { sighting.speciesID.flatMap { store.species(id: $0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SpecimenCard(catalogueNumber: species?.catalogueNumber, caption: sighting.isDemo ? "Demo" : "Sighting") {
                    SightingRow(sighting: sighting)
                    if let species {
                        Text(species.scientificName).font(TFFont.body(.subheadline)).italic().foregroundStyle(Color.tfInk.opacity(0.85))
                        if !species.verified { UnverifiedTag() }
                    }
                    Label(sighting.isSensitive ? "Location hidden to about 11 km" : "Location rounded to about 1 km",
                          systemImage: "mappin.and.ellipse")
                        .font(TFFont.body(.footnote))
                        .foregroundStyle(Color.tfInk)
                }
                if let note = species?.safetyNote { SafetyBanner(message: note) }
            }
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
    }
}
