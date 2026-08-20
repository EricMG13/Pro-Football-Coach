import Foundation
import FootballSimCore
import ProFootballCoachUI

/// The Recruiting Board, built from the authoritative root.
///
/// Every field here is real. `Capacity.weeklyHoursRemaining` is
/// `ProgrammeRecruitingState.contactPointsRemaining` — a genuine weekly-reset resource
/// `WorldScheduler` resets every week and `contact`/`evaluate` spend against directly.
/// `officialVisitsRemaining` is derived from it: the engine has one pooled points resource, not a
/// separate visit counter, so this is how many visits the remaining points could still afford.
public extension CoachWorldReadModelProvider {
    static func recruitingBoard(from state: GameState) -> RecruitingBoardReadModel? {
        guard let control = state.career.college,
              let programme = state.programmes[control.programmeID],
              let recruiting = state.college.programmes[control.programmeID] else { return nil }

        let recruitingOwnerIsUser = control.responsibilityOwners[.recruiting] == .user
        let fitSnapshot = RecruitingFitSnapshot(in: state)
        let prospects = recruiting.boardIDs.enumerated().compactMap { index, prospectID in
            state.prospects[prospectID].map {
                prospect(
                    $0,
                    boardRank: index + 1,
                    programmeID: programme.id,
                    recruiting: recruiting,
                    recruitingOwnerIsUser: recruitingOwnerIsUser,
                    fitSnapshot: fitSnapshot,
                    in: state
                )
            }
        }
        let boardIDs = Set(recruiting.boardIDs)
        let discovery = state.prospects.values
            .filter { prospect in
                guard !boardIDs.contains(prospect.id) else { return false }
                return state.college.prospectRecruitment[prospect.id]?.phase == .available
            }
            .sorted { lhs, rhs in
                let lhsTotal = fitSnapshot.evaluate(
                    programmeID: programme.id,
                    prospectID: lhs.id
                )?.total ?? 0
                let rhsTotal = fitSnapshot.evaluate(
                    programmeID: programme.id,
                    prospectID: rhs.id
                )?.total ?? 0
                if lhsTotal != rhsTotal { return lhsTotal > rhsTotal }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            .prefix(RecruitingBoardReadModel.maximumDiscoveryProspects)
            .map {
                discoveryProspect(
                    $0,
                    programmeID: programme.id,
                    recruiting: recruiting,
                    recruitingOwnerIsUser: recruitingOwnerIsUser,
                    fitSnapshot: fitSnapshot,
                    in: state
                )
            }

        let continueReason = state.pending.mandatoryDecisions.contains {
            $0.programmeID == programme.id
        }
            ? "Complete the pending decision in Coaching HQ before advancing."
            : nil
        return RecruitingBoardReadModel(
            snapshotID: snapshotID("recruiting", programme.id, state.calendar),
            provenance: .simulationSnapshot,
            world: worldReference(state),
            team: teamReference(programme.id, in: state),
            capacity: RecruitingBoardReadModel.Capacity(
                scholarshipSlotsRemaining: max(
                    0,
                    CollegeRules.scholarshipLimit - programme.scholarshipCount
                ),
                weeklyHoursRemaining: recruiting.contactPointsRemaining,
                officialVisitsRemaining: recruiting.contactPointsRemaining
                    / CollegeRules.visitContactCost
            ),
            positionNeeds: positionNeeds(programme, in: state),
            prospects: prospects,
            discovery: discovery,
            canContinue: continueReason == nil,
            continueReason: continueReason
        )
    }

    // MARK: - Prospects

    private static func discoveryProspect(
        _ prospect: Prospect,
        programmeID: UUID,
        recruiting: ProgrammeRecruitingState,
        recruitingOwnerIsUser: Bool,
        fitSnapshot: RecruitingFitSnapshot,
        in state: GameState
    ) -> RecruitingBoardReadModel.Prospect {
        let stableID = prospect.id.uuidString
        let boardFull = recruiting.boardIDs.count >= CollegeRules.recruitingBoardLimit
        let activePhase = state.college.phase == .active
        let portalOpen = state.college.portal.phase != .awaitingSpring
        let available = activePhase && portalOpen && !boardFull && recruitingOwnerIsUser
        let reason: String?
        if !recruitingOwnerIsUser {
            reason = "Recruiting responsibility is delegated"
        } else if !activePhase {
            reason = "Recruiting is not open in this phase"
        } else if !portalOpen {
            reason = "Recruiting is paused for the spring portal transaction"
        } else if boardFull {
            reason = "The recruiting board is full"
        } else {
            reason = nil
        }
        return RecruitingBoardReadModel.Prospect(
            stableID: stableID,
            person: CoachWorldPersonReference(
                stableID: "\(stableID)-person",
                name: prospect.fullName,
                role: label(prospect.position)
            ),
            boardRank: 0,
            position: label(prospect.position),
            hometown: hometown(prospect.originCityID, in: state),
            interest: "Untracked",
            status: "Discoverable",
            evaluation: evaluation(
                prospect.id,
                programmeID: programmeID,
                fitSnapshot: fitSnapshot,
                in: state
            ),
            relationshipHistory: [],
            choices: [CoachWorldActionChoice(
                intentID: CoachWorldIntentID(rawValue: "addToBoard"),
                title: "Add to board",
                cost: "0 contact points",
                consequence: "Starts a bounded relationship record for this prospect",
                isAvailable: available,
                unavailableReason: reason
            )]
        )
    }

    private static func prospect(
        _ prospect: Prospect,
        boardRank: Int,
        programmeID: UUID,
        recruiting: ProgrammeRecruitingState,
        recruitingOwnerIsUser: Bool,
        fitSnapshot: RecruitingFitSnapshot,
        in state: GameState
    ) -> RecruitingBoardReadModel.Prospect {
        let relationship = recruiting.relationships[prospect.id]
        return RecruitingBoardReadModel.Prospect(
            stableID: prospect.id.uuidString,
            person: CoachWorldPersonReference(
                stableID: "\(prospect.id.uuidString)-person",
                name: prospect.fullName,
                role: label(prospect.position)
            ),
            boardRank: boardRank,
            position: label(prospect.position),
            hometown: hometown(prospect.originCityID, in: state),
            interest: interestLabel(relationship?.interest ?? 0),
            status: statusLabel(prospect.id, in: state),
            evaluation: evaluation(
                prospect.id,
                programmeID: programmeID,
                fitSnapshot: fitSnapshot,
                in: state
            ),
            // The board's own bounded event ledger holds no per-prospect interaction log; the
            // domain-event history is global and retention-bounded, not indexed by prospect. G-05
            // (opponent-knowledge boundary) is the closer relative of this gap, not a fit for a
            // fabricated history here.
            relationshipHistory: [],
            choices: choices(
                for: prospect,
                relationship: relationship,
                recruiting: recruiting,
                programme: state.programmes[programmeID],
                recruitment: state.college.prospectRecruitment[prospect.id],
                programmeID: programmeID,
                cyclePhase: state.college.phase,
                recruitingOwnerIsUser: recruitingOwnerIsUser,
                in: state
            )
        )
    }

    private static func hometown(_ cityID: UUID, in state: GameState) -> String {
        guard let city = state.map.city(cityID) else { return "" }
        guard let region = state.map.regions.first(where: { $0.id == city.regionID }) else {
            return city.name
        }
        return "\(city.name), \(region.name)"
    }

    private static func interestLabel(_ interest: Int) -> String {
        switch interest {
        case ..<20: return "Cold"
        case 20..<45: return "Warm"
        case 45..<70: return "Hot"
        default: return "Locked in"
        }
    }

    /// Read from `state.college.prospectRecruitment[id].phase` — the engine's own commitment
    /// state machine — rather than inferred from board membership, which says only that the
    /// programme is pursuing the prospect, not what the prospect has decided.
    private static func statusLabel(_ prospectID: UUID, in state: GameState) -> String {
        switch state.college.prospectRecruitment[prospectID]?.phase {
        case .committed: return "Committed"
        case .signed: return "Signed"
        case .released: return "Released"
        case .available, nil: return "Uncommitted"
        }
    }

    /// The system's own fit evaluation (`RecruitingFitSystem`), not a staff-voice verdict — G-02
    /// is a different gap, about attributing a judgement to a named coach. This is the same
    /// arithmetic the AI reads to make its own offers, surfaced rather than duplicated.
    private static func evaluation(
        _ prospectID: UUID,
        programmeID: UUID,
        fitSnapshot: RecruitingFitSnapshot,
        in state: GameState
    ) -> RecruitingBoardReadModel.Evaluation {
        guard let explanation = fitSnapshot.evaluate(
            programmeID: programmeID,
            prospectID: prospectID
        ) else {
            return RecruitingBoardReadModel.Evaluation(
                verdict: "Unscored",
                schemeFit: "",
                uncertainty: "",
                citedOutliers: []
            )
        }
        let total = explanation.total
        let schemeFitValue = explanation.components.first { $0.reason == .schemeFit }?.value ?? 0
        let confidence = state.scouting.observation(
            observerID: programmeID,
            prospectID: prospectID
        )?.confidence
        let outliers = explanation.components
            .sorted { abs($0.value) > abs($1.value) }
            .prefix(2)
            .map { "\(label($0.reason)) \($0.value >= 0 ? "+" : "")\($0.value)" }

        return RecruitingBoardReadModel.Evaluation(
            verdict: totalBand(total),
            schemeFit: componentBand(schemeFitValue),
            uncertainty: confidence.map { "Confidence \($0)%" } ?? "No evaluation yet",
            citedOutliers: outliers
        )
    }

    private static func totalBand(_ value: Int) -> String {
        // These are the same 0–100 decision bands used by the recruiting contract, so a
        // sub-threshold fit cannot be presented as an "Elite" commitment prospect.
        switch value {
        case ..<60: return "Weak"
        case 60..<70: return "Fair"
        case 70..<85: return "Strong"
        default: return "Elite"
        }
    }

    private static func componentBand(_ value: Int) -> String {
        switch value {
        case ..<0: return "Weak"
        case 0..<4: return "Fair"
        case 4..<8: return "Strong"
        default: return "Elite"
        }
    }

    /// One choice per action the engine's `RecruitingAction` actually accepts, minus
    /// `addToBoard` (already on it) and `setNILAllocation` (its own allocation screen, not this
    /// list). The intent identifier is the action's own case name, resolved back to a
    /// `RecruitingAction` by `CoachWorldReadModelProvider.recruitingAction(for:)`.
    private static func choices(
        for prospect: Prospect,
        relationship: ProgrammeProspectRelationship?,
        recruiting: ProgrammeRecruitingState,
        programme: Programme?,
        recruitment: ProspectRecruitmentState?,
        programmeID: UUID,
        cyclePhase: RecruitingCyclePhase,
        recruitingOwnerIsUser: Bool,
        in state: GameState
    ) -> [CoachWorldActionChoice] {
        let contactCost = "\(CollegeRules.aiEvaluationContactPoints) pts"
        let activePhase = cyclePhase == .active
        let portalOpen = state.college.portal.phase != .awaitingSpring
        let recruitingOpen = activePhase && portalOpen && recruitingOwnerIsUser
        let challengeAuthorized = recruitment.map {
            $0.phase == .committed
                && RecruitingCommitmentChallengePolicy.isAuthorized(
                    programmeID: programmeID,
                    prospectID: prospect.id,
                    in: state
                )
        } ?? false
        let investmentPhase = recruitment?.phase == .available || challengeAuthorized
        let pointsForContact = recruiting.contactPointsRemaining >= CollegeRules.aiEvaluationContactPoints
        let pointsForVisit = recruiting.contactPointsRemaining >= CollegeRules.visitContactCost
        let scholarshipAvailable = (programme?.scholarshipCount ?? CollegeRules.scholarshipLimit)
            < CollegeRules.scholarshipLimit
        let phaseReason: String
        if !recruitingOwnerIsUser {
            phaseReason = "Recruiting responsibility is delegated"
        } else if !activePhase {
            phaseReason = "Recruiting is not open in this phase"
        } else if !portalOpen {
            phaseReason = "Recruiting is paused for the spring portal transaction"
        } else {
            phaseReason = "Recruiting is not open in this phase"
        }
        let onBoard = relationship != nil
        let boardReason = "This prospect is not on this programme's board"
        let prospectReason: String
        switch recruitment?.phase {
        case .signed: prospectReason = "This prospect has signed"
        case .released: prospectReason = "This prospect was released"
        case .committed where !challengeAuthorized:
            prospectReason = "This prospect is committed elsewhere"
        default: prospectReason = "This prospect is not available"
        }
        var built: [CoachWorldActionChoice] = [
            CoachWorldActionChoice(
                intentID: CoachWorldIntentID(rawValue: "contact"),
                title: "Contact",
                cost: contactCost,
                consequence: "Raises interest",
                isAvailable: recruitingOpen && onBoard && investmentPhase && pointsForContact,
                unavailableReason: !recruitingOpen ? phaseReason
                    : !onBoard ? boardReason
                    : !investmentPhase ? prospectReason
                    : "Only \(recruiting.contactPointsRemaining) contact points remain"
            ),
            CoachWorldActionChoice(
                intentID: CoachWorldIntentID(rawValue: "evaluate"),
                title: "Evaluate",
                cost: contactCost,
                consequence: "Narrows the fog on their true ratings",
                isAvailable: recruitingOpen && onBoard && investmentPhase && pointsForContact,
                unavailableReason: !recruitingOpen ? phaseReason
                    : !onBoard ? boardReason
                    : !investmentPhase ? prospectReason
                    : "Only \(recruiting.contactPointsRemaining) contact points remain"
            ),
        ]
        if relationship?.visitScheduled != true {
            built.append(CoachWorldActionChoice(
                intentID: CoachWorldIntentID(rawValue: "scheduleVisit"),
                title: "Schedule visit",
                cost: "\(CollegeRules.visitContactCost) pts",
                consequence: "Creates a commitment window",
                isAvailable: recruitingOpen && onBoard && investmentPhase && pointsForVisit,
                unavailableReason: !recruitingOpen ? phaseReason
                    : !onBoard ? boardReason
                    : !investmentPhase ? prospectReason
                    : "Only \(recruiting.contactPointsRemaining) contact points remain"
            ))
        }
        if relationship?.scholarshipOffered != true {
            built.append(CoachWorldActionChoice(
                intentID: CoachWorldIntentID(rawValue: "offerScholarship"),
                title: "Offer scholarship",
                cost: "1 slot",
                consequence: "Commits a scholarship slot",
                isAvailable: recruitingOpen && onBoard && investmentPhase && scholarshipAvailable,
                unavailableReason: !recruitingOpen ? phaseReason
                    : !onBoard ? boardReason
                    : !investmentPhase ? prospectReason
                    : "No scholarship slots remain"
            ))
        }
        built.append(CoachWorldActionChoice(
            intentID: CoachWorldIntentID(rawValue: "withdraw"),
            title: "Withdraw",
            cost: "Ends the relationship",
            consequence: "Drops recorded interest, any scheduled visit and any scholarship offer",
            isAvailable: recruitingOpen && onBoard && (recruitment?.phase == .available
                || (recruitment?.phase == .committed && recruitment?.programmeID != programmeID)),
            unavailableReason: !recruitingOpen ? phaseReason
                : !onBoard ? boardReason
                : recruitment?.phase == .signed ? "This prospect has signed"
                : recruitment?.phase == .released ? "This prospect was released"
                : recruitment?.phase == .committed ? "This prospect is committed to this programme"
                : "This prospect is not on an active board"
        ))
        return built
    }

    // MARK: - Position needs

    private static func positionNeeds(
        _ programme: Programme,
        in state: GameState
    ) -> [RecruitingBoardReadModel.PositionNeed] {
        var counts: [Position: Int] = [:]
        for playerID in programme.rosterIDs {
            guard let position = state.players[playerID]?.position else { continue }
            counts[position, default: 0] += 1
        }
        return Position.allCases.compactMap { position in
            guard let target = SharedRules.minimumPlayableRosterByPosition[position] else {
                return nil
            }
            return RecruitingBoardReadModel.PositionNeed(
                stableID: "\(programme.id.uuidString)-\(position.rawValue)",
                position: label(position),
                target: target,
                committed: counts[position, default: 0]
            )
        }
    }

    // MARK: - Intent mapping

    /// The inverse of `choices(for:relationship:)`: turns the intent identifier a committed choice
    /// carries back into the `RecruitingAction` `CareerSession` expects.
    ///
    /// The point cost is `CollegeRules.aiEvaluationContactPoints` — the same fixed cost the AI
    /// itself pays for a contact or an evaluation, not a separate number invented for the player.
    /// A programme with fewer points remaining than that refuses the action and the refusal is
    /// reported verbatim, the same as any other intent this app resolves.
    static func recruitingAction(for intentID: CoachWorldIntentID) -> RecruitingAction? {
        switch intentID.rawValue {
        case "addToBoard": return .addToBoard
        case "contact": return .contact(points: CollegeRules.aiEvaluationContactPoints)
        case "evaluate": return .evaluate(points: CollegeRules.aiEvaluationContactPoints)
        case "scheduleVisit": return .scheduleVisit
        case "offerScholarship": return .offerScholarship
        case "withdraw": return .withdraw
        default: return nil
        }
    }

    static func label(_ reason: RecruitingPitch) -> String {
        switch reason {
        case .proximity: return "Proximity"
        case .prestige: return "Prestige"
        case .playingTime: return "Playing time"
        case .schemeFit: return "Scheme fit"
        case .relationship: return "Relationship"
        case .staffQuality: return "Staff quality"
        case .teamSuccess: return "Team success"
        case .nilOpportunity: return "NIL"
        }
    }
}
