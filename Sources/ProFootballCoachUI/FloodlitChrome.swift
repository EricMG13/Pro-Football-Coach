import SwiftUI

// The shared management stage: world backdrop, identity navigator, content, grain
// (`04` section 6.1c, `FLOODLIT-SURFACES.md` section 1).
//
// Every management surface renders inside `CoachWorldFloodlitSurface`. Match Day does not — it is
// the broadcast register and owns its whole frame (section 6.1b).
//
// Navigation lives in the identity header rather than in a rail or a tab bar.

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

    /// A sibling surface in the current family — the header's second-row links.
    public struct Sibling: Sendable, Equatable, Identifiable {
        public var id: CoachWorldScreenID { screen }
        public let screen: CoachWorldScreenID
        /// The short form the 16 pt row prints.
        public let title: String
        public let intentID: CoachWorldIntentID

        /// What VoiceOver says. Shortening a link to fit a row must not shorten what the screen is
        /// called to someone who cannot see the row, so this stays the registry's full title.
        public var accessibleTitle: String { screen.canonicalName }

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
    public let siblings: [Sibling]
    /// Canonical tasks whose read models are retained for this career. Legacy aliases are never
    /// included here; they remain decode inputs only.
    public let availableScreens: [CoachWorldScreenID]

    public var family: CoachWorldSurfaceFamily { screen.family }
    public init(
        screen: CoachWorldScreenID,
        world: World,
        club: CoachWorldTeamReference,
        record: String,
        ranking: String? = nil,
        conference: String? = nil,
        context: String? = nil,
        contextOpponent: CoachWorldTeamReference? = nil,
        siblings: [Sibling] = [],
        availableScreens: [CoachWorldScreenID] = CoachWorldScreenID.allCases
    ) {
        self.screen = screen
        self.world = world
        self.club = club
        self.record = record
        self.ranking = ranking
        self.conference = conference
        self.context = context
        self.contextOpponent = contextOpponent
        self.siblings = siblings
        self.availableScreens = availableScreens
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

/// One row: identity, task family, sibling routes and current context.
struct FloodlitIdentityHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: FloodlitChromeReadModel
    let palette: CoachWorldTokens.Palette
    let onNavigate: (CoachWorldIntentID) -> Void
    let onOpenRegistry: () -> Void

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
        HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            identitySection
                .layoutPriority(2)
            Button {
                onOpenRegistry()
            } label: {
                Label(
                    model.family.canonicalName.uppercased(),
                    systemImage: Chrome.familyDisclosureSymbol
                )
                    .font(CoachWorldTokens.display(10, weight: .bold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(
                        minWidth: CoachWorldTokens.Shape.minimumTarget,
                        minHeight: CoachWorldTokens.Shape.minimumTarget
                    )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Open all tasks, \(model.family.canonicalName)")
            .layoutPriority(4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CoachWorldTokens.Gap.md) {
                    ForEach(model.siblings) { sibling in siblingLink(sibling) }
                }
            }
            .layoutPriority(1)

            Spacer(minLength: CoachWorldTokens.Gap.xs)
            contextSection
                .layoutPriority(0)
        }
        .padding(.horizontal, CoachWorldTokens.Gap.md)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : CoachWorldTokens.Stage.headerHeight)
        .background(headerMaterial)
        .clipShape(CoachWorldCutCorner.headerBand)
        .accessibilityIdentifier("top-navigator")
        .accessibilityElement(children: .contain)
    }

    private var identitySection: some View {
        HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            CoachWorldTeamLogo(
                team: model.club,
                size: .compact,
                surface: CoachWorldTokens.Floodlit.roomDeep,
                palette: palette
            )
            Text(model.club.name.uppercased())
                .font(CoachWorldTokens.display(15, weight: .bold))
                .lineLimit(1)
            Text(model.ranking.map { "\(model.record) · \($0)" } ?? model.record)
                .font(CoachWorldTokens.figure(Chrome.recordSize, weight: .semibold))
                .lineLimit(1)
            if let conference = model.conference {
                Text(conference.uppercased())
                    .font(CoachWorldTokens.display(Chrome.familySize, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(CoachWorldTokens.Floodlit.clubInk.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(identityLabel)
    }

    /// Assembled in steps rather than as one chained expression — the chained form defeated the
    /// type checker outright.
    private var identityLabel: String {
        var parts: [String] = ["\(model.club.name), \(model.record)"]
        if let ranking = model.ranking { parts.append("ranked \(ranking)") }
        if let conference = model.conference { parts.append(conference) }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var contextSection: some View {
        if let context = model.context {
            contextChip(context)
                .frame(width: Chrome.contextViewportWidth, alignment: .trailing)
                .clipped()
        }
    }

    private var headerMaterial: LinearGradient {
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

    private func contextChip(_ context: String) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.xxs) {
            if let opponent = model.contextOpponent {
                CoachWorldTeamLogo(
                    team: opponent,
                    size: .compact,
                    surface: CoachWorldTokens.Floodlit.roomDeep,
                    palette: palette
                )
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

    private func siblingLink(_ sibling: FloodlitChromeReadModel.Sibling) -> some View {
        let isCurrent = sibling.screen == model.screen
        return Button { onNavigate(sibling.intentID) } label: {
            Text(sibling.title.uppercased())
                .font(CoachWorldTokens.display(Chrome.siblingSize, weight: .semibold))
                .tracking(CoachWorldTokens.DisplaySize.tracking(0.09, at: Chrome.siblingSize))
                .frame(
                    minWidth: CoachWorldTokens.Shape.minimumTarget,
                    minHeight: CoachWorldTokens.Shape.minimumTarget
                )
                .foregroundStyle(
                    CoachWorldTokens.Floodlit.clubInk.color.opacity(isCurrent ? 1 : 0.66)
                )
                .lineLimit(1)
                .overlay(alignment: .bottom) {
                    if isCurrent {
                        Rectangle()
                            .fill(CoachWorldTokens.dark.actionPrimary.color)
                            .frame(height: Chrome.siblingUnderline)
                            .offset(y: -Chrome.siblingUnderlineInset)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sibling.accessibleTitle)
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

    static let recordSize: CGFloat = 11
    static let contextSize: CGFloat = 11
    static let contextChipMaxWidth: CGFloat = 210
    static let contextViewportWidth: CGFloat = 132
    static let familySize: CGFloat = 9
    /// Control furniture registered as `chevron.*` in `04` section 6.6.
    static let familyDisclosureSymbol = "chevron.down"
    static let siblingSize: CGFloat = 9.5
    static let siblingUnderline: CGFloat = 2
    static let siblingUnderlineInset: CGFloat = 6
    static let pennantWidth: CGFloat = 11
    static let pennantHeight: CGFloat = 14
    static let pennantDot: CGFloat = 3

    static let notBuiltWidth: CGFloat = 330
    static let notBuiltPadH: CGFloat = 22
    static let notBuiltPadV: CGFloat = 18
}
