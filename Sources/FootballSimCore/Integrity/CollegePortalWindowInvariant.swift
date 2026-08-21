import Foundation

/// `02-GAME-DESIGN.md` §4.1's two portal windows and the bounds `CollegeRules` fixes on them,
/// stated once so they can be asserted **after a transaction** rather than only at a decode.
///
/// `CollegePortalState` already refuses an unsupported shape when it crosses persistence, which is
/// the strongest place to enforce it and the reason most of these limbs have never fired. What
/// persistence cannot say is anything about the interval between two transactions inside one
/// weekly step, and there is a specific claim to make there: the scheduler commits a portal window
/// atomically, so every transaction boundary it exposes carries a *stable* phase. A transactional
/// `postseasonOpen` or `springOpen` surviving a checkpoint would mean a half-open window was left
/// observable — the state would still decode as valid the moment the phase settled, so nothing
/// else in the project would ever notice.
public enum CollegePortalWindowInvariant {
    public enum Breach: String, Sendable, Equatable, CaseIterable {
        /// The shape `CollegePortalState` refuses at its own boundaries.
        case unsupportedState
        /// A half-open window left observable at a transaction boundary.
        case unstablePhaseAtBoundary
        /// The portal is running a season the college state is not.
        case targetSeasonDisagreement
        /// More entrants than `CollegeRules.portalPoolLimit`.
        case poolLimitExceeded
        /// More windows than `CollegeRules.portalWindowCount`.
        case windowCountExceeded
        /// An entrant carrying more offers than `CollegeRules.maximumPortalOffersPerEntrant`.
        case offerLimitExceeded
        /// An entrant whose source programme the root does not have.
        case unknownSourceProgramme
    }

    public struct Finding: Sendable, Equatable {
        public let subjectID: UUID?
        public let breach: Breach

        public init(subjectID: UUID?, breach: Breach) {
            self.subjectID = subjectID
            self.breach = breach
        }
    }

    public static func findings(in state: GameState) -> [Finding] {
        let portal = state.college.portal
        var found: [Finding] = []
        if !portal.isTransactionallyValid {
            found.append(Finding(subjectID: nil, breach: .unsupportedState))
        }
        if !portal.phase.isStableBoundary {
            found.append(Finding(subjectID: nil, breach: .unstablePhaseAtBoundary))
        }
        if portal.targetSeason != state.college.recruitingSeason {
            found.append(Finding(subjectID: nil, breach: .targetSeasonDisagreement))
        }
        if portal.entries.count > CollegeRules.portalPoolLimit {
            found.append(Finding(subjectID: nil, breach: .poolLimitExceeded))
        }
        if portal.summaries.count > CollegeRules.portalWindowCount {
            found.append(Finding(subjectID: nil, breach: .windowCountExceeded))
        }
        let programmeIDs = Set(state.programmes.ids)
        for (playerID, record) in portal.entries {
            if record.offers.count > CollegeRules.maximumPortalOffersPerEntrant {
                found.append(Finding(subjectID: playerID, breach: .offerLimitExceeded))
            }
            if !programmeIDs.contains(record.sourceProgrammeID) {
                found.append(Finding(subjectID: playerID, breach: .unknownSourceProgramme))
            }
        }
        return found.sorted {
            ($0.subjectID?.uuidString ?? "", $0.breach.rawValue)
                < ($1.subjectID?.uuidString ?? "", $1.breach.rawValue)
        }
    }

    public static func isSatisfied(in state: GameState) -> Bool {
        findings(in: state).isEmpty
    }
}
