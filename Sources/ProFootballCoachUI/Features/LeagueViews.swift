import SwiftUI
import FootballSimCore

/// Division tables for the user's conference, with the playoff line marked.
struct DivisionStandingsCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.large) {
            ForEach(Conference.allCases, id: \.self) { conference in
                VStack(alignment: .leading, spacing: Layout.small) {
                    Text(conference.displayName)
                        .font(.titleFont)
                        .foregroundStyle(Broadcast.ink)

                    ForEach(Division.allCases, id: \.self) { division in
                        if let league = app.league {
                            divisionTable(
                                division: division,
                                rows: StandingsCalculator.divisionStandings(
                                    conference: conference, division: division, in: league
                                ),
                                league: league
                            )
                        }
                    }
                }
            }
        }
    }

    /// A division table: column heads, a hairline under them, one row per team, leader marked.
    private func divisionTable(
        division: Division,
        rows: [TeamStanding],
        league: League
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(division.displayName)
                    .font(.labelFont)
                    .foregroundStyle(Broadcast.muted)
                Spacer()
                Text("W–L")
                    .font(.labelFont)
                    .foregroundStyle(Broadcast.muted)
                    .frame(width: 52, alignment: .trailing)
                Text("DIV")
                    .font(.labelFont)
                    .foregroundStyle(Broadcast.muted)
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.bottom, Layout.tight)

            Rule()

            ForEach(Array(rows.enumerated()), id: \.element.team.id) { index, row in
                let isUser = row.team.id == league.userTeamID
                HStack(spacing: Layout.small) {
                    TeamMark(team: row.team, size: 24)
                    Text(row.team.name)
                        .font(.bodyFont)
                        .foregroundStyle(Broadcast.ink)
                        .fontWeight(isUser ? .semibold : .regular)
                        .lineLimit(1)
                    if index == 0 { Stamp("1st", color: Broadcast.muted) }
                    Spacer(minLength: Layout.tight)
                    Text(row.record.description)
                        .font(.figureFont)
                        .foregroundStyle(Broadcast.ink)
                        .frame(width: 52, alignment: .trailing)
                    Text(row.record.divisionDescription)
                        .font(.figureFont)
                        .foregroundStyle(Broadcast.muted)
                        .frame(width: 44, alignment: .trailing)
                }
                .padding(.vertical, Layout.tight)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(index + 1). \(row.team.fullName)"
                        + "\(isUser ? ", your team" : ""), "
                        + "\(row.record.description) overall, "
                        + "\(row.record.divisionDescription) in the division"
                )

                // The division leader is the line that matters; draw it.
                if index < rows.count - 1 { Rule() }
            }
        }
        .card()
        .padding(.bottom, Layout.small)
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
            Text("Power Rankings")
                .font(.titleFont)
                .foregroundStyle(Broadcast.ink)

            ForEach(ranked, id: \.team.id) { row in
                let isUser = row.team.id == app.league?.userTeamID
                HStack(spacing: Layout.small) {
                    Text("\(row.index)")
                        .font(.figureFont)
                        .foregroundStyle(Broadcast.muted)
                        .frame(width: 30, alignment: .trailing)
                    TeamMark(team: row.team, size: 28)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(row.team.fullName)
                            .font(.bodyFont)
                            .foregroundStyle(Broadcast.ink)
                            .fontWeight(isUser ? .bold : .regular)
                            .lineLimit(1)
                        Text(app.league.map { $0.record(for: row.team.id).description } ?? "")
                            .font(.labelFont)
                            .foregroundStyle(Broadcast.muted)
                    }
                    Spacer(minLength: Layout.tight)
                    Text(Format.rating(row.team.overallRating))
                        .font(.figureFont)
                        .ratingStyle(row.team.overallRating)
                }
                .padding(.vertical, Layout.tight)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Number \(row.index), \(row.team.fullName)\(isUser ? ", your team" : ""), "
                        + "\(app.league.map { $0.record(for: row.team.id).description } ?? ""), "
                        + "overall \(Format.rating(row.team.overallRating))"
                )
                if row.index < ranked.count { Rule() }
            }
        }
    }
}

struct NewsFeedCard: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            Text("Around the League")
                .font(.titleFont)
                .foregroundStyle(Broadcast.ink)

            let items = Array((app.league?.news ?? []).suffix(40).reversed())
            if items.isEmpty {
                EmptyStateView(
                    icon: "newspaper",
                    title: "No news yet",
                    message: "Headlines appear once the season is under way."
                )
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: Layout.small) {
                        Image(systemName: item.category.iconName)
                            .font(.caption)
                            .foregroundStyle(Broadcast.muted)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.headline)
                                .font(.bodyFont)
                                .foregroundStyle(Broadcast.ink)
                            if !item.body.isEmpty {
                                Text(item.body)
                                    .font(.labelFont)
                                    .foregroundStyle(Broadcast.muted)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Layout.tight)
                    .accessibilityElement(children: .combine)
                    if index < items.count - 1 { Rule() }
                }
            }
        }
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
                        if let result = league.result(for: game.id) {
                            NavigationLink { GameReportView(record: result) } label: {
                                row(game, league: league)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink { MatchupPreviewSheet(game: game) } label: {
                                row(game, league: league)
                            }
                            .buttonStyle(.plain)
                        }
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
        .background(Broadcast.page)
        .navigationTitle("Schedule")
    }

    private func row(_ game: ScheduledGame, league: League) -> some View {
        let isHome = game.homeTeamID == league.userTeamID
        let opponentID = isHome ? game.awayTeamID : game.homeTeamID
        let opponent = league.team(id: opponentID)
        let result = league.result(for: game.id)

        return HStack(alignment: .center, spacing: Layout.medium) {
            VStack(spacing: 2) {
                Text("Wk")
                    .font(.labelFont)
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(game.week)")
                    .font(.figureFont)
                    .foregroundStyle(.white)
            }
            // Minimum rather than fixed: at accessibility text sizes a 42pt box clipped the
            // week number on the one screen that is nothing but week numbers.
            .frame(minWidth: 42, minHeight: 42)
            .padding(.horizontal, Layout.tight)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.primary))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Layout.tight) {
                    Text(isHome ? "vs" : "@").foregroundStyle(.secondary)
                    Text(opponent?.fullName ?? "TBD").fontWeight(.medium)
                }
                .font(.bodyFont)
                HStack(spacing: Layout.tight) {
                    Stamp(game.kind.label, color: Broadcast.muted)
                    if let opponent {
                        Stamp("\(Int(opponent.overallRating)) ovr",
                              color: RatingPalette.color(for: opponent.overallRating))
                    }
                }
            }

            Spacer()

            if let result {
                let won = result.didWin(league.userTeamID)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(result.score(for: league.userTeamID))-\(result.opponentScore(for: league.userTeamID))")
                        .font(.figureFont)
                        .lineLimit(1)
                    Stamp(
                        won ? "Won" : (result.isTie ? "Tied" : "Lost"),
                        hex: won ? RatingTier.starter.lightHex : RatingTier.fringe.lightHex,
                        filled: true
                    )
                }
            } else {
                Stamp(isHome ? "Home" : "Away", color: Broadcast.muted)
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
