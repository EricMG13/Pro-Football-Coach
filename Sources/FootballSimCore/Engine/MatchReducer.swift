import Foundation

public enum MatchAction: Codable, Sendable, Equatable {
    case advance
    case togglePause
    case toggleTakeover
    case chooseCallIn(TacticalCallInAction)
    /// `02` section 3.2's mid-match tactical change: tempo, aggression and run/pass bias, moved on
    /// the coach's own side only. Distinct from `chooseCallIn`, which is a coordinator's proposal
    /// answered at a specific snap; this is the coach reaching for the plan unprompted, the way
    /// Tactics does.
    case setTacticalPlan(TacticalPlan)
}

public enum MatchPauseBoundary: String, Codable, Sendable, Equatable {
    case snap
    case drive
    case quarter
    case halftime
    case overtime
    case callIn
    case completed
}

/// Compact immutable aftermath for a controlled fixture. Snap-by-snap data remains in the bounded
/// record while this projection keeps the player-facing causal anchors and call receipts stable.
public struct GameEvidence: Codable, Sendable, Equatable {
    public static let maximumDecisiveMatchups = 32
    public static let maximumInjuryEvidence = 32

    public let fixtureID: UUID?
    public let record: GameRecord
    public let homeParticipantIDs: [UUID]
    public let awayParticipantIDs: [UUID]
    public let callInReceipts: [MatchCallInReceipt]
    public let decisiveMatchups: [MatchupRecord]
    public let injuries: [GameInjuryEvidence]

    public init(
        fixtureID: UUID? = nil,
        record: GameRecord,
        homeParticipantIDs: [UUID],
        awayParticipantIDs: [UUID],
        callInReceipts: [MatchCallInReceipt],
        injuries: [GameInjuryEvidence] = []
    ) {
        self.fixtureID = fixtureID
        self.record = record
        self.homeParticipantIDs = Array(Set(homeParticipantIDs)).sorted { $0.uuidString < $1.uuidString }
        self.awayParticipantIDs = Array(Set(awayParticipantIDs)).sorted { $0.uuidString < $1.uuidString }
        self.callInReceipts = callInReceipts
        self.decisiveMatchups = Array(record.plays.compactMap { $0.outcome.decidingMatchup }
            .prefix(Self.maximumDecisiveMatchups))
        self.injuries = Array(injuries.sorted {
            if $0.playerID != $1.playerID { return $0.playerID.uuidString < $1.playerID.uuidString }
            if $0.occurredAt.season != $1.occurredAt.season {
                return $0.occurredAt.season < $1.occurredAt.season
            }
            return $0.occurredAt.week < $1.occurredAt.week
        }.prefix(Self.maximumInjuryEvidence))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let home = try container.decode([UUID].self, forKey: .homeParticipantIDs)
        let away = try container.decode([UUID].self, forKey: .awayParticipantIDs)
        let callIns = try container.decode([MatchCallInReceipt].self, forKey: .callInReceipts)
        let matchups = try container.decode([MatchupRecord].self, forKey: .decisiveMatchups)
        let injuries = try container.decodeIfPresent([GameInjuryEvidence].self, forKey: .injuries) ?? []
        let homeIDs = Set(home)
        let awayIDs = Set(away)
        guard home.count <= CompetitionRules.maximumParticipantsPerTeam,
              away.count <= CompetitionRules.maximumParticipantsPerTeam,
              callIns.count <= MatchupRules.maximumCallInsPerGame,
              matchups.count <= Self.maximumDecisiveMatchups,
              injuries.count <= Self.maximumInjuryEvidence,
              Set(injuries.map(\.playerID)).count == injuries.count,
              injuries.allSatisfy({ injury in
                  let isHome = homeIDs.contains(injury.playerID)
                  let isAway = awayIDs.contains(injury.playerID)
                  return isHome != isAway
                      && (injury.side == .home ? isHome : isAway)
              }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .decisiveMatchups,
                in: container,
                debugDescription: "Game evidence exceeds its bounded aftermath shape."
            )
        }
        self.init(
            fixtureID: try container.decodeIfPresent(UUID.self, forKey: .fixtureID),
            record: try container.decode(GameRecord.self, forKey: .record),
            homeParticipantIDs: home,
            awayParticipantIDs: away,
            callInReceipts: callIns,
            injuries: injuries
        )
        guard decisiveMatchups == matchups else {
            throw DecodingError.dataCorruptedError(
                forKey: .decisiveMatchups,
                in: container,
                debugDescription: "Game evidence anchors disagree with the immutable record."
            )
        }
    }
}

/// A bounded, rules-owned record of a player's match absence. The detailed reducer currently
/// emits no in-play injury events, so ordinary completions carry an honest empty list; the field
/// exists here rather than in the UI so a future injury producer can remain receipt-backed.
public struct GameInjuryEvidence: Codable, Sendable, Equatable {
    public let playerID: UUID
    public let side: Side
    public let area: InjuryArea
    public let severity: InjurySeverity
    public let weeks: Int
    public let occurredAt: CalendarState

    public init(
        playerID: UUID,
        side: Side,
        area: InjuryArea,
        severity: InjurySeverity,
        weeks: Int,
        occurredAt: CalendarState
    ) {
        self.playerID = playerID
        self.side = side
        self.area = area
        self.severity = severity
        self.weeks = min(max(1, weeks), PeopleRules.maximumInjuryWeeks)
        self.occurredAt = occurredAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let weeks = try container.decode(Int.self, forKey: .weeks)
        guard (1...PeopleRules.maximumInjuryWeeks).contains(weeks) else {
            throw DecodingError.dataCorruptedError(
                forKey: .weeks,
                in: container,
                debugDescription: "Match injury evidence exceeds its legal duration."
            )
        }
        self.init(
            playerID: try container.decode(UUID.self, forKey: .playerID),
            side: try container.decode(Side.self, forKey: .side),
            area: try container.decode(InjuryArea.self, forKey: .area),
            severity: try container.decode(InjurySeverity.self, forKey: .severity),
            weeks: weeks,
            occurredAt: try container.decode(CalendarState.self, forKey: .occurredAt)
        )
    }
}

public struct MatchCallInReceipt: Codable, Sendable, Equatable {
    public let side: Side
    public let situation: Situation
    public let action: TacticalCallInAction
    public let trigger: CallInTrigger

    public init(side: Side, situation: Situation, action: TacticalCallInAction,
                trigger: CallInTrigger) {
        self.side = side
        self.situation = situation
        self.action = action
        self.trigger = trigger
    }
}

public struct MatchCompletionReceipt: Codable, Sendable, Equatable {
    public let record: GameRecord
    public let callInReceipts: [MatchCallInReceipt]
    public let evidence: GameEvidence
    public let fingerprint: UInt64

    public init(
        record: GameRecord,
        callInReceipts: [MatchCallInReceipt],
        homeParticipantIDs: [UUID] = [],
        awayParticipantIDs: [UUID] = [],
        evidence: GameEvidence? = nil
    ) {
        self.record = record
        self.callInReceipts = callInReceipts
        self.evidence = evidence ?? GameEvidence(
            record: record,
            homeParticipantIDs: homeParticipantIDs,
            awayParticipantIDs: awayParticipantIDs,
            callInReceipts: callInReceipts
        )
        self.fingerprint = record.playByPlayFingerprint
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let record = try container.decode(GameRecord.self, forKey: .record)
        let callIns = try container.decode([MatchCallInReceipt].self, forKey: .callInReceipts)
        let evidence = try container.decode(GameEvidence.self, forKey: .evidence)
        let fingerprint = try container.decode(UInt64.self, forKey: .fingerprint)
        guard evidence.record == record,
              evidence.callInReceipts == callIns,
              fingerprint == record.playByPlayFingerprint else {
            throw DecodingError.dataCorruptedError(
                forKey: .evidence,
                in: container,
                debugDescription: "Completion evidence does not match its immutable record."
            )
        }
        self.record = record
        self.callInReceipts = callIns
        self.evidence = evidence
        self.fingerprint = fingerprint
    }
}

public struct MatchStepReceipt: Codable, Sendable, Equatable {
    public let boundary: MatchPauseBoundary
    public let play: PlayRecord?
    public let proposal: TacticalCallInProposal?
    public let callIn: MatchCallInReceipt?
    public let completion: MatchCompletionReceipt?

    public init(
        boundary: MatchPauseBoundary,
        play: PlayRecord? = nil,
        proposal: TacticalCallInProposal? = nil,
        callIn: MatchCallInReceipt? = nil,
        completion: MatchCompletionReceipt? = nil
    ) {
        self.boundary = boundary
        self.play = play
        self.proposal = proposal
        self.callIn = callIn
        self.completion = completion
    }
}

public struct MatchSessionState: Codable, Sendable, Equatable {
    public let fixtureID: UUID?
    public let tier: Tier
    public let stage: CompetitionStage
    public let home: SnapPersonnel
    public let away: SnapPersonnel
    public let seed: UInt64
    public let homeFieldAdvantage: Double
    public let controlledSide: Side?
    /// Whether the coach currently owns call-in decisions for the controlled side. Keeping the
    /// side separate from this flag lets a hand-back resume without losing the user's team.
    public var isTakeover: Bool
    public var homePlan: TacticalPlan
    public var awayPlan: TacticalPlan
    public var situation: Situation
    public var drives: [DriveRecord]
    public var currentDrive: DriveProgress?
    public var nextDriveIndex: Int
    public var afterTurnover: Bool
    public var clockRunning: Bool
    public var pendingCallIn: TacticalCallInProposal?
    public var callInReceipts: [MatchCallInReceipt]
    /// Monotonic checkpoint identity used to reject delayed UI actions after a resume or snap.
    /// Missing in older checkpoints means the first loaded state is revision zero.
    public fileprivate(set) var revision: UInt64
    public var isPaused: Bool
    /// Zero means regulation. Positive values identify the bounded overtime period.
    public var overtimePeriod: Int
    /// Counts possessions completed by each side in the active alternating-possession period.
    public var overtimePossessions: [Side: Int]
    public var completedEvidence: GameEvidence?
    public var completed: Bool

    public init(
        tier: Tier,
        stage: CompetitionStage = .regularSeason,
        home: SnapPersonnel,
        away: SnapPersonnel,
        seed: UInt64,
        controlledSide: Side? = nil,
        homePlan: TacticalPlan = .balanced,
        awayPlan: TacticalPlan = .balanced,
        homeFieldAdvantage: Double? = nil,
        initialSituation: Situation? = nil,
        fixtureID: UUID? = nil
    ) {
        let rules = tier.clockRules
        let situation = initialSituation ?? Situation(
            yardLine: MatchupRules.kickoffTouchbackYardLine,
            possession: .home,
            quarter: 1,
            secondsRemainingInQuarter: rules.quarterSeconds,
            timeoutsRemaining: [.home: rules.timeoutsPerHalf, .away: rules.timeoutsPerHalf]
        )
        self.fixtureID = fixtureID
        self.tier = tier
        self.stage = stage
        self.home = home
        self.away = away
        self.seed = seed
        self.homeFieldAdvantage = homeFieldAdvantage ?? tier.homeAdvantage
        self.controlledSide = controlledSide
        self.isTakeover = controlledSide != nil
        self.homePlan = homePlan
        self.awayPlan = awayPlan
        self.situation = situation
        self.drives = []
        self.currentDrive = nil
        self.nextDriveIndex = 0
        self.afterTurnover = false
        self.clockRunning = false
        self.pendingCallIn = nil
        self.callInReceipts = []
        self.revision = 0
        self.isPaused = false
        self.overtimePeriod = 0
        self.overtimePossessions = [:]
        self.completedEvidence = nil
        self.completed = false
    }

    public var completion: MatchCompletionReceipt? {
        guard completed else { return nil }
        return MatchCompletionReceipt(
            record: GameRecord(homeScore: situation.homeScore, awayScore: situation.awayScore,
                               drives: drives, tier: tier),
            callInReceipts: callInReceipts,
            homeParticipantIDs: home.offense.map(\.id) + home.defense.map(\.id),
            awayParticipantIDs: away.offense.map(\.id) + away.defense.map(\.id),
            evidence: completedEvidence
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fixtureID = try container.decodeIfPresent(UUID.self, forKey: .fixtureID)
        self.tier = try container.decode(Tier.self, forKey: .tier)
        self.stage = try container.decodeIfPresent(CompetitionStage.self, forKey: .stage)
            ?? .regularSeason
        self.home = try container.decode(SnapPersonnel.self, forKey: .home)
        self.away = try container.decode(SnapPersonnel.self, forKey: .away)
        self.seed = try container.decode(UInt64.self, forKey: .seed)
        self.homeFieldAdvantage = try container.decode(Double.self, forKey: .homeFieldAdvantage)
        self.controlledSide = try container.decodeIfPresent(Side.self, forKey: .controlledSide)
        self.isTakeover = try container.decodeIfPresent(Bool.self, forKey: .isTakeover)
            ?? (controlledSide != nil)
        self.homePlan = try container.decode(TacticalPlan.self, forKey: .homePlan)
        self.awayPlan = try container.decode(TacticalPlan.self, forKey: .awayPlan)
        self.situation = try container.decode(Situation.self, forKey: .situation)
        self.drives = try container.decode([DriveRecord].self, forKey: .drives)
        self.currentDrive = try container.decodeIfPresent(DriveProgress.self, forKey: .currentDrive)
        self.nextDriveIndex = try container.decode(Int.self, forKey: .nextDriveIndex)
        self.afterTurnover = try container.decode(Bool.self, forKey: .afterTurnover)
        self.clockRunning = try container.decode(Bool.self, forKey: .clockRunning)
        self.pendingCallIn = try container.decodeIfPresent(TacticalCallInProposal.self,
                                                           forKey: .pendingCallIn)
        self.callInReceipts = try container.decode([MatchCallInReceipt].self,
                                                   forKey: .callInReceipts)
        self.revision = try container.decodeIfPresent(UInt64.self, forKey: .revision) ?? 0
        self.isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        self.overtimePeriod = try container.decodeIfPresent(Int.self, forKey: .overtimePeriod)
            ?? 0
        self.overtimePossessions = try container.decodeIfPresent(
            [Side: Int].self,
            forKey: .overtimePossessions
        ) ?? [:]
        self.completedEvidence = try container.decodeIfPresent(GameEvidence.self,
                                                                forKey: .completedEvidence)
        self.completed = try container.decode(Bool.self, forKey: .completed)
        let completedRecord = GameRecord(
            homeScore: situation.homeScore,
            awayScore: situation.awayScore,
            drives: drives,
            tier: tier
        )
        guard completed
            ? (completedEvidence?.record == completedRecord
                && completedEvidence?.callInReceipts == callInReceipts)
            : completedEvidence == nil else {
            throw DecodingError.dataCorruptedError(
                forKey: .completedEvidence,
                in: container,
                debugDescription: "Completed match state must carry matching immutable evidence."
            )
        }
        guard drives.count <= MatchupRules.maximumDrivesPerGame,
              nextDriveIndex >= 0,
              nextDriveIndex <= MatchupRules.maximumDrivesPerGame,
              overtimePeriod >= 0,
              overtimePeriod <= CompetitionRules.maximumOvertimePeriods,
              overtimePossessions.values.allSatisfy({ (0...1).contains($0) }),
              callInReceipts.count <= MatchupRules.maximumCallInsPerGame,
              currentDrive?.ending == nil,
              currentDrive == nil || currentDrive?.situation == situation,
              currentDrive?.plays.count ?? 0 <= MatchupRules.maximumPlaysPerDrive else {
            throw DecodingError.dataCorruptedError(
                forKey: .drives,
                in: container,
                debugDescription: "Match progress exceeds the bounded game budget."
            )
        }
        guard !isTakeover || controlledSide != nil,
              !completed || pendingCallIn == nil,
              callInReceipts.count <= MatchupRules.maximumCallInsPerGame else {
            throw DecodingError.dataCorruptedError(
                forKey: .pendingCallIn,
                in: container,
                debugDescription: "Match control state is inconsistent with its bounded call-in ledger."
            )
        }
        if let proposal = pendingCallIn {
            guard !isPaused,
                  isTakeover,
                  let controlledSide,
                  proposal.situation.possession == controlledSide,
                  let drive = currentDrive,
                  drive.ending == nil,
                  drive.situation == proposal.situation,
                  callInReceipts.count < MatchupRules.maximumCallInsPerGame else {
                throw DecodingError.dataCorruptedError(
                    forKey: .pendingCallIn,
                    in: container,
                    debugDescription: "A pending call-in must describe the current controlled snap."
                )
            }
        }
    }
}

public enum MatchReducerError: Error, Sendable, Equatable {
    case completed
    case paused
    case revisionOverflow
    case unavailableTakeover
    case invalidCallInState
    case awaitingCallIn
    case noPendingCallIn
    case unavailableCallIn(TacticalCallInAction)
    case unavailableTactics
}

private struct MatchPlayCaller: PlayCaller, Sendable {
    let offensivePlan: TacticalPlan
    let defensivePlan: TacticalPlan

    func offensiveCall(for situation: Situation, rules: any ClockRules.Type) -> OffensiveCall {
        TacticalPlayCaller(plan: offensivePlan).offensiveCall(for: situation, rules: rules)
    }

    func defensiveCall(for situation: Situation, rules: any ClockRules.Type) -> DefensiveCall {
        TacticalPlayCaller(plan: defensivePlan).defensiveCall(for: situation, rules: rules)
    }
}

/// One reducer drives both headless games and controlled match checkpoints.
public enum MatchReducer {
    public static func start(
        tier: Tier,
        stage: CompetitionStage = .regularSeason,
        home: SnapPersonnel,
        away: SnapPersonnel,
        seed: UInt64,
        controlledSide: Side? = nil,
        homePlan: TacticalPlan = .balanced,
        awayPlan: TacticalPlan = .balanced,
        homeFieldAdvantage: Double? = nil,
        initialSituation: Situation? = nil,
        fixtureID: UUID? = nil
    ) -> MatchSessionState {
        MatchSessionState(
            tier: tier, stage: stage, home: home, away: away, seed: seed,
            controlledSide: controlledSide, homePlan: homePlan, awayPlan: awayPlan,
            homeFieldAdvantage: homeFieldAdvantage, initialSituation: initialSituation,
            fixtureID: fixtureID
        )
    }

    public static func reduce(
        _ action: MatchAction,
        state: inout MatchSessionState
    ) throws -> MatchStepReceipt {
        try reduce(action, state: &state, callerOverride: nil)
    }

    static func reduce(
        _ action: MatchAction,
        state: inout MatchSessionState,
        callerOverride: (any PlayCaller)?
    ) throws -> MatchStepReceipt {
        guard !state.completed else { throw MatchReducerError.completed }
        guard state.revision < UInt64.max else { throw MatchReducerError.revisionOverflow }
        switch action {
        case .togglePause:
            guard state.pendingCallIn == nil else { throw MatchReducerError.awaitingCallIn }
            state.isPaused.toggle()
            return commit(MatchStepReceipt(boundary: .snap), state: &state)
        case .toggleTakeover:
            guard state.controlledSide != nil else {
                throw MatchReducerError.unavailableTakeover
            }
            guard state.pendingCallIn == nil else { throw MatchReducerError.awaitingCallIn }
            state.isTakeover.toggle()
            return commit(MatchStepReceipt(boundary: .snap), state: &state)
        case .chooseCallIn(let action):
            return try commit(
                chooseCallIn(action, state: &state, callerOverride: callerOverride),
                state: &state
            )
        case .setTacticalPlan(let plan):
            guard let controlledSide = state.controlledSide else {
                throw MatchReducerError.unavailableTactics
            }
            guard state.pendingCallIn == nil else { throw MatchReducerError.awaitingCallIn }
            if controlledSide == .home {
                state.homePlan = plan
            } else {
                state.awayPlan = plan
            }
            return commit(MatchStepReceipt(boundary: .snap), state: &state)
        case .advance:
            guard !state.isPaused else { throw MatchReducerError.paused }
            guard state.pendingCallIn == nil else { throw MatchReducerError.awaitingCallIn }
        }

        prepareDriveIfNeeded(state: &state)
        if let proposal = callInProposal(state: state) {
            state.pendingCallIn = proposal
            return commit(
                MatchStepReceipt(boundary: .callIn, proposal: proposal),
                state: &state
            )
        }
        return commit(
            try resolveSnap(state: &state, callerOverride: callerOverride),
            state: &state
        )
    }

    private static func commit(
        _ receipt: MatchStepReceipt,
        state: inout MatchSessionState
    ) -> MatchStepReceipt {
        state.revision += 1
        return receipt
    }

    /// Runs the same reducer to completion for non-controlled games and tests.
    public static func playToCompletion(
        tier: Tier,
        stage: CompetitionStage = .regularSeason,
        home: SnapPersonnel,
        away: SnapPersonnel,
        caller: any PlayCaller = BaselinePlayCaller(),
        homeFieldAdvantage: Double? = nil,
        seed: UInt64,
        initialSituation: Situation? = nil
    ) -> MatchCompletionReceipt {
        var state = start(
            tier: tier,
            stage: stage,
            home: home,
            away: away,
            seed: seed,
            homeFieldAdvantage: homeFieldAdvantage,
            initialSituation: initialSituation
        )
        while !state.completed {
            do {
                _ = try reduce(.advance, state: &state, callerOverride: caller)
            } catch {
                preconditionFailure("Headless match cannot pause: \(error)")
            }
        }
        guard let completion = state.completion else {
            preconditionFailure("Completed match did not produce a receipt")
        }
        return completion
    }

    private static func prepareDriveIfNeeded(state: inout MatchSessionState) {
        guard state.currentDrive == nil else { return }
        let driveSeed = SeededRandom.derive(from: state.seed, scope: .drive,
                                            ordinal: state.nextDriveIndex)
        state.currentDrive = DriveEngine.begin(
            from: state.situation,
            driveSeed: driveSeed,
            isAfterTurnover: state.afterTurnover,
            clockRunning: state.clockRunning
        )
    }

    private static func callInProposal(state: MatchSessionState) -> TacticalCallInProposal? {
        guard let controlledSide = state.controlledSide,
              state.isTakeover,
              state.callInReceipts.count < MatchupRules.maximumCallInsPerGame,
              let drive = state.currentDrive,
              drive.ending == nil else { return nil }
        let situation = drive.situation
        guard situation.possession == controlledSide else { return nil }
        let plan = controlledSide == .home ? state.homePlan : state.awayPlan
        let opponent = controlledSide == .home ? state.awayPlan : state.homePlan
        return TacticalCallInSystem.proposal(
            for: situation,
            plan: plan,
            opponentPlan: opponent,
            isAfterTurnover: drive.afterTurnover,
            rules: state.tier.clockRules
        )
    }

    private static func chooseCallIn(
        _ action: TacticalCallInAction,
        state: inout MatchSessionState,
        callerOverride: (any PlayCaller)?
    ) throws -> MatchStepReceipt {
        guard let proposal = state.pendingCallIn else {
            throw MatchReducerError.noPendingCallIn
        }
        guard state.isTakeover,
              let controlledSide = state.controlledSide,
              proposal.situation.possession == controlledSide,
              let drive = state.currentDrive,
              drive.ending == nil,
              drive.situation == proposal.situation,
              state.callInReceipts.count < MatchupRules.maximumCallInsPerGame else {
            throw MatchReducerError.invalidCallInState
        }
        guard let option = proposal.options.first(where: { $0.action == action }) else {
            throw MatchReducerError.unavailableCallIn(action)
        }
        let side = proposal.situation.possession
        if side == .home {
            state.homePlan = option.plan
        } else {
            state.awayPlan = option.plan
        }
        let receipt = MatchCallInReceipt(side: side, situation: proposal.situation,
                                        action: action, trigger: proposal.trigger)
        state.callInReceipts.append(receipt)
        state.pendingCallIn = nil
        return try resolveSnap(state: &state, callerOverride: callerOverride,
                               callInTrigger: proposal.trigger, callInReceipt: receipt)
    }

    private static func resolveSnap(
        state: inout MatchSessionState,
        callerOverride: (any PlayCaller)?,
        callInTrigger: CallInTrigger? = nil,
        callInReceipt: MatchCallInReceipt? = nil
    ) throws -> MatchStepReceipt {
        guard var drive = state.currentDrive else {
            throw MatchReducerError.noPendingCallIn
        }
        let possession = drive.situation.possession
        let offense = possession == .home ? state.home : state.away
        let defense = possession == .home ? state.away : state.home
        let caller: any PlayCaller = callerOverride ?? MatchPlayCaller(
            offensivePlan: possession == .home ? state.homePlan : state.awayPlan,
            defensivePlan: possession == .home ? state.awayPlan : state.homePlan
        )
        let play = DriveEngine.step(
            &drive,
            offense: offense,
            defense: defense,
            caller: caller,
            rules: state.tier.clockRules,
            homeFieldAdvantage: state.homeFieldAdvantage,
            callInTrigger: callInTrigger
        )
        state.situation = drive.situation
        state.currentDrive = drive
        guard drive.ending != nil else {
            return MatchStepReceipt(boundary: .snap, play: play, callIn: callInReceipt)
        }

        let finished = DriveEngine.finish(drive)
        state.drives.append(finished.drive)
        state.situation = finished.next
        state.currentDrive = nil
        state.nextDriveIndex += 1
        state.afterTurnover = finished.drive.ending == .turnover
            || finished.drive.ending == .downs
        state.clockRunning = finished.drive.ending == .endOfQuarter

        let priorQuarter = state.situation.quarter
        var crossedHalf = false
        while state.situation.secondsRemainingInQuarter <= 0,
              state.situation.quarter < state.tier.clockRules.quarters {
            state.situation.quarter += 1
            state.situation.secondsRemainingInQuarter += state.tier.clockRules.quarterSeconds
            if state.situation.quarter == state.tier.clockRules.quarters / 2 + 1 {
                state.situation.timeoutsRemaining = [
                    .home: state.tier.clockRules.timeoutsPerHalf,
                    .away: state.tier.clockRules.timeoutsPerHalf
                ]
                state.situation.possession = state.situation.possession.opponent
                state.situation.yardLine = MatchupRules.kickoffTouchbackYardLine
                state.situation.down = 1
                state.situation.distance = MatchupRules.yardsForFirstDown
                state.clockRunning = false
                state.afterTurnover = false
                crossedHalf = true
            }
        }
        if let boundary = progressAfterDrive(
            state: &state,
            completedDrive: finished.drive
        ) {
            if boundary == .completed {
                markCompleted(state: &state)
            }
            let completion = state.completion
            return MatchStepReceipt(
                boundary: boundary,
                play: play,
                callIn: callInReceipt,
                completion: completion
            )
        }
        let boundary: MatchPauseBoundary
        if crossedHalf {
            boundary = .halftime
        } else if state.situation.quarter != priorQuarter {
            boundary = .quarter
        } else {
            boundary = .drive
        }
        return MatchStepReceipt(boundary: boundary, play: play, callIn: callInReceipt)
    }

    private static func progressAfterDrive(
        state: inout MatchSessionState,
        completedDrive: DriveRecord
    ) -> MatchPauseBoundary? {
        let rules = state.tier.clockRules
        let regulationEnded = state.overtimePeriod == 0
            && state.situation.quarter >= rules.quarters
            && state.situation.secondsRemainingInQuarter <= 0

        if state.overtimePeriod == 0, regulationEnded {
            guard state.situation.homeScore == state.situation.awayScore else {
                return .completed
            }
            beginOvertime(state: &state)
            return .overtime
        }

        guard state.overtimePeriod > 0 else {
            guard state.nextDriveIndex >= MatchupRules.maximumDrivesPerGame else {
                return nil
            }
            if state.situation.homeScore == state.situation.awayScore,
               requiresWinner(state) {
                applyOvertimeTiebreak(state: &state)
            }
            return .completed
        }

        switch rules.overtime {
        case .alternatingPossessions:
            state.overtimePossessions[completedDrive.offense, default: 0] += 1
            guard state.overtimePossessions.values.allSatisfy({ $0 >= 1 }) else {
                return nil
            }
            if state.situation.homeScore != state.situation.awayScore {
                return .completed
            }
            guard state.overtimePeriod < CompetitionRules.maximumOvertimePeriods else {
                if requiresWinner(state) {
                    applyOvertimeTiebreak(state: &state)
                }
                return .completed
            }
            beginOvertime(state: &state)
            return .overtime

        case .timedPeriod:
            state.clockRunning = state.situation.secondsRemainingInQuarter > 0
            guard state.situation.secondsRemainingInQuarter <= 0
                    || state.nextDriveIndex >= MatchupRules.maximumDrivesPerGame else {
                return nil
            }
            if state.situation.homeScore != state.situation.awayScore {
                return .completed
            }
            guard state.overtimePeriod < CompetitionRules.maximumOvertimePeriods else {
                return requiresWinner(state) ? forceWinner(state: &state) : .completed
            }
            beginOvertime(state: &state)
            return .overtime
        }
    }

    private static func beginOvertime(state: inout MatchSessionState) {
        state.overtimePeriod += 1
        state.overtimePossessions = [:]
        state.currentDrive = nil
        state.afterTurnover = false
        state.clockRunning = state.tier.clockRules.overtime == .timedPeriod
        state.situation.quarter = state.tier.clockRules.quarters + state.overtimePeriod
        state.situation.secondsRemainingInQuarter = CompetitionRules.overtimePeriodSeconds
        state.situation.possession = .home
        state.situation.yardLine = CompetitionRules.overtimePossessionYardLine
        state.situation.down = 1
        state.situation.distance = MatchupRules.yardsForFirstDown
        state.situation.timeoutsRemaining = [.home: 1, .away: 1]
    }

    private static func forceWinner(state: inout MatchSessionState) -> MatchPauseBoundary {
        applyOvertimeTiebreak(state: &state)
        return .completed
    }

    private static func requiresWinner(_ state: MatchSessionState) -> Bool {
        state.tier == .college || state.stage != .regularSeason
    }

    private static func applyOvertimeTiebreak(state: inout MatchSessionState) {
        let tiebreakSeed = SeededRandom.derive(
            from: state.seed,
            scope: .overtime,
            ordinal: state.overtimePeriod
        )
        let winner: Side = tiebreakSeed.isMultiple(of: 2) ? .home : .away
        let points = CompetitionRules.overtimeFieldGoalPoints
        if winner == .home {
            state.situation.homeScore += points
        } else {
            state.situation.awayScore += points
        }
        // The normal path has room for this explicit bounded tiebreak drive. If a malformed or
        // hostile checkpoint has already exhausted the drive budget, keep the score correction
        // bounded rather than appending a record that would make the checkpoint undecodable.
        if state.drives.count < MatchupRules.maximumDrivesPerGame {
            state.drives.append(DriveRecord(
                offense: winner,
                plays: [],
                ending: .fieldGoal,
                pointsScored: points,
                startYardLine: CompetitionRules.overtimePossessionYardLine
            ))
            state.nextDriveIndex += 1
        }
    }

    private static func markCompleted(state: inout MatchSessionState) {
        state.completed = true
        let record = GameRecord(
            homeScore: state.situation.homeScore,
            awayScore: state.situation.awayScore,
            drives: state.drives,
            tier: state.tier
        )
        state.completedEvidence = GameEvidence(
            fixtureID: state.fixtureID,
            record: record,
            homeParticipantIDs: state.home.offense.map(\.id) + state.home.defense.map(\.id),
            awayParticipantIDs: state.away.offense.map(\.id) + state.away.defense.map(\.id),
            callInReceipts: state.callInReceipts
        )
    }
}
