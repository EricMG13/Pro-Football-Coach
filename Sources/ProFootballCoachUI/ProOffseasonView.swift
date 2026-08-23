import SwiftUI
import FootballSimCore

public struct ProOffseasonView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: ProOffseasonReadModel
    public let title: String
    public let focus: CoachWorldScreenID
    /// The canonical destination this rendering *is*, which is not the same thing as `focus`.
    ///
    /// `focus` selects which board section shows, and the three aliases pass their own screen as
    /// the focus -- so deriving identity from it would stamp 37, 38 and 40 on surfaces the
    /// contract gives no identity of their own. Defaulted to 62 so those aliases inherit Pro
    /// Offseason; Draft Room passes 39, because it is canonical in its own right and only
    /// delegates its draft phase here.
    public let canonicalID: Int
    public let statusMessage: String?
    public let onAction: (ProMarketAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var openID: UUID?
    @State private var pendingMarketAction: PendingMarketAction?

    private struct PendingMarketAction: Identifiable {
        let id: String
        let action: ProOffseasonReadModel.ActionRow
        let subjectName: String?
    }

    public init(
        model: ProOffseasonReadModel,
        title: String = "PRO OFFSEASON",
        focus: CoachWorldScreenID = .proOffseason,
        canonicalID: Int = 62,
        statusMessage: String? = nil,
        onAction: @escaping (ProMarketAction) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
        self.focus = focus
        self.canonicalID = canonicalID
        self.statusMessage = statusMessage
        self.onAction = onAction
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .alert(item: $pendingMarketAction) { action in
            let label = action.subjectName.map { "\(action.action.title) for \($0)" }
                ?? action.action.title
            return Alert(
                title: Text("\(label)?"),
                message: Text(action.action.detail),
                primaryButton: .default(Text("\(label) · \(action.action.detail)")) {
                    onAction(action.action.action)
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: focus) { _, _ in openID = nil }
        .background(alignment: .topLeading) { CanonicalScreenStamp(id: canonicalID) }
        .onChange(of: model.phase) { _, _ in openID = nil }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                header
                capStrip
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !model.actions.isEmpty {
                    marketActions
                }
                if dynamicTypeSize.isAccessibilitySize {
                    listColumn
                    detailPanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        listColumn
                            .frame(width: OffseasonMetric.listColumn)
                        detailPanel
                            .frame(width: OffseasonMetric.detailColumn)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("\(title) \u{00B7} \(model.seasonLabel)", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(phaseLabel, palette: palette, tint: palette.actionPrimary.color)
        }
    }

    private var capStrip: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xs) {
                    capFigures
                }
            } else {
                HStack(spacing: CoachWorldTokens.Gap.xl) {
                    capFigures
                    Spacer(minLength: CoachWorldTokens.Gap.xs)
                }
            }
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: OffseasonMetric.capStripHeight, alignment: .leading)
        .background(
            CoachWorldCutCorner.row.fill(palette.work.color.opacity(OffseasonMetric.stripFill))
        )
    }

    @ViewBuilder
    private var capFigures: some View {
            capFigure("Cap room", currency(model.cap.remainingCap))
            capFigure("Committed", currency(model.cap.committedCap))
            capFigure("Dead money", currency(model.cap.deadMoney))
            capFigure(
                "Active", "\(model.cap.activeRosterCount)/\(ProRules.activeRosterLimit)"
            )
            if let currentPickTeamID = model.currentPickTeamID {
                capFigure(
                    "On the clock",
                    "\(model.nextPick + 1)/\(max(model.totalPicks, 1))"
                )
                .accessibilityLabel(
                    "On the clock, pick \(model.nextPick + 1) of \(max(model.totalPicks, 1)), "
                        + "team \(currentPickTeamID.uuidString)"
                )
            }
    }

    private func capFigure(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(label, palette: palette)
            Text(value)
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.row, weight: .semibold))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var marketActions: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.xxs) {
            FloodlitLabel3("Market actions", palette: palette)
            ForEach(model.actions) { row in genericActionRow(row) }
        }
    }

    private var listColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            if let focusUnavailableReason {
                CoachWorldSystemState(.empty(focusUnavailableReason), palette: palette)
            } else {
                if showsDraftCollection {
                    draftCollection
                }
                if showsFreeAgencyCollection {
                    freeAgencyCollection
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var draftCollection: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3(draftSectionTitle, palette: palette)
            if model.prospects.isEmpty {
                CoachWorldSystemState(
                    .empty("No draft class is currently open."), palette: palette
                )
            } else {
                ForEach(model.prospects) { prospect in prospectRow(prospect) }
            }
        }
    }

    @ViewBuilder
    private var freeAgencyCollection: some View {
        if !model.freeAgents.isEmpty || !model.waivers.isEmpty {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                FloodlitLabel3("Free agency", palette: palette)
                if !model.freeAgents.isEmpty {
                    FloodlitLabel3("Free agents", palette: palette)
                    ForEach(model.freeAgents) { player in freeAgentRow(player) }
                }
                if !model.waivers.isEmpty {
                    FloodlitLabel3("Waivers", palette: palette)
                    ForEach(model.waivers) { waiver in waiverRow(waiver) }
                }
            }
        } else {
            CoachWorldSystemState(.empty("No free agents are currently available."), palette: palette)
        }
    }

    private var showsDraftCollection: Bool {
        switch focus {
        case .proOffseason, .draftBoard, .draftRoom, .proScoutingBoard: true
        default: false
        }
    }

    private var showsFreeAgencyCollection: Bool {
        switch focus {
        case .proOffseason, .freeAgency: true
        default: false
        }
    }

    private var draftSectionTitle: String {
        switch focus {
        case .draftRoom: "Draft room"
        case .proScoutingBoard: "Scouting board"
        default: "Draft board"
        }
    }

    private var focusUnavailableReason: String? {
        switch focus {
        case .draftRoom where model.phase != .draft:
            return "Draft room is closed. The controlled draft clock is not active in this phase."
        case .freeAgency where model.phase != .freeAgency:
            return "Free agency is closed. No free-agent action is available in this phase."
        default:
            return nil
        }
    }

    private func prospectRow(_ prospect: ProOffseasonReadModel.ProspectRow) -> some View {
        FloodlitRow(
            isSelected: openID == prospect.id, palette: palette, action: { openID = prospect.id }
        ) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(prospect.position.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                    .foregroundStyle(palette.stateInfo.color)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: OffseasonMetric.positionColumn, alignment: .leading)
                Text(prospect.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(prospect.estimatedOverall.map { "\($0)" } ?? "\u{2014}")
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.row, weight: .semibold))
                    .foregroundStyle(
                        prospect.estimatedOverall == nil
                            ? palette.contentQuiet.color : palette.contentPrimary.color
                    )
            }
        }
        .accessibilityLabel(
            "\(prospect.name), \(prospect.position), "
                + (prospect.estimatedOverall.map { "estimated overall \($0)" } ?? "unscouted")
        )
    }

    private func freeAgentRow(_ player: ProOffseasonReadModel.FreeAgentRow) -> some View {
        FloodlitRow(isSelected: openID == player.id, palette: palette, action: { openID = player.id }) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(player.position.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                    .foregroundStyle(palette.stateInfo.color)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: OffseasonMetric.positionColumn, alignment: .leading)
                Text(player.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: CoachWorldTokens.Gap.xs)
            }
        }
        .accessibilityLabel("\(player.name), \(player.position)")
    }

    private func waiverRow(_ waiver: ProOffseasonReadModel.WaiverRow) -> some View {
        FloodlitRow(isSelected: openID == waiver.id, palette: palette, action: { openID = waiver.id }) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(waiver.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                FloodlitLabel3(
                    "Due \(waiver.deadline)", palette: palette, tint: palette.stateWarning.color
                )
            }
        }
        .accessibilityLabel("\(waiver.name), claim deadline \(waiver.deadline)")
    }

    /// The selected row's own action, or the market-wide note when nothing is selected.
    private var detailPanel: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("What you can do", palette: palette)
                if let action = openAction {
                    genericActionRow(action, subjectName: openSubjectName)
                } else {
                    Text("Select a name to see what you can do about it.")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var openAction: ProOffseasonReadModel.ActionRow? {
        guard focusUnavailableReason == nil else { return nil }
        guard let openID else { return nil }
        if showsDraftCollection,
           let prospect = model.prospects.first(where: { $0.id == openID }) {
            return prospect.action
        }
        if showsFreeAgencyCollection,
           let player = model.freeAgents.first(where: { $0.id == openID }) {
            return player.action
        }
        if showsFreeAgencyCollection,
           let waiver = model.waivers.first(where: { $0.id == openID }) {
            return waiver.action
        }
        return nil
    }

    private func genericActionRow(
        _ action: ProOffseasonReadModel.ActionRow,
        subjectName: String? = nil
    ) -> some View {
        FloodlitRow(
            palette: palette,
            action: action.isAvailable
                ? {
                    pendingMarketAction = PendingMarketAction(
                        id: action.id + (subjectName ?? ""),
                        action: action,
                        subjectName: subjectName
                    )
                }
                : nil
        ) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text(action.title.uppercased())
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .foregroundStyle(
                        action.isAvailable ? palette.actionPrimary.color : palette.contentQuiet.color
                    )
                    .lineLimit(1)
                Text(action.isAvailable ? action.detail : (action.unavailableReason ?? action.detail))
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityLabel(
            action.isAvailable
                ? "\(action.title). \(action.detail)"
                : "\(action.title), unavailable. \(action.unavailableReason ?? "")"
        )
    }

    private var openSubjectName: String? {
        guard focusUnavailableReason == nil else { return nil }
        guard let openID else { return nil }
        if showsDraftCollection,
           let prospect = model.prospects.first(where: { $0.id == openID }) {
            return prospect.name
        }
        if showsFreeAgencyCollection,
           let player = model.freeAgents.first(where: { $0.id == openID }) {
            return player.name
        }
        if showsFreeAgencyCollection,
           let waiver = model.waivers.first(where: { $0.id == openID }) {
            return waiver.name
        }
        return nil
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Every figure here is recorded. Nothing projects past this phase.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }

    private var phaseLabel: String {
        switch model.phase {
        case .closed: return "Closed"
        case .freeAgency: return "Free agency"
        case .draft: return "Draft"
        case .rosterBuild: return "Roster build"
        }
    }

    private func currency(_ value: Int) -> String {
        value < 0 ? "-$\(abs(value))" : "$\(value)"
    }
}

private enum OffseasonMetric {
    static let listColumn: CGFloat = 424
    static let detailColumn: CGFloat = 261
    static let positionColumn: CGFloat = 88
    static let capStripHeight: CGFloat = 32
    static let stripFill = 0.5
}
