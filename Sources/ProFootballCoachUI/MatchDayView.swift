import SwiftUI

public struct MatchDayView: View {
    public let model: MatchDayReadModel
    public let statusMessage: String?
    public let onControl: (CoachWorldIntentID) -> Void
    public let onInterruption: (CoachWorldIntentID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsEvidence = false

    public init(
        model: MatchDayReadModel,
        statusMessage: String? = nil,
        onControl: @escaping (CoachWorldIntentID) -> Void,
        onInterruption: @escaping (CoachWorldIntentID) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onControl = onControl
        self.onInterruption = onInterruption
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                standardLayout
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .sheet(isPresented: $showsEvidence) { evidenceSheet }
    }

    private var standardLayout: some View {
        VStack(spacing: .zero) {
            scorebug
            HStack(spacing: .zero) {
                field
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let interruption = model.staffInterruption {
                    ScrollView { interruptionRail(interruption) }
                        .frame(width: MatchMetric.callInWidth)
                }
            }
            lowerThird
            controlBar
        }
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: .zero) {
                accessibleScoreStrip
                field
                    .aspectRatio(MatchMetric.fieldAspect, contentMode: .fit)
                    .frame(height: MatchMetric.accessibleFieldHeight)
                lowerThird
                if let interruption = model.staffInterruption {
                    interruptionRail(interruption)
                }
                if let statusMessage {
                    Text(statusMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(CoachWorldTokens.Space.md)
                        .background(palette.raised.color)
                        .accessibilitySortPriority(65)
                }
                VStack(spacing: .zero) {
                    ForEach(orderedControls, id: \.id) { control in
                        controlButton(control)
                            .frame(maxWidth: .infinity)
                    }
                }
                .accessibilitySortPriority(60)
            }
        }
    }

    private var accessibleScoreStrip: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.md) {
                Text("\(model.away.team.abbreviation) \(model.away.score)  ·  "
                    + "\(model.home.team.abbreviation) \(model.home.score)")
                Spacer(minLength: .zero)
                Text("\(quarterLabel) · \(clockLabel)")
                    .monospacedDigit()
            }
            .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Text("\(ordinal(model.situation.down)) & \(model.situation.yardsToGo)"
                + " · \(possessionTeam.abbreviation) BALL · LIVE CHECKPOINT")
                .font(CoachWorldTokens.TypeRole.body.weight(.black))
        }
        .lineLimit(1)
        .minimumScaleFactor(MatchMetric.accessibleScoreScale)
        .padding(CoachWorldTokens.Space.sm)
        .frame(
            maxWidth: .infinity,
            minHeight: MatchMetric.accessibleScoreHeight,
            alignment: .leading
        )
        .background(palette.raised.color.opacity(0.96))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(model.away.team.name) \(model.away.score), "
                + "\(model.home.team.name) \(model.home.score), "
                + "\(quarterLabel), \(clockLabel), \(ordinal(model.situation.down)) and "
                + "\(model.situation.yardsToGo), \(possessionTeam.name) ball, live checkpoint"
        )
        .accessibilitySortPriority(100)
    }

    private var scorebug: some View {
        HStack(spacing: .zero) {
            scoreTeam(model.away, isHome: false)
            scoreTeam(model.home, isHome: true)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text("\(quarterLabel) · \(clockLabel)")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    .monospacedDigit()
                Text("\(ordinal(model.situation.down)) & \(model.situation.yardsToGo) · \(possessionTeam.abbreviation) BALL")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(maxWidth: .infinity, minHeight: MatchMetric.scorebugHeight,
                   alignment: .leading)
            Text("LIVE CHECKPOINT")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.stateLive.color)
                .padding(.horizontal, CoachWorldTokens.Space.sm)
        }
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(model.away.team.name) \(model.away.score), "
                + "\(model.home.team.name) \(model.home.score), "
                + "\(quarterLabel), \(clockLabel), \(ordinal(model.situation.down)) and "
                + "\(model.situation.yardsToGo), \(possessionTeam.name) ball, live checkpoint"
        )
        .accessibilitySortPriority(100)
    }

    private func scoreTeam(_ score: MatchDayReadModel.TeamScore, isHome: Bool) -> some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            Text(score.team.abbreviation)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Text("\(score.score)")
                .font(CoachWorldTokens.TypeRole.title.weight(.black))
                .monospacedDigit()
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: MatchMetric.scorebugHeight)
        .foregroundStyle(isHome ? palette.page.color : palette.contentPrimary.color)
        .background(isHome ? palette.collegeIdentity.color : palette.work.color)
        .overlay(alignment: .trailing) { verticalSeam }
    }

    private var field: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .topLeading) {
                fieldSurface
                endZone(at: .leading, size: size, label: leftEndZoneTeam.abbreviation)
                endZone(at: .trailing, size: size, label: rightEndZoneTeam.abbreviation)
                fieldMarker(
                    x: size.width * CGFloat(model.lineOfScrimmage / 120),
                    height: size.height,
                    color: palette.fieldAnnotation.color,
                    label: "Line of scrimmage"
                )
                fieldMarker(
                    x: size.width * CGFloat(model.firstDownLine / 120),
                    height: size.height,
                    color: palette.fieldLive.color,
                    label: "First-down line"
                )
                ForEach(model.actors, id: \.stableID) { actor in
                    actorMark(actor, size: size)
                }
            }
        }
        .aspectRatio(MatchMetric.fieldAspect, contentMode: .fit)
        .background(palette.fieldTurf.color)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilitySortPriority(80)
    }

    private var fieldSurface: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.fieldTurf.color))

            for index in 0..<12 where index.isMultiple(of: 2) {
                let band = CGRect(
                    x: size.width * CGFloat(index) / 12,
                    y: .zero,
                    width: size.width / 12,
                    height: size.height
                )
                context.fill(Path(band), with: .color(palette.fieldLine.color.opacity(0.035)))
            }

            for index in 0...12 {
                let x = size.width * CGFloat(index) / 12
                var rule = Path()
                rule.move(to: CGPoint(x: x, y: .zero))
                rule.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    rule,
                    with: .color(palette.fieldLine.color.opacity(0.42)),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }

            for yard in 10...110 {
                let x = size.width * CGFloat(yard) / 120
                for yFraction in MatchMetric.hashYFractions {
                    let y = size.height * yFraction
                    var hash = Path()
                    hash.move(to: CGPoint(x: x, y: y - MatchMetric.hashHalfHeight))
                    hash.addLine(to: CGPoint(x: x, y: y + MatchMetric.hashHalfHeight))
                    context.stroke(
                        hash,
                        with: .color(palette.fieldLine.color.opacity(0.52)),
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
                }
            }

            for fieldYard in stride(from: 20, through: 100, by: 10) {
                let displayYard = fieldYard <= 60 ? fieldYard - 10 : 110 - fieldYard
                let label = context.resolve(
                    Text("\(displayYard)")
                        .font(.system(size: CoachWorldTokens.TypeRole.authoredFloor, weight: .bold))
                        .foregroundStyle(palette.fieldLine.color.opacity(0.72))
                )
                let x = size.width * CGFloat(fieldYard) / 120
                context.draw(label, at: CGPoint(x: x, y: size.height * 0.18))
                context.draw(label, at: CGPoint(x: x, y: size.height * 0.82))
            }
        }
        .accessibilityHidden(true)
    }

    private func endZone(at alignment: Alignment, size: CGSize, label: String) -> some View {
        Text(label)
            .font(.system(size: CoachWorldTokens.TypeRole.authoredFloor, weight: .black))
            .foregroundStyle(palette.fieldLine.color)
            .frame(width: size.width / 12, height: size.height)
            .background(palette.page.color.opacity(0.28))
            .frame(maxWidth: .infinity, alignment: alignment)
            .accessibilityHidden(true)
    }

    private func fieldMarker(
        x: CGFloat,
        height: CGFloat,
        color: Color,
        label: String
    ) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: MatchMetric.markerWidth, height: height)
            .offset(x: x - MatchMetric.markerWidth / 2)
            .accessibilityLabel(label)
    }

    private func actorMark(_ actor: MatchDayReadModel.Actor, size: CGSize) -> some View {
        let foreground = model.foregroundActorIDs.contains(actor.stableID)
        let offense = actor.side == model.situation.possession
        return Text(actor.uniformNumber)
            .font(.system(size: CoachWorldTokens.TypeRole.authoredFloor, weight: .black))
            .foregroundStyle(
                actor.side == .home ? palette.page.color : palette.contentPrimary.color
            )
            .frame(width: MatchMetric.actorSize, height: MatchMetric.actorSize)
            .background(actor.side == .home ? palette.collegeIdentity.color : palette.raised.color)
            .overlay {
                Circle().stroke(
                    foreground ? palette.fieldLive.color : palette.fieldLine.color,
                    lineWidth: foreground
                        ? MatchMetric.foregroundStroke
                        : CoachWorldTokens.Shape.hairline
                )
            }
            .clipShape(Circle())
            .position(
                x: size.width * CGFloat(actor.xYardsFromLeftGoalLine / 120),
                y: size.height * CGFloat(actor.yFraction)
            )
            .accessibilityLabel(
                "\(offense ? "Offense" : "Defense"), \(actor.position) "
                    + "number \(actor.uniformNumber), at yard \(Int(actor.xYardsFromLeftGoalLine))"
            )
    }

    private var lowerThird: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Text("WHY THIS PLAY")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.stateLive.color)
            Text(model.causalCommentary)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            Spacer(minLength: .zero)
            if !dynamicTypeSize.isAccessibilitySize, let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: MatchMetric.lowerThirdHeight, alignment: .leading)
        .background(palette.work.color)
        .overlay(alignment: .top) { seam }
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(70)
    }

    private var controlBar: some View {
        HStack(spacing: .zero) {
            ForEach(orderedControls, id: \.id) { control in
                controlButton(control)
            }
        }
        .frame(minHeight: MatchMetric.controlHeight)
        .background(palette.raised.color)
        .accessibilitySortPriority(60)
    }

    private func controlButton(_ control: MatchDayReadModel.ControlState) -> some View {
        let presentation = controlPresentation(control.id)
        let accessibilityLabel = control.value.map {
            "\(presentation.title), \($0)"
        } ?? presentation.title

        return Button {
            onControl(control.intentID)
        } label: {
            VStack(spacing: .zero) {
                Image(systemName: presentation.symbol)
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
                Text(presentation.title)
                    .font(.caption.weight(.bold))
                if let value = control.value { Text(value).font(.caption) }
            }
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(MatchControlButtonStyle(
            selected: control.isSelected,
            palette: palette
        ))
        .disabled(!control.isEnabled)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityAddTraits(control.isSelected ? .isSelected : [])
    }

    private func interruptionRail(
        _ interruption: MatchDayReadModel.StaffInterruption
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("STAFF CALL-IN")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.stateWarning.color)
            HStack(alignment: .top, spacing: CoachWorldTokens.Space.xs) {
                CoachWorldBlankPhotoPlate(
                    name: interruption.staff.name,
                    palette: palette,
                    width: 44,
                    height: 50
                )
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(interruption.staff.name).font(.headline.weight(.black))
                    Text(interruption.staff.role)
                        .font(.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
            }
            Text(interruption.message)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(interruption.actions.map(\.title).joined(separator: " · "))
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            ForEach(interruption.actions, id: \.path) { action in
                interruptionButton(action)
            }
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(palette.page.color)
        .overlay(alignment: .leading) { verticalSeam }
        .accessibilitySortPriority(90)
    }

    private func interruptionButton(
        _ action: MatchDayReadModel.StaffInterruption.Action
    ) -> some View {
        Button {
            onInterruption(action.intentID)
            if action.path == .inspectEvidence { showsEvidence = true }
        } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(action.title).font(.headline.weight(.black))
                Text(action.cost)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.stateWarning.color)
                Text(action.consequence)
                    .font(.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                   alignment: .leading)
            .padding(.horizontal, CoachWorldTokens.Space.xs)
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
        .overlay {
            Rectangle().stroke(
                action.path == .accept ? palette.actionPrimary.color : palette.contentQuiet.color,
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .accessibilityLabel(
            "\(action.title). Cost: \(action.cost). Consequence: \(action.consequence)"
        )
    }

    private var evidenceSheet: some View {
        NavigationStack {
            List(model.staffInterruption?.evidence ?? [], id: \.self, rowContent: Text.init)
                .navigationTitle("Call-in evidence")
                .toolbar { Button("Done") { showsEvidence = false } }
        }
    }

    private var orderedControls: [MatchDayReadModel.ControlState] {
        MatchDayControlID.allCases.compactMap { id in model.controls.first { $0.id == id } }
    }

    private var possessionTeam: CoachWorldTeamReference {
        model.situation.possession == .home ? model.home.team : model.away.team
    }

    private var defendingTeam: CoachWorldTeamReference {
        model.situation.possession == .home ? model.away.team : model.home.team
    }

    private var leftEndZoneTeam: CoachWorldTeamReference {
        model.offenseDirection == .leftToRight ? possessionTeam : defendingTeam
    }

    private var rightEndZoneTeam: CoachWorldTeamReference {
        model.offenseDirection == .leftToRight ? defendingTeam : possessionTeam
    }

    private var quarterLabel: String { "Q\(model.situation.quarter)" }

    private var clockLabel: String {
        String(
            format: "%d:%02d",
            model.situation.clockSecondsRemaining / 60,
            model.situation.clockSecondsRemaining % 60
        )
    }

    private func ordinal(_ value: Int) -> String {
        switch value {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "4th"
        }
    }

    private func controlPresentation(
        _ id: MatchDayControlID
    ) -> (title: String, symbol: String) {
        switch id {
        case .speed: ("Speed", "speedometer")
        case .pause: ("Pause", "pause.fill")
        case .keyMoments: ("Key Moments", "sparkles.tv")
        case .takeOver: ("Take Over", "hand.raised.fill")
        case .tactics: ("Tactics", "rectangle.3.group")
        }
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(height: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(width: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }
}

private struct MatchControlButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let selected: Bool
    let palette: CoachWorldTokens.Palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .foregroundStyle(selected ? palette.page.color : palette.contentPrimary.color)
            .background(selected ? palette.stateLive.color : palette.raised.color)
            .overlay {
                Rectangle().stroke(
                    palette.contentQuiet.color,
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
            .opacity(isEnabled ? 1 : 0.55)
            .brightness(configuration.isPressed ? -0.08 : 0)
    }
}

private enum MatchMetric {
    static let fieldAspect: CGFloat = 120 / 53.3
    static let scorebugHeight: CGFloat = 52
    static let lowerThirdHeight: CGFloat = 44
    static let controlHeight: CGFloat = 48
    static let callInWidth: CGFloat = 270
    static let actorSize: CGFloat = 20
    static let markerWidth: CGFloat = 3
    static let foregroundStroke: CGFloat = 3
    static let accessibleScoreHeight: CGFloat = 64
    static let accessibleFieldHeight: CGFloat = 250
    static let accessibleScoreScale: CGFloat = 0.5
    static let hashHalfHeight: CGFloat = 3
    static let hashYFractions: [CGFloat] = [0.36, 0.64]
}
