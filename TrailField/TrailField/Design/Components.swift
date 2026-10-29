import SwiftUI
import TrailCore

// MARK: - SpecimenCard

/// A museum-drawer style card: thin border, catalogue number in the corner.
struct SpecimenCard<Content: View>: View {
    var catalogueNumber: Int?
    var caption: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if catalogueNumber != nil || caption != nil {
                HStack {
                    if let catalogueNumber {
                        Text(String(format: "No. %03d", catalogueNumber))
                            .font(.system(.caption, design: .serif, weight: .semibold))
                            .foregroundStyle(Color.tfMoss)
                    }
                    Spacer()
                    if let caption {
                        Text(caption.uppercased())
                            .font(TFFont.label(.caption2))
                            .tracking(0.8)
                            .foregroundStyle(Color.tfInk.opacity(0.75))
                    }
                }
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: TFLayout.cornerRadius).stroke(Color.tfInk.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - Chips and tags

struct PointsChip: View {
    let points: Int

    var body: some View {
        Text("+\(points) pts")
            .font(TFFont.label(.subheadline))
            .monospacedDigit()
            .foregroundStyle(Color.tfOnOchre)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.tfOchre, in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(points) points")
    }
}

struct Tag: View {
    let text: String
    var symbol: String?
    var fill: Color = .tfWater

    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol).imageScale(.small).accessibilityHidden(true) }
            Text(text)
        }
        .font(TFFont.label(.caption))
        .foregroundStyle(Color.tfInk)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(fill, in: Capsule())
        .overlay(Capsule().stroke(Color.tfInk.opacity(0.25), lineWidth: 0.5))
    }
}

struct UnverifiedTag: View {
    var body: some View {
        Tag(text: "Unverified", symbol: "questionmark.circle")
            .accessibilityLabel("Unverified. Facts for this species have not been fully checked yet.")
    }
}

/// Anything that is not the player's own real data must wear one of these.
struct SampleTag: View {
    enum Kind: String { case demo = "Demo", samplePlayer = "Sample player" }
    let kind: Kind

    var body: some View {
        Tag(text: kind.rawValue, symbol: "theatermasks", fill: .tfSage)
    }
}

// MARK: - Progress, badges, confidence

struct OrderProgressRing: View {
    let group: SpeciesGroup
    let found: Int
    let total: Int

    private var progress: Double { total == 0 ? 0 : Double(found) / Double(total) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Color.tfSage, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.tfMoss, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                SilhouetteView(group: group, tint: found > 0 ? .tfMoss : Color.tfInk.opacity(0.45))
                    .padding(16)
            }
            .frame(width: 64, height: 64)
            Text("\(found)/\(total)")
                .font(TFFont.label(.caption))
                .monospacedDigit()
                .foregroundStyle(Color.tfInk)
        }
        .frame(minWidth: TFLayout.minTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.displayName): \(found) of \(total) found")
    }
}

struct BadgeView: View {
    let title: String
    let symbol: String
    let detail: String
    let earned: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: earned ? symbol : "lock.fill")
                .font(.title2)
                .foregroundStyle(earned ? Color.tfOnOchre : Color.tfInk.opacity(0.7))
                .frame(width: 52, height: 52)
                .background(earned ? Color.tfOchre : Color.tfSage, in: Circle())
                .overlay(Circle().stroke(Color.tfInk.opacity(0.25), lineWidth: 0.5))
            Text(title)
                .font(TFFont.label(.caption))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tfInk)
        }
        .frame(minWidth: 72, minHeight: TFLayout.minTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) badge, \(earned ? "earned" : "not yet earned"). \(detail)")
    }
}

struct ConfidenceBar: View {
    /// 0...1
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Confidence")
                Spacer()
                Text("\(Int((value * 100).rounded()))%").monospacedDigit()
            }
            .font(TFFont.label(.caption))
            .foregroundStyle(Color.tfInk)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.tfSage)
                    Capsule().fill(Color.tfMoss).frame(width: max(6, proxy.size.width * min(max(value, 0), 1)))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence \(Int((value * 100).rounded())) percent")
    }
}

// MARK: - Banners and empty states

struct SafetyBanner: View {
    var title = "Look, don't touch"
    let rawMessage: String

    init(title: String = "Look, don't touch", message: String) {
        self.title = title
        self.rawMessage = message
    }

    /// Species notes start with "Look, don't touch." which the title already says.
    private var message: String {
        let prefix = "\(title). "
        return rawMessage.hasPrefix(prefix) ? String(rawMessage.dropFirst(prefix.count)) : rawMessage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(Color.tfClay)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(TFFont.heading(.subheadline)).foregroundStyle(Color.tfInk)
                Text(message).font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.tfCard, in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: TFLayout.cornerRadius).stroke(Color.tfClay, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Safety. \(title). \(message)")
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(Color.tfMoss)
                .accessibilityHidden(true)
            Text(title).font(TFFont.heading(.headline)).foregroundStyle(Color.tfInk)
            Text(message)
                .font(TFFont.body(.subheadline))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tfInk.opacity(0.85))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct SectionHeader: View {
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(TFFont.heading(.title3)).foregroundStyle(Color.tfInk)
            Spacer()
            if let detail {
                Text(detail).font(TFFont.body(.footnote)).foregroundStyle(Color.tfInk.opacity(0.8))
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}
