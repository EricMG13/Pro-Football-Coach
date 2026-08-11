import Foundation

public struct CollegeSigning: Codable, Sendable, Equatable {
    public let prospectID: UUID
    public let programmeID: UUID

    public init(prospectID: UUID, programmeID: UUID) {
        self.prospectID = prospectID
        self.programmeID = programmeID
    }
}

public struct CollegeCommitmentResolution: Codable, Sendable, Equatable {
    public let prospectID: UUID
    public let programmeID: UUID
    public let outcome: CommitmentTerminalOutcome

    public init(
        prospectID: UUID,
        programmeID: UUID,
        outcome: CommitmentTerminalOutcome
    ) {
        self.prospectID = prospectID
        self.programmeID = programmeID
        self.outcome = outcome
    }
}

public enum CollegeSigningError: Error, Sendable, Equatable {
    case missingProgramme(UUID)
    case missingRecruitingState(UUID)
    case missingProspect(UUID)
    case duplicatePlayer(UUID)
    case invalidCommitment(UUID)
    case classLimitExceeded(UUID)
    case stateMutationFailed(UUID)
    case terminalConservationFailed
}

public struct CollegeSigningTransition: Sendable, Equatable {
    public let programmes: EntityStore<Programme>
    public let players: EntityStore<Player>
    public let people: PeopleState
    public let college: CollegeState
    public let signings: [CollegeSigning]
    public let resolutions: [CollegeCommitmentResolution]
    public let eventPayloads: [DomainEventPayload]

    public init(
        programmes: EntityStore<Programme>,
        players: EntityStore<Player>,
        people: PeopleState,
        college: CollegeState,
        signings: [CollegeSigning],
        resolutions: [CollegeCommitmentResolution],
        eventPayloads: [DomainEventPayload]
    ) {
        self.programmes = programmes
        self.players = players
        self.people = people
        self.college = college
        self.signings = signings
        self.resolutions = resolutions
        self.eventPayloads = eventPayloads
    }
}

public enum CollegeSigningSystem {
    private struct Candidate {
        let recruitment: ProspectRecruitmentState
        let prospect: Prospect
    }

    public static func signCommitted(in state: GameState) throws -> CollegeSigningTransition {
        var programmes = state.programmes
        var players = state.players
        var people = state.people
        var college = state.college
        var signings: [CollegeSigning] = []
        var resolutions: [CollegeCommitmentResolution] = []
        var resolutionPayloads: [DomainEventPayload] = []
        var joinPayloads: [DomainEventPayload] = []
        let incomingCommitmentIDs = Set(college.prospectRecruitment.values.compactMap {
            $0.phase == .committed ? $0.prospectID : nil
        })

        for programmeID in state.programmes.ids {
            guard let programme = programmes[programmeID] else {
                throw CollegeSigningError.missingProgramme(programmeID)
            }
            guard let recruiting = college.programmes[programmeID] else {
                throw CollegeSigningError.missingRecruitingState(programmeID)
            }
            let rosterCounts = Dictionary(grouping: programme.rosterIDs.compactMap {
                players[$0]?.position
            }, by: { $0 }).mapValues(\.count)
            let candidates = try college.prospectRecruitment.values.compactMap {
                recruitment -> Candidate? in
                guard recruitment.phase == .committed,
                      recruitment.programmeID == programmeID else { return nil }
                guard recruitment.isValid,
                      recruitment.commitmentHistory.last?.winner.programmeID == programmeID else {
                    throw CollegeSigningError.invalidCommitment(recruitment.prospectID)
                }
                guard let prospect = state.prospects[recruitment.prospectID] else {
                    throw CollegeSigningError.missingProspect(recruitment.prospectID)
                }
                guard players[prospect.id] == nil else {
                    throw CollegeSigningError.duplicatePlayer(prospect.id)
                }
                return Candidate(recruitment: recruitment, prospect: prospect)
            }
            guard candidates.count <= CollegeRules.initialSigningsPerClass else {
                throw CollegeSigningError.classLimitExceeded(programmeID)
            }
            let ranked = candidates.sorted { lhs, rhs in
                let lhsMinimum = SharedRules.minimumPlayableRosterByPosition[
                    lhs.prospect.position
                ] ?? 0
                let rhsMinimum = SharedRules.minimumPlayableRosterByPosition[
                    rhs.prospect.position
                ] ?? 0
                let lhsMissing = (rosterCounts[lhs.prospect.position] ?? 0) < lhsMinimum
                let rhsMissing = (rosterCounts[rhs.prospect.position] ?? 0) < rhsMinimum
                if lhsMissing != rhsMissing { return lhsMissing }
                let lhsCalendar = lhs.recruitment.commitmentContext!.committedAt
                let rhsCalendar = rhs.recruitment.commitmentContext!.committedAt
                if lhsCalendar.season != rhsCalendar.season {
                    return lhsCalendar.season < rhsCalendar.season
                }
                if lhsCalendar.week != rhsCalendar.week {
                    return lhsCalendar.week < rhsCalendar.week
                }
                return lhs.prospect.id.uuidString < rhs.prospect.id.uuidString
            }
            let rosterVacancies = max(0, CollegeRules.rosterLimit - programme.rosterIDs.count)
            let scholarshipVacancies = max(
                0,
                CollegeRules.scholarshipLimit - recruiting.scholarshipPlayerIDs.count
            )
            let classVacancies = max(
                0,
                CollegeRules.initialSigningsPerClass
                    - college.prospectRecruitment.values.filter {
                        $0.programmeID == programmeID && $0.phase == .signed
                    }.count
            )
            var selectedIDs: Set<UUID> = []
            var selectedPositionCounts: [Position: Int] = [:]
            var releaseReasons: [UUID: CommitmentReleaseReason] = [:]

            for candidate in ranked {
                let selectedCount = selectedIDs.count
                if selectedCount >= scholarshipVacancies {
                    releaseReasons[candidate.prospect.id] = .scholarshipCapacityChanged
                    continue
                }
                if selectedCount >= rosterVacancies || selectedCount >= classVacancies {
                    releaseReasons[candidate.prospect.id] = .rosterCapacityChanged
                    continue
                }
                let rosterOpeningsAfter = rosterVacancies - selectedCount - 1
                let missingAfter = Position.allCases.reduce(0) { total, position in
                    let candidateAddition = candidate.prospect.position == position ? 1 : 0
                    let projectedCount = (rosterCounts[position] ?? 0)
                        + (selectedPositionCounts[position] ?? 0)
                        + candidateAddition
                    let minimum = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
                    return total + max(0, minimum - projectedCount)
                }
                guard missingAfter <= rosterOpeningsAfter else {
                    releaseReasons[candidate.prospect.id] = .minimumPositionCoverageRequired
                    continue
                }
                selectedIDs.insert(candidate.prospect.id)
                selectedPositionCounts[candidate.prospect.position, default: 0] += 1
            }

            for candidate in ranked {
                let prospect = candidate.prospect
                guard let relationship = recruiting.relationships[prospect.id],
                      let finalContext = candidate.recruitment.commitmentContext,
                      relationship.interest == finalContext.winner.relationshipInterest,
                      recruiting.nilAllocation(for: prospect.id)
                        == finalContext.winner.nilAllocation else {
                    throw CollegeSigningError.invalidCommitment(prospect.id)
                }
                let promisedNIL = recruiting.nilAllocation(for: prospect.id)
                guard selectedIDs.contains(prospect.id) else {
                    guard let reason = releaseReasons[prospect.id],
                          college.release(prospectID: prospect.id, reason: reason) else {
                        throw CollegeSigningError.stateMutationFailed(prospect.id)
                    }
                    let resolution = CollegeCommitmentResolution(
                        prospectID: prospect.id,
                        programmeID: programmeID,
                        outcome: .released(reason: reason)
                    )
                    resolutions.append(resolution)
                    resolutionPayloads.append(.commitmentResolved(
                        prospectID: prospect.id,
                        programmeID: programmeID,
                        outcome: resolution.outcome
                    ))
                    continue
                }
                let player = Player(
                    id: prospect.id,
                    firstName: prospect.firstName,
                    lastName: prospect.lastName,
                    position: prospect.position,
                    age: prospect.age,
                    attributes: prospect.attributes,
                    potential: prospect.potential,
                    traits: prospect.traits,
                    eligibility: Eligibility()
                )
                guard college.sign(prospectID: prospect.id, with: programmeID) else {
                    throw CollegeSigningError.stateMutationFailed(prospect.id)
                }
                players.insert(player)
                people.insert(
                    player: player,
                    recruitingOrigin: PlayerRecruitingOrigin(
                        originCityID: prospect.originCityID,
                        commitmentHistory: candidate.recruitment.commitmentHistory,
                        signedAt: state.calendar,
                        finalInterest: relationship.interest,
                        finalNILAllocation: promisedNIL,
                        overallAtSigning: prospect.overall,
                        recruitingPriorities: prospect.priorities
                    )
                )
                guard programmes.update(programmeID, {
                    $0.rosterIDs.append(player.id)
                    $0.scholarshipCount += 1
                }) else { throw CollegeSigningError.stateMutationFailed(prospect.id) }
                signings.append(CollegeSigning(
                    prospectID: prospect.id,
                    programmeID: programmeID
                ))
                let resolution = CollegeCommitmentResolution(
                    prospectID: prospect.id,
                    programmeID: programmeID,
                    outcome: .signed
                )
                resolutions.append(resolution)
                resolutionPayloads.append(.commitmentResolved(
                    prospectID: prospect.id,
                    programmeID: programmeID,
                    outcome: .signed
                ))
                joinPayloads.append(.playerJoined(
                    playerID: player.id,
                    organisationID: programmeID,
                    source: .recruitedScholarship
                ))
            }
        }

        guard resolutions.count == incomingCommitmentIDs.count,
              Set(resolutions.map(\.prospectID)) == incomingCommitmentIDs else {
            throw CollegeSigningError.terminalConservationFailed
        }

        return CollegeSigningTransition(
            programmes: programmes,
            players: players,
            people: people,
            college: college,
            signings: signings,
            resolutions: resolutions,
            eventPayloads: resolutionPayloads + joinPayloads
        )
    }
}
