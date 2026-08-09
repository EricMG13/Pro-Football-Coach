import SwiftUI

/// The Almanac — the visual world of the record book this franchise writes about itself.
///
/// Grounds are hexes rather than semantic system colours because paper *is* the identity:
/// `systemGroupedBackground` is a neutral grey and cannot express it. Leaving the semantic set
/// costs the automatic light/dark adaptation, so every value here is paid for with a test —
/// `AlmanacTests` measures each one against every surface it is drawn on, in both themes.
///
/// Day is paper. Night keeps the true black and `#1C1C1E` card the team-tint suite already
/// verifies for all 32 franchises, so the night edition inherits that work untouched.
public enum Almanac {

    // MARK: Grounds

    public static let pageLight = "#F2EFE8"
    public static let pageDark = "#000000"
    public static let cardLight = "#FBF8F2"
    public static let cardDark = "#1C1C1E"

    /// Warm near-black by day, warm off-white by night. Never pure black or pure white — paper
    /// has a temperature, and pure values read as a different material.
    public static let inkLight = "#1A1714"
    public static let inkDark = "#F5F2EC"

    /// The printed hairline. Decorative, so it is exempt from the 4.5:1 text rule, but it must
    /// stay visible against its ground.
    public static let ruleLight = "#D9D3C7"
    public static let ruleDark = "#3A3A3C"

    public static var page: Color { Color(light: pageLight, dark: pageDark) }
    public static var card: Color { Color(light: cardLight, dark: cardDark) }
    public static var ink: Color { Color(light: inkLight, dark: inkDark) }
    public static var rule: Color { Color(light: ruleLight, dark: ruleDark) }

    /// Secondary ink for supporting copy. Still clears AA — the audit found `.tertiary` used as
    /// real informational text at 2.11:1, and this is the token that replaces that habit.
    public static let mutedLight = "#5B5347"
    public static let mutedDark = "#A9A296"
    public static var muted: Color { Color(light: mutedLight, dark: mutedDark) }
}

// MARK: - Voice

/// New York carries the record; SF carries the chrome; figures are tabular so columns never dance.
///
/// Text styles only — every role scales with Dynamic Type for free, which is what makes the
/// almanac's display moments safe at XXXL where the old hard-coded 44pt was not.
public extension Font {
    /// Mastheads and edition plates.
    static var almanacDisplay: Font { .system(.largeTitle, design: .serif, weight: .bold) }
    /// Player names, record lines, chapter heads.
    static var almanacTitle: Font { .system(.title2, design: .serif, weight: .semibold) }
    /// Running record prose.
    static var almanacBody: Font { .system(.body, design: .serif) }
    /// Table heads and section chrome.
    static var almanacLabel: Font { .caption.weight(.semibold) }
    /// Any figure that changes between rows or ticks.
    static var almanacFigure: Font { .system(.title3).monospacedDigit() }
}

// MARK: - Components

/// A printed rule. The Almanac separates with rules, not by wrapping everything in a card.
public struct Rule: View {
    public enum Weight { case hair, heavy }

    let weight: Weight

    public init(_ weight: Weight = .hair) { self.weight = weight }

    public var body: some View {
        Rectangle()
            .fill(weight == .hair ? Almanac.rule : Almanac.ink)
            .frame(height: weight == .hair ? 0.5 : 1.5)
            .accessibilityHidden(true)
    }
}

/// A small printed mark for one piece of metadata — the `Chip`'s successor.
///
/// Squared rather than capsule, outlined rather than filled. The fill was the audit's single
/// worst contrast offender (`Chip(filled:)` hard-coded white, measuring as low as 1.41:1); an
/// outline keeps the label at full ink on its own ground, so it cannot fail.
public struct Stamp: View {
    let text: String
    var color: Color

    public init(_ text: String, color: Color = Almanac.ink) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.almanacLabel)
            .tracking(0.6)
            .padding(.horizontal, Layout.tight)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 0.8)
            )
    }
}

/// One line of the ledger: a label on the left, a figure on the right, baselines aligned so a
/// column of them reads as a column.
public struct LedgerRow<Trailing: View>: View {
    let label: String
    let trailing: Trailing

    public init(_ label: String, @ViewBuilder trailing: () -> Trailing) {
        self.label = label
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.small) {
            Text(label).font(.almanacBody)
            Spacer(minLength: Layout.small)
            trailing.font(.almanacFigure)
        }
        .padding(.vertical, Layout.tight)
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
    ///
    /// Exists as a modifier rather than a convention because the audit found Reduce Motion
    /// honoured in exactly zero places across the whole UI layer, against a commitment written
    /// down in both `PRODUCT.md` and `DESIGN.md`. A token cannot be forgotten the way a habit can.
    func motionAware<V: Equatable>(_ animation: Animation = .snappy, value: V) -> some View {
        modifier(MotionAware(animation: animation, value: value))
    }
}
