import SwiftUI
import FootballSimCore

/// The home screen: this week's game, how to play it, and the state of the league.
struct SeasonHubView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme

    @State private var segment = Segment.standings
    @State private var showingPreview = false
    @State private var playMode: PlayMode?

    enum Segment: String, CaseIterable {
        case standings = "Standings"
        case power = "Power"
        case news = "News"
    }

    enum PlayMode: Identifiable {
        case callPlays, onField
        var id: Int { self == .callPlays ? 0 : 1 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                phaseCard

                if let league = app.league {
                    if league.phase.isOffseason {
                        OffseasonHubCard()
                    } else if league.phase == .preseason {
                        preseasonCard
                    } else if let game = app.nextGame {
                        matchupCard(game)
                    } else if app.isOnBye {
                        byeCard
                    }
                }

                if let last = lastResult { lastGameCard(last) }

                segmentPicker
                segmentContent
            }
            .padding(Layout.medium)
        }
        .background(Color.pageBackground)
        .navigationTitle(app.league?.phase.label ?? "Season")
        .sheet(isPresented: $showingPreview) {
            if let game = app.nextGame { MatchupPreviewSheet(game: game) }
        }
        .fullScreenCoverCompat(item: $playMode) { mode in
            if let game = app.nextGame {
                switch mode {
                case .onField: ArcadeFieldView(game: game)
                case .callPlays: LiveGameView(game: game, arcade: false)
                }
            }
        }
    }

    // MARK: - Cards

    private var phaseCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(String(app.league?.year ?? 0)) Season")
                    .font(.headline)
                Text(app.league?.phase.label ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let record = userRecord {
                Chip(record.description, color: theme.primary, filled: true)
            }
        }
        .card()
    }

    private var preseasonCard: some View {
        VStack(spacing: Layout.medium) {
            Text("PRESEASON")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white.opacity(0.8))
            Text("Kickoff Outlook")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if let team = app.userTeam {
                HStack(spacing: Layout.large) {
                    statTile("OVERALL", Format.rating(team.overallRating))
                    statTile("OFFENSE", Format.rating(team.offenseRating))
                    statTile("DEFENSE", Format.rating(team.defenseRating))
                }
            }

            Button {
                app.kickOffSeason()
            } label: {
                Label("Kick Off the Season", systemImage: "football.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.22))
        }
        .padding(Layout.large)
        .frame(maxWidth: .infinity)
        .background(theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.small)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.16)))
    }

    private func matchupCard(_ game: ScheduledGame) -> some View {
        VStack(spacing: Layout.medium) {
            HStack {
                Chip("Week \(game.week)", color: theme.primary, filled: true)
                Spacer()
                Chip(game.homeTeamID == app.league?.userTeamID ? "HOME" : "AWAY", color: .orange)
            }

            if let league = app.league,
               let home = league.team(id: game.homeTeamID),
               let away = league.team(id: game.awayTeamID) {
                HStack(spacing: Layout.medium) {
                    teamColumn(away, league: league)
                    Text("@").font(.headline).foregroundStyle(.secondary)
                    teamColumn(home, league: league)
                }

                MatchupPredictionRow(home: home, away: away, showSpread: league.settings.showPredictionLine)
            }

            Button { showingPreview = true } label: {
                Text("Tap for full matchup preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: Layout.small) {
                HStack(spacing: Layout.small) {
                    Button {
                        app.advanceWeek()
                    } label: {
                        Label("Sim Week", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button { playMode = .callPlays } label: {
                        Label("Call the Plays", systemImage: "list.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button { playMode = .onField } label: {
                    Label("On the Field", systemImage: "gamecontroller.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .card()
    }

    private func teamColumn(_ team: Team, league: League) -> some View {
        VStack(spacing: 4) {
            TeamBadge(team: team, size: 44)
            Text(team.abbreviation).font(.subheadline.weight(.bold))
            Text(league.record(for: team.id).description)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Chip("OVR \(Int(team.overallRating))", color: RatingPalette.color(for: team.overallRating))
        }
        .frame(maxWidth: .infinity)
    }

    private var byeCard: some View {
        VStack(spacing: Layout.small) {
            Text("Bye Week").font(.headline)
            Text("No game this week. Injuries heal and the roster rests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { app.advanceWeek() } label: {
                Label("Advance Week", systemImage: "forward.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .card()
    }

    private func lastGameCard(_ record: GameRecord) -> some View {
        NavigationLink {
            GameReportView(record: record)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Last Game").font(.caption).foregroundStyle(.secondary)
                    Text(scoreline(record)).font(.headline)
                }
                Spacer()
                let won = record.didWin(app.league?.userTeamID ?? UUID())
                Chip(won ? "WIN" : (record.isTie ? "TIE" : "LOSS"), color: won ? .green : .red, filled: true)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .card()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Segments

    private var segmentPicker: some View {
        Picker("", selection: $segment) {
            ForEach(Segment.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch segment {
        case .standings: DivisionStandingsCard()
        case .power: PowerRankingsCard()
        case .news: NewsFeedCard()
        }
    }

    // MARK: - Helpers

    private var userRecord: TeamRecord? {
        guard let league = app.league else { return nil }
        return league.record(for: league.userTeamID)
    }

    private var lastResult: GameRecord? {
        guard let league = app.league else { return nil }
        return league.results.last { $0.involves(league.userTeamID) }
    }

    private func scoreline(_ record: GameRecord) -> String {
        guard let league = app.league else { return "" }
        let mine = record.score(for: league.userTeamID)
        let theirs = record.opponentScore(for: league.userTeamID)
        let opponentID = record.homeTeamID == league.userTeamID ? record.awayTeamID : record.homeTeamID
        let opponent = league.team(id: opponentID)?.abbreviation ?? "OPP"
        return "\(mine)-\(theirs) vs \(opponent)"
    }
}

/// Spread and win-probability pills shown on the matchup card.
struct MatchupPredictionRow: View {
    let home: Team
    let away: Team
    let showSpread: Bool

    private var edge: Double {
        home.overallRating + Double(PlayMatrix.homeFieldRatingBonus) - away.overallRating
    }

    /// Logistic map from rating edge to win probability.
    private var homeWinProbability: Double {
        1 / (1 + pow(2.718_281_8, -edge * 0.16))
    }

    var body: some View {
        HStack(spacing: Layout.small) {
            if showSpread {
                pill(
                    "LINE",
                    edge >= 0
                        ? "\(home.abbreviation) -\(String(format: "%.1f", edge * 0.55))"
                        : "\(away.abbreviation) -\(String(format: "%.1f", -edge * 0.55))",
                    .blue
                )
            }
            pill("WIN %", "\(Int(homeWinProbability * 100))%", homeWinProbability > 0.5 ? .green : .red)
            pill("EDGE", edge >= 0 ? "+\(Int(edge))" : "\(Int(edge))", edge >= 0 ? .green : .red)
        }
    }

    private func pill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.tight)
        .background(RoundedRectangle(cornerRadius: Layout.chipRadius).fill(Color.secondary.opacity(0.10)))
    }
}

/// `fullScreenCover` is iOS-only; on macOS (where this package is type-checked) fall back to a
/// sheet so the same source compiles on both.
extension View {
    @ViewBuilder
    func fullScreenCoverCompat<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}
