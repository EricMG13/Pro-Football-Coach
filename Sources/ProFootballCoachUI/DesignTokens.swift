import SwiftUI

public enum CoachWorldTokens {
    /// The design-handoff frame, `04` section 6.1b.
    ///
    /// The handoff draws Match Day on a 932 x 430 mock and Floodlit Surfaces on the real install
    /// floor. Every offset here is the re-derived 844 x 390 one, so no call site repeats the
    /// arithmetic: leading furniture clears the sensor housing, the bottom band clears the home
    /// indicator, and the trailing gutter is the handoff's own.
    public enum Frame {
        public static let floorWidth: CGFloat = 844
        public static let floorHeight: CGFloat = 390
        public static let sensorHousing: CGFloat = 59
        public static let homeIndicator: CGFloat = 21
        public static let gutter: CGFloat = 20
        /// Sensor housing plus the handoff's 4 pt clearance.
        public static let leadingInset: CGFloat = 63
        /// Home indicator plus the same 4 pt clearance.
        public static let bottomInset: CGFloat = 25
        public static let topInset: CGFloat = 12
        /// 338 of the 932 mock, held as a proportion so it scales with the frame rather than
        /// being re-measured per device.
        public static let lowerThirdWidthRatio: CGFloat = 338 / 932
    }

    /// The management stage's geometry, `04` section 6.1c. Absolute positions at the install
    /// floor: one navigator and one content column share the sensor-safe leading edge.
    public enum Stage {
        public static let contentLeading: CGFloat = Frame.leadingInset
        public static let headerTop: CGFloat = Frame.topInset
        public static let headerHeight: CGFloat = 34
        public static let contentTop: CGFloat = headerTop + headerHeight + 8
        /// `844 - 63 - 20`: the frame minus the sensor-safe leading edge and trailing gutter.
        public static let contentWidth: CGFloat =
            Frame.floorWidth - contentLeading - Frame.gutter
        /// How far the world backdrop bleeds past the bottom edge.
        public static let worldBottomBleed: CGFloat = 0.55
    }

    /// The handoff's gap ladder, verbatim. It is deliberately not a 4/8 grid — Floodlit tunes gaps
    /// per surface, and snapping them to a grid is what makes a dense screen read as a template.
    public enum Gap {
        public static let hair: CGFloat = 2
        public static let tight: CGFloat = 3
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 7
        public static let smPlus: CGFloat = 8
        public static let md: CGFloat = 9
        public static let mdPlus: CGFloat = 11
        public static let lg: CGFloat = 12
        public static let lgPlus: CGFloat = 14
        public static let xl: CGFloat = 18
        public static let xxl: CGFloat = 20
    }

    /// Per-surface padding, `04` section 6.1b. Each is (vertical, horizontal).
    public enum Pad {
        public static let panel = (v: CGFloat(11), h: CGFloat(15))
        public static let row = (v: CGFloat(10), h: CGFloat(12))
        public static let card = (v: CGFloat(12), h: CGFloat(13))
        public static let alert = (v: CGFloat(11), h: CGFloat(16))
        public static let band = (v: CGFloat(14), h: CGFloat(16))
    }

    /// The handoff's motion contract, canonical at `04` section 6.7. One easing curve and five
    /// durations; contrast-bearing actions keep their fill opaque while pressed.
    public enum Motion {
        public static let press: Double = 0.12
        public static let value: Double = 0.22
        public static let world: Double = 0.42
        /// The panel push-in the staff call-in enters with.
        public static let panelEnter: Double = 0.24
        /// The live-snap dot's cycle length. A period, not a state-change duration — the one row
        /// that repeats rather than resolving once, so it is always paired with
        /// `.repeatForever(autoreverses: true)` rather than used alone.
        public static let pulse: Double = 1.5
        public static let panelPushDistance: CGFloat = 14
        /// Legacy dim amount for contrast-neutral furniture. Team actions keep their field opaque
        /// and use a one-point positional cue so generated colours retain measured contrast.
        public static let pressDim: Double = 0.12
        public static let disabledOpacity: Double = 0.4

        // The curve constructor that turns these durations into an `Animation` lives in
        // `CoachWorldMotion.swift`, not here — this enum is data, per `04` section 6.7; scheduling
        // an animation is behaviour, and `04` section 6.7 names the choke point as the one file
        // permitted that. Splitting them is what makes the containment scan meaningful rather than
        // requiring an exemption on the file that also holds every other view's numbers.
    }

    /// The 40-99 rating scale's three bands. Always a *second* reading of a printed figure — the
    /// colour never replaces the number, per `04` section 4.4.
    public enum Heat {
        public static let scaleFloor = 40
        public static let scaleCeiling = 99
        public static let strongFloor = 85
        public static let steadyFloor = 72

        public static func color(for rating: Int, palette: Palette) -> Color {
            switch rating {
            case strongFloor...: palette.stateLive.color
            case steadyFloor..<strongFloor: palette.actionPrimary.color
            default: palette.stateNegative.color
            }
        }
    }

    /// The handoff's literal type scale, in points.
    ///
    /// Drawn in Archivo Narrow; set here in SF Pro Condensed, which is wider at the same size, so
    /// `04` section 6.2's sizing pass applies to everything below `lead`. The 10.5 and 9 pt values
    /// are permitted for tracked uppercase micro-labels only — never for prose, where section 6.2's
    /// 12 pt authored floor is unchanged.
    public enum DisplaySize {
        public static let hero: CGFloat = 32
        public static let name: CGFloat = 26
        public static let score: CGFloat = 32
        public static let situation: CGFloat = 26
        public static let scoreLive: CGFloat = 32
        public static let figure: CGFloat = 32
        public static let screen: CGFloat = 16
        public static let title: CGFloat = 16
        /// The subject line of an opened message: the handoff's inbox reading pane.
        public static let subject: CGFloat = 16
        public static let clock: CGFloat = 17
        public static let lead: CGFloat = 15
        public static let panel: CGFloat = 16
        public static let row: CGFloat = 13
        public static let action: CGFloat = 14
        public static let actionSmall: CGFloat = 12
        public static let pill: CGFloat = 10.5
        public static let flag: CGFloat = 9

        /// Tracking, as the handoff states it in ems, resolved against a size.
        public static func tracking(_ em: CGFloat, at size: CGFloat) -> CGFloat { em * size }
        public static let labelTracking: CGFloat = 0.2
    }

    /// Display type: SF Pro Condensed, uppercase by convention at the call site.
    public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }

    /// Figures: the system face with tabular digits, so a score or a clock does not reflow as it
    /// counts. The handoff's IBM Plex Mono is a web substitute and is not shipped.
    public static func figure(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }

    public enum Space {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
    }

    public enum Shape {
        public static let hairline: CGFloat = 1
        public static let controlRadius: CGFloat = 8
        public static let rowRadius: CGFloat = 8
        public static let surfaceRadius: CGFloat = 10
        public static let cutCorner: CGFloat = 12
        public static let minimumTarget: CGFloat = 44
        public static let broadcastRadius: CGFloat = 0

        /// `CoachWorldRatingRing`'s stroke width as a proportion of its diameter, so the same ring
        /// reads correctly from a 26 pt table cell through a 118 pt hero gauge.
        public static let ringStrokeRatio: CGFloat = 0.12
        /// The floor beneath `ringStrokeRatio` so a small ring's stroke never thins to nothing.
        public static let ringStrokeMinimum: CGFloat = 2
        /// `CoachWorldRatingRing`'s centred figure size as a proportion of its diameter.
        public static let ringTextRatio: CGFloat = 0.42
        /// `CoachWorldSystemState`'s orienting mark sits above the 16 pt screen-title role because
        /// it stands alone above a whole composition, not beside text.
        public static let systemStateMarkSize: CGFloat = 28
    }

    public enum Depth {
        public static let glassPanelOpacity = 0.56
        public static let deepPanelOpacity = 0.82
        public static let glassShadow = (
            alpha: Double(0.28), blur: CGFloat(8), offsetY: CGFloat(4)
        )
        public static let deepShadow = (
            alpha: Double(0.55), blur: CGFloat(18), offsetY: CGFloat(10)
        )
        /// The `content.quiet` panel-border opacity: legible as a seam without reading as a rule.
        public static let panelBorderOpacity = 0.38
    }

    public enum TypeRole {
        public static let display = Font.system(
            .title3, design: .default, weight: .heavy
        ).width(.condensed)
        public static let title = Font.system(
            .headline, design: .default, weight: .heavy
        ).width(.condensed)
        public static let headline = Font.system(
            .subheadline, design: .default, weight: .semibold
        ).width(.condensed)
        public static let body = Font.system(.footnote, design: .default)
        public static let callout = Font.system(.footnote, design: .default)
        public static let caption = Font.system(.caption, design: .default)
        public static let microLabelSize: CGFloat = 10
        public static let microLabelTracking: CGFloat = 0.8
        public static let microLabel = Font.system(
            size: microLabelSize, weight: .bold, design: .default
        ).width(.condensed)

        public static let authoredFloor: CGFloat = 12
        public static let workingProse: CGFloat = 13
    }

    public struct ColorValue: Sendable, Equatable {
        public let red: Double
        public let green: Double
        public let blue: Double

        public init(hex: UInt32) {
            red = Double((hex >> 16) & 0xff) / 255
            green = Double((hex >> 8) & 0xff) / 255
            blue = Double(hex & 0xff) / 255
        }

        public var color: Color {
            Color(red: red, green: green, blue: blue)
        }

        private init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        /// This colour mixed toward another, in linear sRGB components.
        ///
        /// The end zone's fill is stated as "team primary mixed 50% into `#06170f`" — a value the
        /// palette cannot hold, because half of it comes from the save.
        public func mixed(with other: ColorValue, amount: Double) -> ColorValue {
            let t = Swift.min(1, Swift.max(0, amount))
            return ColorValue(
                red: red + (other.red - red) * t,
                green: green + (other.green - green) * t,
                blue: blue + (other.blue - blue) * t
            )
        }
    }

    public struct Palette: Sendable {
        public let page: ColorValue
        public let work: ColorValue
        public let raised: ColorValue
        public let contentPrimary: ColorValue
        public let contentSecondary: ColorValue
        public let contentQuiet: ColorValue
        public let actionPrimary: ColorValue
        public let actionSecondary: ColorValue
        public let actionDestructive: ColorValue
        public let stateLive: ColorValue
        public let statePositive: ColorValue
        public let stateWarning: ColorValue
        public let stateNegative: ColorValue
        public let stateInfo: ColorValue
        public let collegeIdentity: ColorValue
        public let proIdentity: ColorValue
        public let fieldTurf: ColorValue
        public let fieldLine: ColorValue
        public let fieldAnnotation: ColorValue
        public let fieldLive: ColorValue
    }

    /// The single Floodlit palette (`04` section 6.1a, 2026-08-16). Dark-only: there is no
    /// production light palette and no user-facing appearance switch. Role names are unchanged from
    /// the retired v3 palette; only the hex each role resolves to changed, so every call site that
    /// read `.dark` keeps compiling and keeps its meaning.
    public static let dark = Palette(
        page: .init(hex: 0x060A12), work: .init(hex: 0x100E16), raised: .init(hex: 0x12203A),
        contentPrimary: .init(hex: 0xF6FAFF), contentSecondary: .init(hex: 0xA9BACE),
        contentQuiet: .init(hex: 0x7A8A9E), actionPrimary: .init(hex: 0xFFC53D),
        actionSecondary: .init(hex: 0xA9BACE),
        actionDestructive: .init(hex: 0xFF3B54), stateLive: .init(hex: 0x37E08A),
        statePositive: .init(hex: 0x4FD08C), stateWarning: .init(hex: 0xFFB03A),
        stateNegative: .init(hex: 0xFF3B54), stateInfo: .init(hex: 0x6FA8DC),
        collegeIdentity: .init(hex: 0xB07BD6), proIdentity: .init(hex: 0x6FA8DC),
        fieldTurf: .init(hex: 0x072616), fieldLine: .init(hex: 0xF6FAFF),
        fieldAnnotation: .init(hex: 0xFFCE6A), fieldLive: .init(hex: 0x4FD08C)
    )

    /// The Floodlit ramp the 2026-08-18 design handoff ships, over and above `Palette`'s roles
    /// (`04` section 6.1b). These are the hues a role name cannot carry: the turf gradient's five
    /// stops, the gold field's three, the ball's three, and the two club/opponent grounds.
    ///
    /// The handoff's `ink-3` `#65788F` is deliberately absent. It fails 4.5:1 on every ground it is
    /// drawn on; `Palette.contentQuiet` `#7A8A9E` is the same role and ships in its place.
    public enum Floodlit {
        public static let roomDeep = ColorValue(hex: 0x07060B)

        public static let turf = ColorValue(hex: 0x1C6E42)
        public static let turfHot = ColorValue(hex: 0x37A868)
        public static let turfCrown = ColorValue(hex: 0x2A8850)
        public static let turfMid = ColorValue(hex: 0x124E2E)
        public static let turfShade = ColorValue(hex: 0x0A311D)
        public static let turfNight = ColorValue(hex: 0x05150D)

        public static let lamp = ColorValue(hex: 0xFFF2CE)
        public static let goldLight = ColorValue(hex: 0xFFE196)
        public static let goldDeep = ColorValue(hex: 0xD89713)
        public static let goldInk = ColorValue(hex: 0x150F02)

        public static let liveInk = ColorValue(hex: 0xFF8E9C)
        public static let goInk = ColorValue(hex: 0x7DF0B6)
        public static let coolInk = ColorValue(hex: 0x9CC8EE)

        public static let clubField = ColorValue(hex: 0x0F5637)
        public static let clubInk = ColorValue(hex: 0xEAF3EE)
        public static let opponentField = ColorValue(hex: 0x123A5E)
        public static let opponentAccent = ColorValue(hex: 0x9CC5E8)
        public static let opponentInk = ColorValue(hex: 0xC7DEF3)
        public static let endZoneOpponent = ColorValue(hex: 0x1B2431)
        public static let bowlInk = ColorValue(hex: 0xC9A968)

        public static let ballHighlight = ColorValue(hex: 0xA6572A)
        public static let ballMid = ColorValue(hex: 0x7A3E1C)
        public static let ballShade = ColorValue(hex: 0x46220F)

        /// Non-hero glass, flattened (`04` section 6.1c). Blur belongs only where something is
        /// genuinely in front of something else; stacked over a transformed plane it smears, so
        /// panels that are not the hero take a solid fill at the same two depths instead.
        public static let glassFlat = ColorValue(hex: 0x11141E)
        public static let glassFlatDeep = ColorValue(hex: 0x0B0D14)
        /// The registry overlay's ground.
        public static let overlayScrim = ColorValue(hex: 0x04070C)

        /// The committing action's fill, and the only gradient that means "this moves the game
        /// forward". Gold never means "this is good".
        public static let goldField = LinearGradient(
            colors: [goldLight.color, dark.actionPrimary.color, goldDeep.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Glass, as the handoff states it: a fill, a hairline, and a directional sheen. Held as alphas
    /// on white/black rather than as hexes, because that is what they are.
    public enum Glass {
        public static let fill = 0.055
        public static let deep = 0.70
        public static let line = 0.13
        public static let sheen = 0.10
        public static let track = 0.08
        public static let hairline = 0.045
        public static let blurRadius: CGFloat = 24
    }
}
