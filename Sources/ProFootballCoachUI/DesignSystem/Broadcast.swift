import SwiftUI

// MARK: - Registry 20: ScoreBug

/// Teams, score, quarter, clock, down, distance and possession — `04` §6.5 registry 20.
///
/// BROADCAST furniture: square geometry (`04` §6.3 fixes the broadcast radius at 0) and the
/// compressed numeral role, which §6.2 permits here and nowhere else. It overlays a dead margin of
/// the field frame — no management furniture appears on the field itself (`04` §9).
///
/// The possession wedge is one of §6.6's three Broadcast marks, so it **never counts alone**: the
/// spoken sentence says which side has the ball in words.
public struct ScoreBug: View {
    public struct Side: Sendable {
        public let abbreviation: String
        public let name: String
        public let score: Int
        public let fill: Color
        public let ink: Color
        public let hasPossession: Bool

        public init(
            abbreviation: String,
            name: String,
            score: Int,
            fill: Color,
            ink: Color,
            hasPossession: Bool
        ) {
            self.abbreviation = abbreviation
            self.name = name
            self.score = score
            self.fill = fill
            self.ink = ink
            self.hasPossession = hasPossession
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let home: Side
    private let away: Side
    private let period: String
    private let clock: String
    private let situation: String
    private let isClockStopped: Bool

    public init(
        home: Side,
        away: Side,
        period: String,
        clock: String,
        situation: String,
        isClockStopped: Bool = false
    ) {
        self.home = home
        self.away = away
        self.period = period
        self.clock = clock
        self.situation = situation
        self.isClockStopped = isClockStopped
    }

    public var body: some View {
        HStack(spacing: .zero) {
            cell(home)
            cell(away)
            situationBand
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private func cell(_ side: Side) -> some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            if side.hasPossession {
                PossessionWedge()
                    .fill(side.ink)
                    .frame(width: CoachWorldTokens.Space.xs, height: CoachWorldTokens.Space.sm)
                    .accessibilityHidden(true)
            }
            Text(side.abbreviation)
                .font(CoachWorldTokens.TypeRole.display(CoachWorldTokens.Control.actionTextSize))
            Spacer(minLength: CoachWorldTokens.Space.sm)
            Text("\(side.score)")
                .font(CoachWorldTokens.TypeRole.displayFigures(
                    CoachWorldTokens.Control.actionTextSize
                ))
        }
        .foregroundStyle(side.ink)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(side.fill)
        // `04` §6.1 makes the boundary mandatory on every team fill: generated colour cannot be
        // assumed to clear the non-text floor against any surface.
        .overlay(Rectangle().strokeBorder(
            palette.contentSecondary.color,
            lineWidth: CoachWorldTokens.Shape.hairline
        ))
    }

    private var situationBand: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text("\(period) · \(clock)")
                .font(CoachWorldTokens.TypeRole.figures(CoachWorldTokens.Table.cellTextSize, .bold))
                .foregroundStyle(palette.contentPrimary.color)
            Text(situation)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(1)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(palette.page.color)
    }

    private var spoken: String {
        let possession = home.hasPossession ? home.name : away.name
        let clockPhrase = isClockStopped ? "clock stopped" : clock
        return "\(home.name) \(home.score), \(away.name) \(away.score). "
            + "\(period), \(clockPhrase). \(situation). \(possession) ball."
    }
}

/// The possession mark — §6.6 Broadcast marks, member one of three.
struct PossessionWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Registry 21: LowerThird

/// The causal what-just-happened card — `04` §6.5 registry 21.
///
/// One named actor, one thing that happened, and why it matters. `04` §9's one-named-actor rule:
/// the field names exactly one protagonist per moment, and this card is where they are met. Between
/// moments the card is **absent** rather than empty — the field is the empty state.
public struct LowerThird: View {
    @Environment(\.coachWorldPalette) private var palette

    private let uniformNumber: String
    private let actor: String
    private let actorDetail: String
    private let event: String
    private let consequence: String
    private let plate: AnyView?

    public init(
        uniformNumber: String,
        actor: String,
        actorDetail: String,
        event: String,
        consequence: String,
        plate: AnyView? = nil
    ) {
        self.uniformNumber = uniformNumber
        self.actor = actor
        self.actorDetail = actorDetail
        self.event = event
        self.consequence = consequence
        self.plate = plate
    }

    public var body: some View {
        GlassPanel(shape: .row, depth: .deep) {
            HStack(spacing: CoachWorldTokens.Space.sm) {
                Text(uniformNumber)
                    .font(CoachWorldTokens.TypeRole.displayFigures(
                        CoachWorldTokens.Control.actionTextSize
                    ))
                    .foregroundStyle(palette.contentPrimary.color)
                if let plate { plate }
                VStack(alignment: .leading, spacing: .zero) {
                    Text(actor.uppercased())
                        .font(CoachWorldTokens.TypeRole.headline)
                        .foregroundStyle(palette.contentPrimary.color)
                    Text(actorDetail)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                Rectangle()
                    .fill(palette.contentQuiet.color)
                    .frame(width: CoachWorldTokens.Shape.hairline)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: .zero) {
                    Text(event)
                        .font(CoachWorldTokens.TypeRole.headline)
                        .foregroundStyle(palette.fieldLive.color)
                    Text(consequence)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(CoachWorldTokens.Space.sm)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(actor), number \(uniformNumber), \(actorDetail): \(event). \(consequence)"
        )
    }
}

// MARK: - Registry 22: CallInCard

/// A named staff proposal — accept, dismiss, or inspect the evidence. Registry 22.
///
/// `04` §3: decisions push in, menus stay out. Exactly three actions, never a fourth, each at the
/// 44 pt floor. **A cost is a fact, not a warning** — it takes `content.secondary` rather than
/// `state.warning`, because the printed word carries the meaning and colouring it amber would make
/// every trade-off read as a problem.
public struct CallInCard: View {
    public struct Action: Identifiable {
        public let id: String
        public let title: String
        public let cost: String?
        public let consequence: String?
        public let isAvailable: Bool
        /// Why it is unavailable — spoken, so "dimmed" is never the whole explanation.
        public let unavailableReason: String?
        public let isRecommended: Bool

        public init(
            id: String,
            title: String,
            cost: String? = nil,
            consequence: String? = nil,
            isAvailable: Bool = true,
            unavailableReason: String? = nil,
            isRecommended: Bool = false
        ) {
            self.id = id
            self.title = title
            self.cost = cost
            self.consequence = consequence
            self.isAvailable = isAvailable
            self.unavailableReason = unavailableReason
            self.isRecommended = isRecommended
        }
    }

    @Environment(\.coachWorldPalette) private var palette

    private let staffName: String
    private let staffRole: String
    private let proposal: String
    private let actions: [Action]
    private let plate: AnyView?
    private let onAct: (String) -> Void

    public init(
        staffName: String,
        staffRole: String,
        proposal: String,
        actions: [Action],
        plate: AnyView? = nil,
        onAct: @escaping (String) -> Void
    ) {
        self.staffName = staffName
        self.staffRole = staffRole
        self.proposal = proposal
        self.actions = actions
        self.plate = plate
        self.onAct = onAct
    }

    public var body: some View {
        GlassPanel(depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                CoachWorldFieldLabel("Staff call-in", tint: palette.stateWarning)
                HStack(spacing: CoachWorldTokens.Space.sm) {
                    if let plate { plate }
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(staffName)
                            .font(CoachWorldTokens.TypeRole.headline)
                            .foregroundStyle(palette.contentPrimary.color)
                        Text(staffRole)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                }
                Text(proposal)
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentPrimary.color)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(actions) { action in
                    actionRow(action)
                }
            }
            .padding(CoachWorldTokens.Space.sm)
        }
        .accessibilityElement(children: .contain)
    }

    private func actionRow(_ action: Action) -> some View {
        Button { onAct(action.id) } label: {
            VStack(alignment: .leading, spacing: .zero) {
                Text(action.title)
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentPrimary.color)
                if let cost = action.cost {
                    Text("Cost: \(cost)")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                if let consequence = action.consequence {
                    Text(consequence)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .overlay(CutCorner.row.strokeBorder(
                action.isRecommended
                    ? palette.actionPrimary.color
                    : CoachWorldTokens.Glass.edge.color,
                lineWidth: CoachWorldTokens.Shape.hairline
            ))
        }
        .buttonStyle(.plain)
        .disabled(!action.isAvailable)
        .accessibilityLabel(spoken(action))
    }

    /// The recommendation is carried by which action is boundary-marked *and* by the spoken word —
    /// never by colour alone (`04` §6.1).
    private func spoken(_ action: Action) -> String {
        var parts = [action.title]
        if action.isRecommended { parts.append("recommended by \(staffName)") }
        if let cost = action.cost { parts.append("cost: \(cost)") }
        if let consequence = action.consequence { parts.append(consequence) }
        if !action.isAvailable {
            parts.append(action.unavailableReason ?? "unavailable")
        }
        return parts.joined(separator: ". ")
    }
}
