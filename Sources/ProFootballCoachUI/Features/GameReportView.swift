import SwiftUI
import FootballSimCore

/// Post-game report: quarter scores, team comparison and per-position box score.
struct GameReportView: View {
    @Environment(AppState.self) private var app
    let record: GameRecord
    @State private var showingHome = true

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                finalScore
                teamStats
                boxScore
            }
            .padding(Layout.medium)
        }
        .background(Color.pageBackground)
        .navigationTitle("Game Report")
    }

    private var home: Team? { app.league?.team(id: record.homeTeamID) }
    private var away: Team? { app.league?.team(id: record.awayTeamID) }

    private var finalScore: some View {
        VStack(spacing: Layout.small) {
            HStack {
                Text("FINAL").font(.caption.weight(.heavy)).foregroundStyle(.secondary)
                if record.wentToOvertime {
                    Chip("OT\(record.overtimePeriods > 1 ? "\(record.overtimePeriods)" : "")", color: .orange)
                }
                Spacer()
            }
            quarterRow(team: away, stats: record.awayStats, isWinner: record.winnerID == record.awayTeamID)
            Divider()
            quarterRow(team: home, stats: record.homeStats, isWinner: record.winnerID == record.homeTeamID)
        }
        .card()
    }

    private func quarterRow(team: Team?, stats: TeamGameStats, isWinner: Bool) -> some View {
        HStack(spacing: Layout.small) {
            if let team { TeamBadge(team: team, size: 28) }
            Text(team?.abbreviation ?? "—")
                .font(.subheadline.weight(isWinner ? .bold : .regular))
            Spacer()
            ForEach(Array(stats.quarterPoints.enumerated()), id: \.offset) { _, points in
                Text("\(points)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
            }
            Text("\(stats.points)")
                .font(.title3.monospacedDigit().weight(.bold))
                .frame(width: 40, alignment: .trailing)
            if isWinner {
                Image(systemName: "crown.fill").foregroundStyle(.yellow).font(.caption)
            }
        }
    }

    private var teamStats: some View {
        VStack(spacing: Layout.tight) {
            SectionHeader("Team Statistics")
            HStack {
                Text(away?.abbreviation ?? "Away")
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text(home?.abbreviation ?? "Home")
                    .frame(width: 50, alignment: .trailing)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            comparisonRow("Total yards", record.awayStats.totalYards, record.homeStats.totalYards)
            comparisonRow("Passing", record.awayStats.passingYards, record.homeStats.passingYards)
            comparisonRow("Rushing", record.awayStats.rushingYards, record.homeStats.rushingYards)
            comparisonRow("First downs", record.awayStats.firstDowns, record.homeStats.firstDowns)
            comparisonRow("Turnovers", record.awayStats.turnovers, record.homeStats.turnovers)
            comparisonRow("Sacks", record.awayStats.sacks, record.homeStats.sacks)
        }
        .card()
    }

    private func comparisonRow(_ label: String, _ awayValue: Int, _ homeValue: Int) -> some View {
        HStack {
            Text("\(awayValue)").font(.subheadline.monospacedDigit()).frame(width: 50, alignment: .leading)
            Spacer()
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text("\(homeValue)").font(.subheadline.monospacedDigit()).frame(width: 50, alignment: .trailing)
        }
    }

    private var boxScore: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            Picker("", selection: $showingHome) {
                Text(away?.abbreviation ?? "Away").tag(false)
                Text(home?.abbreviation ?? "Home").tag(true)
            }
            .pickerStyle(.segmented)

            let team = showingHome ? home : away
            if let team {
                ForEach(Position.displayOrder, id: \.self) { position in
                    let lines = team.roster
                        .filter { $0.position == position }
                        .compactMap { player -> (Player, StatLine)? in
                            guard let line = record.playerStats[player.id], !line.isEmpty,
                                  line != contributionOnlyAppearance(line) else { return nil }
                            return (player, line)
                        }
                    if !lines.isEmpty {
                        Text(position.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(lines, id: \.0.id) { player, line in
                            HStack {
                                Text(player.name).font(.caption)
                                Spacer()
                                Text(summary(line, position: position))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .card()
    }

    /// A line containing only an appearance is not worth a box-score row.
    private func contributionOnlyAppearance(_ line: StatLine) -> StatLine {
        var blank = StatLine()
        blank.gamesPlayed = line.gamesPlayed
        return blank
    }

    private func summary(_ line: StatLine, position: Position) -> String {
        switch position {
        case .qb:
            return "\(line.completions)/\(line.passAttempts), \(line.passingYards) yds, \(line.passingTouchdowns) TD, \(line.interceptionsThrown) INT"
        case .rb:
            return "\(line.carries) car, \(line.rushingYards) yds, \(line.rushingTouchdowns) TD"
        case .wr, .te:
            return "\(line.receptions) rec, \(line.receivingYards) yds, \(line.receivingTouchdowns) TD"
        case .dl, .lb, .cb, .s:
            return "\(line.tackles) tkl, \(line.sacks) sk, \(line.interceptions) INT"
        case .k:
            return "\(line.fieldGoalsMade)/\(line.fieldGoalsAttempted) FG, \(line.extraPointsMade)/\(line.extraPointsAttempted) XP"
        case .p:
            return "\(line.punts) punts, \(String(format: "%.1f", line.averagePunt)) avg"
        case .ol:
            return "\(line.gamesPlayed) gp"
        }
    }
}

/// Pre-game comparison of the two teams.
struct MatchupPreviewSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let game: ScheduledGame

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.medium) {
                    if let league = app.league,
                       let home = league.team(id: game.homeTeamID),
                       let away = league.team(id: game.awayTeamID) {
                        compare("Overall", away.overallRating, home.overallRating, away: away, home: home)
                        compare("Offense", away.offenseRating, home.offenseRating, away: away, home: home)
                        compare("Defense", away.defenseRating, home.defenseRating, away: away, home: home)
                        compare("Special Teams", away.specialTeamsRating, home.specialTeamsRating, away: away, home: home)
                    }
                }
                .padding(Layout.medium)
            }
            .background(Color.pageBackground)
            .navigationTitle("Matchup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func compare(
        _ label: String,
        _ awayValue: Double,
        _ homeValue: Double,
        away: Team,
        home: Team
    ) -> some View {
        VStack(spacing: Layout.tight) {
            HStack {
                Text(Format.rating(awayValue))
                    .font(.headline.monospacedDigit())
                    .ratingStyle(awayValue)
                Spacer()
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(Format.rating(homeValue))
                    .font(.headline.monospacedDigit())
                    .ratingStyle(homeValue)
            }
            GeometryReader { proxy in
                let total = max(1, awayValue + homeValue)
                HStack(spacing: 2) {
                    Capsule()
                        .fill(Color(hex: away.colors.primaryHex))
                        .frame(width: proxy.size.width * awayValue / total)
                    Capsule().fill(Color(hex: home.colors.primaryHex))
                }
            }
            .frame(height: 8)
            let edge = homeValue - awayValue
            Text(edge >= 0
                 ? "\(home.abbreviation) +\(String(format: "%.1f", edge))"
                 : "\(away.abbreviation) +\(String(format: "%.1f", -edge))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .card()
    }
}
