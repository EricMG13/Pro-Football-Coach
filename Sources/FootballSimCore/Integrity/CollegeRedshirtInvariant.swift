import Foundation

/// `02-GAME-DESIGN.md` §4.1's redshirt legality, stated once so it can be asserted **after a
/// transaction** rather than only on a root at rest.
///
/// Same shape and same reason as `CollegeScholarshipInvariant` and `CollegeEligibilityInvariant`.
///
/// One limb is deliberately **not** here: `WorldIntegrity` also requires a plan's season to equal
/// `state.calendar.season`, and that is a property of a root at rest rather than of the plan. The
/// season boundary moves `college.recruitingSeason` forward several transactions before the
/// calendar follows it at `.weekSnapshot`, so a calendar limb asserted after every transaction
/// would report the scheduler's own ordering as a breach. What is left is the part that is true of
/// a legal plan whenever it is read: it belongs to the player it is filed under, at a programme
/// that has the player and a recruiting state, in the recruiting season the college state is
/// currently running, with a clock year spare to spend. `WorldIntegrity` keeps the calendar limb.
public enum CollegeRedshirtInvariant {
    public enum Breach: String, Sendable, Equatable, CaseIterable {
        /// Filed under a key that is not the plan's own player.
        case misfiledPlan
        /// Season or appearance limit outside the bounds `CollegeRules` fixes.
        case unsupportedShape
        /// A plan for a season the college state is not running.
        case staleSeason
        /// The player is not on the roster of the programme the plan names, or that programme has
        /// no recruiting state.
        case programmeDoesNotHoldPlayer
        /// No spare clock year left to spend on a redshirt.
        case noSpareClockYear
    }

    public struct Finding: Sendable, Equatable {
        public let playerID: UUID
        public let breach: Breach

        public init(playerID: UUID, breach: Breach) {
            self.playerID = playerID
            self.breach = breach
        }
    }

    public static func findings(in state: GameState) -> [Finding] {
        var found: [Finding] = []
        for playerID in state.college.redshirtPlans.keys
            .sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let plan = state.college.redshirtPlans[playerID] else { continue }
            if playerID != plan.playerID {
                found.append(Finding(playerID: playerID, breach: .misfiledPlan))
            }
            if !plan.isStructurallyValid {
                found.append(Finding(playerID: playerID, breach: .unsupportedShape))
            }
            if plan.season != state.college.recruitingSeason {
                found.append(Finding(playerID: playerID, breach: .staleSeason))
            }
            if state.programmes[plan.programmeID]?.rosterIDs.contains(playerID) != true
                || state.college.programmes[plan.programmeID] == nil {
                found.append(Finding(playerID: playerID, breach: .programmeDoesNotHoldPlayer))
            }
            if state.players[playerID]?.eligibility
                .map(CollegeRedshirtSystem.hasSpareClockYear) != true {
                found.append(Finding(playerID: playerID, breach: .noSpareClockYear))
            }
        }
        return found
    }

    public static func isSatisfied(in state: GameState) -> Bool {
        findings(in: state).isEmpty
    }
}
