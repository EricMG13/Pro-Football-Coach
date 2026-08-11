import Foundation

public struct ProgrammeProspectRelationship: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { prospectID }
    public let prospectID: UUID
    public var interest: Int
    public var contactPointsInvested: Int
    public var visitScheduled: Bool
    public var scholarshipOffered: Bool
    public var lastExplanation: [RecruitingScoreComponent]

    public init(
        prospectID: UUID,
        interest: Int = 0,
        contactPointsInvested: Int = 0,
        visitScheduled: Bool = false,
        scholarshipOffered: Bool = false,
        lastExplanation: [RecruitingScoreComponent] = []
    ) {
        self.prospectID = prospectID
        self.interest = min(max(0, interest), 100)
        self.contactPointsInvested = max(0, contactPointsInvested)
        self.visitScheduled = visitScheduled
        self.scholarshipOffered = scholarshipOffered
        self.lastExplanation = Array(lastExplanation.prefix(RecruitingPitch.allCases.count))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedInterest = try container.decode(Int.self, forKey: .interest)
        let decodedContact = try container.decode(Int.self, forKey: .contactPointsInvested)
        let decodedExplanation = try container.decode(
            [RecruitingScoreComponent].self,
            forKey: .lastExplanation
        )
        guard (0...100).contains(decodedInterest),
              (0...CollegeRules.maximumSeasonRecruitingContactPoints).contains(decodedContact),
              decodedExplanation.count <= RecruitingPitch.allCases.count,
              Set(decodedExplanation.map(\.reason)).count == decodedExplanation.count else {
            throw DecodingError.dataCorruptedError(
                forKey: .interest,
                in: container,
                debugDescription: "Recruiting relationship resources are outside their bounds."
            )
        }
        prospectID = try container.decode(UUID.self, forKey: .prospectID)
        interest = decodedInterest
        contactPointsInvested = decodedContact
        visitScheduled = try container.decode(Bool.self, forKey: .visitScheduled)
        scholarshipOffered = try container.decode(Bool.self, forKey: .scholarshipOffered)
        lastExplanation = decodedExplanation
    }
}

public struct ProgrammeRecruitingState: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { programmeID }
    public let programmeID: UUID
    public private(set) var boardIDs: [UUID]
    public private(set) var relationships: [UUID: ProgrammeProspectRelationship]
    public private(set) var scholarshipPlayerIDs: [UUID]
    public private(set) var contactPointsRemaining: Int
    public private(set) var nilState: ProgrammeNILState

    public init(
        programmeID: UUID,
        boardIDs: [UUID] = [],
        relationships: [UUID: ProgrammeProspectRelationship] = [:],
        scholarshipPlayerIDs: [UUID] = [],
        contactPointsRemaining: Int = CollegeRules.weeklyRecruitingContactPoints,
        nilState: ProgrammeNILState? = nil
    ) {
        self.programmeID = programmeID
        self.boardIDs = Self.uniquePrefix(boardIDs, limit: CollegeRules.recruitingBoardLimit)
        self.relationships = relationships
        self.scholarshipPlayerIDs = Self.uniquePrefix(
            scholarshipPlayerIDs,
            limit: CollegeRules.scholarshipLimit
        )
        self.contactPointsRemaining = min(
            max(0, contactPointsRemaining),
            CollegeRules.weeklyRecruitingContactPoints
        )
        self.nilState = nilState ?? ProgrammeNILState(
            programmeID: programmeID,
            season: 0,
            annualBudget: 0
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedBoard = try container.decode([UUID].self, forKey: .boardIDs)
        let decodedRelationships = try container.decode(
            [UUID: ProgrammeProspectRelationship].self,
            forKey: .relationships
        )
        let decodedScholarships = try container.decode(
            [UUID].self,
            forKey: .scholarshipPlayerIDs
        )
        let decodedContact = try container.decode(Int.self, forKey: .contactPointsRemaining)
        let decodedNIL = try container.decode(ProgrammeNILState.self, forKey: .nilState)
        let decodedProgrammeID = try container.decode(UUID.self, forKey: .programmeID)
        guard decodedBoard.count <= CollegeRules.recruitingBoardLimit,
              Set(decodedBoard).count == decodedBoard.count,
              decodedScholarships.count <= CollegeRules.scholarshipLimit,
              Set(decodedScholarships).count == decodedScholarships.count,
              decodedRelationships.allSatisfy({ $0.key == $0.value.prospectID }),
              (0...CollegeRules.weeklyRecruitingContactPoints).contains(decodedContact),
              decodedNIL.programmeID == decodedProgrammeID
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .boardIDs,
                in: container,
                debugDescription: "Programme recruiting state violates identity or resource bounds."
            )
        }
        programmeID = decodedProgrammeID
        boardIDs = decodedBoard
        relationships = decodedRelationships
        scholarshipPlayerIDs = decodedScholarships
        contactPointsRemaining = decodedContact
        nilState = decodedNIL
    }

    private static func uniquePrefix(_ ids: [UUID], limit: Int) -> [UUID] {
        var seen: Set<UUID> = []
        return ids.filter { seen.insert($0).inserted }.prefix(limit).map { $0 }
    }

    mutating func reconcileScholarships(with rosterIDs: [UUID], targetCount: Int) {
        let legalTarget = min(
            max(0, targetCount),
            CollegeRules.scholarshipLimit,
            rosterIDs.count
        )
        let rosterSet = Set(rosterIDs)
        var reconciled = Array(scholarshipPlayerIDs.filter(rosterSet.contains).prefix(legalTarget))
        var seen = Set(reconciled)
        for id in rosterIDs.reversed()
            where reconciled.count < legalTarget
                && seen.insert(id).inserted {
            reconciled.append(id)
        }
        scholarshipPlayerIDs = reconciled
    }

    mutating func addScholarshipPlayer(_ playerID: UUID) -> Bool {
        guard scholarshipPlayerIDs.count < CollegeRules.scholarshipLimit,
              !scholarshipPlayerIDs.contains(playerID) else { return false }
        scholarshipPlayerIDs.append(playerID)
        return true
    }

    mutating func removeScholarshipPlayer(_ playerID: UUID) -> Bool {
        guard let index = scholarshipPlayerIDs.firstIndex(of: playerID) else { return false }
        scholarshipPlayerIDs.remove(at: index)
        return true
    }

    mutating func addToBoard(
        prospectID: UUID,
        relationship: ProgrammeProspectRelationship
    ) -> Bool {
        guard boardIDs.count < CollegeRules.recruitingBoardLimit,
              !boardIDs.contains(prospectID),
              relationships[prospectID] == nil else { return false }
        boardIDs.append(prospectID)
        relationships[prospectID] = relationship
        return true
    }

    mutating func spendContactPoints(_ points: Int) -> Bool {
        guard points > 0, points <= contactPointsRemaining else { return false }
        contactPointsRemaining -= points
        return true
    }

    mutating func updateRelationship(
        _ prospectID: UUID,
        _ mutation: (inout ProgrammeProspectRelationship) -> Void
    ) -> Bool {
        guard var relationship = relationships[prospectID] else { return false }
        mutation(&relationship)
        guard relationship.prospectID == prospectID else { return false }
        relationships[prospectID] = relationship
        return true
    }

    mutating func setNILAllocation(_ amount: Int, prospectID: UUID) -> Bool {
        guard relationships[prospectID] != nil else { return false }
        var nextNIL = nilState
        guard nextNIL.setRecruitingReservation(amount, for: prospectID) else { return false }
        nilState = nextNIL
        return true
    }

    mutating func withdraw(_ prospectID: UUID) -> Bool {
        guard relationships[prospectID] != nil else { return false }
        var nextNIL = nilState
        _ = nextNIL.refundRecruitingReservation(for: prospectID)
        relationships.removeValue(forKey: prospectID)
        boardIDs.removeAll { $0 == prospectID }
        nilState = nextNIL
        return true
    }

    func nilAllocation(for prospectID: UUID) -> Int {
        nilState.recruitingReservations[prospectID] ?? 0
    }

    mutating func reclassifyNILReservation(prospectID: UUID, playerID: UUID) -> Bool {
        nilState.reclassifyRecruitingReservation(
            prospectID: prospectID,
            playerID: playerID
        )
    }

    mutating func refundNILReservation(for prospectID: UUID) {
        _ = nilState.refundRecruitingReservation(for: prospectID)
    }

    mutating func reconcileNILRosterAllocations(with rosterIDs: [UUID]) {
        nilState.retainRosterAllocations(for: Set(rosterIDs))
    }

    mutating func setRosterNILAllocation(_ amount: Int, playerID: UUID) -> Bool {
        nilState.setRosterAllocation(amount, for: playerID)
    }

    mutating func setPortalNILReservation(_ amount: Int, playerID: UUID) -> Bool {
        nilState.setPortalReservation(amount, for: playerID)
    }

    @discardableResult
    mutating func refundPortalNILReservation(for playerID: UUID) -> Int? {
        nilState.refundPortalReservation(for: playerID)
    }

    mutating func reclassifyPortalNILReservation(
        for playerID: UUID,
        expectedAmount: Int
    ) -> Bool {
        nilState.reclassifyPortalReservation(
            for: playerID,
            expectedAmount: expectedAmount
        )
    }

    @discardableResult
    mutating func removeRosterNILAllocation(for playerID: UUID) -> Int? {
        nilState.removeRosterAllocation(for: playerID)
    }

    mutating func resetWeeklyContactPoints() {
        contactPointsRemaining = CollegeRules.weeklyRecruitingContactPoints
    }
}

public enum RecruitingCyclePhase: String, Codable, Sendable, CaseIterable, Hashable {
    case active
    case signing
    case closed
}

public enum ProspectRecruitmentPhase: String, Codable, Sendable, CaseIterable, Hashable {
    case available
    case committed
    case signed
    case released
}

public struct RecruitingCommitmentContenderContext: Codable, Sendable, Equatable {
    public let programmeID: UUID
    public let score: Int
    public let explanation: [RecruitingScoreComponent]
    public let relationshipInterest: Int
    public let nilAllocation: Int
    public let visitScheduled: Bool

    public init(
        programmeID: UUID,
        score: Int,
        explanation: [RecruitingScoreComponent],
        relationshipInterest: Int,
        nilAllocation: Int,
        visitScheduled: Bool
    ) {
        self.programmeID = programmeID
        self.score = score
        self.explanation = Self.canonical(explanation)
        self.relationshipInterest = relationshipInterest
        self.nilAllocation = nilAllocation
        self.visitScheduled = visitScheduled
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedExplanation = try container.decode(
            [RecruitingScoreComponent].self,
            forKey: .explanation
        )
        let decodedInterest = try container.decode(Int.self, forKey: .relationshipInterest)
        let decodedNIL = try container.decode(Int.self, forKey: .nilAllocation)
        let decodedScore = try container.decode(Int.self, forKey: .score)
        guard Self.isValid(
            score: decodedScore,
            explanation: decodedExplanation,
            relationshipInterest: decodedInterest,
            nilAllocation: decodedNIL
        ), decodedExplanation == Self.canonical(decodedExplanation) else {
            throw DecodingError.dataCorruptedError(
                forKey: .score,
                in: container,
                debugDescription: "Commitment score context disagrees with its components."
            )
        }
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        score = decodedScore
        explanation = decodedExplanation
        relationshipInterest = decodedInterest
        nilAllocation = decodedNIL
        visitScheduled = try container.decode(Bool.self, forKey: .visitScheduled)
    }

    var isValid: Bool {
        Self.isValid(
            score: score,
            explanation: explanation,
            relationshipInterest: relationshipInterest,
            nilAllocation: nilAllocation
        )
    }

    private static func isValid(
        score: Int,
        explanation: [RecruitingScoreComponent],
        relationshipInterest: Int,
        nilAllocation: Int
    ) -> Bool {
        (0...100).contains(relationshipInterest)
            && (0...CollegeRules.maximumNILBudget).contains(nilAllocation)
            && explanation.count <= RecruitingPitch.allCases.count
            && Set(explanation.map(\.reason)).count == explanation.count
            && score == relationshipInterest
                + nilAllocation / CollegeRules.nilInterestPointsPerUnit
                + explanation.reduce(0) { $0 + $1.value }
    }

    private static func canonical(
        _ explanation: [RecruitingScoreComponent]
    ) -> [RecruitingScoreComponent] {
        RecruitingPitch.allCases.compactMap { reason in
            explanation.first { $0.reason == reason }
        }
    }
}

public struct RecruitingCommitmentContext: Codable, Sendable, Equatable {
    public let committedAt: CalendarState
    public let winner: RecruitingCommitmentContenderContext
    public let runnerUp: RecruitingCommitmentContenderContext?
    public let previousWinner: RecruitingCommitmentContenderContext?
    public let selectionReason: CommitmentSelectionReason

    public init(
        committedAt: CalendarState,
        winner: RecruitingCommitmentContenderContext,
        runnerUp: RecruitingCommitmentContenderContext? = nil,
        previousWinner: RecruitingCommitmentContenderContext? = nil,
        selectionReason: CommitmentSelectionReason = .normal
    ) {
        self.committedAt = committedAt
        self.winner = winner
        self.runnerUp = runnerUp
        self.previousWinner = previousWinner
        self.selectionReason = selectionReason
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedWinner = try container.decode(
            RecruitingCommitmentContenderContext.self,
            forKey: .winner
        )
        let decodedRunnerUp = try container.decodeIfPresent(
            RecruitingCommitmentContenderContext.self,
            forKey: .runnerUp
        )
        let decodedPreviousWinner = try container.decodeIfPresent(
            RecruitingCommitmentContenderContext.self,
            forKey: .previousWinner
        )
        guard decodedWinner.programmeID != decodedRunnerUp?.programmeID else {
            throw DecodingError.dataCorruptedError(
                forKey: .runnerUp,
                in: container,
                debugDescription: "Commitment winner and runner-up must be different programmes."
            )
        }
        committedAt = try container.decode(CalendarState.self, forKey: .committedAt)
        winner = decodedWinner
        runnerUp = decodedRunnerUp
        previousWinner = decodedPreviousWinner
        selectionReason = try container.decode(
            CommitmentSelectionReason.self,
            forKey: .selectionReason
        )
        guard isValid else {
            throw DecodingError.dataCorruptedError(
                forKey: .winner,
                in: container,
                debugDescription: "Commitment context violates ranking or flip causality."
            )
        }
    }

    var isValid: Bool {
        committedAt.week >= CollegeRules.minimumCommitmentWeek
            && winner.isValid
            && (runnerUp?.isValid ?? true)
            && (previousWinner?.isValid ?? true)
            && winner.programmeID != runnerUp?.programmeID
            && winner.programmeID != previousWinner?.programmeID
            && winner.score >= CollegeRules.minimumCommitmentScore
            && (runnerUp.map { $0.score >= CollegeRules.minimumCommitmentScore } ?? true)
            && (runnerUp.map { winner.score >= $0.score } ?? true)
            && (previousWinner.map {
                winner.score - $0.score
                    >= CollegeRules.minimumCommitmentFlipScoreImprovement
            } ?? true)
            && selectionReason.isValid(winner: winner, runnerUp: runnerUp)
    }
}

public enum CommitmentSelectionReason: Codable, Sendable, Equatable {
    case normal
    case capacityFallback(blockedPreferred: RecruitingCommitmentContenderContext)

    fileprivate func isValid(
        winner: RecruitingCommitmentContenderContext,
        runnerUp: RecruitingCommitmentContenderContext?
    ) -> Bool {
        switch self {
        case .normal:
            return true
        case let .capacityFallback(blockedPreferred):
            return blockedPreferred.isValid
                && blockedPreferred.score >= CollegeRules.minimumCommitmentScore
                && blockedPreferred.programmeID != winner.programmeID
                && blockedPreferred.programmeID != runnerUp?.programmeID
                && blockedPreferred.score >= winner.score
        }
    }
}

public enum CommitmentReleaseReason: String, Codable, Sendable, CaseIterable, Hashable {
    case scholarshipCapacityChanged
    case rosterCapacityChanged
    case minimumPositionCoverageRequired
}

public enum CommitmentTerminalOutcome: Codable, Sendable, Equatable {
    case signed
    case released(reason: CommitmentReleaseReason)
}

public struct ProspectRecruitmentState: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID { prospectID }
    public let prospectID: UUID
    public let phase: ProspectRecruitmentPhase
    public let commitmentHistory: [RecruitingCommitmentContext]
    public let releaseReason: CommitmentReleaseReason?

    public var commitmentContext: RecruitingCommitmentContext? { commitmentHistory.last }
    public var programmeID: UUID? { commitmentContext?.winner.programmeID }

    public init(
        prospectID: UUID,
        phase: ProspectRecruitmentPhase,
        commitmentHistory: [RecruitingCommitmentContext] = [],
        releaseReason: CommitmentReleaseReason? = nil
    ) {
        precondition(Self.hasValidShape(
            phase: phase,
            commitmentHistory: commitmentHistory,
            releaseReason: releaseReason
        ))
        self.prospectID = prospectID
        self.phase = phase
        self.commitmentHistory = commitmentHistory
        self.releaseReason = releaseReason
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPhase = try container.decode(ProspectRecruitmentPhase.self, forKey: .phase)
        let decodedHistory = try container.decodeIfPresent(
            [RecruitingCommitmentContext].self,
            forKey: .commitmentHistory
        ) ?? []
        let decodedReleaseReason = try container.decodeIfPresent(
            CommitmentReleaseReason.self,
            forKey: .releaseReason
        )
        guard Self.hasValidShape(
            phase: decodedPhase,
            commitmentHistory: decodedHistory,
            releaseReason: decodedReleaseReason
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .commitmentHistory,
                in: container,
                debugDescription: "Prospect phase and bounded commitment history disagree."
            )
        }
        prospectID = try container.decode(UUID.self, forKey: .prospectID)
        phase = decodedPhase
        commitmentHistory = decodedHistory
        releaseReason = decodedReleaseReason
    }

    var isValid: Bool {
        Self.hasValidShape(
            phase: phase,
            commitmentHistory: commitmentHistory,
            releaseReason: releaseReason
        )
    }

    private static func hasValidShape(
        phase: ProspectRecruitmentPhase,
        commitmentHistory: [RecruitingCommitmentContext],
        releaseReason: CommitmentReleaseReason?
    ) -> Bool {
        guard commitmentHistory.count <= CollegeRules.commitmentHistoryLimit,
              commitmentHistory.allSatisfy(\.isValid),
              commitmentHistory.first?.previousWinner == nil,
              zip(commitmentHistory, commitmentHistory.dropFirst()).allSatisfy({ previous, next in
                  let previousCalendar = (previous.committedAt.season, previous.committedAt.week)
                  let nextCalendar = (next.committedAt.season, next.committedAt.week)
                  return previousCalendar < nextCalendar
                      && previous.winner.programmeID != next.winner.programmeID
                      && next.previousWinner?.programmeID == previous.winner.programmeID
              }) else { return false }
        switch phase {
        case .available:
            return commitmentHistory.isEmpty && releaseReason == nil
        case .committed, .signed:
            return !commitmentHistory.isEmpty && releaseReason == nil
        case .released:
            return !commitmentHistory.isEmpty && releaseReason != nil
        }
    }
}

public struct CollegeState: Codable, Sendable, Equatable {
    public let recruitingSeason: Int
    public private(set) var portal: CollegePortalState
    public var phase: RecruitingCyclePhase
    public private(set) var programmes: [UUID: ProgrammeRecruitingState]
    public private(set) var prospectRecruitment: [UUID: ProspectRecruitmentState]
    public private(set) var archivedProspects: [UUID: ArchivedProspectIdentity]
    public private(set) var redshirtPlans: [UUID: RedshirtPlan]

    public init(
        recruitingSeason: Int,
        portal: CollegePortalState,
        phase: RecruitingCyclePhase = .active,
        programmes: [UUID: ProgrammeRecruitingState],
        prospectRecruitment: [UUID: ProspectRecruitmentState] = [:],
        archivedProspects: [UUID: ArchivedProspectIdentity] = [:],
        redshirtPlans: [UUID: RedshirtPlan] = [:]
    ) {
        precondition(
            recruitingSeason >= 0 && portal.targetSeason == recruitingSeason,
            "College state and portal must target the same nonnegative recruiting season."
        )
        self.recruitingSeason = recruitingSeason
        self.portal = portal
        self.phase = phase
        self.programmes = programmes
        self.prospectRecruitment = prospectRecruitment
        self.archivedProspects = archivedProspects
        self.redshirtPlans = redshirtPlans
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSeason = try container.decode(Int.self, forKey: .recruitingSeason)
        let decodedPortal = try container.decode(CollegePortalState.self, forKey: .portal)
        let decodedProgrammes = try container.decode(
            [UUID: ProgrammeRecruitingState].self,
            forKey: .programmes
        )
        let decodedRecruitment = try container.decode(
            [UUID: ProspectRecruitmentState].self,
            forKey: .prospectRecruitment
        )
        let decodedArchive = try container.decode(
            [UUID: ArchivedProspectIdentity].self,
            forKey: .archivedProspects
        )
        let decodedRedshirtPlans = try container.decode(
            [UUID: RedshirtPlan].self,
            forKey: .redshirtPlans
        )
        guard decodedSeason >= 0,
              decodedPortal.targetSeason == decodedSeason,
              decodedProgrammes.allSatisfy({ $0.key == $0.value.programmeID }),
              decodedRecruitment.allSatisfy({ $0.key == $0.value.prospectID }),
              decodedRecruitment.values.allSatisfy({ recruitment in
                  recruitment.isValid
                      && recruitment.commitmentHistory.allSatisfy { context in
                          context.committedAt.season == decodedSeason
                              && decodedProgrammes[context.winner.programmeID] != nil
                              && (context.runnerUp.map {
                                  decodedProgrammes[$0.programmeID] != nil
                              } ?? true)
                              && (context.previousWinner.map {
                                  decodedProgrammes[$0.programmeID] != nil
                              } ?? true)
                              && {
                                  if case let .capacityFallback(blockedPreferred)
                                    = context.selectionReason {
                                      return decodedProgrammes[blockedPreferred.programmeID] != nil
                                  }
                                  return true
                              }()
                      }
              }),
              decodedProgrammes.keys.allSatisfy({ programmeID in
                  decodedRecruitment.values.filter {
                      $0.programmeID == programmeID
                          && ($0.phase == .committed || $0.phase == .signed)
                  }.count <= CollegeRules.initialSigningsPerClass
              }),
              decodedArchive.count <= CollegeRules.maximumArchivedProspectIdentities,
              decodedArchive.allSatisfy({ $0.key == $0.value.id }),
              decodedRedshirtPlans.count
                <= CollegeRules.programmeCount * CollegeRules.rosterLimit,
              decodedRedshirtPlans.allSatisfy({
                  $0.key == $0.value.playerID
                      && $0.value.isStructurallyValid
                      && $0.value.season == decodedSeason
                      && decodedProgrammes[$0.value.programmeID] != nil
              }) else {
            throw DecodingError.dataCorruptedError(
                forKey: .programmes,
                in: container,
                debugDescription: "College-state keys disagree with their domain identities."
            )
        }
        recruitingSeason = decodedSeason
        portal = decodedPortal
        phase = try container.decode(RecruitingCyclePhase.self, forKey: .phase)
        programmes = decodedProgrammes
        prospectRecruitment = decodedRecruitment
        archivedProspects = decodedArchive
        redshirtPlans = decodedRedshirtPlans
    }

    public static func bootstrap(
        season: Int,
        programmes: [Programme],
        prospects: [Prospect] = []
    ) -> CollegeState {
        CollegeState(
            recruitingSeason: season,
            portal: CollegePortalState(targetSeason: season),
            programmes: Dictionary(uniqueKeysWithValues: programmes.map { programme in
                let scholarships = Array(
                    programme.rosterIDs.prefix(CollegeRules.scholarshipLimit)
                )
                return (
                    programme.id,
                    ProgrammeRecruitingState(
                        programmeID: programme.id,
                        scholarshipPlayerIDs: scholarships,
                        nilState: ProgrammeNILState(
                            programmeID: programme.id,
                            season: season,
                            annualBudget: programme.resources.value
                                * CollegeRules.nilBudgetPerResourcePoint
                        )
                    )
                )
            }),
            prospectRecruitment: Dictionary(uniqueKeysWithValues: prospects.map {
                ($0.id, ProspectRecruitmentState(prospectID: $0.id, phase: .available))
            })
        )
    }

    /// Keeps the M2 provisional intake bridge legal until M3 signing owns scholarship assignment.
    public mutating func reconcileScholarships(with programmeStore: EntityStore<Programme>) {
        for programme in programmeStore.values {
            guard var recruiting = programmes[programme.id] else { continue }
            recruiting.reconcileScholarships(
                with: programme.rosterIDs,
                targetCount: programme.scholarshipCount
            )
            recruiting.reconcileNILRosterAllocations(with: programme.rosterIDs)
            programmes[programme.id] = recruiting
        }
    }

    mutating func updateProgramme(
        _ id: UUID,
        _ mutation: (inout ProgrammeRecruitingState) -> Void
    ) -> Bool {
        guard var programme = programmes[id] else { return false }
        mutation(&programme)
        guard programme.programmeID == id else { return false }
        programmes[id] = programme
        return true
    }

    mutating func setRedshirtPlan(_ plan: RedshirtPlan) -> Bool {
        guard plan.isStructurallyValid,
              plan.season == recruitingSeason else { return false }
        redshirtPlans[plan.playerID] = plan
        return true
    }

    mutating func clearRedshirtPlan(playerID: UUID, programmeID: UUID) -> Bool {
        guard redshirtPlans[playerID]?.programmeID == programmeID else { return false }
        redshirtPlans.removeValue(forKey: playerID)
        return true
    }

    @discardableResult
    mutating func commit(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        reservationLimit: Int
    ) -> Bool {
        let programmeID = context.winner.programmeID
        guard phase == .active,
              context.isValid,
              context.committedAt.week >= CollegeRules.minimumCommitmentWeek,
              programmes[programmeID] != nil,
              context.committedAt.season == recruitingSeason,
              prospectRecruitment[prospectID]?.phase == .available,
              activeReservationCount(for: programmeID)
                < min(CollegeRules.initialSigningsPerClass, max(0, reservationLimit)) else {
            return false
        }
        prospectRecruitment[prospectID] = ProspectRecruitmentState(
            prospectID: prospectID,
            phase: .committed,
            commitmentHistory: [context]
        )
        return true
    }

    @discardableResult
    mutating func flip(
        prospectID: UUID,
        context: RecruitingCommitmentContext,
        reservationLimit: Int
    ) -> Bool {
        let programmeID = context.winner.programmeID
        guard phase == .active,
              context.isValid,
              context.committedAt.week >= CollegeRules.minimumCommitmentWeek,
              programmes[programmeID] != nil,
              context.committedAt.season == recruitingSeason,
              let existing = prospectRecruitment[prospectID],
              existing.phase == .committed,
              existing.programmeID != programmeID,
              existing.commitmentHistory.count < CollegeRules.commitmentHistoryLimit,
              activeReservationCount(for: programmeID)
                < min(CollegeRules.initialSigningsPerClass, max(0, reservationLimit)) else {
            return false
        }
        prospectRecruitment[prospectID] = ProspectRecruitmentState(
            prospectID: prospectID,
            phase: .committed,
            commitmentHistory: existing.commitmentHistory + [context]
        )
        return true
    }

    @discardableResult
    mutating func sign(prospectID: UUID, with programmeID: UUID) -> Bool {
        guard prospectRecruitment[prospectID]?.phase == .committed,
              prospectRecruitment[prospectID]?.programmeID == programmeID,
              signedCount(for: programmeID) < CollegeRules.initialSigningsPerClass,
              let history = prospectRecruitment[prospectID]?.commitmentHistory,
              var programme = programmes[programmeID],
              programme.addScholarshipPlayer(prospectID),
              programme.reclassifyNILReservation(
                  prospectID: prospectID,
                  playerID: prospectID
              ) else { return false }
        programmes[programmeID] = programme
        prospectRecruitment[prospectID] = ProspectRecruitmentState(
            prospectID: prospectID,
            phase: .signed,
            commitmentHistory: history
        )
        return true
    }

    @discardableResult
    mutating func release(
        prospectID: UUID,
        reason: CommitmentReleaseReason
    ) -> Bool {
        guard let recruitment = prospectRecruitment[prospectID],
              recruitment.phase == .committed,
              let programmeID = recruitment.programmeID,
              var programme = programmes[programmeID] else { return false }
        programme.refundNILReservation(for: prospectID)
        programmes[programmeID] = programme
        prospectRecruitment[prospectID] = ProspectRecruitmentState(
            prospectID: prospectID,
            phase: .released,
            commitmentHistory: recruitment.commitmentHistory,
            releaseReason: reason
        )
        return true
    }

    func activeReservationCount(for programmeID: UUID) -> Int {
        prospectRecruitment.values.filter {
            $0.programmeID == programmeID && ($0.phase == .committed || $0.phase == .signed)
        }.count
    }

    private func signedCount(for programmeID: UUID) -> Int {
        prospectRecruitment.values.filter {
            $0.programmeID == programmeID && $0.phase == .signed
        }.count
    }

    public mutating func resetWeeklyContactPoints() {
        for id in programmes.keys {
            programmes[id]?.resetWeeklyContactPoints()
        }
    }
}
