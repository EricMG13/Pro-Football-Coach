import SwiftUI
import FootballSimCore

/// Division tables for the user's conference, with the playoff line marked.
struct DivisionStandingsCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.medium) {
            ForEach(Conference.allCases, id: \.self) { conference in
                Text(conference.displayName).font(.headline)
                ForEach(Division.allCases, id: \.self) { division in
                    if let league = app.league {
                        let rows = StandingsCalculator.divisionStandings(
                            conference: conference, division: division, in: league
                        )
                        VStack(spacing: 0) {
                            HStack {
                                Text(division.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("W-L").font(.caption2).foregroundStyle(.tertiary)
                                    .frame(width: 46, alignment: .trailing)
                                Text("DIV").font(.caption2).foregroundStyle(.tertiary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                            .padding(.bottom, 4)

                            ForEach(rows, id: \.team.id) { row in
                                HStack {
                                    TeamBadge(team: row.team, size: 24)
                                    Text(row.team.name)
                                        .font(.subheadline)
                                        .fontWeight(row.team.id == league.userTeamID ? .bold : .regular)
                                    Spacer()
                                    Text(row.record.description)
                                        .font(.caption.monospacedDigit())
                                        .frame(width: 46, alignment: .trailing)
                                    Text(row.record.divisionDescription)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                        .padding(.bottom, Layout.small)
                    }
                }
            }
        }
        .card()
    }
}

/// 1–32 by a blend of results and roster strength.
struct PowerRankingsCard: View {
    @Environment(AppState.self) private var app

    private var ranked: [(index: Int, team: Team, score: Double)] {
        guard let league = app.league else { return [] }
        return league.teams
            .map { team -> (Team, Double) in
                let record = league.record(for: team.id)
                let form = record.gamesPlayed > 0 ? record.winPercentage : 0.5
                let differential = Double(record.pointDifferential) / max(1, Double(record.gamesPlayed)) / 10
                return (team, team.overallRating * 0.6 + form * 30 + differential * 4)
            }
            .sorted { $0.1 > $1.1 }
            .enumerated()
            .map { (index: $0.offset + 1, team: $0.element.0, score: $0.element.1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Power Rankings")
            ForEach(ranked, id: \.team.id) { row in
                HStack(spacing: Layout.small) {
                    Text("\(row.index)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .trailing)
                    TeamBadge(team: row.team, size: 26)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(row.team.fullName)
                            .font(.subheadline)
                            .fontWeight(row.team.id == app.league?.userTeamID ? .bold : .regular)
                        Text(app.league.map { $0.record(for: row.team.id).description } ?? "")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(Format.rating(row.team.overallRating))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RatingPalette.color(for: row.team.overallRating))
                }
                .padding(.vertical, 2)
            }
        }
        .card()
    }
}

struct NewsFeedCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Around the League")
            let items = Array((app.league?.news ?? []).suffix(40).reversed())
            if items.isEmpty {
                EmptyStateView(
                    icon: "newspaper",
                    title: "No news yet",
                    message: "Headlines appear once the season is under way."
                )
            } else {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: Layout.small) {
                        Image(systemName: item.category.iconName)
                            .foregroundStyle(.secondary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.headline).font(.subheadline)
                            if !item.body.isEmpty {
                                Text(item.body).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .card()
    }
}

/// The user team's full season, results and upcoming.
struct ScheduleView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.small) {
                if let league = app.league {
                    let games = league.schedule
                        .filter { $0.involves(league.userTeamID) }
                        .sorted { $0.week < $1.week }

                    ForEach(games) { game in
                        row(game, league: league)
                    }
                    if games.isEmpty {
                        EmptyStateView(
                            icon: "calendar",
                            title: "No schedule yet",
                            message: "The fixture list is drawn up when the season starts."
                        )
                    }
                }
            }
            .padding(Layout.medium)
        }
        .background(Color.pageBackground)
        .navigationTitle("Schedule")
    }

    private func row(_ game: ScheduledGame, league: League) -> some View {
        let isHome = game.homeTeamID == league.userTeamID
        let opponentID = isHome ? game.awayTeamID : game.homeTeamID
        let opponent = league.team(id: opponentID)
        let result = league.result(for: game.id)

        return HStack(spacing: Layout.medium) {
            VStack(spacing: 2) {
                Text("WK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(game.week)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.primary))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Layout.tight) {
                    Text(isHome ? "vs" : "@").foregroundStyle(.secondary)
                    Text(opponent?.fullName ?? "TBD").fontWeight(.medium)
                }
                .font(.subheadline)
                HStack(spacing: Layout.tight) {
                    Chip(game.kind.label, color: game.kind == .division ? .blue : .teal)
                    if let opponent {
                        Chip("OVR \(Int(opponent.overallRating))",
                             color: RatingPalette.color(for: opponent.overallRating))
                    }
                }
            }

            Spacer()

            if let result {
                let won = result.didWin(league.userTeamID)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.score(for: league.userTeamID))-\(result.opponentScore(for: league.userTeamID))")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                    Chip(won ? "W" : (result.isTie ? "T" : "L"), color: won ? .green : .red, filled: true)
                }
            } else {
                Chip(isHome ? "HOME" : "AWAY", color: .secondary)
            }
        }
        .padding(Layout.small)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .fill(resultTint(result, league: league))
        )
    }

    private func resultTint(_ result: GameRecord?, league: League) -> Color {
        guard let result else { return Color.cardFill }
        if result.isTie { return Color.cardFill }
        return result.didWin(league.userTeamID)
            ? Color.green.opacity(0.12)
            : Color.red.opacity(0.10)
    }
}
