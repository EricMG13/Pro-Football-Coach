import SwiftUI

/// Registry 24 — a rectangle with four independent corner radii.
///
/// Panels are cut asymmetrically so a surface reads as a deliberate shape rather than a default
/// rounded card. `RoundedRectangle` cannot express four different radii, so the path is drawn by
/// hand. The radii themselves are `04` §6.3's, held in `CoachWorldTokens.Shape` rather than as
/// literals here — a shape may own its geometry, but not its measurements.
public struct CutCorner: Shape, InsettableShape {
    public var topLeading: CGFloat
    public var topTrailing: CGFloat
    public var bottomTrailing: CGFloat
    public var bottomLeading: CGFloat
    private var inset: CGFloat = 0

    public init(_ cut: CoachWorldTokens.Shape.Cut) {
        topLeading = cut.topLeading
        topTrailing = cut.topTrailing
        bottomTrailing = cut.bottomTrailing
        bottomLeading = cut.bottomLeading
    }

    /// Any surface holding content — `04` §6.3.
    public static let panel = CutCorner(CoachWorldTokens.Shape.panelCut)
    /// Table rows, chips and free-standing rows.
    public static let row = CutCorner(CoachWorldTokens.Shape.rowCut)
    /// The committing action: soft on three corners, cut on the last.
    public static let action = CutCorner(CoachWorldTokens.Shape.actionCut)

    public func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        let limit = min(r.width, r.height) / 2
        let tl = min(topLeading, limit)
        let tr = min(topTrailing, limit)
        let br = min(bottomTrailing, limit)
        let bl = min(bottomLeading, limit)

        var path = Path()
        path.move(to: CGPoint(x: r.minX + tl, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX - tr, y: r.minY))
        path.addArc(
            center: CGPoint(x: r.maxX - tr, y: r.minY + tr), radius: tr,
            startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - br))
        path.addArc(
            center: CGPoint(x: r.maxX - br, y: r.maxY - br), radius: br,
            startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: r.minX + bl, y: r.maxY))
        path.addArc(
            center: CGPoint(x: r.minX + bl, y: r.maxY - bl), radius: bl,
            startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + tl))
        path.addArc(
            center: CGPoint(x: r.minX + tl, y: r.minY + tl), radius: tl,
            startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.closeSubpath()
        return path
    }

    public func inset(by amount: CGFloat) -> CutCorner {
        var copy = self
        copy.inset += amount
        return copy
    }
}

/// The score bug's diagonal cut — a bar whose lower edge rakes away to the leading side.
///
/// The proportions are the shape's own identity rather than design tokens: they describe this one
/// piece of BROADCAST furniture and are not reused, which is why they are not in `04` §6.3.
public struct RakedBar: Shape {
    public var lowerLeading: CGFloat
    public var lowerTrailing: CGFloat
    public var breakPoint: CGFloat

    public init(
        lowerLeading: CGFloat = 0.84,
        lowerTrailing: CGFloat = 0.74,
        breakPoint: CGFloat = 0.58
    ) {
        self.lowerLeading = lowerLeading
        self.lowerTrailing = lowerTrailing
        self.breakPoint = breakPoint
    }

    public func path(in r: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * lowerTrailing))
        path.addLine(to: CGPoint(x: r.minX + r.width * breakPoint, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * lowerLeading))
        path.closeSubpath()
        return path
    }
}
