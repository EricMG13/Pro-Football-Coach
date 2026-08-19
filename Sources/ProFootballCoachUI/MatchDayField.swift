import SwiftUI

// The drawn field: turf, paint, end zones, the midfield mark, and the two things that move.
//
// Geometry is percentage-based throughout, exactly as the 2026-08-18 handoff states it, so the
// same numbers hold at the 844 x 390 install floor and on anything larger. `MatchDayView` owns the
// chrome; nothing here knows what a scorebug is.
//
// The whole static plane rasterises once (`FieldPlane` is `Equatable` and ends in `.drawingGroup()`)
// because `BUILD.md` names stacked live material over a transformed plane as the heaviest thing in
// the app. Players and the ball are drawn *outside* that group, so they keep their accessibility
// elements and can move without re-rasterising the turf.

/// The field's shared arithmetic. One place, so the plane, the paint and the tokens cannot drift.
enum MatchFieldGeometry {
    /// The drawn field is 120 yards wide: 100 of play with a 10-yard end zone at each end.
    static let totalYards: Double = 120
    static let endZoneYards: Double = 10
    /// 10 of 120.
    static let goalLineFraction: Double = endZoneYards / totalYards

    /// The band players and the ball are placed in, so a token never sits under the scorebug or the
    /// lower third. The handoff states it as `y% = 10 + v x 0.80`.
    static let playBandTop: Double = 0.10
    static let playBandHeight: Double = 0.80

    static func x(yards: Double, in width: CGFloat) -> CGFloat {
        width * CGFloat(yards / totalYards)
    }

    static func y(fraction: Double, in height: CGFloat) -> CGFloat {
        height * CGFloat(playBandTop + fraction * playBandHeight)
    }

    /// Hash rows, as fractions of the frame height. The two tiers paint the same field differently
    /// and nothing else about it changes.
    static func hashRows(_ tier: MatchTier) -> [CGFloat] {
        switch tier {
        case .college: [0.375, 0.625]
        case .pro: [0.442, 0.558]
        }
    }
}

// MARK: - The turf plane

/// The eight-layer turf stack plus every painted line, drawn once into one raster.
///
/// `Equatable` on purpose: the turf depends on the frame, the tier and the two teams' colours and
/// on nothing that changes between snaps, so `.equatable()` at the call site keeps a moving ball
/// from redrawing a thousand blades of grass sixty times a second.
struct FieldPlane: View, Equatable {
    let tier: MatchTier
    let leftIdentity: CoachWorldTeamIdentity?
    let rightIdentity: CoachWorldTeamIdentity?
    let leftLabel: String
    let rightLabel: String
    let mark: FieldMarkContent

    static func == (lhs: FieldPlane, rhs: FieldPlane) -> Bool {
        lhs.tier == rhs.tier
            && lhs.leftIdentity == rhs.leftIdentity
            && lhs.rightIdentity == rhs.rightIdentity
            && lhs.leftLabel == rhs.leftLabel
            && lhs.rightLabel == rhs.rightLabel
            && lhs.mark == rhs.mark
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                // 1 — ground.
                EllipticalGradient(
                    stops: [
                        .init(color: CoachWorldTokens.Floodlit.turfCrown.color, location: 0),
                        .init(color: CoachWorldTokens.Floodlit.turf.color, location: 0.24),
                        .init(color: CoachWorldTokens.Floodlit.turfMid.color, location: 0.50),
                        .init(color: CoachWorldTokens.Floodlit.turfShade.color, location: 0.74),
                        .init(color: CoachWorldTokens.Floodlit.turfNight.color, location: 1),
                    ],
                    center: UnitPoint(x: 0.5, y: 0.56),
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.69
                )

                // 2 to 6, then 8 — everything that is a rectangle, an ellipse or a hairline.
                Canvas(rendersAsynchronously: false) { context, canvasSize in
                    Self.drawMow(&context, canvasSize)
                    Self.drawWeave(&context, canvasSize)
                    Self.drawCrossCut(&context, canvasSize)
                    Self.drawMottle(&context, canvasSize)
                    Self.drawWear(&context, canvasSize)
                    Self.drawFloodlightPools(&context, canvasSize)
                }

                // 7 — grain, over the turf and under the paint, per the handoff's layer order.
                CoachWorldGrainOverlay()
                    .blendMode(.overlay)
                    .opacity(Turf.grainOpacity)

                EndZonePaint(edge: .leading, identity: leftIdentity, label: leftLabel)
                EndZonePaint(edge: .trailing, identity: rightIdentity, label: rightLabel)

                Canvas(rendersAsynchronously: false) { context, canvasSize in
                    Self.drawPaint(&context, canvasSize, tier: tier)
                }

                FieldMark(content: mark)
                    .frame(width: size.width, height: size.height)
            }
            .frame(width: size.width, height: size.height)
        }
        // The rasterisation the handoff asks for: one texture, not eight composited layers.
        .drawingGroup()
        .accessibilityHidden(true)
    }

    // MARK: Turf layers

    private static func drawMow(_ context: inout GraphicsContext, _ size: CGSize) {
        // Five-yard stripes across the drawn field: 24 bands of 1/24 each.
        let bandWidth = size.width / CGFloat(Turf.mowBands)
        for band in 0..<Turf.mowBands {
            let rect = CGRect(
                x: bandWidth * CGFloat(band), y: 0, width: bandWidth, height: size.height
            )
            let shade = band.isMultiple(of: 2)
                ? GraphicsContext.Shading.color(.white.opacity(Turf.mowLight))
                : GraphicsContext.Shading.color(.black.opacity(Turf.mowDark))
            context.fill(Path(rect), with: shade)
        }
    }

    private static func drawWeave(_ context: inout GraphicsContext, _ size: CGSize) {
        var vertical = Path()
        var x: CGFloat = 0
        while x < size.width {
            vertical.move(to: CGPoint(x: x, y: 0))
            vertical.addLine(to: CGPoint(x: x, y: size.height))
            x += Turf.weaveVerticalPitch
        }
        context.stroke(
            vertical, with: .color(.white.opacity(Turf.weaveLight)), lineWidth: Turf.hairline
        )

        var horizontal = Path()
        var y: CGFloat = 0
        while y < size.height {
            horizontal.move(to: CGPoint(x: 0, y: y))
            horizontal.addLine(to: CGPoint(x: size.width, y: y))
            y += Turf.weaveHorizontalPitch
        }
        context.stroke(
            horizontal, with: .color(.black.opacity(Turf.weaveDark)), lineWidth: Turf.hairline
        )
    }

    private static func drawCrossCut(_ context: inout GraphicsContext, _ size: CGSize) {
        // The mower's second pass, at plus and minus 26 degrees. Drawn as two sheared line sets
        // rather than as a rotated layer: a rotated layer would need its own raster.
        let run = size.height * Turf.crossCutSlope
        for (sign, alpha) in [(1.0, Turf.crossCutLight), (-1.0, Turf.crossCutDark)] {
            var path = Path()
            var start = -run
            while start < size.width + run {
                path.move(to: CGPoint(x: start, y: 0))
                path.addLine(to: CGPoint(x: start + CGFloat(sign) * run, y: size.height))
                start += Turf.crossCutPitch
            }
            let colour: Color = sign > 0 ? .white : .black
            context.stroke(
                path, with: .color(colour.opacity(alpha)), lineWidth: Turf.crossCutWidth
            )
        }
    }

    private static func drawMottle(_ context: inout GraphicsContext, _ size: CGSize) {
        for patch in Turf.mottle {
            context.fill(
                Path(ellipseIn: patch.rect(in: size)),
                with: .color(patch.light
                    ? .white.opacity(patch.alpha)
                    : .black.opacity(patch.alpha))
            )
        }
    }

    private static func drawWear(_ context: inout GraphicsContext, _ size: CGSize) {
        for patch in Turf.wear {
            context.fill(
                Path(ellipseIn: patch.rect(in: size)),
                with: .color(.black.opacity(patch.alpha))
            )
        }
    }

    private static func drawFloodlightPools(_ context: inout GraphicsContext, _ size: CGSize) {
        for pool in Turf.pools {
            context.fill(
                Path(ellipseIn: pool.rect(in: size)),
                with: .color(CoachWorldTokens.Floodlit.lamp.color.opacity(pool.alpha))
            )
        }
    }

    // MARK: Paint

    private static func drawPaint(_ context: inout GraphicsContext, _ size: CGSize, tier: MatchTier) {
        let line = CoachWorldTokens.dark.fieldLine.color
        let goal = MatchFieldGeometry.goalLineFraction
        let playWidth = size.width * CGFloat(1 - 2 * goal)
        let playOrigin = size.width * CGFloat(goal)

        // Five-yard lines, full height, every 5 yards of the playing area.
        var fives = Path()
        for step in 1..<20 {
            let x = playOrigin + playWidth * CGFloat(step) / 20
            fives.move(to: CGPoint(x: x, y: 0))
            fives.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.stroke(fives, with: .color(line.opacity(Paint.fiveYard)), lineWidth: Paint.fiveWidth)

        // One-yard ticks, in a short row just inside each sideline.
        var ticks = Path()
        for yard in 1..<100 {
            let x = playOrigin + playWidth * CGFloat(yard) / 100
            ticks.move(to: CGPoint(x: x, y: Paint.sidelineInset))
            ticks.addLine(to: CGPoint(x: x, y: Paint.sidelineInset + Paint.tickRow))
            ticks.move(to: CGPoint(x: x, y: size.height - Paint.sidelineInset - Paint.tickRow))
            ticks.addLine(to: CGPoint(x: x, y: size.height - Paint.sidelineInset))
        }
        context.stroke(ticks, with: .color(line.opacity(Paint.tick)), lineWidth: Paint.tickWidth)

        // Hash rows, by tier.
        var hashes = Path()
        for row in MatchFieldGeometry.hashRows(tier) {
            let y = size.height * row
            for yard in 1..<100 {
                let x = playOrigin + playWidth * CGFloat(yard) / 100
                hashes.move(to: CGPoint(x: x, y: y - Paint.hashRow / 2))
                hashes.addLine(to: CGPoint(x: x, y: y + Paint.hashRow / 2))
            }
        }
        context.stroke(hashes, with: .color(line.opacity(Paint.tick)), lineWidth: Paint.tickWidth)

        // Sidelines, at the top and bottom of the playing area.
        var sidelines = Path()
        sidelines.move(to: CGPoint(x: playOrigin, y: Paint.fiveWidth / 2))
        sidelines.addLine(to: CGPoint(x: playOrigin + playWidth, y: Paint.fiveWidth / 2))
        sidelines.move(to: CGPoint(x: playOrigin, y: size.height - Paint.fiveWidth / 2))
        sidelines.addLine(to: CGPoint(x: playOrigin + playWidth, y: size.height - Paint.fiveWidth / 2))
        context.stroke(
            sidelines, with: .color(line.opacity(Paint.sideline)), lineWidth: Paint.fiveWidth
        )

        // Goal lines.
        var goals = Path()
        for fraction in [goal, 1 - goal] {
            let x = size.width * CGFloat(fraction)
            goals.move(to: CGPoint(x: x, y: 0))
            goals.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.stroke(goals, with: .color(line.opacity(Paint.goal)), lineWidth: Paint.goalWidth)

        drawYardNumbers(&context, size, playOrigin: playOrigin, playWidth: playWidth, line: line)
        drawPylons(&context, size, goal: goal)
    }

    private static func drawYardNumbers(
        _ context: inout GraphicsContext,
        _ size: CGSize,
        playOrigin: CGFloat,
        playWidth: CGFloat,
        line: Color
    ) {
        for yard in stride(from: 10, through: 90, by: 10) {
            let printed = yard <= 50 ? yard : 100 - yard
            let x = playOrigin + playWidth * CGFloat(yard) / 100
            let text = context.resolve(
                Text("\(printed)")
                    .font(CoachWorldTokens.display(Paint.numberSize, weight: .bold))
                    .tracking(CoachWorldTokens.DisplaySize.tracking(0.05, at: Paint.numberSize))
                    .foregroundStyle(line.opacity(Paint.number))
            )
            for row in [Paint.numberTopRow, Paint.numberBottomRow] {
                let y = size.height * row
                // The paint's soft drop, drawn as an offset copy — a Canvas has no text shadow.
                context.draw(
                    context.resolve(
                        Text("\(printed)")
                            .font(CoachWorldTokens.display(Paint.numberSize, weight: .bold))
                            .tracking(
                                CoachWorldTokens.DisplaySize.tracking(0.05, at: Paint.numberSize)
                            )
                            .foregroundStyle(Color.black.opacity(Paint.numberShadow))
                    ),
                    at: CGPoint(x: x, y: y + Paint.numberShadowOffset)
                )
                context.draw(text, at: CGPoint(x: x, y: y))

                // The direction arrow points at the near goal line. The 50 has none.
                guard printed != 50 else { continue }
                let towardLeading = yard < 50
                let arrowX = x + (towardLeading ? -Paint.arrowOffset : Paint.arrowOffset)
                var arrow = Path()
                let half = Paint.arrowSize / 2
                let tip = arrowX + (towardLeading ? -half : half)
                let base = arrowX - (towardLeading ? -half : half)
                arrow.move(to: CGPoint(x: tip, y: y))
                arrow.addLine(to: CGPoint(x: base, y: y - half))
                arrow.addLine(to: CGPoint(x: base, y: y + half))
                arrow.closeSubpath()
                context.fill(arrow, with: .color(line.opacity(Paint.number)))
            }
        }
    }

    private static func drawPylons(_ context: inout GraphicsContext, _ size: CGSize, goal: Double) {
        let glow = CoachWorldTokens.dark.stateWarning.color
        for fraction in [0, goal, 1 - goal, 1] {
            for edge in [true, false] {
                let x = size.width * CGFloat(fraction) - Paint.pylonWidth / 2
                let y = edge ? 0 : size.height - Paint.pylonHeight
                let rect = CGRect(
                    x: x, y: y, width: Paint.pylonWidth, height: Paint.pylonHeight
                )
                // The glow, then the pylon: a Canvas cannot blur, so the halo is a wider, fainter
                // copy of the same shape.
                context.fill(
                    Path(ellipseIn: rect.insetBy(dx: -Paint.pylonGlow, dy: -Paint.pylonGlow)),
                    with: .color(glow.opacity(Paint.pylonGlowAlpha))
                )
                context.fill(Path(rect), with: .color(glow))
            }
        }
    }
}

// MARK: - End zones

/// One painted end zone: fill, cross mow, sheen, corner falloff and the rotated team name.
///
/// The lettering is the part worth matching exactly — eight offset copies in the team's accent
/// behind one pale copy, which is how a painted-on name reads at this scale.
struct EndZonePaint: View {
    enum Edge { case leading, trailing }

    let edge: Edge
    let identity: CoachWorldTeamIdentity?
    let label: String

    private var isOurs: Bool { identity != nil }

    private var fill: Color {
        guard let identity else { return CoachWorldTokens.Floodlit.endZoneOpponent.color }
        return identity.field.mixed(with: EndZone.deepGround, amount: 0.5).color
    }

    private var accent: Color {
        identity?.accent.color ?? CoachWorldTokens.Floodlit.opponentAccent.color
    }

    private var ink: Color {
        (isOurs ? EndZone.oursInk : EndZone.theirsInk)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let zoneWidth = size.width * CGFloat(MatchFieldGeometry.goalLineFraction)
            ZStack {
                fill
                crossMow
                LinearGradient(
                    colors: [.white.opacity(isOurs ? EndZone.sheenOurs : EndZone.sheenTheirs), .clear],
                    startPoint: .topLeading,
                    endPoint: .init(x: 0.44, y: 0.44)
                )
                LinearGradient(
                    colors: [
                        EndZone.deepGround.color.opacity(isOurs ? 0.40 : 0.24),
                        EndZone.deepGround.color.opacity(isOurs ? 0.56 : 0.40),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    stops: [
                        .init(color: .clear, location: 0.36),
                        .init(color: Color.black.opacity(EndZone.falloff), location: 1),
                    ],
                    center: UnitPoint(x: 0.26, y: 0.34),
                    startRadius: 0,
                    endRadius: max(zoneWidth, size.height) * EndZone.falloffRadius
                )
                CoachWorldGrainOverlay()
                    .blendMode(.overlay)
                    .opacity(EndZone.grainOpacity)
                lettering
                    .frame(width: size.height, height: zoneWidth)
                    .rotationEffect(.degrees(isOurs ? -90 : 90))
                    .frame(width: zoneWidth, height: size.height)
            }
            .frame(width: zoneWidth, height: size.height)
            .overlay(alignment: edge == .leading ? .leading : .trailing) { endLine }
            .overlay(alignment: .top) { edgeLine }
            .overlay(alignment: .bottom) { edgeLine }
            .frame(width: size.width, alignment: edge == .leading ? .leading : .trailing)
        }
        .accessibilityHidden(true)
    }

    private var crossMow: some View {
        GeometryReader { geometry in
            Canvas(rendersAsynchronously: false) { context, size in
                var y: CGFloat = 0
                var light = true
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: EndZone.mowPitch)
                    context.fill(
                        Path(rect),
                        with: .color(light
                            ? .white.opacity(EndZone.mowLight)
                            : .black.opacity(EndZone.mowDark))
                    )
                    y += EndZone.mowPitch
                    light.toggle()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    /// The painted name: eight accent copies at plus and minus two points, then one pale copy.
    private var lettering: some View {
        let size = isOurs ? EndZone.oursSize : EndZone.theirsSize
        let tracking = isOurs ? EndZone.oursTracking : EndZone.theirsTracking
        let text = Text(label.uppercased())
            .font(CoachWorldTokens.display(size, weight: .bold))
            .tracking(CoachWorldTokens.DisplaySize.tracking(tracking, at: size))
        return ZStack {
            ForEach(Array(EndZone.outlineOffsets.enumerated()), id: \.offset) { _, offset in
                text
                    .foregroundStyle(accent.opacity(EndZone.outlineAlpha))
                    .offset(x: offset.x, y: offset.y)
            }
            text.foregroundStyle(ink)
        }
        .lineLimit(1)
        .fixedSize()
    }

    private var endLine: some View {
        Rectangle()
            .fill(CoachWorldTokens.dark.fieldLine.color.opacity(Paint.goal))
            .frame(width: Paint.goalWidth)
    }

    private var edgeLine: some View {
        Rectangle()
            .fill(CoachWorldTokens.dark.fieldLine.color.opacity(Paint.sideline))
            .frame(height: Paint.fiveWidth)
    }
}

// MARK: - The midfield mark

/// What the centre circle draws, resolved from the game kind by the caller so the shape here has
/// no opinion about competition structure.
struct FieldMarkContent: Equatable {
    let kind: MatchGameKind
    /// The centred glyph: a team's short name in the regular season, `EC` / `XLIV` / `PLAYOFF`
    /// otherwise.
    let glyph: String
    let lead: String?
    let trail: String?
}

/// The painted midfield mark. Low alpha and no hard edge, so the mow reads through it.
struct FieldMark: View {
    let content: FieldMarkContent

    var body: some View {
        ZStack {
            switch content.kind {
            case .regular: regular
            case .conference: conference
            case .bowl: bowl
            case .playoff: playoff
            case .championship: championship
            }
        }
        .compositingGroup()
        .blur(radius: Mark.paintBlur)
        .accessibilityHidden(true)
    }

    private var regular: some View {
        ZStack {
            Circle()
                .stroke(line(Mark.ringAlpha), lineWidth: Mark.ringWidth)
                .frame(width: Mark.regularDiameter, height: Mark.regularDiameter)
            Circle()
                .stroke(line(Mark.innerRingAlpha), lineWidth: CoachWorldTokens.Shape.hairline)
                .frame(width: Mark.regularInner, height: Mark.regularInner)
            glyph(CoachWorldTokens.DisplaySize.row, alpha: Mark.glyphAlpha)
        }
    }

    private var conference: some View {
        ZStack {
            diamond(Mark.conferenceDiamond, stroke: Mark.conferenceStroke, colour: cool(0.40))
            diamond(Mark.conferenceInner, stroke: CoachWorldTokens.Shape.hairline, colour: cool(0.24))
            stack(glyphSize: CoachWorldTokens.DisplaySize.panel, tracking: 0.3)
        }
    }

    private var bowl: some View {
        ZStack {
            diamond(Mark.bowlSize, stroke: Mark.conferenceStroke, colour: gold(0.45))
            Rectangle()
                .stroke(line(Mark.innerRingAlpha), lineWidth: CoachWorldTokens.Shape.hairline)
                .frame(width: Mark.bowlSize, height: Mark.bowlSize)
            stack(glyphSize: CoachWorldTokens.DisplaySize.row, tracking: 0.34)
        }
    }

    private var playoff: some View {
        ZStack {
            VStack(spacing: .zero) {
                bracket(open: .down)
                Spacer(minLength: Mark.bracketGap)
                bracket(open: .up)
            }
            .frame(height: Mark.playoffHeight)
            stack(glyphSize: CoachWorldTokens.DisplaySize.lead, tracking: 0.3)
        }
    }

    private var championship: some View {
        ZStack {
            Circle()
                .stroke(gold(0.45), lineWidth: Mark.conferenceStroke)
                .frame(width: Mark.championshipDiameter, height: Mark.championshipDiameter)
            Circle()
                .stroke(line(Mark.innerRingAlpha), lineWidth: CoachWorldTokens.Shape.hairline)
                .frame(width: Mark.championshipInner, height: Mark.championshipInner)
            VStack(spacing: CoachWorldTokens.Gap.hair) {
                Image(systemName: "star.fill")
                    .font(.system(size: Mark.starSize))
                    .foregroundStyle(gold(0.5))
                stack(glyphSize: .zero, tracking: 0.24)
            }
        }
    }

    // MARK: pieces

    private func stack(glyphSize: CGFloat, tracking: CGFloat) -> some View {
        VStack(spacing: CoachWorldTokens.Gap.hair) {
            if let lead = content.lead {
                caption(lead, tracking: tracking)
            }
            if glyphSize > 0 {
                glyph(glyphSize, alpha: Mark.glyphAlpha)
            }
            if let trail = content.trail {
                caption(trail, tracking: tracking)
            }
        }
    }

    private func glyph(_ size: CGFloat, alpha: Double) -> some View {
        Text(content.glyph.uppercased())
            .font(CoachWorldTokens.display(size, weight: .bold))
            .foregroundStyle(line(alpha))
            .lineLimit(1)
    }

    private func caption(_ text: String, tracking: CGFloat) -> some View {
        Text(text.uppercased())
            .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
            .tracking(
                CoachWorldTokens.DisplaySize.tracking(tracking, at: CoachWorldTokens.DisplaySize.flag)
            )
            .foregroundStyle(line(Mark.captionAlpha))
            .lineLimit(1)
    }

    private func diamond(_ size: CGFloat, stroke: CGFloat, colour: Color) -> some View {
        Rectangle()
            .stroke(colour, lineWidth: stroke)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
    }

    private enum BracketOpening { case up, down }

    private func bracket(open: BracketOpening) -> some View {
        Path { path in
            let w = Mark.bracketWidth
            let h = Mark.bracketDepth
            switch open {
            case .down:
                path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: h))
            case .up:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w, y: 0))
            }
        }
        .stroke(
            CoachWorldTokens.dark.stateNegative.color.opacity(0.42),
            lineWidth: Mark.conferenceStroke
        )
        .frame(width: Mark.bracketWidth, height: Mark.bracketDepth)
    }

    private func line(_ alpha: Double) -> Color {
        CoachWorldTokens.dark.fieldLine.color.opacity(alpha)
    }

    private func gold(_ alpha: Double) -> Color {
        CoachWorldTokens.dark.actionPrimary.color.opacity(alpha)
    }

    private func cool(_ alpha: Double) -> Color {
        CoachWorldTokens.Floodlit.opponentAccent.color.opacity(alpha)
    }
}

// MARK: - Tokens and marks

/// One of the twenty-two. A 15 pt disc carrying a position shorthand, not a jersey number:
/// `04` section 6.5 #18 makes the diagram's marks role tokens, and eleven `LT LG C RG RT` read as a
/// formation where eleven two-digit numbers read as noise.
struct PlayerToken: View {
    let label: String
    let isOurs: Bool

    var body: some View {
        Text(label.uppercased())
            .font(CoachWorldTokens.display(Token.labelSize, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(isOurs
                ? CoachWorldTokens.Floodlit.goldInk.color
                : CoachWorldTokens.Floodlit.opponentInk.color)
            .lineLimit(1)
            .minimumScaleFactor(Token.labelScaleFloor)
            .padding(.horizontal, CoachWorldTokens.Gap.hair)
            .frame(width: Token.diameter, height: Token.diameter)
            .background(
                Circle().fill(isOurs
                    ? CoachWorldTokens.dark.actionPrimary.color
                    : CoachWorldTokens.Floodlit.opponentField.color)
            )
            .overlay(
                Circle().stroke(
                    isOurs
                        ? CoachWorldTokens.Floodlit.goldLight.color
                        : CoachWorldTokens.Floodlit.opponentAccent.color.opacity(0.7),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            )
            .shadow(color: .black.opacity(Token.shadowAlpha), radius: Token.shadowRadius, y: 3)
    }
}

/// The football: a lens, not a circle, with a shadow that stays on the turf while the ball rises.
///
/// `ballHeight` is 0 on the turf and 1 at the apex of a throw. Three cues carry the depth — the ball
/// lifts and grows, it tilts along its flight, and the shadow separates downward under the system's
/// single upper-left light.
struct BallToken: View {
    let ballHeight: Double

    private var height: Double { min(1, max(0, ballHeight)) }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(Ball.shadowAlpha - height * Ball.shadowFade))
                .frame(width: Ball.shadowWidth, height: Ball.shadowHeight)
                .blur(radius: Ball.shadowBlur)
                .scaleEffect(Ball.shadowRestScale + height * (1 - Ball.shadowRestScale))
                .offset(y: height * Ball.shadowDrop)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            CoachWorldTokens.Floodlit.lamp.color.opacity(Ball.glowAlpha), .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: Ball.glowWidth / 2
                    )
                )
                .frame(width: Ball.glowWidth, height: Ball.glowHeight)
                .scaleEffect(Ball.glowRestScale + height * (Ball.glowApexScale - Ball.glowRestScale))
                .offset(y: -height * Ball.lift)

            leather
                .frame(width: Ball.width, height: Ball.height)
                .rotationEffect(.degrees(-Ball.tilt * height))
                .scaleEffect(1 + height * (Ball.apexScale - 1))
                .offset(y: -height * Ball.lift)
        }
        .accessibilityHidden(true)
    }

    private var leather: some View {
        ZStack {
            Ball.silhouette
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: CoachWorldTokens.Floodlit.ballHighlight.color, location: 0),
                            .init(color: CoachWorldTokens.Floodlit.ballMid.color, location: 0.44),
                            .init(color: CoachWorldTokens.Floodlit.ballShade.color, location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            GeometryReader { geometry in
                let scale = geometry.size.width / Ball.width
                ZStack(alignment: .topLeading) {
                    ForEach(Ball.stripes, id: \.self) { x in
                        Rectangle()
                            .fill(CoachWorldTokens.dark.fieldLine.color.opacity(Ball.markAlpha))
                            .frame(width: Ball.stripeWidth * scale, height: Ball.stripeHeight * scale)
                            .offset(x: x * scale, y: Ball.stripeTop * scale)
                    }
                    Rectangle()
                        .fill(CoachWorldTokens.dark.fieldLine.color.opacity(Ball.markAlpha))
                        .frame(width: Ball.laceWidth * scale, height: Ball.laceHeight * scale)
                        .offset(x: Ball.laceX * scale, y: Ball.laceY * scale)
                    ForEach(Ball.laceTicks, id: \.self) { x in
                        Rectangle()
                            .fill(CoachWorldTokens.dark.fieldLine.color.opacity(Ball.markAlpha))
                            .frame(width: Ball.tickWidth * scale, height: Ball.tickHeight * scale)
                            .offset(x: x * scale, y: Ball.tickTop * scale)
                    }
                }
            }
        }
        .clipShape(Ball.silhouette)
    }
}

// MARK: - Literals

/// Every drawing constant the field needs, in one place — `CLAUDE.md` forbids a literal at a call
/// site, and these are values the design states rather than roles the palette holds.
private enum Turf {
    static let hairline: CGFloat = 1
    static let mowBands = 24
    static let mowLight = 0.03
    static let mowDark = 0.07
    static let weaveVerticalPitch: CGFloat = 3
    static let weaveHorizontalPitch: CGFloat = 2
    static let weaveLight = 0.026
    static let weaveDark = 0.07
    static let crossCutPitch: CGFloat = 5
    static let crossCutWidth: CGFloat = 2
    static let crossCutLight = 0.016
    static let crossCutDark = 0.03
    /// tan(26 degrees), as the shear the cross cut is drawn at.
    static let crossCutSlope: CGFloat = 0.4877
    static let grainOpacity = 0.62

    struct Patch {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        let alpha: Double
        var light = true

        func rect(in size: CGSize) -> CGRect {
            CGRect(
                x: size.width * CGFloat(x - width / 2),
                y: size.height * CGFloat(y - height / 2),
                width: size.width * CGFloat(width),
                height: size.height * CGFloat(height)
            )
        }
    }

    static let mottle: [Patch] = [
        .init(x: 0.14, y: 0.22, width: 0.26, height: 0.42, alpha: 0.035),
        .init(x: 0.38, y: 0.76, width: 0.30, height: 0.38, alpha: 0.025),
        .init(x: 0.70, y: 0.88, width: 0.24, height: 0.34, alpha: 0.030),
        .init(x: 0.62, y: 0.18, width: 0.28, height: 0.40, alpha: 0.14, light: false),
        .init(x: 0.86, y: 0.70, width: 0.22, height: 0.36, alpha: 0.16, light: false),
    ]

    static let wear: [Patch] = [
        .init(x: 0.50, y: 0.50, width: 0.46, height: 0.30, alpha: 0.34, light: false),
        .init(x: 0.26, y: 0.46, width: 0.30, height: 0.16, alpha: 0.22, light: false),
        .init(x: 0.74, y: 0.56, width: 0.30, height: 0.16, alpha: 0.22, light: false),
        .init(x: 0.50, y: 0.96, width: 0.70, height: 0.16, alpha: 0.26, light: false),
    ]

    static let pools: [Patch] = [
        .init(x: 0.20, y: 0.06, width: 0.42, height: 0.52, alpha: 0.070),
        .init(x: 0.50, y: 0.04, width: 0.44, height: 0.50, alpha: 0.075),
        .init(x: 0.80, y: 0.06, width: 0.42, height: 0.52, alpha: 0.070),
        .init(x: 0.50, y: 0.98, width: 0.80, height: 0.36, alpha: 0.050),
    ]
}

/// Module-internal rather than file-private (2026-08-19, S-8) so `ContractTests` can assert the
/// real yard-number opacity through `@testable import` instead of hardcoding a duplicate literal.
enum Paint {
    static let fiveYard = 0.26
    static let fiveWidth: CGFloat = 2
    static let tick = 0.30
    static let tickWidth: CGFloat = 1.5
    static let tickRow: CGFloat = 7
    static let sidelineInset: CGFloat = 3
    static let sideline = 0.40
    static let goal = 0.90
    static let goalWidth: CGFloat = 3
    static let hashRow: CGFloat = 6
    static let numberSize: CGFloat = 23
    static let number = 0.33
    static let numberShadow = 0.45
    static let numberShadowOffset: CGFloat = 2
    static let numberTopRow: CGFloat = 0.20
    static let numberBottomRow: CGFloat = 0.80
    static let arrowSize: CGFloat = 10
    static let arrowOffset: CGFloat = 16
    static let pylonWidth: CGFloat = 5
    static let pylonHeight: CGFloat = 9
    static let pylonGlow: CGFloat = 7
    static let pylonGlowAlpha = 0.35
}

private enum EndZone {
    static let deepGround = CoachWorldTokens.ColorValue(hex: 0x072616)
    static let oursInk = Color(red: 247 / 255, green: 251 / 255, blue: 255 / 255).opacity(0.93)
    static let theirsInk = Color(red: 240 / 255, green: 247 / 255, blue: 255 / 255).opacity(0.90)
    static let oursSize: CGFloat = 38
    static let theirsSize: CGFloat = 36
    static let oursTracking: CGFloat = 0.11
    static let theirsTracking: CGFloat = 0.10
    static let outlineAlpha = 0.60
    static let outlineStep: CGFloat = 2
    static let outlineOffsets: [CGPoint] = [
        .init(x: 0, y: -outlineStep), .init(x: 0, y: outlineStep),
        .init(x: -outlineStep, y: 0), .init(x: outlineStep, y: 0),
        .init(x: -outlineStep, y: -outlineStep), .init(x: outlineStep, y: -outlineStep),
        .init(x: -outlineStep, y: outlineStep), .init(x: outlineStep, y: outlineStep),
    ]
    static let mowPitch: CGFloat = 15
    static let mowLight = 0.035
    static let mowDark = 0.06
    static let sheenOurs = 0.055
    static let sheenTheirs = 0.06
    static let falloff = 0.52
    static let falloffRadius: CGFloat = 1.3
    static let grainOpacity = 0.5
}

private enum Mark {
    static let paintBlur: CGFloat = 0.2
    static let ringWidth: CGFloat = 3
    static let ringAlpha = 0.30
    static let innerRingAlpha = 0.15
    static let glyphAlpha = 0.42
    static let captionAlpha = 0.34
    static let regularDiameter: CGFloat = 106
    static let regularInner: CGFloat = 94
    static let conferenceDiamond: CGFloat = 74
    static let conferenceInner: CGFloat = 52
    static let conferenceStroke: CGFloat = 3
    static let bowlSize: CGFloat = 82
    static let playoffHeight: CGFloat = 120
    static let bracketWidth: CGFloat = 22
    static let bracketDepth: CGFloat = 20
    static let bracketGap: CGFloat = 40
    static let championshipDiameter: CGFloat = 128
    static let championshipInner: CGFloat = 112
    static let starSize: CGFloat = 22
}

private enum Token {
    static let diameter: CGFloat = 15
    /// Below `04` section 6.2's 12 pt authored floor, and permitted there only as a tracked
    /// uppercase micro-label — which a position shorthand is. It never carries prose.
    static let labelSize: CGFloat = 9
    static let labelScaleFloor: CGFloat = 0.7
    static let shadowAlpha = 0.55
    static let shadowRadius: CGFloat = 10
}

private enum Ball {
    static let width: CGFloat = 17
    static let height: CGFloat = 10
    static let apexScale: CGFloat = 1.7
    static let tilt: Double = 21
    static let lift: CGFloat = 17
    static let markAlpha = 0.82
    static let stripes: [CGFloat] = [3.4, 12.2]
    static let stripeWidth: CGFloat = 1.4
    static let stripeHeight: CGFloat = 6
    static let stripeTop: CGFloat = 2
    static let laceX: CGFloat = 6.4
    static let laceY: CGFloat = 4.4
    static let laceWidth: CGFloat = 4.6
    static let laceHeight: CGFloat = 1.3
    static let laceTicks: [CGFloat] = [7.2, 9.6]
    static let tickWidth: CGFloat = 1
    static let tickHeight: CGFloat = 3.6
    static let tickTop: CGFloat = 3.2
    static let shadowWidth: CGFloat = 20
    static let shadowHeight: CGFloat = 9
    static let shadowBlur: CGFloat = 2.5
    static let shadowAlpha = 0.62
    static let shadowFade = 0.07
    static let shadowRestScale: CGFloat = 0.78
    static let shadowDrop: CGFloat = 7
    static let glowWidth: CGFloat = 26
    static let glowHeight: CGFloat = 20
    static let glowAlpha = 0.34
    static let glowRestScale: CGFloat = 0.9
    static let glowApexScale: CGFloat = 1.5

    /// The pointed silhouette the design specifies as a clip path — two curves meeting at a point
    /// at each end. An ellipse is the shape this replaces, and the difference is the whole reason
    /// the ball reads as a football.
    static let silhouette = Ball.Lens()

    struct Lens: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.minX + w * x / Ball.width, y: rect.minY + h * y / Ball.height)
            }
            var path = Path()
            path.move(to: p(0.6, 5))
            path.addCurve(to: p(16.4, 5), control1: p(4, 0.3), control2: p(13, 0.3))
            path.addCurve(to: p(0.6, 5), control1: p(13, 9.7), control2: p(4, 9.7))
            path.closeSubpath()
            return path
        }
    }
}
