import SwiftUI

public struct PlayerProfileView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: PlayerProfileReadModel
    public let team: CoachWorldTeamReference
    public let onClose: () -> Void
    public let onInspectDevelopment: (String) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var activeRoute = ProfileRoute.overview

    public init(
        model: PlayerProfileReadModel,
        team: CoachWorldTeamReference,
        onClose: @escaping () -> Void,
        onInspectDevelopment: @escaping (String) -> Void
    ) {
        self.model = model
        self.team = team
        self.onClose = onClose
        self.onInspectDevelopment = onInspectDevelopment
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { accessibleLayout }
            } else {
                workspace
            }
        }
        .accessibilityIdentifier("player-profile-screen")
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    /// The reference's two columns: the dial and the identity on the left, the open route's panel
    /// on the right.
    private var workspace: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            routeBar
            HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                identityColumn
                    .frame(width: ProfileMetric.identityColumn)
                ScrollView { routePanel }
            }
        }
        .padding(.vertical, CoachWorldTokens.Pad.panel.v)
    }

    /// Pills, then the way back. The reference sets the return as a quiet link rather than a
    /// button, because leaving is not the thing this screen is for.
    private var routeBar: some View {
        HStack(spacing: CoachWorldTokens.Gap.xs) {
            ForEach(ProfileRoute.allCases, id: \.rawValue) { route in
                FloodlitPill(
                    route.rawValue,
                    isSelected: activeRoute == route,
                    palette: palette,
                    action: { activeRoute = route }
                )
            }
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button(action: onClose) {
                Text("Back to personnel")
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                    .foregroundStyle(palette.contentQuiet.color)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            }
            .buttonStyle(.plain)
        }
        .accessibilitySortPriority(350)
    }

    /// The dial, the jersey, the name, and the first four attributes as shares.
    private var identityColumn: some View {
        HStack(alignment: .center, spacing: CoachWorldTokens.Gap.xl) {
            FloodlitAttributeDial(
                rating: model.overall,
                title: model.position,
                diameter: ProfileMetric.dialDiameter,
                palette: palette
            )
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                    uniformMark
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                        FloodlitLabel3(
                            model.rosterRole, palette: palette, tint: palette.stateInfo.color
                        )
                        Text(model.person.name)
                            .coachWorldDisplay(CoachWorldTokens.DisplaySize.screen, weight: .bold)
                            .lineLimit(1)
                            .minimumScaleFactor(ProfileMetric.nameScaleFloor)
                    }
                }
                FloodlitLabel3(originLine, palette: palette)
                Text(statusLine)
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(1)
                headlineAttributes
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    /// The programme, and where the player is from when the root records it. It does not, for
    /// rostered players -- so the line says the programme alone rather than borrowing its city.
    private var originLine: String {
        model.hometown.isEmpty ? team.name : "\(team.name) \u{00B7} \(model.hometown)"
    }

    private var statusLine: String {
        "\(model.academicYear) \u{00B7} \(model.availability) \u{00B7} "
            + "condition \(model.condition)"
    }

    /// The reference sets four attribute shares beside the name. They are the first four the model
    /// records, in the order it records them; picking the four highest would be the interface
    /// deciding what about a player matters.
    private var headlineAttributes: some View {
        let attributes = model.attributeGroups
            .flatMap(\.attributes)
            .prefix(ProfileMetric.headlineAttributeCount)
        return VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            ForEach(Array(attributes)) { attribute in
                HStack(spacing: CoachWorldTokens.Gap.sm) {
                    FloodlitLabel3(attribute.label, palette: palette)
                        .frame(width: ProfileMetric.attributeLabel, alignment: .leading)
                    FloodlitShareBar(
                        proportion: proportion(of: attribute.value),
                        tint: CoachWorldTokens.Heat.color(for: attribute.value, palette: palette),
                        palette: palette
                    )
                    Text("\(attribute.value)")
                        .coachWorldFigure(CoachWorldTokens.DisplaySize.pill, weight: .semibold)
                        .frame(width: ProfileMetric.attributeValue, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(attribute.label), \(attribute.value), \(attribute.confidence)"
                )
            }
        }
        .padding(.top, CoachWorldTokens.Gap.xxs)
    }

    /// Where a rating sits on the 40-99 scale, not a percentage of 99.
    private func proportion(of rating: Int) -> Double {
        let floor = CoachWorldTokens.Heat.scaleFloor
        let ceiling = CoachWorldTokens.Heat.scaleCeiling
        let clamped = min(max(rating, floor), ceiling)
        return Double(clamped - floor) / Double(ceiling - floor)
    }

    /// The right panel: one route at a time, each ending in the action that route leads to.
    private var routePanel: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                HStack(spacing: CoachWorldTokens.Gap.smPlus) {
                    FloodlitLabel3(routeTitle, palette: palette)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    Text(routeMeta)
                        .coachWorldFigure(CoachWorldTokens.DisplaySize.pill)
                        .foregroundStyle(palette.contentQuiet.color)
                        .lineLimit(1)
                }
                routeRows
                if activeRoute == .overview || activeRoute == .development {
                    HStack {
                        Spacer(minLength: .zero)
                        Button("Open development evidence") {
                            activeRoute = .development
                            onInspectDevelopment(model.stableID)
                        }
                        .buttonStyle(
                            CoachWorldActionButtonStyle(role: .primary, palette: palette)
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var routeTitle: String {
        switch activeRoute {
        case .overview: "What the staff has"
        case .attributes: "Every attribute"
        case .development: "How the player is coming on"
        case .history: "What is on the record"
        }
    }

    private var routeMeta: String {
        switch activeRoute {
        case .overview: return model.schemeFit
        case .attributes:
            let count = model.attributeGroups.flatMap(\.attributes).count
            return count == 1 ? "1 attribute" : "\(count) attributes"
        case .development, .history:
            return model.recentForm.isEmpty
                ? "no games recorded"
                : "\(model.recentForm.count) games recorded"
        }
    }

    @ViewBuilder
    private var routeRows: some View {
        switch activeRoute {
        case .overview:
            VStack(alignment: .leading, spacing: .zero) {
                ForEach(Array(model.strengths.enumerated()), id: \.offset) { _, strength in
                    panelRow("Strength", strength)
                }
                panelRow("Concern", model.concern.isEmpty ? "None recorded." : model.concern)
                panelRow("Fit", model.schemeFit)
                panelRow("Role", model.rosterRole)
            }
            quote(model.staffSummary)
        case .attributes:
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                ForEach(model.attributeGroups) { group in
                    attributeGroup(group)
                }
            }
        case .development:
            VStack(alignment: .leading, spacing: .zero) {
                formRows
            }
            quote(model.developmentEvidence)
        case .history:
            VStack(alignment: .leading, spacing: .zero) {
                panelRow("Available", model.availability)
                panelRow("Condition", "\(model.condition)", value: model.condition)
                formRows
            }
            quote(model.historyEvidence)
        }
    }

    @ViewBuilder
    private var formRows: some View {
        if model.recentForm.isEmpty {
            panelRow("Form", "No recent form recorded.")
        } else {
            ForEach(model.recentForm) { entry in
                panelRow(entry.opponent, "Graded \(entry.rating)", value: entry.rating)
            }
        }
    }

    /// The reference's panel row: a key, a value, a share of the scale, and the figure.
    private func panelRow(_ key: String, _ text: String, value: Int? = nil) -> some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3(key, palette: palette)
                .frame(width: ProfileMetric.panelKey, alignment: .leading)
            Text(text)
                .font(CoachWorldTokens.TypeRole.caption)
                .lineLimit(ProfileMetric.panelValueLines)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let value {
                FloodlitShareBar(
                    proportion: proportion(of: value),
                    tint: CoachWorldTokens.Heat.color(for: value, palette: palette),
                    palette: palette
                )
                .frame(width: ProfileMetric.panelBar)
                Text("\(value)")
                    .coachWorldFigure(CoachWorldTokens.DisplaySize.pill, weight: .semibold)
                    .foregroundStyle(CoachWorldTokens.Heat.color(for: value, palette: palette))
                    .frame(width: ProfileMetric.panelFigure, alignment: .trailing)
            }
        }
        .frame(minHeight: ProfileMetric.panelRowHeight)
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key), \(text)")
    }

    /// Attributed prose, or the gap where it will be. `04` section 4.4 refuses a sentence in the
    /// interface's own voice, so an absent staff summary says it is absent rather than inventing one.
    @ViewBuilder
    private func quote(_ text: String) -> some View {
        Text(text.isEmpty ? "No staff evidence recorded yet." : text)
            .font(CoachWorldTokens.TypeRole.caption)
            .foregroundStyle(
                text.isEmpty ? palette.contentQuiet.color : palette.contentSecondary.color
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    private func attributeGroup(_ group: PlayerProfileReadModel.AttributeGroup) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            FloodlitLabel3(group.title, palette: palette)
            ForEach(group.attributes) { attribute in
                panelRow(attribute.label, attribute.confidence, value: attribute.value)
            }
        }
    }

    /// The player's club: uniform mark in the programme's secondary, which `04` section 5 names as
    /// identity furniture rather than decoration.
    private var uniformMark: some View {
        Text("\(model.number)")
            .coachWorldFigure(CoachWorldTokens.DisplaySize.subject, weight: .semibold)
            .foregroundStyle(markInk.color)
            .padding(.horizontal, CoachWorldTokens.Gap.xs)
            .frame(minWidth: ProfileMetric.markWidth, minHeight: ProfileMetric.markHeight)
            .background(
                (identity?.accent.color ?? palette.collegeIdentity.color),
                in: CoachWorldCutCorner.chip
            )
            .accessibilityLabel("\(team.name), number \(model.number)")
    }

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: team,
            behind: palette.raised,
            inks: [palette.contentPrimary, palette.page]
        )
    }

    private var markInk: CoachWorldTokens.ColorValue {
        guard let accent = identity?.accent else { return palette.page }
        return accent.mostLegibleInk(from: [palette.page, palette.contentPrimary]) ?? palette.page
    }

    /// At AX sizes the two columns stack and the dial keeps its stated stroke rather than scaling.
    private var accessibleLayout: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            routeBar
            identityColumn
                .accessibilityElement(children: .combine)
                .accessibilityLabel(identityAccessibilityLabel)
            routePanel
        }
        .padding(.vertical, CoachWorldTokens.Pad.panel.v)
    }

    private var identityAccessibilityLabel: String {
        "Number \(model.number), \(model.person.name), \(model.position), "
            + "\(model.academicYear), role \(model.rosterRole), "
            + "\(model.availability), condition \(model.condition)"
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))
            .frame(height: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }
}

private enum ProfileRoute: String, CaseIterable {
    case overview = "Overview"
    case attributes = "Attributes"
    case development = "Development"
    case history = "History"
}

private enum ProfileMetric {
    /// The handoff's 340pt identity column and 150pt dial.
    static let identityColumn: CGFloat = 340
    static let dialDiameter: CGFloat = 150
    static let attributeLabel: CGFloat = 50
    static let attributeValue: CGFloat = 18
    static let headlineAttributeCount = 4
    static let markWidth: CGFloat = 40
    static let markHeight: CGFloat = 38
    static let nameScaleFloor: CGFloat = 0.7
    static let panelKey: CGFloat = 56
    static let panelBar: CGFloat = 44
    static let panelFigure: CGFloat = 44
    static let panelRowHeight: CGFloat = 27
    static let panelValueLines = 2
}
