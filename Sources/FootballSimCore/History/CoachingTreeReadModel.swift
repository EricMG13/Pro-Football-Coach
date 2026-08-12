import Foundation

/// One coach who served under a head coach and later held a head-coaching job of their own.
public struct CoachingTreeDisciple: Sendable, Equatable, Identifiable {
    public var id: UUID { staffID }
    public let staffID: UUID
    public let name: String
    public let sharedSeason: Int
    public let sharedOrganisationID: UUID
    public let roleUnderMentor: StaffRole
    public let firstHeadCoachSeason: Int

    public init(
        staffID: UUID,
        name: String,
        sharedSeason: Int,
        sharedOrganisationID: UUID,
        roleUnderMentor: StaffRole,
        firstHeadCoachSeason: Int
    ) {
        self.staffID = staffID
        self.name = name
        self.sharedSeason = sharedSeason
        self.sharedOrganisationID = sharedOrganisationID
        self.roleUnderMentor = roleUnderMentor
        self.firstHeadCoachSeason = firstHeadCoachSeason
    }
}

public struct CoachingTreeBranch: Sendable, Equatable, Identifiable {
    public var id: UUID { mentorID }
    public let mentorID: UUID
    public let mentorName: String
    public let disciples: [CoachingTreeDisciple]

    public init(mentorID: UUID, mentorName: String, disciples: [CoachingTreeDisciple]) {
        self.mentorID = mentorID
        self.mentorName = mentorName
        self.disciples = Array(disciples.prefix(CoachingTreeReadModel.maximumDisciplesPerBranch))
    }
}

/// Rebuildable coaching-tree projection: who a head coach came up under, and who came up under them.
///
/// Deliberately not `Codable`. `PeopleState.staffCareers` is the authority and is already bounded at
/// `PeopleRules.careerSeasonHistoryLimit` assignments per coach. Persisting a second copy of the
/// same facts would create a second authority that can disagree with the first, which is the failure
/// `03b` names; this is rebuilt after load exactly like `WorldHistoryReadModel`.
public struct CoachingTreeReadModel: Sendable, Equatable {
    /// Bounds. A career is twenty seasons of staff churn across 166 organisations, and a screen
    /// shows a list, not a census.
    public static let maximumBranches = 256
    public static let maximumDisciplesPerBranch = 16

    public let branches: [CoachingTreeBranch]

    public init(branches: [CoachingTreeBranch]) {
        self.branches = Array(branches.prefix(CoachingTreeReadModel.maximumBranches))
    }

    public static func build(from state: GameState) -> CoachingTreeReadModel {
        // Ordered before anything is derived from it, so every index below is built by walking an
        // array rather than a dictionary and no output depends on this launch's hash seed.
        let careers = state.people.staffCareers.values
            .sorted { $0.staffID.uuidString < $1.staffID.uuidString }

        let firstHeadCoachSeason = Self.firstHeadCoachSeasons(in: careers)
        let headCoachBySeat = Self.headCoachesBySeat(in: careers)

        var disciplesByMentor: [UUID: [CoachingTreeDisciple]] = [:]
        for career in careers {
            guard let becameHeadCoach = firstHeadCoachSeason[career.staffID] else { continue }
            // Earliest first, because serving under the same head coach for four years is one
            // relationship and the season it started is the one worth naming.
            let servedUnderSomeone = career.assignments
                .filter { $0.role != .headCoach }
                .sorted { $0.season < $1.season }
            var claimedMentors: Set<UUID> = []
            for assignment in servedUnderSomeone {
                let seat = seatKey(
                    season: assignment.season,
                    organisationID: assignment.organisationID
                )
                guard let mentorID = headCoachBySeat[seat], mentorID != career.staffID else {
                    continue
                }
                guard claimedMentors.insert(mentorID).inserted else { continue }
                disciplesByMentor[mentorID, default: []].append(CoachingTreeDisciple(
                    staffID: career.staffID,
                    name: Self.name(of: career.staffID, in: state),
                    sharedSeason: assignment.season,
                    sharedOrganisationID: assignment.organisationID,
                    roleUnderMentor: assignment.role,
                    firstHeadCoachSeason: becameHeadCoach
                ))
            }
        }

        var branches: [CoachingTreeBranch] = []
        branches.reserveCapacity(disciplesByMentor.count)
        for (mentorID, disciples) in disciplesByMentor {
            let ordered = disciples.sorted { lhs, rhs in
                lhs.sharedSeason == rhs.sharedSeason
                    ? lhs.staffID.uuidString < rhs.staffID.uuidString
                    : lhs.sharedSeason < rhs.sharedSeason
            }
            branches.append(CoachingTreeBranch(
                mentorID: mentorID,
                mentorName: Self.name(of: mentorID, in: state),
                disciples: ordered
            ))
        }
        // Deepest first, and the bound is applied after the sort, so what survives truncation is the
        // trees worth showing rather than whichever the dictionary happened to list first.
        branches.sort { lhs, rhs in
            lhs.disciples.count == rhs.disciples.count
                ? lhs.mentorID.uuidString < rhs.mentorID.uuidString
                : lhs.disciples.count > rhs.disciples.count
        }

        return CoachingTreeReadModel(branches: branches)
    }

    /// The season each coach first held a head-coaching job. A coach with no such season is neither
    /// a mentor nor a disciple, so this one index answers both questions.
    private static func firstHeadCoachSeasons(
        in careers: [StaffCareerRecord]
    ) -> [UUID: Int] {
        var seasons: [UUID: Int] = [:]
        for career in careers {
            for assignment in career.assignments where assignment.role == .headCoach {
                if let existing = seasons[career.staffID] {
                    seasons[career.staffID] = min(existing, assignment.season)
                } else {
                    seasons[career.staffID] = assignment.season
                }
            }
        }
        return seasons
    }

    /// Who held each organisation's head-coaching seat in each season.
    ///
    /// A season with two recorded head coaches is possible after a midseason change, and the lower
    /// UUID wins so the answer is the same on every run rather than the order the records arrived.
    private static func headCoachesBySeat(in careers: [StaffCareerRecord]) -> [String: UUID] {
        var occupants: [String: UUID] = [:]
        for career in careers {
            for assignment in career.assignments where assignment.role == .headCoach {
                let seat = seatKey(
                    season: assignment.season,
                    organisationID: assignment.organisationID
                )
                if let existing = occupants[seat], existing.uuidString <= career.staffID.uuidString {
                    continue
                }
                occupants[seat] = career.staffID
            }
        }
        return occupants
    }

    /// A season-and-organisation seat, as one string.
    ///
    /// A `Hashable` struct would read better and cannot be used: `ContractTests` enumerates every
    /// dictionary key type in the engine and requires it to be `CodingKeyRepresentable`, so that a
    /// map can never encode in hash order. `RivalrySystem.pairKey` solves the same problem the same
    /// way.
    private static func seatKey(season: Int, organisationID: UUID) -> String {
        "\(season)|\(organisationID.uuidString)"
    }

    private static func name(of staffID: UUID, in state: GameState) -> String {
        state.staff[staffID]?.fullName ?? "Former coach"
    }
}
