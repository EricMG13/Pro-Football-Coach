import SwiftUI

/// Registry 29 — a proportion drawn as an arc, in the large form.
///
/// `04` §6.5's proportion rule: where the data is a share of a whole, the form is a ring, not a
/// bar. The same primitive runs from a 26 pt table cell to a 212 pt attribute dial, which is what
/// makes the language hold together at density.
///
/// **The arc never carries the value alone.** It is a second reading of a printed figure, so the
/// gauge itself is accessibility-hidden and the caller prints and speaks the number.
public struct ArcGauge: View {
    @Environment(\.coachWorldPalette) private var palette

    private let value: Double
    private let lineWidth: CGFloat
    private let tint: [Color]?
    private let startAngle: Double

    public init(
        value: Double,
        lineWidth: CGFloat = CoachWorldTokens.Gauge.arcLineWidth,
        tint: [Color]? = nil,
        startAngle: Double = -90
    ) {
        self.value = value
        self.lineWidth = lineWidth
        self.tint = tint
        self.startAngle = startAngle
    }

    /// Half the stroke, so the arc sits inside its own bounds. Computed here rather than inline:
    /// a literal divisor inside `.padding(…)` reads as a design-token literal to `ContractTests`,
    /// and it is right to — a number in that position is one nobody can review.
    private var strokeInset: CGFloat { lineWidth / 2 }

    private var arcColors: [Color] {
        tint ?? [CoachWorldTokens.Gauge.arcLight.color, CoachWorldTokens.Gauge.arcDeep.color]
    }

    public var body: some View {
        ZStack {
            Circle().stroke(CoachWorldTokens.Gauge.track.color, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(value, 1)))
                .stroke(
                    AngularGradient(colors: arcColors, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(startAngle))
        }
        .padding(strokeInset)
        .accessibilityHidden(true)
    }
}

/// Registry 30 — the table-scale ring: a value inside its own proportion.
///
/// 26 pt by default, which `04` §6.5 records as the smallest size at which the arc still reads.
/// The figure is drawn inside the ring, so the ring is never the only reading.
public struct ValueRing: View {
    @Environment(\.coachWorldPalette) private var palette

    private let value: Int
    private let scale: Double
    private let diameter: CGFloat
    private let tint: Color?
    private let text: String?
    private let textTint: Color?
    private let accessibleValue: String?

    public init(
        _ value: Int,
        scale: Double = 100,
        diameter: CGFloat = CoachWorldTokens.Gauge.ringDiameter,
        tint: Color? = nil,
        text: String? = nil,
        textTint: Color? = nil,
        accessibleValue: String? = nil
    ) {
        self.value = value
        self.scale = scale
        self.diameter = diameter
        self.tint = tint
        self.text = text
        self.textTint = textTint
        self.accessibleValue = accessibleValue
    }

    private var ringWidth: CGFloat {
        max(CoachWorldTokens.Gauge.ringWidthFloor, diameter * CoachWorldTokens.Gauge.ringWidthRatio)
    }

    private var strokeInset: CGFloat { ringWidth / 2 }
    private var figureSize: CGFloat { diameter * 0.36 }
    private var printed: String { text ?? "\(value)" }

    public var body: some View {
        ZStack {
            Circle().stroke(CoachWorldTokens.Glass.track.color, lineWidth: ringWidth)
            Circle()
                .trim(from: 0, to: min(Double(value) / scale, 1))
                .stroke(
                    tint ?? palette.actionPrimary.color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
            Text(printed)
                .font(CoachWorldTokens.TypeRole.figures(figureSize, .bold))
                .foregroundStyle((textTint ?? palette.contentPrimary.color))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(width: diameter, height: diameter)
        .padding(strokeInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleValue ?? printed)
    }
}

/// Registry 31 — concentric arcs, one per attribute, radius carrying the value.
///
/// A passer who is elite everywhere except mobility reads as a ring with one bite taken out of it —
/// a silhouette recognised before a single number is read. Values run on the 40–99 rating scale, so
/// a full ring is 99 and an empty one 40; a 0–99 dial would show every player three-quarters full.
public struct AttributeDial: View {
    public struct Track: Identifiable, Sendable {
        public let id: String
        public let value: Int
        public let tint: Color

        public init(id: String, value: Int, tint: Color) {
            self.id = id
            self.value = value
            self.tint = tint
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let tracks: [Track]
    private let overall: Int
    private let diameter: CGFloat
    private let lineWidth: CGFloat
    private let trackSpacing: CGFloat

    public init(
        tracks: [Track],
        overall: Int,
        diameter: CGFloat = CoachWorldTokens.Gauge.dialDiameter,
        lineWidth: CGFloat = CoachWorldTokens.Gauge.dialLineWidth,
        trackSpacing: CGFloat = CoachWorldTokens.Gauge.dialTrackSpacing
    ) {
        self.tracks = tracks
        self.overall = overall
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.trackSpacing = trackSpacing
    }

    private var strokeInset: CGFloat { lineWidth / 2 }
    private var overallSize: CGFloat { diameter * 0.198 }
    private var coreInset: CGFloat {
        CGFloat(tracks.count) * trackSpacing + CoachWorldTokens.Gauge.dialCoreInset
    }
    private var coreRadius: CGFloat { diameter * 0.3 }

    private func fraction(_ value: Int) -> Double {
        let range = CoachWorldTokens.Gauge.ratingScale
        let span = range.upperBound - range.lowerBound
        return max(0, min((Double(value) - range.lowerBound) / span, 1))
    }

    public var body: some View {
        ZStack {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                let inset = CGFloat(index) * trackSpacing + strokeInset
                ZStack {
                    Circle().stroke(CoachWorldTokens.Gauge.dialTrack.color, lineWidth: lineWidth)
                    Circle()
                        .trim(from: 0, to: fraction(track.value))
                        .stroke(
                            track.tint,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .padding(inset)
            }

            core
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    /// The core carries the one number that summarises the rest.
    private var core: some View {
        Circle()
            .fill(RadialGradient(
                colors: [
                    CoachWorldTokens.Gauge.dialCoreHighlight.color,
                    CoachWorldTokens.Atmosphere.dialCore.color
                ],
                center: UnitPoint(x: 0.34, y: 0.26),
                startRadius: .zero,
                endRadius: coreRadius
            ))
            .overlay(
                Circle().strokeBorder(
                    CoachWorldTokens.Glass.edge.color,
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            )
            .overlay {
                VStack(spacing: .zero) {
                    Text("\(overall)")
                        .font(CoachWorldTokens.TypeRole.display(overallSize))
                        .foregroundStyle(palette.contentPrimary.color)
                    CoachWorldFieldLabel("Overall")
                }
            }
            .padding(coreInset)
    }

    /// One sentence, because a ring of arcs has no reading order a screen reader can infer.
    private var spokenSummary: String {
        let parts = tracks.map { "\($0.id) \($0.value)" }.joined(separator: ", ")
        return "Overall \(overall). \(parts)."
    }
}

/// Registry 32 — a horizontal share, for a comparison that must sit inline in a row.
///
/// The stated exception to the proportion rule: rival programmes competing for the same recruit sit
/// in a table row, where a ring per rival would not fit and would not compare.
public struct ShareBar: View {
    @Environment(\.coachWorldPalette) private var palette

    private let value: Double
    private let tint: Color?
    private let height: CGFloat

    public init(
        value: Double,
        tint: Color? = nil,
        height: CGFloat = CoachWorldTokens.Gauge.shareBarHeight
    ) {
        self.value = value
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(CoachWorldTokens.Gauge.track.color)
                Capsule().fill(tint ?? palette.actionPrimary.color)
                    .frame(width: proxy.size.width * max(0, min(value, 1)))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
