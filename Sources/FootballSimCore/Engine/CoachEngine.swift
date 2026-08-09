import Foundation

/// One node on a coaching skill tree.
public struct SkillNode: Sendable, Equatable {
    public let branch: SkillBranch
    public let index: Int
    public let name: String
    public let detail: String
    public let cost: Int

    public init(branch: SkillBranch, index: Int, name: String, detail: String, cost: Int) {
        self.branch = branch
        self.index = index
        self.name = name
        self.detail = detail
        self.cost = cost
    }
}

/// The four coaching trees. Each is a straight chain: later nodes cost more and need the one
/// before them, so a career specialises rather than buying everything.
public enum SkillTrees {

    public static func nodes(for branch: SkillBranch) -> [SkillNode] {
        let definitions: [(String, String)]
        switch branch {
        case .scouting:
            definitions = [
                ("Sharper Eye I", "Narrows every prospect's rating range."),
                ("Sharper Eye II", "Narrows it further still."),
                ("Extra Scouts", "Adds 40 scouting points each season."),
                ("Combine Insider", "Reveals potential on first-round talent for free."),
                ("Sleeper Radar", "Flags prospects rated well above their draft slot."),
                ("Draft-Day Trader", "Rival teams accept pick swaps closer to even value."),
            ]
        case .development:
            definitions = [
                ("Position Coaches I", "Players gain 10% more in training camp."),
                ("Position Coaches II", "Make that 20%."),
                ("Veteran Mentors", "Players past their peak decline more slowly."),
                ("Youth Program", "Players under 25 develop faster."),
                ("Breakout Culture", "One extra player breaks out every camp."),
                ("Iron Regimen", "Cuts the injury rate across the roster."),
            ]
        case .offense:
            definitions = [
                ("Scheme Guru I", "Your offence rates one point higher."),
                ("Scheme Guru II", "Make that two points."),
                ("Red-Zone Package", "Better conversion rate inside the twenty."),
                ("Two-Minute Drill", "The hurry-up offence runs more efficiently."),
                ("Explosive Plays", "Big plays come more often."),
                ("Fourth-Down Analytics", "Sharper go-for-it recommendations."),
            ]
        case .defense:
            definitions = [
                ("Scheme Guru I", "Your defence rates one point higher."),
                ("Scheme Guru II", "Make that two points."),
                ("Third-Down Stop", "Better on third down."),
                ("Turnover Chain", "Takeaways come more often."),
                ("Blitz Architect", "Pressure packages get home more."),
                ("Bend Don't Break", "Fewer touchdowns allowed in the red zone."),
            ]
        }

        return definitions.enumerated().map { index, entry in
            SkillNode(
                branch: branch,
                index: index,
                name: entry.0,
                detail: entry.1,
                cost: index + 1
            )
        }
    }

    public static func node(branch: SkillBranch, index: Int) -> SkillNode? {
        let all = nodes(for: branch)
        guard index >= 0, index < all.count else { return nil }
        return all[index]
    }
}

/// The coaching career: experience, levels, skills, goals and job security.
public enum CoachEngine {

    // MARK: - Experience

    public enum ExperienceEvent: Sendable {
        case win, divisionWin, playoffWin, championship, goalCompleted(Int), draftSteal

        public var points: Int {
            switch self {
            case .win: 40
            case .divisionWin: 50
            case .playoffWin: 80
            case .championship: 200
            case .goalCompleted(let value): value
            case .draftSteal: 50
            }
        }
    }

    /// Pays the coach for a result. The event table existed from the start and nothing ever
    /// called it, so wins, division wins, playoff runs and titles were all worth nothing.
    public static func awardForResult(
        win: Bool,
        isDivisional: Bool,
        isPlayoff: Bool,
        in league: inout League
    ) {
        guard win else { return }
        let event: ExperienceEvent
        if isPlayoff {
            event = .playoffWin
        } else if isDivisional {
            event = .divisionWin
        } else {
            event = .win
        }
        award(event, to: &league.coach)
    }

    /// Awards experience and levels the coach up, handing out a skill point per level.
    public static func award(_ event: ExperienceEvent, to coach: inout CoachProfile) {
        coach.experience += event.points
        while coach.experience >= coach.experienceForNextLevel {
            coach.experience -= coach.experienceForNextLevel
            coach.level += 1
            coach.skillPoints += 1
        }
    }

    /// Spends a skill point, if the node is affordable and its prerequisite is unlocked.
    @discardableResult
    public static func unlock(branch: SkillBranch, index: Int, coach: inout CoachProfile) -> Bool {
        guard let node = SkillTrees.node(branch: branch, index: index) else { return false }
        guard !coach.hasUnlocked(branch: branch, node: index) else { return false }
        guard coach.skillPoints >= node.cost else { return false }
        // Chains unlock in order.
        if index > 0, !coach.hasUnlocked(branch: branch, node: index - 1) { return false }

        coach.skillPoints -= node.cost
        coach.unlockedNodes[branch, default: []].append(index)
        return true
    }

    /// The free first point that comes with the coach's background.
    public static func applyBackgroundBonus(to coach: inout CoachProfile) {
        unlock(branch: coach.background.branch, index: 0, coach: &coach)
    }

    // MARK: - Skill effects

    public static func developmentBonus(for coach: CoachProfile) -> Double {
        var bonus = 0.0
        if coach.hasUnlocked(branch: .development, node: 0) { bonus += 0.10 }
        if coach.hasUnlocked(branch: .development, node: 1) { bonus += 0.10 }
        return bonus
    }

    public static func offenseRatingBonus(for coach: CoachProfile) -> Double {
        var bonus = 0.0
        if coach.hasUnlocked(branch: .offense, node: 0) { bonus += 1 }
        if coach.hasUnlocked(branch: .offense, node: 1) { bonus += 1 }
        return bonus
    }

    public static func defenseRatingBonus(for coach: CoachProfile) -> Double {
        var bonus = 0.0
        if coach.hasUnlocked(branch: .defense, node: 0) { bonus += 1 }
        if coach.hasUnlocked(branch: .defense, node: 1) { bonus += 1 }
        return bonus
    }

    public static func scoutingPoints(for coach: CoachProfile) -> Int {
        LeagueRules.scoutingPointsPerSeason
            + (coach.hasUnlocked(branch: .scouting, node: 2) ? 40 : 0)
    }

    /// How much of a prospect's rating range scouting reveals.
    public static func scoutingFogReduction(for coach: CoachProfile) -> Int {
        var reduction = 0
        if coach.hasUnlocked(branch: .scouting, node: 0) { reduction += 2 }
        if coach.hasUnlocked(branch: .scouting, node: 1) { reduction += 2 }
        return reduction
    }

    public static func injuryRateMultiplier(for coach: CoachProfile) -> Double {
        coach.hasUnlocked(branch: .development, node: 5) ? 0.85 : 1.0
    }

    // MARK: - Goals

    /// An owner-set objective worth experience.
    public struct SeasonGoal: Codable, Sendable, Equatable, Identifiable {
        public let id: UUID
        public let description: String
        public let target: Int
        public var progress: Int
        public let experienceReward: Int
        public let isEndOfSeason: Bool
        public let kind: Kind
        /// Whether this goal's experience has already been handed over. Goals settle every week,
        /// so without this a goal that stays complete pays again every single settle.
        public var hasPaidOut: Bool

        public enum Kind: String, Codable, Sendable {
            case wins, playoffs, divisionTitle, topOffense, topDefense, capSpace, championship
        }

        public init(
            id: UUID = UUID(),
            description: String,
            target: Int,
            progress: Int = 0,
            experienceReward: Int,
            isEndOfSeason: Bool,
            kind: Kind,
            hasPaidOut: Bool = false
        ) {
            self.id = id
            self.description = description
            self.target = target
            self.progress = progress
            self.experienceReward = experienceReward
            self.isEndOfSeason = isEndOfSeason
            self.kind = kind
            self.hasPaidOut = hasPaidOut
        }

        private enum CodingKeys: String, CodingKey {
            case id, description, target, progress, experienceReward, isEndOfSeason, kind
            case hasPaidOut
        }

        /// Decoded field by field so franchises saved before the flag existed still load.
        ///
        /// A goal that arrives already complete from such a save is assumed paid: it was, on the
        /// week it completed, and possibly on every week since. Assuming otherwise would hand out
        /// the reward one more time on the next settle.
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            description = try container.decode(String.self, forKey: .description)
            target = try container.decode(Int.self, forKey: .target)
            progress = try container.decode(Int.self, forKey: .progress)
            experienceReward = try container.decode(Int.self, forKey: .experienceReward)
            isEndOfSeason = try container.decode(Bool.self, forKey: .isEndOfSeason)
            kind = try container.decode(Kind.self, forKey: .kind)
            hasPaidOut = try container.decodeIfPresent(Bool.self, forKey: .hasPaidOut)
                ?? (progress >= target)
        }

        public var isComplete: Bool { progress >= target }
        public var fraction: Double {
            target == 0 ? 0 : min(1, Double(progress) / Double(target))
        }
    }

    /// Builds the season's goals, scaled to how good the roster actually is — a rebuilding
    /// team is not asked to win the title.
    public static func makeSeasonGoals(for league: League, rng: inout SeededRandom) -> [SeasonGoal] {
        guard let team = league.userTeam else { return [] }
        let strength = team.overallRating
        let expectedWins = max(4, min(13, Int((strength - 58) / 2.2)))

        var goals: [SeasonGoal] = [
            SeasonGoal(
                id: rng.uuid(),
                description: "Win \(expectedWins)+ games",
                target: expectedWins,
                experienceReward: 100,
                isEndOfSeason: false,
                kind: .wins
            )
        ]

        if strength > 72 {
            goals.append(
                SeasonGoal(
                    id: rng.uuid(),
                    description: "Reach the playoffs",
                    target: 1,
                    experienceReward: 120,
                    isEndOfSeason: true,
                    kind: .playoffs
                )
            )
        }
        if strength > 80 {
            goals.append(
                SeasonGoal(
                    id: rng.uuid(),
                    description: "Win the division",
                    target: 1,
                    experienceReward: 150,
                    isEndOfSeason: true,
                    kind: .divisionTitle
                )
            )
        }
        goals.append(
            SeasonGoal(
                id: rng.uuid(),
                description: "Finish top 10 in total defence",
                target: 1,
                experienceReward: 80,
                isEndOfSeason: true,
                kind: .topDefense
            )
        )
        goals.append(
            SeasonGoal(
                id: rng.uuid(),
                description: "Carry $5M+ of cap space into the offseason",
                target: 1,
                experienceReward: 60,
                isEndOfSeason: true,
                kind: .capSpace
            )
        )
        return goals
    }

    /// Scores the season's goals and pays out the experience earned.
    @discardableResult
    public static func settleGoals(
        _ goals: inout [SeasonGoal],
        league: inout League
    ) -> [SeasonGoal] {
        guard let team = league.userTeam else { return [] }
        let record = league.record(for: team.id)
        var completed: [SeasonGoal] = []

        for index in goals.indices {
            switch goals[index].kind {
            case .wins:
                goals[index].progress = record.wins
            case .playoffs:
                let madeIt = StandingsCalculator
                    .playoffSeeds(conference: team.conference, in: league)
                    .contains { $0.team.id == team.id }
                goals[index].progress = madeIt ? 1 : 0
            case .divisionTitle:
                let winner = StandingsCalculator
                    .divisionStandings(conference: team.conference, division: team.division, in: league)
                    .first?.team.id
                goals[index].progress = winner == team.id ? 1 : 0
            case .topOffense, .topDefense:
                let ranked = league.teams.sorted {
                    goals[index].kind == .topOffense
                        ? $0.offenseRating > $1.offenseRating
                        : $0.defenseRating > $1.defenseRating
                }
                let rank = (ranked.firstIndex { $0.id == team.id } ?? 99) + 1
                goals[index].progress = rank <= 10 ? 1 : 0
            case .capSpace:
                goals[index].progress = CapEngine.capSpace(for: team, in: league) >= 5_000_000 ? 1 : 0
            case .championship:
                goals[index].progress = SeasonEngine.champion(of: league)?.id == team.id ? 1 : 0
            }

            // Only the settle that first completes a goal pays it.
            if goals[index].isComplete, !goals[index].hasPaidOut {
                goals[index].hasPaidOut = true
                award(.goalCompleted(goals[index].experienceReward), to: &league.coach)
                completed.append(goals[index])
            }
        }
        return completed
    }

    // MARK: - Job security

    /// Moves the needle on the hot seat based on results against expectations.
    public static func updateJobSecurity(_ league: inout League) {
        guard let team = league.userTeam else { return }
        let record = league.record(for: team.id)
        guard record.gamesPlayed > 0 else { return }

        let expected = max(0.30, min(0.70, (team.overallRating - 58) / 34))
        let actual = record.winPercentage
        // Patience scales how hard a bad year lands.
        let patience = Double(team.ownerPatience)
        var swing = (actual - expected) * 120 / max(1, patience * 0.6)

        if SeasonEngine.champion(of: league)?.id == team.id { swing += 45 }
        let madePlayoffs = StandingsCalculator
            .playoffSeeds(conference: team.conference, in: league)
            .contains { $0.team.id == team.id }
        if madePlayoffs { swing += 12 }

        league.coach.jobSecurity = min(100, max(0, league.coach.jobSecurity + Int(swing.rounded())))
        league.coach.careerWins += record.wins
        league.coach.careerLosses += record.losses
        league.coach.careerTies += record.ties
        if madePlayoffs { league.coach.playoffAppearances += 1 }
        if SeasonEngine.champion(of: league)?.id == team.id { league.coach.championships += 1 }
    }

    /// An offer of a head-coaching job.
    public struct JobOffer: Codable, Sendable, Identifiable, Equatable {
        public let id: UUID
        public let teamID: UUID
        public let teamName: String
        public let salary: Int
        public let years: Int

        public init(id: UUID = UUID(), teamID: UUID, teamName: String, salary: Int, years: Int) {
            self.id = id
            self.teamID = teamID
            self.teamName = teamName
            self.salary = salary
            self.years = years
        }
    }

    /// Takes a job, moving the coach and his career with him.
    ///
    /// Everything a franchise screen reads off the coach — his cap sheet, his depth chart, his
    /// goals — hangs off `userTeamID`, so this is the one place it moves.
    public static func accept(offer: JobOffer, in league: inout League) {
        league.userTeamID = offer.teamID
        league.coach.salary = offer.salary
        league.coach.contractYears = offer.years
        league.coach.contractYearsElapsed = 0
        league.coach.jobSecurity = 55
        league.coach.teamsCoached += 1
        league.jobOffers = []
        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: 0,
                category: .staff,
                headline: "\(league.coach.name) takes over at \(offer.teamName)",
                body: "A \(offer.years)-year deal worth "
                    + "\(offer.salary / 1_000_000) million a season.",
                teamIDs: [offer.teamID]
            )
        )
    }

    /// Runs the head coach's own year in the carousel: ages his deal, decides whether he keeps
    /// the job, and puts offers on the table when he does not.
    ///
    /// Returns true if he is between jobs afterwards.
    @discardableResult
    public static func settleHeadCoachJob(_ league: inout League) -> Bool {
        league.coach.contractYearsElapsed += 1
        let expired = league.coach.contractYearsRemaining <= 0
        let sacked = league.settings.coachFiringEnabled && league.coach.jobSecurity <= 12

        guard sacked || expired else { return false }

        // A coach who cannot be fired cannot be shown the door by the calendar either. Without
        // this, switching the setting off still evicted him the moment his deal ran out.
        let secureEnoughToStay = league.coach.jobSecurity >= 55
            || !league.settings.coachFiringEnabled

        // A secure coach whose deal ran out is simply re-signed where he is; nobody sacks a
        // winner over paperwork.
        if expired, !sacked, secureEnoughToStay {
            league.coach.contractYears = 3
            league.coach.contractYearsElapsed = 0
            league.news.append(
                NewsItem(
                    id: league.rng.uuid(),
                    year: league.year,
                    week: 0,
                    category: .staff,
                    headline: "\(league.coach.name) signs an extension",
                    body: "Three more years to finish the job."
                )
            )
            return false
        }

        let team = league.userTeam?.fullName ?? "his club"
        league.news.append(
            NewsItem(
                id: league.rng.uuid(),
                year: league.year,
                week: 0,
                category: .hotSeat,
                headline: sacked
                    ? "\(team) part company with \(league.coach.name)"
                    : "\(league.coach.name) leaves \(team) as his contract expires",
                body: sacked
                    ? "The owner has run out of patience."
                    : "Both sides are free to look elsewhere."
            )
        )
        var rng = league.rng
        league.jobOffers = jobOffers(for: league, rng: &rng)
        league.rng = rng
        return true
    }

    /// Jobs available to this coach.
    ///
    /// This list is never allowed to be empty: in the game this one learns from, a contract
    /// running out with no offers on the table left the save unplayable. If nothing else is
    /// open, the weakest team in the league takes a chance on him.
    public static func jobOffers(for league: League, rng: inout SeededRandom) -> [JobOffer] {
        let reputation = coachReputation(league.coach)
        var offers: [JobOffer] = []

        for team in league.teams where team.id != league.userTeamID {
            // Struggling teams look for a new voice; strong ones only chase a proven winner.
            let record = league.record(for: team.id)
            let openness = record.gamesPlayed > 0
                ? (1 - record.winPercentage) * 100
                : Double(100 - team.reputation)
            guard openness > 45 else { continue }
            guard Double(team.reputation) <= reputation + 25 else { continue }

            offers.append(
                JobOffer(
                    id: rng.uuid(),
                    teamID: team.id,
                    teamName: team.fullName,
                    salary: max(1_500_000, Int(reputation * 120_000)),
                    years: rng.int(in: 2...4)
                )
            )
        }

        if offers.isEmpty {
            // Guaranteed floor: somebody always needs a coach.
            if let desperate = league.teams
                .filter({ $0.id != league.userTeamID })
                .min(by: { $0.reputation < $1.reputation }) {
                offers.append(
                    JobOffer(
                        id: rng.uuid(),
                        teamID: desperate.id,
                        teamName: desperate.fullName,
                        salary: 1_500_000,
                        years: 2
                    )
                )
            }
        }

        return offers.sorted { $0.salary > $1.salary }
    }

    /// A rough standing in the profession, from results and titles.
    public static func coachReputation(_ coach: CoachProfile) -> Double {
        let games = coach.careerWins + coach.careerLosses + coach.careerTies
        let winRate = games == 0 ? 0.5 : Double(coach.careerWins) / Double(games)
        return min(
            99,
            30 + winRate * 45 + Double(coach.championships) * 12 + Double(coach.playoffAppearances) * 3
        )
    }
}
