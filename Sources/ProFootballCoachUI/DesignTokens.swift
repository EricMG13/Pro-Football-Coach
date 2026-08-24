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
    /// floor: the content column starts at the leading inset and runs to the trailing gutter, and
    /// the header spans that same column.
    ///
    /// **The 44 pt icon rail was removed on 2026-08-23** (`04` section 6.1c). Navigation lives
    /// entirely in the identity band — family on the left, jump-to on the right — so a column of
    /// glyphs beside it was a second navigation for the same set of places. Removing it
    /// generalises the exception the section already carried: Title, Job Board and Offer started
    /// at the rail-free leading edge because they sit outside the coaching week, and every
    /// management surface now uses that geometry. The content column gains 52 pt.
    public enum Stage {
        public static let contentLeading: CGFloat = Frame.leadingInset
        public static let contentTop: CGFloat = 46
        public static let headerTop: CGFloat = 3
        public static let headerPrimaryRow: CGFloat = 22
        public static let headerSecondaryRow: CGFloat = 16
        /// `844 - 63 - 20`: the frame minus the leading inset and the trailing gutter. Derived,
        /// not chosen, so it stays right if the floor ever moves.
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

    /// The handoff's motion contract, canonical at `04` section 6.7. One easing curve, five
    /// durations, and press is a dimming rather than a scale.
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
        /// Press dims rather than scales, so a committing action never shrinks under the thumb
        /// that is committing with it.
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

        // `04` section 6.4, amended 2026-08-22: five bands diverging around a neutral centre, not
        // the three this shipped until 2026-08-23. Two defects went with the three-band form, and
        // the second is the serious one. An ordinary starter at 74 read as a caution. And the
        // middle band was the warning colour, which sat 6.1 degrees from gold — so every average
        // rating in every dense table was spending the commit colour.
        //
        // The centre is deliberately ink rather than a colour: average is not a state, and
        // colouring it makes the whole table look like a verdict.
        public static let wellBelowCeiling = 59
        public static let belowCeiling = 69
        public static let averageCeiling = 79
        public static let aboveCeiling = 84
        /// Retained under its old name because call sites read it as "where warm stops": the floor
        /// of the neutral centre.
        public static let steadyFloor = 70
        public static let strongFloor = 85

        public static func color(for rating: Int, palette: Palette) -> Color {
            switch rating {
            case ...wellBelowCeiling: palette.stateNegative.color
            case ...belowCeiling: palette.stateWarning.color
            case ...averageCeiling: palette.contentSecondary.color
            case ...aboveCeiling: palette.statePositiveLight.color
            default: palette.statePositive.color
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
        public static let hero: CGFloat = 66
        public static let name: CGFloat = 60
        public static let score: CGFloat = 54
        public static let situation: CGFloat = 52
        public static let scoreLive: CGFloat = 40
        public static let figure: CGFloat = 34
        public static let screen: CGFloat = 25
        public static let title: CGFloat = 20
        /// The subject line of an opened message: the handoff's inbox reading pane.
        public static let subject: CGFloat = 22
        public static let clock: CGFloat = 19
        public static let lead: CGFloat = 17
        public static let panel: CGFloat = 16
        public static let row: CGFloat = 15
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
        /// `CoachWorldSystemState`'s orienting mark — one step above the 20 pt Display floor
        /// (04 section 6.2) because it stands alone above a whole composition, not beside text.
        public static let systemStateMarkSize: CGFloat = 28
    }

    public enum Depth {
        public static let glassPanelOpacity = 0.56
        public static let deepPanelOpacity = 0.82
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
        /// `04` section 6.1a. The heat scale's fourth band — `state.positive` lightened, stated as
        /// a measured value so no view has to invent the lightening.
        public let statePositiveLight: ColorValue
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
        statePositive: .init(hex: 0x4FD08C), statePositiveLight: .init(hex: 0x7FCB9E),
        // 0xFFB03A until 2026-08-23: 6.1 degrees from gold at the same saturation, so a caution and
        // a commit were the same colour under a thumb at 11 pt. 0xC9704A is 24.1 degrees off and
        // clears 4.5:1 on all three grounds (`04` section 6.1a).
        stateWarning: .init(hex: 0xC9704A),
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
    /// Translucent surfacing (`04` section 6.1a, added 2026-08-23).
    ///
    /// **Every value here is a pigment at an alpha, never an independent colour**, and that is the
    /// whole reason this exists. A view that writes `Color.white.opacity(0.07)` has hard-coded
    /// `contentPrimary` and will not follow when it moves — and a hex scan never sees it, because
    /// it is not a hex. That is a coverage boundary mistaken for a quality boundary, and it is how
    /// the design standard's own components accumulated 75 hard-coded colours while its colour
    /// rule read PASS.
    ///
    /// Named by **job**, not by opacity: a wash lifts a surface off its ground, a recess pushes one
    /// behind. Reach for the nearest step rather than adding one — the point of a scale is that it
    /// runs out.
    public enum Surfacing {
        /// A surface lifted off its ground. `contentPrimary` at an alpha.
        public enum Wash: Double, Sendable, CaseIterable {
            case faintest = 0.01
            case faint = 0.07
            case soft = 0.10
            case clear = 0.13
            case strong = 0.20
        }

        /// A surface pushed behind. `page` at an alpha.
        public enum Recess: Double, Sendable, CaseIterable {
            case light = 0.34
            case deep = 0.70
        }

        /// Selection and focus on a working surface. `raised` at an alpha — **never gold and never
        /// the club accent**. Gold means the committing action; a club accent means a different
        /// thing per save, and a generated secondary can itself be gold-adjacent (the placeholder
        /// club's is `#F2D864`), which is why position in a table is marked in ink.
        public enum Select: Double, Sendable, CaseIterable {
            case faint = 0.30
            case soft = 0.72
            case strong = 0.82
        }

        /// An opaque-enough working plate. Deliberately `0.96` and not `1.0`: it is what lets a
        /// plate read as solid while a trace of the world still reaches through it, which is the
        /// rule that every screen still happens somewhere.
        public static let plateAlpha = 0.96

        public static func wash(_ step: Wash, palette: Palette) -> Color {
            palette.contentPrimary.color.opacity(step.rawValue)
        }

        public static func recess(_ step: Recess, palette: Palette) -> Color {
            palette.page.color.opacity(step.rawValue)
        }

        public static func select(_ step: Select, palette: Palette) -> Color {
            palette.raised.color.opacity(step.rawValue)
        }

        public static func plate(deep: Bool = false) -> Color {
            (deep ? Floodlit.glassFlatDeep : Floodlit.glassFlat).color.opacity(plateAlpha)
        }
    }

    /// The hairline family (`04` section 6.1a, added 2026-08-23).
    ///
    /// Two jobs, five values. A **structural** rule groups and is nearly invisible; a **legible**
    /// seam is meant to be seen. Neither carries meaning on its own — a hairline that encodes a
    /// value is a datum drawn as furniture.
    ///
    /// **The Increase Contrast branch lives here rather than in a paragraph.** `04` section 7: the
    /// hairlines step up and the material drops, and the inks deliberately do not move, because
    /// every ink already clears 4.5:1 on all four grounds and lightening passing ink only flattens
    /// the three-step hierarchy that tells a reader what is a figure and what is a label.
    public enum Rule: Sendable, CaseIterable {
        case structural
        case legible
        case strong
        /// The seam on a glass panel. Under Reduce Transparency it becomes `legible`: the world is
        /// what the glass was floating above, and with no blur to separate them a near-invisible
        /// seam leaves the panel with no edge at all.
        case glass
        case row

        /// `contentPrimary` for the two that sit on glass, `contentQuiet` for the three that group.
        var base: KeyPath<Palette, ColorValue> {
            switch self {
            case .structural, .legible, .strong: \Palette.contentQuiet
            case .glass, .row: \Palette.contentPrimary
            }
        }

        var standardAlpha: Double {
            switch self {
            case .structural: 0.20
            case .legible: 0.38
            case .strong: 0.42
            case .glass: 0.13
            case .row: 0.14
            }
        }

        var increasedAlpha: Double {
            switch self {
            case .structural: 0.38
            case .legible: 0.62
            case .strong: 0.72
            case .glass: 0.62   // = legible, stepped up
            case .row: 0.26
            }
        }

        public func color(
            palette: Palette,
            contrast: ColorSchemeContrast = .standard,
            reduceTransparency: Bool = false
        ) -> Color {
            if self == .glass && reduceTransparency && contrast != .increased {
                return Rule.legible.color(palette: palette, contrast: contrast)
            }
            let alpha = contrast == .increased ? increasedAlpha : standardAlpha
            return palette[keyPath: base].color.opacity(alpha)
        }
    }

    /// Banner grounds (`04` section 6.1a, added 2026-08-23) — three grounds the four-ground palette
    /// does not cover.
    ///
    /// **Kept as measured values rather than derived from the state roles**, which is the one place
    /// the read-a-role rule is broken on purpose. The only contrast figures anyone has for a banner
    /// were measured on *these* stops: `contentSecondary` at 8.49 / 5.71 / 7.56, `contentQuiet` at
    /// 4.77 / **3.21** / 4.25. A ground mixed from `statePositive` would be a different green and
    /// would invalidate them with nothing saying so — so moving a stop forces a re-measure.
    ///
    /// **Only `contentPrimary` and `contentSecondary` are legal on any of them.** `contentQuiet`
    /// fails on two of the three.
    public enum Banner: Sendable, CaseIterable {
        case info
        case good
        case bad

        public var from: Color { Self.stop(fromHex, alpha: 0.97) }
        public var to: Color { Self.stop(toHex, alpha: 0.97) }
        public var edge: Color { Self.stop(edgeHex, alpha: edgeAlpha) }

        private var fromHex: UInt32 {
            switch self {
            case .info: 0x12203A
            case .good: 0x0F5637
            case .bad: 0x4A1420
            }
        }

        private var toHex: UInt32 {
            switch self {
            case .info: 0x0B0D14
            case .good: 0x091410
            case .bad: 0x110A0E
            }
        }

        private var edgeHex: UInt32 {
            switch self {
            case .info: 0x7A8A9E
            case .good: 0x4FD08C
            case .bad: 0xFF3B54
            }
        }

        private var edgeAlpha: Double {
            switch self {
            case .info: 0.42
            case .good: 0.50
            case .bad: 0.45
            }
        }

        private static func stop(_ hex: UInt32, alpha: Double) -> Color {
            ColorValue(hex: hex).color.opacity(alpha)
        }
    }

    /// The singletons that had no home (`04` section 6.1a, added 2026-08-23).
    public enum Ink {
        /// Ink on any filled control is the ground, never white. Measured on each fill: gold 12.55,
        /// live 11.50, positive 10.13, warning 10.87, info 7.84, negative 5.67. **One token, no
        /// per-fill exceptions** — a per-fill ink is how one control ends up unreadable.
        public static func onFill(palette: Palette) -> Color { palette.page.color }
        /// The verb on a commit.
        public static var onGold: Color { Floodlit.goldInk.color }
        /// The sub-label naming where the commit goes. Same ink, stepped back.
        public static var onGoldQuiet: Color { Floodlit.goldInk.color.opacity(0.74) }
        /// An unobserved rating, printed as the word `Unseen` — never a blank, a dash or a zero.
        /// **Not a range**: uncertainty in this product is stated in words, per `04` section 6.4.
        public static func unseen(palette: Palette) -> Color {
            palette.contentQuiet.color.opacity(0.62)
        }
    }

    /// The fade on a strip with more content than room — the band's sibling tabs.
    ///
    /// **Applied only when the strip actually overruns.** An always-on fade claims a truncation that
    /// is not happening, which is the same defect as a caret that opens nothing.
    public enum Mask {
        public static let trailingInset: CGFloat = 16
        public static func trailing(width: CGFloat) -> LinearGradient {
            let stop = width > trailingInset ? (width - trailingInset) / width : 0
            return LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: stop),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

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
