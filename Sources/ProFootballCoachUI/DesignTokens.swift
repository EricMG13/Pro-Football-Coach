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
}
