import CoreGraphics
import Foundation
import TrailCore
import Vision

enum FaceStatus: Equatable {
    case checking, clear, person, failed
}

enum FaceCheck {
    /// Photos with people are refused. If the check itself fails we also refuse (privacy first).
    nonisolated static func check(_ image: CGImage) -> FaceStatus {
        let request = VNDetectFaceRectanglesRequest()
        #if targetEnvironment(simulator)
        request.usesCPUOnly = true
        #endif
        do {
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
            return (request.results ?? []).isEmpty ? .clear : .person
        } catch {
            return .failed
        }
    }
}

/// Tier 1: Vision's built-in classifier, used only as a hint. Always shown as a "Suggestion".
struct VisionHint: Equatable {
    let label: String
    let confidence: Double
    /// `nil` for the generic "insect" label.
    let order: InsectOrder?
}

struct VisionResult: Equatable {
    var hint: VisionHint?
    var looksLikeSpider: Bool
}

enum VisionHintService {
    /// Only labels that exist in Vision's real label list (dumped 29 Oct 2026, see Docs/DATA_SOURCES.md).
    /// There is no beetle, grasshopper, termite, wasp or fly label, so those are never suggested.
    nonisolated static let orderForLabel: [String: InsectOrder?] = [
        "ant": .hymenoptera,
        "bee": .hymenoptera,
        "butterfly": .lepidoptera,
        "moth": .lepidoptera,
        "dragonfly": .odonata,
        "ladybug": .coleoptera,
        "insect": nil,
    ]
    nonisolated static let minimumConfidence = 0.15
    nonisolated static let spiderLabel = "spider"

    nonisolated static func classify(_ image: CGImage) -> VisionResult {
        let request = VNClassifyImageRequest()
        #if targetEnvironment(simulator)
        request.usesCPUOnly = true
        #endif
        guard (try? VNImageRequestHandler(cgImage: image, options: [:]).perform([request])) != nil else {
            return VisionResult(hint: nil, looksLikeSpider: false)
        }
        // Re-check against this device's label list rather than trusting the macOS dump.
        let supported = Set((try? request.supportedIdentifiers()) ?? [])
        let observations = request.results ?? []

        let spider = observations.contains { $0.identifier == spiderLabel && $0.confidence >= 0.3 }

        let candidates = observations
            .filter { orderForLabel.keys.contains($0.identifier) && supported.contains($0.identifier) }
            .filter { Double($0.confidence) >= minimumConfidence }
        // Prefer a specific label over the generic "insect" one.
        let best = candidates.filter { $0.identifier != "insect" }.max { $0.confidence < $1.confidence }
            ?? candidates.max { $0.confidence < $1.confidence }

        guard let best else { return VisionResult(hint: nil, looksLikeSpider: spider) }
        return VisionResult(
            hint: VisionHint(
                label: best.identifier,
                confidence: Double(best.confidence),
                order: orderForLabel[best.identifier] ?? nil
            ),
            looksLikeSpider: spider
        )
    }
}
