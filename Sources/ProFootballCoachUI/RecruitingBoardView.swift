import SwiftUI

public struct RecruitingBoardView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RecruitingBoardReadModel
    public let statusMessage: String?
    public let onAction: (String, CoachWorldIntentID) -> Void
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onOpenProspect: (String) -> Void
    public let onOpenShortlist: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var deskGap = CoachWorldTokens.Space.xs
    @State private var selectedProspectID: String
    @State private var pendingWithdrawal: PendingWithdrawal?

    public init(
        model: RecruitingBoardReadModel,
        statusMessage: String? = nil,
        onAction: @escaping (String, CoachWorldIntentID) -> Void,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onOpenProspect: @escaping (String) -> Void = { _ in },
        onOpenShortlist: @escaping () -> Void = {}
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onOpenProspect = onOpenProspect
        self.onOpenShortlist = onOpenShortlist
        _selectedProspectID = State(
            initialValue: model.prospects.first?.stableID
                ?? model.discovery.first?.stableID
                ?? ""
        )
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var selectedProspect: RecruitingBoardReadModel.Prospect? {
        model.prospects.first(where: { $0.stableID == selectedProspectID })
            ?? model.discovery.first(where: { $0.stableID == selectedProspectID })
            ?? model.prospects.first
            ?? model.discovery.first
    }

    private var hasProspects: Bool {
        !model.prospects.isEmpty || !model.discovery.isEmpty
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    // The shared chrome's identity header already states the programme.
                    if chrome == nil { worldStrip }
                    standardLayout
                }
            }
        }
        .alert(item: $pendingWithdrawal) { pending in
            Alert(
                title: Text("Withdraw \(pending.name)?"),
                message: Text(
                    "This drops all recorded interest, any scheduled visit and any scholarship "
                        + "offer. There is no undo."
                ),
                primaryButton: .destructive(Text("Withdraw")) {
                    onAction(pending.id, CoachWorldIntentID(rawValue: "withdraw"))
                },
                secondaryButton: .cancel()
            )
        }
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: 24) }
    }

    /// Withdraw is the one destructive choice a prospect's action desk offers, so it alone routes
    /// through a confirmation rather than firing on tap like Contact, Evaluate or Offer scholarship.
    /// `id` is the prospect's own `stableID` -- `RecruitingBoardReadModel.Prospect` is `Equatable`
    /// but not `Identifiable`, and `.alert(item:)` needs an identity to key its presentation on.
    private struct PendingWithdrawal: Identifiable {
            let id: String
            let name: String
    }

    private var worldStrip: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
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
                Label("Advance week", systemImage: "forward.end.fill")
            }
                .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                .disabled(!model.canContinue)
                .accessibilityHint(model.continueReason ?? "")
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
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
            isCurrent: current,
            palette: palette,
            action: { onNavigate(screen) }
        )
    }

    private var standardLayout: some View {
        HStack(spacing: deskGap) {
            boardSurface
                .frame(maxWidth: .infinity)
            dossier
                .frame(width: RecruitingMetric.dossierWidth)
        }
        .padding(.horizontal, CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: .zero) {
                boardHeader
                if !hasProspects {
                    CoachWorldSystemState(
                        .empty(
                            "No prospects on the board. Add evaluated prospects before "
                                + "assigning recruiting time."
                        ),
                        palette: palette
                    )
                } else {
                    accessibleProspectRows
                    accessibleDiscoveryRows
                    capacityStrip
                    if let prospect = selectedProspect {
                        personHeader(prospect)
                        evaluation(prospect)
                        relationship(prospect)
                        surfaceLinks(prospect)
                        actionDesk(prospect)
                    }
                }
                accessibleWorldContext
            }
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
            Button("Advance week", action: onContinue)
                .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                .disabled(!model.canContinue)
                .accessibilityHint(model.continueReason ?? "")
        }
        .padding(CoachWorldTokens.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.raised.color)
        .overlay(alignment: .top) { seam }
        .accessibilitySortPriority(50)
    }

    private var boardSurface: some View {
        VStack(spacing: .zero) {
            boardHeader
            capacityStrip
            if !hasProspects {
                CoachWorldSystemState(
                    .empty(
                        "No prospects on the board. Add evaluated prospects before "
                            + "assigning recruiting time."
                    ),
                    palette: palette
                )
            } else {
                // The rows scroll inside the panel, so the panel frames the pane at its full
                // height. Scrolling the panel itself would push its cut corners and lower border
                // off-screen on a full board, and spread the specular gradient over the whole
                // content height instead of the pane.
                ScrollView(.vertical) {
                    VStack(spacing: .zero) {
                        comparisonTable
                        discoveryTable
                    }
                }
                positionPlanFooter
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .coachWorldFloodlitPanel(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity),
            depth: .deep
        )
        .accessibilitySortPriority(100)
    }


    /// The class plan every row on the board is judged against (`MLB 0/2 · WR 2/3 · …`).
    ///
    /// A footer, not a header chip: it is the sum of the table above it, and in the header it
    /// competed with the title and truncated.
    private var positionPlanFooter: some View {
        HStack(spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3("Position plan", palette: palette)
            Text(positionPlanLine)
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(1)
                .minimumScaleFactor(RecruitingMetric.planScaleFloor)
            Spacer(minLength: .zero)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: RecruitingMetric.planHeight)
        .overlay(alignment: .top) { seam }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Position plan. \(positionPlanLine)")
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
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                }
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(minHeight: RecruitingMetric.boardHeaderHeight)
        .overlay(alignment: .bottom) { seam }
        .accessibilityElement(children: .combine)
    }

    private var boardTitle: some View {
        Text("RECRUITING BOARD")
            .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    private var sampleCareerFlag: some View {
        Text("SAMPLE CAREER")
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.page.color)
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(minHeight: RecruitingMetric.fixtureFlagHeight)
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
                        "Contact points",
                        value: "\(model.capacity.weeklyHoursRemaining)"
                    )
                    compactCapacity(
                        "Visits",
                        value: "\(model.capacity.officialVisitsRemaining)"
                    )
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.lg) {
                    capacityValue(
                        "SLOTS",
                        value: "\(model.capacity.scholarshipSlotsRemaining)",
                        suffix: "open"
                    )
                    capacityValue(
                        "CONTACT",
                        value: "\(model.capacity.weeklyHoursRemaining)",
                        suffix: "left"
                    )
                    capacityValue(
                        "VISITS",
                        value: "\(model.capacity.officialVisitsRemaining)",
                        suffix: "left"
                    )
                    Spacer(minLength: .zero)
                }
                .padding(.horizontal, CoachWorldTokens.Pad.row.h)
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
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .frame(maxWidth: .infinity, minHeight: RecruitingMetric.capacityHeight)
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
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .fixedSize(horizontal: true, vertical: false)
        .frame(minHeight: RecruitingMetric.capacityHeight)
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
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(minHeight: RecruitingMetric.tableHeaderHeight)
            .background(palette.page.color)
            .overlay(alignment: .bottom) { seam }

            ForEach(model.prospects, id: \.stableID) { prospect in
                comparisonRow(prospect)
            }
            Spacer(minLength: .zero)
        }
        // Acquisition Room, `04` section 2: "a rank may travel, because the movement is the fact
        // being reported" -- the one register where a reorder is itself the content, not decoration.
        // Rows are already keyed by stableID rather than array position, which is what lets SwiftUI
        // interpolate a reorder instead of cross-fading unrelated rows into each other's places.
        .coachWorldAnimation(CoachWorldTokens.Motion.world, value: model.prospects)
    }

    private var discoveryTable: some View {
        Group {
            if !model.discovery.isEmpty {
                VStack(spacing: .zero) {
                    Text("DISCOVERY · AVAILABLE PROSPECTS")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.collegeIdentity.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .frame(minHeight: RecruitingMetric.tableHeaderHeight)
                        .background(palette.page.color)
                        .overlay(alignment: .bottom) { seam }
                    ForEach(model.discovery, id: \.stableID) { prospect in
                        comparisonRow(prospect)
                    }
                }
            }
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
                Text(prospect.boardRank == 0 ? "D" : "\(prospect.boardRank)")
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
            .padding(.horizontal, CoachWorldTokens.Space.xs)
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
            .overlay(alignment: .bottom) { seam }
        }
        .buttonStyle(.plain)
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

    private var accessibleDiscoveryRows: some View {
        Group {
            if !model.discovery.isEmpty {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    Text("DISCOVERY · AVAILABLE PROSPECTS")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.collegeIdentity.color)
                    ForEach(model.discovery, id: \.stableID) { prospect in
                        Button {
                            selectedProspectID = prospect.stableID
                        } label: {
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Discovery · \(prospect.person.name)")
                                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                                    Spacer()
                                    Text(prospect.position)
                                        .font(CoachWorldTokens.TypeRole.headline.weight(.heavy))
                                }
                                Text("\(prospect.hometown) · \(prospect.evaluation.schemeFit) fit")
                                    .foregroundStyle(palette.contentSecondary.color)
                                Text(prospect.status)
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
                .padding(.horizontal, CoachWorldTokens.Space.md)
                .padding(.vertical, CoachWorldTokens.Space.sm)
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
                        surfaceLinks(prospect)
                    }
                }
                actionDesk(prospect)
                    .background(palette.page.color)
                    .overlay(alignment: .top) { seam }
            }
            .coachWorldFloodlitPanel(
                fill: palette.page.color,
                border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
            )
            .accessibilitySortPriority(80)
        } else {
            // The empty dossier is still a bounded pane beside the board, so it keeps the panel
            // the filled dossier has. Only a full-screen ground would be dropped here.
            CoachWorldSystemState(
                .empty(
                    "No prospect selected. Select a prospect to review the system evaluation."
                ),
                palette: palette
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .coachWorldFloodlitPanel(
                fill: palette.page.color,
                border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
            )
            .accessibilitySortPriority(80)
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
                Text(prospect.boardRank == 0
                    ? "DISCOVERY · \(prospect.position)"
                    : "BOARD #\(prospect.boardRank) · \(prospect.position)")
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
            (prospect.boardRank == 0 ? "Discovery prospect" : "Board rank \(prospect.boardRank)")
                + ", \(prospect.person.name), "
                + "\(prospect.position), \(prospect.hometown), \(prospect.status)"
        )
    }

    private func evaluation(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("SYSTEM EVALUATION")
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

    private func actionTitle(_ choice: CoachWorldActionChoice) -> some View {
        Text(choice.title)
            .font(CoachWorldTokens.TypeRole.body.weight(.black))
    }

    private func actionConsequence(_ choice: CoachWorldActionChoice) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(choice.consequence)
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            // The provider always assigns unavailableReason a fallback string, never nil, so
            // this must gate on isAvailable itself -- otherwise an enabled choice draws a reason
            // its own state contradicts, e.g. Withdraw reading "This prospect is not on an active
            // board" directly beside its own working button.
            if !choice.isAvailable, let reason = choice.unavailableReason {
                Text(reason)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentQuiet.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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

    private func surfaceLinks(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("PROSPECT SURFACES")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                        prospectLinks(prospect)
                    }
                } else {
                    HStack(spacing: CoachWorldTokens.Space.xs) {
                        prospectLinks(prospect)
                    }
                }
            }
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .padding(.vertical, CoachWorldTokens.Space.xs)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func prospectLinks(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        Button("Open profile") { onOpenProspect(prospect.stableID) }
            .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        Button("Shortlist") { onOpenShortlist() }
            .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
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
                        if choice.intentID == CoachWorldIntentID(rawValue: "withdraw") {
                            pendingWithdrawal = PendingWithdrawal(
                                id: prospect.stableID, name: prospect.person.name
                            )
                        } else {
                            onAction(prospect.stableID, choice.intentID)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            HStack {
                                actionTitle(choice)
                                Spacer()
                                Text(choice.cost)
                                    .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                                    .foregroundStyle(palette.collegeIdentity.color)
                            }
                            actionConsequence(choice)
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
                            + (choice.isAvailable ? "" : (choice.unavailableReason
                                .map { ". Unavailable: \($0)" } ?? ""))
                    )
                }
            }
        }
        .padding(CoachWorldTokens.Space.sm)
    }

    private var worldContextLine: String {
        "\(model.capacity.scholarshipSlotsRemaining) scholarships · "
            + "\(model.capacity.weeklyHoursRemaining) contact points · "
            + "\(model.capacity.officialVisitsRemaining) visits"
    }

    private var positionPlanLine: String {
        model.positionNeeds.map { need in
            "\(need.position) \(need.committed)/\(need.target)"
        }.joined(separator: " · ")
    }

    private func prospectAccessibilityLabel(
        _ prospect: RecruitingBoardReadModel.Prospect
    ) -> String {
            (prospect.boardRank == 0 ? "Discovery prospect" : "Board rank \(prospect.boardRank)")
                + ", \(prospect.person.name), "
                + "\(prospect.position), \(prospect.hometown), \(prospect.interest) interest, "
            + "\(prospect.status), \(prospect.evaluation.schemeFit) scheme fit"
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))
            .frame(height: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))
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
    static let planHeight: CGFloat = 30
    static let planScaleFloor: CGFloat = 0.7

    static let worldStripHeight: CGFloat = 48
    static let dossierWidth: CGFloat = 326
    static let boardHeaderHeight: CGFloat = 36
    static let capacityHeight: CGFloat = 36
    static let tableHeaderHeight: CGFloat = 22
    static let rowHeight: CGFloat = 44
    static let rankWidth: CGFloat = 24
    static let positionWidth: CGFloat = 34
    static let interestWidth: CGFloat = 54
    static let statusWidth: CGFloat = 84
    static let fitWidth: CGFloat = 56
    static let photoWidth: CGFloat = 44
    static let photoHeight: CGFloat = 52
    static let fixtureFlagHeight: CGFloat = 28
    static let collegeCut: CGFloat = 8
    static let selectedRuleWidth: CGFloat = 3
}
