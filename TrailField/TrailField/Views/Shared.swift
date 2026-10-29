import SwiftUI
import TrailCore

/// A sighting's photo, or a silhouette on sage for demo data.
struct SightingThumbnail: View {
    let sighting: Sighting
    var size: CGFloat = 64
    @Environment(SpeciesStore.self) private var store

    var body: some View {
        Group {
            if let data = sighting.photoData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Color.tfSage
                    SilhouetteView(group: store.group(for: sighting.taxon)).padding(size * 0.2)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tfInk.opacity(0.28), lineWidth: 0.5))
        .accessibilityHidden(true)
    }
}

struct SightingRow: View {
    let sighting: Sighting
    @Environment(SpeciesStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            SightingThumbnail(sighting: sighting)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.title(for: sighting.taxon))
                    .font(TFFont.body().weight(.semibold))
                    .foregroundStyle(Color.tfInk)
                Text(sighting.loggedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(TFFont.body(.footnote))
                    .foregroundStyle(Color.tfInk.opacity(0.8))
                HStack(spacing: 6) {
                    if sighting.scored { PointsChip(points: sighting.points) }
                    if sighting.isDemo { SampleTag(kind: .demo) }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: TFLayout.minTarget)
        .accessibilityElement(children: .combine)
    }
}
