import SwiftUI

// The scorebug and the furniture it shares a corner with: five variants chosen by `MatchGameKind`,
// per handoff MATCH-DAY.md section 3, plus the top-right stack section 5 draws beside it.

/// The possession wedge and the committing action's mark, `04` section 6.6's "Broadcast marks"
/// class: two drawn shapes, not SF Symbols, capped at two members and never counted alone —
/// both always sit beside a printed value. A `Shape` rather than `Image(systemName:)` because the
/// symbol-register scan reads `systemName:` literals, and a drawn wedge is what the register
/// itself says these are.
struct BroadcastWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The top-left glass bug: our cell, their cell, the clock cell, and — for every kind but
/// `.regular` — a band naming the event above or below the row.
struct ScoreBug: View {
    let model: MatchDayReadModel
    let quarterLabel: String
    let clockLabel: String
    let downDistance: String
    let spot: String

    private var kind: MatchGameKind { model.kind }
    private var event: MatchDayReadModel.EventBadge? { model.event }

    var body: some View {
        VStack(spacing: .zero) {
            if kind == .conference, let event { band(event, placement: .above) }
            row
            if kind == .playoff, let event { band(event, placement: .below) }
            if kind == .championship { Rectangle().fill(Bug.goldRule).frame(height: Bug.hairline) }
        }
        .coachWorldFloodlitPanel(
            fill: ground.opacity(Bug.groundAlpha),
            border: border,
            depth: .deep,
            shape: CoachWorldCutCorner.card
        )
        .overlay(alignment: .top) {
            if kind == .playoff {
                Rectangle().fill(CoachWorldTokens.dark.stateNegative.color).frame(height: 2)
                    .clipShape(CoachWorldCutCorner.card)
            }
        }
        .frame(maxWidth: Bug.maxWidth)
        .shadow(color: .black.opacity(Bug.shadowAlpha), radius: Bug.shadowRadius, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(model.away.team.name) \(model.away.score), \(model.home.team.name) \(model.home.score), "
                + "\(quarterLabel), \(clockLabel), \(downDistance), \(spot)"
                + (event.map { ", \($0.title)" } ?? "")
        )
    }

    private var row: some View {
        // Our cell, their cell, clock cell — the handoff's stated order, which is by perspective
        // and not by who owns the venue. Ordering by `home`/`away` put the opponent first on every
        // home game.
        let ours: MatchSide = model.perspective
        let theirs: MatchSide = ours == .home ? .away : .home
        return HStack(spacing: .zero) {
            cell(score(for: ours), side: ours)
            cell(score(for: theirs), side: theirs)
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text("\(quarterLabel) · \(clockLabel)")
                    .font(CoachWorldTokens.figure(Bug.clock, weight: .semibold))
                    .foregroundStyle(CoachWorldTokens.dark.contentPrimary.color)
                Text("\(downDistance.uppercased()) · \(spot.uppercased())")
                    .font(CoachWorldTokens.display(Bug.subline, weight: .semibold))
                    .tracking(CoachWorldTokens.DisplaySize.tracking(0.14, at: Bug.subline))
                    .foregroundStyle(CoachWorldTokens.dark.contentSecondary.color)
            }
            .fixedSize()
            .padding(.horizontal, CoachWorldTokens.Pad.card.h)
            .frame(minHeight: Bug.rowHeight, alignment: .leading)
        }
    }

    private func score(for side: MatchSide) -> MatchDayReadModel.TeamScore {
        side == .home ? model.home : model.away
    }

    /// `side` is which physical side of the game this cell is (which decides possession and
    /// draw order); `isOurs` is whether it is the coach's own program (which decides styling).
    /// The two are independent — an away game keeps `side == .away` but `isOurs == true`.
    private func cell(_ score: MatchDayReadModel.TeamScore, side: MatchSide) -> some View {
        let hasBall = model.situation.possession == side
        let isOurs = side == model.perspective
        return HStack(spacing: CoachWorldTokens.Gap.xs) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text(score.team.abbreviation.uppercased())
                    .font(CoachWorldTokens.display(Bug.name, weight: .bold))
                if let subline = score.subline {
                    Text(subline)
                        .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .semibold))
                        .foregroundStyle(cellInk(isOurs).opacity(0.7))
                }
            }
            if let seed = score.seed {
                Text("\(seed)")
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                    .foregroundStyle(CoachWorldTokens.Floodlit.liveInk.color)
                    .padding(.horizontal, CoachWorldTokens.Gap.xxs)
                    .overlay {
                        Capsule().stroke(
                            CoachWorldTokens.dark.stateNegative.color.opacity(0.5),
                            lineWidth: CoachWorldTokens.Shape.hairline
                        )
                    }
                    .accessibilityLabel("Seed \(seed)")
            }
            Text("\(score.score)")
                .font(CoachWorldTokens.figure(scoreSize, weight: .bold))
                .foregroundStyle(cellInk(isOurs))
            // Trails the score, per the handoff's stated cell order (rail, name, score, triangle).
            if hasBall {
                BroadcastWedge()
                    .fill(CoachWorldTokens.dark.actionPrimary.color)
                    .frame(width: Bug.possessionSize, height: Bug.possessionSize)
                    .accessibilityHidden(true)
            }
        }
        .fixedSize()
        .foregroundStyle(cellInk(isOurs))
        .padding(.horizontal, CoachWorldTokens.Pad.card.h)
        .frame(minHeight: Bug.rowHeight, alignment: .leading)
        .background(isOurs ? goldRail : nil, alignment: .leading)
        .background(cellGround(isOurs))
    }

    private var goldRail: some View {
        Rectangle().fill(CoachWorldTokens.dark.actionPrimary.color).frame(width: Bug.railWidth)
    }

    private func cellGround(_ isOurs: Bool) -> some View {
        Group {
            if isOurs {
                if let identity {
                    identity.field.color.opacity(0.30)
                } else {
                    CoachWorldTokens.Floodlit.clubField.color.opacity(0.30)
                }
            } else {
                CoachWorldTokens.Floodlit.opponentField.color.opacity(0.5)
            }
        }
    }

    private func cellInk(_ isOurs: Bool) -> Color {
        if isOurs {
            CoachWorldTokens.dark.actionPrimary.color
        } else {
            CoachWorldTokens.Floodlit.opponentAccent.color
        }
    }

    /// Our own team's colours — never the opponent's, whatever the opponent's real pair is. The
    /// design's "their cell" is a fixed neutral navy regardless of who they are.
    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: model.perspective == .home ? model.home.team : model.away.team,
            behind: CoachWorldTokens.Floodlit.roomDeep,
            inks: [CoachWorldTokens.dark.contentPrimary, CoachWorldTokens.Floodlit.goldInk]
        )
    }

    private enum BandPlacement { case above, below }

    private func band(_ event: MatchDayReadModel.EventBadge, placement: BandPlacement) -> some View {
        VStack(spacing: CoachWorldTokens.Gap.hair) {
            Text(event.title.uppercased())
                .font(CoachWorldTokens.display(Bug.bandTitle, weight: .bold))
                .tracking(CoachWorldTokens.DisplaySize.tracking(0.18, at: Bug.bandTitle))
            if let subtitle = event.subtitle {
                Text(subtitle.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .semibold))
                    .foregroundStyle(bandInk.opacity(0.75))
            }
        }
        .foregroundStyle(bandInk)
        .padding(.vertical, CoachWorldTokens.Gap.xxs)
        .frame(maxWidth: .infinity)
        .background(bandGround)
    }

    private var bandInk: Color {
        switch kind {
        case .conference: CoachWorldTokens.Floodlit.opponentAccent.color
        case .playoff: CoachWorldTokens.Floodlit.liveInk.color
        default: CoachWorldTokens.dark.contentSecondary.color
        }
    }

    private var bandGround: Color {
        switch kind {
        case .conference: CoachWorldTokens.Floodlit.opponentAccent.color.opacity(0.16)
        case .playoff: CoachWorldTokens.dark.stateNegative.color.opacity(0.14)
        default: .clear
        }
    }

    private var ground: Color {
        switch kind {
        case .bowl: Color(red: 14 / 255, green: 10 / 255, blue: 6 / 255)
        default: CoachWorldTokens.Floodlit.roomDeep.color
        }
    }

    private var border: Color {
        switch kind {
        case .conference: CoachWorldTokens.Floodlit.opponentAccent.color.opacity(0.34)
        case .bowl: CoachWorldTokens.dark.actionPrimary.color.opacity(0.35)
        case .championship: CoachWorldTokens.dark.actionPrimary.color.opacity(0.55)
        default: Color.white.opacity(CoachWorldTokens.Glass.line)
        }
    }

    private var scoreSize: CGFloat {
        switch kind {
        case .bowl: 23
        case .championship: 26
        default: 21
        }
    }
}

private enum Bug {
    static let maxWidth: CGFloat = 340
    static let rowHeight: CGFloat = 34
    static let name: CGFloat = 13
    /// Clock 14, down-and-spot 10 — the handoff's stated clock-cell sizes. These were 19 and 14,
    /// which wrapped "1ST & 10 · CAR BALL" onto a second line and made the whole bug twice its
    /// drawn height.
    static let clock: CGFloat = 14
    static let subline: CGFloat = 10
    static let bandTitle: CGFloat = 9
    static let railWidth: CGFloat = 3
    static let groundAlpha = 0.88
    static let shadowAlpha = 0.72
    static let shadowRadius: CGFloat = 20
    static let hairline: CGFloat = 1
    static let possessionSize: CGFloat = 7
    static let goldRule = Color(red: 216 / 255, green: 151 / 255, blue: 19 / 255).opacity(0.35)
    /// The committing action's own glow — `glow-gold` from the token table, `04` section 6.1b.
    static let actionGlowRadius: CGFloat = 26
    static let actionGlowYOffset: CGFloat = 2
}

// MARK: - Top-right stack

/// "18 OF 25", the three marks, and the rate note beneath.
struct CallInBudgetBug: View {
    let budget: MatchDayReadModel.CallInBudget

    var body: some View {
        VStack(alignment: .trailing, spacing: CoachWorldTokens.Gap.xxs) {
            HStack(spacing: CoachWorldTokens.Gap.xxs) {
                Text("CALL-INS")
                    .font(CoachWorldTokens.display(Budget.label, weight: .bold))
                    .tracking(CoachWorldTokens.DisplaySize.tracking(0.18, at: Budget.label))
                    .foregroundStyle(CoachWorldTokens.dark.contentSecondary.color)
                Spacer(minLength: CoachWorldTokens.Gap.sm)
                HStack(spacing: CoachWorldTokens.Gap.hair) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: Budget.markCorner)
                            .fill(index < budget.marks
                                ? CoachWorldTokens.dark.actionPrimary.color
                                : CoachWorldTokens.dark.actionPrimary.color.opacity(0.12))
                            .overlay {
                                RoundedRectangle(cornerRadius: Budget.markCorner).stroke(
                                    CoachWorldTokens.dark.actionPrimary.color.opacity(0.55),
                                    lineWidth: CoachWorldTokens.Shape.hairline
                                )
                            }
                            .frame(width: Budget.markWidth, height: Budget.markHeight)
                    }
                }
                .accessibilityHidden(true)
                Text("\(budget.used) OF \(budget.total)")
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.lead, weight: .bold))
                    .foregroundStyle(CoachWorldTokens.dark.actionPrimary.color)
            }
            Text(budget.rateNote.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .semibold))
                .tracking(CoachWorldTokens.DisplaySize.tracking(0.12, at: CoachWorldTokens.DisplaySize.flag))
                .foregroundStyle(CoachWorldTokens.dark.contentQuiet.color)
        }
        // Hugs its content. Without this the `Spacer` above is greedy: the bug stretched to the
        // full frame width and, drawn after the scorebug in the ZStack, painted straight over it —
        // the whole top-left scorebug vanished. The spacer collapses to its `minLength` here, which
        // is the gap the design actually asks for between the label and the marks.
        .fixedSize(horizontal: true, vertical: false)
        .padding(.vertical, CoachWorldTokens.Pad.card.v)
        .padding(.horizontal, CoachWorldTokens.Pad.card.h)
        .coachWorldFloodlitPanel(
            fill: CoachWorldTokens.Floodlit.roomDeep.color.opacity(0.86),
            border: Color.white.opacity(CoachWorldTokens.Glass.line),
            depth: .deep,
            shape: CoachWorldCutCorner.card
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Call-ins, \(budget.used) of \(budget.total). \(budget.rateNote)")
    }

    private enum Budget {
        static let label: CGFloat = 10
        static let markWidth: CGFloat = 9
        static let markHeight: CGFloat = 15
        static let markCorner: CGFloat = 1
    }
}

/// The three-cell selector that sets `MatchControlDepth`.
///
/// `onSelect` fires the same signal regardless of which cell was tapped, matching the convention
/// every other Match Day control already follows: one intent per control, with the provider
/// deciding what it means. Which exact value a tap should choose is provider wiring the handoff
/// does not specify.
struct ControlDepthSelector: View {
    let depth: MatchControlDepth
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(MatchControlDepth.allCases, id: \.self) { candidate in
                Button(action: onSelect) {
                    Text(title(candidate))
                        .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                        .tracking(
                            CoachWorldTokens.DisplaySize.tracking(0.1, at: CoachWorldTokens.DisplaySize.flag)
                        )
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                }
                .foregroundStyle(depth == candidate
                    ? CoachWorldTokens.dark.contentPrimary.color
                    : CoachWorldTokens.dark.contentSecondary.color)
                .overlay {
                    if depth == candidate {
                        Rectangle().stroke(
                            CoachWorldTokens.dark.actionPrimary.color,
                            lineWidth: CoachWorldTokens.Shape.hairline
                        )
                    }
                }
                .accessibilityLabel(title(candidate))
                .accessibilityAddTraits(depth == candidate ? .isSelected : [])
            }
        }
        .coachWorldFloodlitPanel(
            fill: CoachWorldTokens.Floodlit.roomDeep.color.opacity(0.86),
            border: Color.white.opacity(CoachWorldTokens.Glass.line),
            depth: .deep,
            shape: CoachWorldCutCorner.card
        )
    }

    private func title(_ depth: MatchControlDepth) -> String {
        switch depth {
        case .everySnap: "EVERY SNAP"
        case .coordinator: "COORD"
        case .leverage: "LEVERAGE"
        }
    }
}

// MARK: - Lower third

/// The phase, the actor and headline, and clamped commentary. No coloured left border — Floodlit
/// forbids one here.
///
/// `phase` and `isLive` are presentation state the caller derives from where the animation clock
/// sits (`04` section 9's PRE-SNAP / SNAP / RESULT frames): this component renders what it is
/// told rather than re-deriving a state machine from the read model.
struct MatchLowerThird: View {
    let model: MatchDayReadModel
    let phase: String
    let isLive: Bool
    let headline: String?
    /// The handoff's right-aligned "← WEEK" link. Optional because it is the one piece of
    /// navigation on this surface: when no caller supplies a way out, none is drawn rather than a
    /// dead control.
    var onExit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            HStack(spacing: CoachWorldTokens.Gap.xs) {
                Text(phase.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                    .tracking(
                        CoachWorldTokens.DisplaySize.tracking(0.18, at: CoachWorldTokens.DisplaySize.flag)
                    )
                    .foregroundStyle(CoachWorldTokens.dark.actionPrimary.color)
                if isLive {
                    LiveDot()
                    Text("IN PLAY")
                        .font(
                            CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                        )
                        .foregroundStyle(CoachWorldTokens.Floodlit.liveInk.color)
                }
                if let onExit {
                    Spacer(minLength: CoachWorldTokens.Gap.smPlus)
                    Button(action: onExit) {
                        Text("← WEEK")
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.flag, weight: .bold
                                )
                            )
                            .tracking(
                                CoachWorldTokens.DisplaySize
                                    .tracking(0.18, at: CoachWorldTokens.DisplaySize.flag)
                            )
                            .foregroundStyle(CoachWorldTokens.dark.contentSecondary.color)
                            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                    }
                    .accessibilityLabel("Back to the week")
                }
            }
            if let actor = model.foregroundActorIDs.first,
               let entry = model.actors.first(where: { $0.stableID == actor }),
               let headline {
                Text("\(entry.uniformNumber) \(entry.position) · \(headline)")
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Text(model.causalCommentary)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(CoachWorldTokens.dark.contentSecondary.color)
                .lineLimit(2)
        }
        .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        .padding(.horizontal, CoachWorldTokens.Pad.panel.h)
        .frame(maxWidth: .infinity, alignment: .leading)
        .coachWorldFloodlitPanel(
            fill: CoachWorldTokens.Floodlit.roomDeep.color.opacity(0.80),
            border: Color.white.opacity(CoachWorldTokens.Glass.line),
            depth: .deep,
            shape: CoachWorldCutCorner.card
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(phase). \(model.playback?.sentence ?? model.causalCommentary)"
        )
    }
}

private struct LiveDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(CoachWorldTokens.dark.stateNegative.color)
            .frame(width: 5, height: 5)
            .opacity(pulsing ? 0.4 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - The committing action

/// The one gold, glowing control: `Snap it` / `Play on` / `Next snap`, bottom-right in the thumb
/// arc. The only ambient glow in the system that is not the week ribbon's lamp pulse.
struct CommittingAction: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CoachWorldTokens.Gap.xs) {
                Text(title.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.action, weight: .bold))
                // The key-moment mark, `04` section 6.6's second Broadcast member.
                BroadcastWedge()
                    .fill(CoachWorldTokens.Floodlit.goldInk.color)
                    .frame(width: 10, height: 13)
            }
            .frame(minWidth: 120, minHeight: CoachWorldTokens.Shape.minimumTarget)
            .padding(.horizontal, CoachWorldTokens.Gap.lg)
        }
        .foregroundStyle(CoachWorldTokens.Floodlit.goldInk.color)
        .background(CoachWorldTokens.Floodlit.goldField)
        .clipShape(CoachWorldCutCorner.action)
        .shadow(
            color: CoachWorldTokens.dark.actionPrimary.color.opacity(0.45),
            radius: Bug.actionGlowRadius, y: Bug.actionGlowYOffset
        )
        .accessibilityLabel(title)
    }
}
