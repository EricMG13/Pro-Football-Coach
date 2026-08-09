import SwiftUI
import FootballSimCore

/// Cap sheet, free agency, trades and the draft — the week-to-week work of running a team.
struct FrontOfficeView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                capCard

                VStack(spacing: 0) {
                    NavigationLink { ContractsView() } label: {
                        row("Contracts", "doc.text.fill", .blue)
                    }
                    Divider().padding(.leading, 52)
                    NavigationLink { FreeAgencyView() } label: {
                        row("Free Agents (\(app.league?.freeAgents.count ?? 0))", "person.crop.circle.badge.plus", .green)
                    }
                    Divider().padding(.leading, 52)
                    NavigationLink { TradeCenterView() } label: {
                        row("Trade Center", "arrow.left.arrow.right", .orange)
                    }
                    Divider().padding(.leading, 52)
                    NavigationLink { DraftBoardView() } label: {
                        row("Draft Board", "person.badge.plus", .purple)
                    }
                }
                .card()

                ownerCard
            }
            .padding(Layout.medium)
        }
        .background(Broadcast.page)
        .navigationTitle("Front Office")
    }

    /// The ledger: what you have, what you have spent, and what you are still paying players
    /// who no longer play here.
    private var capCard: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            Text("Salary Cap")
                .font(.titleFont)
                .foregroundStyle(Broadcast.ink)

            LedgerRow("Cap space") {
                Text(Format.signedMoney(app.capSpace))
                    .foregroundStyle(app.capSpace >= 0 ? Broadcast.ink : Color(hex: RatingTier.fringe.lightHex))
            }
            Rule()
            LedgerRow("Salary cap") {
                Text(Format.money(app.league?.salaryCap ?? 0)).foregroundStyle(Broadcast.ink)
            }

            if let league = app.league, let team = league.userTeam {
                let spent = CapEngine.capSpent(for: team, deadMoney: league.deadMoney[team.id] ?? 0)
                let dead = league.deadMoney[team.id] ?? 0
                Rule()
                LedgerRow("Committed to the roster") {
                    Text(Format.money(spent - dead)).foregroundStyle(Broadcast.ink)
                }
                Rule()
                LedgerRow("Dead money") {
                    Text(Format.money(dead))
                        .foregroundStyle(dead > 0 ? Color(hex: RatingTier.fringe.lightHex) : Broadcast.muted)
                }
                Rule()

                // Say the number, then say what it means.
                Text(capSentence(space: app.capSpace, dead: dead))
                    .font(.bodyFont)
                    .foregroundStyle(app.capSpace < 0 ? Broadcast.ink : Broadcast.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(capSentence(space: app.capSpace, dead: dead))
            }
        }
        .card()
    }

    /// The consequence, in the coach's terms. Over the cap is a deadline, not a red number.
    private func capSentence(space: Int, dead: Int) -> String {
        if space < 0 {
            return "You are \(Format.money(-space)) over. That has to be cleared before the season "
                + "opens — release someone, restructure, or the league does it for you."
        }
        if dead > 0 {
            return "\(Format.money(dead)) of that is dead money: players you are still paying who "
                + "play somewhere else. \(Format.money(space)) is yours to spend."
        }
        return "\(Format.money(space)) to spend, and nothing owed to anyone who has left."
    }

    private var ownerCard: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            Text("Ownership")
                .font(.titleFont)
                .foregroundStyle(Broadcast.ink)

            if let league = app.league, let team = league.userTeam {
                LedgerRow("Patience") {
                    Text(patienceWord(team.ownerPatience)).foregroundStyle(Broadcast.ink)
                }
                Rule()
                LedgerRow("Job security") {
                    Text("\(league.coach.jobSecurity)%").foregroundStyle(Broadcast.ink)
                }
                Rule()
                Text(securitySentence(league.coach.jobSecurity))
                    .font(.bodyFont)
                    .foregroundStyle(Broadcast.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
    }

    /// Patience was drawn as repeated bullet glyphs, which say nothing to a screen reader and
    /// nothing to anyone who has not counted them.
    private func patienceWord(_ value: Int) -> String {
        switch value {
        case ...1: "Thin"
        case 2: "Short"
        case 3: "Even"
        case 4: "Long"
        default: "Deep"
        }
    }

    /// The thresholds that actually govern the career, said out loud rather than left as a bar.
    private func securitySentence(_ value: Int) -> String {
        switch value {
        case ..<25:
            "The owner is listening to other names. Below 12 and the decision is made for you."
        case ..<55:
            "You are being watched. A run of wins settles this; another bad month does not."
        default:
            "Nobody is asking about your job. Keep it there and the extension writes itself."
        }
    }

    private func row(_ title: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: Layout.medium) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 24)
            Text(title).font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, Layout.small)
        .contentShape(Rectangle())
    }
}

/// Everyone under contract, sorted by what they cost.
struct ContractsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if let team = app.userTeam {
                let sorted = team.roster
                    .filter { $0.contract != nil }
                    .sorted { ($0.contract?.currentCapHit ?? 0) > ($1.contract?.currentCapHit ?? 0) }
                ForEach(sorted) { player in
                    NavigationLink { PlayerCardView(player: player) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name).font(.subheadline)
                                Text("\(player.position.abbreviation) · \(player.age)y · \(player.contract?.yearsRemaining ?? 0)yr left")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Format.money(player.contract?.currentCapHit ?? 0))
                                    .font(.subheadline.monospacedDigit())
                                if (player.contract?.isExpiring ?? false) {
                                    Chip("EXPIRING", color: .orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Contracts")
    }
}

/// The open market, with a simple offer sheet.
struct FreeAgencyView: View {
    @Environment(AppState.self) private var app
    @State private var positionFilter: Position?
    @State private var offering: Player?

    var body: some View {
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

            ForEach(filtered) { player in
                Button { offering = player } label: {
                    HStack {
                        Text("\(player.overall)")
                            .font(.subheadline.monospacedDigit().weight(.bold))
                            .ratingStyle(player.overall)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name).font(.subheadline)
                            Text("\(player.position.abbreviation) · \(player.age)y · potential \(player.potential.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Format.money(askingPrice(player)))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    // Without this the gap between the name and the price is not tappable.
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Free Agents")
        .sheet(item: $offering) { player in
            OfferSheet(player: player, asking: askingPrice(player))
        }
        .appearanceAware()
    }

    private var filtered: [Player] {
        let all = (app.league?.freeAgents ?? []).sorted { $0.overall > $1.overall }
        guard let positionFilter else { return all }
        return all.filter { $0.position == positionFilter }
    }

    private func askingPrice(_ player: Player) -> Int {
        guard let league = app.league, let team = league.userTeam else { return 0 }
        return ContractPricer.askingSalary(
            for: player, teamReputation: team.reputation, salaryCap: league.salaryCap
        )
    }
}

struct OfferSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let player: Player
    let asking: Int

    @State private var years = 3
    @State private var salaryMillions: Double = 0
    @State private var toPracticeSquad = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Offer") {
                    Stepper("Years: \(years)", value: $years, in: 1...LeagueRules.maxContractYears)
                    VStack(alignment: .leading) {
                        Text("Salary: \(Format.money(Int(salaryMillions * 1_000_000))) per year")
                        Slider(
                            value: $salaryMillions,
                            in: 0.9...max(1.0, Double(asking) / 1_000_000 * 2.2)
                        )
                    }
                    SummaryRow(label: "He is asking", value: Format.money(asking))
                    SummaryRow(label: "Total value", value: Format.money(Int(salaryMillions * 1_000_000) * years))
                    Toggle("Sign to practice squad", isOn: $toPracticeSquad)
                    if toPracticeSquad {
                        Text("Squad money — \(Format.money(contract.currentCapHit)) a year, "
                             + "whatever the slider says. He develops without taking a roster "
                             + "spot, and any club can sign him away.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Interest") {
                    ProgressView(value: interest, total: 1)
                        .tint(interest >= 0.45 ? .green : .orange)
                    Text(interest >= 0.45
                         ? "He would sign this."
                         : "Not enough — he expects more money or a bigger role.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message {
                    Section { Text(message).foregroundStyle(.red) }
                }

                Section {
                    Button(toPracticeSquad ? "Sign to Practice Squad" : "Sign Player") { submit() }
                        .disabled(interest < 0.45)
                }
            }
            .navigationTitle(player.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear { salaryMillions = Double(asking) / 1_000_000 }
        }
    }

    /// What he would actually be paid. A practice-squad deal is squad money whatever the slider
    /// says, so the interest below is measured against the real terms and a good player refuses.
    private var contract: Contract {
        toPracticeSquad
            ? ContractPricer.minimumContract(age: player.age)
            : Contract.flat(years: years, salary: Int(salaryMillions * 1_000_000))
    }

    private var interest: Double {
        guard let league = app.league, let team = league.userTeam else { return 0 }
        return FreeAgencyEngine.interest(
            player: player,
            offer: .init(teamID: team.id, contract: contract),
            team: team,
            league: league
        )
    }

    private func submit() {
        if app.sign(playerID: player.id, contract: contract, practiceSquad: toPracticeSquad) {
            dismiss()
        } else {
            message = refusalReason
        }
    }

    /// The sign call only reports success, so work out which door was shut and say so.
    private var refusalReason: String {
        guard let league = app.league, let team = league.userTeam else {
            return "That signing could not be completed."
        }
        if toPracticeSquad, team.practiceSquad.count >= LeagueRules.practiceSquadSize {
            return "The practice squad is full."
        }
        if !toPracticeSquad, team.activeRoster.count >= LeagueRules.activeRosterSize {
            return "The active roster is full. Release a player or send one down first."
        }
        if !CapEngine.canAfford(contract, team: team, in: league) {
            let over = contract.capHit(inYear: 0) - CapEngine.capSpace(for: team, in: league)
            return "That contract is \(Format.money(over)) over the cap."
        }
        return "That signing could not be completed."
    }
}

/// Propose a swap and see what the other front office says.
struct TradeCenterView: View {
    @Environment(AppState.self) private var app

    @State private var partnerID: UUID?
    @State private var sending: Set<UUID> = []
    @State private var receiving: Set<UUID> = []
    @State private var verdict: String?

    var body: some View {
        List {
            Section("Trade Partner") {
                // Switching partner used to leave both sides' selections in place, so a package
                // could be assembled from players who were never on the table.
                Picker("Team", selection: $partnerID) {
                    Text("Choose a team").tag(UUID?.none)
                    ForEach(otherTeams) { team in
                        Text(team.fullName).tag(UUID?.some(team.id))
                    }
                }
            }

            if let team = app.userTeam {
                Section("You Send") {
                    ForEach(team.activeRoster.sorted { $0.overall > $1.overall }.prefix(30)) { player in
                        selectionRow(player, isSelected: sending.contains(player.id)) {
                            toggle(player.id, in: &sending)
                        }
                    }
                }
            }

            if let partner {
                Section("You Receive") {
                    ForEach(partner.activeRoster.sorted { $0.overall > $1.overall }.prefix(30)) { player in
                        selectionRow(player, isSelected: receiving.contains(player.id)) {
                            toggle(player.id, in: &receiving)
                        }
                    }
                }
            }

            Section {
                Button("Propose Trade") { propose() }
                    .disabled(partnerID == nil || (sending.isEmpty && receiving.isEmpty))
                if let verdict {
                    Text(verdict)
                        .font(.bodyFont)
                        .foregroundStyle(Broadcast.ink)
                }
            }
        }
        // Switching partner used to leave both sides' selections in place, so a package could be
        // assembled from players who were never on the table.
        .onChange(of: partnerID) { _, _ in
            sending.removeAll()
            receiving.removeAll()
            verdict = nil
        }
        .navigationTitle("Trade Center")
    }

    private var otherTeams: [Team] {
        (app.league?.teams ?? []).filter { $0.id != app.league?.userTeamID }
    }

    private var partner: Team? {
        guard let partnerID else { return nil }
        return app.league?.team(id: partnerID)
    }

    private func selectionRow(_ player: Player, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text("\(player.overall)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .ratingStyle(player.overall)
                Text(player.name).font(.subheadline)
                Spacer()
                Text(player.position.abbreviation).font(.caption).foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ id: UUID, in set: inout Set<UUID>) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private func propose() {
        guard let league = app.league, let partnerID else { return }
        let proposal = TradeProposal(
            fromTeamID: league.userTeamID,
            toTeamID: partnerID,
            sending: TradePackage(playerIDs: Array(sending)),
            receiving: TradePackage(playerIDs: Array(receiving))
        )
        let result = TradeEngine.evaluate(proposal, league: league, picks: app.draftPicks)
        switch result {
        case .accepted:
            var picks = app.draftPicks
            app.mutate { league in
                TradeEngine.execute(proposal, league: &league, picks: &picks)
            }
            app.draftPicks = picks
            verdict = "Accepted — the deal is done."
            sending = []
            receiving = []
        case .rejected(let reason):
            verdict = reason
        }
    }
}

/// Prospects with their scouting fog, and the points to clear it.
struct DraftBoardView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if app.draftClass.isEmpty {
                EmptyStateView(
                    icon: "person.badge.plus",
                    title: "No draft class yet",
                    message: "Prospects appear once the season reaches the draft."
                )
            } else {
                Section {
                    HStack {
                        Text("Scouting points")
                        Spacer()
                        Text("\(app.scoutingPoints)").foregroundStyle(.secondary)
                    }
                }
                ForEach(app.draftClass.sorted { $0.midpoint > $1.midpoint }) { prospect in
                    VStack(alignment: .leading, spacing: Layout.tight) {
                        HStack {
                            Text(prospect.scoutedRange)
                                .font(.subheadline.monospacedDigit().weight(.bold))
                                .ratingStyle(prospect.midpoint)
                                .frame(width: 62, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(prospect.name).font(.subheadline)
                                Text("\(prospect.position.abbreviation) · projected round \(prospect.projectedRound)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if prospect.potentialRevealed {
                                Chip(prospect.player.potential.rawValue, color: .purple, filled: true)
                            }
                        }
                        HStack(spacing: Layout.tight) {
                            ForEach([ScoutingEngine.Action.narrow, .revealPotential, .fullReport], id: \.displayName) { action in
                                Button {
                                    scout(prospect, action)
                                } label: {
                                    Chip("\(action.displayName) · \(action.cost)", color: .blue)
                                }
                                .buttonStyle(.plain)
                                .disabled(app.scoutingPoints < action.cost)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Draft Board")
    }

    private func scout(_ prospect: DraftProspect, _ action: ScoutingEngine.Action) {
        guard let coach = app.league?.coach else { return }
        var prospects = app.draftClass
        var points = app.scoutingPoints
        ScoutingEngine.scout(
            prospectID: prospect.id,
            action: action,
            in: &prospects,
            pointsRemaining: &points,
            coach: coach
        )
        app.draftClass = prospects
        app.scoutingPoints = points
    }
}
