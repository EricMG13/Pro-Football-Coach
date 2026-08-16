import SwiftUI

/// Shared rankings/playoff picture surface. Ranking and bracket data are read from the same
/// competition snapshot so the two views cannot disagree about the field.
public struct CompetitionOverviewView: View {
    public let model: CompetitionOverviewReadModel
    public let focus: CoachWorldScreenID
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onContinue: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: CompetitionOverviewReadModel,
        focus: CoachWorldScreenID,
        statusMessage: String? = nil,
        onClose: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
        self.focus = focus
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onContinue = onContinue
        self.onSelectTeam = onSelectTeam
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            surface.accessibilitySortPriority(100)
        } else {
            surface.accessibilitySortPriority(100)
        }
    }

    private var surface: some View {
        VStack(spacing: .zero) {
            topBar
            if let statusMessage {
                Text(statusMessage)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.stateWarning.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CoachWorldTokens.Space.md)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                    if focus == .rankingsPlayoffPicture || model.bracket.isEmpty {
                        rankings
                    }
                    if focus == .bracketPostseason || !model.bracket.isEmpty {
                        bracket
                    }
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Button("League", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            VStack(alignment: .leading, spacing: .zero) {
                Text(focus == .bracketPostseason ? "Postseason" : "Rankings")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Text(model.tier + " · " + model.seasonLabel)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Spacer()
            Button(action: onContinue) {
                Label("Continue", systemImage: "forward.end.fill")
            }
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
    }

    private var rankings: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Current ranking")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            ForEach(model.rankings, content: rankingRow)
        }
    }

    private var bracket: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Postseason path")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.bracket.isEmpty {
                Text("No postseason games are scheduled yet.")
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                ForEach(model.bracket, content: bracketRow)
            }
        }
    }

    private func rankingRow(_ row: CompetitionOverviewReadModel.RankingRow) -> some View {
        Button {
            guard let id = UUID(uuidString: row.id) else { return }
            onSelectTeam(id)
        } label: {
            HStack(spacing: CoachWorldTokens.Space.sm) {
                Text(String(row.rank))
                    .frame(width: 34, alignment: .leading)
                    .monospacedDigit()
                Text(row.team.name)
                    .fontWeight(row.isControlled ? .bold : .regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(row.record).monospacedDigit()
            }
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .background(row.isControlled ? palette.collegeIdentity.color.opacity(0.14) : .clear)
        .accessibilityLabel(String(row.rank) + ", " + row.team.name + ", " + row.record)
    }

    private func bracketRow(_ game: CompetitionOverviewReadModel.BracketGame) -> some View {
        Button {
            guard let id = UUID(uuidString: game.home.stableID) else { return }
            onSelectTeam(id)
        } label: {
            HStack(spacing: CoachWorldTokens.Space.sm) {
                VStack(alignment: .leading, spacing: .zero) {
                    Text(game.stage)
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    Text(game.week)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .frame(width: 125, alignment: .leading)
                Text(game.away.name + " at " + game.home.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(game.score ?? "—").monospacedDigit()
            }
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            game.stage + ", " + game.away.name + " at " + game.home.name
                + ", " + (game.score ?? "scheduled")
        )
    }
}
