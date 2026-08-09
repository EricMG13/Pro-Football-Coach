import SwiftUI
import FootballSimCore

/// Spacing, radius and type tokens. Everything visual references these rather than literals,
/// so the whole app can be re-proportioned from one file.
public enum Layout {
    public static let tight: CGFloat = 6
    public static let small: CGFloat = 10
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let cardRadius: CGFloat = 20
    public static let chipRadius: CGFloat = 10
    public static let rowHeight: CGFloat = 52
}

public extension Color {
    /// Resolves to a different hex per theme. Two fixed colours rather than one with an opacity
    /// adjustment, because no single hue clears 4.5:1 against both a white card and a near-black
    /// one — the light and dark ends of a band have to be picked independently.
    init(light: String, dark: String) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
        #else
        self.init(hex: light)
        #endif
    }

    /// Builds a colour from a `#RRGGBB` string, falling back to grey on anything unparseable.
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            self = .gray
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// The colour identity of the team the user is coaching. Injected through the environment so
/// every screen re-themes when a coach changes jobs.
public struct TeamTheme: Sendable {
    public let primary: Color
    public let secondary: Color
    /// The colour controls are tinted with. Same identity as `primary` on a light background,
    /// lightened on a dark one: a bordered button draws its label in the tint over a faint wash
    /// of the same tint, so a navy or maroon team turns its own buttons into dark-on-dark.
    public let tint: Color

    public init(primary: Color, secondary: Color, tint: Color? = nil) {
        self.primary = primary
        self.secondary = secondary
        self.tint = tint ?? primary
    }

    public init(colors: TeamColors) {
        self.init(
            primary: Color(hex: colors.primaryHex),
            secondary: Color(hex: colors.secondaryHex),
            tint: Color(
                light: colors.primaryHex,
                dark: TeamTheme.legibleOnDark(colors.primaryHex)
            )
        )
    }

    /// Lifts a hex toward white until it clears 4.5:1 against the dark surface it is drawn on.
    /// Returns the input untouched when it already does.
    ///
    /// The default is the grouped card, not the page: cards are lighter than the page in dark
    /// mode, so they are the harder target, and they are where the buttons actually sit. The
    /// wash a bordered button paints behind its own label is lighter still, which is why the
    /// lift is measured against the composited surface rather than the bare card.
    public static func legibleOnDark(_ hex: String, background: String = darkCard) -> String {
        var mix = 0.0
        var candidate = hex
        while mix <= 0.95, contrastRatio(candidate, surface(for: candidate, over: background)) < 4.5 {
            mix += 0.05
            candidate = blend(hex, toward: "#FFFFFF", amount: mix)
        }
        return candidate
    }

    /// The app's dark surfaces, matching `systemGroupedBackground` and its secondary.
    public static let darkCard = "#1C1C1E"
    public static let darkPage = "#000000"
    /// How much of the tint a `.bordered` button paints behind its own label.
    public static let controlWashAlpha = 0.15

    /// What a tinted label is really drawn on: its own colour, washed over the card.
    public static func surface(for tint: String, over background: String) -> String {
        blend(background, toward: tint, amount: controlWashAlpha)
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

    /// WCAG 2.2 §1.4.3, kept here so the palette can check itself without a test target.
    public static func contrastRatio(_ a: String, _ b: String) -> Double {
        func luminance(_ hex: String) -> Double {
            let linear = channels(hex).map {
                $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        }
        let (high, low) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (high + 0.05) / (low + 0.05)
    }

    /// Neutral identity used before a team has been chosen.
    public static let neutral = TeamTheme(primary: .accentColor, secondary: .secondary)

    public var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, primary.opacity(0.75), .black.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct TeamThemeKey: EnvironmentKey {
    static let defaultValue = TeamTheme.neutral
}

public extension EnvironmentValues {
    var teamTheme: TeamTheme {
        get { self[TeamThemeKey.self] }
        set { self[TeamThemeKey.self] = newValue }
    }
}

/// Rating bands, shared by every screen that shows an overall so the same number always reads
/// the same way.
///
/// The colours are hand-picked rather than SwiftUI system colours. `.green` and `.orange` as
/// text on a white card measure 2.2:1 — less than half the 4.5:1 the project commits to, and
/// the worst contrast in the app. Every hex below is verified against the card, the page and
/// the 14 % `Chip` tint in both themes by `DesignSystemTests`; change one and the test says so.
///
/// Clearing 4.5:1 on white forces all five bands dark, which leaves them near-isoluminant —
/// hue ends up doing all the visual work. The rating itself is always drawn alongside, and
/// `label` carries the band to VoiceOver, so the tier is never colour-only.
public enum RatingTier: String, CaseIterable, Sendable {
    case elite, star, starter, rotational, fringe

    public init(rating: Int) {
        self = switch rating {
        case 90...: .elite
        case 84..<90: .star
        case 74..<84: .starter
        case 64..<74: .rotational
        default: .fringe
        }
    }

    /// Spoken after the rating by VoiceOver. Deliberately not a letter grade — the player card
    /// already shows Potential as A+…F and a second letter scale would read as the same scale.
    public var label: String {
        switch self {
        case .elite: "elite"
        case .star: "star"
        case .starter: "starter"
        case .rotational: "rotational"
        case .fringe: "fringe"
        }
    }

    public var lightHex: String {
        switch self {
        case .elite: "#6B4BC4"
        case .star: "#155CB0"
        case .starter: "#22661F"
        case .rotational: "#8A5000"
        case .fringe: "#AB2A1E"
        }
    }

    public var darkHex: String {
        switch self {
        case .elite: "#C3A6FF"
        case .star: "#6BB3FF"
        case .starter: "#67D77A"
        case .rotational: "#F5A93C"
        case .fringe: "#FF8A80"
        }
    }

    public var color: Color { Color(light: lightHex, dark: darkHex) }
}

/// The three things an openness indicator can say, and the two palettes it says them in.
///
/// Two palettes because the indicator is drawn on two very different grounds: over dark turf,
/// where it can be bright and saturated, and as text on a card, where `.green` measures 2.2:1
/// and is the exact failure `RatingTier` above exists to avoid. The text hexes are the tier
/// hexes for that reason — already verified against card, page and chip tint in both themes.
///
/// Colour is never the only channel. The field draws a solid ring for open, a broken ring for
/// contested and a thin one for covered, and `label` carries the state to VoiceOver.
public enum OpennessTier: String, CaseIterable, Sendable {
    case open, contested, covered

    public init(_ state: OpennessState) {
        self = switch state {
        case .open: .open
        case .contested: .contested
        case .covered: .covered
        }
    }

    public var label: String {
        switch self {
        case .open: "open"
        case .contested: "contested"
        case .covered: "covered"
        }
    }

    public var lightHex: String {
        switch self {
        case .open: "#22661F"
        case .contested: "#8A5000"
        case .covered: "#AB2A1E"
        }
    }

    public var darkHex: String {
        switch self {
        case .open: "#67D77A"
        case .contested: "#F5A93C"
        case .covered: "#FF8A80"
        }
    }

    /// For text and chips, where the ground is a card or the page.
    public var textColor: Color { Color(light: lightHex, dark: darkHex) }

    /// For the ring drawn over turf, which is dark in both themes and takes the bright end.
    ///
    /// Reds are the awkward case: 4.5:1 against turf needs a relative luminance around 0.55, and
    /// no saturated red gets near it — pure red manages 2.0:1. So "covered" is a light salmon
    /// rather than the red the eye expects, and the thin ring it is drawn as does the rest of
    /// the work. All three sit near 5:1 rather than on the 4.5 line, so a small palette tweak
    /// cannot silently drop one under it.
    public var fieldHex: String {
        switch self {
        case .open: "#5BE889"
        case .contested: "#FFD166"
        case .covered: "#FFB8C4"
        }
    }

    public var fieldColor: Color { Color(hex: fieldHex) }

    /// The turf both themes draw, and what the field palette is verified against.
    public static let turfHex = "#225C31"
}

public enum RatingPalette {
    public static func tier(for rating: Int) -> RatingTier { RatingTier(rating: rating) }

    public static func tier(for rating: Double) -> RatingTier {
        RatingTier(rating: Int(rating.rounded()))
    }

    public static func color(for rating: Int) -> Color { tier(for: rating).color }

    public static func color(for rating: Double) -> Color { tier(for: rating).color }
}

public extension View {
    /// Tints a displayed rating and tells VoiceOver which band it falls in. The colour is a
    /// scanning aid; the spoken tier is what makes the band available without it.
    ///
    /// Set as an accessibility *value* rather than a label so the visible text — which may be a
    /// scouted range ("68–84") or a one-decimal average — is still what gets read first.
    func ratingStyle(_ rating: Int) -> some View {
        foregroundStyle(RatingPalette.color(for: rating))
            .accessibilityValue(RatingTier(rating: rating).label)
    }

    func ratingStyle(_ rating: Double) -> some View { ratingStyle(Int(rating.rounded())) }
}

/// A white rounded card — the app's primary container.
public struct CardBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(Layout.medium)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                    .fill(Color.cardFill)
            )
    }
}

public extension Color {
    /// Card surface that adapts to light and dark without hard-coding either.
    static var cardFill: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemGroupedBackground)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    static var pageBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #else
        Color.gray.opacity(0.06)
        #endif
    }
}

public extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// A small pill used for every piece of metadata in the app: week numbers, positions,
/// home and away, contract years.
public struct Chip: View {
    let text: String
    var color: Color = .secondary
    var filled = false

    public init(_ text: String, color: Color = .secondary, filled: Bool = false) {
        self.text = text
        self.color = color
        self.filled = filled
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, Layout.small)
            .padding(.vertical, 4)
            .foregroundStyle(filled ? Color.white : color)
            .background(
                Capsule().fill(filled ? color : color.opacity(0.14))
            )
    }
}

/// Section header with an optional trailing accessory.
public struct SectionHeader<Accessory: View>: View {
    let title: String
    let accessory: Accessory

    public init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            accessory
        }
    }
}

public extension SectionHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

/// Empty state shown wherever a list has nothing in it yet.
public struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    public init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: Layout.small) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.large)
    }
}

/// Formatting helpers shared across screens.
public enum Format {
    public static func money(_ amount: Int) -> String { NewsEngine.money(amount) }

    public static func signedMoney(_ amount: Int) -> String {
        amount < 0 ? "-\(money(-amount))" : money(amount)
    }

    public static func rating(_ value: Double) -> String { String(format: "%.1f", value) }

    public static func percent(_ value: Double) -> String { String(format: "%.1f%%", value) }

    public static func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// "6' 2\"" from inches.
    public static func height(_ inches: Int) -> String { "\(inches / 12)' \(inches % 12)\"" }
}
