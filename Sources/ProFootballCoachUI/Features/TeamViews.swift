import SwiftUI
import FootballSimCore

/// Team overview: identity, ratings, and the way into the roster.
struct TeamView: View {
    @Environment(AppState.self) private var app
    @Environment(\.teamTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                if let team = app.userTeam, let league = app.league {
                    header(team, league: league)
                    ratings(team)

                    VStack(spacing: 0) {
                        NavigationLink { DepthChartView() } label: {
                            navRow("Depth Chart & Roster", "person.3.sequence.fill", .blue)
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { InjuryReportView() } label: {
                            navRow(
                                team.injuredPlayers.isEmpty
                                    ? "Injury Report — everyone is healthy"
                                    : "Injury Report — \(team.injuredPlayers.count) out",
                                "cross.case.fill",
                                .red
                            )
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { StatsView() } label: {
                            navRow("League Statistics", "chart.bar.fill", .green)
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink { StaffView() } label: {
                            navRow("Coaching Staff", "person.2.badge.gearshape.fill", .purple)
                        }
                    }
                    .card()
                }
            }
            .padding(Layout.medium)
        }
        .background(Broadcast.page)
        .navigationTitle("Team")
    }

    private func header(_ team: Team, league: League) -> some View {
        VStack(spacing: Layout.small) {
            TeamBadge(team: team, size: 68)
            Text(team.fullName)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text("\(team.conference.displayName) · \(team.division.displayName)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            HStack(spacing: Layout.small) {
                Chip(league.record(for: team.id).description, color: .white, filled: false)
                Chip("Reputation \(team.reputation)", color: .white)
                Chip(team.stadiumName, color: .white)
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.large)
        .background(theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    private func ratings(_ team: Team) -> some View {
        VStack(spacing: Layout.small) {
            ratingBar("Offense", team.offenseRating)
            ratingBar("Defense", team.defenseRating)
            ratingBar("Special Teams", team.specialTeamsRating)
            Divider()
            HStack {
                Text("Schemes").foregroundStyle(.secondary)
                Spacer()
                Chip(team.offensiveScheme.displayName, color: .orange)
                Chip(team.defensiveScheme.displayName, color: .teal)
            }
            .font(.subheadline)
        }
        .card()
    }

    private func ratingBar(_ label: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(Format.rating(value))
                    .font(.subheadline.weight(.semibold))
                    .ratingStyle(value)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(RatingPalette.color(for: value))
                        .frame(width: proxy.size.width * min(1, max(0, (value - 40) / 59)))
                }
            }
            .frame(height: 6)
        }
    }

    private func navRow(_ title: String, _ icon: String, _ tint: Color) -> some View {
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

/// Roster by position, in depth order, reorderable.
struct DepthChartView: View {
    @Environment(AppState.self) private var app
    @State private var showingPracticeSquad = false
    @State private var refusal: String?

    var body: some View {
        List {
            if let team = app.userTeam {
                Section {
                    HStack {
                        Text("Active roster")
                        Spacer()
                        Text("\(team.activeRoster.count)/\(LeagueRules.activeRosterSize)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Practice squad")
                        Spacer()
                        Text("\(team.practiceSquad.count)/\(LeagueRules.practiceSquadSize)")
                            .foregroundStyle(.secondary)
                    }
                    Toggle("Show practice squad", isOn: $showingPracticeSquad)
                    Button("Auto-Sort by Rating") { app.autoSortDepthChart() }
                    Text(
                        showingPracticeSquad
                            ? "Swipe a player right to call him up."
                            : "Swipe a player right to send him to the practice squad."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                // Who the engine will actually field, which is not the chart order: depthOrder
                // puts the healthy first, so an injured man at the top of the chart does not play.
                let startingIDs = Set(
                    Position.displayOrder.flatMap { team.starters(at: $0) }.map(\.id)
                )

                ForEach(Position.displayOrder, id: \.self) { position in
                    let players = showingPracticeSquad
                        ? team.roster.filter { $0.position == position && $0.isOnPracticeSquad }
                        : team.depthOrder(for: position, healthyOnly: false)
                    if !players.isEmpty {
                        Section {
                            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                                NavigationLink {
                                    PlayerCardView(player: player)
                                } label: {
                                    PlayerRow(
                                        player: player,
                                        depthIndex: showingPracticeSquad ? nil : index,
                                        starterCount: position.starterCount,
                                        startsOnSunday: startingIDs.contains(player.id)
                                    )
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if player.isOnPracticeSquad {
                                        Button {
                                            refusal = app.elevate(playerID: player.id)
                                        } label: {
                                            Label("Call Up", systemImage: "arrow.up.circle.fill")
                                        }
                                        .tint(.green)
                                    } else {
                                        Button {
                                            refusal = app.demote(playerID: player.id)
                                        } label: {
                                            Label("Send Down", systemImage: "arrow.down.circle")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }
                            .onMove { source, destination in
                                guard !showingPracticeSquad else { return }
                                app.moveDepthChart(position: position, from: source, to: destination)
                            }
                        } header: {
                            HStack {
                                Text("\(position.displayName)")
                                Spacer()
                                Text("\(players.count)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Depth Chart")
        .alert(
            "Can't make that move",
            isPresented: Binding(get: { refusal != nil }, set: { if !$0 { refusal = nil } })
        ) {
            Button("OK", role: .cancel) { refusal = nil }
        } message: {
            Text(refusal ?? "")
        }
        // EditButton is iOS-only; the package also builds for macOS so the whole UI stays
        // compile-checked without Xcode.
        #if os(iOS)
        .toolbar { EditButton() }
        #endif
    }
}

struct PlayerRow: View {
    let player: Player
    var depthIndex: Int?
    var starterCount: Int = 1
    /// Whether the engine will actually field him, rather than where he sits on the chart.
    var startsOnSunday: Bool = false

    /// The role chip used to read straight off the chart index, so an injured QB1 showed a red
    /// cross and a green STARTER at the same time while the sim started QB2. It reports the
    /// engine's own choice now, and says so when a man is on the chart but unavailable.
    private var roleChip: (String, Color)? {
        guard depthIndex != nil else { return nil }
        if !player.isHealthy {
            return startsOnSunday ? nil : ("Out", Color(hex: RatingTier.fringe.lightHex))
        }
        if startsOnSunday { return ("Starter", Color(hex: RatingTier.starter.lightHex)) }
        if let depthIndex, depthIndex < starterCount * 2 {
            return ("Backup", Color(hex: RatingTier.rotational.lightHex))
        }
        return nil
    }

    var body: some View {
        HStack(spacing: Layout.small) {
            Text("\(player.overall)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .ratingStyle(player.overall)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Layout.tight) {
                    Text(player.name).font(.subheadline)
                    if !player.isHealthy {
                        Image(systemName: "cross.case.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                HStack(spacing: Layout.tight) {
                    Text("\(player.position.abbreviation) · \(player.age)y · \(player.yearsPro)yr pro")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let roleChip {
                Stamp(roleChip.0, color: roleChip.1)
            }
            if let contract = player.contract {
                Text(Format.money(contract.currentCapHit))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// One player, everything about him.
struct PlayerCardView: View {
    @Environment(AppState.self) private var app
    let player: Player
    @State private var confirmingCut = false

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.medium) {
                identity
                basics
                if let contract = player.contract { contractCard(contract) }
                statsCard
                attributes
                if !player.traits.isEmpty { traitsCard }
                if isOnUserTeam { actions }
            }
            .padding(Layout.medium)
        }
        .background(Broadcast.page)
        .navigationTitle(player.name)
        .alert("Release \(player.name)?", isPresented: $confirmingCut) {
            Button("Release", role: .destructive) { app.cut(playerID: player.id) }
            Button("Keep", role: .cancel) {}
        } message: {
            Text(cutMessage)
        }
    }

    private var isOnUserTeam: Bool {
        app.userTeam?.player(id: player.id) != nil
    }

    private var cutMessage: String {
        guard let contract = player.contract else { return "He is not under contract." }
        let dead = contract.deadMoneyIfCutNow()
        let saving = contract.capSavingsIfCutNow()
        return dead > 0
            ? "This leaves \(Format.money(dead)) of dead money and \(saving >= 0 ? "frees" : "costs") \(Format.money(abs(saving))) of cap space."
            : "This frees \(Format.money(saving)) of cap space."
    }

    /// The dossier head: the name in the record's own voice, the figure that matters, and one
    /// sentence of provenance built from what the engine already knows about him.
    ///
    /// The overall used to be a hard-coded 44pt, which was the one number on the screen that
    /// refused to scale with Dynamic Type — on a page that exists to show it.
    private var identity: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(player.name)
                    .font(.displayFont)
                    .foregroundStyle(Broadcast.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Layout.small)
                Text("\(player.overall)")
                    .font(.displayFont)
                    .ratingStyle(player.overall)
            }

            HStack(spacing: Layout.tight) {
                Stamp(player.position.abbreviation)
                Stamp("#\(player.jersey)")
                Stamp("Potential \(player.potential.rawValue)")
            }

            Rule()

            Text(dossier)
                .font(.bodyFont)
                .foregroundStyle(Broadcast.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(player.name), \(player.position.displayName), number \(player.jersey). "
                + "Overall \(player.overall), \(RatingTier(rating: player.overall).label). "
                + "Potential \(player.potential.rawValue). \(dossier)"
        )
    }

    /// One line of scouting, assembled from facts the engine already holds. No invention.
    private var dossier: String {
        let tenure: String
        switch player.yearsPro {
        case 0: tenure = "A rookie"
        case 1: tenure = "Second-year \(player.position.displayName.lowercased())"
        default: tenure = "\(ordinalYear(player.yearsPro + 1))-year \(player.position.displayName.lowercased())"
        }

        let origin: String
        if let draft = player.draftOrigin {
            origin = draft.isUndrafted
                ? "signed as an undrafted free agent out of \(player.college)"
                : "taken in round \(draft.round) of the \(String(draft.year)) draft out of \(player.college)"
        } else {
            origin = "out of \(player.college)"
        }

        return "\(tenure), \(origin). Age \(player.age)."
    }

    private func ordinalYear(_ value: Int) -> String {
        switch value {
        case 3: "Third"
        case 4: "Fourth"
        case 5: "Fifth"
        case 6: "Sixth"
        case 7: "Seventh"
        case 8: "Eighth"
        case 9: "Ninth"
        case 10: "Tenth"
        default: "\(value)th"
        }
    }

    private var potentialColor: Color {
        switch player.potential {
        case .aPlus, .a: .purple
        case .bPlus, .b: .blue
        case .cPlus, .c: .green
        case .d: .orange
        case .f: .red
        }
    }

    private var basics: some View {
        VStack(spacing: Layout.tight) {
            SummaryRow(label: "Age", value: "\(player.age)")
            SummaryRow(label: "Years pro", value: "\(player.yearsPro)")
            SummaryRow(label: "Height", value: Format.height(player.heightInches))
            SummaryRow(label: "Weight", value: "\(player.weightPounds) lbs")
            SummaryRow(label: "College", value: player.college)
            SummaryRow(label: "Drafted", value: player.draftOrigin?.label ?? "Undrafted")
            SummaryRow(label: "Morale", value: "\(player.morale)")
            if !player.isHealthy {
                SummaryRow(label: "Injury", value: "\(player.injuryWeeksRemaining) week(s) out")
            }
        }
        .card()
    }

    private func contractCard(_ contract: Contract) -> some View {
        VStack(spacing: Layout.tight) {
            SectionHeader("Contract")
            SummaryRow(label: "Years left", value: "\(contract.yearsRemaining) of \(contract.years)")
            SummaryRow(label: "Cap hit", value: Format.money(contract.currentCapHit))
            SummaryRow(label: "Average per year", value: Format.money(contract.averagePerYear))
            SummaryRow(label: "Signing bonus", value: Format.money(contract.signingBonus))
            SummaryRow(label: "Guaranteed years", value: "\(contract.guaranteedYears)")
            SummaryRow(label: "Dead money if cut", value: Format.money(contract.deadMoneyIfCutNow()))
        }
        .card()
    }

    private var statsCard: some View {
        VStack(spacing: Layout.tight) {
            SectionHeader("This Season")
            if let league = app.league {
                let line = league.seasonStats(for: player.id)
                if line.isEmpty {
                    Text("No statistics yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(statRows(line), id: \.0) { row in
                        SummaryRow(label: row.0, value: row.1)
                    }
                }
            }
        }
        .card()
    }

    /// Only the lines that matter for this position, so a lineman's card isn't full of zeros.
    private func statRows(_ line: StatLine) -> [(String, String)] {
        var rows: [(String, String)] = [("Games", "\(line.gamesPlayed)")]
        switch player.position {
        case .qb:
            rows += [
                ("Passing yards", "\(line.passingYards)"),
                ("Touchdowns", "\(line.passingTouchdowns)"),
                ("Interceptions", "\(line.interceptionsThrown)"),
                ("Completion %", Format.percent(line.completionPercentage)),
                ("Passer rating", String(format: "%.1f", line.passerRating)),
            ]
        case .rb:
            rows += [
                ("Rushing yards", "\(line.rushingYards)"),
                ("Carries", "\(line.carries)"),
                ("Yards per carry", String(format: "%.1f", line.yardsPerCarry)),
                ("Rushing TDs", "\(line.rushingTouchdowns)"),
                ("Receptions", "\(line.receptions)"),
            ]
        case .wr, .te:
            rows += [
                ("Receptions", "\(line.receptions)"),
                ("Receiving yards", "\(line.receivingYards)"),
                ("Yards per catch", String(format: "%.1f", line.yardsPerReception)),
                ("Touchdowns", "\(line.receivingTouchdowns)"),
                ("Targets", "\(line.targets)"),
            ]
        case .dl, .lb, .cb, .s:
            rows += [
                ("Tackles", "\(line.tackles)"),
                ("Sacks", "\(line.sacks)"),
                ("Interceptions", "\(line.interceptions)"),
                ("Passes defended", "\(line.passesDefended)"),
                ("Forced fumbles", "\(line.forcedFumbles)"),
            ]
        case .k:
            rows += [
                ("Field goals", "\(line.fieldGoalsMade)/\(line.fieldGoalsAttempted)"),
                ("Field goal %", Format.percent(line.fieldGoalPercentage)),
                ("Extra points", "\(line.extraPointsMade)/\(line.extraPointsAttempted)"),
                ("Longest", "\(line.longestFieldGoal)"),
            ]
        case .p:
            rows += [
                ("Punts", "\(line.punts)"),
                ("Punt yards", "\(line.puntYards)"),
                ("Average", String(format: "%.1f", line.averagePunt)),
            ]
        case .ol:
            break
        }
        return rows
    }

    private var attributes: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Attributes")
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: Layout.small) {
                ForEach(player.position.attributes, id: \.self) { attribute in
                    let value = player.ratings[attribute]
                    VStack(spacing: 2) {
                        Text("\(value)")
                            .font(.headline.monospacedDigit())
                            .ratingStyle(value)
                        Text(attribute.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.small)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.chipRadius)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
            }
        }
        .card()
    }

    private var traitsCard: some View {
        VStack(alignment: .leading, spacing: Layout.small) {
            SectionHeader("Traits")
            ForEach(player.traits, id: \.self) { trait in
                VStack(alignment: .leading, spacing: 2) {
                    Text(trait.displayName).font(.subheadline.weight(.medium))
                    Text(trait.detail).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }

    private var actions: some View {
        Button(role: .destructive) {
            confirmingCut = true
        } label: {
            Label("Release Player", systemImage: "person.badge.minus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

struct InjuryReportView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if let injured = app.userTeam?.injuredPlayers, !injured.isEmpty {
                ForEach(injured.sorted { $0.injuryWeeksRemaining > $1.injuryWeeksRemaining }) { player in
                    NavigationLink { PlayerCardView(player: player) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name).font(.subheadline)
                                Text(player.position.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Chip("\(player.injuryWeeksRemaining) wk", color: .red, filled: true)
                        }
                    }
                }
            } else {
                EmptyStateView(
                    icon: "checkmark.seal.fill",
                    title: "Everyone is healthy",
                    message: "No players are currently on the injury report."
                )
            }
        }
        .navigationTitle("Injury Report")
    }
}

struct StaffView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        List {
            if let team = app.userTeam {
                Section {
                    HStack {
                        Text("Staff budget")
                        Spacer()
                        Text(Format.money(team.staffBudget)).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Committed")
                        Spacer()
                        Text(Format.money(team.staff.reduce(0) { $0 + $1.salary }))
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(StaffRole.allCases, id: \.self) { role in
                    Section(role.displayName) {
                        if let member = team.staff(role) {
                            VStack(alignment: .leading, spacing: Layout.tight) {
                                HStack {
                                    Text(member.name).font(.headline)
                                    Spacer()
                                    Text("\(member.rating)")
                                        .font(.headline.monospacedDigit())
                                        .ratingStyle(member.rating)
                                }
                                HStack(spacing: Layout.tight) {
                                    if member.matchesScheme(
                                        offense: team.offensiveScheme,
                                        defense: team.defensiveScheme
                                    ) {
                                        Chip("Scheme fit", color: .green)
                                    } else {
                                        Chip("Scheme mismatch", color: .orange)
                                    }
                                    if let trait = member.trait { Chip(trait.displayName, color: .purple) }
                                    Chip("\(member.contractYears)yr", color: .secondary)
                                }
                                Text("\(Format.money(member.salary)) per year · age \(member.age)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        } else {
                            Text("Vacancy").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Coaching Staff")
    }
}
