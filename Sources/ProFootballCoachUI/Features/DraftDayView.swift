import SwiftUI
import FootballSimCore

/// Draft day, run one pick at a time.
///
/// The AI teams pick automatically and the screen stops whenever the user is on the clock,
/// so the one day a franchise game should slow down actually does.
struct DraftDayView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.teamTheme) private var theme

    @State private var positionFilter: Position?
    @State private var lastPick: CompletedPick?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if app.draftSession?.isFinished ?? true {
                    finishedState
                } else {
                    board
                }
                footer
            }
            .background(Broadcast.page)
            .navigationTitle("Draft Day")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { app.beginDraftIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Layout.small) {
            if let session = app.draftSession, let clock = session.onTheClock {
                Text("ROUND \(clock.round) · PICK \(session.pickInRound)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.85))
                Text(app.league?.team(id: clock.teamID)?.fullName ?? "")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                if session.isUserOnTheClock {
                    Chip("YOU ARE ON THE CLOCK", color: .white, filled: false)
                        .foregroundStyle(.white)
                }
            } else {
                Text("Draft complete")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }

            if let lastPick {
                Text("\(lastPick.playerName) — \(lastPick.position.abbreviation), \(lastPick.rating) OVR")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.medium)
        .background(theme.gradient)
    }

    // MARK: - Board

    private var board: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Layout.tight) {
                        Button { positionFilter = nil } label: {
                            Chip("All", color: .accentColor, filled: positionFilter == nil)
                        }
                        ForEach(Position.displayOrder, id: \.self) { position in
                            Button { positionFilter = position } label: {
                                Chip(
                                    position.abbreviation,
                                    color: .accentColor,
                                    filled: positionFilter == position
                                )
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Section("Best Available") {
                ForEach(available) { prospect in
                    HStack(spacing: Layout.small) {
                        Text(prospect.scoutedRange)
                            .font(.caption.monospacedDigit().weight(.bold))
                            .ratingStyle(prospect.midpoint)
                            .frame(width: 56, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(prospect.name).font(.subheadline)
                            HStack(spacing: Layout.tight) {
                                Text(prospect.position.abbreviation)
                                Text("· R\(prospect.projectedRound) projection")
                                if prospect.potentialRevealed {
                                    Text("· \(prospect.player.potential.rawValue)")
                                        .foregroundStyle(.purple)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if app.draftSession?.isUserOnTheClock == true {
                            Button("Draft") { select(prospect) }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
                    }
                }
            }

            if let picks = app.draftSession?.completed, !picks.isEmpty {
                Section("Picks So Far") {
                    ForEach(picks.suffix(20).reversed()) { pick in
                        HStack {
                            Text("\(pick.round).\(pick.pickInRound)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 34, alignment: .leading)
                            Text(app.league?.team(id: pick.teamID)?.abbreviation ?? "—")
                                .font(.caption.weight(.bold))
                                .frame(width: 40, alignment: .leading)
                            Text("\(pick.playerName) (\(pick.position.abbreviation))")
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var finishedState: some View {
        List {
            Section("Your Draft Class") {
                let mine = (app.draftSession?.completed ?? [])
                    .filter { $0.teamID == app.league?.userTeamID }
                if mine.isEmpty {
                    Text("No picks made.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(mine) { pick in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pick.playerName).font(.subheadline)
                            Text("Round \(pick.round), pick \(pick.pickInRound) · \(pick.position.abbreviation)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(pick.rating)")
                            .font(.headline.monospacedDigit())
                            .ratingStyle(pick.rating)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Layout.small) {
            if let session = app.draftSession, !session.isFinished {
                if session.isUserOnTheClock {
                    Button {
                        lastPick = app.autoPickForUser()
                    } label: {
                        Label("Let the Staff Pick", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        app.advanceDraftToUserPick()
                    } label: {
                        Label("Continue", systemImage: "forward.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    app.finishDraft()
                } label: {
                    Label("Sim Rest of Draft", systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            } else {
                Button {
                    app.completeDraftStage()
                    dismiss()
                } label: {
                    Label("Finish Draft", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Layout.medium)
        .background(.bar)
    }

    private var available: [DraftProspect] {
        let board = (app.draftSession?.prospects ?? [])
            .sorted { $0.midpoint > $1.midpoint }
        let filtered = positionFilter.map { position in
            board.filter { $0.position == position }
        } ?? board
        return Array(filtered.prefix(40))
    }

    private func select(_ prospect: DraftProspect) {
        lastPick = app.selectInDraft(prospectID: prospect.id)
    }
}

/// Keep your own expiring players before the market opens.
struct ReSignView: View {
    @Environment(AppState.self) private var app
    @State private var negotiating: Player?

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Cap space")
                    Spacer()
                    Text(Format.signedMoney(app.capSpace))
                        .foregroundStyle(app.capSpace >= 0 ? .green : .red)
                }
            }

            Section("Expiring Contracts") {
                if expiring.isEmpty {
                    Text("Nobody's deal is up.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(expiring) { player in
                    Button { negotiating = player } label: {
                        HStack {
                            Text("\(player.overall)")
                                .font(.subheadline.monospacedDigit().weight(.bold))
                                .ratingStyle(player.overall)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name).font(.subheadline)
                                Text("\(player.position.abbreviation) · \(player.age)y")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Format.money(asking(player)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Re-Sign")
        .sheet(item: $negotiating) { player in
            NegotiationSheet(player: player)
        }
    }

    private var expiring: [Player] {
        guard let team = app.userTeam else { return [] }
        return ReSignEngine.expiring(for: team)
    }

    private func asking(_ player: Player) -> Int {
        guard let league = app.league, let team = league.userTeam else { return 0 }
        return ReSignEngine.askingSalary(for: player, team: team, league: league)
    }
}

struct NegotiationSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let player: Player
    @State private var years = 3
    @State private var salaryMillions: Double = 1
    @State private var message: String?
    @State private var rounds = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    SummaryRow(label: "Overall", value: "\(player.overall)")
                    SummaryRow(label: "Age", value: "\(player.age)")
                    SummaryRow(label: "Asking", value: Format.money(asking))
                    if !player.traits.isEmpty {
                        SummaryRow(
                            label: "Traits",
                            value: player.traits.map(\.displayName).joined(separator: ", ")
                        )
                    }
                }

                Section("Your Offer") {
                    Stepper("Years: \(years)", value: $years, in: 1...LeagueRules.maxContractYears)
                    VStack(alignment: .leading) {
                        Text("Salary: \(Format.money(Int(salaryMillions * 1_000_000))) per year")
                        Slider(value: $salaryMillions, in: 0.9...max(1.0, Double(asking) / 1_000_000 * 2))
                    }
                    SummaryRow(label: "Cap hit", value: Format.money(offer.capHit(inYear: 0)))
                }

                Section("He Says") {
                    ProgressView(value: acceptance, total: 1)
                        .tint(acceptance > 0.6 ? .green : (acceptance > 0.35 ? .orange : .red))
                    Text(verdict)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message {
                    Section { Text(message).foregroundStyle(.red) }
                }

                Section {
                    Button("Offer Contract") { submit() }
                }
            }
            .navigationTitle(player.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear { salaryMillions = Double(asking) / 1_000_000 }
        }
    }

    private var asking: Int {
        guard let league = app.league, let team = league.userTeam else { return 1_000_000 }
        return ReSignEngine.askingSalary(for: player, team: team, league: league)
    }

    private var offer: Contract {
        Contract.flat(years: years, salary: Int(salaryMillions * 1_000_000))
    }

    private var acceptance: Double {
        guard let league = app.league, let team = league.userTeam else { return 0 }
        return ReSignEngine.acceptance(player: player, offer: offer, team: team, league: league)
    }

    private var verdict: String {
        switch acceptance {
        case 0.75...: "He would sign this today."
        case 0.5..<0.75: "He is interested."
        case 0.3..<0.5: "He wants more."
        default: "He would walk."
        }
    }

    private func submit() {
        guard app.league != nil else { return }
        rounds += 1
        // Rolling against the acceptance chance rather than gating on it keeps a negotiation
        // a negotiation: a marginal offer might work, and might not.
        if app.reSign(playerID: player.id, contract: offer, chance: acceptance) {
            dismiss()
        } else if rounds >= 3 {
            message = "He has ended talks and will test the market."
        } else {
            message = "Turned down. Try again with better terms."
        }
    }
}
