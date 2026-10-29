import SwiftUI

/// Colour tokens live in Assets.xcassets (light and dark). Views never use literal colours.
extension Color {
    static let tfPaper = Color(.paper)
    static let tfCard = Color(.card)
    static let tfInk = Color(.ink)
    static let tfMoss = Color(.moss)
    static let tfSage = Color(.sage)
    static let tfOchre = Color(.ochre)
    /// Text on an Ochre fill (Ink in light mode, Paper in dark mode).
    static let tfOnOchre = Color(.onOchre)
    static let tfClay = Color(.clay)
    static let tfWater = Color(.water)
}

/// Contrast rules (checked with WCAG maths, see CLAUDE.md):
/// - Body text is always Ink.
/// - Moss text is fine on Paper, Card, Sage and Water.
/// - Clay is for icons, borders and bold text on Card only. Ochre is a fill, never text.
/// - Text on Moss fills is Paper. Text on Clay fills is Card. Text on Ochre fills is OnOchre.
enum TFFont {
    /// New York serif for headings; scales with Dynamic Type.
    static func heading(_ style: Font.TextStyle = .title2) -> Font {
        .system(style, design: .serif, weight: .semibold)
    }
    /// SF for body copy.
    static func body(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .default)
    }
    static func label(_ style: Font.TextStyle = .caption) -> Font {
        .system(style, design: .default, weight: .semibold)
    }
}

enum TFLayout {
    static let minTarget: CGFloat = 44
    static let cornerRadius: CGFloat = 14
    static let screenPadding: CGFloat = 16
}

struct PaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color.tfPaper.ignoresSafeArea())
    }
}

extension View {
    func paperBackground() -> some View { modifier(PaperBackground()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TFFont.body().weight(.semibold))
            .foregroundStyle(Color.tfPaper)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(Color.tfMoss.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4),
                        in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TFFont.body().weight(.semibold))
            .foregroundStyle(Color.tfMoss)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(Color.tfCard.opacity(configuration.isPressed ? 0.7 : 1),
                        in: RoundedRectangle(cornerRadius: TFLayout.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: TFLayout.cornerRadius).stroke(Color.tfMoss, lineWidth: 1.5))
    }
}
