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

    public init(primary: Color, secondary: Color) {
        self.primary = primary
        self.secondary = secondary
    }

    public init(colors: TeamColors) {
        self.init(primary: Color(hex: colors.primaryHex), secondary: Color(hex: colors.secondaryHex))
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

/// Rating colour bands, shared by every screen that shows an overall so the same number always
/// reads the same way.
public enum RatingPalette {
    public static func color(for rating: Int) -> Color {
        switch rating {
        case 90...: .purple
        case 84..<90: .blue
        case 74..<84: .green
        case 64..<74: .orange
        default: .red
        }
    }

    public static func color(for rating: Double) -> Color { color(for: Int(rating.rounded())) }
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
