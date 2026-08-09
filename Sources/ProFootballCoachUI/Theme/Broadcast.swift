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
/// Tinted rather than filled by default. The filled variant put white on a raw colour and was the
/// worst contrast in the app; here `filled` is opt-in and takes a colour dark enough for it.
public struct Stamp: View {
    let text: String
    var color: Color
    var filled: Bool

    public init(_ text: String, color: Color = .accentColor, filled: Bool = false) {
        self.text = text
        self.color = color
        self.filled = filled
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
