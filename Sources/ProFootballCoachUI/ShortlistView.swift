import SwiftUI

/// A bounded active-board view. The recruiting board remains the mutation authority.
public struct ShortlistView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: RecruitingBoardReadModel
    public let statusMessage: String?
    public let onOpenProspect: (String) -> Void
    public let onClose: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""

    public init(
        model: RecruitingBoardReadModel,
        statusMessage: String? = nil,
        onOpenProspect: @escaping (String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onOpenProspect = onOpenProspect
        self.onClose = onClose
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var filteredProspects: [RecruitingBoardReadModel.Prospect] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return model.prospects }
        return model.prospects.filter {
            $0.person.name.lowercased().contains(normalized)
                || $0.position.lowercased().contains(normalized)
                || $0.status.lowercased().contains(normalized)
        }
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if dynamicTypeSize.isAccessibilitySize {
                    monitoredList
                    needsPanel
                } else {
                    HStack(alignment: .top, spacing: CoachWorldTokens.Gap.lg) {
                        monitoredList
                            .frame(width: ShortlistMetric.listColumn)
                        needsPanel
                            .frame(width: ShortlistMetric.panelColumn)
                    }
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var header: some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            TextField("Name, position or status", text: $query)
                .textFieldStyle(.plain)
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.actionSmall))
                .accessibilityLabel("Filter the board by name, position or status")
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(countLabel, palette: palette)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(
            CoachWorldCutCorner.row.fill(palette.work.color.opacity(ShortlistMetric.fieldFill))
        )
        .overlay {
            CoachWorldCutCorner.row.stroke(
                Color.white.opacity(CoachWorldTokens.Glass.line),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
    }

    private var countLabel: String {
        let shown = filteredProspects.count
        let total = model.prospects.count
        return shown == total ? "\(total) monitored" : "\(shown) of \(total)"
    }

    /// The board, narrowed. Rank leads because the board's order is the coach's own judgement.
    private var monitoredList: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
            if filteredProspects.isEmpty {
                CoachWorldSystemState(
                    .empty("No prospect on the board matches that filter."),
                    palette: palette
                )
            } else {
                ForEach(filteredProspects, id: \.stableID) { prospect in
                    prospectRow(prospect)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prospectRow(_ prospect: RecruitingBoardReadModel.Prospect) -> some View {
        FloodlitRow(palette: palette, action: { onOpenProspect(prospect.stableID) }) {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text("\(prospect.boardRank)")
                    .font(
                        CoachWorldTokens.figure(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .semibold
                        )
                    )
                    .foregroundStyle(palette.contentQuiet.color)
                    .frame(width: ShortlistMetric.rankColumn, alignment: .leading)
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.hair) {
                    Text(prospect.person.name.uppercased())
                        .font(
                            CoachWorldTokens.display(
                                CoachWorldTokens.DisplaySize.row, weight: .bold
                            )
                        )
                        .lineLimit(1)
                    FloodlitLabel3(
                        "\(prospect.position) \u{00B7} \(prospect.status)", palette: palette
                    )
                }
                Spacer(minLength: CoachWorldTokens.Gap.xs)
                Text(prospect.interest.uppercased())
                    .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.flag, weight: .bold))
                    .foregroundStyle(palette.stateInfo.color)
                    .lineLimit(1)
                    .frame(width: ShortlistMetric.interestColumn, alignment: .trailing)
            }
        }
        .accessibilityLabel(
            "Board rank \(prospect.boardRank), \(prospect.person.name), \(prospect.position), "
                + "\(prospect.status), \(prospect.interest) interest. "
                + "Last contact: \(nextContact(prospect))."
        )
    }

    /// The reference's "what the class still needs": one row per position, committed against target.
    ///
    /// A share bar is honest here because `PositionNeed` states its own target -- the whole is the
    /// number of bodies the class is meant to hold, not an open-ended count.
    private var needsPanel: some View {
        FloodlitCard(palette: palette, depth: .deep) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.smPlus) {
                FloodlitLabel3("What the class still needs", palette: palette)
                if model.positionNeeds.isEmpty {
                    Text("No position need is recorded for this class.")
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentQuiet.color)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(model.positionNeeds, id: \.stableID) { need in
                        needRow(need)
                    }
                }
                FloodlitLabel3(
                    "\(model.capacity.scholarshipSlotsRemaining) scholarships left",
                    palette: palette,
                    tint: palette.actionPrimary.color
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func needRow(_ need: RecruitingBoardReadModel.PositionNeed) -> some View {
        let short = max(0, need.target - need.committed)
        return HStack(spacing: CoachWorldTokens.Gap.smPlus) {
            Text(need.position.uppercased())
                .font(CoachWorldTokens.display(CoachWorldTokens.DisplaySize.pill, weight: .bold))
                .lineLimit(1)
                .frame(width: ShortlistMetric.needLabel, alignment: .leading)
            FloodlitShareBar(
                proportion: need.target > 0 ? Double(need.committed) / Double(need.target) : 0,
                tint: short == 0 ? palette.statePositive.color : palette.actionPrimary.color,
                palette: palette
            )
            Text("\(need.committed)/\(need.target)")
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.pill, weight: .semibold))
                .frame(width: ShortlistMetric.needFigure, alignment: .trailing)
        }
        .frame(minHeight: ShortlistMetric.needRowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            short == 0
                ? "\(need.position), full at \(need.target)"
                : "\(need.position), \(need.committed) of \(need.target), \(short) short"
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("The board in your own order. Nothing here ranks the class for you.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            Button("Close", action: onClose)
                .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
        }
        .floodlitFooterStrip(palette: palette)
    }

    private func nextContact(_ prospect: RecruitingBoardReadModel.Prospect) -> String {
        prospect.relationshipHistory.first?.dateLabel ?? "No contact recorded"
    }
}

private enum ShortlistMetric {
    /// The handoff's 430pt board column and 263pt needs panel.
    static let listColumn: CGFloat = 430
    static let panelColumn: CGFloat = 263
    static let rankColumn: CGFloat = 22
    static let interestColumn: CGFloat = 64
    static let needLabel: CGFloat = 46
    static let needFigure: CGFloat = 46
    static let needRowHeight: CGFloat = 22
    static let fieldFill = 0.5
}
