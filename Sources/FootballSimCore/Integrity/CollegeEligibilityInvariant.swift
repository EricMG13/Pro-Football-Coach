import Foundation

/// `02-GAME-DESIGN.md` §11.1's eligibility clock — four seasons of competition inside a five-year
/// window — stated once so it can be asserted **after a transaction** rather than only on a root at
/// rest.
///
/// Same shape and same reason as `CollegeScholarshipInvariant`: the limbs lived inline in
/// `WorldIntegrity`'s per-player boolean, fused with contract and lifecycle limbs behind a single
/// `invalidPlayerLifecycle`, so a caller could not ask about the clock alone.
///
/// The sweep is two-sided on purpose. A college roster player must hold a clock that has not run
/// out; a professional roster player must hold none at all. Checking only the first limb would let
/// a clock survive the promotion out of the college game unnoticed, and that partition — every
/// rostered player is swept by exactly one of the two — is what makes "every player" true by
/// construction rather than by enumeration.
public enum CollegeEligibilityInvariant {
    public enum Breach: String, Sendable, Equatable, CaseIterable {
        /// A college roster player with no eligibility clock at all.
        case missingClock
        /// A college roster player whose clock has run out on either counter.
        case exhaustedClock
        /// Counters no supported transition could have produced: fewer years than seasons, or a
        /// gap wider than the single redshirt year the window holds.
        case impossibleClock
        /// A professional roster player still carrying a college clock.
        case professionalHoldsClock
    }

    public struct Finding: Sendable, Equatable {
        public let playerID: UUID
        public let breach: Breach

        public init(playerID: UUID, breach: Breach) {
            self.playerID = playerID
            self.breach = breach
        }
    }

    /// One college roster player's limbs.
    public static func collegeFindings(playerID: UUID, eligibility: Eligibility?) -> [Finding] {
        guard let eligibility else {
            return [Finding(playerID: playerID, breach: .missingClock)]
        }
        var found: [Finding] = []
        if eligibility.isExhausted {
            found.append(Finding(playerID: playerID, breach: .exhaustedClock))
        }
        if !eligibility.isValidForActiveCollegeRoot {
            found.append(Finding(playerID: playerID, breach: .impossibleClock))
        }
        return found
    }

    public static func findings(in state: GameState) -> [Finding] {
        let collegeRosterIDs = Set(state.programmes.values.flatMap(\.rosterIDs))
        let proRosterIDs = Set(state.proTeams.values.flatMap {
            $0.rosterIDs + $0.practiceSquadIDs
        })
        // The sweep runs unsorted and the *findings* are sorted at the end. Ordering the
        // population instead means materialising a UUID string per rostered player on every call,
        // which is the whole world; ordering the findings is almost always ordering nothing, and
        // the caller sees the same deterministic list either way.
        var found: [Finding] = []
        for id in collegeRosterIDs {
            found += collegeFindings(playerID: id, eligibility: state.players[id]?.eligibility)
        }
        for id in proRosterIDs where state.players[id]?.eligibility != nil {
            found.append(Finding(playerID: id, breach: .professionalHoldsClock))
        }
        return found.sorted {
            ($0.playerID.uuidString, $0.breach.rawValue)
                < ($1.playerID.uuidString, $1.breach.rawValue)
        }
    }

    public static func isSatisfied(in state: GameState) -> Bool {
        findings(in: state).isEmpty
    }
}
