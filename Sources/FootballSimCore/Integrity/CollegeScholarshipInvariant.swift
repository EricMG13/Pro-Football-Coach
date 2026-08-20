import Foundation

/// `02-GAME-DESIGN.md` §11's scholarship limit, stated once so it can be asserted **after a
/// transaction** rather than only on a root at rest.
///
/// The four limbs below used to live inline inside `WorldIntegrity`'s programme-recruiting
/// boolean, fused with a dozen unrelated ones behind a single `invalidProgrammeRecruitingState`.
/// That is what made the rule unenforceable end to end: a caller that wanted to check scholarships
/// between two transactions had to run the whole-world check — which also asserts calendar
/// agreement, NIL conservation and board shape, none of which hold mid-transaction — and even then
/// the answer named a programme rather than a limb. Naming the limbs makes the rule something a
/// caller can hold, while keeping exactly one statement of it.
public enum CollegeScholarshipInvariant {
    public enum Breach: String, Sendable, Equatable, CaseIterable {
        /// More holders than `CollegeRules.scholarshipLimit`.
        case overLimit
        /// One player holding two.
        case duplicateHolder
        /// A scholarship held by someone who is not on that programme's roster.
        case holderOffRoster
        /// `Programme.scholarshipCount` and the college-side holder list disagree. Two counters
        /// for one rule, so either can drift; the pair is the rule, not each half.
        case countDisagreement
        /// A programme with no college recruiting state at all, or recruiting state for no
        /// programme. Without this limb a whole programme could leave the sweep unchecked.
        case missingCounterpart
    }

    public struct Finding: Sendable, Equatable {
        public let programmeID: UUID
        public let breach: Breach

        public init(programmeID: UUID, breach: Breach) {
            self.programmeID = programmeID
            self.breach = breach
        }
    }

    /// One programme's limbs. `nil` for either side is `missingCounterpart` rather than a skip —
    /// a sweep that quietly drops the pairs it cannot resolve reports green on a world that has
    /// lost half of one.
    public static func findings(
        programmeID: UUID,
        programme: Programme?,
        recruiting: ProgrammeRecruitingState?
    ) -> [Finding] {
        guard let programme, let recruiting else {
            return [Finding(programmeID: programmeID, breach: .missingCounterpart)]
        }
        var found: [Finding] = []
        let holders = recruiting.scholarshipPlayerIDs
        let holderSet = Set(holders)
        if holders.count > CollegeRules.scholarshipLimit {
            found.append(Finding(programmeID: programmeID, breach: .overLimit))
        }
        if holderSet.count != holders.count {
            found.append(Finding(programmeID: programmeID, breach: .duplicateHolder))
        }
        if !holderSet.isSubset(of: Set(programme.rosterIDs)) {
            found.append(Finding(programmeID: programmeID, breach: .holderOffRoster))
        }
        if holders.count != programme.scholarshipCount {
            found.append(Finding(programmeID: programmeID, breach: .countDisagreement))
        }
        return found
    }

    /// Every college programme in the root, both directions. The union is deliberate: iterating
    /// only `state.programmes` would make an orphan recruiting state invisible, and iterating only
    /// `state.college.programmes` would do the same for a programme that has lost its recruiting
    /// state. The class is enumerated by construction, so a programme added later is swept the day
    /// it exists rather than the day someone remembers it.
    public static func findings(in state: GameState) -> [Finding] {
        let ids = Set(state.programmes.ids).union(state.college.programmes.keys)
        return ids.sorted { $0.uuidString < $1.uuidString }.flatMap { id in
            findings(
                programmeID: id,
                programme: state.programmes[id],
                recruiting: state.college.programmes[id]
            )
        }
    }

    public static func isSatisfied(in state: GameState) -> Bool {
        findings(in: state).isEmpty
    }
}
