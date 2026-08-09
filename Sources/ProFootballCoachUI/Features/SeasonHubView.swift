import SwiftUI
import FootballSimCore

/// The home screen: this week's game, how to play it, and the state of the league.
struct SeasonHubView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme

    @State private var segment = Segment.standings
    @State private var showingPreview = false
    @State private var playMode: PlayMode?
    @State private var confirmingSimWeek = false

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
                masthead

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
        .background(Almanac.page)
        .inlineTitleCompat()
        .navigationTitle("")
        .sheet(isPresented: $showingPreview) {
            if let game = app.nextGame { MatchupPreviewSheet(game: game) }
        }
        .confirmationDialog(
            "Sim this week?",
            isPresented: $confirmingSimWeek,
            titleVisibility: .visible
        ) {
            Button("Sim the week", role: .destructive) { app.advanceWeek() }
            Button("Go back", role: .cancel) {}
        } message: {
            Text("Your game is played for you and the result stands. You cannot replay it.")
        }
        .fullScreenCoverCompat(item: $playMode) { mode in
            if let game = app.nextGame {
                switch mode {
                case .onField: ArcadeFieldView(game: game)
                case .callPlays: LiveGameView(game: game)
                }
            }
        }
    }

    // MARK: - Cards

    /// The front page's masthead: the edition's date line and the franchise's record, over a
    /// heavy rule. No card — the page is the surface.
    private var masthead: some View {
        VStack(alignment: .leading, spacing: Layout.tight) {
            Text(app.userTeam?.fullName.uppercased() ?? "THE LEAGUE")
                .font(.almanacLabel)
                .tracking(1.2)
                .foregroundStyle(Almanac.muted)

            // Year and record share the top line; the phase gets its own so a long label like
            // "Conference Championships" cannot wrap and shove the record out of alignment.
            HStack(alignment: .firstTextBaseline) {
                Text(String(app.league?.year ?? 0))
                    .font(.almanacDisplay)
                    .foregroundStyle(Almanac.ink)
                Spacer(minLength: Layout.small)
                if let record = userRecord {
                    Text(record.description)
                        .font(.almanacFigure)
                        .foregroundStyle(Almanac.ink)
                }
            }

            Text(app.league?.phase.label ?? "")
                .font(.almanacTitle)
                .foregroundStyle(Almanac.muted)
                .fixedSize(horizontal: false, vertical: true)

            Rule(.heavy)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mastheadReading)
    }

    private var mastheadReading: String {
        let team = app.userTeam?.fullName ?? "The league"
        let phase = app.league?.phase.label ?? ""
        let record = userRecord.map { ", \($0.description)" } ?? ""
        return "\(team). \(String(app.league?.year ?? 0)) \(phase)\(record)."
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

    /// The week's story. This is one of the seven earned editions: on gameday the page takes the
    /// franchise's colour plate, because this is the moment the almanac is written about.
    private func matchupCard(_ game: ScheduledGame) -> some View {
        VStack(alignment: .leading, spacing: Layout.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("WEEK \(game.week)")
                    .font(.almanacLabel)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(game.homeTeamID == app.league?.userTeamID ? "AT HOME" : "ON THE ROAD")
                    .font(.almanacLabel)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.85))
            }

            if let league = app.league,
               let home = league.team(id: game.homeTeamID),
               let away = league.team(id: game.awayTeamID) {
                HStack(alignment: .center, spacing: Layout.small) {
                    editionTeam(away, league: league)
                    Text("at")
                        .font(.almanacBody)
                        .foregroundStyle(.white.opacity(0.7))
                    editionTeam(home, league: league)
                }
                .frame(maxWidth: .infinity)

                Text(MatchupOdds.summary(home: home, away: away, userTeamID: league.userTeamID))
                    .font(.almanacBody)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button { showingPreview = true } label: {
                HStack(spacing: Layout.tight) {
                    Text("The full preview")
                    Image(systemName: "chevron.right").font(.caption2)
                }
                .font(.almanacLabel)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.vertical, Layout.small)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: Layout.small) {
                Button { playMode = .callPlays } label: {
                    Label("Call the Plays", systemImage: "list.clipboard")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 30)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))

                HStack(spacing: Layout.small) {
                    Button { playMode = .onField } label: {
                        Label("On the Field", systemImage: "gamecontroller.fill")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 30)
                    }
                    .buttonStyle(.bordered)

                    Button { confirmingSimWeek = true } label: {
                        Label("Sim", systemImage: "forward.fill")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 30)
                    }
                    .buttonStyle(.bordered)
                }
                .tint(.white.opacity(0.9))
            }
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    private func editionTeam(_ team: Team, league: League) -> some View {
        VStack(spacing: Layout.tight) {
            TeamBadge(team: team, size: 44)
            Text(team.name)
                .font(.almanacTitle)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(league.record(for: team.id).description) · \(Int(team.overallRating)) ovr")
                .font(.almanacLabel)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(team.fullName), \(league.record(for: team.id).description), "
                + "overall \(Int(team.overallRating))"
        )
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

    /// Last week's result, written as a line of the record rather than boxed in a card with a
    /// coloured pill. The outcome is a word, so it survives without colour.
    private func lastGameCard(_ record: GameRecord) -> some View {
        let won = record.didWin(app.league?.userTeamID ?? UUID())
        let outcome = won ? "Won" : (record.isTie ? "Tied" : "Lost")
        let tier: Color = won ? Almanac.ink : Almanac.muted

        return NavigationLink {
            GameReportView(record: record)
        } label: {
            VStack(alignment: .leading, spacing: Layout.tight) {
                Text("LAST WEEK")
                    .font(.almanacLabel)
                    .tracking(1.2)
                    .foregroundStyle(Almanac.muted)
                HStack(alignment: .firstTextBaseline, spacing: Layout.small) {
                    Text(outcome)
                        .font(.almanacTitle)
                        .foregroundStyle(tier)
                    Text(scoreline(record))
                        .font(.almanacFigure)
                        .foregroundStyle(Almanac.ink)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Almanac.muted)
                }
                Rule()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Last week: \(outcome), \(scoreline(record)). Opens the game report.")
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

/// The week's lede: one authored sentence, then the numbers behind it.
///
/// Replaces the LINE / WIN % / EDGE pill row carried over from the reference app — three numbers
/// the reader had to assemble into a meaning. The Almanac states the meaning first, in the
/// coordinator's voice, and keeps the figures underneath it where they can be checked.
struct MatchupLede: View {
    let home: Team
    let away: Team
    let userTeamID: UUID
    let showSpread: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            Text(MatchupOdds.summary(home: home, away: away, userTeamID: userTeamID))
                .font(.almanacBody)
                .foregroundStyle(Almanac.ink)
                .fixedSize(horizontal: false, vertical: true)

            Rule()

            HStack(alignment: .firstTextBaseline, spacing: Layout.medium) {
                if showSpread {
                    figure("Line", spreadLabel)
                }
                figure("Win", "\(Int((winProbabilityForReader * 100).rounded()))%")
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func figure(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.tight) {
            Text(label.uppercased())
                .font(.almanacLabel)
                .tracking(0.6)
                .foregroundStyle(Almanac.muted)
            Text(value)
                .font(.almanacFigure)
                .foregroundStyle(Almanac.ink)
        }
    }

    /// Always stated from the reader's side when they are playing, so "62%" never silently means
    /// the opponent.
    private var winProbabilityForReader: Double {
        let homeProbability = MatchupOdds.homeWinProbability(home: home, away: away)
        return home.id == userTeamID ? homeProbability : 1 - homeProbability
    }

    private var spreadLabel: String {
        let spread = MatchupOdds.spread(home: home, away: away)
        let favourite = spread >= 0 ? home : away
        return "\(favourite.abbreviation) −\(String(format: "%.1f", abs(spread)))"
    }
}

/// `navigationBarTitleDisplayMode` is iOS-only; the package also type-checks on macOS.
extension View {
    @ViewBuilder
    func inlineTitleCompat() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
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
