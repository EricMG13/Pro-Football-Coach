import Foundation

public enum RedshirtSeasonOutcome: String, Codable, Sendable, Equatable {
    case notDesignated
    case preservedCompetitionSeason
    case burnedByUsage
}

public struct RedshirtSeasonResolution: Codable, Sendable, Equatable {
    public let outcome: RedshirtSeasonOutcome
    public let plannedAppearanceLimit: Int?

    public init(
        outcome: RedshirtSeasonOutcome,
        plannedAppearanceLimit: Int?
    ) {
        precondition(Self.hasValidShape(
            outcome: outcome,
            plannedAppearanceLimit: plannedAppearanceLimit
        ))
        self.outcome = outcome
        self.plannedAppearanceLimit = plannedAppearanceLimit
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedOutcome = try container.decode(
            RedshirtSeasonOutcome.self,
            forKey: .outcome
        )
        let decodedLimit = try container.decodeIfPresent(
            Int.self,
            forKey: .plannedAppearanceLimit
        )
        guard Self.hasValidShape(
            outcome: decodedOutcome,
            plannedAppearanceLimit: decodedLimit
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .plannedAppearanceLimit,
                in: container,
                debugDescription: "A redshirt outcome disagrees with its plan."
            )
        }
        outcome = decodedOutcome
        plannedAppearanceLimit = decodedLimit
    }

    public func isValid(appearances: Int) -> Bool {
        guard (0...CollegeRules.maximumGamesPerSeason).contains(appearances) else { return false }
        switch outcome {
        case .notDesignated:
            return plannedAppearanceLimit == nil
        case .preservedCompetitionSeason:
            return appearances <= CollegeRules.maximumRedshirtAppearances
                && plannedAppearanceLimit.map(
                    CollegeRules.redshirtAppearanceLimitRange.contains
                ) == true
        case .burnedByUsage:
            return appearances > CollegeRules.maximumRedshirtAppearances
                && plannedAppearanceLimit.map(
                    CollegeRules.redshirtAppearanceLimitRange.contains
                ) == true
        }
    }

    private static func hasValidShape(
        outcome: RedshirtSeasonOutcome,
        plannedAppearanceLimit: Int?
    ) -> Bool {
        switch outcome {
        case .notDesignated:
            return plannedAppearanceLimit == nil
        case .preservedCompetitionSeason, .burnedByUsage:
            return plannedAppearanceLimit.map(
                CollegeRules.redshirtAppearanceLimitRange.contains
            ) == true
        }
    }
}

public struct RedshirtPlan: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { playerID }
    public let playerID: UUID
    public let programmeID: UUID
    public let season: Int
    public let plannedAppearanceLimit: Int

    public init(
        playerID: UUID,
        programmeID: UUID,
        season: Int,
        plannedAppearanceLimit: Int
    ) {
        precondition(
            season >= 0
                && CollegeRules.redshirtAppearanceLimitRange.contains(plannedAppearanceLimit),
            "Redshirt plans require a non-negative season and an appearance limit from zero through four."
        )
        self.playerID = playerID
        self.programmeID = programmeID
        self.season = season
        self.plannedAppearanceLimit = plannedAppearanceLimit
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .season)
        let decodedLimit = try container.decode(Int.self, forKey: .plannedAppearanceLimit)
        guard decodedSeason >= 0,
              CollegeRules.redshirtAppearanceLimitRange.contains(decodedLimit) else {
            throw DecodingError.dataCorruptedError(
                forKey: .plannedAppearanceLimit,
                in: container,
                debugDescription: "A redshirt plan is outside its season or appearance bounds."
            )
        }
        playerID = try container.decode(UUID.self, forKey: .playerID)
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        season = decodedSeason
        plannedAppearanceLimit = decodedLimit
    }

    var isStructurallyValid: Bool {
        season >= 0
            && CollegeRules.redshirtAppearanceLimitRange.contains(plannedAppearanceLimit)
    }
}

public enum RedshirtPlanError: Error, Sendable, Equatable {
    case invalidAppearanceLimit
    case seasonUnavailable
    case missingProgramme
    case missingPlayer
    case playerNotOwnedByProgramme
    case ineligiblePlayer
    case noSpareClockYear
    case usageAlreadyExhausted
    case capacityConflict
    case missingDesignation
}

public enum CollegeRedshirtSystem {
    public static func hasSpareClockYear(_ eligibility: Eligibility) -> Bool {
        !eligibility.isExhausted
            && eligibility.yearsRemaining > eligibility.seasonsRemaining
    }

    static func allowsAutomaticAppearance(
        playerID: UUID,
        programmeID: UUID,
        in state: GameState
    ) -> Bool {
        guard let plan = state.college.redshirtPlans[playerID],
              plan.programmeID == programmeID,
              plan.season == state.calendar.season else { return true }
        let appearances = state.competition.playerStatistics[playerID]?.games ?? 0
        return appearances < plan.plannedAppearanceLimit
    }

    public static func seasonResolution(
        playerID: UUID,
        programmeID: UUID,
        in state: GameState
    ) -> RedshirtSeasonResolution {
        seasonResolution(
            playerID: playerID,
            programmeID: programmeID,
            in: state,
            season: state.calendar.season,
            college: state.college
        )
    }

    static func seasonResolution(
        playerID: UUID,
        programmeID: UUID,
        in state: GameState,
        season: Int,
        college: CollegeState
    ) -> RedshirtSeasonResolution {
        guard let plan = college.redshirtPlans[playerID],
              plan.programmeID == programmeID,
              plan.season == season else {
            return RedshirtSeasonResolution(
                outcome: .notDesignated,
                plannedAppearanceLimit: nil
            )
        }
        let appearances = state.competition.playerStatistics[playerID]?.games ?? 0
        return RedshirtSeasonResolution(
            outcome: appearances <= CollegeRules.maximumRedshirtAppearances
                ? .preservedCompetitionSeason
                : .burnedByUsage,
            plannedAppearanceLimit: plan.plannedAppearanceLimit
        )
    }

    public static func preservesCompetitionSeason(
        playerID: UUID,
        programmeID: UUID,
        in state: GameState
    ) -> Bool {
        seasonResolution(
            playerID: playerID,
            programmeID: programmeID,
            in: state
        ).outcome == .preservedCompetitionSeason
    }

    static func preservesCompetitionSeason(
        playerID: UUID,
        programmeID: UUID,
        in state: GameState,
        college: CollegeState
    ) -> Bool {
        seasonResolution(
            playerID: playerID,
            programmeID: programmeID,
            in: state,
            season: state.calendar.season,
            college: college
        ).outcome == .preservedCompetitionSeason
    }

    public static func designate(
        playerID: UUID,
        programmeID: UUID,
        plannedAppearanceLimit: Int,
        in state: GameState
    ) throws -> CollegeState {
        guard CollegeRules.redshirtAppearanceLimitRange.contains(plannedAppearanceLimit) else {
            throw RedshirtPlanError.invalidAppearanceLimit
        }
        guard state.college.phase == .active,
              state.college.recruitingSeason == state.calendar.season else {
            throw RedshirtPlanError.seasonUnavailable
        }
        guard state.programmes[programmeID] != nil,
              state.college.programmes[programmeID] != nil else {
            throw RedshirtPlanError.missingProgramme
        }
        guard state.programmes[programmeID]?.rosterIDs.contains(playerID) == true else {
            throw RedshirtPlanError.playerNotOwnedByProgramme
        }
        guard let player = state.players[playerID],
              let lifecycle = state.people.playerLifecycle[playerID] else {
            throw RedshirtPlanError.missingPlayer
        }
        guard let eligibility = player.eligibility,
              lifecycle.status == .active,
              !eligibility.isExhausted else {
            throw RedshirtPlanError.ineligiblePlayer
        }
        let appearances = state.competition.playerStatistics[playerID]?.games ?? 0
        guard appearances <= CollegeRules.maximumRedshirtAppearances else {
            throw RedshirtPlanError.usageAlreadyExhausted
        }
        guard hasSpareClockYear(eligibility) else {
            throw RedshirtPlanError.noSpareClockYear
        }
        var college = state.college
        let plan = RedshirtPlan(
            playerID: playerID,
            programmeID: programmeID,
            season: state.calendar.season,
            plannedAppearanceLimit: plannedAppearanceLimit
        )
        guard college.setRedshirtPlan(plan) else {
            throw RedshirtPlanError.seasonUnavailable
        }
        guard let capacity = CollegeCommitmentCapacitySystem.capacity(
            programmeID: programmeID,
            in: state,
            college: college
        ),
            capacity.activeReservations <= capacity.maximumReservations,
            capacity.preservesMinimumPositionCoverage else {
            throw RedshirtPlanError.capacityConflict
        }
        return college
    }

    public static func clearDesignation(
        playerID: UUID,
        programmeID: UUID,
        in state: GameState
    ) throws -> CollegeState {
        guard state.college.phase == .active,
              state.college.recruitingSeason == state.calendar.season else {
            throw RedshirtPlanError.seasonUnavailable
        }
        guard state.programmes[programmeID] != nil,
              state.college.programmes[programmeID] != nil else {
            throw RedshirtPlanError.missingProgramme
        }
        guard state.programmes[programmeID]?.rosterIDs.contains(playerID) == true else {
            throw RedshirtPlanError.playerNotOwnedByProgramme
        }
        guard state.college.redshirtPlans[playerID]?.programmeID == programmeID else {
            throw RedshirtPlanError.missingDesignation
        }
        var college = state.college
        guard college.clearRedshirtPlan(playerID: playerID, programmeID: programmeID) else {
            throw RedshirtPlanError.missingDesignation
        }
        return college
    }
}
