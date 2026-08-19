import SwiftUI
import FootballSimCore

public struct ProManagementView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: ProManagementReadModel
    public let title: String
    public let statusMessage: String?
    public let onAction: (ProManagementAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var openPlayerID: UUID?
    @State private var pendingRelease: ProManagementReadModel.PlayerRow?

    public init(
        model: ProManagementReadModel,
        title: String = "CAP & CONTRACTS",
        statusMessage: String? = nil,
        onAction: @escaping (ProManagementAction) -> Void,
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
        .alert(item: $pendingRelease) { player in
            let deadMoney = player.contract?.deadMoney(ifReleasedAtSeason: model.calendar.season) ?? 0
            return Alert(
                title: Text("Release \(player.name)?"),
                message: Text(
                    "This removes the player from the roster and adds \(currency(deadMoney)) to dead money."
                ),
                primaryButton: .destructive(
                    Text("Release \(player.name) · add \(currency(deadMoney)) dead money")
                ) {
                    guard let action = player.action?.action else { return }
                    onAction(action)
                },
                secondaryButton: .cancel()
            )
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.md) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    capColumn
                    hitsColumn
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.xl) {
                        capColumn
                            .frame(width: ProManagementMetric.capColumn)
                        hitsColumn
                            .frame(width: ProManagementMetric.hitsColumn)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        FloodlitLabel3("\(title) \u{00B7} \(model.seasonLabel)", palette: palette)
    }

    /// The reference's own lead figure: cap room, at display size, with a plain state word beside
    /// it -- under the cap or over it, nothing softer.
    private var capColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                FloodlitLabel3("Cap room", palette: palette)
                Text(currency(model.cap.remainingCap))
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.name, weight: .bold))
                    .foregroundStyle(capTint)
                Text(model.cap.remainingCap >= 0 ? "Under the cap" : "Over the cap")
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.title, weight: .bold
                        )
                    )
                    .foregroundStyle(capTint)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Cap room \(currency(model.cap.remainingCap)), "
                    + (model.cap.remainingCap >= 0 ? "under the cap" : "over the cap")
            )
            VStack(alignment: .leading, spacing: .zero) {
                capFact("Committed", currency(model.cap.committedCap))
                capFact("Dead money", currency(model.cap.deadMoney), tint: palette.stateWarning.color)
                capFact("Cap limit", currency(model.cap.capLimit))
            }
            HStack(spacing: CoachWorldTokens.Gap.xl) {
                FloodlitArcGauge(
                    proportion: committedShare,
                    figure: "\(Int((committedShare * 100).rounded()))%",
                    caption: "Committed",
                    palette: palette
                )
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    FloodlitLabel3("Roster", palette: palette)
                    Text("\(model.cap.activeRosterCount)/\(ProRules.activeRosterLimit) active")
                        .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill))
                        .foregroundStyle(palette.contentSecondary.color)
                    Text("\(model.cap.practiceSquadCount)/\(ProRules.practiceSquadLimit) practice")
                        .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill))
                        .foregroundStyle(palette.contentSecondary.color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var capTint: Color {
        model.cap.remainingCap >= 0 ? palette.statePositive.color : palette.stateWarning.color
    }

    private var committedShare: Double {
        model.cap.capLimit > 0
            ? min(1, Double(model.cap.committedCap) / Double(model.cap.capLimit))
            : 0
    }

    private func capFact(_ label: String, _ value: String, tint: Color? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Gap.xs) {
            FloodlitLabel3(label, palette: palette)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Text(value)
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.row, weight: .semibold))
                .foregroundStyle(tint ?? palette.contentPrimary.color)
        }
        .frame(minHeight: ProManagementMetric.capFactHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(ProManagementMetric.seamAlpha))
                .frame(height: CoachWorldTokens.Shape.hairline)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    /// The reference's "Largest cap hits": every contracted player, heaviest hit first, with the
    /// term beside the figure. The roster's own action -- an extension, a cut, a restructure --
    /// opens beneath whichever row is selected, rather than living on every row at once.
    private var hitsColumn: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            FloodlitLabel3("Largest cap hits", palette: palette)
            if allContracted.isEmpty {
                CoachWorldSystemState(
                    .empty("No contracted players are recorded here."),
                    palette: palette
                )
            } else {
                ForEach(allContracted) { player in
                    playerRow(player)
                    if openPlayerID == player.id, let action = player.action {
                        actionRow(player, action)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Ten, matching the reference's own hint-placeholder-count for this list: the label reads
    /// "Largest cap hits", and an unbounded list under that label would contradict itself.
    private static let hitsShown = 10

    private var allContracted: [ProManagementReadModel.PlayerRow] {
        Array(
            (model.activeRoster + model.practiceSquad)
                .filter { $0.contract != nil }
                .sorted { $0.capHit > $1.capHit }
                .prefix(Self.hitsShown)
        )
    }

    private func playerRow(_ player: ProManagementReadModel.PlayerRow) -> some View {
        FloodlitRow(
            isSelected: openPlayerID == player.id,
            palette: palette,
            action: { openPlayerID = openPlayerID == player.id ? nil : player.id }
        ) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(player.name.uppercased())
                        .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.row, weight: .bold))
                        .lineLimit(1)
                    // `player.position` is a full word ("Defensive tackle"), not a short code --
                    // unlike the two-to-four-letter codes this pill treatment fits elsewhere.
                    FloodlitLabel3(player.rosterKind.isEmpty ? player.position
                                                             : "\(player.position) \u{00B7} \(player.rosterKind)",
                                   palette: palette)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let contract = player.contract {
                    Text(contract.years == 1 ? "1 yr" : "\(contract.years) yrs")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .frame(width: ProManagementMetric.termColumn, alignment: .trailing)
                }
                Text(currency(player.capHit))
                    .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.row, weight: .semibold))
                    .frame(width: ProManagementMetric.hitColumn, alignment: .trailing)
            }
        }
        .accessibilityLabel(
            "\(player.position) \(player.name), \(player.rosterKind), "
                + "\(currency(player.capHit)) cap hit"
        )
    }

    private func actionRow(
        _ player: ProManagementReadModel.PlayerRow,
        _ action: ProManagementReadModel.ActionRow
    ) -> some View {
        FloodlitRow(
            palette: palette,
            action: action.isAvailable ? { pendingRelease = player } : nil
        ) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                Text(action.title.uppercased())
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    // Not the reserved gold: `player.action` is always a release/cut, an
                    // immediately-executing mutation on tap, and `04` section 6.5 reserves the
                    // gold field for exactly one committing action per screen -- the footer's
                    // Negotiate. A warning tone says "consequential" without claiming that slot.
                    .foregroundStyle(
                        action.isAvailable ? palette.stateWarning.color : palette.contentQuiet.color
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
                ? "\(action.title) for \(player.name). \(action.detail)"
                : "\(action.title) for \(player.name), unavailable. "
                    + (action.unavailableReason ?? "")
        )
    }

    /// The reference's real committing action here is "Negotiate", not a plain close -- this
    /// screen already carries the data (`model.negotiations`) and the route to reach it
    /// (`.contractNegotiation` is a real registry entry, reachable through the same
    /// `route|<rawValue>` chrome-navigation intent every sibling/rail entry already uses).
    /// Routing through it rather than inventing new plumbing.
    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text(negotiationNote)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
            FloodlitCommittingAction("Negotiate") {
                onNavigateChrome?(
                    CoachWorldIntentID(rawValue: "route|\(CoachWorldScreenID.contractNegotiation.rawValue)")
                )
            }
        }
        .floodlitFooterStrip(palette: palette)
    }

    private var negotiationNote: String {
        model.negotiations.isEmpty
            ? "No contract negotiation is open right now."
            : (model.negotiations.count == 1
                ? "1 negotiation is open."
                : "\(model.negotiations.count) negotiations are open.")
    }

    private func currency(_ value: Int) -> String {
        value < 0 ? "-$\(abs(value))" : "$\(value)"
    }
}

private enum ProManagementMetric {
    /// The handoff's 250pt cap column and 290pt hits column.
    static let capColumn: CGFloat = 250
    static let hitsColumn: CGFloat = 290
    static let capFactHeight: CGFloat = 26
    static let seamAlpha = 0.05
    static let positionColumn: CGFloat = 44
    static let termColumn: CGFloat = 44
    static let hitColumn: CGFloat = 64
}
