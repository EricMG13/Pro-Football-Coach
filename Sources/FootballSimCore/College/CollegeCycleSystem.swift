import Foundation

public struct CollegeCycleTransition: Sendable, Equatable {
    public let programmes: EntityStore<Programme>
    public let players: EntityStore<Player>
    public let people: PeopleState
    public let prospects: EntityStore<Prospect>
    public let college: CollegeState
    public let scouting: ScoutingState
    public let commitmentResolutions: [CollegeCommitmentResolution]
    public let eventPayloads: [DomainEventPayload]

    public init(
        programmes: EntityStore<Programme>,
        players: EntityStore<Player>,
        people: PeopleState,
        prospects: EntityStore<Prospect>,
        college: CollegeState,
        scouting: ScoutingState,
        commitmentResolutions: [CollegeCommitmentResolution],
        eventPayloads: [DomainEventPayload]
    ) {
        self.programmes = programmes
        self.players = players
        self.people = people
        self.prospects = prospects
        self.college = college
        self.scouting = scouting
        self.commitmentResolutions = commitmentResolutions
        self.eventPayloads = eventPayloads
    }
}

public enum CollegeWalkOnWindow: Int, Sendable, Equatable {
    case postseasonCoverage = 1
    case springRosterFill = 2
}

public struct CollegeWalkOnTransition: Sendable, Equatable {
    public let programmes: EntityStore<Programme>
    public let players: EntityStore<Player>
    public let people: PeopleState
    public let eventPayloads: [DomainEventPayload]

    public init(
        programmes: EntityStore<Programme>,
        players: EntityStore<Player>,
        people: PeopleState,
        eventPayloads: [DomainEventPayload]
    ) {
        self.programmes = programmes
        self.players = players
        self.people = people
        self.eventPayloads = eventPayloads
    }
}

public enum CollegeCycleSystem {
    static func hotProspectIDs(in history: DomainEventLedger) -> Set<UUID> {
        Set((history.recent + history.archive.flatMap(\.notableEvents))
            .flatMap { $0.payload.referencedProspectIDs })
    }

    /// Removes compact former-prospect identities once no retained event body references them.
    /// Rollover owns creation because it still has the outgoing full prospect identity.
    static func pruningArchivedProspects(in state: GameState) -> CollegeState {
        let referencedIDs = hotProspectIDs(in: state.history)
        let retainedArchive = state.college.archivedProspects.filter {
            referencedIDs.contains($0.key)
        }
        guard retainedArchive.count != state.college.archivedProspects.count else {
            return state.college
        }
        return CollegeState(
            recruitingSeason: state.college.recruitingSeason,
            portal: state.college.portal,
            phase: state.college.phase,
            programmes: state.college.programmes,
            prospectRecruitment: state.college.prospectRecruitment,
            archivedProspects: retainedArchive,
            redshirtPlans: state.college.redshirtPlans
        )
    }

    public static func closeAndOpen(
        nextSeason: Int,
        in state: GameState
    ) throws -> CollegeCycleTransition {
        let signing = try CollegeSigningSystem.signCommitted(in: state)
        let programmes = signing.programmes
        let players = signing.players
        let people = signing.people

        let referencedIDs = hotProspectIDs(in: state.history).union(
            signing.eventPayloads.flatMap(\.referencedProspectIDs)
        )
        var archive = state.college.archivedProspects.filter {
            referencedIDs.contains($0.key)
        }
        for prospect in state.prospects.values
            where players[prospect.id] == nil && referencedIDs.contains(prospect.id) {
            archive[prospect.id] = ArchivedProspectIdentity(
                prospect: prospect,
                recruitingSeason: state.college.recruitingSeason
            )
        }
        let nextProspects = ProspectPopulationGenerator.generate(
            rootSeed: state.league.seed,
            season: nextSeason,
            map: state.map
        )
        let programmeStates = Dictionary(uniqueKeysWithValues: programmes.values.map { programme in
            let previousRecruiting = signing.college.programmes[programme.id]
            let scholarshipIDs = previousRecruiting?.scholarshipPlayerIDs
                .filter { programme.rosterIDs.contains($0) } ?? []
            let rosterSet = Set(programme.rosterIDs)
            let retainedRosterNIL = previousRecruiting?.nilState.rosterAllocations.filter {
                rosterSet.contains($0.key)
            } ?? [:]
            return (
                programme.id,
                ProgrammeRecruitingState(
                    programmeID: programme.id,
                    scholarshipPlayerIDs: scholarshipIDs,
                    nilState: ProgrammeNILState(
                        programmeID: programme.id,
                        season: nextSeason,
                        annualBudget: programme.resources.value
                            * CollegeRules.nilBudgetPerResourcePoint,
                        rosterAllocations: retainedRosterNIL
                    )
                )
            )
        })
        let college = CollegeState(
            recruitingSeason: nextSeason,
            portal: CollegePortalState(targetSeason: nextSeason),
            phase: .active,
            programmes: programmeStates,
            prospectRecruitment: Dictionary(uniqueKeysWithValues: nextProspects.map {
                ($0.id, ProspectRecruitmentState(prospectID: $0.id, phase: .available))
            }),
            archivedProspects: archive,
            redshirtPlans: [:]
        )
        return CollegeCycleTransition(
            programmes: programmes,
            players: players,
            people: people,
            prospects: EntityStore(nextProspects),
            college: college,
            scouting: ScoutingState(),
            commitmentResolutions: signing.resolutions,
            eventPayloads: signing.eventPayloads
        )
    }

    public static func addWalkOns(
        for window: CollegeWalkOnWindow,
        season: Int,
        in state: GameState
    ) -> CollegeWalkOnTransition {
        var programmes = state.programmes
        var players = state.players
        var people = state.people
        var payloads: [DomainEventPayload] = []
        let ordinalBase = window.rawValue * 1_000_000
        var reservedIdentityIDs = Set(state.players.ids)
            .union([state.league.id])
            .union(state.league.conferences.map(\.id))
            .union(state.league.divisions.map(\.id))
            .union(state.prospects.ids)
            .union(state.staff.ids)
            .union(state.programmes.ids)
            .union(state.proTeams.ids)
            .union(state.identities.keys)
            .union(state.rivalries.ids)
            .union(state.map.regions.map(\.id))
            .union(state.map.cities.map(\.id))
            .union(state.competition.currentSchedule.games.map(\.id))
            .union(state.history.recent.map(\.id))
            .union(state.history.recent.flatMap(\.payload.referencedEntityIDs))
            .union(state.history.recent.flatMap(\.payload.referencedProspectIDs))
            .union(state.pending.mandatoryDecisions.map(\.id))
            .union(state.people.playerLifecycle.keys)
            .union(state.people.playerCareers.keys)
            .union(state.people.staffCareers.keys)
            .union(state.people.departedPlayers.keys)
            .union(state.college.archivedProspects.keys)

        for programmeID in programmes.ids {
            guard let programme = programmes[programmeID] else { continue }
            var rosterIDs = programme.rosterIDs
            var ordinal = 0
            func countsByPosition() -> [Position: Int] {
                Dictionary(grouping: rosterIDs.compactMap {
                    players[$0]?.position
                }, by: { $0 }).mapValues(\.count)
            }
            func appendWalkOn(at position: Position) {
                while true {
                    let walkOn = RosterPopulationGenerator.walkOn(
                        rootSeed: state.league.seed,
                        season: season,
                        organisationID: programmeID,
                        position: position,
                        ordinal: ordinalBase + ordinal,
                        prestige: programme.prestige
                    )
                    ordinal += 1
                    guard reservedIdentityIDs.insert(walkOn.id).inserted else { continue }
                    players.insert(walkOn)
                    people.insert(player: walkOn)
                    rosterIDs.append(walkOn.id)
                    payloads.append(.playerJoined(
                        playerID: walkOn.id,
                        organisationID: programmeID,
                        source: .walkOn
                    ))
                    return
                }
            }

            switch window {
            case .postseasonCoverage:
                for position in Position.allCases {
                    let minimum = SharedRules.minimumPlayableRosterByPosition[position] ?? 0
                    while (countsByPosition()[position] ?? 0) < minimum {
                        appendWalkOn(at: position)
                    }
                }
            case .springRosterFill:
                while rosterIDs.count < CollegeRules.rosterLimit {
                    let counts = countsByPosition()
                    let position = Position.allCases.min { lhs, rhs in
                        let lhsTarget = max(1, CollegeRules.initialRosterByPosition[lhs] ?? 1)
                        let rhsTarget = max(1, CollegeRules.initialRosterByPosition[rhs] ?? 1)
                        let lhsPressure = (counts[lhs] ?? 0) * 1_000 / lhsTarget
                        let rhsPressure = (counts[rhs] ?? 0) * 1_000 / rhsTarget
                        if lhsPressure != rhsPressure { return lhsPressure < rhsPressure }
                        return lhs.rawValue < rhs.rawValue
                    }!
                    appendWalkOn(at: position)
                }
            }
            programmes.update(programmeID) { $0.rosterIDs = rosterIDs }
        }
        return CollegeWalkOnTransition(
            programmes: programmes,
            players: players,
            people: people,
            eventPayloads: payloads
        )
    }
}
