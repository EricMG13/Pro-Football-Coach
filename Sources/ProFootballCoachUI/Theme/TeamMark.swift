import SwiftUI
import FootballSimCore

/// A franchise's logo, drawn rather than shipped.
///
/// `PRODUCT.md` forbids image assets, so every mark is composed from the two colours the team
/// already carries: the primary fills the field, the secondary cuts the motif. Which motif a club
/// gets is derived from its abbreviation, so it is stable for the life of the franchise, survives
/// a save, and needs no table to maintain — and a custom league invented later gets a mark for
/// free.
///
/// Until now `secondaryHex` was loaded on every team and never drawn anywhere.
public struct TeamMark: View {
    public enum Motif: Int, CaseIterable, Sendable {
        case chevron, bar, wedge, ring, diagonal, star, arch

        /// Stable per club: the same abbreviation always yields the same mark.
        public static func forAbbreviation(_ abbreviation: String) -> Motif {
            let seed = abbreviation.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
            return Motif(rawValue: seed % Motif.allCases.count) ?? .chevron
        }
    }

    let abbreviation: String
    let primaryHex: String
    let secondaryHex: String
    var size: CGFloat
    /// Below this the motif is noise, so the mark falls back to the lettermark alone.
    private var showsMotif: Bool { size >= 30 }

    public init(
        abbreviation: String,
        primaryHex: String,
        secondaryHex: String,
        size: CGFloat = 34
    ) {
        self.abbreviation = abbreviation
        self.primaryHex = primaryHex
        self.secondaryHex = secondaryHex
        self.size = size
    }

    public init(team: Team, size: CGFloat = 34) {
        self.init(
            abbreviation: team.abbreviation,
            primaryHex: team.colors.primaryHex,
            secondaryHex: team.colors.secondaryHex,
            size: size
        )
    }

    private var primary: Color { Color(hex: primaryHex) }
    private var secondary: Color { Color(hex: Self.legibleMotif(secondaryHex, on: primaryHex)) }

    /// Pushes a club's second colour away from its first until the motif is actually visible.
    ///
    /// Two colours can differ in hue and still share a luminance — San Francisco's grey-blue
    /// field and red trim measure 1.02:1, so the mark would read as a plain disc. This lifts or
    /// deepens the trim, whichever direction has room, and leaves a colour that already works
    /// exactly as the club chose it. Doing it here rather than editing the table means a league
    /// invented later is covered too.
    public static func legibleMotif(_ hex: String, on field: String, minimum: Double = 1.6) -> String {
        guard TeamTheme.contrastRatio(hex, field) < minimum else { return hex }

        let fieldIsDark = TeamTheme.contrastRatio(field, "#FFFFFF") > TeamTheme.contrastRatio(field, "#000000")
        let target = fieldIsDark ? "#FFFFFF" : "#000000"

        var candidate = hex
        var mix = 0.0
        while mix <= 0.9, TeamTheme.contrastRatio(candidate, field) < minimum {
            mix += 0.05
            candidate = blend(hex, toward: target, amount: mix)
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

    public var body: some View {
        ZStack {
            Circle().fill(primary)

            if showsMotif {
                motif
                    .fill(secondary)
                    .opacity(0.9)
                    .clipShape(Circle())
            }

            Text(abbreviation)
                .font(.system(size: size * 0.30, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, size * 0.08)
                .shadow(color: primary.opacity(0.9), radius: 0.5)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// Each motif is one closed path in a unit square, scaled to the mark.
    private var motif: some Shape {
        MotifShape(kind: Motif.forAbbreviation(abbreviation))
    }
}

/// The seven marks, drawn in a 0…1 space so one shape serves every size.
struct MotifShape: Shape {
    let kind: TeamMark.Motif

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        switch kind {
        case .chevron:
            path.move(to: CGPoint(x: 0, y: h * 0.62))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.28))
            path.addLine(to: CGPoint(x: w, y: h * 0.62))
            path.addLine(to: CGPoint(x: w, y: h * 0.82))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.48))
            path.addLine(to: CGPoint(x: 0, y: h * 0.82))
            path.closeSubpath()

        case .bar:
            path.addRect(CGRect(x: 0, y: h * 0.60, width: w, height: h * 0.13))
            path.addRect(CGRect(x: 0, y: h * 0.80, width: w, height: h * 0.07))

        case .wedge:
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w, y: h * 0.34))
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()

        case .ring:
            path.addEllipse(in: CGRect(x: w * 0.14, y: h * 0.14, width: w * 0.72, height: h * 0.72))
            path.addEllipse(in: CGRect(x: w * 0.26, y: h * 0.26, width: w * 0.48, height: h * 0.48))

        case .diagonal:
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w * 0.62, y: 0))
            path.addLine(to: CGPoint(x: w, y: 0))
            path.addLine(to: CGPoint(x: w * 0.38, y: h))
            path.closeSubpath()

        case .star:
            let centre = CGPoint(x: w / 2, y: h / 2)
            let outer = min(w, h) * 0.46
            let inner = outer * 0.42
            for index in 0..<10 {
                let radius = index.isMultiple(of: 2) ? outer : inner
                let angle = (Double(index) * .pi / 5) - .pi / 2
                let point = CGPoint(
                    x: centre.x + CGFloat(cos(angle)) * radius,
                    y: centre.y + CGFloat(sin(angle)) * radius
                )
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()

        case .arch:
            path.move(to: CGPoint(x: w * 0.10, y: h))
            path.addLine(to: CGPoint(x: w * 0.10, y: h * 0.52))
            path.addQuadCurve(
                to: CGPoint(x: w * 0.90, y: h * 0.52),
                control: CGPoint(x: w * 0.5, y: h * 0.02)
            )
            path.addLine(to: CGPoint(x: w * 0.90, y: h))
            path.addLine(to: CGPoint(x: w * 0.74, y: h))
            path.addLine(to: CGPoint(x: w * 0.74, y: h * 0.56))
            path.addQuadCurve(
                to: CGPoint(x: w * 0.26, y: h * 0.56),
                control: CGPoint(x: w * 0.5, y: h * 0.24)
            )
            path.addLine(to: CGPoint(x: w * 0.26, y: h))
            path.closeSubpath()
        }

        return path
    }
}
