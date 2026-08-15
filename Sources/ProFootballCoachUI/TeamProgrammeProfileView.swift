import SwiftUI

/// Shared profile for every map, standings and schedule organisation.
public struct TeamProgrammeProfileView: View {
    public let model: TeamProgrammeProfileReadModel
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        model: TeamProgrammeProfileReadModel,
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
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
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
                    identity
                    facts
                    fixtures
                    rivals
                    traditions
                }
                .padding(CoachWorldTokens.Space.md)
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .frame(maxWidth: .infinity,
               alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .center)
        .accessibilitySortPriority(100)
    }

    private var topBar: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Button("League", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            VStack(alignment: .leading, spacing: .zero) {
                Text("Team profile")
                    .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Text(model.seasonLabel)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Spacer()
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(model.team.name)
                .font(CoachWorldTokens.TypeRole.display.weight(.black))
            Text(model.cityName + " · " + model.regionName)
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
            Text(model.tier + " · " + model.conference)
                .font(CoachWorldTokens.TypeRole.callout.weight(.bold))
            if let division = model.division {
                Text(division)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.team.name + ", " + model.cityName + ", " + model.tier)
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Programme facts")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            fact("Venue", model.venue.name)
            fact("Record", model.record)
            fact("Rank", model.rank ?? "Unranked")
            fact("Prestige", String(model.prestige))
            fact("Roster", String(model.rosterCount))
            fact("Staff", String(model.staffCount))
        }
    }

    private var fixtures: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Schedule")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.fixtures.isEmpty {
                Text("No fixtures recorded")
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                ForEach(model.fixtures, content: fixtureRow)
            }
        }
    }

    private func fixtureRow(_ fixture: TeamProgrammeProfileReadModel.Fixture) -> some View {
        let opponentLabel = (fixture.isHome ? "vs " : "at ") + fixture.opponent.name
        let scoreLabel = fixture.score ?? "—"
        return HStack(spacing: CoachWorldTokens.Space.sm) {
            VStack(alignment: .leading, spacing: .zero) {
                Text(fixture.week)
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                Text(fixture.stage)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            .frame(width: 130, alignment: .leading)
            Text(opponentLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(scoreLabel).monospacedDigit()
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            fixture.week + ", " + (fixture.isHome ? "versus " : "at ")
                + fixture.opponent.name + ", " + (fixture.score ?? "scheduled")
        )
    }

    private var rivals: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Rivalries")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.rivals.isEmpty {
                Text("No rivalry recorded")
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                ForEach(model.rivals) { rival in
                    Button {
                        guard let id = UUID(uuidString: rival.id) else { return }
                        onSelectTeam(id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: .zero) {
                                Text(rival.team.name).fontWeight(.bold)
                                Text(rival.origin)
                                    .font(CoachWorldTokens.TypeRole.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                            }
                            Spacer()
                            Text(String(rival.intensity)).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        rival.team.name + ", " + rival.origin + ", intensity "
                            + String(rival.intensity)
                    )
                }
            }
        }
    }

    private var traditions: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Traditions")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.traditions.isEmpty {
                Text("No traditions recorded")
                    .foregroundStyle(palette.contentSecondary.color)
            } else {
                ForEach(model.traditions, id: \.self) { tradition in
                    Text(tradition)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget,
                               alignment: .leading)
                }
            }
        }
    }

    private func fact(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentQuiet.color)
            Spacer()
            Text(value)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + ", " + value)
    }
}
