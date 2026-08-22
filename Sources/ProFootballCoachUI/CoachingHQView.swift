import SwiftUI

public struct CoachingHQView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?

    public let model: CoachingHQReadModel
    public let statusMessage: String?
    public let onCommit: (CoachWorldIntentID) -> Void
    public let onInspect: () -> Void
    public let onDelegate: () -> Void
    public let onPrepare: () -> Void
    public let onContinue: () -> Void
    public let onOpenCorrespondence: (String) -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let showsProOffseason: Bool
    public let showsDraftRoom: Bool
    public let showsSigningDay: Bool
    public let showsCollegeOffseason: Bool
    public let showsProManagement: Bool
    public let showsContractNegotiation: Bool
    public let showsRecruitingBoard: Bool
    public let showsRealignmentEvent: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var deskGap = CoachWorldTokens.Space.xs
    @State private var selectedChoiceID: CoachWorldIntentID?

    public init(
        model: CoachingHQReadModel,
        statusMessage: String? = nil,
        onCommit: @escaping (CoachWorldIntentID) -> Void,
        onInspect: @escaping () -> Void,
        onDelegate: @escaping () -> Void,
        onPrepare: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        onOpenCorrespondence: @escaping (String) -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        showsProOffseason: Bool = false,
        showsDraftRoom: Bool = false,
        showsSigningDay: Bool = false,
        showsCollegeOffseason: Bool = false,
        showsProManagement: Bool = false,
        showsContractNegotiation: Bool = false,
        showsRecruitingBoard: Bool = false,
        showsRealignmentEvent: Bool = false
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onInspect = onInspect
        self.onDelegate = onDelegate
        self.onPrepare = onPrepare
        self.onContinue = onContinue
        self.onOpenCorrespondence = onOpenCorrespondence
        self.onNavigate = onNavigate
        self.showsProOffseason = showsProOffseason
        self.showsDraftRoom = showsDraftRoom
        self.showsSigningDay = showsSigningDay
        self.showsCollegeOffseason = showsCollegeOffseason
        self.showsProManagement = showsProManagement
        self.showsContractNegotiation = showsContractNegotiation
        self.showsRecruitingBoard = showsRecruitingBoard
        self.showsRealignmentEvent = showsRealignmentEvent
        _selectedChoiceID = State(initialValue: nil)
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            VStack(spacing: .zero) {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibleLayout
                } else {
                    // The shared chrome's identity header states the programme, record and next
                    // fixture. Drawing this surface's own strip as well stacked two navigations on
                    // top of each other.
                    if chrome == nil { worldStrip }
                    standardLayout
                }
            }
        }
    }

    private var worldStrip: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: CoachWorldTokens.Space.xs) {
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(model.team.name.uppercased())
                            .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        Text(accessibleWorldContextLine)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")
                    worldMenu.frame(maxWidth: .infinity, alignment: .leading)
                    continueButton.frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Space.sm) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text("COACH'S WORLD")
                            .coachWorldDisplay(CoachWorldTokens.TypeRole.microLabelSize)
                            .tracking(CoachWorldTokens.TypeRole.microLabelTracking)
                            .foregroundStyle(palette.actionPrimary.color)
                        Text(model.team.name.uppercased())
                            .font(CoachWorldTokens.TypeRole.title.weight(.black))
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")

                    Rectangle()
                        .fill(palette.contentQuiet.color.opacity(0.45))
                        .frame(width: CoachWorldTokens.Shape.hairline, height: 28)
                        .accessibilityHidden(true)
                    HStack(spacing: CoachWorldTokens.Space.xxs) {
                        route("Office", screen: .coachingHQ, current: true)
                        route("Inbox", screen: .inbox)
                        route("Film", screen: .opponentReportFilmRoom)
                        route("Team", screen: .roster)
                        if showsRecruitingBoard { route("Recruit", screen: .recruitingBoard) }
                        route("League", screen: .leagueMap)
                        route("Health", screen: .teamHealth)
                        worldMenu
                    }
                    .frame(maxWidth: .infinity)
                    continueButton
                }
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.md)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? CoachWorldTokens.Space.xs : .zero)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : HQMetric.worldStripHeight)
        .background(palette.page.color.opacity(CoachWorldTokens.Depth.deepPanelOpacity))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.actionPrimary.color.opacity(0.72))
                .frame(height: 2)
        }
        .accessibilitySortPriority(50)
    }

    private var worldMenu: some View {
        Menu("World") {
            Button("Office") { onNavigate(.coachingHQ) }
            Button("Settings & accessibility") { onNavigate(.settingsAccessibility) }
            Button("Inbox") { onNavigate(.inbox) }
            Button("Film") { onNavigate(.opponentReportFilmRoom) }
            Button("Team") { onNavigate(.roster) }
            if showsRecruitingBoard {
                Button("Recruit") { onNavigate(.recruitingBoard) }
            }
            Button("League") { onNavigate(.leagueMap) }
            Button("Career") { onNavigate(.careerHub) }
            Button("News") { onNavigate(.news) }
            Button("Record book") { onNavigate(.recordBook) }
            Button("Rivalries") { onNavigate(.rivalries) }
            Button("Career line") { onNavigate(.careerLine) }
            Button("Coaching tree") { onNavigate(.coachingTree) }
            Button("Statistics & leaders") { onNavigate(.statisticsLeaders) }
            Button("Awards & honours") { onNavigate(.awardsHonours) }
            if showsRealignmentEvent {
                Button("Realignment event") { onNavigate(.realignmentEvent) }
            }
            Button("Search") { onNavigate(.worldSearch) }
            Button("Game plan") { onNavigate(.gamePlan) }
            Button("Practice") { onNavigate(.practicePlan) }
            Button("Depth chart") { onNavigate(.depthChart) }
            Button("Team health") { onNavigate(.teamHealth) }
            Button("Staff room") { onNavigate(.staffRoom) }
            if showsProOffseason {
                Button("Pro offseason") { onNavigate(.proOffseason) }
                if showsDraftRoom {
                    Button("Draft room") { onNavigate(.draftRoom) }
                }
            }
            if showsCollegeOffseason {
                Button("College offseason") { onNavigate(.collegeOffseason) }
            }
            if showsRecruitingBoard {
                if showsSigningDay {
                    Button("Signing day") { onNavigate(.signingDay) }
                }
                Button("Class overview") { onNavigate(.classOverview) }
                Button("Contact & visit planner") { onNavigate(.contactVisitPlanner) }
            }
            if showsProManagement {
                Button("Cap & contracts") { onNavigate(.capContracts) }
                if showsContractNegotiation {
                    Button("Contract negotiation") { onNavigate(.contractNegotiation) }
                }
                Button("Roster cuts & transactions") { onNavigate(.rosterCutsTransactions) }
            }
            Button("Rankings") { onNavigate(.rankingsPlayoffPicture) }
            Button("Postseason") { onNavigate(.bracketPostseason) }
        }
        .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
               minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private var continueButton: some View {
        let available = canAdvance
        return Button(action: onContinue) {
            Label("Continue · \(mandatoryCount) due", systemImage: "forward.end.fill")
        }
            .buttonStyle(CoachWorldActionButtonStyle(
                role: available ? .live : .secondary,
                palette: palette
            ))
            .disabled(!available)
            .accessibilityHint(
                available
                    ? "Advances the week."
                    : "Complete preparation and clear mandatory decisions before advancing."
            )
    }

    private func route(_ title: String, screen: CoachWorldScreenID, current: Bool = false) -> some View {
        CoachWorldRouteButton(
            title: title,
            isCurrent: current,
            palette: palette,
            action: { onNavigate(screen) }
        )
    }

    /// The week hub as the Floodlit reference draws it: the week's open agenda on the left, the
    /// one decision in the middle, availability and standing on the right, and the single
    /// committing action bottom-right.
    ///
    /// The columns are the reference's named widths, not fluid — `04` section 6.1c states that
    /// content columns are deliberate.
    private var standardLayout: some View {
        HStack(alignment: .top, spacing: CoachWorldTokens.Gap.smPlus) {
            weekAgendaColumn.frame(width: HQMetric.agendaColumn)
            decisionColumn.frame(maxWidth: .infinity, alignment: .topLeading)
            supportColumn.frame(width: HQMetric.supportColumn)
        }
    }

    // MARK: The week's agenda

    private var weekAgendaColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(
                "\(model.week.weekLabel) \u{00B7} \(model.week.currentDay)", palette: palette
            )
            Text("\(model.obligations.count) OPEN")
                .coachWorldDisplay(HQMetric.heroSize, weight: .heavy)
                .foregroundStyle(palette.contentPrimary.color)
                .lineLimit(1)
                .minimumScaleFactor(HQMetric.heroScaleFloor)
            VStack(spacing: CoachWorldTokens.Gap.hair) {
                ForEach(model.obligations, id: \.stableID) { obligation in
                    FloodlitRow(palette: palette) {
                        HStack(spacing: CoachWorldTokens.Gap.xs) {
                            Text(obligation.title.uppercased())
                                .coachWorldDisplay(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                                .lineLimit(1)
                                .minimumScaleFactor(HQMetric.rowScaleFloor)
                            Spacer(minLength: CoachWorldTokens.Gap.xxs)
                            FloodlitLabel3(
                                obligation.isMandatory ? "Must" : "Open",
                                palette: palette,
                                tint: palette.actionPrimary.color
                            )
                        }
                    }
                }
            }
            Spacer(minLength: .zero)
        }
        .accessibilitySortPriority(70)
    }

    // MARK: The decision

    @ViewBuilder
    private var decisionColumn: some View {
        if let decision = model.decision {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                HStack {
                    FloodlitLabel3(
                        model.opponent.map { "\(decision.deadline) \u{00B7} \($0.name)" }
                            ?? decision.deadline,
                        palette: palette
                    )
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    FloodlitLabel3("You decide", palette: palette, tint: palette.actionPrimary.color)
                }
                Text(decision.title)
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.lead, weight: .bold)
                    .fixedSize(horizontal: false, vertical: true)
                if let evidence = decision.evidence.first {
                    Text(evidence)
                        .font(CoachWorldTokens.TypeRole.body)
                        .foregroundStyle(palette.contentSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: CoachWorldTokens.Gap.xxs) {
                    ForEach(decision.choices, id: \.intentID) { choice in
                        choiceRow(choice)
                    }
                }
                HStack(spacing: CoachWorldTokens.Gap.xs) {
                    FloodlitLabel3("Why it is here", palette: palette)
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                    secondaryAction("Open film", action: onInspect)
                    secondaryAction("Delegate", action: onDelegate)
                }
                Spacer(minLength: .zero)
            }
            .accessibilitySortPriority(90)
        } else {
            noDecision
        }
    }

    /// One option, carrying its own cost. The interface never says which to pick, so there is no
    /// recommended state here (`04` section 4.4).
    private func choiceRow(_ choice: CoachWorldActionChoice) -> some View {
        FloodlitRow(
            isSelected: selectedChoiceID == choice.intentID,
            palette: palette,
            action: {
                selectedChoiceID = choice.intentID
                onCommit(choice.intentID)
            }
        ) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text(choice.title.uppercased())
                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.row, weight: .bold)
                    .lineLimit(1)
                FloodlitCostLine(
                    cost: choice.cost,
                    exposure: choice.isAvailable ? nil : choice.unavailableReason,
                    palette: palette
                )
            }
        }
        .disabled(!choice.isAvailable)
        .opacity(choice.isAvailable ? 1 : CoachWorldTokens.Motion.disabledOpacity)
    }

    private func secondaryAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                .tracking(
                    CoachWorldTokens.DisplaySize.tracking(0.1, at: CoachWorldTokens.DisplaySize.flag)
                )
                .padding(.horizontal, CoachWorldTokens.Gap.md)
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.contentSecondary.color)
        .overlay {
            CoachWorldCutCorner.row.stroke(
                Color.white.opacity(0.14), lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
        .contentShape(CoachWorldCutCorner.row)
    }

    // MARK: Availability and standing

    private var supportColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
            if !model.squadHealth.isEmpty {
                FloodlitCard(palette: palette, depth: .deep) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                        FloodlitLabel3("Squad health", palette: palette)
                        ForEach(model.squadHealth) { row in
                            HStack(spacing: CoachWorldTokens.Gap.xs) {
                                Text(row.slot.uppercased())
                                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                                    .foregroundStyle(palette.stateInfo.color)
                                    .frame(width: HQMetric.slotColumn, alignment: .leading)
                                Text(row.player)
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .lineLimit(1)
                                Spacer(minLength: CoachWorldTokens.Gap.xxs)
                                Text(row.status)
                                    .coachWorldDisplay(CoachWorldTokens.DisplaySize.flag, weight: .bold)
                                    .foregroundStyle(
                                        row.isConcern
                                            ? palette.stateWarning.color
                                            : palette.stateLive.color
                                    )
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(row.slot) \(row.player), \(row.status)")
                        }
                    }
                }
            }

            if !model.stakeholders.isEmpty {
                FloodlitCard(palette: palette, depth: .deep) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                        FloodlitLabel3("Stakeholders", palette: palette)
                        ForEach(model.stakeholders) { row in
                            HStack(spacing: CoachWorldTokens.Gap.xs) {
                                Text(row.name)
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .lineLimit(1)
                                Spacer(minLength: CoachWorldTokens.Gap.xxs)
                                Text("\(row.support)")
                                    .coachWorldFigure(CoachWorldTokens.DisplaySize.actionSmall, weight: .bold)
                                // Support is a proportion of a stated whole, so an arc is legitimate
                                // here — and it is a second reading of the printed figure, never the
                                // only one.
                                // One tint, not the rating heat bands: those are defined for the
                                // 40-99 rating scale, and support is a 0-100 standing. Colouring a
                                // 58 support red because 58 is a poor *rating* states something
                                // the figure does not mean.
                                FloodlitShareBar(
                                    proportion: Double(row.support) / 100, palette: palette
                                )
                                .frame(width: HQMetric.supportBar)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(row.name), support \(row.support) of 100")
                        }
                    }
                }
            }

            Spacer(minLength: .zero)

            Text("\(model.obligations.count) still open")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
            FloodlitCommittingAction("Advance", isEnabled: canAdvance, action: onContinue)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilitySortPriority(60)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: deskGap) {
                decisionFloor
                if let decision = model.decision {
                    decisionActions(decision)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .background(palette.work.color)
                        .overlay(alignment: .top) { seam }
                }
                // The shared chrome states the programme; drawing this as well stacks two navigations.
                if chrome == nil { worldStrip }
                HStack(alignment: .top, spacing: deskGap) {
                    identityRail
                    deskWire
                }
                // Neither column takes a fixed width of its own -- standardLayout applies that at
                // its call site -- so both flow full width here instead of the side-by-side
                // columns standardLayout uses. Without these, accessibleLayout carried no way to
                // advance the week at all (its only continueButton call sat inside worldStrip,
                // itself gated on chrome == nil, which production's shared-chrome construction
                // never satisfies) and silently dropped squad health and stakeholders too.
                weekAgendaColumn
                supportColumn
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var identityRail: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("\(model.week.seasonLabel) · \(model.week.weekLabel)".uppercased())
                .coachWorldDisplay(CoachWorldTokens.TypeRole.microLabelSize)
                .tracking(CoachWorldTokens.TypeRole.microLabelTracking)
                .foregroundStyle(palette.actionPrimary.color)
            Text(model.week.currentDay.uppercased())
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            if let obligation = model.obligations.first {
                Text(obligation.consequence)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            seam
            if let opponent = model.opponent {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text("NEXT FIXTURE")
                        .coachWorldDisplay(CoachWorldTokens.TypeRole.microLabelSize)
                        .tracking(CoachWorldTokens.TypeRole.microLabelTracking)
                        .foregroundStyle(palette.contentQuiet.color)
                    Text(opponent.name.uppercased())
                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                    Text(model.venue?.name ?? "Venue not set")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .accessibilityElement(children: .combine)
            }
            if let recommendation = model.staffRecommendation {
                HStack(alignment: .top, spacing: CoachWorldTokens.Space.xs) {
                    CoachWorldBlankPhotoPlate(
                        name: recommendation.staff.name,
                        palette: palette,
                        width: 48,
                        height: 54
                    )
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(recommendation.staff.name).font(.headline)
                            .lineLimit(2)
                        Text(recommendation.staff.role)
                            .font(.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.actionPrimary.color.opacity(0.42)
        )
        .accessibilitySortPriority(40)
    }

    private var decisionFloor: some View {
        VStack(spacing: .zero) {
            weekPlan
            if let decision = model.decision {
                decisionSurface(decision)
            } else {
                noDecision
            }
        }
        .coachWorldFloodlitPanel(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.55),
            depth: .deep
        )
        .accessibilitySortPriority(100)
    }

    private var weekPlan: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(accessibleCurrentDayLabel)
                        .foregroundStyle(palette.page.color)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .background(palette.collegeIdentity.color)
                    Text(model.week.nextDeadline)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                       alignment: .leading)
            } else {
                HStack(spacing: .zero) {
                    ForEach(model.weekPlan, id: \.stableID) { day in
                        Text("\(day.dayLabel)\n\(day.assignment)")
                            .multilineTextAlignment(.center)
                            .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                            .frame(maxWidth: .infinity,
                                   minHeight: CoachWorldTokens.Shape.minimumTarget)
                            .background(day.isCurrent ? palette.actionPrimary.color : Color.clear)
                            .foregroundStyle(
                                // S-2, 2026-08-19 review: was a hand-typed Color(red:green:blue:)
                                // literal, ~1/255 per channel off the canon `goldInk` token
                                // (0x150F02) that already exists for exactly this ink-on-gold
                                // case -- FloodlitPatterns.swift:335 and MatchDayField.swift:651
                                // use it the same way, ink on an isCurrent/isSelected gold ground.
                                day.isCurrent ? CoachWorldTokens.Floodlit.goldInk.color
                                    : palette.contentPrimary.color
                            )
                            .accessibilityLabel("\(day.dayLabel), \(day.assignment)")
                            .accessibilityAddTraits(day.isCurrent ? .isSelected : [])
                            .overlay(alignment: .trailing) { verticalSeam }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) { seam }
    }

    private func decisionSurface(_ decision: CoachingHQReadModel.Decision) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("DUE · \(decision.deadline.uppercased())")
                            Spacer()
                            Text("\(unallocatedTimeLabel) unallocated")
                        }
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.collegeIdentity.color)
                        Text(decision.title)
                            .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                        decisionEvidence(decision)
                    }
                } else {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            Text("DUE · \(decision.deadline.uppercased())")
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                .foregroundStyle(palette.collegeIdentity.color)
                                .lineLimit(1)
                            Text(decision.title)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            decisionEvidence(decision)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: CoachWorldTokens.Space.xxs) {
                            Text(unallocatedTimeLabel)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                            Text("UNALLOCATED").font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        }
                        .foregroundStyle(palette.collegeIdentity.color)
                        .frame(width: 104, alignment: .trailing)
                        .accessibilityLabel("\(unallocatedTimeLabel) unallocated")
                    }
                }
            }

            VStack(spacing: CoachWorldTokens.Space.xs) {
                ForEach(decision.choices, id: \.intentID) { choice in
                    choiceButton(choice)
                }
            }

            if !dynamicTypeSize.isAccessibilitySize {
                decisionActions(decision)
            }
        }
        .padding(CoachWorldTokens.Space.sm)
    }

    @ViewBuilder
    private func decisionEvidence(_ decision: CoachingHQReadModel.Decision) -> some View {
        if let evidence = decision.evidence.first {
            Text(evidence)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(2)
        }
        if let recommendation = model.staffRecommendation {
            Text("\(recommendation.staff.name): \(recommendation.verdict) · \(recommendation.confidence) confidence")
                .font(CoachWorldTokens.TypeRole.caption.weight(.semibold))
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(2)
        }
    }

    private func decisionActions(_ decision: CoachingHQReadModel.Decision) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    selectionReceiptView(in: decision)
                    filmButton.frame(maxWidth: .infinity)
                    delegateButton.frame(maxWidth: .infinity)
                    commitButton.frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Space.xxs) {
                    selectionReceiptView(in: decision)
                    filmButton
                    delegateButton
                    commitButton
                }
            }
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func selectionReceiptView(in decision: CoachingHQReadModel.Decision) -> some View {
        Text(selectionReceipt(in: decision))
            .font(CoachWorldTokens.TypeRole.caption)
            .foregroundStyle(palette.contentSecondary.color)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                   alignment: .leading)
    }

    private var filmButton: some View {
        Button(action: onInspect) {
            Label("Open film room", systemImage: "film")
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .accessibilityLabel("Inspect film")
        .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
    }

    private var delegateButton: some View {
        Button(action: onDelegate) {
            Image(systemName: "person.2")
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
            .accessibilityLabel("Delegate")
            .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
    }

    private var commitButton: some View {
        Button {
            if let selectedChoiceID { onCommit(selectedChoiceID) }
        } label: {
            Label("Set work", systemImage: "checkmark")
        }
        .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        .layoutPriority(1)
        .disabled(selectedChoiceID == nil)
    }

    private func choiceButton(_ choice: CoachWorldActionChoice) -> some View {
        let selected = selectedChoiceID == choice.intentID
        return Button {
            selectedChoiceID = choice.intentID
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.sm) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    HStack {
                        Text(choice.title).font(.headline)
                        Spacer()
                        Text(choice.cost).font(.caption.weight(.bold))
                    }
                    if !choice.consequence.isEmpty {
                        Text(choice.consequence)
                            .font(CoachWorldTokens.TypeRole.callout)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                }
            }
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(
                selected
                    ? palette.collegeIdentity.color.opacity(0.14)
                    : palette.raised.color.opacity(0.5)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                    .stroke(
                        selected
                            ? palette.collegeIdentity.color
                            : palette.contentQuiet.color.opacity(0.65),
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
        }
        .buttonStyle(.plain)
        .disabled(!choice.isAvailable)
        .accessibilityLabel(
            "\(choice.title). Cost: \(choice.cost)"
                + (choice.consequence.isEmpty ? "" : ". Consequence: \(choice.consequence)")
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var deskWire: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text("YOUR DESK").font(.headline.weight(.black))
                Spacer()
                Text("\(mandatoryCount) DUE")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(palette.stateWarning.color)
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .overlay(alignment: .bottom) { seam }

            ForEach(model.correspondence, id: \.stableID) { item in
                Button { onOpenCorrespondence(item.stableID) } label: {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text("\(item.received) · \(item.isUnread ? "ANSWER" : "READ")")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(palette.collegeIdentity.color)
                        Text(item.subject).font(.callout.weight(.semibold))
                        Text(item.sender.name)
                            .font(.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                    .padding(.horizontal, CoachWorldTokens.Space.sm)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { seam }
            }

            if let opponent = model.opponent {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    Text("NEXT FIXTURE").font(.caption.weight(.heavy))
                    Text(opponent.name).font(.headline)
                    Text(model.venue?.name ?? "Venue not set")
                        .font(.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .padding(CoachWorldTokens.Space.sm)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .top)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(0.55)
        )
        .accessibilitySortPriority(30)
    }

    private var noDecision: some View {
        VStack(spacing: CoachWorldTokens.Space.sm) {
            ContentUnavailableView(
                preparationNeeded
                    ? "Weekly preparation required"
                    : (mandatoryCount > 0 ? "Mandatory work remains" : "No mandatory work"),
                systemImage: preparationNeeded ? "clipboard" : "checkmark.circle",
                description: Text(
                    statusMessage ?? (preparationNeeded
                        ? "Set a game plan and practice plan before the controlled fixture."
                        : (mandatoryCount > 0
                            ? "Clear the remaining mandatory work before the week can advance."
                            : model.week.nextDeadline))
                )
            )
            if preparationNeeded {
                Button("Delegate balanced preparation", action: onPrepare)
                    .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                    .accessibilityHint("Commits the balanced game and practice plans for this week.")
            }
            if model.opponent != nil {
                filmButton.frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mandatoryCount: Int {
        model.obligations.filter(\.isMandatory).count
    }

    private var canAdvance: Bool {
        mandatoryCount == 0 && model.decision == nil && !preparationNeeded
    }

    private var preparationNeeded: Bool {
        model.weekPlan.contains { plan in
            plan.isCurrent && (plan.dayLabel == "Game plan" || plan.dayLabel == "Practice")
        }
    }

    private func selectionReceipt(in decision: CoachingHQReadModel.Decision) -> String {
        if let statusMessage { return statusMessage }
        guard let selectedChoiceID,
              let choice = decision.choices.first(where: { $0.intentID == selectedChoiceID })
        else { return "Choose · unsaved" }
        let shortTitle = choice.title.split(separator: "·").first.map(String.init) ?? choice.title
        return "\(shortTitle) · \(choice.cost) · not saved"
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(height: CoachWorldTokens.Shape.hairline)
    }

    private var worldContextLine: String {
        [model.coach.name, model.week.seasonLabel, model.week.weekLabel,
         model.recordLabel, model.rankLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var accessibleWorldContextLine: String {
        [model.week.weekLabel, model.recordLabel, model.rankLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var accessibleCurrentDayLabel: String {
        guard let current = model.weekPlan.first(where: \.isCurrent) else {
            return model.week.currentDay.uppercased()
        }
        return "\(current.dayLabel.uppercased()) · \(current.assignment.uppercased())"
    }

    private var unallocatedTimeLabel: String {
        let minutes = max(model.unallocatedPracticeMinutes, 0)
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 { return "\(hours)h" }
        if hours == 0 { return "\(remainder)m" }
        return "\(hours)h \(remainder)m"
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(width: CoachWorldTokens.Shape.hairline)
    }
}

private enum HQMetric {
    /// The reference's named column widths. Deliberate, not fluid (`04` section 6.1c).
    static let agendaColumn: CGFloat = 150
    static let supportColumn: CGFloat = 250
    /// The week's open count is the surface's dominant object, so it takes display-figure size.
    static let heroSize: CGFloat = 34
    static let heroScaleFloor: CGFloat = 0.6
    static let rowScaleFloor: CGFloat = 0.7
    static let slotColumn: CGFloat = 34
    static let supportBar: CGFloat = 44

    static let worldStripHeight: CGFloat = 52
}
