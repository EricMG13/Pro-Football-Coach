import Foundation

/// A draft-eligible player, with the uncertainty that makes drafting a decision rather than
/// a lookup. The true ratings exist from the start; what the user sees depends on scouting.
public struct DraftProspect: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var player: Player
    /// True overall, hidden until the player is drafted.
    public var trueOverall: Int
    /// What scouting currently believes, as a range.
    public var scoutedLow: Int
    public var scoutedHigh: Int
    public var potentialRevealed: Bool
    public var fullyScouted: Bool
    /// Where the league consensus expects him to go.
    public var projectedRound: Int

    public init(
        id: UUID = UUID(),
        player: Player,
        trueOverall: Int,
        scoutedLow: Int,
        scoutedHigh: Int,
        potentialRevealed: Bool = false,
        fullyScouted: Bool = false,
        projectedRound: Int
    ) {
        self.id = id
        self.player = player
        self.trueOverall = trueOverall
        self.scoutedLow = scoutedLow
        self.scoutedHigh = scoutedHigh
        self.potentialRevealed = potentialRevealed
        self.fullyScouted = fullyScouted
        self.projectedRound = projectedRound
    }

    public var scoutedRange: String { fullyScouted ? "\(trueOverall)" : "\(scoutedLow)–\(scoutedHigh)" }
    public var midpoint: Int { fullyScouted ? trueOverall : (scoutedLow + scoutedHigh) / 2 }
    public var name: String { player.name }
    public var position: Position { player.position }
}

/// Builds each year's draft class, including the steals and busts that give a class its story.
public enum DraftClassFactory {

    public static func makeClass(year: Int, rng: inout SeededRandom) -> [DraftProspect] {
        var prospects: [DraftProspect] = []
        let total = LeagueRules.draftPickCount + LeagueRules.undraftedPoolSize

        for index in 0..<total {
            let projectedRound = min(
                LeagueRules.draftRounds + 1,
                index / LeagueRules.teamCount + 1
            )
            // Talent falls away smoothly through the rounds.
            let expected = 78.0 - Double(index) * 0.075
            var target = Int(rng.gaussian(mean: expected, sd: 3.4).rounded())

            // Steals and busts: roughly six and five per class, the reason scouting matters.
            var potentialOverride: PotentialGrade?
            if projectedRound >= 4, rng.chance(0.030) {
                target += rng.int(in: 5...9)
                potentialOverride = rng.chance(0.5) ? .aPlus : .a
            } else if projectedRound <= 2, rng.chance(0.075) {
                target -= rng.int(in: 6...11)
                potentialOverride = rng.chance(0.5) ? .f : .d
            }

            let position = weightedPosition(&rng)
            let player = PlayerFactory.make(
                position: position,
                age: rng.int(in: LeagueRules.rookieAgeRange),
                targetOverall: target.clampedToRating(),
                year: year,
                rng: &rng,
                potentialOverride: potentialOverride
            )

            // Initial fog: ±8, wider for players nobody has studied closely.
            let spread = rng.int(in: 6...9)
            prospects.append(
                DraftProspect(
                    id: rng.uuid(),
                    player: player,
                    trueOverall: player.overall,
                    scoutedLow: (player.overall - spread).clampedToRating(),
                    scoutedHigh: (player.overall + spread).clampedToRating(),
                    projectedRound: projectedRound
                )
            )
        }
        return prospects
    }

    /// Draft classes mirror roster needs — more linemen than kickers.
    private static func weightedPosition(_ rng: inout SeededRandom) -> Position {
        let weights: [(Position, Double)] = Position.allCases.map { ($0, Double($0.rosterTarget)) }
        let total = weights.reduce(0) { $0 + $1.1 }
        var roll = rng.double01() * total
        for (position, weight) in weights {
            roll -= weight
            if roll <= 0 { return position }
        }
        return .wr
    }
}

/// Spending scouting points to narrow the fog.
public enum ScoutingEngine {

    public enum Action: Sendable {
        case narrow, revealPotential, fullReport

        public var cost: Int {
            switch self {
            case .narrow: 10
            case .revealPotential: 25
            case .fullReport: 40
            }
        }

        public var displayName: String {
            switch self {
            case .narrow: "Narrow Range"
            case .revealPotential: "Reveal Potential"
            case .fullReport: "Full Report"
            }
        }
    }

    /// Applies a scouting action. Returns the points spent, or zero if it did nothing.
    @discardableResult
    public static func scout(
        prospectID: UUID,
        action: Action,
        in prospects: inout [DraftProspect],
        pointsRemaining: inout Int,
        coach: CoachProfile
    ) -> Int {
        guard pointsRemaining >= action.cost,
              let index = prospects.firstIndex(where: { $0.id == prospectID })
        else { return 0 }

        switch action {
        case .narrow:
            let step = 3 + CoachEngine.scoutingFogReduction(for: coach)
            guard !prospects[index].fullyScouted else { return 0 }
            prospects[index].scoutedLow = min(
                prospects[index].trueOverall,
                prospects[index].scoutedLow + step
            )
            prospects[index].scoutedHigh = max(
                prospects[index].trueOverall,
                prospects[index].scoutedHigh - step
            )
            if prospects[index].scoutedHigh - prospects[index].scoutedLow <= 1 {
                prospects[index].fullyScouted = true
            }
        case .revealPotential:
            guard !prospects[index].potentialRevealed else { return 0 }
            prospects[index].potentialRevealed = true
        case .fullReport:
            prospects[index].fullyScouted = true
            prospects[index].potentialRevealed = true
            prospects[index].scoutedLow = prospects[index].trueOverall
            prospects[index].scoutedHigh = prospects[index].trueOverall
        }

        pointsRemaining -= action.cost
        return action.cost
    }

    /// Prospects rated well above where the league expects them to go.
    public static func sleepers(in prospects: [DraftProspect]) -> [DraftProspect] {
        prospects.filter { prospect in
            prospect.projectedRound >= 4 && prospect.trueOverall >= 72
        }
    }
}

/// Runs the draft: order, AI selections, and the picks the user makes.
public enum DraftEngine {

    /// Draft order is the reverse of the standings, with playoff teams sorted by how far they
    /// went and the champion picking last.
    public static func draftOrder(for league: League) -> [UUID] {
        let champion = SeasonEngine.champion(of: league)?.id
        let playoffTeams = Set(
            Conference.allCases.flatMap { conference in
                StandingsCalculator.playoffSeeds(conference: conference, in: league).map(\.team.id)
            }
        )

        func playoffDepth(_ teamID: UUID) -> Int {
            league.results
                .filter { $0.kind.isPlayoff && $0.involves(teamID) }
                .count
        }

        return league.teams
            .sorted { lhs, rhs in
                if lhs.id == champion { return false }
                if rhs.id == champion { return true }

                let lhsInPlayoffs = playoffTeams.contains(lhs.id)
                let rhsInPlayoffs = playoffTeams.contains(rhs.id)
                if lhsInPlayoffs != rhsInPlayoffs { return !lhsInPlayoffs }

                if lhsInPlayoffs {
                    let lhsDepth = playoffDepth(lhs.id)
                    let rhsDepth = playoffDepth(rhs.id)
                    if lhsDepth != rhsDepth { return lhsDepth < rhsDepth }
                }

                let lhsRecord = league.record(for: lhs.id)
                let rhsRecord = league.record(for: rhs.id)
                if lhsRecord.winPercentage != rhsRecord.winPercentage {
                    return lhsRecord.winPercentage < rhsRecord.winPercentage
                }
                return lhs.abbreviation < rhs.abbreviation
            }
            .map(\.id)
    }

    /// The full pick sequence: seven rounds through the draft order, honouring traded picks.
    public static func pickSequence(league: League, picks: [DraftPick]) -> [(round: Int, teamID: UUID)] {
        let order = draftOrder(for: league)
        var sequence: [(Int, UUID)] = []
        for round in 1...LeagueRules.draftRounds {
            for originalTeamID in order {
                let owner = picks.first {
                    $0.year == league.year && $0.round == round && $0.originalTeamID == originalTeamID
                }?.ownerTeamID ?? originalTeamID
                sequence.append((round, owner))
            }
        }
        return sequence
    }

    /// The prospect an AI team takes: best available, weighted by need and philosophy.
    public static func aiSelection(
        for team: Team,
        from prospects: [DraftProspect],
        round: Int,
        rng: inout SeededRandom
    ) -> DraftProspect? {
        guard !prospects.isEmpty else { return nil }

        let scored = prospects.map { prospect -> (DraftProspect, Double) in
            var score = Double(prospect.trueOverall)
            score += FreeAgencyEngine.positionalNeed(for: prospect.position, on: team) * 9
            score += Double(prospect.player.potential.ceilingBonus)
                * (team.aiPersonality == .rebuilder ? 0.55 : 0.30)
            score += LeagueRules.positionSalaryPremium(prospect.position) * 2.2
            // Front offices are not perfect evaluators; a little noise creates draft steals.
            score += rng.gaussian(mean: 0, sd: 3.5)
            return (prospect, score)
        }

        return scored.max { $0.1 < $1.1 }?.0
    }

    /// Runs the whole draft, letting a callback make the user's picks.
    @discardableResult
    public static func runDraft(
        _ league: inout League,
        prospects: inout [DraftProspect],
        picks: [DraftPick],
        userPick: ((Int, [DraftProspect]) -> DraftProspect?)? = nil
    ) -> [NewsItem] {
        var news: [NewsItem] = []
        let sequence = pickSequence(league: league, picks: picks)
        var pickInRound = 0
        var currentRound = 1

        for (round, teamID) in sequence {
            if round != currentRound {
                currentRound = round
                pickInRound = 0
            }
            pickInRound += 1
            guard !prospects.isEmpty else { break }
            guard let teamIndex = league.teams.firstIndex(where: { $0.id == teamID }) else { continue }

            let chosen: DraftProspect?
            if teamID == league.userTeamID, let userPick {
                chosen = userPick(round, prospects)
            } else {
                chosen = aiSelection(
                    for: league.teams[teamIndex],
                    from: prospects,
                    round: round,
                    rng: &league.rng
                )
            }
            guard let prospect = chosen,
                  let prospectIndex = prospects.firstIndex(where: { $0.id == prospect.id })
            else { continue }
            prospects.remove(at: prospectIndex)

            var rookie = prospect.player
            rookie.draftOrigin = DraftOrigin(year: league.year, round: round, pickInRound: pickInRound)
            rookie.contract = ContractPricer.rookieContract(round: round, pickInRound: pickInRound)
            league.teams[teamIndex].roster.append(rookie)

            if round <= 2 || teamID == league.userTeamID {
                news.append(
                    NewsItem(
                        id: league.rng.uuid(),
                        year: league.year,
                        week: 0,
                        category: .draft,
                        headline: "\(league.teams[teamIndex].name) take \(rookie.position.abbreviation) \(rookie.name)",
                        body: "Round \(round), pick \(pickInRound).",
                        teamIDs: [teamID]
                    )
                )
            }
        }

        for index in league.teams.indices { league.teams[index].autoSortDepthChart() }
        league.news.append(contentsOf: news)
        return news
    }

    /// Signs leftovers to minimum deals so teams that need bodies get them.
    public static func signUndrafted(_ league: inout League, prospects: inout [DraftProspect]) {
        let ordered = prospects.sorted { $0.trueOverall > $1.trueOverall }
        for prospect in ordered {
            guard let teamIndex = league.teams.indices.min(by: { lhs, rhs in
                league.teams[lhs].roster.count < league.teams[rhs].roster.count
            }) else { break }
            guard league.teams[teamIndex].roster.count
                < LeagueRules.activeRosterSize + LeagueRules.practiceSquadSize else { break }

            var rookie = prospect.player
            rookie.draftOrigin = DraftOrigin(year: league.year, round: 0, pickInRound: 0)
            rookie.contract = ContractPricer.minimumContract(age: rookie.age)
            rookie.isOnPracticeSquad = true
            league.teams[teamIndex].roster.append(rookie)
        }
        prospects.removeAll()
    }
}
