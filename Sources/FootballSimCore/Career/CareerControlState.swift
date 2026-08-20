import Foundation

public enum CollegeCareerResponsibility: String, Codable, Sendable, CaseIterable, Hashable {
    case recruiting
    case portalAndRetention
    case nilAllocation
    case redshirts
}

public enum CareerResponsibilityOwner: Codable, Sendable, Equatable {
    case user
    case delegated(staffID: UUID)
}

public struct CollegeCareerControl: Codable, Sendable, Equatable {
    public let coachID: UUID
    public let programmeID: UUID
    public let startedAt: CalendarState
    public private(set) var responsibilityOwners: [
        CollegeCareerResponsibility: CareerResponsibilityOwner
    ]

    public init(
        coachID: UUID,
        programmeID: UUID,
        startedAt: CalendarState,
        responsibilityOwners: [
            CollegeCareerResponsibility: CareerResponsibilityOwner
        ] = Dictionary(uniqueKeysWithValues: CollegeCareerResponsibility.allCases.map {
            ($0, .user)
        })
    ) {
        precondition(
            Set(responsibilityOwners.keys) == Set(CollegeCareerResponsibility.allCases),
            "A college career requires one owner for every management responsibility."
        )
        self.coachID = coachID
        self.programmeID = programmeID
        self.startedAt = startedAt
        self.responsibilityOwners = responsibilityOwners
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedOwners = try container.decode(
            [CollegeCareerResponsibility: CareerResponsibilityOwner].self,
            forKey: .responsibilityOwners
        )
        guard Set(decodedOwners.keys) == Set(CollegeCareerResponsibility.allCases) else {
            throw DecodingError.dataCorruptedError(
                forKey: .responsibilityOwners,
                in: container,
                debugDescription: "A college career has missing or unknown responsibilities."
            )
        }
        coachID = try container.decode(UUID.self, forKey: .coachID)
        programmeID = try container.decode(UUID.self, forKey: .programmeID)
        startedAt = try container.decode(CalendarState.self, forKey: .startedAt)
        responsibilityOwners = decodedOwners
    }

    mutating func setOwner(
        _ owner: CareerResponsibilityOwner,
        for responsibility: CollegeCareerResponsibility
    ) {
        responsibilityOwners[responsibility] = owner
    }
}

public struct CareerControlState: Codable, Sendable, Equatable {
    public static let maximumMandatoryDecisionResolutions = 10_000
    public private(set) var college: CollegeCareerControl?
    /// The coach identity survives tier transitions and separation from a programme.
    /// Optional decoding keeps schema-11 saves readable; new careers always set it.
    public private(set) var coachID: UUID?
    public private(set) var mandatoryDecisionResolutions: [MandatoryDecisionResolution]

    public init(
        college: CollegeCareerControl? = nil,
        coachID: UUID? = nil,
        mandatoryDecisionResolutions: [MandatoryDecisionResolution] = []
    ) {
        precondition(
            mandatoryDecisionResolutions.count <= Self.maximumMandatoryDecisionResolutions
                && Set(mandatoryDecisionResolutions.map(\.decisionID)).count
                    == mandatoryDecisionResolutions.count,
            "Career decision history is invalid."
        )
        self.college = college
        self.coachID = coachID ?? college?.coachID
        self.mandatoryDecisionResolutions = mandatoryDecisionResolutions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode(
            [MandatoryDecisionResolution].self,
            forKey: .mandatoryDecisionResolutions
        )
        guard decoded.count <= Self.maximumMandatoryDecisionResolutions,
              Set(decoded.map(\.decisionID)).count == decoded.count else {
            throw DecodingError.dataCorruptedError(
                forKey: .mandatoryDecisionResolutions,
                in: container,
                debugDescription: "Career decision history is invalid."
            )
        }
        college = try container.decodeIfPresent(CollegeCareerControl.self, forKey: .college)
        coachID = try container.decodeIfPresent(UUID.self, forKey: .coachID) ?? college?.coachID
        mandatoryDecisionResolutions = decoded
    }

    mutating func setCollege(_ control: CollegeCareerControl) {
        college = control
        coachID = control.coachID
    }

    mutating func clearCollege() {
        college = nil
    }

    @discardableResult
    mutating func recordResolution(_ resolution: MandatoryDecisionResolution) -> Bool {
        guard mandatoryDecisionResolutions.count < Self.maximumMandatoryDecisionResolutions,
              !mandatoryDecisionResolutions.contains(where: {
                  $0.decisionID == resolution.decisionID
              }) else { return false }
        mandatoryDecisionResolutions.append(resolution)
        return true
    }
}

public enum CareerControlError: Error, Equatable {
    case careerAlreadyStarted
    case missingProgramme
    case missingHeadCoach
}

public struct CareerControlTransition: Sendable, Equatable {
    public let state: GameState
    public let control: CollegeCareerControl

    public init(state: GameState, control: CollegeCareerControl) {
        self.state = state
        self.control = control
    }
}

public enum CareerControlSystem {
    public static func startCollegeCareer(
        at programmeID: UUID,
        in state: GameState
    ) throws -> CareerControlTransition {
        guard state.career.college == nil, state.careerArc.currentJob == nil else {
            throw CareerControlError.careerAlreadyStarted
        }
        guard let programme = state.programmes[programmeID] else {
            throw CareerControlError.missingProgramme
        }
        let headCoachIDs = programme.staffIDs.filter {
            state.staff[$0]?.role == .headCoach
        }
        guard headCoachIDs.count == 1 else {
            throw CareerControlError.missingHeadCoach
        }
        var coach: Staff
        if let existingCoachID = state.career.coachID,
           let existingCoach = state.staff[existingCoachID] {
            coach = existingCoach
        } else {
            var ordinal = 10_000
            repeat {
                coach = StaffPopulationGenerator.replacement(
                    rootSeed: state.league.seed,
                    season: state.calendar.season,
                    organisationID: programmeID,
                    prestige: programme.prestige,
                    role: .headCoach,
                    positionGroup: nil,
                    ordinal: ordinal
                )
                ordinal += 1
            } while state.staff[coach.id] != nil
        }
        let control = CollegeCareerControl(
            coachID: coach.id,
            programmeID: programmeID,
            startedAt: state.calendar
        )
        var next = state
        next.staff.insert(coach)
        for organisationID in next.programmes.ids where organisationID != programmeID {
            _ = next.programmes.update(organisationID) { programme in
                programme.staffIDs.removeAll { $0 == coach.id }
            }
        }
        for teamID in next.proTeams.ids {
            _ = next.proTeams.update(teamID) { team in
                team.staffIDs.removeAll { $0 == coach.id }
            }
        }
        _ = next.programmes.update(programmeID) { programme in
            programme.staffIDs = programme.staffIDs
                .filter { $0 != headCoachIDs[0] && $0 != coach.id }
                + [coach.id]
        }
        // Appended, not inserted-if-absent: a coach who resigned and was hired again already has
        // a career record, and leaving its last assignment pointing at the former programme is the
        // stale seat root integrity refuses.
        next.people.recordStaffAssignment(
            StaffCareerAssignment(
                season: state.calendar.season,
                organisationID: programmeID,
                role: .headCoach
            ),
            for: coach
        )
        next.career.setCollege(control)
        guard WorldIntegrity.check(next).isValid else {
            throw CareerControlError.missingHeadCoach
        }
        return CareerControlTransition(state: next, control: control)
    }

    /// Moves the controlled coach, and the coordinators who carry their scheme identity, to the
    /// professional team they were promoted to.
    ///
    /// The career arc records the job; the world records the chair. Leaving the chair behind is
    /// what let a promoted coach stay listed as their old programme's head coach, and kept the
    /// professional seat out of `people.staffCareers` — the one authority the coaching tree and
    /// the season history archive both read, so the promotion vanished from every history surface.
    ///
    /// `02` section 9 names the four coordinators as the subset of staff the promotion carries, and
    /// position coaches as staying put: what travels is the staff that holds scheme identity, which
    /// is the line above it in the same list. Owner decision 2026-08-20.
    static func seatProfessionalPromotion(
        teamID: UUID,
        in state: inout GameState
    ) {
        guard let coachID = state.career.coachID,
              state.staff[coachID] != nil,
              state.proTeams[teamID] != nil else { return }
        let season = state.calendar.season
        let arriving = [coachID] + coordinatorsServingWith(coachID, in: state)

        vacate(staffIDs: arriving, in: &state)

        // The incumbents of every seat the arriving group fills are displaced together, for the
        // same reason the head coach is: an organisation holds one coach per role, so a seat that
        // is being taken cannot also still be held.
        //
        // Derived from who actually arrived, never from the roles a promotion usually carries. A
        // promotion accepted while seeking brings the coach alone, and clearing the coordinator
        // seats then would empty four chairs nobody is walking into.
        let replacedRoles = Set(arriving.compactMap { state.staff[$0]?.role })
        let displaced = Set((state.proTeams[teamID]?.staffIDs ?? []).filter { staffID in
            state.staff[staffID].map { replacedRoles.contains($0.role) } ?? false
        })
        _ = state.proTeams.update(teamID) { team in
            team.staffIDs = team.staffIDs.filter {
                !arriving.contains($0) && !displaced.contains($0)
            } + arriving
        }
        for staffID in arriving {
            guard let member = state.staff[staffID] else { continue }
            state.people.recordStaffAssignment(
                StaffCareerAssignment(
                    season: season,
                    organisationID: teamID,
                    role: member.role
                ),
                for: member
            )
        }
    }

    /// The coordinators employed by whichever organisation currently seats the coach, in role
    /// order so the same promotion moves the same people on every run.
    private static func coordinatorsServingWith(
        _ coachID: UUID,
        in state: GameState
    ) -> [UUID] {
        let staffIDs = state.programmes.values.first {
            $0.staffIDs.contains(coachID)
        }?.staffIDs ?? state.proTeams.values.first {
            $0.staffIDs.contains(coachID)
        }?.staffIDs ?? []
        return StaffRole.coordinators.compactMap { role in
            staffIDs.first { state.staff[$0]?.role == role }
        }
    }

    /// Takes the controlled coach off whatever staff still lists them, appointing a successor to
    /// the seat they leave.
    ///
    /// Separation has to reach the world, not just the career state. Clearing `career.college`
    /// alone left a resigned or promoted coach standing in their old organisation's staff list as
    /// its head coach, which every staff surface then reported as current employment.
    ///
    /// Only the coach: `02` section 9 makes the staff that follows a promotion rule, not a
    /// separation rule. A coach who resigns or is fired goes nowhere and takes nobody.
    static func vacateCurrentSeat(in state: inout GameState) {
        guard let coachID = state.career.coachID else { return }
        vacate(staffIDs: [coachID], in: &state)
    }

    /// Removes each of these people from whichever organisation employs them, filling the seat
    /// each one leaves with a generated coach of the same role.
    ///
    /// The seat is found in the world rather than in `career.college`, because a promotion can
    /// also be accepted while seeking, after a resignation has already cleared that control.
    /// Career records are left alone: they are employment history, and a move is not an erasure.
    private static func vacate(staffIDs: [UUID], in state: inout GameState) {
        let season = state.calendar.season
        for staffID in staffIDs {
            guard let member = state.staff[staffID] else { continue }
            for programmeID in state.programmes.ids {
                guard state.programmes[programmeID]?.staffIDs.contains(staffID) == true,
                      let prestige = state.programmes[programmeID]?.prestige else { continue }
                let successorID = appointReplacement(
                    organisationID: programmeID,
                    prestige: prestige,
                    season: season,
                    for: member,
                    in: &state
                )
                _ = state.programmes.update(programmeID) { programme in
                    programme.staffIDs = programme.staffIDs.filter {
                        $0 != staffID
                    } + [successorID]
                }
            }
            for teamID in state.proTeams.ids {
                guard state.proTeams[teamID]?.staffIDs.contains(staffID) == true,
                      let prestige = state.proTeams[teamID]?.prestige else { continue }
                let successorID = appointReplacement(
                    organisationID: teamID,
                    prestige: prestige,
                    season: season,
                    for: member,
                    in: &state
                )
                _ = state.proTeams.update(teamID) { team in
                    team.staffIDs = team.staffIDs.filter { $0 != staffID } + [successorID]
                }
            }
        }
    }

    /// Generates and inserts a coach for a seat that is about to be vacated.
    /// `WorldIntegrity` holds every organisation to exactly one coach per role, so a vacancy is not
    /// a state the world is allowed to be in even for one intent.
    private static func appointReplacement(
        organisationID: UUID,
        prestige: Rating,
        season: Int,
        for departing: Staff,
        in state: inout GameState
    ) -> UUID {
        var ordinal = 20_000
        var successor: Staff
        repeat {
            successor = StaffPopulationGenerator.replacement(
                rootSeed: state.league.seed,
                season: season,
                organisationID: organisationID,
                prestige: prestige,
                role: departing.role,
                positionGroup: departing.positionGroup,
                ordinal: ordinal
            )
            ordinal += 1
        } while state.staff[successor.id] != nil
        state.staff.insert(successor)
        state.people.insert(
            staff: successor,
            assignment: StaffCareerAssignment(
                season: season,
                organisationID: organisationID,
                role: successor.role
            )
        )
        return successor.id
    }

    @discardableResult
    public static func setResponsibility(
        _ responsibility: CollegeCareerResponsibility,
        owner: CareerResponsibilityOwner,
        in state: inout GameState
    ) -> Bool {
        guard var control = state.career.college,
              let programme = state.programmes[control.programmeID] else { return false }
        if case let .delegated(staffID) = owner {
            guard programme.staffIDs.contains(staffID), state.staff[staffID] != nil else {
                return false
            }
        }
        control.setOwner(owner, for: responsibility)
        var proposed = state
        proposed.career.setCollege(control)
        guard WorldIntegrity.check(proposed).isValid else { return false }
        state = proposed
        return true
    }
}

/// Runs the same recruiting policy as every other programme, but only when the controlled
/// responsibility has explicitly been delegated to an employed staff member.
public enum CollegeCareerDelegationSystem {
    public static func processRecruiting(
        in state: GameState
    ) throws -> CollegeRecruitingAITransition {
        guard let control = state.career.college,
              case .delegated = control.responsibilityOwners[.recruiting] else {
            return CollegeRecruitingAITransition(
                college: state.college,
                scouting: state.scouting,
                decisions: [],
                eventPayloads: []
            )
        }
        return try CollegeRecruitingAISystem.process(
            programmeIDs: [control.programmeID],
            in: state
        )
    }
}
