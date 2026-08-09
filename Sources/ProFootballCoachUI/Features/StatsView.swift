import SwiftUI
import FootballSimCore

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
