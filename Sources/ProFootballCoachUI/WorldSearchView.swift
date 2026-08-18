import SwiftUI

/// Search entry for current college programmes and professional teams.
public struct WorldSearchView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: WorldSearchReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""
    @State private var scope: SearchScope = .everything

    public init(
        model: WorldSearchReadModel,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onSelectTeam = onSelectTeam
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    private var visibleResults: [WorldSearchReadModel.Result] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return model.results }
        return model.results.filter {
            [$0.team.name, $0.cityName, $0.regionName, $0.tier]
                .joined(separator: " ")
                .lowercased()
                .contains(needle)
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
                searchField
                scopeBar
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if scopedResults.isEmpty {
                    CoachWorldSystemState(
                        .empty(
                            "No organisation matches that search. "
                                + "Try a team, city, region or tier."
                        ),
                        palette: palette
                    )
                } else {
                    resultGroups
                }
            }
            .padding(.vertical, CoachWorldTokens.Pad.panel.v)
            // The column is the handoff's width, held at the leading edge. A bare `maxWidth`
            // inside a ScrollView centres what it constrains, which floated this column into the
            // middle of the stage instead of starting it at the content inset.
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : SearchMetric.column,
                   alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    /// One field, dense results -- the handoff's own description of this surface.
    private var searchField: some View {
        HStack(spacing: CoachWorldTokens.Gap.md) {
            TextField("Team, city or region", text: $query)
                .textFieldStyle(.plain)
                .font(CoachWorldTokens.figure(CoachWorldTokens.DisplaySize.actionSmall))
                .accessibilityLabel("Search current teams, cities or regions")
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitLabel3(countLabel, palette: palette)
        }
        .padding(.horizontal, CoachWorldTokens.Pad.row.h)
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .background(CoachWorldCutCorner.row.fill(palette.work.color.opacity(SearchMetric.fieldFill)))
        .overlay {
            CoachWorldCutCorner.row.stroke(
                Color.white.opacity(CoachWorldTokens.Glass.line),
                lineWidth: CoachWorldTokens.Shape.hairline
            )
        }
    }

    private var countLabel: String {
        let shown = scopedResults.count
        let total = model.results.count
        if shown == total { return total == 1 ? "1 organisation" : "\(total) organisations" }
        return "\(shown) of \(total)"
    }

    /// The reference's scope chips. The scopes are the tiers the world actually holds, read off the
    /// results rather than hard-coded, so a world with one tier does not offer a chip that matches
    /// nothing.
    private var scopeBar: some View {
        HStack(spacing: CoachWorldTokens.Gap.xxs) {
            FloodlitPill(
                SearchScope.everything.label,
                isSelected: scope == .everything,
                palette: palette,
                action: { scope = .everything }
            )
            ForEach(tiers, id: \.self) { tier in
                FloodlitPill(
                    tier,
                    isSelected: scope == .tier(tier),
                    palette: palette,
                    action: { scope = .tier(tier) }
                )
            }
        }
    }

    private var tiers: [String] {
        var seen = Set<String>()
        return model.results.compactMap { seen.insert($0.tier).inserted ? $0.tier : nil }
    }

    private var scopedResults: [WorldSearchReadModel.Result] {
        visibleResults.filter { scope.holds($0.tier) }
    }

    /// Results grouped by tier, which is the only grouping the model records.
    private var resultGroups: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.sm) {
            ForEach(groupedTiers, id: \.self) { tier in
                VStack(alignment: .leading, spacing: CoachWorldTokens.Gap.tight) {
                    FloodlitLabel3(tier, palette: palette, tint: palette.stateInfo.color)
                    ForEach(scopedResults.filter { $0.tier == tier }) { result in
                        resultRow(result)
                    }
                }
            }
        }
    }

    private var groupedTiers: [String] {
        var seen = Set<String>()
        return scopedResults.compactMap { seen.insert($0.tier).inserted ? $0.tier : nil }
    }

    private func resultRow(_ result: WorldSearchReadModel.Result) -> some View {
        Button {
            guard let id = UUID(uuidString: result.id) else { return }
            onSelectTeam(id)
        } label: {
            HStack(spacing: CoachWorldTokens.Gap.md) {
                Text(result.team.name.uppercased())
                    .font(
                        CoachWorldTokens.display(
                            CoachWorldTokens.DisplaySize.actionSmall, weight: .bold
                        )
                    )
                    .lineLimit(1)
                    .frame(width: SearchMetric.nameColumn, alignment: .leading)
                Text("\(result.cityName), \(result.regionName)")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, CoachWorldTokens.Pad.row.h)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .background(
                CoachWorldCutCorner.row.fill(palette.work.color.opacity(SearchMetric.rowFill))
            )
            .contentShape(CoachWorldCutCorner.row)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(result.team.name), \(result.tier), \(result.cityName), \(result.regionName)"
        )
    }

    private var footer: some View {
        HStack(spacing: CoachWorldTokens.Gap.mdPlus) {
            Text("Every organisation currently in the world.")
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: CoachWorldTokens.Gap.xs)
            FloodlitCommittingAction("Done", action: onClose)
        }
        .floodlitFooterStrip(palette: palette)
    }
}

/// What the scope chips filter to. Tiers come from the results themselves, so this carries the
/// chosen tier rather than enumerating a set the world may not have.
private enum SearchScope: Equatable {
    case everything
    case tier(String)

    var label: String {
        switch self {
        case .everything: "Everything"
        case let .tier(name): name
        }
    }

    func holds(_ tier: String) -> Bool {
        switch self {
        case .everything: true
        case let .tier(name): name == tier
        }
    }
}

private enum SearchMetric {
    /// The handoff's 430pt results column.
    static let column: CGFloat = 430
    static let nameColumn: CGFloat = 212
    static let fieldFill = 0.5
    static let rowFill = 0.32
}
