import Foundation

/// Why a coach got better or worse this season. Causal, like a player's development summary, because
/// a number nobody can explain is a number nobody can act on.
public enum StaffDevelopmentReason: String, Sendable, CaseIterable {
    case experience
    case age
    case seasonResult
    case continuity
}

public struct StaffDevelopmentChange: Sendable, Equatable {
    public let staffID: UUID
    public let attribute: CoachAttribute
    /// Signed, in rating points.
    public let delta: Int
    public let reputationDelta: Int

    public init(staffID: UUID, attribute: CoachAttribute, delta: Int, reputationDelta: Int) {
        self.staffID = staffID
        self.attribute = attribute
        self.delta = delta
        self.reputationDelta = reputationDelta
    }
}

public struct StaffDevelopmentTransition: Sendable, Equatable {
    public let staff: EntityStore<Staff>
    public let changes: [StaffDevelopmentChange]

    public init(staff: EntityStore<Staff>, changes: [StaffDevelopmentChange]) {
        self.staff = staff
        self.changes = changes
    }
}

/// Staff have careers. `02` §6.1.
///
/// §6.1 recorded this as open in the plainest terms: **staff ratings do not change over a career**,
/// so a coordinator who wins for a decade is exactly as good as the day they arrived, and the
/// continuity §6 calls a resource bought nothing. A coaching game in which coaches never develop is
/// missing the thing it is named after.
///
/// Bounded exactly as player development is — one attribute, one point, once a season — because the
/// same argument applies: a system that can move a rating by more than a point a year turns a
/// twenty-season career into a rating range nobody designed.
public enum StaffDevelopmentSystem {
    /// Develops every member of staff for a completed season.
    ///
    /// Deterministic from the world seed, the season and the person, so the same save develops the
    /// same coaches. No draw depends on anything a reader could change.
    public static func process(after completed: CalendarState, in state: GameState) -> StaffDevelopmentTransition {
        var staff = state.staff
        var changes: [StaffDevelopmentChange] = []

        for id in state.staff.ids.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let member = staff[id] else { continue }
            var rng = SeededRandom(seed: SeededRandom.derive(
                from: SeededRandom.derive(from: state.league.seed, scope: .personnel,
                                          identifier: id),
                scope: .season,
                ordinal: completed.season
            ))
            // Drawn first and unconditionally, so which attribute moves does not depend on whether
            // anything moved — the property every other draw in this engine holds.
            let attribute = rng.pick(CoachAttribute.allCases)
            let noise = rng.int(in: PeopleRules.staffDevelopmentNoise)

            let standing = employerStanding(of: id, in: state)
            var score = noise
            // Experience, up to the age at which a coach has seen everything worth seeing.
            if member.age <= PeopleRules.staffLearningAge { score += PeopleRules.staffExperienceValue }
            if member.age >= PeopleRules.staffDeclineAge { score -= PeopleRules.staffAgeCost }
            if let standing {
                if standing >= PeopleRules.staffSuccessPercentile {
                    score += PeopleRules.staffResultValue
                }
                if standing <= PeopleRules.staffFailurePercentile {
                    score -= PeopleRules.staffResultValue
                }
            }
            // Continuity is a resource (`02` §6), and this is the one place it pays: a coach who has
            // been somewhere long enough to know it gets more out of the same season.
            if member.seasonsWithProgramme >= PeopleRules.staffSettledSeasons {
                score += PeopleRules.staffContinuityValue
            }

            let delta = score >= PeopleRules.staffDevelopmentThreshold
                ? 1
                : (score <= -PeopleRules.staffDevelopmentThreshold ? -1 : 0)
            // Reputation follows results rather than ability, because it is what other clubs see:
            // a coordinator on a winning team is poachable whether or not they got better.
            let reputationDelta: Int
            if let standing, standing >= PeopleRules.staffSuccessPercentile {
                reputationDelta = PeopleRules.staffReputationStep
            } else if let standing, standing <= PeopleRules.staffFailurePercentile {
                reputationDelta = -PeopleRules.staffReputationStep
            } else {
                reputationDelta = 0
            }

            guard delta != 0 || reputationDelta != 0 else { continue }
            let before = member.rating(attribute).value
            let after = Rating(before + delta)
            let reputationAfter = Rating(member.reputation.value + reputationDelta)
            let appliedDelta = after.value - before
            let appliedReputation = reputationAfter.value - member.reputation.value
            guard appliedDelta != 0 || appliedReputation != 0 else { continue }

            staff.update(id) {
                $0.ratings[attribute] = after
                $0.reputation = reputationAfter
            }
            changes.append(StaffDevelopmentChange(
                staffID: id,
                attribute: attribute,
                delta: appliedDelta,
                reputationDelta: appliedReputation
            ))
        }
        return StaffDevelopmentTransition(staff: staff, changes: changes)
    }

    /// Where this coach's organisation finished, as a percentile with 100 at the top — or nil when
    /// they are unemployed or no season has been archived yet.
    ///
    /// Read from the archived final ranking rather than from the standings, and not for
    /// convenience: development runs at the boundary, *after* the season has been completed and the
    /// table rolled over, so standings at that moment describe a season nobody has played. The
    /// archive is also what `ProgrammeEvolutionSystem` reads to move prestige — one definition of
    /// how a season went, used twice rather than two definitions that can disagree.
    public static func employerStanding(of staffID: UUID, in state: GameState) -> Int? {
        guard let organisationID = employer(of: staffID, in: state),
              let archive = state.competition.archives.last else { return nil }
        let ranking = state.programmes[organisationID] != nil
            ? archive.finalCollegeRanking
            : archive.finalProRanking
        guard let index = ranking.firstIndex(of: organisationID), ranking.count > 1 else {
            return nil
        }
        return (ranking.count - 1 - index) * 100 / (ranking.count - 1)
    }

    static func employer(of staffID: UUID, in state: GameState) -> UUID? {
        if let programme = state.programmes.values.first(where: {
            $0.staffIDs.contains(staffID)
        }) { return programme.id }
        return state.proTeams.values.first { $0.staffIDs.contains(staffID) }?.id
    }
}
