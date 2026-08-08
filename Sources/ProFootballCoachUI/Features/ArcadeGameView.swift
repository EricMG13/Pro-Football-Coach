import SwiftUI
import FootballSimCore

/// "On the Field" — the arcade presentation layer.
///
/// It draws the same game the engine already resolved: a side-on field, the ball moving with
/// each play, and the drive log building underneath. The engine stays the single source of
/// truth for the rules, so a game played here and a game simmed produce identical results —
/// the divergence between watched and simulated outcomes is exactly the complaint this design
/// set out to avoid.
///
/// Drawn with SwiftUI shapes rather than sprite assets: nothing to ship, scales to any device,
/// and the look is our own.
struct ArcadeGameView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme

    let record: GameRecord
    @Binding var revealedPlays: Int
    let onFinish: () -> Void

    private var currentPlay: PlayEvent? {
        guard revealedPlays > 0, revealedPlays <= record.plays.count else {
            return record.plays.first
        }
        return record.plays[revealedPlays - 1]
    }

    var body: some View {
        VStack(spacing: 0) {
            scoreboard
            field
            lastPlayCard
            Spacer(minLength: 0)
            controls
        }
        .background(Color.pageBackground)
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        let play = currentPlay
        return HStack(spacing: Layout.medium) {
            teamScore(app.league?.team(id: record.awayTeamID), play?.awayScore ?? 0)
            VStack(spacing: 2) {
                Text(play?.clockLabel ?? "Q1 15:00")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                if let play, play.down > 0 {
                    Text("\(play.down) & \(play.distance)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            teamScore(app.league?.team(id: record.homeTeamID), play?.homeScore ?? 0)
        }
        .padding(Layout.small)
        .frame(maxWidth: .infinity)
        .background(theme.gradient)
    }

    private func teamScore(_ team: Team?, _ score: Int) -> some View {
        HStack(spacing: Layout.small) {
            if let team { TeamBadge(team: team, size: 28) }
            Text("\(score)")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Field

    private var field: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let endZone = width * 0.10
            let playingWidth = width - endZone * 2
            let ballFraction = Double(currentPlay?.yardLine ?? 25) / 100

            ZStack(alignment: .leading) {
                Rectangle().fill(Color(red: 0.16, green: 0.42, blue: 0.22))

                // Yard lines every ten yards.
                ForEach(0...10, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(index == 0 || index == 10 ? 0.9 : 0.35))
                        .frame(width: index % 5 == 0 ? 2 : 1)
                        .offset(x: endZone + playingWidth * Double(index) / 10)
                }

                // End zones in each team's colour.
                Rectangle()
                    .fill(Color(hex: app.league?.team(id: record.awayTeamID)?.colors.primaryHex ?? "#333"))
                    .frame(width: endZone)
                Rectangle()
                    .fill(Color(hex: app.league?.team(id: record.homeTeamID)?.colors.primaryHex ?? "#333"))
                    .frame(width: endZone)
                    .offset(x: width - endZone)

                // Line of scrimmage and the line to gain.
                Rectangle()
                    .fill(.blue)
                    .frame(width: 2)
                    .offset(x: endZone + playingWidth * ballFraction)
                if let play = currentPlay, play.down > 0 {
                    let firstDown = min(1.0, ballFraction + Double(play.distance) / 100)
                    Rectangle()
                        .fill(.yellow)
                        .frame(width: 2)
                        .offset(x: endZone + playingWidth * firstDown)
                }

                // The ball.
                Ellipse()
                    .fill(Color(red: 0.45, green: 0.22, blue: 0.10))
                    .frame(width: 16, height: 10)
                    .overlay(Capsule().stroke(.white, lineWidth: 1).frame(width: 8, height: 1))
                    .offset(x: endZone + playingWidth * ballFraction - 8, y: height * 0.18)
                    .animation(.easeInOut(duration: 0.35), value: ballFraction)
            }
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: Layout.chipRadius))
        .padding(Layout.small)
    }

    private var lastPlayCard: some View {
        VStack(alignment: .leading, spacing: Layout.tight) {
            Text("LAST PLAY")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.secondary)
            Text(currentPlay?.description ?? "Ready for kickoff.")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let play = currentPlay, play.yards != 0 {
                Chip(
                    play.yards > 0 ? "+\(play.yards) yards" : "\(play.yards) yards",
                    color: play.yards > 0 ? .green : .red
                )
            }
        }
        .card()
        .padding(.horizontal, Layout.small)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: Layout.small) {
            HStack(spacing: Layout.small) {
                Button {
                    step(1)
                } label: {
                    Label("Snap", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    step(8)
                } label: {
                    Label("Drive", systemImage: "forward.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                revealedPlays = record.plays.count
                onFinish()
            } label: {
                Label("Sim to Final", systemImage: "flag.checkered").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Text("Every mode runs the same simulation — playing it out never changes the result.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Layout.medium)
        .background(.bar)
    }

    private func step(_ count: Int) {
        revealedPlays = min(record.plays.count, revealedPlays + count)
        if revealedPlays >= record.plays.count { onFinish() }
    }
}

/// League-wide statistical leaders.
struct StatsView: View {
    @Environment(AppState.self) private var app
    @State private var category = Category.passing

    enum Category: String, CaseIterable {
        case passing = "Passing"
        case rushing = "Rushing"
        case receiving = "Receiving"
        case tackles = "Tackles"
        case sacks = "Sacks"
        case interceptions = "Interceptions"
        case kicking = "Kicking"

        var color: Color {
            switch self {
            case .passing: .blue
            case .rushing: .orange
            case .receiving: .green
            case .tackles: .red
            case .sacks: .purple
            case .interceptions: .indigo
            case .kicking: .teal
            }
        }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Layout.tight) {
                        ForEach(Category.allCases, id: \.self) { option in
                            Button { category = option } label: {
                                Chip(option.rawValue, color: option.color, filled: category == option)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section(category.rawValue) {
                if leaders.isEmpty {
                    Text("No statistics yet this season.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(leaders.enumerated()), id: \.element.player.id) { index, entry in
                        NavigationLink { PlayerCardView(player: entry.player) } label: {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.player.name).font(.subheadline)
                                    Text("\(entry.player.position.abbreviation) · \(entry.teamAbbreviation)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(entry.value)
                                    .font(.subheadline.monospacedDigit().weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Statistics")
    }

    private struct Leader {
        let player: Player
        let teamAbbreviation: String
        let value: String
        let sortKey: Double
    }

    private var leaders: [Leader] {
        guard let league = app.league else { return [] }
        var entries: [Leader] = []

        for team in league.teams {
            for player in team.roster {
                let line = league.seasonStats(for: player.id)
                guard !line.isEmpty else { continue }
                let leader: Leader?
                switch category {
                case .passing:
                    leader = line.passingYards > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.passingYards) yds, \(line.passingTouchdowns) TD",
                                 sortKey: Double(line.passingYards))
                        : nil
                case .rushing:
                    leader = line.rushingYards > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.rushingYards) yds, \(line.rushingTouchdowns) TD",
                                 sortKey: Double(line.rushingYards))
                        : nil
                case .receiving:
                    leader = line.receivingYards > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.receptions) rec, \(line.receivingYards) yds",
                                 sortKey: Double(line.receivingYards))
                        : nil
                case .tackles:
                    leader = line.tackles > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.tackles)", sortKey: Double(line.tackles))
                        : nil
                case .sacks:
                    leader = line.sacks > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.sacks)", sortKey: Double(line.sacks))
                        : nil
                case .interceptions:
                    leader = line.interceptions > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.interceptions)", sortKey: Double(line.interceptions))
                        : nil
                case .kicking:
                    leader = line.fieldGoalsAttempted > 0
                        ? Leader(player: player, teamAbbreviation: team.abbreviation,
                                 value: "\(line.fieldGoalsMade)/\(line.fieldGoalsAttempted)",
                                 sortKey: Double(line.fieldGoalsMade))
                        : nil
                }
                if let leader { entries.append(leader) }
            }
        }

        return entries.sorted { $0.sortKey > $1.sortKey }.prefix(25).map { $0 }
    }
}
