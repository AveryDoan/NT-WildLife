import SwiftUI
import TrailCore

/// Original silhouettes, one per browsing group, drawn from simple shapes.
/// Facing up inside a unit square. Not copied from any existing artwork.
struct InsectSilhouette: Shape {
    let group: SpeciesGroup

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let s = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - s / 2, y: rect.midY - s / 2)

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * s, y: origin.y + y * s) }
        func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, angle: Double = 0) {
            let box = CGRect(x: -rx * s, y: -ry * s, width: 2 * rx * s, height: 2 * ry * s)
            var e = Path(ellipseIn: box)
            e = e.applying(CGAffineTransform(rotationAngle: CGFloat(angle * .pi / 180)))
            e = e.applying(CGAffineTransform(translationX: pt(cx, cy).x, y: pt(cx, cy).y))
            path.addPath(e)
        }
        func bar(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, width: CGFloat = 0.035) {
            let a = pt(x1, y1), b = pt(x2, y2)
            let dx = b.x - a.x, dy = b.y - a.y
            let len = max((dx * dx + dy * dy).squareRoot(), 0.001)
            let nx = -dy / len * width * s / 2, ny = dx / len * width * s / 2
            path.move(to: CGPoint(x: a.x + nx, y: a.y + ny))
            path.addLine(to: CGPoint(x: b.x + nx, y: b.y + ny))
            path.addLine(to: CGPoint(x: b.x - nx, y: b.y - ny))
            path.addLine(to: CGPoint(x: a.x - nx, y: a.y - ny))
            path.closeSubpath()
        }
        /// Draws a shape and its left-right mirror.
        func mirrored(_ draw: (CGFloat) -> Void) {
            draw(1)
            draw(-1)
        }
        func mx(_ x: CGFloat, _ side: CGFloat) -> CGFloat { 0.5 + (x - 0.5) * side }

        func sixLegs(topY: CGFloat, spread: CGFloat = 0.34) {
            mirrored { side in
                bar(mx(0.45, side), topY, mx(0.5 - spread, side), topY - 0.08)
                bar(mx(0.45, side), topY + 0.1, mx(0.5 - spread - 0.03, side), topY + 0.12)
                bar(mx(0.45, side), topY + 0.2, mx(0.5 - spread, side), topY + 0.3)
            }
        }
        func antennae(y: CGFloat = 0.17) {
            mirrored { side in bar(mx(0.47, side), y, mx(0.38, side), y - 0.12, width: 0.022) }
        }

        switch group {
        case .beetles:
            ellipse(0.5, 0.6, 0.23, 0.29)
            ellipse(0.5, 0.25, 0.1, 0.08)
            sixLegs(topY: 0.45)
            antennae(y: 0.2)
        case .butterfliesAndMoths:
            mirrored { side in
                ellipse(mx(0.27, side), 0.36, 0.22, 0.17, angle: Double(-25 * side))
                ellipse(mx(0.3, side), 0.66, 0.15, 0.13, angle: Double(20 * side))
            }
            ellipse(0.5, 0.52, 0.035, 0.24)
            ellipse(0.5, 0.26, 0.05, 0.05)
            mirrored { side in bar(mx(0.49, side), 0.24, mx(0.4, side), 0.08, width: 0.02) }
        case .ants:
            ellipse(0.5, 0.2, 0.08, 0.08)
            ellipse(0.5, 0.4, 0.06, 0.09)
            ellipse(0.5, 0.7, 0.12, 0.17)
            sixLegs(topY: 0.34, spread: 0.36)
            antennae(y: 0.17)
        case .termites:
            ellipse(0.5, 0.2, 0.09, 0.09)
            ellipse(0.5, 0.62, 0.14, 0.3)
            sixLegs(topY: 0.38, spread: 0.3)
            antennae(y: 0.18)
        case .beesAndWasps:
            mirrored { side in ellipse(mx(0.26, side), 0.32, 0.18, 0.07, angle: Double(-28 * side)) }
            ellipse(0.5, 0.2, 0.08, 0.07)
            ellipse(0.5, 0.38, 0.12, 0.1)
            ellipse(0.5, 0.67, 0.1, 0.19)
            sixLegs(topY: 0.4, spread: 0.3)
            antennae(y: 0.16)
        case .grasshoppers:
            ellipse(0.5, 0.5, 0.075, 0.3)
            ellipse(0.5, 0.17, 0.09, 0.08)
            mirrored { side in
                bar(mx(0.45, side), 0.62, mx(0.2, side), 0.5, width: 0.045)
                bar(mx(0.2, side), 0.5, mx(0.17, side), 0.9, width: 0.03)
                bar(mx(0.46, side), 0.32, mx(0.3, side), 0.4)
                bar(mx(0.46, side), 0.42, mx(0.33, side), 0.6)
                bar(mx(0.47, side), 0.17, mx(0.38, side), 0.04, width: 0.02)
            }
        case .bugs:
            var shield = Path()
            shield.move(to: pt(0.5, 0.3))
            shield.addCurve(to: pt(0.74, 0.5), control1: pt(0.66, 0.3), control2: pt(0.74, 0.38))
            shield.addCurve(to: pt(0.5, 0.88), control1: pt(0.74, 0.7), control2: pt(0.6, 0.84))
            shield.addCurve(to: pt(0.26, 0.5), control1: pt(0.4, 0.84), control2: pt(0.26, 0.7))
            shield.addCurve(to: pt(0.5, 0.3), control1: pt(0.26, 0.38), control2: pt(0.34, 0.3))
            path.addPath(shield)
            ellipse(0.5, 0.22, 0.08, 0.08)
            sixLegs(topY: 0.42, spread: 0.36)
            antennae(y: 0.18)
        case .dragonflies:
            ellipse(0.5, 0.55, 0.03, 0.34)
            ellipse(0.5, 0.17, 0.06, 0.06)
            mirrored { side in
                ellipse(mx(0.25, side), 0.3, 0.25, 0.05, angle: Double(8 * side))
                ellipse(mx(0.25, side), 0.42, 0.24, 0.05, angle: Double(-6 * side))
            }
        case .flies:
            mirrored { side in ellipse(mx(0.28, side), 0.62, 0.12, 0.26, angle: Double(-25 * side)) }
            ellipse(0.5, 0.6, 0.14, 0.2)
            ellipse(0.5, 0.3, 0.11, 0.1)
            sixLegs(topY: 0.48, spread: 0.3)
        case .other:
            ellipse(0.5, 0.62, 0.15, 0.24)
            ellipse(0.5, 0.28, 0.09, 0.09)
            sixLegs(topY: 0.46, spread: 0.32)
            antennae(y: 0.22)
        }
        return path
    }
}

/// Silhouette with a sensible accessibility label.
struct SilhouetteView: View {
    let group: SpeciesGroup
    var tint: Color = .tfMoss

    var body: some View {
        InsectSilhouette(group: group)
            .fill(tint)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}
