import Foundation

/// One coordinator changing hands.
public struct StaffPoaching: Sendable, Equatable {
    public let staffID: UUID
    public let fromOrganisationID: UUID
    public let toOrganisationID: UUID
    /// The coach the poacher moved aside to make room. They are out of work, not deleted.
    public let displacedStaffID: UUID
    /// Who the losing organisation hired to fill the hole, the same season.
    public let replacementStaffID: UUID

    public init(
        staffID: UUID,
        fromOrganisationID: UUID,
        toOrganisationID: UUID,
        displacedStaffID: UUID,
        replacementStaffID: UUID
    ) {
        self.staffID = staffID
        self.fromOrganisationID = fromOrganisationID
        self.toOrganisationID = toOrganisationID
        self.displacedStaffID = displacedStaffID
        self.replacementStaffID = replacementStaffID
    }
}

public struct StaffPoachingTransition: Sendable, Equatable {
    public let state: GameState
    public let poachings: [StaffPoaching]
    public let eventPayloads: [DomainEventPayload]

    public init(state: GameState, poachings: [StaffPoaching], eventPayloads: [DomainEventPayload]) {
        self.state = state
        self.poachings = poachings
        self.eventPayloads = eventPayloads
    }
}

/// Coordinators are poached when they perform. `02` §4.1, §6.1.
///
/// `Staff` has said since P3 that "staff are poached when they perform", §4.1 sells it as an
/// offseason beat, and §6.1 recorded the truth: **nothing ever came for anybody's staff.** Vacancies
/// were filled, ageing coaches retired, and no coordinator in the world ever moved for a better job.
/// That made continuity free — the resource §6 names cost nothing to hold.
///
/// **Atomic, and complete at every point.** Whole-root integrity requires complete role coverage on
/// every organisation, so a move that left a hole would be a world that cannot be saved. Each
/// poaching therefore does four things at once: the coordinator moves, the poacher's incumbent is
/// moved aside, the losing organisation hires a generated replacement, and both career records are
/// written.
///
/// **The coach's staff are not exempt, and that is the point.** §4.1's beat is that a coordinator who
/// wins for you gets taken. When the person poached held a delegated responsibility, the delegation
/// reverts to the coach rather than pointing at somebody who now works elsewhere — a dangling
/// delegation is an invalid root, and silently keeping it would be worse than the loss.
public enum StaffPoachingSystem {
    public static func process(
        after completed: CalendarState,
        in state: GameState
    ) -> StaffPoachingTransition {
        var next = state
        var poachings: [StaffPoaching] = []
        var payloads: [DomainEventPayload] = []
        // Nobody is moved twice in one offseason, in either direction: a coordinator who has just
        // taken a job is not immediately available, and an organisation that has just been raided
        // is not raided again before it has replaced anybody.
        var movedStaffIDs: Set<UUID> = []
        var touchedOrganisationIDs: Set<UUID> = []

        for candidate in candidates(in: state) {
            guard poachings.count < PeopleRules.maximumPoachingsPerSeason else { break }
            guard !movedStaffIDs.contains(candidate.staffID),
                  !touchedOrganisationIDs.contains(candidate.fromOrganisationID),
                  !touchedOrganisationIDs.contains(candidate.toOrganisationID) else { continue }
            guard let member = next.staff[candidate.staffID],
                  let incumbent = incumbent(
                      role: member.role,
                      positionGroup: member.positionGroup,
                      at: candidate.toOrganisationID,
                      in: next
                  ) else { continue }
            // A poacher whose own man is better does not want yours. Checked here rather than in
            // the candidate scan because the scan runs against the world before any move.
            guard member.reputation.value > incumbent.reputation.value else { continue }

            let replacement = StaffPopulationGenerator.replacement(
                rootSeed: next.league.seed,
                season: completed.season + 1,
                organisationID: candidate.fromOrganisationID,
                prestige: prestige(of: candidate.fromOrganisationID, in: next),
                role: member.role,
                positionGroup: member.positionGroup,
                // Past every ordinal `resolvedStaffIDs` uses for its vacancies, so a replacement
                // hired here and one hired there are never the same generated person.
                ordinal: PeopleRules.staffPerOrganisation + poachings.count
            )

            // 1. The poacher's incumbent is out of work. Not deleted: an unemployed coach is a
            //    legal thing in this world — that is what an aged-out coordinator already becomes —
            //    and deleting them would take their career record with them.
            setStaffIDs(at: candidate.toOrganisationID, in: &next) { ids in
                ids.removeAll { $0 == incumbent.id }
                ids.append(member.id)
            }
            // 2. The coordinator moves, and starts again at nothing: continuity is a resource you
            //    hold, not one you carry with you.
            setStaffIDs(at: candidate.fromOrganisationID, in: &next) { ids in
                ids.removeAll { $0 == member.id }
                ids.append(replacement.id)
            }
            next.staff.update(member.id) { $0.seasonsWithProgramme = 0 }
            next.staff.insert(replacement)
            next.people.updateStaffCareer(member.id) {
                $0.append(StaffCareerAssignment(
                    season: completed.season + 1,
                    organisationID: candidate.toOrganisationID,
                    role: member.role
                ))
            }
            next.people.insert(
                staff: replacement,
                assignment: StaffCareerAssignment(
                    season: completed.season + 1,
                    organisationID: candidate.fromOrganisationID,
                    role: replacement.role
                )
            )
            // 3. A delegation that pointed at the person who just left now points at nobody, which
            //    is an invalid root. The coach takes the responsibility back.
            reclaimDelegations(of: member.id, in: &next)

            movedStaffIDs.insert(member.id)
            touchedOrganisationIDs.insert(candidate.fromOrganisationID)
            touchedOrganisationIDs.insert(candidate.toOrganisationID)
            poachings.append(StaffPoaching(
                staffID: member.id,
                fromOrganisationID: candidate.fromOrganisationID,
                toOrganisationID: candidate.toOrganisationID,
                displacedStaffID: incumbent.id,
                replacementStaffID: replacement.id
            ))
            payloads.append(.staffHired(
                staffID: member.id,
                organisationID: candidate.toOrganisationID,
                role: member.role
            ))
            payloads.append(.staffHired(
                staffID: replacement.id,
                organisationID: candidate.fromOrganisationID,
                role: replacement.role
            ))
        }

        // Refused wholesale rather than partly applied. Every step above is meant to keep coverage
        // true, and if the result disagrees the honest answer is the world that did not move — a
        // half-applied offseason is the kind of corruption a save carries forever.
        guard WorldIntegrity.check(next).isValid else {
            return StaffPoachingTransition(state: state, poachings: [], eventPayloads: [])
        }
        return StaffPoachingTransition(state: next, poachings: poachings, eventPayloads: payloads)
    }

    // MARK: - Who is available, and who wants them

    struct Candidate {
        let staffID: UUID
        let fromOrganisationID: UUID
        let toOrganisationID: UUID
        let reputation: Int
    }

    /// Every move worth making, best coordinator first.
    ///
    /// Deterministic and draw-free: reputation says who is wanted, prestige says who can have them,
    /// and identity breaks every tie. A market that rolled dice for this would move different people
    /// in a replay of the same season.
    static func candidates(in state: GameState) -> [Candidate] {
        let organisations = state.programmes.values.map { ($0.id, $0.prestige.value, $0.staffIDs) }
            + state.proTeams.values.map { ($0.id, $0.prestige.value, $0.staffIDs) }
        let byPrestige = organisations.sorted {
            $0.1 == $1.1 ? $0.0.uuidString < $1.0.uuidString : $0.1 > $1.1
        }

        var result: [Candidate] = []
        for (organisationID, prestige, staffIDs) in byPrestige {
            for staffID in staffIDs.sorted(by: { $0.uuidString < $1.uuidString }) {
                guard let member = state.staff[staffID] else { continue }
                // Head coaches are the carousel's business (`02` §7), not the staff market's, and a
                // coach poached out of their own seat would be resigning by simulation.
                guard member.role != .headCoach else { continue }
                guard member.reputation.value >= PeopleRules.poachableReputation else { continue }
                // A poacher has to be meaningfully bigger. A lateral move is not a poaching, and
                // without the gap equals would trade coordinators forever.
                guard let poacher = byPrestige.first(where: {
                    $0.0 != organisationID && $0.1 >= prestige + PeopleRules.poachingPrestigeGap
                }) else { continue }
                result.append(Candidate(
                    staffID: staffID,
                    fromOrganisationID: organisationID,
                    toOrganisationID: poacher.0,
                    reputation: member.reputation.value
                ))
            }
        }
        return result.sorted {
            $0.reputation == $1.reputation
                ? $0.staffID.uuidString < $1.staffID.uuidString
                : $0.reputation > $1.reputation
        }
    }

    static func incumbent(
        role: StaffRole,
        positionGroup: PositionGroup?,
        at organisationID: UUID,
        in state: GameState
    ) -> Staff? {
        let staffIDs = state.programmes[organisationID]?.staffIDs
            ?? state.proTeams[organisationID]?.staffIDs
            ?? []
        return staffIDs
            .compactMap { state.staff[$0] }
            .first { $0.role == role && $0.positionGroup == positionGroup }
    }

    static func prestige(of organisationID: UUID, in state: GameState) -> Rating {
        state.programmes[organisationID]?.prestige
            ?? state.proTeams[organisationID]?.prestige
            ?? Rating(SharedRules.ratingRange.lowerBound)
    }

    static func setStaffIDs(
        at organisationID: UUID,
        in state: inout GameState,
        _ mutate: (inout [UUID]) -> Void
    ) {
        if state.programmes[organisationID] != nil {
            state.programmes.update(organisationID) { mutate(&$0.staffIDs) }
        } else {
            state.proTeams.update(organisationID) { mutate(&$0.staffIDs) }
        }
    }

    /// Hands back every responsibility delegated to somebody who has just left.
    static func reclaimDelegations(of staffID: UUID, in state: inout GameState) {
        guard let control = state.career.college else { return }
        for (responsibility, owner) in control.responsibilityOwners
            .sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            guard case let .delegated(delegateID) = owner, delegateID == staffID else { continue }
            CareerControlSystem.setResponsibility(responsibility, owner: .user, in: &state)
        }
    }
}
