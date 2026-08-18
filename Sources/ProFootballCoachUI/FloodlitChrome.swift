import SwiftUI

// The shared management stage: world backdrop, identity header, icon rail, content, grain
// (`04` section 6.1c, `FLOODLIT-SURFACES.md` section 1).
//
// Every management surface renders inside `CoachWorldFloodlitSurface`. Match Day does not — it is
// the broadcast register and owns its whole frame (section 6.1b).
//
// Navigation lives in the identity header rather than in a rail or a tab bar: the family on the
// left, jump-to on the right. The icon rail names kinds of thing, not routes within a family.

// MARK: - Read model

/// What the chrome prints. Every field is a fact the provider holds; the chrome computes nothing
/// except layout, per `FLOODLIT-SURFACES.md` section 5's read-model seam.
public struct FloodlitChromeReadModel: Sendable, Equatable {
    /// Which backdrop this surface stands in. The single variable that changes per screen.
    public enum World: String, CaseIterable, Sendable, Equatable {
        case pitch
        case facility
        /// The one place the light goes cold: a projector beam, and glass without the warm sheen.
        case film
    }

    /// One entry in the icon rail. `symbol` is an SF Symbol from `04` section 6.6's control
    /// furniture — a marked control read from its label, never a symbol to be learned.
    public struct RailEntry: Sendable, Equatable, Identifiable {
        public var id: CoachWorldScreenID { screen }
        public let screen: CoachWorldScreenID
        public let symbol: String
        /// Written sentence case; the rail uppercases on render.
        public let label: String
        public let intentID: CoachWorldIntentID

        public init(
            screen: CoachWorldScreenID,
            symbol: String,
            label: String,
            intentID: CoachWorldIntentID
        ) {
            self.screen = screen
            self.symbol = symbol
            self.label = label
            self.intentID = intentID
        }
    }

    /// A sibling surface in the current family — the header's second-row links.
    public struct Sibling: Sendable, Equatable, Identifiable {
        public var id: CoachWorldScreenID { screen }
        public let screen: CoachWorldScreenID
        public let title: String
        public let intentID: CoachWorldIntentID

        public init(screen: CoachWorldScreenID, title: String, intentID: CoachWorldIntentID) {
            self.screen = screen
            self.title = title
            self.intentID = intentID
        }
    }

    public let screen: CoachWorldScreenID
    public let world: World
    public let club: CoachWorldTeamReference
    /// `4-2`, already formatted with the en dash `04` section 6.1's copy rules ask for.
    public let record: String
    /// `#21`, or nil when the programme is unranked — an absent ranking is not a ranking of zero.
    public let ranking: String?
    /// Nil when the programme's conference is not retained on this route. An absent conference is
    /// not a wrong conference, so the header omits the slot rather than guessing.
    public let conference: String?
    /// The right-hand context chip: `Sat · Halloran Tech`.
    public let context: String?
    public let contextOpponent: CoachWorldTeamReference?
    public let rail: [RailEntry]
    public let siblings: [Sibling]

    public var family: CoachWorldSurfaceFamily { screen.family }
    public var showsIconRail: Bool { screen.showsIconRail }

    public init(
        screen: CoachWorldScreenID,
        world: World,
        club: CoachWorldTeamReference,
        record: String,
        ranking: String? = nil,
        conference: String? = nil,
        context: String? = nil,
        contextOpponent: CoachWorldTeamReference? = nil,
        rail: [RailEntry] = [],
        siblings: [Sibling] = []
    ) {
        self.screen = screen
        self.world = world
        self.club = club
        self.record = record
        self.ranking = ranking
        self.conference = conference
        self.context = context
        self.contextOpponent = contextOpponent
        self.rail = rail
        self.siblings = siblings
    }
}

// MARK: - World backdrop

/// `pitch | facility | film`, drawn from gradients and transforms only — `04` section 5 and the
/// handoff both forbid photography and illustration anywhere in the product.
struct CoachWorldWorldBackdrop: View {
    let world: FloodlitChromeReadModel.World
    let palette: CoachWorldTokens.Palette

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                LinearGradient(
                    colors: ground,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                lamp(size)
                Canvas(rendersAsynchronously: false) { context, canvasSize in
                    switch world {
                    case .pitch: Self.drawPitch(&context, canvasSize, palette: palette)
                    case .facility: Self.drawFacility(&context, canvasSize, palette: palette)
                    case .film: Self.drawFilm(&context, canvasSize, palette: palette)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        // The world is static per screen, so it rasterises once rather than recompositing behind
        // every content change. `BUILD.md`'s transformed-plane warning applies here as much as on
        // Match Day.
        .drawingGroup()
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var ground: [Color] {
        switch world {
        case .pitch: [palette.page.color, palette.work.color, palette.page.color]
        case .facility: [palette.page.color, CoachWorldTokens.Floodlit.roomDeep.color, palette.page.color]
        // Cold: the film room's ground loses the warm middle entirely.
        case .film: [CoachWorldTokens.Floodlit.roomDeep.color, palette.page.color, CoachWorldTokens.Floodlit.roomDeep.color]
        }
    }

    /// The single upper-left-ish light the whole system is lit by. Cold and centred for film.
    private func lamp(_ size: CGSize) -> some View {
        RadialGradient(
            colors: [lampColour.opacity(lampAlpha), .clear],
            center: world == .film ? UnitPoint(x: 0.5, y: -0.1) : UnitPoint(x: 0.78, y: 0.02),
            startRadius: 0,
            endRadius: size.width * Chrome.lampRadiusRatio
        )
    }

    private var lampColour: Color {
        world == .film
            ? CoachWorldTokens.dark.stateInfo.color
            : CoachWorldTokens.Floodlit.lamp.color
    }

    private var lampAlpha: Double {
        world == .film ? Chrome.filmLampAlpha : Chrome.lampAlpha
    }

    // MARK: worlds

    private static func drawPitch(
        _ context: inout GraphicsContext, _ size: CGSize, palette: CoachWorldTokens.Palette
    ) {
        var plane = Path()
        plane.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.42))
        plane.addLine(to: CGPoint(x: size.width * 0.86, y: size.height * 0.42))
        plane.addLine(to: CGPoint(x: size.width * 1.08, y: size.height * Chrome.bleed))
        plane.addLine(to: CGPoint(x: size.width * -0.08, y: size.height * Chrome.bleed))
        plane.closeSubpath()
        context.fill(
            plane,
            with: .linearGradient(
                Gradient(colors: [
                    palette.fieldTurf.color.opacity(0.12),
                    palette.fieldTurf.color.opacity(0.34),
                ]),
                startPoint: CGPoint(x: size.width / 2, y: size.height * 0.42),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )
        for index in 0..<7 {
            let progress = CGFloat(index) / 6
            let y = size.height * (0.47 + progress * 0.48)
            let inset = size.width * (0.16 - progress * 0.19)
            var line = Path()
            line.move(to: CGPoint(x: inset, y: y))
            line.addLine(to: CGPoint(x: size.width - inset, y: y))
            context.stroke(
                line,
                with: .color(palette.fieldLine.color.opacity(0.07)),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
    }

    /// A floor receding to a window band — the room a coach works in, not a stadium.
    private static func drawFacility(
        _ context: inout GraphicsContext, _ size: CGSize, palette: CoachWorldTokens.Palette
    ) {
        var floor = Path()
        floor.move(to: CGPoint(x: size.width * -0.08, y: size.height * 0.58))
        floor.addLine(to: CGPoint(x: size.width * 1.08, y: size.height * 0.58))
        floor.addLine(to: CGPoint(x: size.width * 1.16, y: size.height * Chrome.bleed))
        floor.addLine(to: CGPoint(x: size.width * -0.16, y: size.height * Chrome.bleed))
        floor.closeSubpath()
        context.fill(
            floor,
            with: .linearGradient(
                Gradient(colors: [
                    CoachWorldTokens.Floodlit.roomDeep.color.opacity(0.0),
                    CoachWorldTokens.Floodlit.roomDeep.color.opacity(0.55),
                ]),
                startPoint: CGPoint(x: size.width / 2, y: size.height * 0.58),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )
        // The window band: verticals, receding.
        for index in 0..<9 {
            let x = size.width * (0.06 + CGFloat(index) * 0.11)
            var mullion = Path()
            mullion.move(to: CGPoint(x: x, y: size.height * 0.05))
            mullion.addLine(to: CGPoint(x: x, y: size.height * 0.56))
            context.stroke(
                mullion,
                with: .color(palette.contentPrimary.color.opacity(0.04)),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
    }

    /// The projector beam and five fixed dust motes. Fixed, because a random mote is a different
    /// screen every launch and this product's determinism rule does not stop at the simulation.
    private static func drawFilm(
        _ context: inout GraphicsContext, _ size: CGSize, palette: CoachWorldTokens.Palette
    ) {
        var beam = Path()
        beam.move(to: CGPoint(x: size.width * 0.46, y: .zero))
        beam.addLine(to: CGPoint(x: size.width * 0.54, y: .zero))
        beam.addLine(to: CGPoint(x: size.width * 1.02, y: size.height * Chrome.bleed))
        beam.addLine(to: CGPoint(x: size.width * -0.02, y: size.height * Chrome.bleed))
        beam.closeSubpath()
        context.fill(
            beam,
            with: .linearGradient(
                Gradient(colors: [
                    palette.stateInfo.color.opacity(0.10),
                    palette.stateInfo.color.opacity(0.0),
                ]),
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )
        for mote in Chrome.dustMotes {
            let rect = CGRect(
                x: size.width * mote.x - mote.r / 2,
                y: size.height * mote.y - mote.r / 2,
                width: mote.r,
                height: mote.r
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(palette.contentPrimary.color.opacity(mote.alpha))
            )
        }
    }
}

// MARK: - Identity header

/// Two rows: who we are and how we are doing, then where in the family we are.
struct FloodlitIdentityHeader: View {
    let model: FloodlitChromeReadModel
    let palette: CoachWorldTokens.Palette
    let onNavigate: (CoachWorldIntentID) -> Void

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: model.club,
            behind: CoachWorldTokens.Floodlit.roomDeep,
            inks: [CoachWorldTokens.Floodlit.clubInk, CoachWorldTokens.dark.contentPrimary]
        )
    }

    private var clubField: Color {
        (identity?.field ?? CoachWorldTokens.Floodlit.clubField).color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            primaryRow
            Rectangle()
                .fill(CoachWorldTokens.dark.actionPrimary.color.opacity(Chrome.headerSeamAlpha))
                .frame(height: CoachWorldTokens.Shape.hairline)
            secondaryRow
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: clubField.opacity(0.92), location: 0),
                    .init(color: clubField.opacity(0.54), location: 0.5),
                    .init(color: clubField.opacity(0.16), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(CoachWorldTokens.dark.actionPrimary.color)
                .frame(width: Chrome.headerRail)
        }
        .overlay {
            CoachWorldCutCorner.headerBand.stroke(
                CoachWorldTokens.dark.actionPrimary.color.opacity(Chrome.headerRingAlpha),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .clipShape(CoachWorldCutCorner.headerBand)
    }

    private var primaryRow: some View {
        HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            CoachWorldPennant(team: model.club)
            Text(model.club.name.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.lead, weight: .bold))
                .tracking(Chrome.clubTracking)
                .foregroundStyle(CoachWorldTokens.Floodlit.clubInk.color)
                .lineLimit(1)
            Text(model.ranking.map { "\(model.record) · \($0)" } ?? model.record)
                .font(CoachWorldTokens.figure(Chrome.recordSize, weight: .semibold))
                .foregroundStyle(CoachWorldTokens.Floodlit.clubInk.color.opacity(0.78))
                .lineLimit(1)
            if let conference = model.conference {
                Text(conference.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .semibold))
                    .tracking(
                        CoachWorldTokens.DisplaySize.tracking(0.2, at: CoachWorldTokens.DisplaySize.flag)
                    )
                    .foregroundStyle(CoachWorldTokens.Floodlit.clubInk.color.opacity(0.70))
                    .lineLimit(1)
            }
            Spacer(minLength: CoachWorldTokens.Gap.smPlus)
            if let context = model.context {
                contextChip(context)
            }
        }
        .padding(.horizontal, CoachWorldTokens.Gap.md)
        .frame(minHeight: CoachWorldTokens.Stage.headerPrimaryRow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(primaryRowLabel)
    }


    /// Assembled in steps rather than as one chained expression — the chained form defeated the
    /// type checker outright.
    private var primaryRowLabel: String {
        var parts: [String] = ["\(model.club.name), \(model.record)"]
        if let ranking = model.ranking { parts.append("ranked \(ranking)") }
        if let conference = model.conference { parts.append(conference) }
        if let context = model.context { parts.append("Next: \(context)") }
        return parts.joined(separator: ", ")
    }

    private func contextChip(_ context: String) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.xxs) {
            if let opponent = model.contextOpponent {
                CoachWorldPennant(team: opponent)
            }
            Text(context.uppercased())
                .font(CoachWorldTokens.display(Chrome.contextSize, weight: .bold))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .foregroundStyle(CoachWorldTokens.Floodlit.clubInk.color)
        .padding(.horizontal, CoachWorldTokens.Gap.xs)
        .padding(.vertical, CoachWorldTokens.Gap.hair)
        .frame(maxWidth: Chrome.contextChipMaxWidth, alignment: .trailing)
        .background(CoachWorldTokens.dark.page.color.opacity(0.34), in: CoachWorldCutCorner.chip)
        .overlay {
            CoachWorldCutCorner.chip.stroke(
                Color.white.opacity(0.10), lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
    }

    private var secondaryRow: some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            Text(model.family.canonicalName.uppercased())
                .font(CoachWorldTokens.display(Chrome.familySize, weight: .bold))
                .tracking(CoachWorldTokens.DisplaySize.tracking(0.2, at: Chrome.familySize))
                .foregroundStyle(CoachWorldTokens.dark.actionPrimary.color)
            ForEach(model.siblings) { sibling in
                siblingLink(sibling)
            }
            Spacer(minLength: CoachWorldTokens.Gap.xs)
        }
        .padding(.horizontal, CoachWorldTokens.Gap.md)
        .frame(minHeight: CoachWorldTokens.Stage.headerSecondaryRow)
    }

    private func siblingLink(_ sibling: FloodlitChromeReadModel.Sibling) -> some View {
        let isCurrent = sibling.screen == model.screen
        return Button { onNavigate(sibling.intentID) } label: {
            Text(sibling.title.uppercased())
                .font(CoachWorldTokens.display(Chrome.siblingSize, weight: .semibold))
                .tracking(CoachWorldTokens.DisplaySize.tracking(0.09, at: Chrome.siblingSize))
                .foregroundStyle(
                    CoachWorldTokens.Floodlit.clubInk.color.opacity(isCurrent ? 1 : 0.66)
                )
                .lineLimit(1)
                .overlay(alignment: .bottom) {
                    if isCurrent {
                        Rectangle()
                            .fill(CoachWorldTokens.dark.actionPrimary.color)
                            .frame(height: Chrome.siblingUnderline)
                            .offset(y: Chrome.siblingUnderlineOffset)
                    }
                }
                // Visible size and tappable size are allowed to differ; tappable size is not
                // allowed to drop below 44 (`04` section 6.1c). Padding out to the target and then
                // cancelling the same amount keeps the hit area at 44 while the row stays 16 —
                // a plain `.frame(minHeight: 44)` grew the header instead and pushed it under the
                // content column.
                .padding(.vertical, Chrome.siblingTargetPad)
                .contentShape(Rectangle())
                .padding(.vertical, -Chrome.siblingTargetPad)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sibling.title)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

/// The team mark: a green field, a gold stripe and a pale dot. Stands for a team, never for the
/// product — there is no logo anywhere in this game (`README` assets rule).
struct CoachWorldPennant: View {
    let team: CoachWorldTeamReference

    /// Generated colour resolves through `CoachWorldTeamIdentity` and nowhere else — that is where
    /// the contrast floors live, and where a pair that cannot be read at all is refused outright
    /// (`04` section 5). Reading `primaryColorHex` here directly would paint an illegible pennant
    /// for exactly the generated pairs the identity type exists to catch.
    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: team,
            behind: CoachWorldTokens.Floodlit.roomDeep,
            inks: [CoachWorldTokens.Floodlit.clubInk, CoachWorldTokens.dark.contentPrimary]
        )
    }

    /// The neutral club field when the team carries no legible pair. An honest fallback beats an
    /// unreadable identity.
    private var field: Color {
        (identity?.field ?? CoachWorldTokens.Floodlit.clubField).color
    }

    private var dot: Color {
        (identity?.onField ?? CoachWorldTokens.Floodlit.clubInk).color
    }

    var body: some View {
        ZStack {
            CoachWorldCutCorner.chip.fill(field)
            CoachWorldCutCorner.chip.stroke(
                CoachWorldTokens.dark.actionPrimary.color.opacity(0.55),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
            Circle()
                // The measured-legible ink for this field, not a fixed pale one: on a light
                // generated primary a fixed pale dot disappears.
                .fill(dot)
                .frame(width: Chrome.pennantDot, height: Chrome.pennantDot)
        }
        .frame(width: Chrome.pennantWidth, height: Chrome.pennantHeight)
        .accessibilityHidden(true)
    }
}

// MARK: - Icon rail

/// Seven entries, each a 44 pt stack of a symbol over a tracked label. Icons name a kind of thing;
/// every one carries its label, so none is a symbol the player has to learn (`04` section 6.6).
struct FloodlitIconRail: View {
    let entries: [FloodlitChromeReadModel.RailEntry]
    let current: CoachWorldScreenID
    let palette: CoachWorldTokens.Palette
    let onNavigate: (CoachWorldIntentID) -> Void
    var axis: Axis = .vertical

    var body: some View {
        Group {
            if axis == .vertical {
                VStack(spacing: CoachWorldTokens.Stage.railGap) {
                    ForEach(entries) { entry in railButton(entry) }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CoachWorldTokens.Stage.railGap) {
                        ForEach(entries) { entry in railButton(entry) }
                    }
                }
            }
        }
        .accessibilityLabel("Sections")
    }

    private func railButton(_ entry: FloodlitChromeReadModel.RailEntry) -> some View {
        let isCurrent = entry.screen == current
        return Button { onNavigate(entry.intentID) } label: {
            VStack(spacing: CoachWorldTokens.Gap.hair) {
                Image(systemName: entry.symbol)
                    .font(.system(size: Chrome.railSymbol, weight: .semibold))
                    .accessibilityHidden(true)
                Text(entry.label.uppercased())
                    .font(CoachWorldTokens.display(Chrome.railLabel, weight: .bold))
                    .tracking(CoachWorldTokens.DisplaySize.tracking(0.1, at: Chrome.railLabel))
                    .lineLimit(1)
                    .minimumScaleFactor(Chrome.railLabelFloor)
            }
            .frame(
                width: CoachWorldTokens.Stage.railWidth,
                height: CoachWorldTokens.Shape.minimumTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isCurrent ? palette.actionPrimary.color : palette.contentSecondary.color)
        .background {
            if isCurrent {
                CoachWorldCutCorner.row.fill(palette.actionPrimary.color.opacity(0.14))
            }
        }
        .overlay {
            if isCurrent {
                CoachWorldCutCorner.row.stroke(
                    palette.actionPrimary.color, lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
        }
        .accessibilityLabel(entry.label)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

// MARK: - Registered-not-built

/// The honest state for a registered surface with no design yet: what it is, and what it needs.
/// Kept deliberately, rather than a spinner or a blank — `FLOODLIT-SURFACES.md` section 1.
struct FloodlitRegisteredNotBuilt: View {
    private let screen: CoachWorldScreenID
    private let needs: String
    private let palette: CoachWorldTokens.Palette

    init(
        screen: CoachWorldScreenID,
        needs: String,
        palette: CoachWorldTokens.Palette = CoachWorldTokens.dark
    ) {
        self.screen = screen
        self.needs = needs
        self.palette = palette
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
            FloodlitLabel3(screen.canonicalName, palette: palette)
            Text(needs)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Chrome.notBuiltPadH)
        .padding(.vertical, Chrome.notBuiltPadV)
        .frame(width: Chrome.notBuiltWidth, alignment: .leading)
        .coachWorldFloodlitPanel(
            fill: CoachWorldTokens.Floodlit.glassFlatDeep.color,
            border: Color.white.opacity(CoachWorldTokens.Glass.line),
            depth: .deep
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(screen.canonicalName). Registered, not built. \(needs)")
    }
}

// MARK: - Literals

private enum Chrome {
    static let grainOpacity = 0.5
    static let bleed: CGFloat = 1 + CoachWorldTokens.Stage.worldBottomBleed * 0.1
    static let lampRadiusRatio: CGFloat = 0.52
    static let lampAlpha = 0.22
    static let filmLampAlpha = 0.16

    struct Mote { let x: CGFloat; let y: CGFloat; let r: CGFloat; let alpha: Double }
    /// Five, fixed. A random mote is a different screen every launch.
    static let dustMotes: [Mote] = [
        .init(x: 0.38, y: 0.22, r: 2.5, alpha: 0.10),
        .init(x: 0.56, y: 0.34, r: 1.8, alpha: 0.08),
        .init(x: 0.47, y: 0.52, r: 3.0, alpha: 0.07),
        .init(x: 0.62, y: 0.66, r: 2.0, alpha: 0.06),
        .init(x: 0.41, y: 0.78, r: 2.4, alpha: 0.05),
    ]

    static let headerRail: CGFloat = 3
    static let headerSeamAlpha = 0.14
    static let headerRingAlpha = 0.13
    static let clubTracking: CGFloat = 0.5
    static let recordSize: CGFloat = 11
    static let contextSize: CGFloat = 11
    static let contextChipMaxWidth: CGFloat = 210
    static let familySize: CGFloat = 8.5
    static let siblingSize: CGFloat = 9.5
    static let siblingUnderline: CGFloat = 2
    static let siblingUnderlineOffset: CGFloat = 3
    /// Half the difference between the 16 pt row and the 44 pt minimum target, applied as padding
    /// and then cancelled so the hit area grows without the layout following it.
    static let siblingTargetPad: CGFloat = 14

    static let pennantWidth: CGFloat = 11
    static let pennantHeight: CGFloat = 14
    static let pennantDot: CGFloat = 3

    static let railSymbol: CGFloat = 16
    static let railLabel: CGFloat = 7.5
    static let railLabelFloor: CGFloat = 0.7

    static let notBuiltWidth: CGFloat = 330
    static let notBuiltPadH: CGFloat = 22
    static let notBuiltPadV: CGFloat = 18
}
