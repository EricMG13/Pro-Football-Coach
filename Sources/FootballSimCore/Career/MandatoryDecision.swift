import Foundation

public enum MandatoryDecisionSubject: Codable, Sendable, Equatable {
    case recruiting(prospectID: UUID)
    case portalRetention(playerID: UUID, window: CollegePortalWindow)
    case redshirt(playerID: UUID)
    case nilAllocation(playerID: UUID)

    public var responsibility: CollegeCareerResponsibility {
        switch self {
        case .recruiting: return .recruiting
        case .portalRetention: return .portalAndRetention
        case .redshirt: return .redshirts
        case .nilAllocation: return .nilAllocation
        }
    }

    var entityID: UUID {
        switch self {
        case let .recruiting(prospectID): return prospectID
        case let .portalRetention(playerID, _),
             let .redshirt(playerID),
             let .nilAllocation(playerID): return playerID
        }
    }
}

public enum MandatoryDecisionAction: Codable, Sendable, Equatable {
    case recruiting(RecruitingAction)
    case portalRetention(nilAllocation: Int)
    case portalRelease
    case redshirt(plannedAppearanceLimit: Int?)
    case nilAllocation(amount: Int)
}

public struct MandatoryDecisionOption: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let action: MandatoryDecisionAction

    public init(id: UUID, action: MandatoryDecisionAction) {
        self.id = id
        self.action = action
    }
}

public enum MandatoryDecisionReasonCode: String, Codable, Sendable, CaseIterable {
    case rosterNeed
    case rosterPath
    case scholarshipCapacity
    case nilBudget
    case playingTime
    case relationship
    case teamSuccess
    case restless
    case eligibility
    case fit
    case deadline
}

public struct MandatoryDecisionReason: Codable, Sendable, Equatable {
    public let code: MandatoryDecisionReasonCode
    public let value: Int
    public let relatedEntityID: UUID?

    public init(
        code: MandatoryDecisionReasonCode,
        value: Int,
        relatedEntityID: UUID? = nil
    ) {
        precondition((-10_000...10_000).contains(value), "A decision reason is out of bounds.")
        self.code = code
        self.value = value
        self.relatedEntityID = relatedEntityID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedValue = try container.decode(Int.self, forKey: .value)
        guard (-10_000...10_000).contains(decodedValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .value,
                in: container,
                debugDescription: "A decision reason is out of bounds."
            )
        }
        code = try container.decode(MandatoryDecisionReasonCode.self, forKey: .code)
        value = decodedValue
        relatedEntityID = try container.decodeIfPresent(UUID.self, forKey: .relatedEntityID)
    }
}

public struct MandatoryDecision: Codable, Sendable, Equatable, Identifiable {
    public static let optionCountRange = 2...3
    public static let maximumReasonCount = 8

    public let id: UUID
    public let programmeID: UUID
    public let subject: MandatoryDecisionSubject
    public let createdAt: CalendarState
    public let deadline: CalendarState
    public let owner: CareerResponsibilityOwner
    public let options: [MandatoryDecisionOption]
    public let recommendedOptionID: UUID
    public let reasons: [MandatoryDecisionReason]

    public var responsibility: CollegeCareerResponsibility { subject.responsibility }

    public init(
        id: UUID,
        programmeID: UUID,
        subject: MandatoryDecisionSubject,
        createdAt: CalendarState,
        deadline: CalendarState,
        owner: CareerResponsibilityOwner,
        options: [MandatoryDecisionOption],
        recommendedOptionID: UUID,
        reasons: [MandatoryDecisionReason]
    ) {
        precondition(Self.isValid(
            subject: subject,
            createdAt: createdAt,
            deadline: deadline,
            options: options,
            recommendedOptionID: recommendedOptionID,
            reasons: reasons
        ), "A mandatory decision is invalid.")
        self.id = id
        self.programmeID = programmeID
        self.subject = subject
        self.createdAt = createdAt
        self.deadline = deadline
        self.owner = owner
        self.options = options
        self.recommendedOptionID = recommendedOptionID
        self.reasons = reasons
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSubject = try container.decode(MandatoryDecisionSubject.self, forKey: .subject)
        let decodedCreatedAt = try container.decode(CalendarState.self, forKey: .createdAt)
        let decodedDeadline = try container.decode(CalendarState.self, forKey: .deadline)
        let decodedOptions = try container.decode([MandatoryDecisionOption].self, forKey: .options)
        let decodedRecommendation = try container.decode(UUID.self, forKey: .recommendedOptionID)
        let decodedReasons = try container.decode([MandatoryDecisionReason].self, forKey: .reasons)
        guard Self.isValid(
            subject: decodedSubject,
            createdAt: decodedCreatedAt,
            deadline: decodedDeadline,
            options: decodedOptions,
            recommendedOptionID: decodedRecommendation,
            reasons: decodedReasons
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .options,
                in: container,
                debugDescription: "A mandatory decision is invalid."
            )
        }
        id = try container.decode(UUID.self, forKey: .id)
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        subject = decodedSubject
        createdAt = decodedCreatedAt
        deadline = decodedDeadline
        owner = try container.decode(CareerResponsibilityOwner.self, forKey: .owner)
        options = decodedOptions
        recommendedOptionID = decodedRecommendation
        reasons = decodedReasons
    }

    private static func isValid(
        subject: MandatoryDecisionSubject,
        createdAt: CalendarState,
        deadline: CalendarState,
        options: [MandatoryDecisionOption],
        recommendedOptionID: UUID,
        reasons: [MandatoryDecisionReason]
    ) -> Bool {
        let optionIDs = options.map(\.id)
        return optionCountRange.contains(options.count)
            && Set(optionIDs).count == optionIDs.count
            && optionIDs.contains(recommendedOptionID)
            && (1...maximumReasonCount).contains(reasons.count)
            && !occurs(deadline, before: createdAt)
            && options.allSatisfy { actionIsValid($0.action, for: subject) }
    }

    static func actionIsValid(
        _ action: MandatoryDecisionAction,
        for subject: MandatoryDecisionSubject
    ) -> Bool {
        switch (subject, action) {
        case let (.recruiting, .recruiting(action)):
            switch action {
            case let .contact(points), let .evaluate(points):
                return (1...CollegeRules.weeklyRecruitingContactPoints).contains(points)
            case let .setNILAllocation(amount):
                return (0...CollegeRules.maximumNILBudget).contains(amount)
            case .addToBoard, .scheduleVisit, .offerScholarship, .withdraw:
                return true
            }
        case let (.portalRetention, .portalRetention(amount)),
             let (.nilAllocation, .nilAllocation(amount)):
            return (0...CollegeRules.maximumNILBudget).contains(amount)
        case (.portalRetention, .portalRelease):
            return true
        case let (.redshirt, .redshirt(limit)):
            return limit.map(CollegeRules.redshirtAppearanceLimitRange.contains) ?? true
        default:
            return false
        }
    }

    private static func occurs(_ lhs: CalendarState, before rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }
}

public struct MandatoryDecisionResolution: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { decisionID }
    public let decisionID: UUID
    public let programmeID: UUID
    public let subject: MandatoryDecisionSubject
    public let optionID: UUID
    public let action: MandatoryDecisionAction
    public let decidedAt: CalendarState

    public init(
        decisionID: UUID,
        programmeID: UUID,
        subject: MandatoryDecisionSubject,
        optionID: UUID,
        action: MandatoryDecisionAction,
        decidedAt: CalendarState
    ) {
        self.decisionID = decisionID
        self.programmeID = programmeID
        self.subject = subject
        self.optionID = optionID
        self.action = action
        self.decidedAt = decidedAt
    }
}

/// The result of applying one decision option: the new root, and whatever the underlying system
/// considered worth recording. The payloads matter — a recruiting answer emits interaction events,
/// and dropping them would make the delegated answer invisible where the chosen one is not.
public struct MandatoryDecisionApplication: Sendable {
    public let state: GameState
    public let eventPayloads: [DomainEventPayload]

    public init(state: GameState, eventPayloads: [DomainEventPayload]) {
        self.state = state
        self.eventPayloads = eventPayloads
    }
}

public enum CareerMandatoryDecisionSystem {
    /// Applies one decision option's action to the root, or returns `nil` when it cannot be applied.
    ///
    /// Shared deliberately. The player answering an obligation and the staff answering it on their
    /// behalf when its deadline elapses must do the *same thing* — two implementations of "what this
    /// option means" would let the delegated outcome drift from the chosen one, which is exactly the
    /// coverage boundary `CLAUDE.md` names as a defect.
    static func applying(
        _ action: MandatoryDecisionAction,
        subject: MandatoryDecisionSubject,
        programmeID: UUID,
        in state: GameState
    ) -> MandatoryDecisionApplication? {
        var next = state
        var payloads: [DomainEventPayload] = []
        switch action {
        case let .recruiting(recruitingAction):
            guard let transition = try? CollegeRecruitingSystem.apply(
                RecruitingActionRequest(
                    programmeID: programmeID,
                    prospectID: subject.entityID,
                    action: recruitingAction
                ),
                in: next
            ) else { return nil }
            next.prospects = transition.prospects
            next.college = transition.college
            next.scouting = transition.scouting
            payloads = transition.eventPayloads
        case let .redshirt(plannedAppearanceLimit):
            if let plannedAppearanceLimit {
                guard let college = try? CollegeRedshirtSystem.designate(
                    playerID: subject.entityID,
                    programmeID: programmeID,
                    plannedAppearanceLimit: plannedAppearanceLimit,
                    in: next
                ) else { return nil }
                next.college = college
            } else if next.college.redshirtPlans[subject.entityID] != nil {
                guard let college = try? CollegeRedshirtSystem.clearDesignation(
                    playerID: subject.entityID,
                    programmeID: programmeID,
                    in: next
                ) else { return nil }
                next.college = college
            }
        case let .nilAllocation(amount):
            var applied = false
            _ = next.college.updateProgramme(programmeID) {
                applied = $0.setRosterNILAllocation(amount, playerID: subject.entityID)
            }
            guard applied else { return nil }
        case .portalRetention, .portalRelease:
            // Retention is already resolved by the portal policy before the obligation is raised;
            // the answer is recorded, and applies no further state change. Kept explicit rather
            // than folded into a `default` so a future portal write cannot be added silently.
            break
        }
        return MandatoryDecisionApplication(state: next, eventPayloads: payloads)
    }

    public static func refresh(
        in state: GameState,
        deadlineAt: CalendarState? = nil
    ) -> GameState {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID] else { return state }
        if state.college.portal.phase == .awaitingSpring {
            return refreshSpringPortal(control: control, deadlineAt: deadlineAt, in: state)
        }
        guard state.calendar.week <= 2,
              state.college.phase == .active,
              state.college.portal.phase == .closed else { return state }
        var next = state
        for position in Position.allCases {
            let players = programme.rosterIDs.compactMap { state.players[$0] }.filter {
                $0.position == position
            }.sorted {
                if $0.overall.value != $1.overall.value {
                    return $0.overall.value > $1.overall.value
                }
                return $0.id.uuidString < $1.id.uuidString
            }
            let minimum = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
            guard minimum > 0,
                  players.count > minimum,
                  let eligibility = players[minimum].eligibility,
                  eligibility.seasonsRemaining == CollegeRules.seasonsOfCompetition,
                  eligibility.yearsRemaining == CollegeRules.eligibilityClockYears,
                  state.people.playerLifecycle[players[minimum].id]?.status == .active,
                  state.college.redshirtPlans[players[minimum].id] == nil else { continue }
            let playerID = players[minimum].id
            let decisionID = stableID(
                rootSeed: state.league.seed,
                season: state.calendar.season,
                playerID: playerID,
                discriminator: 0
            )
            guard !next.pending.mandatoryDecisions.contains(where: { $0.id == decisionID }),
                  !next.career.mandatoryDecisionResolutions.contains(where: {
                      $0.decisionID == decisionID
                  }) else { continue }
            let noRedshirtID = stableID(
                rootSeed: state.league.seed,
                season: state.calendar.season,
                playerID: playerID,
                discriminator: 1
            )
            let redshirtID = stableID(
                rootSeed: state.league.seed,
                season: state.calendar.season,
                playerID: playerID,
                discriminator: 2
            )
            let ratingGap = max(0, players[minimum - 1].overall.value - players[minimum].overall.value)
            let recommendedOptionID = ratingGap >= 5 ? redshirtID : noRedshirtID
            let owner = control.responsibilityOwners[.redshirts] ?? .user
            let decision = MandatoryDecision(
                id: decisionID,
                programmeID: control.programmeID,
                subject: .redshirt(playerID: playerID),
                createdAt: state.calendar,
                deadline: deadlineAt ?? state.calendar,
                owner: owner,
                options: [
                    MandatoryDecisionOption(
                        id: noRedshirtID,
                        action: .redshirt(plannedAppearanceLimit: nil)
                    ),
                    MandatoryDecisionOption(
                        id: redshirtID,
                        action: .redshirt(
                            plannedAppearanceLimit: CollegeRules.maximumRedshirtAppearances
                        )
                    ),
                ],
                recommendedOptionID: recommendedOptionID,
                reasons: [
                    MandatoryDecisionReason(
                        code: .playingTime,
                        value: ratingGap,
                        relatedEntityID: playerID
                    ),
                    MandatoryDecisionReason(code: .eligibility, value: 1),
                ]
            )
            switch owner {
            case .user:
                _ = next.pending.enqueue(decision)
            case .delegated:
                let option = decision.options.first { $0.id == recommendedOptionID }!
                if case let .redshirt(limit?) = option.action {
                    guard let college = try? CollegeRedshirtSystem.designate(
                        playerID: playerID,
                        programmeID: control.programmeID,
                        plannedAppearanceLimit: limit,
                        in: next
                    ) else { continue }
                    next.college = college
                }
                _ = next.career.recordResolution(MandatoryDecisionResolution(
                    decisionID: decision.id,
                    programmeID: decision.programmeID,
                    subject: decision.subject,
                    optionID: option.id,
                    action: option.action,
                    decidedAt: state.calendar
                ))
            }
        }
        return WorldIntegrity.check(next).isValid ? next : state
    }

    private static func refreshSpringPortal(
        control: CollegeCareerControl,
        deadlineAt: CalendarState? = nil,
        in state: GameState
    ) -> GameState {
        guard control.responsibilityOwners[.portalAndRetention] == .user,
              let snapshot = CollegePortalPolicyV1.makeSnapshot(
                  targetSeason: state.calendar.season,
                  window: .spring,
                  in: state
              ),
              let programme = state.college.programmes[control.programmeID],
              let transition = CollegePortalPolicyV1.resolveRetention(
                  for: control.programmeID,
                  programme: programme,
                  using: snapshot
              ) else { return state }
        var next = state
        for intent in snapshot.intents where intent.sourceProgrammeID == control.programmeID {
            guard let resolution = transition.resolutions[intent.playerID],
                  resolution.outcome == .retained else { continue }
            let decisionID = stableID(
                rootSeed: state.league.seed,
                season: state.calendar.season,
                playerID: intent.playerID,
                discriminator: 10
            )
            guard !next.pending.mandatoryDecisions.contains(where: { $0.id == decisionID }),
                  !next.career.mandatoryDecisionResolutions.contains(where: {
                      $0.decisionID == decisionID
                  }) else { continue }
            let retainID = stableID(
                rootSeed: state.league.seed,
                season: state.calendar.season,
                playerID: intent.playerID,
                discriminator: 11
            )
            let releaseID = stableID(
                rootSeed: state.league.seed,
                season: state.calendar.season,
                playerID: intent.playerID,
                discriminator: 12
            )
            let reasons = intent.components.map { component in
                MandatoryDecisionReason(
                    code: reasonCode(component.reason),
                    value: component.value,
                    relatedEntityID: intent.playerID
                )
            }
            _ = next.pending.enqueue(MandatoryDecision(
                id: decisionID,
                programmeID: control.programmeID,
                subject: .portalRetention(playerID: intent.playerID, window: .spring),
                createdAt: state.calendar,
                deadline: deadlineAt ?? state.calendar,
                owner: .user,
                options: [
                    MandatoryDecisionOption(
                        id: retainID,
                        action: .portalRetention(
                            nilAllocation: resolution.sourceRosterNILAfterDecision
                        )
                    ),
                    MandatoryDecisionOption(id: releaseID, action: .portalRelease),
                ],
                recommendedOptionID: retainID,
                reasons: reasons
            ))
        }
        return WorldIntegrity.check(next).isValid ? next : state
    }

    private static func reasonCode(
        _ reason: CollegePortalIntentReason
    ) -> MandatoryDecisionReasonCode {
        switch reason {
        case .playingTime: return .playingTime
        case .rosterPath: return .rosterPath
        case .relationship: return .relationship
        case .nilAllocation: return .nilBudget
        case .teamSuccess: return .teamSuccess
        case .restless: return .restless
        }
    }

    private static func stableID(
        rootSeed: UInt64,
        season: Int,
        playerID: UUID,
        discriminator: Int
    ) -> UUID {
        let seasonSeed = SeededRandom.derive(from: rootSeed, scope: .season, ordinal: season)
        let playerSeed = SeededRandom.derive(
            from: seasonSeed,
            scope: .personnel,
            identifier: playerID
        )
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: playerSeed,
            scope: .scheduler,
            ordinal: discriminator
        ))
        return rng.uuid()
    }
}
