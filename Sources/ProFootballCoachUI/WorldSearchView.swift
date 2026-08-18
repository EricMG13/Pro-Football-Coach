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
            VStack(spacing: .zero) {
                topBar
                if let statusMessage {
                    Text(statusMessage)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.stateWarning.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, CoachWorldTokens.Space.md)
                }
                TextField("Search teams, cities or regions", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, CoachWorldTokens.Space.md)
                    .padding(.vertical, CoachWorldTokens.Space.sm)
                    .accessibilityLabel("Search current teams, cities or regions")
                if visibleResults.isEmpty {
                    CoachWorldSystemState(
                        .empty("No organisation matches that search. Try a team, city, region or tier."),
                        palette: palette
                    )
                } else {
                    List {
                        ForEach(visibleResults, content: resultRow)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity,
                   alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        }
        .accessibilitySortPriority(100)
    }

    private func resultRow(_ result: WorldSearchReadModel.Result) -> some View {
        let context = result.tier + " · " + result.cityName + " · " + result.regionName
        return Button {
            guard let id = UUID(uuidString: result.id) else { return }
            onSelectTeam(id)
        } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(result.team.name)
                    .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                Text(context)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                   alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            result.team.name + ", " + result.tier + ", " + result.cityName
                + ", " + result.regionName
        )
    }

    private var topBar: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Button("Office", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            VStack(alignment: .leading, spacing: .zero) {
                Text("World search")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Text(model.seasonLabel)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Spacer()
            Text(String(model.results.count) + " organisations")
                .font(CoachWorldTokens.TypeRole.caption)
                .foregroundStyle(palette.contentSecondary.color)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .coachWorldFloodlitPanel(
            fill: palette.raised.color,
            border: palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity),
            depth: .deep
        )
    }
}
