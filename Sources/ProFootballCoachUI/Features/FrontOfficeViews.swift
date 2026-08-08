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
        .background(Color.pageBackground)
        .navigationTitle("Front Office")
    }

    private var capCard: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Salary Cap")
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Space").font(.caption).foregroundStyle(.secondary)
                    Text(Format.signedMoney(app.capSpace))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(app.capSpace >= 0 ? .green : .red)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cap").font(.caption).foregroundStyle(.secondary)
                    Text(Format.money(app.league?.salaryCap ?? 0)).font(.headline)
                }
            }

            if let league = app.league, let team = league.userTeam {
                let spent = CapEngine.capSpent(for: team, deadMoney: league.deadMoney[team.id] ?? 0)
                let dead = league.deadMoney[team.id] ?? 0
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let spentFraction = min(1, Double(spent) / Double(max(1, league.salaryCap)))
                    let deadFraction = min(1, Double(dead) / Double(max(1, league.salaryCap)))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15))
                        Capsule().fill(Color.accentColor).frame(width: width * spentFraction)
                        Capsule().fill(Color.red).frame(width: width * deadFraction)
                    }
                }
                .frame(height: 10)

                HStack {
                    Label(Format.money(spent - dead), systemImage: "person.fill")
                    Spacer()
                    Label("\(Format.money(dead)) dead", systemImage: "xmark.circle")
                        .foregroundStyle(dead > 0 ? .red : .secondary)
                }
                .font(.caption)
            }
        }
        .card()
    }

    private var ownerCard: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Ownership")
            if let league = app.league, let team = league.userTeam {
                SummaryRow(label: "Owner patience", value: String(repeating: "●", count: team.ownerPatience))
                SummaryRow(label: "Job security", value: "\(league.coach.jobSecurity)%")
                ProgressView(value: Double(league.coach.jobSecurity), total: 100)
                    .tint(securityColor(league.coach.jobSecurity))
            }
        }
        .card()
    }

    private func securityColor(_ value: Int) -> Color {
        switch value {
        case ..<25: .red
        case ..<55: .orange
        default: .green
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
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Free Agents")
        .sheet(item: $offering) { player in
            OfferSheet(player: player, asking: askingPrice(player))
        }
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
                    Button("Sign Player") { submit() }
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

    private var contract: Contract {
        Contract.flat(years: years, salary: Int(salaryMillions * 1_000_000))
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
        if app.sign(playerID: player.id, contract: contract) {
            dismiss()
        } else {
            message = "Not enough cap space or roster room for that contract."
        }
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
                        .font(.subheadline)
                        .foregroundStyle(verdict.hasPrefix("Accepted") ? .green : .orange)
                }
            }
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
