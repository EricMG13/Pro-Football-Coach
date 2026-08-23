import SwiftUI

public struct RosterView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RosterReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onInspectDevelopment: (String) -> Void
    public let onOpenProfile: ((String) -> Void)?
    public let showsRecruitingBoard: Bool
    private let showsAcademicYear: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var workspaceGap = CoachWorldTokens.Space.xs
    @State private var selectedPlayerID: String
    @State private var sort = RosterSortDescriptor(field: .overall, isAscending: false)
    @State private var presentedProfile: PlayerProfileReadModel?

    public init(
        model: RosterReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onInspectDevelopment: @escaping (String) -> Void,
        onOpenProfile: ((String) -> Void)? = nil,
        showsRecruitingBoard: Bool = false
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onInspectDevelopment = onInspectDevelopment
        self.onOpenProfile = onOpenProfile
        self.showsRecruitingBoard = showsRecruitingBoard
        self.showsAcademicYear = model.players.contains { !$0.academicYear.isEmpty }
        _selectedPlayerID = State(initialValue: model.players.first?.stableID ?? "")
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var visiblePlayers: [RosterReadModel.PlayerRow] {
        sort.sorted(model.players)
    }

    private var selectedPlayer: RosterReadModel.PlayerRow? {
        model.players.first(where: { $0.stableID == selectedPlayerID })
            ?? model.players.first
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    // The shared chrome's identity header already states the programme, so drawing
                    // this surface's own strip as well stacks two navigations.
                    if chrome == nil { worldStrip }
                    // The identity header already lists this family's surfaces; drawing them
                    // again as tabs is the same navigation twice on one screen.
                    if chrome == nil { personnelRoutes }
                    standardLayout
                }
            }
        }
        // `children: .contain` before the identifier, not the identifier alone. An accessibility
        // property applied to a container propagates down and the outer one wins, so a bare
        // `.accessibilityIdentifier` here renamed every descendant to `roster-screen` -- the
        // composition's own `ax-reflow` marker included, which made the accessibility-size proof
        // unable to see its own precondition. `.contain` names this container and leaves its
        // children their own identifiers.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("roster-screen")
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: 16) }
        .onChange(of: model.players.map(\.stableID), initial: true) { _, stableIDs in
            if !stableIDs.contains(selectedPlayerID) {
                selectedPlayerID = stableIDs.first ?? ""
            }
        }
        .sheet(item: $presentedProfile) { profile in
            PlayerProfileView(
                model: profile,
                team: model.team,
                onClose: { presentedProfile = nil },
                onInspectDevelopment: onInspectDevelopment
            )
        }
    }

    private var worldStrip: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                CoachWorldTeamLogo(
                    team: model.team,
                    size: .large,
                    surface: palette.raised,
                    palette: palette
                )
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(model.team.name.uppercased())
                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        .lineLimit(1)
                    Text(statusMessage ?? worldContextLine)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(worldContextInk)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(identity?.onField.color ?? palette.contentPrimary.color)
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(maxHeight: .infinity)
            .background(identity?.field.color ?? palette.raised.color)
            .overlay(alignment: .trailing) {
                // Canon 6.1: a generated field below 3:1 against the surface behind it is spoken
                // by a boundary, because the colour alone cannot be relied on to separate them.
                if identity?.needsBoundary == true { verticalSeam }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")

            Divider().overlay(palette.contentQuiet.color)

            HStack(spacing: .zero) {
                route("Office", screen: .coachingHQ)
                route("Inbox", screen: .inbox)
                route("Film", screen: .opponentReportFilmRoom)
                route("Team", screen: .roster, current: true)
                if showsRecruitingBoard { route("Recruit", screen: .recruitingBoard) }
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
        .frame(height: RosterMetric.worldStripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(50)
    }

    /// Selection speaks in the programme's colour where a reader can see it against the working
    /// surface, and falls back to the tier token where the generated pair cannot clear 3:1.
    private var selectionColour: CoachWorldTokens.ColorValue {
        identity?.selectionRule(on: palette.work) ?? palette.collegeIdentity
    }

    private var worldContextInk: Color {
        if statusMessage != nil, identity == nil { return palette.statePositive.color }
        return (identity?.onField ?? palette.contentSecondary).color
    }

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: model.team,
            behind: palette.raised,
            inks: [palette.contentPrimary, palette.page]
        )
    }

    private var personnelRoutes: some View {
        HStack(spacing: .zero) {
            personnelRoute("Roster", screen: .roster, isCurrent: true)
            personnelRoute("Depth", screen: .depthChart)
            personnelRoute("Health", screen: .teamHealth)
            personnelRoute("Development", screen: .developmentPlan)
            personnelRoute("Staff", screen: .staffRoom)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.page.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(40)
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
            selection: selectionColour,
            action: { onNavigate(screen) }
        )
    }

    private func personnelRoute(
        _ title: String,
        screen: CoachWorldScreenID,
        isCurrent: Bool = false
    ) -> some View {
        Button(action: { onNavigate(screen) }) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .background(isCurrent ? selectionColour.color.opacity(0.16) : Color.clear)
        .overlay(alignment: .bottom) {
            if isCurrent {
                Rectangle()
                    .fill(selectionColour.color)
                    .frame(height: RosterMetric.selectedRuleWidth)
                    .accessibilityHidden(true)
            }
        }
        .disabled(!isCurrent && screen != .depthChart && screen != .teamHealth && screen != .inbox)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var summaryRibbon: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: .zero) {
                    summaryValue("Roster", "\(model.players.count)/\(model.rosterLimit)")
                    summaryValue("Injuries", "\(model.injuryCount)")
                    summaryValue("Open needs", "\(model.openNeedCount)")
                    if showsAcademicYear { summaryValue("Class balance", classBalance) }
                }
            } else {
                HStack(spacing: .zero) {
                    summaryValue("ROSTER", "\(model.players.count)/\(model.rosterLimit)")
                    summaryValue("INJURIES", "\(model.injuryCount)")
                    summaryValue("OPEN NEEDS", "\(model.openNeedCount)")
                    if showsAcademicYear {
                        summaryValue("CLASS BALANCE", classBalance, fitsContent: true)
                    }
                }
            }
        }
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(100)
    }

    private func summaryValue(
        _ label: String,
        _ value: String,
        fitsContent: Bool = false
    ) -> some View {
        // The class-balance value is four terms long, so a label-beside-value cell
        // hyphenates the label and wraps the value at this width. Stacking keeps both
        // on one line each without shrinking type below the dense-screen floor, and
        // the long cell takes its natural width so the short counts absorb the rest.
        VStack(alignment: .leading, spacing: .zero) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .monospacedDigit()
        }
        // One line keeps the dense ribbon on its 44-point band. At accessibility sizes
        // the ribbon is already a scrolling column, so wrapping beats truncating a
        // class balance that carries four counts.
        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        .fixedSize(horizontal: fitsContent, vertical: false)
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .frame(
            maxWidth: fitsContent ? nil : .infinity,
            minHeight: RosterMetric.summaryHeight,
            alignment: .leading
        )
        .overlay(alignment: .trailing) { verticalSeam }
        .accessibilityElement(children: .combine)
    }

    private var standardLayout: some View {
        GeometryReader { proxy in
            let availableWidth = max(
                .zero,
                proxy.size.width - workspaceGap - (CoachWorldTokens.Space.xs * 2)
            )
            HStack(spacing: workspaceGap) {
                rosterSurface
                    .frame(width: availableWidth * RosterMetric.tableFraction)
                inspector
                    .frame(width: availableWidth * (1 - RosterMetric.tableFraction))
            }
            .padding(.horizontal, CoachWorldTokens.Space.xs)
        }
    }

    private var rosterSurface: some View {
        VStack(spacing: .zero) {
            summaryRibbon
            if model.players.isEmpty {
                CoachWorldSystemState(
                    .empty(
                        "No players on the roster. Players appear here when a career "
                            + "roster is available."
                    ),
                    palette: palette
                )
            } else {
                comparisonTable
            }
        }
        .coachWorldFloodlitPanel(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity),
            depth: .deep
        )
        .accessibilitySortPriority(100)
    }

    private var comparisonTable: some View {
        VStack(spacing: .zero) {
            tableHeader
            ScrollView {
                LazyVStack(spacing: .zero) {
                    ForEach(visiblePlayers, id: \.id) { player in
                        rosterRow(player)
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        // The reference's column order: POS, NO., PLAYER, YR, RATING, FIT, FRESH, AVAILABLE.
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            sortButton("POS", accessibilityName: "Position", field: .position,
                       width: RosterMetric.positionWidth)
            sortButton("NO.", accessibilityName: "Number", field: .number,
                       width: RosterMetric.numberWidth, alignment: .trailing)
            sortButton("PLAYER", accessibilityName: "Player", field: .name,
                       alignment: .leading)
                .layoutPriority(1)
            if showsAcademicYear { tableHeading("YR", width: RosterMetric.yearWidth) }
            sortButton("RATING", accessibilityName: "Rating", field: .overall,
                       width: RosterMetric.ratingWidth)
            tableHeading("FIT", width: RosterMetric.fitWidth)
            sortButton("FRESH", accessibilityName: "Freshness", field: .condition,
                       width: RosterMetric.freshWidth)
            tableHeading("AVAILABLE", width: RosterMetric.statusWidth)
        }
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .frame(minHeight: RosterMetric.headerHeight)
        .background(palette.page.color)
        .overlay(alignment: .bottom) { seam }
    }

    private func sortButton(
        _ title: String,
        accessibilityName: String,
        field: RosterSortField,
        width: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        Button(action: { toggleSort(field) }) {
            HStack(spacing: CoachWorldTokens.Space.xxs) {
                Text(title)
                    .lineLimit(1)
                if sort.field == field {
                    Image(systemName: sort.isAscending ? "chevron.up" : "chevron.down")
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
            .frame(width: width)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
        .foregroundStyle(palette.contentSecondary.color)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .accessibilityLabel("Sort by \(accessibilityName)")
        .accessibilityValue(
            sort.field == field ? (sort.isAscending ? "Ascending" : "Descending") : ""
        )
    }

    private func tableHeading(
        _ title: String,
        width: CGFloat,
        alignment: Alignment = .center
    ) -> some View {
        Text(title)
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.contentSecondary.color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(width: width, alignment: alignment)
    }

    private func rosterRow(_ player: RosterReadModel.PlayerRow) -> some View {
        let isSelected = player.stableID == selectedPlayer?.stableID
        return Button(action: { selectedPlayerID = player.stableID }) {
            HStack(spacing: CoachWorldTokens.Space.xxs) {
                // The slot, as a role token in cool ink — registry #18, and what maps a table row
                // to a place on the field diagram.
                Text(player.position.uppercased())
                    .foregroundStyle(palette.stateInfo.color)
                    .frame(width: RosterMetric.positionWidth, alignment: .leading)
                Text("\(player.number)")
                    .monospacedDigit()
                    .foregroundStyle(palette.actionPrimary.color)
                    .frame(width: RosterMetric.numberWidth, alignment: .trailing)
                Text(player.person.name)
                    .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                Spacer(minLength: CoachWorldTokens.Gap.xxs)
                if showsAcademicYear {
                    Text(player.academicYear)
                        .foregroundStyle(palette.contentSecondary.color)
                        .frame(width: RosterMetric.yearWidth)
                }
                ratingCell(player.overall)
                Text(player.schemeFit)
                    .frame(width: RosterMetric.fitWidth)
                // Freshness is a proportion of full condition, so the arc family's 4 pt step is
                // the right mark — beside the figure, never instead of it.
                HStack(spacing: CoachWorldTokens.Gap.xxs) {
                    Text("\(player.condition)")
                        .monospacedDigit()
                        .foregroundStyle(ratingColor(player.condition))
                    FloodlitShareBar(
                        proportion: Double(player.condition) / 100,
                        tint: ratingColor(player.condition),
                        palette: palette
                    )
                    .frame(width: RosterMetric.freshBar)
                }
                .frame(width: RosterMetric.freshWidth)
                Text(player.availability)
                    .foregroundStyle(availabilityColor(player.availability))
                    .frame(width: RosterMetric.statusWidth)
            }
            .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(height: RosterMetric.rowContentHeight)
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
            .contentShape(Rectangle())
            .background(
                isSelected
                    ? selectionColour.color.opacity(0.14)
                    : palette.raised.color.opacity(0.34)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(selectionColour.color)
                        .frame(width: RosterMetric.selectedRuleWidth)
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottom) { seam }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playerAccessibilityLabel(player))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func ratingCell(_ rating: Int) -> some View {
        Text("\(rating)")
            .monospacedDigit()
            .foregroundStyle(ratingColor(rating))
            .frame(width: RosterMetric.ratingWidth)
    }

    private func developmentDeltaCell(_ delta: Int?) -> some View {
        let text = delta.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "—"
        return Text(text)
            .monospacedDigit()
            .foregroundStyle(developmentDeltaColor(delta))
            .frame(width: RosterMetric.ratingWidth)
    }

    @ViewBuilder
    private var inspector: some View {
        if let selected = selectedPlayer {
            ScrollView {
                inspectorContent(selected)
            }
            .coachWorldFloodlitPanel(
                fill: palette.page.color,
                border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity)
            )
            .accessibilitySortPriority(80)
        } else {
            CoachWorldSystemState(
                .empty("No player selected. Select a player to review the dossier."),
                palette: palette
            )
        }
    }

    private func inspectorContent(_ selected: RosterReadModel.PlayerRow) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            // The reference leads the dossier with the rating as a ValueRing beside the name,
            // not a photo plate — the rating is what the row was selected for.
            HStack(alignment: .center, spacing: CoachWorldTokens.Space.sm) {
                CoachWorldRatingRing(
                    value: selected.overall,
                    diameter: RosterMetric.dossierRing,
                    palette: palette
                )
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(selected.person.name)
                        .font(CoachWorldTokens.TypeRole.title.weight(.black))
                        .lineLimit(1)
                    Text(
                        [selected.academicYear, "#\(selected.number)", selected.position]
                            .filter { !$0.isEmpty }
                            .joined(separator: " · ")
                    )
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
            }
            .accessibilityElement(children: .combine)
            .padding(CoachWorldTokens.Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.raised.color.opacity(0.5))

            dossierAttributes(selected)
            if !selected.profile.concern.isEmpty {
                inspectorSection("CONCERN", selected.profile.concern)
            }
            inspectorSection(
                "AVAILABILITY",
                "\(selected.availability) · Condition \(selected.condition)"
            )

            Button("Open full dossier") {
                if let onOpenProfile {
                    onOpenProfile(selected.stableID)
                } else {
                    presentedProfile = selected.profile
                }
            }
            .accessibilityIdentifier("roster-open-dossier")
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
            .padding(CoachWorldTokens.Space.sm)
        }
    }


    /// The reference's four attribute bars. Each is a rating on the 40-99 scale, so the heat bands
    /// apply here — unlike the week hub's stakeholder standing, which is a different scale.
    @ViewBuilder
    private func dossierAttributes(_ selected: RosterReadModel.PlayerRow) -> some View {
        let attributes = selected.profile.attributeGroups
            .flatMap(\.attributes)
            .prefix(RosterMetric.dossierAttributeCount)
        if !attributes.isEmpty {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                FloodlitLabel3("Attributes", palette: palette)
                ForEach(Array(attributes), id: \.stableID) { attribute in
                    HStack(spacing: CoachWorldTokens.Gap.xs) {
                        Text(attribute.label.uppercased())
                            .font(
                                CoachWorldTokens.display(
                                    CoachWorldTokens.DisplaySize.flag, weight: .bold
                                )
                            )
                            .foregroundStyle(palette.contentSecondary.color)
                            .frame(width: RosterMetric.attributeLabel, alignment: .leading)
                        FloodlitShareBar(
                            proportion: proportion(of: attribute.value),
                            tint: ratingColor(attribute.value),
                            palette: palette
                        )
                        Text("\(attribute.value)")
                            .font(
                                CoachWorldTokens.figure(
                                    CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                                )
                            )
                            .frame(width: RosterMetric.attributeValue, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(attribute.label), \(attribute.value)")
                }
            }
            .padding(CoachWorldTokens.Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { seam }
        }
    }

    /// Where the rating sits on the 40-99 scale, which is the proportion a bar may draw. Drawing
    /// `value / 100` would make a 40 — the floor of the scale — look like 40 per cent of something.
    private func proportion(of rating: Int) -> Double {
        let floor = Double(CoachWorldTokens.Heat.scaleFloor)
        let ceiling = Double(CoachWorldTokens.Heat.scaleCeiling)
        return min(1, max(0, (Double(rating) - floor) / (ceiling - floor)))
    }

    private func inspectorSection(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { seam }
        .accessibilityElement(children: .combine)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: .zero) {
                summaryRibbon
                if model.players.isEmpty {
                    CoachWorldSystemState(
                        .empty(
                            "No players on the roster. Players appear here when a career "
                                + "roster is available."
                        ),
                        palette: palette
                    )
                } else {
                    accessibleRosterRows
                    if let selected = selectedPlayer {
                        inspectorContent(selected)
                    }
                }
                accessibleWorldRoutes
            }
        }
        .accessibilitySortPriority(100)
    }

    private var accessibleRosterRows: some View {
        LazyVStack(spacing: .zero) {
            ForEach(visiblePlayers, id: \.id) { player in
                let isSelected = player.stableID == selectedPlayer?.stableID
                Button(action: { selectedPlayerID = player.stableID }) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("#\(player.number) · \(player.person.name)")
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                            Spacer()
                            Text(player.position)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.heavy))
                        }
                        Text(
                            [player.academicYear, player.rosterRole]
                                .filter { !$0.isEmpty }
                                .joined(separator: " · ")
                        )
                            .foregroundStyle(palette.contentSecondary.color)
                        accessibleRating("OVR", player.overall)
                        accessibleDevelopmentDelta(player.developmentDelta)
                        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xxs) {
                            Text("FIT")
                                .foregroundStyle(palette.contentSecondary.color)
                            Text(player.schemeFit)
                        }
                        accessibleRating("COND", player.condition)
                        Text(player.availability)
                            .foregroundStyle(availabilityColor(player.availability))
                    }
                    .padding(CoachWorldTokens.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected ? selectionColour.color.opacity(0.14) : Color.clear
                    )
                    .overlay(alignment: .leading) {
                        if isSelected {
                            Rectangle()
                                .fill(selectionColour.color)
                                .frame(width: RosterMetric.selectedRuleWidth)
                                .accessibilityHidden(true)
                        }
                    }
                    .overlay(alignment: .bottom) { seam }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(playerAccessibilityLabel(player))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func accessibleRating(_ label: String, _ rating: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .foregroundStyle(palette.contentSecondary.color)
            Text("\(rating)")
                .monospacedDigit()
                .foregroundStyle(ratingColor(rating))
        }
    }

    private func accessibleDevelopmentDelta(_ delta: Int?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xxs) {
            Text("DEV change")
                .foregroundStyle(palette.contentSecondary.color)
            Text(delta.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "No recorded change")
                .monospacedDigit()
                .foregroundStyle(developmentDeltaColor(delta))
        }
    }

    private var accessibleWorldRoutes: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("WORLD")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text("\(model.team.name) · \(model.coach.name)")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Text(statusMessage ?? worldContextLine)
                .foregroundStyle(palette.contentSecondary.color)
            route("Office", screen: .coachingHQ)
            route("Inbox", screen: .inbox)
            route("Film", screen: .opponentReportFilmRoom)
            route("Team", screen: .roster, current: true)
            route("Health", screen: .teamHealth)
            if showsRecruitingBoard { route("Recruit", screen: .recruitingBoard) }
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

    private func toggleSort(_ field: RosterSortField) {
        sort = RosterSortDescriptor(
            field: field,
            isAscending: sort.field == field ? !sort.isAscending : true
        )
    }

    private func ratingColor(_ rating: Int) -> Color {
        if rating >= 85 { return palette.statePositive.color }
        if rating >= 70 { return palette.stateWarning.color }
        return palette.stateNegative.color
    }

    private func developmentDeltaColor(_ delta: Int?) -> Color {
        guard let delta else { return palette.contentSecondary.color }
        if delta > 0 { return palette.statePositive.color }
        if delta < 0 { return palette.stateNegative.color }
        return palette.contentSecondary.color
    }

    private func availabilityColor(_ availability: String) -> Color {
        availability == "Available"
            ? palette.statePositive.color
            : palette.stateWarning.color
    }

    private func playerAccessibilityLabel(_ player: RosterReadModel.PlayerRow) -> String {
        [
            "Number \(player.number)",
            player.person.name,
            player.position,
            player.academicYear,
            player.rosterRole,
            "overall \(player.overall)",
            "development change \(player.developmentDelta.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "none")",
            "fit \(player.schemeFit)",
            "condition \(player.condition)",
            player.availability,
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private var classBalance: String {
        let counts = Dictionary(grouping: model.players, by: \.academicYear)
            .mapValues(\.count)
        return ["FR", "SO", "JR", "SR"]
            .map { "\($0) \(counts[$0, default: 0])" }
            .joined(separator: " · ")
    }

    private var worldContextLine: String {
        [model.coach.name, model.seasonLabel, model.weekLabel, model.recordLabel, model.rankLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
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

private enum RosterMetric {
    static let dossierRing: CGFloat = 44
    static let dossierAttributeCount = 4
    static let attributeLabel: CGFloat = 62
    static let attributeValue: CGFloat = 26

    /// The reference's academic-year and freshness columns.
    static let yearWidth: CGFloat = 30
    static let freshWidth: CGFloat = 66
    static let freshBar: CGFloat = 34

    static let worldStripHeight: CGFloat = 48
    static let summaryHeight: CGFloat = 44
    static let headerHeight: CGFloat = 44
    static let rowContentHeight: CGFloat = 28
    static let selectedRuleWidth: CGFloat = 3
    static let markWidth: CGFloat = 34
    static let markHeight: CGFloat = 22
    static let tableFraction: CGFloat = 0.68
    static let numberWidth: CGFloat = 28
    static let positionWidth: CGFloat = 34
    static let ratingWidth: CGFloat = 78
    static let fitWidth: CGFloat = 46
    static let statusWidth: CGFloat = 60
    static let photoWidth: CGFloat = 52
    static let photoHeight: CGFloat = 64
}
