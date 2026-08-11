import SwiftUI

public struct RecruitingBoardView: View {
    public let model: RecruitingBoardReadModel
    public let statusMessage: String?
    public let onAction: (String, CoachWorldIntentID) -> Void
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var deskGap = CoachWorldTokens.Space.xs
    @State private var selectedProspectID: String

    public init(
        model: RecruitingBoardReadModel,
        statusMessage: String? = nil,
        onAction: @escaping (String, CoachWorldIntentID) -> Void,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        _selectedProspectID = State(initialValue: model.prospects.first?.stableID ?? "")
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    private var selectedProspect: RecruitingBoardReadModel.Prospect? {
        model.prospects.first(where: { $0.stableID == selectedProspectID })
            ?? model.prospects.first
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    worldStrip
                    standardLayout
                }
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private var worldStrip: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(model.team.name.uppercased())
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    .lineLimit(1)
                Text(statusMessage ?? worldContextLine)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(
                        statusMessage == nil
                            ? palette.contentSecondary.color
                            : palette.statePositive.color
                    )
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")

            Divider().overlay(palette.contentQuiet.color)

            HStack(spacing: .zero) {
                route("Office", screen: .coachingHQ)
                route("Team", screen: .roster)
                route("Recruit", screen: .recruitingBoard, current: true)
                route("League", screen: .leagueMap)
                route("Career", screen: .careerHub)
            }
            .frame(maxWidth: .infinity)

            Button(action: onContinue) {
                Label("Continue", systemImage: "forward.end.fill")
            }
                .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        }
        .padding(.horizontal, CoachWorldTokens.Space.md)
        .frame(height: RecruitingMetric.worldStripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(50)
    }

    private func route(
        _ title: String,
        screen: CoachWorldScreenID,
        current: Bool = false
    ) -> some View {
        CoachWorldRouteButton(
            title: title,
            screen: screen,
            isCurrent: current,
            palette: palette,
            action: { onNavigate(screen) }
        )
    }

    private var standardLayout: some View {
        HStack(spacing: deskGap) {
            boardSurface.frame(maxWidth: .infinity)
            dossier
                .frame(width: RecruitingMetric.dossierWidth)
        }
        .padding(.horizontal, CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: .zero) {
                boardHeader
                if model.prospects.isEmpty {
                    ContentUnavailableView(
                        "No prospects on the board",
                        systemImage: "list.number",
                        description: Text("Add evaluated prospects before assigning recruiting time.")
                    )
                } else {
                    accessibleProspectRows
                    capacityStrip
                    if let prospect = selectedProspect {
                        personHeader(prospect)
                        evaluation(prospect)
                        relationship(prospect)
                        actionDesk(prospect)
                    }
                }
                accessibleWorldContext
            }
        }
        .background {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius)
                .fill(palette.work.color)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius)
                .stroke(palette.contentQuiet.color.opacity(0.38), lineWidth: CoachWorldTokens.Shape.hairline)
        }
        .accessibilitySortPriority(100)
    }

    private var accessibleWorldContext: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("WORLD")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Text(statusMessage ?? worldContextLine)
                .foregroundStyle(palette.contentSecondary.color)
            route("Office", screen: .coachingHQ)
            route("Team", screen: .roster)
            route("Recruit", screen: .recruitingBoard, current: true)
            route("League", screen: .leagueMap)
            route("Career", screen: .careerHub)
            Button("Continue", action: onContinue)
                .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        }
        .padding(CoachWorldTokens.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.raised.color)
        .overlay(alignment: .top) { seam }
        .accessibilitySortPriority(50)
    }

    private var boardSurface: some View {
        VStack(spacing: CoachWorldTokens.Space.xxs) {
            boardHeader
            capacityStrip
            if model.prospects.isEmpty {
                ContentUnavailableView(
                    "No prospects on the board",
                    systemImage: "list.number",
                    description: Text("Add evaluated prospects before assigning recruiting time.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                comparisonTable
            }
        }
        .background(palette.work.color)
        .accessibilitySortPriority(100)
    }

    private var boardHeader: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    boardTitle
                    sampleCareerFlag
                    Text("POSITION PLAN · \(positionPlanLine)")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                        .foregroundStyle(palette.contentSecondary.color)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Space.sm) {
                    boardTitle
                    sampleCareerFlag
                    Spacer()
                    Text(positionPlanLine)
                        .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                        .foregroundStyle(palette.contentSecondary.color)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.md)
        .frame(minHeight: RecruitingMetric.boardHeaderHeight)
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
    }

    private var boardTitle: some View {
        Text("RECRUITING BOARD")
            .font(CoachWorldTokens.TypeRole.title.weight(.black))
    }

    private var sampleCareerFlag: some View {
        Text("SAMPLE CAREER")
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.page.color)
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .background(
                RecruitingCollegeCutShape(cut: RecruitingMetric.collegeCut)
                    .fill(palette.collegeIdentity.color)
            )
            .opacity(model.provenance == .sample ? 1 : 0)
            .accessibilityHidden(model.provenance != .sample)
    }

    private var capacityStrip: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: .zero) {
                    compactCapacity(
                        "Scholarships",
                        value: "\(model.capacity.scholarshipSlotsRemaining)"
                    )
                    compactCapacity(
                        "Weekly hours",
                        value: "\(model.capacity.weeklyHoursRemaining)"
                    )
                    compactCapacity(
                        "Visits",
                        value: "\(model.capacity.officialVisitsRemaining)"
                    )
                }
            } else {
                HStack(spacing: .zero) {
                    capacityValue(
                        "SLOTS",
                        value: "\(model.capacity.scholarshipSlotsRemaining)",
                        suffix: "open"
                    )
                    capacityValue(
                        "HOURS",
                        value: "\(model.capacity.weeklyHoursRemaining)h",
                        suffix: "left"
                    )
                    capacityValue(
                        "VISITS",
                        value: "\(model.capacity.officialVisitsRemaining)",
                        suffix: "left"
                    )
                }
            }
        }
        .frame(minHeight: RecruitingMetric.capacityHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
    }

    private func compactCapacity(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(value)
                .font(CoachWorldTokens.TypeRole.title.weight(.black))
                .monospacedDigit()
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .foregroundStyle(palette.contentSecondary.color)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
        .overlay(alignment: .trailing) { verticalSeam }
        .accessibilityElement(children: .combine)
    }

    private func capacityValue(_ label: String, value: String, suffix: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(1)
            Spacer(minLength: CoachWorldTokens.Space.xxs)
            Text(value)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .monospacedDigit()
            Text(suffix)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
        .overlay(alignment: .trailing) { verticalSeam }
        .accessibilityElement(children: .combine)
    }

    private var comparisonTable: some View {
        VStack(spacing: .zero) {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                tableHeader("#", width: RecruitingMetric.rankWidth, alignment: .trailing)
                tableHeader("PROSPECT", alignment: .leading)
                tableHeader("POS", width: RecruitingMetric.positionWidth)
                tableHeader("INT.", width: RecruitingMetric.interestWidth)
                tableHeader("STATUS", width: RecruitingMetric.statusWidth)
                tableHeader("FIT", width: RecruitingMetric.fitWidth)
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: RecruitingMetric.tableHeaderHeight)
            .background(palette.page.color)
            .overlay(alignment: .bottom) { seam }

            ForEach(model.prospects, id: \.stableID) { prospect in
                comparisonRow(prospect)
            }
            Spacer(minLength: .zero)
        }
    }

    private func tableHeader(
        _ title: String,
        width: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        Text(title)
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.contentSecondary.color)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
            .frame(width: width)
            .lineLimit(1)
    }

    private func comparisonRow(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        Button {
            selectedProspectID = prospect.stableID
        } label: {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                Text("\(prospect.boardRank)")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    .monospacedDigit()
                    .frame(width: RecruitingMetric.rankWidth, alignment: .trailing)
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(prospect.person.name)
                        .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(prospect.hometown)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                rowValue(prospect.position, width: RecruitingMetric.positionWidth)
                rowValue(prospect.interest, width: RecruitingMetric.interestWidth)
                rowValue(prospect.status, width: RecruitingMetric.statusWidth)
                rowValue(prospect.evaluation.schemeFit, width: RecruitingMetric.fitWidth)
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: RecruitingMetric.rowHeight)
            .contentShape(Rectangle())
            .background(
                prospect.stableID == selectedProspect?.stableID
                    ? palette.collegeIdentity.color.opacity(0.14)
                    : palette.raised.color.opacity(0.34)
            )
            .overlay(alignment: .leading) {
                if prospect.stableID == selectedProspect?.stableID {
                    Rectangle().fill(palette.collegeIdentity.color)
                        .frame(width: RecruitingMetric.selectedRuleWidth)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                    .stroke(
                        prospect.stableID == selectedProspect?.stableID
                            ? palette.collegeIdentity.color
                            : palette.contentQuiet.color.opacity(0.38),
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, CoachWorldTokens.Space.xxs)
        .accessibilityLabel(prospectAccessibilityLabel(prospect))
        .accessibilityAddTraits(
            prospect.stableID == selectedProspect?.stableID ? .isSelected : []
        )
    }

    private func rowValue(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
            .foregroundStyle(palette.contentSecondary.color)
            .frame(width: width)
            .lineLimit(1)
    }

    private var accessibleProspectRows: some View {
        VStack(spacing: .zero) {
            ForEach(model.prospects, id: \.stableID) { prospect in
                Button {
                    selectedProspectID = prospect.stableID
                } label: {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("#\(prospect.boardRank) · \(prospect.person.name)")
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                            Spacer()
                            Text(prospect.position)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.heavy))
                        }
                        Text("\(prospect.hometown) · \(prospect.interest) interest")
                            .foregroundStyle(palette.contentSecondary.color)
                        Text("\(prospect.status) · \(prospect.evaluation.schemeFit) fit")
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .padding(CoachWorldTokens.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        prospect.stableID == selectedProspect?.stableID
                            ? palette.collegeIdentity.color.opacity(0.14)
                            : Color.clear
                    )
                    .overlay(alignment: .leading) {
                        if prospect.stableID == selectedProspect?.stableID {
                            Rectangle().fill(palette.collegeIdentity.color)
                                .frame(width: RecruitingMetric.selectedRuleWidth)
                        }
                    }
                    .overlay(alignment: .bottom) { seam }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(prospectAccessibilityLabel(prospect))
                .accessibilityAddTraits(
                    prospect.stableID == selectedProspect?.stableID ? .isSelected : []
                )
            }
        }
    }

    @ViewBuilder
    private var dossier: some View {
        if let prospect = selectedProspect {
            VStack(spacing: .zero) {
                ScrollView {
                    VStack(alignment: .leading, spacing: .zero) {
                        personHeader(prospect)
                        evaluation(prospect)
                        relationship(prospect)
                    }
                }
                actionDesk(prospect)
                    .background(palette.page.color)
                    .overlay(alignment: .top) { seam }
            }
            .coachWorldDeskSurface(
                fill: palette.page.color,
                border: palette.contentQuiet.color.opacity(0.38)
            )
            .accessibilitySortPriority(80)
        } else {
            ContentUnavailableView(
                "No prospect selected",
                systemImage: "person.crop.rectangle",
                description: Text("Select a prospect to review the staff evaluation.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.page.color)
        }
    }

    private func personHeader(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        HStack(alignment: .top, spacing: CoachWorldTokens.Space.sm) {
            CoachWorldBlankPhotoPlate(
                name: prospect.person.name,
                palette: palette,
                width: RecruitingMetric.photoWidth,
                height: RecruitingMetric.photoHeight
            )
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text("BOARD #\(prospect.boardRank) · \(prospect.position)")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                Text(prospect.person.name)
                    .font(CoachWorldTokens.TypeRole.title.weight(.black))
                    .lineLimit(2)
                Text("\(prospect.hometown) · \(prospect.status)")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(2)
            }
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.collegeIdentity.color.opacity(0.08))
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Board rank \(prospect.boardRank), \(prospect.person.name), "
                + "\(prospect.position), \(prospect.hometown), \(prospect.status)"
        )
    }

    private func evaluation(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("STAFF EVALUATION")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(prospect.evaluation.verdict)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: CoachWorldTokens.Space.md) {
                metric("SCHEME FIT", prospect.evaluation.schemeFit)
                metric("UNCERTAINTY", prospect.evaluation.uncertainty)
            }
            if !prospect.evaluation.citedOutliers.isEmpty {
                Text(prospect.evaluation.citedOutliers.prefix(3).joined(separator: " · "))
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(CoachWorldTokens.Space.sm)
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.body.weight(.black))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func relationship(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("RELATIONSHIP LOG")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            if prospect.relationshipHistory.isEmpty {
                Text("No contact recorded")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                ForEach(prospect.relationshipHistory, id: \.stableID) { event in
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text("\(event.dateLabel) · \(event.summary)")
                            .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                        Text(event.effect)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(CoachWorldTokens.Space.sm)
        .overlay(alignment: .bottom) { seam }
    }

    private func actionDesk(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("ASSIGN RECRUITING WORK")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            if prospect.choices.isEmpty {
                Text("No action is currently available")
                    .font(CoachWorldTokens.TypeRole.body)
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                ForEach(prospect.choices, id: \.intentID) { choice in
                    Button {
                        onAction(prospect.stableID, choice.intentID)
                    } label: {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            HStack {
                                Text(choice.title)
                                    .font(CoachWorldTokens.TypeRole.body.weight(.black))
                                Spacer()
                                Text(choice.cost)
                                    .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                                    .foregroundStyle(palette.collegeIdentity.color)
                            }
                            Text(choice.consequence)
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentSecondary.color)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: CoachWorldTokens.Shape.minimumTarget,
                            alignment: .leading
                        )
                        .background(palette.work.color)
                        .overlay {
                            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius).stroke(
                                choice.isAvailable
                                    ? palette.actionPrimary.color
                                    : palette.contentQuiet.color,
                                lineWidth: CoachWorldTokens.Shape.hairline
                            )
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!choice.isAvailable)
                    .accessibilityLabel(
                        "\(choice.title). Cost: \(choice.cost). Consequence: "
                            + "\(choice.consequence)"
                    )
                }
            }
        }
        .padding(CoachWorldTokens.Space.sm)
    }

    private var worldContextLine: String {
        let sample = model.provenance == .sample ? "Sample career · " : ""
        return sample
            + "\(model.capacity.scholarshipSlotsRemaining) scholarships · "
            + "\(model.capacity.weeklyHoursRemaining) recruiting hours"
    }

    private var positionPlanLine: String {
        model.positionNeeds.map { need in
            "\(need.position) \(need.committed)/\(need.target)"
        }.joined(separator: " · ")
    }

    private func prospectAccessibilityLabel(
        _ prospect: RecruitingBoardReadModel.Prospect
    ) -> String {
        "Board rank \(prospect.boardRank), \(prospect.person.name), "
            + "\(prospect.position), \(prospect.hometown), \(prospect.interest) interest, "
            + "\(prospect.status), \(prospect.evaluation.schemeFit) scheme fit"
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.38))
            .frame(height: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.38))
            .frame(width: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }
}

private struct RecruitingCollegeCutShape: Shape {
    let cut: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: rect.origin)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private enum RecruitingMetric {
    static let worldStripHeight: CGFloat = 56
    static let dossierWidth: CGFloat = 318
    static let boardHeaderHeight: CGFloat = 44
    static let capacityHeight: CGFloat = 44
    static let tableHeaderHeight: CGFloat = 24
    static let rowHeight: CGFloat = 44
    static let rankWidth: CGFloat = 24
    static let positionWidth: CGFloat = 34
    static let interestWidth: CGFloat = 54
    static let statusWidth: CGFloat = 84
    static let fitWidth: CGFloat = 56
    static let photoWidth: CGFloat = 52
    static let photoHeight: CGFloat = 64
    static let collegeCut: CGFloat = 8
    static let selectedRuleWidth: CGFloat = 3
}
