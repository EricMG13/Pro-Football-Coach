import SwiftUI
import FootballSimCore

public struct ProManagementView: View {
    public let model: ProManagementReadModel
    public let title: String
    public let statusMessage: String?
    public let onAction: (ProManagementAction) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        CoachWorldFloodlitStage(palette: palette) {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    header
                    if let statusMessage {
                        Text(statusMessage)
                            .font(CoachWorldTokens.TypeRole.callout)
                            .foregroundStyle(palette.stateWarning.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    summary
                    rosterSection("ACTIVE ROSTER", model.activeRoster)
                    rosterSection("PRACTICE SQUAD", model.practiceSquad)
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .accessibilitySortPriority(100)
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    titleBlock
                    doneButton
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer(minLength: CoachWorldTokens.Space.sm)
                    doneButton
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.proIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.seasonLabel)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var doneButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private var summary: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: CoachWorldTokens.Space.xs)],
            alignment: .leading,
            spacing: CoachWorldTokens.Space.xs
        ) {
            summaryCell("CAP ROOM", currency(model.cap.remainingCap))
            summaryCell("CAP LIMIT", currency(model.cap.capLimit))
            summaryCell("COMMITTED", currency(model.cap.committedCap))
            summaryCell("DEAD MONEY", currency(model.cap.deadMoney))
            summaryCell("ACTIVE", "\(model.cap.activeRosterCount)/\(ProRules.activeRosterLimit)")
            summaryCell("PRACTICE", "\(model.cap.practiceSquadCount)/\(ProRules.practiceSquadLimit)")
        }
        .accessibilitySortPriority(80)
    }

    private func rosterSection(
        _ heading: String,
        _ rows: [ProManagementReadModel.PlayerRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(heading)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            if rows.isEmpty {
                CoachWorldSystemState(
                    .empty("No contracted players are recorded here."),
                    palette: palette
                )
            } else {
                ForEach(rows) { player in
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(player.name)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                            Spacer(minLength: CoachWorldTokens.Space.xs)
                            Text(currency(player.capHit))
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentSecondary.color)
                        }
                        Text("\(player.position) · \(player.rosterKind)")
                            .font(CoachWorldTokens.TypeRole.body)
                            .foregroundStyle(palette.contentSecondary.color)
                        if let action = player.action {
                            actionButton(action)
                        }
                    }
                    .padding(CoachWorldTokens.Space.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .coachWorldFloodlitPanel(
                        fill: palette.raised.color,
                        border: palette.contentQuiet.color
                            .opacity(CoachWorldTokens.Depth.panelBorderOpacity)
                    )
                    .accessibilityElement(children: .contain)
                }
            }
        }
    }

    private func actionButton(_ action: ProManagementReadModel.ActionRow) -> some View {
        Button { onAction(action.action) } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(action.title)
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Text(action.isAvailable ? action.detail : (action.unavailableReason ?? action.detail))
                    .font(CoachWorldTokens.TypeRole.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                   alignment: .leading)
        }
        .buttonStyle(CoachWorldActionButtonStyle(
            role: action.isAvailable ? .live : .secondary,
            palette: palette
        ))
        .disabled(!action.isAvailable)
        .accessibilityLabel(action.isAvailable ? action.title : "\(action.title), unavailable")
        .accessibilityHint(action.isAvailable ? action.detail : (action.unavailableReason ?? ""))
    }

    private func summaryCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text(label)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            Text(value)
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label.capitalized), \(value)")
    }

    private func currency(_ value: Int) -> String {
        value < 0 ? "-$\(abs(value))" : "$\(value)"
    }
}
