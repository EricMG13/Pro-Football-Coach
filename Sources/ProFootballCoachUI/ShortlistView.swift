import SwiftUI

/// A bounded active-board view. The recruiting board remains the mutation authority.
public struct ShortlistView: View {
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
        CoachWorldFloodlitStage(palette: palette) {
            scrollContent
        }
        .accessibilitySortPriority(100)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                header
                if let statusMessage {
                    Text(statusMessage)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                TextField("Search active board", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                    .accessibilityLabel("Search active recruiting board")
                Text("MONITORED · \(filteredProspects.count) of \(model.prospects.count)")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    .foregroundStyle(palette.collegeIdentity.color)
                if filteredProspects.isEmpty {
                    CoachWorldSystemState(
                        .empty(
                            "No monitored prospects. Add evaluated prospects to the board "
                                + "before monitoring contact windows."
                        ),
                        palette: palette
                    )
                } else {
                    ForEach(filteredProspects, id: \.stableID) { prospect in
                        Button { onOpenProspect(prospect.stableID) } label: {
                            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                                HStack {
                                    Text(prospect.person.name)
                                        .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                    Spacer()
                                    Text(prospect.position)
                                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                }
                                Text("#\(prospect.boardRank) · \(prospect.status) · \(prospect.interest) interest")
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                                Text("Next contact: \(nextContact(prospect))")
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                            }
                            .padding(CoachWorldTokens.Space.sm)
                            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                            .coachWorldFloodlitPanel(
                                fill: palette.raised.color,
                                border: palette.contentQuiet.color
                                    .opacity(CoachWorldTokens.Depth.panelBorderOpacity)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "\(prospect.person.name), board rank \(prospect.boardRank), "
                                + "\(prospect.position), \(prospect.status), open profile"
                        )
                    }
                }
            }
            .padding(CoachWorldTokens.Space.md)
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    titleBlock
                    closeButton
                }
            } else {
                HStack(alignment: .top) {
                    titleBlock
                    Spacer()
                    closeButton
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
            Text("SHORTLIST")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text("Active board prospects with bounded status and next-contact context")
                .foregroundStyle(palette.contentSecondary.color)
        }
    }

    private var closeButton: some View {
        Button("Done", action: onClose)
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func nextContact(_ prospect: RecruitingBoardReadModel.Prospect) -> String {
        prospect.relationshipHistory.first?.dateLabel ?? "No contact recorded"
    }
}
