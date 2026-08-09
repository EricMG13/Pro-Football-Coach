import SwiftUI

/// The Broadcast skin — modern native surfaces, team colour as a header band, chips for metadata.
///
/// Replaces the Almanac's paper-and-serif world. Grounds and text come back to the system
/// semantic set, which is the modern-iOS default and, unlike hand-picked paper, adapts to Dark
/// Mode, Increased Contrast and Reduce Transparency without a hand-maintained table. The one
/// place hexes remain is the rating ladder, where the colour carries meaning and is verified.
public enum Broadcast {

    // MARK: Grounds

    public static var page: Color { Color.pageBackground }
    public static var card: Color { Color.cardFill }

    /// Body and supporting text. Semantic, so contrast is the platform's job.
    public static var ink: Color { .primary }
    public static var muted: Color { .secondary }

    /// Hairline separator.
    public static var rule: Color {
        #if canImport(UIKit)
        Color(uiColor: .separator)
        #else
        Color.gray.opacity(0.3)
        #endif
    }

    /// The wash a chip paints behind its own label. Kept in one place so every chip agrees.
    public static let chipTint = 0.14

    /// Darkens a fill until white on it clears 4.5:1.
    ///
    /// A filled chip takes whatever colour the call site had to hand, and the call sites hand it
    /// `.orange`, `.yellow`, `.green` — which measure as low as 1.4:1 under white. Rather than
    /// audit 36 of them, the component refuses to render an unreadable fill.
    public static func legibleFill(_ hex: String) -> String {
        var candidate = hex
        var mix = 0.0
        while mix <= 0.9, TeamTheme.contrastRatio(candidate, "#FFFFFF") < 4.5 {
            mix += 0.05
            candidate = blend(hex, toward: "#000000", amount: mix)
        }
        return candidate
    }

    private static func channels(_ hex: String) -> [Double] {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let value = UInt32(cleaned, radix: 16) ?? 0
        return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF].map { Double($0) / 255 }
    }

    private static func blend(_ hex: String, toward target: String, amount: Double) -> String {
        let (from, to) = (channels(hex), channels(target))
        let mixed = (0..<3).map { UInt32(((from[$0] * (1 - amount)) + to[$0] * amount) * 255) }
        return String(format: "#%02X%02X%02X", mixed[0], mixed[1], mixed[2])
    }
}

// MARK: - Voice

/// Sans throughout — SF carries both the record and the chrome. Figures are tabular so a column
/// of them never dances. Text styles only, so Dynamic Type works for free.
public extension Font {
    /// Scores, a lone dominant figure, screen titles.
    static var displayFont: Font { .system(.largeTitle, weight: .bold) }
    /// Player names, section heads, row titles.
    static var titleFont: Font { .system(.title3, weight: .semibold) }
    /// Running copy — news, dossier lines, the coordinator's sentence.
    static var bodyFont: Font { .body }
    /// Table heads, chip labels, overlines.
    static var labelFont: Font { .caption.weight(.semibold) }
    /// Any figure that changes between rows or ticks.
    static var figureFont: Font { .system(.title3, weight: .semibold).monospacedDigit() }
}

// MARK: - Components

/// A hairline divider. Rows use `.hair`; section breaks use `.heavy`.
public struct Rule: View {
    public enum Weight { case hair, heavy }

    let weight: Weight

    public init(_ weight: Weight = .hair) { self.weight = weight }

    public var body: some View {
        Rectangle()
            .fill(weight == .hair ? Broadcast.rule : Broadcast.muted.opacity(0.45))
            .frame(height: weight == .hair ? 0.5 : 1)
            .accessibilityHidden(true)
    }
}

/// A chip: one piece of metadata, capsule, label at full strength over a wash of its own colour.
///
/// Tinted by default. `filled` puts white on the colour, which is how the old component reached
/// 1.41:1 — so a filled chip built from a known hex darkens that hex until white clears 4.5:1
/// rather than trusting whatever the call site had to hand.
public struct Stamp: View {
    let text: String
    var color: Color
    var filled: Bool
    /// The fill's own hex, when the caller knows it. Only a hex can be corrected; a semantic
    /// colour like `.secondary` has no fixed value to measure.
    var fillHex: String?

    public init(_ text: String, color: Color = .accentColor, filled: Bool = false) {
        self.text = text
        self.color = color
        self.filled = filled
        self.fillHex = nil
    }

    /// Builds a chip from a known colour, so a filled one can be made legible.
    public init(_ text: String, hex: String, filled: Bool = false) {
        self.text = text
        self.filled = filled
        self.fillHex = hex
        self.color = filled ? Color(hex: Broadcast.legibleFill(hex)) : Color(hex: hex)
    }

    public var body: some View {
        Text(text)
            .font(.labelFont)
            .padding(.horizontal, Layout.small)
            .padding(.vertical, 4)
            .foregroundStyle(filled ? Color.white : color)
            .background(
                Capsule().fill(filled ? color : color.opacity(Broadcast.chipTint))
            )
    }
}

/// A label-and-figure row, baselines aligned so a column of them reads as a column.
public struct LedgerRow<Trailing: View>: View {
    let label: String
    let trailing: Trailing

    public init(_ label: String, @ViewBuilder trailing: () -> Trailing) {
        self.label = label
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.small) {
            Text(label).font(.bodyFont).foregroundStyle(Broadcast.muted)
            Spacer(minLength: Layout.small)
            trailing.font(.figureFont)
        }
        .padding(.vertical, Layout.tight)
    }
}

/// The signature of this skin: a team-colour band above neutral card content.
///
/// One loud element per surface, and only on the surfaces licensed to have it — the band carries
/// the identity so the body underneath can stay calm and legible.
public struct BroadcastBand<Content: View, Body: View>: View {
    @Environment(\.teamTheme) private var theme

    let band: Content
    let content: Body

    public init(@ViewBuilder band: () -> Content, @ViewBuilder content: () -> Body) {
        self.band = band()
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            band
                .padding(.horizontal, Layout.medium)
                .padding(.vertical, Layout.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.primary)

            content
                .padding(Layout.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Broadcast.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }
}

/// Carries the chosen appearance into a sheet.
///
/// `preferredColorScheme` on the root does not reach a sheet: it is presented outside that
/// hierarchy. Applying it where the sheet is presented keeps every one of them honest without
/// each sheet body having to remember.
public struct AppearanceAware: ViewModifier {
    @Environment(AppState.self) private var app

    public func body(content: Content) -> some View {
        content.preferredColorScheme(app.appearance.colorScheme)
    }
}

public extension View {
    func appearanceAware() -> some View { modifier(AppearanceAware()) }
}

// MARK: - Motion

private struct MotionAware<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

public extension View {
    /// Animates unless the reader has asked the system for less motion.
    func motionAware<V: Equatable>(_ animation: Animation = .snappy, value: V) -> some View {
        modifier(MotionAware(animation: animation, value: value))
    }
}
