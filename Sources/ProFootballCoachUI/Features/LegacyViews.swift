import SwiftUI
import FootballSimCore

/// Preset challenges, picked from the main menu.
struct ScenarioPickerView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var chosen: Scenario?
    @State private var teamIndex = 0
    @State private var firstName = ""
    @State private var lastName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Scenario.all) { scenario in
                        Button { chosen = scenario } label: {
                            VStack(alignment: .leading, spacing: Layout.tight) {
                                HStack {
                                    Text(scenario.name).font(.headline)
                                    Spacer()
                                    if chosen?.id == scenario.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                                Text(scenario.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Label(scenario.objective, systemImage: "target")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Choose a challenge")
                }

                if chosen != nil {
                    Section("Your Team") {
                        Picker("Team", selection: $teamIndex) {
                            ForEach(Array(TeamTable.entries.enumerated()), id: \.offset) { index, entry in
                                Text("\(entry.city) \(entry.name)").tag(index)
                            }
                        }
                    }
                    Section("Coach") {
                        TextField("First name", text: $firstName)
                        TextField("Last name", text: $lastName)
                    }
                    Section {
                        Button("Start Scenario") { start() }
                    }
                }
            }
            .navigationTitle("Scenarios")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func start() {
        guard let chosen else { return }
        let coach = CoachProfile(
            firstName: firstName.isEmpty ? "Alex" : firstName,
            lastName: lastName.isEmpty ? "Rivers" : lastName,
            age: 42,
            background: .playcaller
        )
        app.startScenario(
            chosen,
            teamIndex: teamIndex,
            coach: coach,
            settings: LeagueSettings()
        )
        dismiss()
    }
}

/// League record book — seeded marks that current players chase down.
struct RecordsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if let league = app.league {
                let records = RecordsBook.current(in: league)
                Section("Single Season") {
                    ForEach(records.filter { !$0.kind.isCareer }) { record in
                        recordRow(record)
                    }
                }
                Section("Career") {
                    ForEach(records.filter(\.kind.isCareer)) { record in
                        recordRow(record)
                    }
                }
            }
        }
        .navigationTitle("Record Book")
    }

    private func recordRow(_ record: LeagueRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.kind.displayName).font(.subheadline)
                Text("\(record.holderName) · \(String(record.year))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.value)")
                .font(.headline.monospacedDigit())
        }
    }
}

/// Everyone enshrined since the franchise began.
struct HallOfFameView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            let members = (app.league?.hallOfFame ?? []).sorted { $0.inductionYear > $1.inductionYear }
            if members.isEmpty {
                EmptyStateView(
                    icon: "star.circle",
                    title: "Nobody enshrined yet",
                    message: "Great careers are honoured when they end. Give it a few seasons."
                )
            } else {
                ForEach(members) { member in
                    HStack(spacing: Layout.medium) {
                        Image(systemName: "star.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name).font(.headline)
                            Text("\(member.position.displayName) · Class of \(String(member.inductionYear))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(member.careerSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Hall of Fame")
    }
}

/// Everything the coach has actually won, in one cabinet.
///
/// The record book and the Hall of Fame are league-wide; this screen is deliberately selfish —
/// only silverware this coach and this team earned appears here, because that is the thing a
/// franchise player wants to look at after a title.
struct TrophyRoomView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                if let league = app.league {
                    career(league)
                    if titles.isEmpty && conferenceTitles.isEmpty && awards.isEmpty {
                        EmptyStateView(
                            icon: "trophy",
                            title: "The case is empty",
                            message: "Win a title, take a conference, or coach a player to an "
                                + "award and it will be waiting here."
                        )
                        .card()
                    } else {
                        if !titles.isEmpty { trophyCase }
                        if !conferenceTitles.isEmpty { conferenceCase }
                        if !awards.isEmpty { awardCase }
                    }
                }
            }
            .padding(Layout.medium)
        }
        .background(Color.pageBackground)
        .navigationTitle("Trophy Room")
    }

    private func career(_ league: League) -> some View {
        VStack(spacing: Layout.small) {
            Image(systemName: titles.isEmpty ? "shield" : "trophy.fill")
                .font(.system(size: 44))
                .foregroundStyle(titles.isEmpty ? .white.opacity(0.7) : .yellow)
            Text(league.coach.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(careerRecord(league))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: Layout.small) {
                Chip("\(league.coach.championships) titles", color: .white)
                Chip("\(league.coach.playoffAppearances) playoffs", color: .white)
                Chip(
                    league.coach.teamsCoached == 1 ? "1 team" : "\(league.coach.teamsCoached) teams",
                    color: .white,
                    filled: false
                )
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.large)
        .background(theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    private var trophyCase: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Championships")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Layout.small)],
                      spacing: Layout.small) {
                ForEach(titles, id: \.self) { year in
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.title)
                            .foregroundStyle(.yellow)
                        Text(String(year)).font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.small)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .card()
    }

    private var conferenceCase: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Conference Titles")
            ForEach(conferenceTitles, id: \.self) { year in
                HStack {
                    Image(systemName: "flag.fill").foregroundStyle(.orange)
                    Text(String(year)).font(.subheadline)
                    Spacer()
                    Text(titles.contains(year) ? "Won the final" : "Lost the final")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    private var awardCase: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Your Players' Awards")
            ForEach(Array(awards.enumerated()), id: \.offset) { _, award in
                HStack {
                    Image(systemName: "rosette").foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(award.playerName).font(.subheadline)
                        Text(award.kind.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(award.year)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    /// Career totals only absorb a season once it ends, so fold the year in progress in here —
    /// otherwise a coach in November is told he has never taken charge of a game.
    private func careerRecord(_ league: League) -> String {
        let coach = league.coach
        let season = league.record(for: league.userTeamID)
        let wins = coach.careerWins + season.wins
        let losses = coach.careerLosses + season.losses
        let ties = coach.careerTies + season.ties
        let games = wins + losses + ties
        guard games > 0 else { return "No games coached yet" }
        let percentage = Double(wins) / Double(games) * 100
        let record = ties > 0 ? "\(wins)-\(losses)-\(ties)" : "\(wins)-\(losses)"
        return "\(record) · \(String(format: "%.1f", percentage))%"
    }

    private var userTeamID: UUID? { app.league?.userTeamID }

    private var titles: [Int] {
        guard let userTeamID, let history = app.league?.history else { return [] }
        return history.filter { $0.championTeamID == userTeamID }.map(\.year).sorted(by: >)
    }

    /// Both finalists won their conference, so reaching the final is the title.
    private var conferenceTitles: [Int] {
        guard let userTeamID, let history = app.league?.history else { return [] }
        return history
            .filter { $0.championTeamID == userTeamID || $0.runnerUpTeamID == userTeamID }
            .map(\.year)
            .sorted(by: >)
    }

    private var awards: [SeasonAward] {
        guard let userTeamID, let history = app.league?.history else { return [] }
        return history
            .flatMap(\.awards)
            .filter { $0.teamID == userTeamID }
            .sorted { $0.year > $1.year }
    }
}
