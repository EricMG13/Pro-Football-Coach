import SwiftUI

public struct RosterView: View {
    public let model: RosterReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onOpenProfile: (PlayerProfileReadModel) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var workspaceGap = CoachWorldTokens.Space.xs
    @State private var selectedPlayerID: String
    @State private var sort = RosterSortDescriptor(field: .overall, isAscending: false)

    public init(
        model: RosterReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onOpenProfile: @escaping (PlayerProfileReadModel) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onOpenProfile = onOpenProfile
        _selectedPlayerID = State(initialValue: model.players.first?.stableID ?? "")
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    private var visiblePlayers: [RosterReadModel.PlayerRow] {
        sort.sorted(model.players)
    }

    private var selectedPlayer: RosterReadModel.PlayerRow? {
        model.players.first(where: { $0.stableID == selectedPlayerID })
            ?? model.players.first
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    worldStrip
                    personnelRoutes
                    standardLayout
                }
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .onChange(of: model.players.map(\.stableID), initial: true) { _, stableIDs in
            if !stableIDs.contains(selectedPlayerID) {
                selectedPlayerID = stableIDs.first ?? ""
            }
        }
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
                route("Team", screen: .roster, current: true)
                route("Recruit", screen: .recruitingBoard)
                route("League", screen: .leagueMap)
                route("Career", screen: .careerHub)
            }
            .frame(maxWidth: .infinity)

            Button(action: onContinue) {
                Label("Continue", systemImage: "forward.end.fill")
            }
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(height: RosterMetric.worldStripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(50)
    }

    private var personnelRoutes: some View {
        HStack(spacing: .zero) {
            personnelRoute("Roster", isCurrent: true)
            personnelRoute("Depth")
            personnelRoute("Development")
            personnelRoute("Staff")
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
            action: { onNavigate(screen) }
        )
    }

    private func personnelRoute(_ title: String, isCurrent: Bool = false) -> some View {
        Button(action: { if isCurrent { onNavigate(.roster) } }) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .background(isCurrent ? palette.collegeIdentity.color.opacity(0.16) : Color.clear)
        .overlay(alignment: .bottom) {
            if isCurrent {
                Rectangle()
                    .fill(palette.collegeIdentity.color)
                    .frame(height: RosterMetric.selectedRuleWidth)
                    .accessibilityHidden(true)
            }
        }
        .disabled(!isCurrent)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private var summaryRibbon: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: .zero) {
                    summaryValue("Roster", "\(model.players.count)/\(model.rosterLimit)")
                    summaryValue("Injuries", "\(model.injuryCount)")
                    summaryValue("Open needs", "\(model.openNeedCount)")
                    summaryValue("Class balance", classBalance)
                }
            } else {
                HStack(spacing: .zero) {
                    summaryValue("ROSTER", "\(model.players.count)/\(model.rosterLimit)")
                    summaryValue("INJURIES", "\(model.injuryCount)")
                    summaryValue("OPEN NEEDS", "\(model.openNeedCount)")
                    summaryValue("CLASS BALANCE", classBalance)
                }
            }
        }
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(100)
    }

    private func summaryValue(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Spacer(minLength: CoachWorldTokens.Space.xxs)
            Text(value)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .monospacedDigit()
        }
        .padding(.horizontal, CoachWorldTokens.Space.xs)
        .frame(maxWidth: .infinity, minHeight: RosterMetric.summaryHeight)
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
                ContentUnavailableView(
                    "No players on the roster",
                    systemImage: "person.3",
                    description: Text("Players appear here when a career roster is available.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                comparisonTable
            }
        }
        .background(palette.work.color)
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.38)
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
        HStack(spacing: CoachWorldTokens.Space.xxs) {
            sortButton("#", accessibilityName: "Number", field: .number,
                       width: RosterMetric.numberWidth, alignment: .trailing)
            sortButton("PLAYER", accessibilityName: "Player", field: .name,
                       alignment: .leading)
            sortButton("POS", accessibilityName: "Position", field: .position,
                       width: RosterMetric.positionWidth)
            sortButton("OVR", accessibilityName: "Overall", field: .overall,
                       width: RosterMetric.ratingWidth)
            sortButton("DEV", accessibilityName: "Development", field: .development,
                       width: RosterMetric.ratingWidth)
            tableHeading("FIT", width: RosterMetric.fitWidth)
            sortButton("COND", accessibilityName: "Condition", field: .condition,
                       width: RosterMetric.ratingWidth)
            tableHeading("STATUS", width: RosterMetric.statusWidth)
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
            .frame(width: width, alignment: alignment)
    }

    private func rosterRow(_ player: RosterReadModel.PlayerRow) -> some View {
        let isSelected = player.stableID == selectedPlayer?.stableID
        return Button(action: { selectedPlayerID = player.stableID }) {
            HStack(spacing: CoachWorldTokens.Space.xxs) {
                Text("\(player.number)")
                    .monospacedDigit()
                    .frame(width: RosterMetric.numberWidth, alignment: .trailing)
                VStack(alignment: .leading, spacing: .zero) {
                    Text(player.person.name)
                        .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                    Text("\(player.academicYear) · \(player.rosterRole)")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(player.position)
                    .frame(width: RosterMetric.positionWidth)
                ratingCell(player.overall)
                ratingCell(player.development)
                Text(player.schemeFit)
                    .frame(width: RosterMetric.fitWidth)
                ratingCell(player.condition)
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
                    ? palette.collegeIdentity.color.opacity(0.14)
                    : palette.raised.color.opacity(0.34)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(palette.collegeIdentity.color)
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

    @ViewBuilder
    private var inspector: some View {
        if let selected = selectedPlayer {
            ScrollView {
                inspectorContent(selected)
            }
            .coachWorldDeskSurface(
                fill: palette.page.color,
                border: palette.contentQuiet.color.opacity(0.38)
            )
            .accessibilitySortPriority(80)
        } else {
            ContentUnavailableView(
                "No player selected",
                systemImage: "person.crop.rectangle",
                description: Text("Select a player to review the dossier.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func inspectorContent(_ selected: RosterReadModel.PlayerRow) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top, spacing: CoachWorldTokens.Space.sm) {
                CoachWorldBlankPhotoPlate(
                    name: selected.person.name,
                    palette: palette,
                    width: RosterMetric.photoWidth,
                    height: RosterMetric.photoHeight
                )
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text("#\(selected.number) · \(selected.position)")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.collegeIdentity.color)
                    Text(selected.person.name)
                        .font(CoachWorldTokens.TypeRole.title.weight(.black))
                    Text("\(selected.academicYear) · \(selected.rosterRole)")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
            }
            .accessibilityElement(children: .combine)
            .padding(CoachWorldTokens.Space.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.collegeIdentity.color.opacity(0.08))

            inspectorSection("STRENGTHS", selected.profile.strengths.joined(separator: " · "))
            inspectorSection("CONCERN", selected.profile.concern)
            inspectorSection(
                "AVAILABILITY",
                "\(selected.availability) · Condition \(selected.condition)"
            )

            Button("Open dossier") {
                onOpenProfile(selected.profile)
            }
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private func inspectorSection(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
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
                    ContentUnavailableView(
                        "No players on the roster",
                        systemImage: "person.3",
                        description: Text("Players appear here when a career roster is available.")
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
        .background(palette.work.color)
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
                        Text("\(player.academicYear) · \(player.rosterRole)")
                            .foregroundStyle(palette.contentSecondary.color)
                        Text(
                            "OVR \(player.overall) · DEV \(player.development) · "
                                + "FIT \(player.schemeFit) · COND \(player.condition)"
                        )
                        .monospacedDigit()
                        Text(player.availability)
                            .foregroundStyle(availabilityColor(player.availability))
                    }
                    .padding(CoachWorldTokens.Space.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected ? palette.collegeIdentity.color.opacity(0.14) : Color.clear
                    )
                    .overlay(alignment: .leading) {
                        if isSelected {
                            Rectangle()
                                .fill(palette.collegeIdentity.color)
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

    private var accessibleWorldRoutes: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("WORLD")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text("\(model.team.name) · \(model.coach.name)")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            Text(statusMessage ?? worldContextLine)
                .foregroundStyle(palette.contentSecondary.color)
            route("Office", screen: .coachingHQ)
            route("Team", screen: .roster, current: true)
            route("Recruit", screen: .recruitingBoard)
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

    private func availabilityColor(_ availability: String) -> Color {
        availability == "Available"
            ? palette.statePositive.color
            : palette.stateWarning.color
    }

    private func playerAccessibilityLabel(_ player: RosterReadModel.PlayerRow) -> String {
        "Number \(player.number), \(player.person.name), \(player.position), "
            + "\(player.academicYear), \(player.rosterRole), overall \(player.overall), "
            + "development \(player.development), fit \(player.schemeFit), "
            + "condition \(player.condition), \(player.availability)"
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

private enum RosterMetric {
    static let worldStripHeight: CGFloat = 48
    static let summaryHeight: CGFloat = 36
    static let headerHeight: CGFloat = 44
    static let rowContentHeight: CGFloat = 28
    static let selectedRuleWidth: CGFloat = 3
    static let tableFraction: CGFloat = 0.64
    static let numberWidth: CGFloat = 28
    static let positionWidth: CGFloat = 34
    static let ratingWidth: CGFloat = 42
    static let fitWidth: CGFloat = 52
    static let statusWidth: CGFloat = 66
    static let photoWidth: CGFloat = 52
    static let photoHeight: CGFloat = 64
}
