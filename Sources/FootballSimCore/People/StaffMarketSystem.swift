import Foundation

public enum StaffMarketError: Error, Sendable, Equatable {
    case missingOrganisation
    case missingIncumbent
    case unknownCandidate
    case cannotAfford(needed: Int, available: Int)
    case cannotReplaceHeadCoach
    /// The swap would leave a world that cannot be saved. Checked rather than assumed, because this
    /// system writes to four places at once and an atomic transaction that trusted itself is how
    /// the missing career record below went unnoticed in the first place.
    case invalidRoot
}

/// A coach the organisation could hire. Generated, never persisted.
public struct StaffCandidate: Sendable, Equatable, Identifiable {
    public var id: UUID { staff.id }
    public let staff: Staff
    /// What they would cost a season.
    public let salary: Int

    public init(staff: Staff, salary: Int) {
        self.staff = staff
        self.salary = salary
    }
}

/// Hiring and firing. `02` §6.1.
///
/// `02` §6 makes staff continuity a resource and §4.1 sells "coordinators poached, replacements
/// hired" as an offseason beat. Neither was reachable: `CoachIntent` had seven cases and none
/// concerned staff, vacancies resolved deterministically inside the weekly `jobAndStaffMarkets`
/// step, and a coach could not hire or fire anybody at all. Screens 20 and 21 exist for a system
/// that did not.
///
/// **A replacement, not a firing.** `WorldIntegrity` requires complete role coverage on every
/// organisation, so releasing a coordinator on Tuesday and hiring one on Friday is a world that is
/// invalid in between — and this project's transactions validate a whole copied root. One atomic
/// swap keeps coverage true at every point a save could be written.
public enum StaffMarketSystem {
    /// The people available for a role, deterministically generated from the world seed.
    ///
    /// Generated rather than drawn from a persisted pool, for the reason the draft class is: a pool
    /// that had to be stored, aged and pruned is save growth and a bounded-collection problem, and
    /// the market only has to be *stable*, not remembered. The same world offers the same names to
    /// the same organisation in the same season.
    public static func candidates(
        for organisationID: UUID,
        role: StaffRole,
        positionGroup: PositionGroup? = nil,
        in state: GameState
    ) -> [StaffCandidate] {
        let prestige = state.programmes[organisationID]?.prestige
            ?? state.proTeams[organisationID]?.prestige
            ?? Rating(SharedRules.ratingRange.lowerBound)
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: SeededRandom.derive(from: state.league.seed, scope: .personnel,
                                      identifier: organisationID),
            scope: .personnel,
            ordinal: state.calendar.season * 100
                + (StaffRole.allCases.firstIndex(of: role) ?? 0)
        ))
        return (0..<PeopleRules.staffCandidatesPerRole).map { _ in
            // Centred on what this organisation can attract: prestige buys interviews, which is the
            // same argument `02` §8 makes for recruiting and the reason prestige moves at all.
            let baseline = 48 + (prestige.value - SharedRules.ratingRange.lowerBound) * 32 / 59
            let name = NameGrammar.personName(using: &rng)
            var ratings: [CoachAttribute: Rating] = [:]
            for attribute in CoachAttribute.allCases {
                ratings[attribute] = Rating(baseline + rng.int(in: -14...14))
            }
            let reputation = Rating(baseline + rng.int(in: -10...10))
            let staff = Staff(
                id: rng.uuid(),
                firstName: name.given,
                lastName: name.family,
                role: role,
                age: rng.int(in: PeopleRules.staffAgeRange),
                reputation: reputation,
                positionGroup: role == .positionCoach ? positionGroup : nil,
                ratings: ratings
            )
            return StaffCandidate(
                staff: staff,
                salary: FinanceRules.salary(reputation: reputation, role: role)
            )
        }
    }

    /// Replaces one member of staff with a candidate, atomically.
    ///
    /// - Throws: `StaffMarketError.cannotAfford` when the organisation cannot pay the difference —
    ///   which is what makes hiring a decision rather than a wish, and what `02` §10's reserves are
    ///   for.
    public static func replace(
        incumbentID: UUID,
        with candidate: StaffCandidate,
        at organisationID: UUID,
        in state: GameState
    ) throws -> GameState {
        var next = state
        guard next.programmes[organisationID] != nil || next.proTeams[organisationID] != nil else {
            throw StaffMarketError.missingOrganisation
        }
        guard let incumbent = next.staff[incumbentID] else {
            throw StaffMarketError.missingIncumbent
        }
        // The coach's own seat is not theirs to fill. `02` §7's carousel decides who holds it, and a
        // head coach who could hire their own replacement would be resigning through the staff
        // screen.
        guard incumbent.role != .headCoach else { throw StaffMarketError.cannotReplaceHeadCoach }
        guard candidate.staff.role == incumbent.role,
              candidate.staff.positionGroup == incumbent.positionGroup else {
            throw StaffMarketError.unknownCandidate
        }

        // The cost is the difference for the rest of the season plus what the outgoing contract
        // still owes, which is why replacing an expensive coach with a cheap one is not free.
        let outgoing = FinanceRules.salary(reputation: incumbent.reputation, role: incumbent.role)
        let cost = candidate.salary + outgoing / PeopleRules.staffSeveranceShare
        var finances = next.programmes[organisationID]?.finances(defaultingFor: .college)
            ?? next.proTeams[organisationID]!.finances(defaultingFor: .pro)
        guard finances.spend(cost) else {
            throw StaffMarketError.cannotAfford(needed: cost, available: finances.reserves)
        }

        // The outgoing coach is out of work, not deleted. Removing them from `staff` while their
        // career record stayed behind produced an `orphanStaffCareer`, so **every hire this system
        // made was an invalid root** — a defect in this file, found while building §6.1's poaching
        // and fixed here rather than worked around there. An unemployed coach is a legal thing in
        // this world: it is exactly what an aged-out coordinator already becomes.
        next.staff.insert(candidate.staff)
        // And the new one needs a career, for the same reason: whole-root integrity requires one per
        // staff entity, and requires its latest assignment to name the organisation they work for.
        next.people.insert(
            staff: candidate.staff,
            assignment: StaffCareerAssignment(
                season: state.calendar.season,
                organisationID: organisationID,
                role: candidate.staff.role
            )
        )
        if next.programmes[organisationID] != nil {
            _ = next.programmes.update(organisationID) { programme in
                programme.staffIDs.removeAll { $0 == incumbentID }
                programme.staffIDs.append(candidate.staff.id)
                programme.finances = finances
            }
        } else {
            _ = next.proTeams.update(organisationID) { team in
                team.staffIDs.removeAll { $0 == incumbentID }
                team.staffIDs.append(candidate.staff.id)
                team.finances = finances
            }
        }
        guard WorldIntegrity.check(next).isValid else { throw StaffMarketError.invalidRoot }
        return next
    }
}
