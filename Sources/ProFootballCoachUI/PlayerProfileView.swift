import SwiftUI

public struct PlayerProfileView: View {
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
        CoachWorldFloodlitStage(palette: palette) {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { accessibleLayout }
            } else {
                VStack(spacing: .zero) {
                    identityBand
                    routeBar
                    routeContent
                    actionArea
                }
            }
        }
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var identityBand: some View {
        HStack(alignment: .top, spacing: CoachWorldTokens.Space.sm) {
            VStack(spacing: CoachWorldTokens.Space.xxs) {
                CoachWorldBlankPhotoPlate(
                    name: model.person.name,
                    palette: palette,
                    width: ProfileMetric.photoWidth,
                    height: ProfileMetric.photoHeight
                )
                uniformMark
            }

            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text("#\(model.number)")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(numberInk.color)
                Text(model.person.name)
                    .font(CoachWorldTokens.TypeRole.display)
                    .lineLimit(1)
                Text("\(model.position) · \(model.academicYear)")
                    .font(CoachWorldTokens.TypeRole.headline)
                Text(model.hometown)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                identityFact("ROLE", model.rosterRole)
                identityFact("AVAILABILITY", model.availability)
                identityFact("CONDITION", "\(model.condition)")
            }
        }
        .font(CoachWorldTokens.TypeRole.body)
        .padding(CoachWorldTokens.Space.md)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(identityAccessibilityLabel)
        .accessibilitySortPriority(400)
    }

    /// The player's club: uniform mark in the programme's secondary, which `04` section 5 names as
    /// identity furniture rather than decoration.
    private var uniformMark: some View {
        Text(team.abbreviation)
            .font(CoachWorldTokens.TypeRole.caption.weight(.black))
            .foregroundStyle(markInk.color)
            .padding(.horizontal, CoachWorldTokens.Space.xxs)
            .frame(minWidth: ProfileMetric.markWidth, minHeight: ProfileMetric.markHeight)
            .background(
                (identity?.accent.color ?? palette.collegeIdentity.color),
                in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
            )
            .accessibilityLabel(team.name)
    }

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: team,
            behind: palette.raised,
            inks: [palette.contentPrimary, palette.page]
        )
    }

    private var numberInk: CoachWorldTokens.ColorValue {
        identity?.selectionRule(on: palette.raised) ?? palette.collegeIdentity
    }

    private var markInk: CoachWorldTokens.ColorValue {
        guard let accent = identity?.accent else { return palette.page }
        return accent.mostLegibleInk(from: [palette.page, palette.contentPrimary]) ?? palette.page
    }

    private func identityFact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }

    private var routeBar: some View {
        HStack(spacing: .zero) {
            ForEach(ProfileRoute.allCases, id: \.rawValue) { route in
                Button(route.rawValue) {
                    activeRoute = route
                }
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                .buttonStyle(.plain)
                .background(
                    activeRoute.rawValue == route.rawValue
                        ? numberInk.color.opacity(0.16)
                        : Color.clear
                )
                .accessibilityAddTraits(
                    activeRoute.rawValue == route.rawValue ? .isSelected : []
                )
            }
        }
        .background(palette.page.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(350)
    }

    @ViewBuilder
    private var routeContent: some View {
        switch activeRoute {
        case .overview:
            GeometryReader { proxy in
                // Landscape leaves this band about 200 points tall, which is less
                // than three attribute rows plus the evidence rail need. Each
                // column scrolls so nothing is silently clipped off the bottom.
                HStack(alignment: .top, spacing: ProfileMetric.workspaceGap) {
                    ScrollView { attributeBody }
                        .frame(width: proxy.size.width * ProfileMetric.attributeFraction)
                    ScrollView { evidenceRail }
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, CoachWorldTokens.Space.xs)
            }
        case .attributes:
            ScrollView { attributeBody.padding(.horizontal, CoachWorldTokens.Space.xs) }
        case .development:
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    recentForm
                    evidenceFact("DEVELOPMENT EVIDENCE", model.developmentEvidence)
                    evidenceFact("SCHEME FIT", model.schemeFit)
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
                .padding(.vertical, CoachWorldTokens.Space.xs)
            }
        case .history:
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    evidenceFact("HISTORY", model.historyEvidence)
                    recentForm
                    evidenceFact("AVAILABILITY", model.availability)
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
                .padding(.vertical, CoachWorldTokens.Space.xs)
            }
        }
    }

    private var attributeBody: some View {
        HStack(alignment: .top, spacing: CoachWorldTokens.Space.xs) {
            ForEach(model.attributeGroups) { group in
                attributeGroup(group)
            }
        }
        .padding(.vertical, CoachWorldTokens.Space.xs)
        .accessibilitySortPriority(300)
    }

    private func attributeGroup(_ group: PlayerProfileReadModel.AttributeGroup) -> some View {
        VStack(spacing: .zero) {
            Text(group.title.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
                .padding(CoachWorldTokens.Space.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            ForEach(group.attributes) { attribute in
                HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xxs) {
                    Text(attribute.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(attribute.value)")
                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(ratingColor(attribute.value))
                }
                .font(CoachWorldTokens.TypeRole.body)
                .padding(.horizontal, CoachWorldTokens.Space.sm)
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .overlay(alignment: .top) { seam }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(attribute.label), \(attribute.value), \(attribute.confidence) confidence"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .coachWorldFloodlitPanel(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
        )
    }

    private var evidenceRail: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            positionDiagram
            evidenceFact("SCHEME FIT", model.schemeFit)
            recentForm
            evidenceFact("STAFF SUMMARY", model.staffSummary)
            evidenceFact("STRENGTHS", model.strengths.joined(separator: " · "))
            evidenceFact("CONCERN", model.concern)
        }
        .padding(.vertical, CoachWorldTokens.Space.xs)
        .accessibilitySortPriority(200)
    }

    private var positionDiagram: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                .fill(palette.fieldTurf.color)

            VStack(spacing: CoachWorldTokens.Space.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(palette.fieldLine.color.opacity(0.72))
                        .frame(height: CoachWorldTokens.Shape.hairline)
                }
            }
            .padding(CoachWorldTokens.Space.sm)
            .accessibilityHidden(true)

            Text(model.position)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .foregroundStyle(palette.page.color)
                .padding(CoachWorldTokens.Space.xs)
                .background(palette.fieldLive.color, in: Circle())
        }
        .frame(minHeight: ProfileMetric.fieldHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(model.position) position marker")
    }

    private func evidenceFact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
                .accessibilityAddTraits(.isHeader)
            Text(value.isEmpty ? "No recorded evidence." : value)
                .font(CoachWorldTokens.TypeRole.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var recentForm: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("RECENT FORM")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
                .accessibilityAddTraits(.isHeader)
            if model.recentForm.isEmpty {
                Text("No recent form recorded.")
                    .font(CoachWorldTokens.TypeRole.body)
            } else {
                HStack(spacing: CoachWorldTokens.Space.xs) {
                    ForEach(model.recentForm) { entry in
                        VStack(spacing: .zero) {
                            Text(entry.opponent)
                            Text("\(entry.rating)")
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                                .monospacedDigit()
                                .foregroundStyle(ratingColor(entry.rating))
                        }
                    }
                }
                .font(CoachWorldTokens.TypeRole.caption)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(recentFormAccessibilityLabel)
    }

    private var actionArea: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Button("Review development") {
                activeRoute = .development
                onInspectDevelopment(model.stableID)
            }
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))

            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(palette.raised.color)
        .overlay(alignment: .top) { seam }
        .accessibilitySortPriority(100)
    }

    private var accessibleLayout: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
            identityBand
            routeBar
            switch activeRoute {
            case .overview:
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    ForEach(model.attributeGroups) { group in
                        attributeGroup(group)
                    }
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
                .accessibilitySortPriority(300)
                evidenceRail
                    .padding(.horizontal, CoachWorldTokens.Space.sm)
            case .attributes:
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    ForEach(model.attributeGroups) { group in
                        attributeGroup(group)
                    }
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
            case .development:
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    recentForm
                    evidenceFact("DEVELOPMENT EVIDENCE", model.developmentEvidence)
                    evidenceFact("SCHEME FIT", model.schemeFit)
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
            case .history:
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    evidenceFact("HISTORY", model.historyEvidence)
                    recentForm
                    evidenceFact("AVAILABILITY", model.availability)
                }
                .padding(.horizontal, CoachWorldTokens.Space.sm)
            }
            actionArea
        }
    }

    private var identityAccessibilityLabel: String {
        "Number \(model.number), \(model.person.name), \(model.position), "
            + "\(model.academicYear), hometown \(model.hometown), role \(model.rosterRole), "
            + "\(model.availability), condition \(model.condition)"
    }

    private var recentFormAccessibilityLabel: String {
        guard !model.recentForm.isEmpty else { return "Recent form, no recent form recorded" }
        let entries = model.recentForm
            .map { "\($0.opponent), \($0.rating)" }
            .joined(separator: ", then ")
        return "Recent form, \(entries)"
    }

    private func ratingColor(_ rating: Int) -> Color {
        if rating >= 85 { return palette.statePositive.color }
        if rating >= 70 { return palette.stateWarning.color }
        return palette.stateNegative.color
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.38))
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
    static let attributeFraction = 0.68
    static let workspaceGap = CoachWorldTokens.Space.xs
    static let photoWidth: CGFloat = 64
    static let photoHeight: CGFloat = 72
    static let fieldHeight: CGFloat = 96
    static let markWidth: CGFloat = 34
    static let markHeight: CGFloat = 20
}
