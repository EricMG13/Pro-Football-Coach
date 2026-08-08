import Foundation

/// Retirement, awards, staff churn and the offseason pipeline that ties them together.
public enum OffseasonEngine {

    // MARK: - Retirements

    /// Ages players out of the league. Older, declining and injury-worn players go first;
    /// quarterbacks and specialists last longest.
    @discardableResult
    public static func processRetirements(_ league: inout League) -> [Player] {
        var retired: [Player] = []

        for teamIndex in league.teams.indices {
            var keeping: [Player] = []
            for player in league.teams[teamIndex].roster {
                if shouldRetire(player, rng: &league.rng) {
                    retired.append(player)
                    let team = league.teams[teamIndex]
                    league.news.append(
                        NewsEngine.retirement(
                            player: player, team: team, league: league, rng: &league.rng
                        )
                    )
                } else {
                    keeping.append(player)
                }
            }
            league.teams[teamIndex].roster = keeping
            league.teams[teamIndex].autoSortDepthChart()
        }

        league.freeAgents.removeAll { player in
            if shouldRetire(player, rng: &league.rng) {
                retired.append(player)
                return true
            }
            return false
        }

        return retired
    }

    private static func shouldRetire(_ player: Player, rng: inout SeededRandom) -> Bool {
        let peak = LeagueRules.peakAgeWindow(player.position)
        guard player.age > peak.upperBound else { return false }

        let yearsPast = Double(player.age - peak.upperBound)
        var chance = yearsPast * 0.10
        // A player who can still play keeps playing.
        chance -= Double(player.overall - 70) * 0.012
        if player.position.isSpecialist { chance *= 0.5 }
        if player.age >= 40 { chance = 1.0 }
        if player.contract == nil { chance += 0.15 }

        return rng.chance(min(1, max(0, chance)))
    }

    // MARK: - Awards

    /// Votes on the season's individual awards from production and team success.
    public static func selectAwards(_ league: League, rng: inout SeededRandom) -> [SeasonAward] {
        var awards: [SeasonAward] = []

        func stats(for playerID: UUID) -> StatLine { league.seasonStats(for: playerID) }

        /// Rough offensive value: yards and touchdowns, with passing discounted per yard.
        func offensiveScore(_ player: Player) -> Double {
            let line = stats(for: player.id)
            let teamRecord = league.teams.first { $0.player(id: player.id) != nil }
                .map { league.record(for: $0.id).winPercentage } ?? 0.5
            let production = Double(line.passingYards) * 0.35
                + Double(line.rushingYards) * 0.9
                + Double(line.receivingYards) * 0.9
                + Double(line.totalTouchdowns) * 45
                - Double(line.interceptionsThrown) * 30
            return production * (0.75 + teamRecord * 0.5)
        }

        func defensiveScore(_ player: Player) -> Double {
            let line = stats(for: player.id)
            let teamRecord = league.teams.first { $0.player(id: player.id) != nil }
                .map { league.record(for: $0.id).winPercentage } ?? 0.5
            let production = Double(line.tackles) * 3
                + Double(line.sacks) * 26
                + Double(line.interceptions) * 45
                + Double(line.passesDefended) * 9
                + Double(line.forcedFumbles) * 20
            return production * (0.75 + teamRecord * 0.5)
        }

        let allPlayers = league.teams.flatMap { team in team.roster.map { ($0, team) } }

        func award(_ kind: AwardKind, from pool: [(Player, Team)], score: (Player) -> Double) {
            guard let best = pool.max(by: { score($0.0) < score($1.0) }), score(best.0) > 0 else { return }
            awards.append(
                SeasonAward(
                    kind: kind,
                    year: league.year,
                    playerID: best.0.id,
                    playerName: best.0.name,
                    teamID: best.1.id
                )
            )
        }

        let offensivePlayers = allPlayers.filter { $0.0.position.isOffense }
        let defensivePlayers = allPlayers.filter { $0.0.position.isDefense }

        award(.mostValuablePlayer, from: allPlayers) { player in
            player.position.isOffense ? offensiveScore(player) : defensiveScore(player) * 0.85
        }
        award(.offensivePlayerOfTheYear, from: offensivePlayers, score: offensiveScore)
        award(.defensivePlayerOfTheYear, from: defensivePlayers, score: defensiveScore)
        award(.offensiveRookieOfTheYear, from: offensivePlayers.filter { $0.0.isRookie }, score: offensiveScore)
        award(.defensiveRookieOfTheYear, from: defensivePlayers.filter { $0.0.isRookie }, score: defensiveScore)

        // Coach of the year goes to the team that most outperformed its roster.
        if let overachiever = league.teams.max(by: { lhs, rhs in
            let lhsGap = league.record(for: lhs.id).winPercentage - (lhs.overallRating - 58) / 34
            let rhsGap = league.record(for: rhs.id).winPercentage - (rhs.overallRating - 58) / 34
            return lhsGap < rhsGap
        }) {
            awards.append(
                SeasonAward(
                    kind: .coachOfTheYear,
                    year: league.year,
                    playerID: nil,
                    playerName: "\(overachiever.fullName) head coach",
                    teamID: overachiever.id
                )
            )
        }

        return awards
    }

    // MARK: - Staff

    /// Coordinators get poached, retire, or stay. Vacancies are filled from a generated market.
    public static func runCoachingCarousel(_ league: inout League) {
        for teamIndex in league.teams.indices {
            let record = league.record(for: league.teams[teamIndex].id)
            var staff = league.teams[teamIndex].staff

            for staffIndex in staff.indices {
                staff[staffIndex].contractYears -= 1
                // Success builds a head-coaching case.
                let successBump = Int((record.winPercentage - 0.5) * 20)
                staff[staffIndex].headCoachCandidacy = max(
                    0, staff[staffIndex].headCoachCandidacy + successBump
                )
            }

            // Poaching and expiry both create vacancies.
            staff.removeAll { member in
                member.contractYears <= 0
                    || member.age >= 68
                    || (member.headCoachCandidacy > 40 && league.rng.chance(0.25))
            }

            for role in StaffRole.allCases where !staff.contains(where: { $0.role == role }) {
                staff.append(
                    makeStaffCandidate(
                        role: role,
                        team: league.teams[teamIndex],
                        rng: &league.rng
                    )
                )
            }
            league.teams[teamIndex].staff = staff
        }
    }

    /// Generates a coordinator on the market, scaled to how attractive the job is.
    public static func makeStaffCandidate(
        role: StaffRole,
        team: Team,
        rng: inout SeededRandom
    ) -> StaffMember {
        let (first, last) = NameBank.fullName(&rng)
        // Good jobs attract good coordinators.
        let floor = 42 + team.reputation / 3
        let ceiling = min(95, floor + 30)
        let matches = rng.chance(0.65)
        return StaffMember(
            id: rng.uuid(),
            firstName: first,
            lastName: last,
            role: role,
            age: rng.int(in: 33...62),
            rating: rng.int(in: floor...ceiling),
            offensiveScheme: role == .offensiveCoordinator
                ? (matches ? team.offensiveScheme : rng.pick(OffensiveScheme.allCases))
                : nil,
            defensiveScheme: role == .defensiveCoordinator
                ? (matches ? team.defensiveScheme : rng.pick(DefensiveScheme.allCases))
                : nil,
            trait: rng.chance(0.3) ? rng.pick(StaffTrait.allCases) : nil,
            salary: rng.int(in: 1_000_000...7_000_000),
            contractYears: rng.int(in: 2...4)
        )
    }

    // MARK: - Roster upkeep

    /// Trims every AI roster to the legal limit, keeping the best players and respecting
    /// positional minimums.
    public static func runCutdown(_ league: inout League) {
        for teamIndex in league.teams.indices {
            var team = league.teams[teamIndex]

            // Fill any position that is short before cutting anyone.
            for position in Position.allCases {
                var count = team.roster.filter { $0.position == position && !$0.isOnPracticeSquad }.count
                while count < position.minimumRosterCount {
                    let filler = PlayerFactory.make(
                        position: position,
                        age: league.rng.int(in: 22...28),
                        targetOverall: league.rng.int(in: 52...64),
                        year: league.year,
                        rng: &league.rng
                    )
                    var signed = filler
                    signed.contract = ContractPricer.minimumContract(age: filler.age)
                    team.roster.append(signed)
                    count += 1
                }
            }

            // Rank everyone, then keep the best while never dropping below a positional floor.
            let ranked = team.roster.sorted { $0.overall > $1.overall }
            var keep: [Player] = []
            var practiceSquad: [Player] = []
            var countByPosition: [Position: Int] = [:]

            for player in ranked {
                let current = countByPosition[player.position] ?? 0
                if keep.count < LeagueRules.activeRosterSize {
                    keep.append(player)
                    countByPosition[player.position] = current + 1
                } else if practiceSquad.count < LeagueRules.practiceSquadSize {
                    practiceSquad.append(player)
                }
            }

            // Repair any position left short by pure rating order.
            for position in Position.allCases {
                var have = keep.filter { $0.position == position }.count
                while have < position.minimumRosterCount {
                    guard let promoted = practiceSquad.first(where: { $0.position == position })
                        ?? team.roster.first(where: { player in
                            player.position == position && !keep.contains { $0.id == player.id }
                        })
                    else { break }
                    practiceSquad.removeAll { $0.id == promoted.id }
                    // Drop the least valuable player at an over-stocked position.
                    if let victim = keep
                        .filter({ candidate in
                            candidate.position != position
                                && keep.filter { $0.position == candidate.position }.count
                                    > candidate.position.minimumRosterCount
                        })
                        .min(by: { $0.overall < $1.overall }) {
                        keep.removeAll { $0.id == victim.id }
                        practiceSquad.append(victim)
                    }
                    keep.append(promoted)
                    have += 1
                }
            }

            var roster: [Player] = keep.map {
                var player = $0
                player.isOnPracticeSquad = false
                if player.contract == nil {
                    player.contract = ContractPricer.minimumContract(age: player.age)
                }
                return player
            }
            roster += practiceSquad.map {
                var player = $0
                player.isOnPracticeSquad = true
                if player.contract == nil {
                    player.contract = ContractPricer.minimumContract(age: player.age)
                }
                return player
            }

            team.roster = roster
            team.autoSortDepthChart()
            league.teams[teamIndex] = team
        }
    }

    /// Alternates shedding salary and filling holes until both are satisfied.
    ///
    /// The two pull against each other — cutting for cap room empties roster spots, and filling
    /// them costs money — so a single pass of either leaves teams illegal. Replacements come in
    /// at the league minimum, which is always cheaper than whoever was cut, so this converges.
    public static func settleRostersAndCap(_ league: inout League, passes: Int = 3) {
        for _ in 0..<passes {
            for team in league.teams {
                CapEngine.enforceCapCompliance(teamID: team.id, in: &league)
            }
            fillRosters(&league)
            let illegal = league.teams.contains { CapEngine.capSpace(for: $0, in: league) < 0 }
            if !illegal { return }
        }
    }

    /// Brings every roster back up to the full complement, signing the best available free
    /// agents first and generating fringe players only when the market has run dry.
    ///
    /// Without this, retirements and expiring contracts bleed a few players from every roster
    /// each year and a decade later the league is fielding forty-man teams.
    public static func fillRosters(_ league: inout League) {
        for teamIndex in league.teams.indices {
            while league.teams[teamIndex].activeRoster.count < LeagueRules.activeRosterSize {
                let team = league.teams[teamIndex]
                // Prefer whichever position the team is thinnest at.
                let neediest = Position.allCases.max { lhs, rhs in
                    FreeAgencyEngine.positionalNeed(for: lhs, on: team)
                        < FreeAgencyEngine.positionalNeed(for: rhs, on: team)
                } ?? .wr

                let candidates = league.freeAgents
                    .filter { $0.position == neediest }
                    .sorted { $0.overall > $1.overall }

                if let best = candidates.first,
                   CapEngine.sign(
                       playerID: best.id,
                       to: team.id,
                       contract: ContractPricer.minimumContract(age: best.age),
                       in: &league
                   ) {
                    continue
                }

                // Market is empty at that position: bring in a fringe professional.
                var filler = PlayerFactory.make(
                    position: neediest,
                    age: league.rng.int(in: 22...29),
                    targetOverall: league.rng.int(in: 50...63),
                    year: league.year,
                    rng: &league.rng
                )
                filler.contract = ContractPricer.minimumContract(age: filler.age)
                league.teams[teamIndex].roster.append(filler)
            }

            while league.teams[teamIndex].practiceSquad.count < LeagueRules.practiceSquadSize {
                var prospect = PlayerFactory.make(
                    position: league.rng.pick(Position.allCases.filter { !$0.isSpecialist }),
                    age: league.rng.int(in: 21...24),
                    targetOverall: league.rng.int(in: 48...60),
                    year: league.year,
                    rng: &league.rng
                )
                prospect.isOnPracticeSquad = true
                prospect.contract = ContractPricer.minimumContract(age: prospect.age)
                league.teams[teamIndex].roster.append(prospect)
            }

            league.teams[teamIndex].autoSortDepthChart()
        }
    }

    /// Every team re-signs the expiring players it wants to keep, before the market opens.
    public static func runReSigning(_ league: inout League) {
        for teamIndex in league.teams.indices {
            guard league.teams[teamIndex].id != league.userTeamID else { continue }
            let team = league.teams[teamIndex]

            for player in team.roster where player.contract?.isExpired ?? true {
                let need = FreeAgencyEngine.positionalNeed(for: player.position, on: team)
                let worthKeeping = player.overall >= 68 || need > 0.5
                guard worthKeeping else { continue }

                var rng = league.rng
                let contract = ContractPricer.marketContract(
                    for: player, salaryCap: league.salaryCap, rng: &rng
                )
                league.rng = rng
                guard CapEngine.canAfford(contract, team: league.teams[teamIndex], in: league) else { continue }
                if let index = league.teams[teamIndex].roster.firstIndex(where: { $0.id == player.id }) {
                    league.teams[teamIndex].roster[index].contract = contract
                }
            }
        }
    }

    // MARK: - Pipeline

    /// Runs one offseason stage and moves the league to the next.
    @discardableResult
    public static func advanceStage(
        _ league: inout League,
        prospects: inout [DraftProspect],
        picks: inout [DraftPick]
    ) -> OffseasonStage? {
        guard case .offseason(let rawStage) = league.phase,
              let stage = OffseasonStage(rawValue: rawStage) else { return nil }

        switch stage {
        case .seasonReview:
            let awards = selectAwards(league, rng: &league.rng)
            CoachEngine.updateJobSecurity(&league)
            archiveSeason(&league, awards: awards)

        case .coachingCarousel:
            runCoachingCarousel(&league)

        case .retirements:
            let retired = processRetirements(&league)
            // Career totals are still readable at this point, so enshrinement happens here.
            let inducted = HallOfFame.induct(retiring: retired, league: league)
            league.hallOfFame.append(contentsOf: inducted)
            for member in inducted {
                league.news.append(
                    NewsItem(
                        id: league.rng.uuid(),
                        year: league.year,
                        week: 0,
                        category: .award,
                        headline: "\(member.name) is elected to the Hall of Fame",
                        body: member.careerSummary
                    )
                )
            }

        case .reSigning:
            CapEngine.rolloverContracts(in: &league)
            runReSigning(&league)

        case .freeAgency:
            for wave in 0..<FreeAgencyEngine.waves {
                FreeAgencyEngine.runWave(&league, wave: wave)
            }
            FreeAgencyEngine.fillRosterHoles(&league)

        case .draft:
            prospects = DraftClassFactory.makeClass(year: league.year + 1, rng: &league.rng)
            picks = TradeEngine.makePicks(for: league)
            DraftEngine.runDraft(&league, prospects: &prospects, picks: picks)
            DraftEngine.signUndrafted(&league, prospects: &prospects)

        case .trainingCamp:
            ProgressionEngine.runTrainingCamp(&league)

        case .rosterCutdown:
            // Order matters: shedding salary releases players, so the cap has to be settled
            // before rosters are filled back up, or teams start the season short-handed.
            settleRostersAndCap(&league)
            runCutdown(&league)
            settleRostersAndCap(&league)
            FreeAgencyEngine.replenishStreetFreeAgents(&league)
            // Last thing before the new year, so retirements and cuts have all landed and the
            // set of players still in the league is final. Order matters: the market closes
            // first, so the players it sends home are pruned from the archive too.
            closeTheMarket(&league)
            pruneDepartedPlayers(from: &league)
            startNextSeason(&league)
            return stage
        }

        league.phase = .offseason(stage: rawStage + 1)
        return stage
    }

    /// Files the finished season into history so records, the Hall of Fame and the previous
    /// seasons screen have something to read.
    private static func archiveSeason(_ league: inout League, awards: [SeasonAward]) {
        var playerStats: [UUID: StatLine] = [:]
        for record in league.results {
            for (playerID, line) in record.playerStats {
                playerStats[playerID, default: StatLine()].add(line)
            }
        }
        let champion = SeasonEngine.champion(of: league)
        let final = league.results.first { $0.kind == .championship }

        league.history.append(
            SeasonSummary(
                year: league.year,
                championTeamID: champion?.id,
                runnerUpTeamID: final?.loserID,
                standings: league.standings,
                playerStats: playerStats,
                awards: awards,
                userRecord: league.standings[league.userTeamID]
            )
        )
    }

    /// Sends home the free agents nobody is going to sign, and trims the news feed.
    ///
    /// Both of these grow without limit otherwise: every cut and every expiring contract adds a
    /// free agent forever, and every signing adds a story. After ten seasons that is nine
    /// thousand unsigned players and eight thousand headlines, which is most of the save file
    /// and a scan that gets slower every year. Keeping the best of the pool is also truer to
    /// the sport — a 30-year-old who went unsigned for three straight seasons has retired,
    /// whether or not the game says so.
    private static func closeTheMarket(_ league: inout League) {
        let stillPlaying = league.freeAgents
            .filter { $0.age < LeagueRules.freeAgentRetirementAge }
            .sorted { $0.overall > $1.overall }
        league.freeAgents = Array(stillPlaying.prefix(LeagueRules.freeAgentPoolLimit))

        if league.news.count > LeagueRules.newsFeedLimit {
            league.news = Array(league.news.suffix(LeagueRules.newsFeedLimit))
        }
    }

    /// Drops archived stat lines for players who have left the league entirely.
    ///
    /// A season's archive holds a line for every player who took a snap, so ten years of it is
    /// most of the save file. Once a player is retired he is on nobody's roster and in no free
    /// agent pool, and the only screens that still name him — the record book and the Hall of
    /// Fame — keep their own copy of what he did. His archived lines are dead weight, and the
    /// save has to stay small enough to write on every week advance.
    private static func pruneDepartedPlayers(from league: inout League) {
        var living = Set<UUID>()
        for team in league.teams {
            for player in team.roster { living.insert(player.id) }
        }
        for player in league.freeAgents { living.insert(player.id) }

        league.history = league.history.map { season in
            let kept = season.playerStats.filter { living.contains($0.key) }
            guard kept.count != season.playerStats.count else { return season }
            return SeasonSummary(
                year: season.year,
                championTeamID: season.championTeamID,
                runnerUpTeamID: season.runnerUpTeamID,
                standings: season.standings,
                playerStats: kept,
                awards: season.awards,
                userRecord: season.userRecord
            )
        }
    }

    /// Rolls the calendar over into the next league year.
    private static func startNextSeason(_ league: inout League) {
        league.year += 1
        league.coach.age += 1
        league.coach.contractYearsElapsed += 1
        CapEngine.advanceSalaryCap(in: &league)
        // The finished season's per-player totals were folded into `history` during the season
        // review, so the game records themselves can go — that is what keeps saves small.
        league.results = []
        league.phase = .preseason
    }

    /// Runs the entire offseason unattended — used by soak tests and by simming ahead.
    public static func runFullOffseason(_ league: inout League) {
        var prospects: [DraftProspect] = []
        var picks: [DraftPick] = []
        var guardCounter = 0
        while league.phase.isOffseason && guardCounter < OffseasonStage.allCases.count + 2 {
            advanceStage(&league, prospects: &prospects, picks: &picks)
            guardCounter += 1
        }
    }
}
