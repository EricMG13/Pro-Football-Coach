import FootballSimCore

public enum CoachWorldDataProvenance: String, Sendable, Equatable {
    case simulationSnapshot
    case sample
}

public struct CoachWorldAssetReference: Sendable, Equatable {
    public let stableID: String
    public let assetName: String

    public init(stableID: String, assetName: String) {
        self.stableID = stableID
        self.assetName = assetName
    }
}

public struct CoachWorldReference: Sendable, Equatable {
    public let stableID: String
    public let name: String
    public let badge: CoachWorldAssetReference?

    public init(stableID: String, name: String, badge: CoachWorldAssetReference? = nil) {
        self.stableID = stableID
        self.name = name
        self.badge = badge
    }
}

public struct CoachWorldTeamReference: Sendable, Equatable {
    public let stableID: String
    public let name: String
    public let abbreviation: String
    public let mark: CoachWorldAssetReference?
    public let secondaryMarkAsset: CoachWorldAssetReference?
    public let uniformAsset: CoachWorldAssetReference?
    public let primaryColorHex: String?
    public let secondaryColorHex: String?

    public init(
        stableID: String,
        name: String,
        abbreviation: String,
        mark: CoachWorldAssetReference? = nil,
        secondaryMarkAsset: CoachWorldAssetReference? = nil,
        uniformAsset: CoachWorldAssetReference? = nil,
        primaryColorHex: String? = nil,
        secondaryColorHex: String? = nil
    ) {
        self.stableID = stableID
        self.name = name
        self.abbreviation = abbreviation
        self.mark = mark
        self.secondaryMarkAsset = secondaryMarkAsset
        self.uniformAsset = uniformAsset
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
    }
}

public struct CoachWorldPersonReference: Sendable, Equatable {
    public let stableID: String
    public let name: String
    public let role: String
    public let photo: CoachWorldAssetReference?

    public init(
        stableID: String,
        name: String,
        role: String,
        photo: CoachWorldAssetReference? = nil
    ) {
        self.stableID = stableID
        self.name = name
        self.role = role
        self.photo = photo
    }
}

public struct CoachWorldVenueReference: Sendable, Equatable {
    public let stableID: String
    public let name: String
    public let image: CoachWorldAssetReference?

    public init(stableID: String, name: String, image: CoachWorldAssetReference? = nil) {
        self.stableID = stableID
        self.name = name
        self.image = image
    }
}

public struct CoachWorldIntentID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct CoachWorldActionChoice: Sendable, Equatable {
    public let intentID: CoachWorldIntentID
    public let title: String
    public let cost: String
    public let consequence: String
    public let isAvailable: Bool
    public let unavailableReason: String?

    public init(
        intentID: CoachWorldIntentID,
        title: String,
        cost: String,
        consequence: String,
        isAvailable: Bool = true,
        unavailableReason: String? = nil
    ) {
        self.intentID = intentID
        self.title = title
        self.cost = cost
        self.consequence = consequence
        self.isAvailable = isAvailable
        self.unavailableReason = isAvailable ? nil : unavailableReason
    }
}

public struct CoachingHQReadModel: Sendable, Equatable {
    public struct DayPlan: Sendable, Equatable {
        public let stableID: String
        public let dayLabel: String
        public let assignment: String
        public let isCurrent: Bool

        public init(stableID: String, dayLabel: String, assignment: String, isCurrent: Bool) {
            self.stableID = stableID
            self.dayLabel = dayLabel
            self.assignment = assignment
            self.isCurrent = isCurrent
        }
    }

    public struct WeekContext: Sendable, Equatable {
        public let seasonLabel: String
        public let weekLabel: String
        public let currentDay: String
        public let nextDeadline: String

        public init(
            seasonLabel: String,
            weekLabel: String,
            currentDay: String,
            nextDeadline: String
        ) {
            self.seasonLabel = seasonLabel
            self.weekLabel = weekLabel
            self.currentDay = currentDay
            self.nextDeadline = nextDeadline
        }
    }

    public struct Obligation: Sendable, Equatable {
        public let stableID: String
        public let title: String
        public let due: String
        public let consequence: String
        public let isMandatory: Bool

        public init(
            stableID: String,
            title: String,
            due: String,
            consequence: String,
            isMandatory: Bool
        ) {
            self.stableID = stableID
            self.title = title
            self.due = due
            self.consequence = consequence
            self.isMandatory = isMandatory
        }
    }

    public struct Decision: Sendable, Equatable {
        public enum ValidationError: Error, Equatable {
            case optionCount(Int)
        }

        public let stableID: String
        public let title: String
        public let deadline: String
        public let evidence: [String]
        public let choices: [CoachWorldActionChoice]

        public init(
            stableID: String,
            title: String,
            deadline: String,
            evidence: [String],
            choices: [CoachWorldActionChoice]
        ) throws {
            guard (2...3).contains(choices.count) else {
                throw ValidationError.optionCount(choices.count)
            }
            self.stableID = stableID
            self.title = title
            self.deadline = deadline
            self.evidence = evidence
            self.choices = choices
        }
    }

    public struct StaffRecommendation: Sendable, Equatable {
        public let staff: CoachWorldPersonReference
        public let verdict: String
        public let reason: String
        public let confidence: String

        public init(
            staff: CoachWorldPersonReference,
            verdict: String,
            reason: String,
            confidence: String
        ) {
            self.staff = staff
            self.verdict = verdict
            self.reason = reason
            self.confidence = confidence
        }
    }

    public struct Correspondence: Sendable, Equatable {
        public let stableID: String
        public let sender: CoachWorldPersonReference
        public let subject: String
        public let received: String
        public let isUnread: Bool

        public init(
            stableID: String,
            sender: CoachWorldPersonReference,
            subject: String,
            received: String,
            isUnread: Bool
        ) {
            self.stableID = stableID
            self.sender = sender
            self.subject = subject
            self.received = received
            self.isUnread = isUnread
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let coach: CoachWorldPersonReference
    public let recordLabel: String
    public let rankLabel: String?
    public let venue: CoachWorldVenueReference?
    public let week: WeekContext
    public let weekPlan: [DayPlan]
    public let unallocatedPracticeMinutes: Int
    public let opponent: CoachWorldTeamReference?
    public let obligations: [Obligation]
    public let decision: Decision?
    public let staffRecommendation: StaffRecommendation?
    public let correspondence: [Correspondence]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        coach: CoachWorldPersonReference,
        recordLabel: String,
        rankLabel: String?,
        venue: CoachWorldVenueReference?,
        week: WeekContext,
        weekPlan: [DayPlan],
        unallocatedPracticeMinutes: Int,
        opponent: CoachWorldTeamReference?,
        obligations: [Obligation],
        decision: Decision?,
        staffRecommendation: StaffRecommendation?,
        correspondence: [Correspondence]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.coach = coach
        self.recordLabel = recordLabel
        self.rankLabel = rankLabel
        self.venue = venue
        self.week = week
        self.weekPlan = weekPlan
        self.unallocatedPracticeMinutes = unallocatedPracticeMinutes
        self.opponent = opponent
        self.obligations = obligations
        self.decision = decision
        self.staffRecommendation = staffRecommendation
        self.correspondence = correspondence
    }
}

public struct GamePlanReadModel: Sendable, Equatable {
    public struct Option: Sendable, Equatable, Identifiable {
        public let id: String
        public let title: String
        public let plan: TacticalPlan
        public let consequence: String

        public init(id: String, title: String, plan: TacticalPlan, consequence: String) {
            self.id = id
            self.title = title
            self.plan = plan
            self.consequence = consequence
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let team: CoachWorldTeamReference
    public let opponent: CoachWorldTeamReference?
    public let weekLabel: String
    public let currentPlan: TacticalPlan?
    public let options: [Option]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        team: CoachWorldTeamReference,
        opponent: CoachWorldTeamReference?,
        weekLabel: String,
        currentPlan: TacticalPlan?,
        options: [Option]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.team = team
        self.opponent = opponent
        self.weekLabel = weekLabel
        self.currentPlan = currentPlan
        self.options = options
    }
}

public struct PracticePlanReadModel: Sendable, Equatable {
    public struct Option: Sendable, Equatable, Identifiable {
        public let id: String
        public let title: String
        public let plan: TacticalPracticePlan
        public let consequence: String

        public init(
            id: String,
            title: String,
            plan: TacticalPracticePlan,
            consequence: String
        ) {
            self.id = id
            self.title = title
            self.plan = plan
            self.consequence = consequence
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let team: CoachWorldTeamReference
    public let weekLabel: String
    public let currentPlan: TacticalPracticePlan?
    public let options: [Option]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        team: CoachWorldTeamReference,
        weekLabel: String,
        currentPlan: TacticalPracticePlan?,
        options: [Option]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.team = team
        self.weekLabel = weekLabel
        self.currentPlan = currentPlan
        self.options = options
    }
}

public struct DepthChartReadModel: Sendable, Equatable {
    public struct Slot: Sendable, Equatable, Identifiable {
        public let id: String
        public let playerID: String
        public let playerName: String
        public let availability: String
        public let isStarter: Bool
        public let isUnavailable: Bool
        public let isOverride: Bool

        public init(
            id: String,
            playerID: String,
            playerName: String,
            availability: String,
            isStarter: Bool,
            isUnavailable: Bool,
            isOverride: Bool
        ) {
            self.id = id
            self.playerID = playerID
            self.playerName = playerName
            self.availability = availability
            self.isStarter = isStarter
            self.isUnavailable = isUnavailable
            self.isOverride = isOverride
        }
    }

    public struct PositionGroup: Sendable, Equatable, Identifiable {
        public let id: String
        public let title: String
        public let slots: [Slot]

        public init(id: String, title: String, slots: [Slot]) {
            self.id = id
            self.title = title
            self.slots = slots
        }
    }

    public struct Option: Sendable, Equatable, Identifiable {
        public let id: String
        public let title: String
        public let plan: PersonnelPlan
        public let consequence: String

        public init(id: String, title: String, plan: PersonnelPlan, consequence: String) {
            self.id = id
            self.title = title
            self.plan = plan
            self.consequence = consequence
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let team: CoachWorldTeamReference
    public let weekLabel: String
    public let currentPlan: PersonnelPlan?
    public let positions: [PositionGroup]
    public let options: [Option]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        team: CoachWorldTeamReference,
        weekLabel: String,
        currentPlan: PersonnelPlan?,
        positions: [PositionGroup],
        options: [Option]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.team = team
        self.weekLabel = weekLabel
        self.currentPlan = currentPlan
        self.positions = positions
        self.options = options
    }
}

public struct CareerHubReadModel: Sendable, Equatable {
    public struct JobRow: Sendable, Equatable, Identifiable {
        public let id: String
        public let team: CoachWorldTeamReference
        public let tier: String
        public let started: String
        public let ended: String?
        public let reason: String?

        public init(
            id: String,
            team: CoachWorldTeamReference,
            tier: String,
            started: String,
            ended: String? = nil,
            reason: String? = nil
        ) {
            self.id = id
            self.team = team
            self.tier = tier
            self.started = started
            self.ended = ended
            self.reason = reason
        }
    }

    public struct OpportunityRow: Sendable, Equatable, Identifiable {
        public let id: String
        public let team: CoachWorldTeamReference
        public let tier: String
        public let offered: String
        public let expires: String
        public let prestige: Int
        public let rationale: String

        public init(
            id: String,
            team: CoachWorldTeamReference,
            tier: String,
            offered: String,
            expires: String,
            prestige: Int,
            rationale: String
        ) {
            self.id = id
            self.team = team
            self.tier = tier
            self.offered = offered
            self.expires = expires
            self.prestige = prestige
            self.rationale = rationale
        }
    }

    public struct SupportRow: Sendable, Equatable, Identifiable {
        public let id: String
        public let stakeholder: String
        public let value: Int

        public init(id: String, stakeholder: String, value: Int) {
            self.id = id
            self.stakeholder = stakeholder
            self.value = value
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let coach: CoachWorldPersonReference
    public let status: String
    public let currentJob: JobRow?
    public let history: [JobRow]
    public let opportunities: [OpportunityRow]
    public let support: [SupportRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        coach: CoachWorldPersonReference,
        status: String,
        currentJob: JobRow?,
        history: [JobRow],
        opportunities: [OpportunityRow],
        support: [SupportRow]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.coach = coach
        self.status = status
        self.currentJob = currentJob
        self.history = history
        self.opportunities = opportunities
        self.support = support
    }
}

public struct StandingsReadModel: Sendable, Equatable {
    public struct Row: Sendable, Equatable, Identifiable {
        public let id: String
        public let team: CoachWorldTeamReference
        public let wins: Int
        public let losses: Int
        public let ties: Int
        public let conferenceRecord: String
        public let pointsFor: Int
        public let pointsAgainst: Int
        public let isControlled: Bool

        public init(
            id: String,
            team: CoachWorldTeamReference,
            wins: Int,
            losses: Int,
            ties: Int,
            conferenceRecord: String,
            pointsFor: Int,
            pointsAgainst: Int,
            isControlled: Bool
        ) {
            self.id = id
            self.team = team
            self.wins = wins
            self.losses = losses
            self.ties = ties
            self.conferenceRecord = conferenceRecord
            self.pointsFor = pointsFor
            self.pointsAgainst = pointsAgainst
            self.isControlled = isControlled
        }

        public var record: String {
            ties == 0 ? "\(wins)-\(losses)" : "\(wins)-\(losses)-\(ties)"
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let seasonLabel: String
    public let weekLabel: String
    public let tier: String
    public let rows: [Row]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        seasonLabel: String,
        weekLabel: String,
        tier: String,
        rows: [Row]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.seasonLabel = seasonLabel
        self.weekLabel = weekLabel
        self.tier = tier
        self.rows = rows
    }
}

public struct ScheduleReadModel: Sendable, Equatable {
    public struct GameRow: Sendable, Equatable, Identifiable {
        public let id: String
        public let week: String
        public let stage: String
        public let home: CoachWorldTeamReference
        public let away: CoachWorldTeamReference
        public let score: String?
        public let isControlled: Bool

        public init(
            id: String,
            week: String,
            stage: String,
            home: CoachWorldTeamReference,
            away: CoachWorldTeamReference,
            score: String?,
            isControlled: Bool
        ) {
            self.id = id
            self.week = week
            self.stage = stage
            self.home = home
            self.away = away
            self.score = score
            self.isControlled = isControlled
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let seasonLabel: String
    public let tier: String
    public let games: [GameRow]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        seasonLabel: String,
        tier: String,
        games: [GameRow]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.seasonLabel = seasonLabel
        self.tier = tier
        self.games = games
    }
}

/// Authoritative profile for any college programme or professional team.
///
/// This is deliberately a compact projection: identities, standings, schedule and rivalry
/// references all retain the engine UUID so a profile opened from any surface describes the same
/// organisation rather than a copied map card.
public struct TeamProgrammeProfileReadModel: Sendable, Equatable {
    public struct Fixture: Sendable, Equatable, Identifiable {
        public let id: String
        public let week: String
        public let opponent: CoachWorldTeamReference
        public let isHome: Bool
        public let score: String?
        public let stage: String

        public init(
            id: String,
            week: String,
            opponent: CoachWorldTeamReference,
            isHome: Bool,
            score: String?,
            stage: String
        ) {
            self.id = id
            self.week = week
            self.opponent = opponent
            self.isHome = isHome
            self.score = score
            self.stage = stage
        }
    }

    public struct Rival: Sendable, Equatable, Identifiable {
        public let id: String
        public let team: CoachWorldTeamReference
        public let origin: String
        public let intensity: Int

        public init(id: String, team: CoachWorldTeamReference, origin: String, intensity: Int) {
            self.id = id
            self.team = team
            self.origin = origin
            self.intensity = intensity
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let cityName: String
    public let regionName: String
    public let seasonLabel: String
    public let tier: String
    public let conference: String
    public let division: String?
    public let venue: CoachWorldVenueReference
    public let prestige: Int
    public let record: String
    public let rank: String?
    public let rosterCount: Int
    public let staffCount: Int
    public let traditions: [String]
    public let fixtures: [Fixture]
    public let rivals: [Rival]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        cityName: String,
        regionName: String,
        seasonLabel: String,
        tier: String,
        conference: String,
        division: String?,
        venue: CoachWorldVenueReference,
        prestige: Int,
        record: String,
        rank: String?,
        rosterCount: Int,
        staffCount: Int,
        traditions: [String],
        fixtures: [Fixture],
        rivals: [Rival]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.cityName = cityName
        self.regionName = regionName
        self.seasonLabel = seasonLabel
        self.tier = tier
        self.conference = conference
        self.division = division
        self.venue = venue
        self.prestige = prestige
        self.record = record
        self.rank = rank
        self.rosterCount = rosterCount
        self.staffCount = staffCount
        self.traditions = Array(traditions.prefix(8))
        self.fixtures = Array(fixtures.prefix(12))
        self.rivals = Array(rivals.prefix(8))
    }
}

/// Bounded current-world organisation search. Results carry stable IDs so opening one routes to
/// the same Team/Programme Profile used by map, standings and schedule.
public struct WorldSearchReadModel: Sendable, Equatable {
    public struct Result: Sendable, Equatable, Identifiable {
        public let id: String
        public let team: CoachWorldTeamReference
        public let tier: String
        public let cityName: String
        public let regionName: String

        public init(
            id: String,
            team: CoachWorldTeamReference,
            tier: String,
            cityName: String,
            regionName: String
        ) {
            self.id = id
            self.team = team
            self.tier = tier
            self.cityName = cityName
            self.regionName = regionName
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let seasonLabel: String
    public let results: [Result]

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        seasonLabel: String,
        results: [Result]
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.seasonLabel = seasonLabel
        self.results = Array(results.prefix(256))
    }
}

public struct CompetitionOverviewReadModel: Sendable, Equatable {
    public struct RankingRow: Sendable, Equatable, Identifiable {
        public let id: String
        public let team: CoachWorldTeamReference
        public let rank: Int
        public let record: String
        public let isControlled: Bool

        public init(id: String, team: CoachWorldTeamReference, rank: Int, record: String,
                    isControlled: Bool) {
            self.id = id
            self.team = team
            self.rank = rank
            self.record = record
            self.isControlled = isControlled
        }
    }

    public struct BracketGame: Sendable, Equatable, Identifiable {
        public let id: String
        public let stage: String
        public let home: CoachWorldTeamReference
        public let away: CoachWorldTeamReference
        public let score: String?
        public let week: String

        public init(id: String, stage: String, home: CoachWorldTeamReference,
                    away: CoachWorldTeamReference, score: String?, week: String) {
            self.id = id
            self.stage = stage
            self.home = home
            self.away = away
            self.score = score
            self.week = week
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let seasonLabel: String
    public let tier: String
    public let rankings: [RankingRow]
    public let bracket: [BracketGame]

    public init(snapshotID: String, provenance: CoachWorldDataProvenance,
                world: CoachWorldReference, seasonLabel: String, tier: String,
                rankings: [RankingRow], bracket: [BracketGame]) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.seasonLabel = seasonLabel
        self.tier = tier
        self.rankings = Array(rankings.prefix(166))
        self.bracket = Array(bracket.prefix(64))
    }
}

public struct RecruitingBoardReadModel: Sendable, Equatable {
    public struct Capacity: Sendable, Equatable {
        public let scholarshipSlotsRemaining: Int
        /// `ProgrammeRecruitingState.contactPointsRemaining` — a real, weekly-reset engine
        /// resource that `contact` and `evaluate` spend against directly.
        public let weeklyHoursRemaining: Int
        /// Derived, not stored: the engine has one pooled points resource, not a separate visit
        /// counter, and `scheduleVisit` draws `CollegeRules.visitContactCost` from the same pool.
        /// This is how many visits the remaining points could still afford — a real computed fact,
        /// the same kind of derivation as `condition` from fatigue elsewhere in this provider.
        public let officialVisitsRemaining: Int

        public init(
            scholarshipSlotsRemaining: Int,
            weeklyHoursRemaining: Int,
            officialVisitsRemaining: Int
        ) {
            self.scholarshipSlotsRemaining = scholarshipSlotsRemaining
            self.weeklyHoursRemaining = weeklyHoursRemaining
            self.officialVisitsRemaining = officialVisitsRemaining
        }
    }

    public struct PositionNeed: Sendable, Equatable {
        public let stableID: String
        public let position: String
        public let target: Int
        public let committed: Int

        public init(stableID: String, position: String, target: Int, committed: Int) {
            self.stableID = stableID
            self.position = position
            self.target = target
            self.committed = committed
        }
    }

    public struct Evaluation: Sendable, Equatable {
        public let verdict: String
        public let schemeFit: String
        public let uncertainty: String
        public let citedOutliers: [String]

        public init(
            verdict: String,
            schemeFit: String,
            uncertainty: String,
            citedOutliers: [String]
        ) {
            self.verdict = verdict
            self.schemeFit = schemeFit
            self.uncertainty = uncertainty
            self.citedOutliers = citedOutliers
        }
    }

    public struct RelationshipEvent: Sendable, Equatable {
        public let stableID: String
        public let dateLabel: String
        public let summary: String
        public let effect: String

        public init(stableID: String, dateLabel: String, summary: String, effect: String) {
            self.stableID = stableID
            self.dateLabel = dateLabel
            self.summary = summary
            self.effect = effect
        }
    }

    public struct Prospect: Sendable, Equatable {
        public let stableID: String
        public let person: CoachWorldPersonReference
        public let boardRank: Int
        public let position: String
        public let hometown: String
        public let interest: String
        public let status: String
        public let evaluation: Evaluation
        public let relationshipHistory: [RelationshipEvent]
        public let choices: [CoachWorldActionChoice]

        public init(
            stableID: String,
            person: CoachWorldPersonReference,
            boardRank: Int,
            position: String,
            hometown: String,
            interest: String,
            status: String,
            evaluation: Evaluation,
            relationshipHistory: [RelationshipEvent],
            choices: [CoachWorldActionChoice]
        ) {
            self.stableID = stableID
            self.person = person
            self.boardRank = boardRank
            self.position = position
            self.hometown = hometown
            self.interest = interest
            self.status = status
            self.evaluation = evaluation
            self.relationshipHistory = relationshipHistory
            self.choices = choices
        }
    }

    public let snapshotID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let team: CoachWorldTeamReference
    public let capacity: Capacity
    public let positionNeeds: [PositionNeed]
    public let prospects: [Prospect]
    public let canContinue: Bool
    public let continueReason: String?

    public init(
        snapshotID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        team: CoachWorldTeamReference,
        capacity: Capacity,
        positionNeeds: [PositionNeed],
        prospects: [Prospect],
        canContinue: Bool = true,
        continueReason: String? = nil
    ) {
        self.snapshotID = snapshotID
        self.provenance = provenance
        self.world = world
        self.team = team
        self.capacity = capacity
        self.positionNeeds = positionNeeds
        self.prospects = prospects
        self.canContinue = canContinue
        self.continueReason = continueReason
    }
}

public enum MatchSide: String, Sendable, Equatable {
    case home
    case away
}

public enum MatchFieldDirection: String, Sendable, Equatable {
    case leftToRight
    case rightToLeft
}

public enum MatchDayControlID: String, CaseIterable, Sendable, Equatable {
    case speed
    case pause
    case keyMoments
    case takeOver
    case tactics
}

public struct MatchDayReadModel: Sendable, Equatable {
    public enum ValidationError: Error, Equatable {
        case invalidOutcomeID
        case invalidTeamIdentity
        case invalidScore
        case invalidSituation(String)
        case commentaryRequired
        case actorCount(Int)
        case duplicateActorID
        case invalidTeamDistribution
        case invalidFieldPosition(String)
        case invalidLine(String)
        case foregroundCount(Int)
        case unknownForegroundActor(String)
        case invalidControls
    }

    public struct TeamScore: Sendable, Equatable {
        public let team: CoachWorldTeamReference
        public let score: Int

        public init(team: CoachWorldTeamReference, score: Int) {
            self.team = team
            self.score = score
        }
    }

    public struct Situation: Sendable, Equatable {
        public let quarter: Int
        public let clockSecondsRemaining: Int
        public let down: Int
        public let yardsToGo: Int
        public let possession: MatchSide

        public init(
            quarter: Int,
            clockSecondsRemaining: Int,
            down: Int,
            yardsToGo: Int,
            possession: MatchSide
        ) {
            self.quarter = quarter
            self.clockSecondsRemaining = clockSecondsRemaining
            self.down = down
            self.yardsToGo = yardsToGo
            self.possession = possession
        }
    }

    public struct Actor: Sendable, Equatable {
        public let stableID: String
        public let side: MatchSide
        public let uniformNumber: String
        public let position: String
        public let xYardsFromLeftGoalLine: Double
        public let yFraction: Double

        public init(
            stableID: String,
            side: MatchSide,
            uniformNumber: String,
            position: String,
            xYardsFromLeftGoalLine: Double,
            yFraction: Double
        ) {
            self.stableID = stableID
            self.side = side
            self.uniformNumber = uniformNumber
            self.position = position
            self.xYardsFromLeftGoalLine = xYardsFromLeftGoalLine
            self.yFraction = yFraction
        }
    }

    public struct StaffInterruption: Sendable, Equatable {
        public enum Path: String, CaseIterable, Hashable, Sendable {
            case accept
            case dismiss
            case inspectEvidence
        }

        public enum ValidationError: Error, Equatable {
            case duplicatePath(Path)
            case missingPath(Path)
            case evidenceRequired
            case costRequired(Path)
            case consequenceRequired(Path)
            case duplicateIntentID
        }

        public struct Action: Sendable, Equatable {
            public let path: Path
            public let intentID: CoachWorldIntentID
            public let title: String
            public let cost: String
            public let consequence: String
            public let isEnabled: Bool

            public init(
                path: Path,
                intentID: CoachWorldIntentID,
                title: String,
                cost: String,
                consequence: String,
                isEnabled: Bool = true
            ) {
                self.path = path
                self.intentID = intentID
                self.title = title
                self.cost = cost
                self.consequence = consequence
                self.isEnabled = isEnabled
            }
        }

        public let stableID: String
        public let staff: CoachWorldPersonReference
        public let message: String
        public let evidence: [String]
        public let actions: [Action]

        public init(
            stableID: String,
            staff: CoachWorldPersonReference,
            message: String,
            evidence: [String],
            actions: [Action]
        ) throws {
            guard evidence.contains(where: { item in
                item.contains(where: { !$0.isWhitespace })
            }) else {
                throw ValidationError.evidenceRequired
            }
            var seen: Set<Path> = []
            for action in actions {
                guard action.cost.contains(where: { !$0.isWhitespace }) else {
                    throw ValidationError.costRequired(action.path)
                }
                guard action.consequence.contains(where: { !$0.isWhitespace }) else {
                    throw ValidationError.consequenceRequired(action.path)
                }
                guard seen.insert(action.path).inserted else {
                    throw ValidationError.duplicatePath(action.path)
                }
            }
            if let missing = Path.allCases.first(where: { !seen.contains($0) }) {
                throw ValidationError.missingPath(missing)
            }
            guard Set(actions.map(\.intentID)).count == actions.count else {
                throw ValidationError.duplicateIntentID
            }
            self.stableID = stableID
            self.staff = staff
            self.message = message
            self.evidence = evidence
            self.actions = actions
        }
    }

    public struct ControlState: Sendable, Equatable {
        public let id: MatchDayControlID
        public let value: String?
        public let isEnabled: Bool
        public let isSelected: Bool
        public let intentID: CoachWorldIntentID

        public init(
            id: MatchDayControlID,
            value: String?,
            isEnabled: Bool,
            isSelected: Bool,
            intentID: CoachWorldIntentID
        ) {
            self.id = id
            self.value = value
            self.isEnabled = isEnabled
            self.isSelected = isSelected
            self.intentID = intentID
        }
    }

    public let recordedOutcomeID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let venue: CoachWorldVenueReference
    public let home: TeamScore
    public let away: TeamScore
    public let situation: Situation
    public let offenseDirection: MatchFieldDirection
    public let actors: [Actor]
    public let lineOfScrimmage: Double
    public let firstDownLine: Double
    public let foregroundActorIDs: [String]
    public let causalCommentary: String
    public let staffInterruption: StaffInterruption?
    public let controls: [ControlState]

    public init(
        recordedOutcomeID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        venue: CoachWorldVenueReference,
        home: TeamScore,
        away: TeamScore,
        situation: Situation,
        offenseDirection: MatchFieldDirection,
        actors: [Actor],
        lineOfScrimmage: Double,
        firstDownLine: Double,
        foregroundActorIDs: [String],
        causalCommentary: String,
        staffInterruption: StaffInterruption?,
        controls: [ControlState]
    ) throws {
        guard recordedOutcomeID.contains(where: { !$0.isWhitespace }) else {
            throw ValidationError.invalidOutcomeID
        }
        guard home.team.stableID != away.team.stableID else {
            throw ValidationError.invalidTeamIdentity
        }
        guard home.score >= 0, away.score >= 0 else {
            throw ValidationError.invalidScore
        }
        guard situation.quarter >= 1 else {
            throw ValidationError.invalidSituation("quarter")
        }
        guard (0...900).contains(situation.clockSecondsRemaining) else {
            throw ValidationError.invalidSituation("clock")
        }
        guard (1...4).contains(situation.down) else {
            throw ValidationError.invalidSituation("down")
        }
        guard situation.yardsToGo >= 1 else {
            throw ValidationError.invalidSituation("yardsToGo")
        }
        guard causalCommentary.contains(where: { !$0.isWhitespace }) else {
            throw ValidationError.commentaryRequired
        }
        guard actors.count == 22 else { throw ValidationError.actorCount(actors.count) }
        guard Set(actors.map(\.stableID)).count == actors.count else {
            throw ValidationError.duplicateActorID
        }
        guard actors.filter({ $0.side == .home }).count == 11,
              actors.filter({ $0.side == .away }).count == 11 else {
            throw ValidationError.invalidTeamDistribution
        }
        for actor in actors {
            guard (0...120).contains(actor.xYardsFromLeftGoalLine),
                  (0...1).contains(actor.yFraction) else {
                throw ValidationError.invalidFieldPosition(actor.stableID)
            }
        }
        guard (0...120).contains(lineOfScrimmage) else {
            throw ValidationError.invalidLine("lineOfScrimmage")
        }
        guard (0...120).contains(firstDownLine) else {
            throw ValidationError.invalidLine("firstDownLine")
        }
        guard offenseDirection == .leftToRight
                ? firstDownLine > lineOfScrimmage
                : firstDownLine < lineOfScrimmage else {
            throw ValidationError.invalidLine("firstDownDirection")
        }
        guard Set(foregroundActorIDs).count == foregroundActorIDs.count,
              foregroundActorIDs.count <= 3 else {
            throw ValidationError.foregroundCount(foregroundActorIDs.count)
        }
        let actorIDs = Set(actors.map(\.stableID))
        if let unknown = foregroundActorIDs.first(where: { !actorIDs.contains($0) }) {
            throw ValidationError.unknownForegroundActor(unknown)
        }
        guard controls.count == MatchDayControlID.allCases.count,
              Set(controls.map(\.id)) == Set(MatchDayControlID.allCases) else {
            throw ValidationError.invalidControls
        }
        guard Set(controls.map(\.intentID)).count == controls.count else {
            throw ValidationError.invalidControls
        }

        self.recordedOutcomeID = recordedOutcomeID
        self.provenance = provenance
        self.world = world
        self.venue = venue
        self.home = home
        self.away = away
        self.situation = situation
        self.offenseDirection = offenseDirection
        self.actors = actors
        self.lineOfScrimmage = lineOfScrimmage
        self.firstDownLine = firstDownLine
        self.foregroundActorIDs = foregroundActorIDs
        self.causalCommentary = causalCommentary
        self.staffInterruption = staffInterruption
        self.controls = controls
    }
}

/// Immutable post-game projection. It is populated only from a persisted detailed summary; a
/// missing evidence record is an honest empty state rather than a reconstructed story.
public struct AftermathReadModel: Sendable, Equatable {
    public struct Grade: Sendable, Equatable, Identifiable {
        public var id: String { stableID }
        public let stableID: String
        public let player: CoachWorldPersonReference
        public let team: CoachWorldTeamReference
        public let position: String
        public let rating: Int
        public let evidence: String

        public init(
            stableID: String,
            player: CoachWorldPersonReference,
            team: CoachWorldTeamReference,
            position: String,
            rating: Int,
            evidence: String
        ) {
            self.stableID = stableID
            self.player = player
            self.team = team
            self.position = position
            self.rating = min(99, max(0, rating))
            self.evidence = evidence
        }
    }

    public let recordedOutcomeID: String
    public let provenance: CoachWorldDataProvenance
    public let world: CoachWorldReference
    public let venue: CoachWorldVenueReference
    public let home: MatchDayReadModel.TeamScore
    public let away: MatchDayReadModel.TeamScore
    public let resultLabel: String
    public let headline: String
    public let evidence: [String]
    public let callIns: [String]
    public let injuries: [String]
    public let grades: [Grade]

    public init(
        recordedOutcomeID: String,
        provenance: CoachWorldDataProvenance,
        world: CoachWorldReference,
        venue: CoachWorldVenueReference,
        home: MatchDayReadModel.TeamScore,
        away: MatchDayReadModel.TeamScore,
        resultLabel: String,
        headline: String,
        evidence: [String],
        callIns: [String],
        injuries: [String],
        grades: [Grade]
    ) {
        self.recordedOutcomeID = recordedOutcomeID
        self.provenance = provenance
        self.world = world
        self.venue = venue
        self.home = home
        self.away = away
        self.resultLabel = resultLabel
        self.headline = headline
        self.evidence = Array(evidence.prefix(16))
        self.callIns = Array(callIns.prefix(16))
        self.injuries = Array(injuries.prefix(16))
        self.grades = Array(grades.prefix(32))
    }
}

#if DEBUG
public enum CoachWorldSampleData {
    public static let world = CoachWorldReference(
        stableID: "sample-world",
        name: "Sample Football Universe"
    )
    // Colours are `04` section 6.1's labelled synthetic reference trio, not invented values: the
    // dark-primary pair for the home programme and the low-chroma pair away, so the fixtures
    // exercise both the ordinary case and the one that measures 2.67 on dark `work` and therefore
    // demands a boundary. Trade dress is the generator's contract; these are canon's own cards.
    public static let homeTeam = CoachWorldTeamReference(
        stableID: "sample-carson",
        name: "Carson Tech",
        abbreviation: "CAR",
        primaryColorHex: "#14382A",
        secondaryColorHex: "#D9B23C"
    )
    public static let awayTeam = CoachWorldTeamReference(
        stableID: "sample-southern",
        name: "Southern State",
        abbreviation: "SOU",
        primaryColorHex: "#555B66",
        secondaryColorHex: "#D9DDE4"
    )
    public static let venue = CoachWorldVenueReference(
        stableID: "sample-venue",
        name: "Memorial Field"
    )
    public static let coordinator = CoachWorldPersonReference(
        stableID: "sample-coordinator",
        name: "Morgan Hale",
        role: "Defensive coordinator"
    )
    public static let headCoach = CoachWorldPersonReference(
        stableID: "sample-head-coach",
        name: "Eric Mercer",
        role: "Head coach"
    )

    public static let coachingHQ: CoachingHQReadModel = {
        let decision = try! CoachingHQReadModel.Decision(
            stableID: "sample-practice-decision",
            title: "Protect the edge or pressure the pocket?",
            deadline: "Tuesday, 14:00",
            evidence: ["Outside runs win early downs."],
            choices: [
                .init(
                    intentID: .init(rawValue: "sample-run-fits"),
                    title: "Run Fits",
                    cost: "2 hours",
                    consequence: "Lose pressure reps"
                ),
                .init(
                    intentID: .init(rawValue: "sample-pass-rush"),
                    title: "Pass Rush",
                    cost: "2 hours",
                    consequence: "Run-fit concern remains"
                ),
            ]
        )
        return CoachingHQReadModel(
            snapshotID: "sample-hq-snapshot",
            provenance: .sample,
            world: world,
            team: homeTeam,
            coach: headCoach,
            recordLabel: "6–2",
            rankLabel: "#19",
            venue: venue,
            week: .init(
                seasonLabel: "2027 season",
                weekLabel: "Week 9",
                currentDay: "Monday",
                nextDeadline: "Practice plan due Tuesday, 14:00"
            ),
            weekPlan: [
                .init(stableID: "sample-mon", dayLabel: "Mon", assignment: "Rest", isCurrent: true),
                .init(stableID: "sample-tue", dayLabel: "Tue", assignment: "Work", isCurrent: false),
                .init(stableID: "sample-wed", dayLabel: "Wed", assignment: "Install", isCurrent: false),
                .init(stableID: "sample-thu", dayLabel: "Thu", assignment: "Polish", isCurrent: false),
                .init(stableID: "sample-fri", dayLabel: "Fri", assignment: "Travel", isCurrent: false),
                .init(stableID: "sample-sat", dayLabel: "Sat", assignment: "Game", isCurrent: false),
                .init(stableID: "sample-sun", dayLabel: "Sun", assignment: "Review", isCurrent: false),
            ],
            unallocatedPracticeMinutes: 180,
            opponent: awayTeam,
            obligations: [
                .init(
                    stableID: "sample-obligation",
                    title: "Set practice emphasis",
                    due: "Tuesday, 14:00",
                    consequence: "Staff cannot prepare the install",
                    isMandatory: true
                ),
            ],
            decision: decision,
            staffRecommendation: .init(
                staff: coordinator,
                verdict: "Run fits first",
                reason: "The opponent creates its efficient downs outside the tackles.",
                confidence: "Medium"
            ),
            correspondence: [
                .init(
                    stableID: "sample-message",
                    sender: coordinator,
                    subject: "First film notes are ready",
                    received: "08:15",
                    isUnread: true
                ),
            ]
        )
    }()

    public static let recruitingBoard: RecruitingBoardReadModel = {
        func prospect(
            id: String,
            rank: Int,
            name: String,
            position: String,
            hometown: String,
            interest: String,
            status: String,
            verdict: String,
            fit: String,
            uncertainty: String,
            outliers: [String],
            contact: String,
            effect: String
        ) -> RecruitingBoardReadModel.Prospect {
            .init(
                stableID: id,
                person: .init(
                    stableID: "\(id)-person",
                    name: name,
                    role: position
                ),
                boardRank: rank,
                position: position,
                hometown: hometown,
                interest: interest,
                status: status,
                evaluation: .init(
                    verdict: verdict,
                    schemeFit: fit,
                    uncertainty: uncertainty,
                    citedOutliers: outliers
                ),
                relationshipHistory: [
                    .init(
                        stableID: "\(id)-contact",
                        dateLabel: "Monday",
                        summary: contact,
                        effect: effect
                    ),
                ],
                choices: [
                    .init(
                        intentID: .init(rawValue: "\(id)-call"),
                        title: "Call prospect",
                        cost: "1 recruiting hour",
                        consequence: "Advances this relationship; delays another call"
                    ),
                    .init(
                        intentID: .init(rawValue: "\(id)-visit"),
                        title: "Offer official visit",
                        cost: "1 of 4 remaining visits",
                        consequence: "Creates a commitment window"
                    ),
                ]
            )
        }

        return RecruitingBoardReadModel(
            snapshotID: "sample-recruiting-snapshot",
            provenance: .sample,
            world: world,
            team: homeTeam,
            capacity: .init(
                scholarshipSlotsRemaining: 8,
                weeklyHoursRemaining: 22,
                officialVisitsRemaining: 4
            ),
            positionNeeds: [
                .init(stableID: "sample-need-qb", position: "QB", target: 1, committed: 0),
                .init(stableID: "sample-need-dl", position: "DL", target: 3, committed: 1),
                .init(stableID: "sample-need-ol", position: "OL", target: 2, committed: 0),
            ],
            prospects: [
                prospect(
                    id: "sample-prospect-mercer",
                    rank: 1,
                    name: "Jordan Mercer",
                    position: "QB",
                    hometown: "Brack Hollow, Kestrel Marches",
                    interest: "High",
                    status: "Evaluating",
                    verdict: "Starter tools; decision speed remains uncertain",
                    fit: "Strong",
                    uncertainty: "Medium",
                    outliers: ["Deep accuracy", "Pressure response"],
                    contact: "Position coach call",
                    effect: "Interest improved"
                ),
                prospect(
                    id: "sample-prospect-harris",
                    rank: 2,
                    name: "Malik Harris",
                    position: "EDGE",
                    hometown: "Larkin Crossing, Gallow Uplands",
                    interest: "Medium",
                    status: "Contacted",
                    verdict: "First-step pressure changes passing downs",
                    fit: "Elite",
                    uncertainty: "Low",
                    outliers: ["Burst", "Run anchor"],
                    contact: "Coordinator film review",
                    effect: "Family requested depth-chart detail"
                ),
                prospect(
                    id: "sample-prospect-alvarez",
                    rank: 3,
                    name: "Mateo Alvarez",
                    position: "OT",
                    hometown: "Pellham Mills, Dunmore Basin",
                    interest: "High",
                    status: "Visit ready",
                    verdict: "Long pass protector with unfinished leverage",
                    fit: "Strong",
                    uncertainty: "Medium",
                    outliers: ["Length", "Pad level"],
                    contact: "Family call",
                    effect: "Official visit dates discussed"
                ),
                prospect(
                    id: "sample-prospect-brooks",
                    rank: 4,
                    name: "Darius Brooks",
                    position: "CB",
                    hometown: "Wexford Harbor, Yarrow Tidelands",
                    interest: "Low",
                    status: "Watching",
                    verdict: "Press corner traits; recovery speed needs proof",
                    fit: "Good",
                    uncertainty: "High",
                    outliers: ["Press timing", "Recovery speed"],
                    contact: "Area scout check-in",
                    effect: "No movement after first contact"
                ),
                prospect(
                    id: "sample-prospect-okafor",
                    rank: 5,
                    name: "Nia Okafor",
                    position: "DT",
                    hometown: "Harrow Landing, Redmoor Coast",
                    interest: "Medium",
                    status: "Evaluating",
                    verdict: "Interior disruptor; snap volume is the open question",
                    fit: "Strong",
                    uncertainty: "Medium",
                    outliers: ["Get-off", "Snap volume"],
                    contact: "Defensive line coach call",
                    effect: "Requested scheme cut-ups"
                ),
            ]
        )
    }()

    public static let matchDay: MatchDayReadModel = {
        let homeFormation: [(number: String, position: String, x: Double, y: Double)] = [
            ("12", "QB", 51, 0.50), ("24", "RB", 46, 0.50),
            ("1", "WR", 54, 0.08), ("11", "WR", 54, 0.92), ("87", "TE", 55, 0.24),
            ("72", "LT", 56, 0.34), ("65", "LG", 56, 0.42), ("55", "C", 56, 0.50),
            ("68", "RG", 56, 0.58), ("76", "RT", 56, 0.66), ("6", "SLOT", 53, 0.78),
        ]
        let homeActors: [MatchDayReadModel.Actor] = homeFormation.enumerated().map { index, actor in
            return MatchDayReadModel.Actor(
                stableID: "sample-home-\(index)",
                side: .home,
                uniformNumber: actor.number,
                position: actor.position,
                xYardsFromLeftGoalLine: actor.x,
                yFraction: actor.y
            )
        }
        let awayFormation: [(number: String, position: String, x: Double, y: Double)] = [
            ("3", "CB", 61, 0.08), ("94", "DE", 61, 0.26), ("91", "DT", 61, 0.42),
            ("99", "DT", 61, 0.58), ("90", "DE", 61, 0.74), ("21", "CB", 61, 0.92),
            ("44", "LB", 65, 0.32), ("50", "LB", 65, 0.50), ("32", "LB", 65, 0.68),
            ("7", "FS", 72, 0.38), ("9", "SS", 68, 0.64),
        ]
        let awayActors: [MatchDayReadModel.Actor] = awayFormation.enumerated().map { index, actor in
            return MatchDayReadModel.Actor(
                stableID: "sample-away-\(index)",
                side: .away,
                uniformNumber: actor.number,
                position: actor.position,
                xYardsFromLeftGoalLine: actor.x,
                yFraction: actor.y
            )
        }
        let controls = MatchDayControlID.allCases.map { control in
            MatchDayReadModel.ControlState(
                id: control,
                value: control == .speed ? "1×" : nil,
                isEnabled: true,
                isSelected: control == .keyMoments,
                intentID: .init(rawValue: "sample-match-\(control.rawValue)")
            )
        }
        return try! MatchDayReadModel(
            recordedOutcomeID: "sample-recorded-outcome",
            provenance: .sample,
            world: world,
            venue: venue,
            home: .init(team: homeTeam, score: 28),
            away: .init(team: awayTeam, score: 24),
            situation: .init(
                quarter: 3,
                clockSecondsRemaining: 502,
                down: 1,
                yardsToGo: 10,
                possession: .home
            ),
            offenseDirection: .leftToRight,
            actors: homeActors + awayActors,
            lineOfScrimmage: 58,
            firstDownLine: 68,
            foregroundActorIDs: ["sample-home-0", "sample-home-4", "sample-away-10"],
            causalCommentary: "The safety stepped down after the tight end motion.",
            staffInterruption: .init(
                stableID: "sample-call-in",
                staff: coordinator,
                message: "Their weak-side safety is triggering before the snap.",
                evidence: ["Safety alignment moved inside the hash after tight end motion."],
                actions: [
                    .init(
                        path: .accept,
                        intentID: .init(rawValue: "sample-take-over"),
                        title: "Accept adjustment",
                        cost: "Applies after this play",
                        consequence: "The recorded moment remains unchanged"
                    ),
                    .init(
                        path: .dismiss,
                        intentID: .init(rawValue: "sample-delegate"),
                        title: "Dismiss call-in",
                        cost: "No tactical change",
                        consequence: "Staff keeps the current future call"
                    ),
                    .init(
                        path: .inspectEvidence,
                        intentID: .init(rawValue: "sample-inspect-evidence"),
                        title: "Inspect evidence",
                        cost: "No commitment",
                        consequence: "Opens the safety-trigger evidence"
                    ),
                ]
            ),
            controls: controls
        )
    }()
}
#endif
