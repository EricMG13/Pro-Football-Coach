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
}
