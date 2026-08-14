import SwiftUI

public enum CoachWorldTokens {
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
        public static let minimumTarget: CGFloat = 44
        public static let broadcastRadius: CGFloat = 0

        /// The asymmetric cut radii of `04` §6.3, clockwise from top-leading.
        ///
        /// A panel reads as a deliberate shape rather than a default card because its four radii
        /// differ. `RoundedRectangle` cannot express this, which is why `CutCorner` exists.
        public struct Cut: Sendable, Equatable {
            public let topLeading: CGFloat
            public let topTrailing: CGFloat
            public let bottomTrailing: CGFloat
            public let bottomLeading: CGFloat

            public init(
                _ topLeading: CGFloat,
                _ topTrailing: CGFloat,
                _ bottomTrailing: CGFloat,
                _ bottomLeading: CGFloat
            ) {
                self.topLeading = topLeading
                self.topTrailing = topTrailing
                self.bottomTrailing = bottomTrailing
                self.bottomLeading = bottomLeading
            }
        }

        /// Any surface holding content.
        public static let panelCut = Cut(4, 22, 4, 22)
        /// Table rows, chips and free-standing rows.
        public static let rowCut = Cut(3, 14, 3, 14)
        /// The committing control — soft on three corners, cut on the last.
        public static let actionCut = Cut(22, 22, 22, 5)
        /// A run of continuous table rows is one surface; cutting each row turns a table into a
        /// stack of cards, so continuous rows and BROADCAST furniture stay square (`04` §6.3).
        public static let squareCut = Cut(0, 0, 0, 0)
    }

    /// Depth, as `04` §6.1 permits it: real elevation, never decorative shadow.
    ///
    /// `04` §6.1 forbids "decorative shadow" and "depth that is not real depth". A panel held above
    /// a world casts a shadow because it is genuinely above it; nothing else in the system does.
    public enum Elevation {
        public static let panelShadowRadius: CGFloat = 22
        public static let panelShadowOffsetY: CGFloat = 18
        public static let panelShadowOpacity: Double = 0.85

        /// At most two material panels are live per screen — the dominant object's and one
        /// secondary region's. `04` §6.1 states the budget; a screen wanting a third has a
        /// composition problem, not a performance problem. Stacked `.ultraThinMaterial` over a
        /// 3D-transformed plane is the heaviest thing the system draws, and P13's 16.7 ms ceiling
        /// is still unmeasured.
        public static let materialPanelBudget = 2
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

        public static let authoredFloor: CGFloat = 12
        public static let workingProse: CGFloat = 13

        /// The micro-label's floor. `04` §6.2 moves Floodlit's 9 pt `Label3` to 10 pt: below the
        /// Caption floor and below `04b` §8's authored-type check. Its tracking is kept, because an
        /// uppercase micro-label is read as a shape rather than as words.
        public static let microLabel: CGFloat = 10
        /// Tracking as a fraction of size, for those uppercase micro-labels only.
        public static let microLabelTracking: Double = 0.2

        // MARK: Faces
        //
        // These take a size because the sizes that matter here are *computed* — a gauge's figure
        // scales with its own diameter, so it cannot come from a fixed ramp. Where a size is
        // authored rather than derived, the call site wraps it in `@ScaledMetric` against the role
        // it belongs to, per `04` §6.2. A bare literal passed here is a defect.

        /// Condensed display — headlines, scores, names, section titles. `04` §6.2 mandates
        /// condensed for Display, Title and Headline.
        public static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight).width(.condensed)
        }

        /// Condensed display for figures that must not jitter as they change.
        public static func displayFigures(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight).width(.condensed).monospacedDigit()
        }

        /// Ordinary interface text — standard width, because condensing working prose buys density
        /// at the cost of reading comfort (`04` §6.2).
        public static func text(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        /// Figures in a column.
        public static func figures(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight).monospacedDigit()
        }
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

    /// Floodlit, dark — `04` §6.1. Values move with canon or the token-sync suite fails, so the two
    /// are edited together and never across a phase boundary.
    public static let dark = Palette(
        page: .init(hex: 0x060A12), work: .init(hex: 0x141A26), raised: .init(hex: 0x1E2735),
        contentPrimary: .init(hex: 0xF6FAFF), contentSecondary: .init(hex: 0xA9BACE),
        contentQuiet: .init(hex: 0x8496AC), actionPrimary: .init(hex: 0xFFC53D),
        actionSecondary: .init(hex: 0xA9BACE),
        actionDestructive: .init(hex: 0xFF8E9C), stateLive: .init(hex: 0xFF8E9C),
        statePositive: .init(hex: 0x7DF0B6), stateWarning: .init(hex: 0xFFB03A),
        stateNegative: .init(hex: 0xFF8E9C), stateInfo: .init(hex: 0x9CC8EE),
        collegeIdentity: .init(hex: 0xC79AE4), proIdentity: .init(hex: 0x9CC8EE),
        fieldTurf: .init(hex: 0x1C6E42), fieldLine: .init(hex: 0xF5F7FA),
        fieldAnnotation: .init(hex: 0xFFC53D), fieldLive: .init(hex: 0xC6F24E)
    )

    /// Floodlit, light — the same places by day, not an inversion of the night values.
    public static let light = Palette(
        page: .init(hex: 0xEDF1F6), work: .init(hex: 0xFAFBFD), raised: .init(hex: 0xDCE3EC),
        contentPrimary: .init(hex: 0x0B111C), contentSecondary: .init(hex: 0x414B5C),
        contentQuiet: .init(hex: 0x566274), actionPrimary: .init(hex: 0x7A5200),
        actionSecondary: .init(hex: 0x414B5C),
        actionDestructive: .init(hex: 0xA3202F), stateLive: .init(hex: 0xA3202F),
        statePositive: .init(hex: 0x14653C), stateWarning: .init(hex: 0x704C00),
        stateNegative: .init(hex: 0xA3202F), stateInfo: .init(hex: 0x1E5A8C),
        collegeIdentity: .init(hex: 0x6A3E9C), proIdentity: .init(hex: 0x26608D),
        fieldTurf: .init(hex: 0xD9E7DD), fieldLine: .init(hex: 0x0E1218),
        fieldAnnotation: .init(hex: 0x7A5200), fieldLive: .init(hex: 0x3F6300)
    )

    /// The fills of `04` §6.1's second table. A state fill colours a chip, a rule or an indicator;
    /// the ink of the same name carries text. `#FF3B54` measures 4.30 on dark `raised` — a non-text
    /// value — which is the whole reason the two are separate.
    public struct StateFills: Sendable {
        public let live: ColorValue
        public let positive: ColorValue
        public let warning: ColorValue
        public let info: ColorValue
        public let collegeIdentity: ColorValue
        /// Ink for any filled control or badge: a fill is inked with the ground, never with
        /// `contentPrimary`, which measures 1.51 on the gold fill.
        public let onFill: ColorValue
    }

    public static let darkFills = StateFills(
        live: .init(hex: 0xFF3B54), positive: .init(hex: 0x37E08A),
        warning: .init(hex: 0xFFB03A), info: .init(hex: 0x6FA8DC),
        collegeIdentity: .init(hex: 0xB07BD6), onFill: .init(hex: 0x150F02)
    )

    /// `field.annotation` is a non-text indicator at 3.96 on turf. A *label* on the field takes this
    /// lighter form, which measures 4.90. One gold cannot do both jobs — `04` §6.1.
    public static let fieldLabel = ColorValue(hex: 0xFFE196)

    /// The opaque equivalent of the deep glass panel, and what every panel becomes under Reduce
    /// Transparency. `04` §6.1 specifies α ≥ 0.82 for the fill this flattens — raised from 0.78 on
    /// 2026-08-14, because the original derivation composited bare turf and missed the mown stripe
    /// and the lamp beams above it, where 0.78 left `content.quiet` at 4.23.
    public static let deepPanelOpacity: Double = 0.82

    /// One stop of an atmosphere gradient: a value, the alpha it is laid at, and where it sits.
    ///
    /// The alpha travels with the value because it is half the measurement — `04` §6.1's atmosphere
    /// table states both, and the deep-panel rule is derived against the *composited* ground rather
    /// than the bare stop.
    public struct AtmosphereStop: Sendable, Equatable {
        public let value: ColorValue
        public let alpha: Double
        public let location: Double?

        public init(_ hex: UInt32, alpha: Double = 1, at location: Double? = nil) {
            self.value = ColorValue(hex: hex)
            self.alpha = alpha
            self.location = location
        }

        public var color: Color { value.color.opacity(alpha) }
    }

    /// The worlds of `04` §2, as `04` §6.1's atmosphere table states them.
    ///
    /// **Backdrop, not surface.** Nothing draws text on these; a panel sits over them and the
    /// deep-panel rule governs legibility there. They live here rather than in `WorldBackdrop`
    /// because a colour literal in a view is a defect (§6.1) and because the token-sync suite
    /// requires canon to hold every value the tree ships.
    public enum Atmosphere {
        // Grounds — opaque, three stops each, painted top to bottom.
        public static let pitchGround: [ColorValue] = [
            .init(hex: 0x12203A), .init(hex: 0x060A12), .init(hex: 0x03060B)
        ]
        public static let pitchAfterGround: [ColorValue] = [
            .init(hex: 0x0B1A16), .init(hex: 0x060D10), .init(hex: 0x03060A)
        ]
        public static let facilityGround: [ColorValue] = [
            .init(hex: 0x1A1420), .init(hex: 0x100E16), .init(hex: 0x07060B)
        ]
        public static let deskGround: [ColorValue] = [
            .init(hex: 0x100E16), .init(hex: 0x07060B)
        ]
        public static let filmRoomGround: [ColorValue] = [
            .init(hex: 0x0E1826), .init(hex: 0x070C15), .init(hex: 0x04060B)
        ]

        // Vignettes — the dark that closes each world down at its edges.
        public static let pitchVignette: [AtmosphereStop] = [
            .init(0x080E1A, alpha: 0.34, at: 0.34), .init(0x04080E, alpha: 0.80, at: 0.92)
        ]
        public static let pitchAfterVignette: [AtmosphereStop] = [
            .init(0x050A0E, alpha: 0.86, at: 0.05), .init(0x081216, alpha: 0.30, at: 0.34),
            .init(0x03060A, alpha: 0.88, at: 0.94)
        ]
        public static let deskVignette: [AtmosphereStop] = [
            .init(0x07060C, alpha: 0.82, at: 0.30), .init(0x0A0810, alpha: 0.60, at: 0.52),
            .init(0x030307, alpha: 0.94, at: 0.96)
        ]
        public static let facilityVignette: [AtmosphereStop] = [
            .init(0x08060D, alpha: 0.55, at: 0.26), .init(0x0C0912, alpha: 0.12, at: 0.46),
            .init(0x040308, alpha: 0.86, at: 0.94)
        ]

        // Facility furniture.
        public static let facilityFloor: [ColorValue] = [
            .init(hex: 0x1A1421), .init(hex: 0x0C0912), .init(hex: 0x05040A)
        ]
        public static let windowBand: [ColorValue] = [
            .init(hex: 0x0A1322), .init(hex: 0x0B1626), .init(hex: 0x080D18)
        ]
        public static let stadiumGlow: [AtmosphereStop] = [
            .init(0x78FFBE, alpha: 0.28), .init(0x50C896, alpha: 0.07)
        ]
        public static let stadiumLightBar = AtmosphereStop(0xB4FFDC, alpha: 0.66)
        public static let mullion = AtmosphereStop(0x06050A, alpha: 0.9)

        // Film room.
        public static let projectorThrow: [AtmosphereStop] = [
            .init(0xB0D6FF, alpha: 0.20, at: 0), .init(0xB0D6FF, alpha: 0.02, at: 0.62)
        ]
        public static let dustMote = AtmosphereStop(0xC8E1FF, alpha: 0.5)

        /// The pitch's overhead lamps. This is the brightest ground any panel sits over, and the
        /// value the deep-panel floor in `04` §6.1 is derived against.
        public static let lamp = AtmosphereStop(0xFFF2CE, alpha: 0.55)

        // The turf plane, centre outward. `turf` is `field.turf`, the role `04` §6.1 measures the
        // field grammar against; the other two are the plane's own falloff.
        public static let turfHot = ColorValue(hex: 0x37A868)
        public static let turf = ColorValue(hex: 0x1C6E42)
        public static let turfDeep = ColorValue(hex: 0x072616)

        /// The mown band: white at 0.055, twelve bands across the field. `04` §6.1 fixes the count
        /// at twelve, not the prototype's twenty, so the gauge stays a ten-yard read.
        public static let mownBand = AtmosphereStop(0xFFFFFF, alpha: 0.055)
        public static let mownBandCount = 12

        /// The `AttributeDial` core, which carries the one number summarising its ring.
        /// Composited over the worst deep panel it resolves to `#0F141A` — `content.primary` 17.65.
        public static let dialCore = AtmosphereStop(0x060B14, alpha: 0.72)

        /// The lower stop of the display gradient. This one **is** text: `04` §6.2 measures a
        /// gradient fill at its worst stop, and this is it — 8.12 / 7.14 / 6.16 on page / work /
        /// raised, 5.85 over the worst lamp-lit ground.
        public static let displayGradientFoot = ColorValue(hex: 0x93A8C0)

        /// Film grain, in overlay blend above everything. Dropped under Reduce Transparency
        /// (`04` §7) — it carries no information, so removing it costs only texture.
        public static let grainOpacity: Double = 0.5

        /// The warm overhead pools on the facility floor, and the sheen between them.
        public static let lampWarm = ColorValue(hex: 0xFFCE6A)
        public static let floorSheen = AtmosphereStop(0xFFFFFF, alpha: 0.035)

        /// Softness on each light source. These are blur radii rather than corner radii, and they
        /// are stated here because `ContractTests` reads `radius:` as a design-token position —
        /// correctly, since a blur that varies by call site is a value nobody can review.
        public enum Blur {
            public static let stadiumGlow: CGFloat = 9
            public static let stadiumBar: CGFloat = 1
            public static let lampBeam: CGFloat = 7
            public static let projector: CGFloat = 16
            public static let dustMote: CGFloat = 0.4
        }
    }

    /// Glass, as `04` §6.1 states it. The standard fill cannot carry prose over a lit world; the
    /// deep fill can, at `deepPanelOpacity` or above.
    public enum Glass {
        public static let standardFill = AtmosphereStop(0xFFFFFF, alpha: 0.055)
        public static let deepFill = AtmosphereStop(0x08070E, alpha: deepPanelOpacity)
        /// The 1 pt edge that makes a pane read as glass rather than a hole. Structural, per §6.1:
        /// it carries no meaning and never substitutes for the legible seam.
        public static let edge = AtmosphereStop(0xFFFFFF, alpha: 0.13)
        public static let sheen = AtmosphereStop(0xFFFFFF, alpha: 0.10)
        public static let track = AtmosphereStop(0xFFFFFF, alpha: 0.08)
        public static let structuralRule = AtmosphereStop(0xFFFFFF, alpha: 0.045)
    }
}
