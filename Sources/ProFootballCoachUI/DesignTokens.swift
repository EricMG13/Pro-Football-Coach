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
        public static let display = Font.title2.weight(.heavy).width(.condensed)
        public static let title = Font.title3.weight(.heavy).width(.condensed)
        public static let headline = Font.headline.weight(.semibold).width(.condensed)
        public static let body = Font.body
        public static let callout = Font.callout
        public static let caption = Font.caption

        public static let authoredFloor: CGFloat = 12
        public static let workingProse: CGFloat = 17
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

    public static let dark = Palette(
        page: .init(hex: 0x080A14), work: .init(hex: 0x111426), raised: .init(hex: 0x191D32),
        contentPrimary: .init(hex: 0xF4F5FA), contentSecondary: .init(hex: 0xB8BDCC),
        contentQuiet: .init(hex: 0x858CA2), actionPrimary: .init(hex: 0x9964E8),
        actionSecondary: .init(hex: 0xB8BDCC),
        actionDestructive: .init(hex: 0xF07886), stateLive: .init(hex: 0x72D7A0),
        statePositive: .init(hex: 0x6FD39A), stateWarning: .init(hex: 0xF0C56C),
        stateNegative: .init(hex: 0xF07886), stateInfo: .init(hex: 0x72ADEC),
        collegeIdentity: .init(hex: 0xA861D6), proIdentity: .init(hex: 0x5B9DE0),
        fieldTurf: .init(hex: 0x163E2A), fieldLine: .init(hex: 0xF5F7FA),
        fieldAnnotation: .init(hex: 0xE7C45D), fieldLive: .init(hex: 0xC6F24E)
    )

    public static let light = Palette(
        page: .init(hex: 0xF1F2F7), work: .init(hex: 0xFBFBFD), raised: .init(hex: 0xE6E8F0),
        contentPrimary: .init(hex: 0x111426), contentSecondary: .init(hex: 0x4D5366),
        contentQuiet: .init(hex: 0x596074), actionPrimary: .init(hex: 0x6840B0),
        actionSecondary: .init(hex: 0x4D5366),
        actionDestructive: .init(hex: 0xA42D32), stateLive: .init(hex: 0x4A6F00),
        statePositive: .init(hex: 0x1F7048), stateWarning: .init(hex: 0x765300),
        stateNegative: .init(hex: 0xA42D32), stateInfo: .init(hex: 0x205F96),
        collegeIdentity: .init(hex: 0x6840B0), proIdentity: .init(hex: 0x2D628B),
        fieldTurf: .init(hex: 0xDCE8DF), fieldLine: .init(hex: 0x0E1218),
        fieldAnnotation: .init(hex: 0x7A5200), fieldLive: .init(hex: 0x4A6F00)
    )
}
