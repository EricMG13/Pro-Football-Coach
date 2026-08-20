import Foundation

/// `02-GAME-DESIGN.md` §4.3's commitment rules — one live commitment per prospect, a bounded flip
/// chain, and a class that fits the capacity it was reserved against — stated once so they can be
/// asserted **after a transaction** rather than only on a root at rest.
///
/// Uniqueness is structural here rather than counted: a prospect holds one
/// `ProspectRecruitmentState`, and the programme it names is the last winner in its own history.
/// What that structure cannot say on its own is whether the history is a legal chain, whether the
/// programmes it names exist, and whether the programme on the other end can still hold the class
/// it has accumulated. Those are the limbs below.
///
/// The calendar limbs `WorldIntegrity` also applies — a commitment must not be dated in the future
/// relative to `state.calendar` — stay there. The season boundary moves `college.recruitingSeason`
/// several transactions before the calendar follows, so a calendar limb asserted after every
/// transaction would report the scheduler's own ordering as a breach.
public enum CollegeCommitmentInvariant {
    public enum Breach: String, Sendable, Equatable, CaseIterable {
        /// Filed under a key that is not the state's own prospect.
        case misfiledRecruitment
        /// Phase, history bound, flip chain, or release reason disagree with each other.
        case unsupportedShape
        /// A commitment naming a programme the root does not have.
        case unknownProgramme
        /// A live commitment for a prospect the root no longer carries.
        case missingProspect
        /// A signed commitment with no player behind it. Signing converts the identity; a signed
        /// row without a player is a class member who exists on one side of the transaction only.
        case signedWithoutPlayer
        /// More live commitments than `CollegeRules.initialSigningsPerClass`.
        case classLimitExceeded
        /// More live commitments than the capacity they were reserved against, or a programme
        /// whose capacity cannot be computed at all.
        case capacityExceeded
    }

    public struct Finding: Sendable, Equatable {
        public let subjectID: UUID
        public let breach: Breach

        public init(subjectID: UUID, breach: Breach) {
            self.subjectID = subjectID
            self.breach = breach
        }
    }

    /// The capacity limb alone, so `WorldIntegrity` and this sweep state it once. Position
    /// coverage is a roster rule rather than a commitment one and stays with its own caller.
    public static func capacityIsHonoured(_ capacity: ProgrammeCommitmentCapacity?) -> Bool {
        guard let capacity else { return false }
        return capacity.activeReservations <= capacity.maximumReservations
    }

    public static func findings(in state: GameState) -> [Finding] {
        let programmeIDs = Set(state.programmes.ids)
        var found: [Finding] = []

        for (key, recruitment) in state.college.prospectRecruitment {
            if key != recruitment.prospectID {
                found.append(Finding(subjectID: key, breach: .misfiledRecruitment))
            }
            if !recruitment.isValid {
                found.append(Finding(subjectID: key, breach: .unsupportedShape))
            }
            let namedProgrammeIDs = Set(recruitment.commitmentHistory.map(\.winner.programmeID))
            if !namedProgrammeIDs.isSubset(of: programmeIDs) {
                found.append(Finding(subjectID: key, breach: .unknownProgramme))
            }
            switch recruitment.phase {
            case .committed:
                if state.prospects[recruitment.prospectID] == nil {
                    found.append(Finding(subjectID: key, breach: .missingProspect))
                }
            case .signed:
                if state.players[recruitment.prospectID] == nil {
                    found.append(Finding(subjectID: key, breach: .signedWithoutPlayer))
                }
            case .available, .released:
                break
            }
        }

        for programmeID in programmeIDs {
            let live = state.college.activeReservationCount(for: programmeID)
            if live > CollegeRules.initialSigningsPerClass {
                found.append(Finding(subjectID: programmeID, breach: .classLimitExceeded))
            }
            guard state.college.programmes[programmeID] != nil else { continue }
            if !capacityIsHonoured(CollegeCommitmentCapacitySystem.capacity(
                programmeID: programmeID,
                in: state,
                college: state.college
            )) {
                found.append(Finding(subjectID: programmeID, breach: .capacityExceeded))
            }
        }

        // Findings are sorted, not the populations they came from: ordering the population means
        // materialising a UUID string per prospect on every call, and the population is the whole
        // annual pool.
        return found.sorted {
            ($0.subjectID.uuidString, $0.breach.rawValue)
                < ($1.subjectID.uuidString, $1.breach.rawValue)
        }
    }

    public static func isSatisfied(in state: GameState) -> Bool {
        findings(in: state).isEmpty
    }
}
