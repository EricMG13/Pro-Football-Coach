import SwiftUI
import FootballSimCore

public struct ProOffseasonView: View {
    public let model: ProOffseasonReadModel
    public let title: String
    public let statusMessage: String?
    public let onAction: (ProMarketAction) -> Void
    public let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
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
                if !model.actions.isEmpty {
                    section("MARKET ACTIONS") {
                        ForEach(model.actions) { row in
                            actionButton(row)
                        }
                    }
                }
                prospectsSection
                freeAgentsSection
                waiversSection
            }
            .padding(CoachWorldTokens.Space.md)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
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
            Text("\(model.seasonLabel) · \(phaseLabel)")
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
            if let currentPickTeamID = model.currentPickTeamID {
                summaryCell("NEXT PICK", "\(model.nextPick + 1)/\(max(model.totalPicks, 1))")
                    .accessibilityLabel("Next pick, \(currentPickTeamID.uuidString)")
            }
        }
        .accessibilitySortPriority(80)
    }

    private var prospectsSection: some View {
        section("DRAFT BOARD") {
            if model.prospects.isEmpty {
                emptyText("No draft class is currently open.")
            } else {
                ForEach(model.prospects) { prospect in
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(prospect.name)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                            Spacer(minLength: CoachWorldTokens.Space.xs)
                            Text(prospect.position)
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                .foregroundStyle(palette.contentSecondary.color)
                        }
                        Text(prospect.estimatedOverall.map {
                            "Estimated overall \($0) · confidence \(prospect.confidence ?? 0)%"
                        } ?? "Unscouted · no estimate shown")
                            .font(CoachWorldTokens.TypeRole.body)
                            .foregroundStyle(palette.contentSecondary.color)
                        if let action = prospect.action {
                            actionButton(action)
                        }
                    }
                    .padding(CoachWorldTokens.Space.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.raised.color.opacity(0.7))
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(
                        "\(prospect.name), \(prospect.position), "
                            + (prospect.estimatedOverall.map { "estimated overall \($0)" }
                               ?? "unscouted")
                    )
                }
            }
        }
    }

    private var freeAgentsSection: some View {
        section("FREE AGENTS") {
            if model.freeAgents.isEmpty {
                emptyText("No free agents are available in this phase.")
            } else {
                ForEach(model.freeAgents) { player in
                    row(title: player.name, detail: player.position, action: player.action)
                }
            }
        }
    }

    private var waiversSection: some View {
        section("WAIVERS") {
            if model.waivers.isEmpty {
                emptyText("No active waiver claims are recorded.")
            } else {
                ForEach(model.waivers) { waiver in
                    row(
                        title: waiver.name,
                        detail: "Claim deadline \(waiver.deadline)",
                        action: waiver.action
                    )
                }
            }
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title)
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentSecondary.color)
            content()
        }
    }

    private func row(
        title: String,
        detail: String,
        action: ProOffseasonReadModel.ActionRow?
    ) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                Spacer(minLength: CoachWorldTokens.Space.xs)
                Text(detail)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            if let action { actionButton(action) }
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(palette.raised.color.opacity(0.7))
    }

    private func actionButton(_ action: ProOffseasonReadModel.ActionRow) -> some View {
        Button {
            onAction(action.action)
        } label: {
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
        .accessibilityLabel(
            action.isAvailable ? action.title : "\(action.title), unavailable"
        )
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

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(CoachWorldTokens.TypeRole.body)
            .foregroundStyle(palette.contentSecondary.color)
            .fixedSize(horizontal: false, vertical: true)
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
