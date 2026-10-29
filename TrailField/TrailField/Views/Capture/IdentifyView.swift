import SwiftData
import SwiftUI
import TrailCore

struct IdentifyView: View {
    let draft: CaptureDraft
    let onCancel: () -> Void
    let onSaved: (CaptureFlowView.SaveResult) -> Void

    @Environment(SpeciesStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var sightings: [Sighting]

    private enum Pick: Equatable {
        case species(String)
        case order(InsectOrder)
        case notSure
    }

    @State private var pick: Pick?
    @State private var acceptedSuggestion = false
    @State private var pinOnMap = true
    @State private var isSaving = false
    @State private var locationProvider = LocationProvider()

    private var freshness: PhotoFreshness {
        PhotoFreshness.classify(capturedAt: draft.photo.capturedAt, now: .now)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                photoHeader

                switch draft.faceStatus {
                case .checking:
                    HStack(spacing: 10) {
                        ProgressView().tint(Color.tfMoss)
                        Text("Checking the photo…").font(TFFont.body()).foregroundStyle(Color.tfInk)
                    }
                case .person:
                    blockedMessage(
                        title: "This photo has a person in it",
                        message: "TrailField never saves photos of people. Please choose a photo with just the insect."
                    )
                case .failed:
                    blockedMessage(
                        title: "Couldn't check this photo",
                        message: "We check every photo for people before saving it, and that check didn't work this time. Please try again."
                    )
                case .clear:
                    identifyContent
                }
            }
            .padding(TFLayout.screenPadding)
        }
        .paperBackground()
        .navigationTitle("What is it?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel).frame(minHeight: TFLayout.minTarget)
            }
        }
        #if DEBUG
        .task(id: draft.faceStatus) {
            // `-debugPick magnetic-termite|order:Lepidoptera|notSure` and `-debugSave YES` drive the flow in the simulator.
            guard draft.faceStatus == .clear, let raw = UserDefaults.standard.string(forKey: "debugPick") else { return }
            if raw == "notSure" { pick = .notSure }
            else if raw.hasPrefix("order:"), let o = InsectOrder(scientificName: String(raw.dropFirst(6))) { pick = .order(o) }
            else { pick = .species(raw) }
            if UserDefaults.standard.bool(forKey: "debugSave") { save() }
        }
        #endif
        .safeAreaInset(edge: .bottom) {
            if draft.faceStatus == .clear {
                Button(action: save) {
                    if isSaving {
                        ProgressView().tint(Color.tfPaper)
                    } else {
                        Text(saveTitle)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(pick == nil || isSaving)
                .padding(TFLayout.screenPadding)
                .background(.bar)
            }
        }
    }

    // MARK: Sections

    private var photoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = UIImage(data: draft.photo.jpegData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: TFLayout.cornerRadius).stroke(Color.tfInk.opacity(0.28), lineWidth: 1))
                    .accessibilityLabel("Your photo")
            }
            if draft.faceStatus == .clear {
                freshnessLabel
            }
        }
    }

    private var freshnessLabel: some View {
        let (symbol, text): (String, String) = {
            switch freshness {
            case .recent:
                let when = draft.photo.capturedAt.map {
                    RelativeDateTimeFormatter().localizedString(for: $0, relativeTo: .now)
                } ?? ""
                return ("clock", "Taken \(when). This can earn points.")
            case .stale:
                return ("clock.badge.exclamationmark", "Taken more than 72 hours ago. It will count in your guide only: no points.")
            case .unknown:
                return ("clock.badge.questionmark", "We can't read when this was taken. It will count in your guide only: no points.")
            }
        }()
        return VStack(alignment: .leading, spacing: 2) {
            Label(text, systemImage: symbol)
                .font(TFFont.body(.footnote))
                .foregroundStyle(Color.tfInk)
            Text("Photo time comes from the photo itself, so it is self-reported.")
                .font(TFFont.body(.caption))
                .foregroundStyle(Color.tfInk.opacity(0.75))
        }
    }

    private func blockedMessage(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SpecimenCard {
                Label(title, systemImage: "person.crop.circle.badge.xmark")
                    .font(TFFont.heading(.headline))
                    .foregroundStyle(Color.tfInk)
                Text(message).font(TFFont.body()).foregroundStyle(Color.tfInk)
            }
            Button("Choose another photo", action: onCancel)
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    @ViewBuilder
    private var identifyContent: some View {
        if draft.vision?.looksLikeSpider == true {
            SafetyBanner(
                title: "That might be a spider",
                message: "Spiders aren't insects, and some bite. Keep your distance. You can still log it as \"Not sure\"."
            )
        }
        if let hint = draft.vision?.hint {
            suggestionCard(hint)
        }

        SectionHeader(title: "Pick what you found")
        ForEach(store.groups, id: \.self) { group in
            VStack(alignment: .leading, spacing: 8) {
                Text(group.displayName)
                    .font(TFFont.label(.subheadline))
                    .foregroundStyle(Color.tfMoss)
                    .accessibilityAddTraits(.isHeader)
                ForEach(store.species(in: group)) { species in
                    speciesRow(species)
                }
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("I only know the group")
                .font(TFFont.label(.subheadline))
                .foregroundStyle(Color.tfMoss)
                .accessibilityAddTraits(.isHeader)
            Text("Worth 5 points.")
                .font(TFFont.body(.footnote))
                .foregroundStyle(Color.tfInk.opacity(0.8))
            ForEach(InsectOrder.allCases, id: \.self) { order in
                choiceRow(
                    selected: pick == .order(order),
                    group: order.group,
                    title: order.displayName,
                    subtitle: order.scientificName,
                    italicSubtitle: false
                ) {
                    pick = .order(order)
                    acceptedSuggestion = false
                }
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Can't tell?").font(TFFont.label(.subheadline)).foregroundStyle(Color.tfMoss)
                .accessibilityAddTraits(.isHeader)
            choiceRow(
                selected: pick == .notSure,
                symbol: "questionmark.circle",
                title: "Not sure",
                subtitle: "Saved to your \"To identify\" shelf. No points.",
                italicSubtitle: false
            ) {
                pick = .notSure
                acceptedSuggestion = false
            }
        }

        Toggle(isOn: $pinOnMap) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pin this find on the map").font(TFFont.body()).foregroundStyle(Color.tfInk)
                Text("Only a rounded spot (about 1 km) is saved, never your exact position.")
                    .font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.8))
            }
        }
        .frame(minHeight: TFLayout.minTarget)
        .padding(.bottom, 80)
    }

    private func suggestionCard(_ hint: VisionHint) -> some View {
        SpecimenCard(caption: "Suggestion") {
            Text(hint.order.map { "Might be in: \($0.displayName)" } ?? "Might be an insect")
                .font(TFFont.heading(.headline))
                .foregroundStyle(Color.tfInk)
            Text("Based on the label \"\(hint.label)\" from the phone's built-in photo recogniser. It can be wrong, so you decide.")
                .font(TFFont.body(.footnote))
                .foregroundStyle(Color.tfInk)
            ConfidenceBar(value: hint.confidence)
            if let order = hint.order {
                Button {
                    pick = .order(order)
                    acceptedSuggestion = true
                } label: {
                    Text("Use \"\(order.displayName)\"")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private func speciesRow(_ species: SpeciesInfo) -> some View {
        choiceRow(
            selected: pick == .species(species.id),
            group: species.group,
            title: species.commonName,
            subtitle: species.scientificName,
            italicSubtitle: true,
            unverified: !species.verified
        ) {
            pick = .species(species.id)
            acceptedSuggestion = false
        }
    }

    private func choiceRow(
        selected: Bool,
        group: SpeciesGroup? = nil,
        symbol: String? = nil,
        title: String,
        subtitle: String,
        italicSubtitle: Bool,
        unverified: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if let group {
                        SilhouetteView(group: group, tint: .tfMoss)
                    } else if let symbol {
                        Image(systemName: symbol).font(.title2).foregroundStyle(Color.tfMoss)
                    }
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(TFFont.body().weight(.semibold)).foregroundStyle(Color.tfInk)
                    Text(subtitle)
                        .font(TFFont.body(.footnote))
                        .italic(italicSubtitle)
                        .foregroundStyle(Color.tfInk.opacity(0.8))
                    if unverified { UnverifiedTag() }
                }
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.tfMoss : Color.tfInk.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: TFLayout.minTarget, alignment: .leading)
            .background(selected ? Color.tfSage : Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TFLayout.cornerRadius)
                    .stroke(selected ? Color.tfMoss : Color.tfInk.opacity(0.28), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)\(unverified ? ", unverified" : "")")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    // MARK: Saving

    private var saveTitle: String {
        switch pick {
        case .none: return "Choose one to continue"
        case .notSure: return "Save to \"To identify\""
        default: return "Save to my guide"
        }
    }

    private func choice() -> IdentifyChoice? {
        switch pick {
        case .species(let id):
            guard let species = store.species(id: id) else { return nil }
            return IdentifyChoice(taxon: .species(id: id), species: species, acceptedSuggestion: false)
        case .order(let order):
            return IdentifyChoice(taxon: .order(order.scientificName), species: nil, acceptedSuggestion: acceptedSuggestion)
        case .notSure:
            return IdentifyChoice(taxon: .notSure, species: nil, acceptedSuggestion: false)
        case .none:
            return nil
        }
    }

    private func save() {
        guard let choice = choice(), !isSaving else { return }
        isSaving = true
        Task {
            var coordinate = draft.photo.embeddedLocation
            if pinOnMap {
                if coordinate == nil { coordinate = await locationProvider.currentCoordinate() }
            } else {
                coordinate = nil
            }

            let (sighting, breakdown) = SightingService.save(
                photo: draft.photo,
                faceStatus: draft.faceStatus,
                choice: choice,
                suggestion: draft.vision?.hint,
                coordinate: coordinate,
                history: sightings,
                context: context
            )
            isSaving = false
            onSaved(.init(sighting: sighting, breakdown: breakdown, pinned: sighting?.coordinate != nil))
        }
    }
}
