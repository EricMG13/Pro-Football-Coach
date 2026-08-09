import SwiftUI
import FootballSimCore

/// Call the Plays — the game played one snap at a time, with the user calling their own offence.
///
/// This screen used to resolve the entire game in `onAppear` and then replay the finished log at
/// whatever pace the reader clicked through. The app's own subtitle is "Run the franchise. Call
/// every down", and the genre has been asking for play-calling since the KushDingies fork, so a
/// replay viewer wearing the name was the single worst thing in the product. It drives
/// `InteractiveGame` now: the engine owns every rule, and it pauses when the user's offence is on
/// the field.
struct LiveGameView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.teamTheme) private var theme

    let game: ScheduledGame

    @State private var live: InteractiveGame?
    @State private var lastPlays: [PlayEvent] = []
    @State private var confirmingSimToEnd = false

    var body: some View {
        NavigationStack {
            Group {
                if let live {
                    if live.state == .finished, let record = live.record {
                        finalWhistle(record)
                    } else {
                        callSheet(live)
                    }
                } else {
                    ProgressView("Kickoff…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Broadcast.page)
            .inlineTitleCompat()
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sim to Final") { confirmingSimToEnd = true }
                        .disabled(live?.state == .finished)
                }
            }
        }
        .confirmationDialog(
            "Hand the rest to the engine?",
            isPresented: $confirmingSimToEnd,
            titleVisibility: .visible
        ) {
            Button("Sim to final", role: .destructive) { simulateRemainder() }
            Button("Keep calling", role: .cancel) {}
        } message: {
            Text("The rest of the game is resolved for you. The result stands.")
        }
        .onAppear(perform: begin)
    }

    private var title: String {
        guard let league = app.league,
              let home = league.team(id: game.homeTeamID),
              let away = league.team(id: game.awayTeamID) else { return "Game" }
        return "\(away.abbreviation) at \(home.abbreviation)"
    }

    // MARK: - Driving the engine

    private func begin() {
        guard live == nil, let league = app.league,
              let home = league.team(id: game.homeTeamID),
              let away = league.team(id: game.awayTeamID) else { return }

        var started = InteractiveGame(
            home: home,
            away: away,
            userTeamID: league.userTeamID,
            week: game.week,
            year: league.year,
            kind: game.kind,
            scheduledGameID: game.id,
            settings: league.settings,
            neutralSite: game.isNeutralSite,
            rng: league.rng
        )
        lastPlays = started.advanceUntilUserTurn()
        live = started
        commitRNG()
    }

    private func call(_ play: OffensivePlay) {
        guard var current = live else { return }
        lastPlays = current.playUserSnap(call: play, execution: .neutral)
        if current.state != .finished {
            lastPlays += current.advanceUntilUserTurn()
        }
        live = current
        commitRNG()
    }

    private func simulateRemainder() {
        guard var current = live else { return }
        current.simulateRemainder()
        live = current
        commitRNG()
    }

    /// The game borrows the league's random stream, so hand back where it got to. Otherwise a
    /// reloaded franchise would replay the same numbers.
    private func commitRNG() {
        guard let live else { return }
        let stream = live.currentRNG
        app.mutate { $0.rng = stream }
    }

    private func finish(_ record: GameRecord) {
        app.advanceWeek(userGameResult: record)
        dismiss()
    }

    // MARK: - The call sheet

    private func callSheet(_ live: InteractiveGame) -> some View {
        VStack(spacing: 0) {
            scoreBug(live)

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.medium) {
                    if let latest = lastPlays.last ?? live.plays.last {
                        consequence(latest)
                    }

                    if case .awaitingUserPlay(let situation) = live.state {
                        situationLine(situation)
                        calls(for: situation)
                    } else {
                        Text("The opposition has the ball.")
                            .font(.bodyFont)
                            .foregroundStyle(Broadcast.muted)
                    }

                    driveLog(live)
                }
                .padding(Layout.medium)
            }
        }
    }

    /// The score bug: both franchises in their own colours, the clock, and the ball.
    private func scoreBug(_ live: InteractiveGame) -> some View {
        let league = app.league
        let home = league?.team(id: game.homeTeamID)
        let away = league?.team(id: game.awayTeamID)
        let userIsHome = league?.userTeamID == game.homeTeamID

        return VStack(spacing: Layout.tight) {
            HStack(alignment: .center, spacing: Layout.medium) {
                scoreSide(away, score: userIsHome ? live.opponentScore : live.userScore)
                VStack(spacing: 2) {
                    Text("Q\(live.quarter)")
                        .font(.labelFont)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(Format.clock(live.clockRemaining))
                        .font(.figureFont)
                        .foregroundStyle(.white)
                }
                scoreSide(home, score: userIsHome ? live.userScore : live.opponentScore)
            }
        }
        .padding(Layout.medium)
        .frame(maxWidth: .infinity)
        .background(theme.gradient)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(away?.name ?? "Away") \(userIsHome ? live.opponentScore : live.userScore), "
                + "\(home?.name ?? "Home") \(userIsHome ? live.userScore : live.opponentScore). "
                + "Quarter \(live.quarter), \(Format.clock(live.clockRemaining)) remaining."
        )
    }

    private func scoreSide(_ team: Team?, score: Int) -> some View {
        VStack(spacing: 2) {
            Text(team?.abbreviation ?? "—")
                .font(.labelFont)
                .foregroundStyle(.white.opacity(0.85))
            Text("\(score)")
                .font(.displayFont)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func consequence(_ play: PlayEvent) -> some View {
        VStack(alignment: .leading, spacing: Layout.tight) {
            Text("Last play")
                .font(.labelFont)
                .foregroundStyle(Broadcast.muted)
            Text(play.description)
                .font(.bodyFont)
                .foregroundStyle(Broadcast.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rule()
        }
        .accessibilityElement(children: .combine)
    }

    private func situationLine(_ situation: GameSituation) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.small) {
            Text("\(ordinal(situation.down)) & \(situation.distance)")
                .font(.titleFont)
                .foregroundStyle(Broadcast.ink)
            Text(fieldPosition(situation))
                .font(.bodyFont)
                .foregroundStyle(Broadcast.muted)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(ordinal(situation.down)) and \(situation.distance), \(fieldPosition(situation))"
        )
    }

    private func fieldPosition(_ situation: GameSituation) -> String {
        let yard = situation.yardLine
        if yard == 50 { return "at midfield" }
        return yard < 50 ? "on your own \(yard)" : "on their \(100 - yard)"
    }

    /// The call sheet proper. The coordinator's suggestion is marked, not pre-selected — the
    /// point of the screen is that the call is yours.
    private func calls(for situation: GameSituation) -> some View {
        let suggested = suggestion(for: situation)

        return VStack(alignment: .leading, spacing: Layout.small) {
            Text("Your call")
                .font(.labelFont)
                .foregroundStyle(Broadcast.muted)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Layout.small),
                          GridItem(.flexible(), spacing: Layout.small)],
                spacing: Layout.small
            ) {
                ForEach(OffensivePlay.standardCalls, id: \.self) { play in
                    callButton(play, isSuggested: play == suggested)
                }
            }

            if situation.down == 4 {
                Rule()
                Text("Fourth down")
                    .font(.labelFont)
                    .foregroundStyle(Broadcast.muted)
                HStack(spacing: Layout.small) {
                    callButton(.fieldGoal, isSuggested: false)
                    callButton(.punt, isSuggested: false)
                }
            }
        }
    }

    /// What the offensive coordinator would call. Marked on the sheet, never pre-selected — the
    /// whole point of the screen is that the call is the user's.
    private func suggestion(for situation: GameSituation) -> OffensivePlay? {
        guard let league = app.league,
              let offense = league.team(id: league.userTeamID) else { return nil }
        // A throwaway stream: this is a hint, and it must not consume the game's randomness.
        var rng = SeededRandom(seed: UInt64(situation.down &* 31 &+ situation.distance))
        return PlayCaller.offensiveCall(situation: situation, team: offense, rng: &rng)
    }

    private func callButton(_ play: OffensivePlay, isSuggested: Bool) -> some View {
        Button { call(play) } label: {
            VStack(spacing: 2) {
                Text(play.displayName)
                    .font(.bodyFont)
                    .foregroundStyle(Broadcast.ink)
                if isSuggested {
                    Text("the coordinator likes this")
                        .font(.labelFont)
                        .foregroundStyle(Broadcast.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.vertical, Layout.tight)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(
                        isSuggested ? Broadcast.ink : Broadcast.rule,
                        lineWidth: isSuggested ? 1.5 : 0.8
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isSuggested ? "\(play.displayName). Your coordinator's suggestion." : play.displayName
        )
    }

    private func driveLog(_ live: InteractiveGame) -> some View {
        VStack(alignment: .leading, spacing: Layout.tight) {
            Rule()
            Text("The drive")
                .font(.labelFont)
                .foregroundStyle(Broadcast.muted)
            ForEach(Array(live.plays.suffix(12).reversed())) { play in
                VStack(alignment: .leading, spacing: 2) {
                    Text(play.description)
                        .font(.bodyFont)
                        .foregroundStyle(Broadcast.ink)
                    Text("\(play.clockLabel) · \(play.awayScore)–\(play.homeScore)")
                        .font(.labelFont)
                        .foregroundStyle(Broadcast.muted)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                Rule()
            }
        }
    }

    // MARK: - The final whistle

    /// One of the seven earned editions: the result takes the whole page, in the winner's colours,
    /// consequence first.
    private func finalWhistle(_ record: GameRecord) -> some View {
        let userID = app.league?.userTeamID ?? UUID()
        let won = record.didWin(userID)
        let mine = record.score(for: userID)
        let theirs = record.opponentScore(for: userID)

        return ScrollView {
            VStack(spacing: Layout.large) {
                VStack(spacing: Layout.small) {
                    Text("Final")
                        .font(.labelFont)
                        .tracking(2.0)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(won ? "You won" : (record.isTie ? "A tie" : "You lost"))
                        .font(.displayFont)
                        .foregroundStyle(.white)
                    Text("\(mine)–\(theirs)")
                        .font(.displayFont)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(Layout.large)
                .background(theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Final. \(won ? "You won" : (record.isTie ? "A tie" : "You lost")), "
                        + "\(mine) to \(theirs)."
                )

                VStack(spacing: Layout.small) {
                    NavigationLink { GameReportView(record: record) } label: {
                        Text("The full box score")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 30)
                    }
                    .buttonStyle(.bordered)

                    Button { finish(record) } label: {
                        Text("Finish the week")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 30)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(Layout.medium)
        }
    }

    private func ordinal(_ value: Int) -> String {
        switch value {
        case 1: "1st"
        case 2: "2nd"
        case 3: "3rd"
        default: "4th"
        }
    }
}
