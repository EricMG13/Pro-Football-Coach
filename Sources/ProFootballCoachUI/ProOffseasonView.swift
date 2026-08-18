import SwiftUI
import FootballSimCore

public struct ProOffseasonView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: ProOffseasonReadModel
    public let title: String
    public let statusMessage: String?
    public let onAction: (ProMarketAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var openID: UUID?

    public init(
        model: ProOffseasonReadModel,
        title: String = "PRO OFFSEASON",
        statusMessage: String? = nil,
        onAction: @escaping (ProMarketAction) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.title = title
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

    /// Named, not tappable: the four scouting/draft/free-agency routes switch through the shared
    /// chrome's sibling row, which is where every other multi-route family in this port switches.
    /// A second, unconnected set of stage pills here would be a control with nothing wired to it.
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.md) {
            FloodlitLabel3("\(title) \u{00B7} \(model.seasonLabel)", palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(phaseLabel, palette: palette, tint: palette.actionPrimary.color)
        }
    }

    private var capStrip: some View {
        HStack(spacing: CoachWorldTokens.Gap.xl) {
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
            Spacer(minLength: CoachWorldTokens.Gap.xs)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: OffseasonMetric.capStripHeight)
        .background(
            CoachWorldCutCorner.row.fill(palette.work.color.opacity(OffseasonMetric.stripFill))
        )
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

    /// This shell backs five real routes, not four: the four named wrapper views AND
    /// `ProOffseasonView` itself, reached directly via `CoachingHQView`'s "Pro offseason" button
    /// with the default title "PRO OFFSEASON" and no phase restriction. A title-text match
    /// (`title.contains("FREE AGENCY")`) picked one list and made the other two permanently
    /// unreachable from that fifth route regardless of `model.phase` -- during free agency itself,
    /// the hub screen would show the draft board and hide the very free agents it's the phase for.
    /// Showing every non-empty section, as the pre-conversion view already did, has no such
    /// blind spot: a route with nothing in a bucket already renders nothing for it.
    private var listColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.lg) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                FloodlitLabel3("Draft board", palette: palette)
                if model.prospects.isEmpty {
                    CoachWorldSystemState(
                        .empty("No draft class is currently open."), palette: palette
                    )
                } else {
                    ForEach(model.prospects) { prospect in prospectRow(prospect) }
                }
            }
            if !model.freeAgents.isEmpty || !model.waivers.isEmpty {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                    if !model.freeAgents.isEmpty {
                        FloodlitLabel3("Free agents", palette: palette)
                        ForEach(model.freeAgents) { player in freeAgentRow(player) }
                    }
                    if !model.waivers.isEmpty {
                        FloodlitLabel3("Waivers", palette: palette)
                        ForEach(model.waivers) { waiver in waiverRow(waiver) }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prospectRow(_ prospect: ProOffseasonReadModel.ProspectRow) -> some View {
        FloodlitRow(
            isSelected: openID == prospect.id, palette: palette, action: { openID = prospect.id }
        ) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(prospect.position.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                    .foregroundStyle(palette.stateInfo.color)
                    .lineLimit(1)
                    .frame(width: OffseasonMetric.positionColumn, alignment: .leading)
                Text(prospect.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(1)
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
                    .lineLimit(1)
                    .frame(width: OffseasonMetric.positionColumn, alignment: .leading)
                Text(player.name.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                    .lineLimit(1)
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
                    .lineLimit(1)
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
                    genericActionRow(action)
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
        guard let openID else { return nil }
        if let prospect = model.prospects.first(where: { $0.id == openID }) {
            return prospect.action
        }
        if let player = model.freeAgents.first(where: { $0.id == openID }) {
            return player.action
        }
        if let waiver = model.waivers.first(where: { $0.id == openID }) {
            return waiver.action
        }
        return nil
    }

    private func genericActionRow(_ action: ProOffseasonReadModel.ActionRow) -> some View {
        FloodlitRow(palette: palette, action: action.isAvailable ? { onAction(action.action) } : nil) {
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

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Every figure here is recorded. Nothing projects past this phase.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Done", action: onClose)
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
    static let positionColumn: CGFloat = 44
    static let capStripHeight: CGFloat = 32
    static let stripFill = 0.5
}
