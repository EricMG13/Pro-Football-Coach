import Foundation

public enum IntegrityCheck: String, Codable, Sendable, CaseIterable, Hashable {
    case conferenceMembership
    case divisionMembership
    case identities
    case rivalryMembership
    case playerOwnership
    case staffEmployment
    case rosterLimits
    case eventReferences
    case calendarAgreement
    case historyBound
    case scheduleReferences
    case standingsDerivation
    case statisticsDerivation
    case eligibilityTransitions
    case contractExpiry
    case observerKnowledge
    case positionalCoverage
    case competitionHistory
    case peopleState
    case staffCoverage
    case collegeState
    case portalState
    case portalHistory
    case portalKnowledge
    case careerControl
    case careerArc
    case salaryCap
    case professionalMarket
    case tacticalState
}

public enum IntegrityIssue: Sendable, Equatable, CustomStringConvertible {
    case missingConferenceMember(conferenceID: UUID, memberID: UUID)
    case conferenceMembershipMismatch(organisationID: UUID)
    case missingDivisionMember(divisionID: UUID, memberID: UUID)
    case divisionMembershipMismatch(teamID: UUID)
    case missingIdentity(ownerID: UUID)
    case missingRivalryMember(rivalryID: UUID, memberID: UUID)
    case missingPlayer(playerID: UUID, ownerID: UUID)
    case duplicatePlayerReference(playerID: UUID, ownerID: UUID)
    case duplicatePlayerOwnership(id: UUID, owners: Int)
    case missingStaff(staffID: UUID, ownerID: UUID)
    case duplicateStaffReference(staffID: UUID, ownerID: UUID)
    case duplicateStaffEmployment(id: UUID, employers: Int)
    case illegalCollegeRoster(programmeID: UUID)
    case illegalProRoster(teamID: UUID)
    case missingEventReference(eventID: UUID, entityID: UUID)
    case missingScheduledParticipant(gameID: UUID, participantID: UUID)
    case duplicateScheduledGame(gameID: UUID)
    case invalidScheduledGame(gameID: UUID)
    case invalidPostseason(tier: Tier, stage: CompetitionStage)
    case standingsDoNotMatchResults
    case statisticsDoNotMatchResults
    case missingPositionalCoverage(organisationID: UUID, position: Position)
    case competitionArchiveLimitExceeded
    case invalidSeasonArchive(season: Int)
    case invalidCompetitionRecord(gameID: UUID)
    case missingPlayerLifecycle(playerID: UUID)
    case orphanPlayerLifecycle(playerID: UUID)
    case missingPlayerCareer(playerID: UUID)
    case orphanPlayerCareer(playerID: UUID)
    case missingStaffCareer(staffID: UUID)
    case orphanStaffCareer(staffID: UUID)
    case missingStaffRole(organisationID: UUID, role: StaffRole, group: PositionGroup?)
    case invalidStaffProfile(staffID: UUID)
    case invalidPlayerLifecycle(playerID: UUID)
    case invalidPlayerCareer(playerID: UUID)
    case missingProgrammeRecruitingState(programmeID: UUID)
    case orphanProgrammeRecruitingState(programmeID: UUID)
    case invalidProgrammeRecruitingState(programmeID: UUID)
    case invalidRedshirtPlan(playerID: UUID)
    case invalidRecruitingCyclePhase(RecruitingCyclePhase)
    case invalidProspect(prospectID: UUID)
    case missingProspect(prospectID: UUID, ownerID: UUID)
    case invalidScoutingObservation(observerID: UUID, prospectID: UUID)
    case invalidPortalState
    case invalidPortalOwner(playerID: UUID, expectedProgrammeID: UUID)
    case invalidPortalScholarship(playerID: UUID)
    case invalidPortalNIL(playerID: UUID)
    case invalidPortalCareer(playerID: UUID)
    case invalidPortalReservation(programmeID: UUID)
    case invalidPortalCapacity(targetSeason: Int, window: CollegePortalWindow)
    case invalidPortalEvent(eventID: UUID)
    case invalidPortalKnowledge(observerID: UUID, playerID: UUID)
    case invalidHistoricalEvent(eventID: UUID)
    case invalidCareerControl
    case invalidCareerArc
    case invalidProfessionalCap(teamID: UUID)
    case invalidProfessionalMarket
    case invalidMandatoryDecision(decisionID: UUID)
    case invalidTacticalState
    case calendarDisagreement
    case historyLimitExceeded

    public var description: String {
        switch self {
        case let .missingConferenceMember(conferenceID, memberID):
            return "Conference \(conferenceID) references missing member \(memberID)."
        case let .conferenceMembershipMismatch(organisationID):
            return "Organisation \(organisationID) disagrees with its conference membership."
        case let .missingDivisionMember(divisionID, memberID):
            return "Division \(divisionID) references missing member \(memberID)."
        case let .divisionMembershipMismatch(teamID):
            return "Pro team \(teamID) disagrees with its division membership."
        case let .missingIdentity(ownerID):
            return "Organisation \(ownerID) has no identity."
        case let .missingRivalryMember(rivalryID, memberID):
            return "Rivalry \(rivalryID) references missing member \(memberID)."
        case let .missingPlayer(playerID, ownerID):
            return "Organisation \(ownerID) references missing player \(playerID)."
        case let .duplicatePlayerReference(playerID, ownerID):
            return "Organisation \(ownerID) repeats player \(playerID) in its roster lists."
        case let .duplicatePlayerOwnership(id, owners):
            return "Player \(id) appears on \(owners) rosters."
        case let .missingStaff(staffID, ownerID):
            return "Organisation \(ownerID) references missing staff member \(staffID)."
        case let .duplicateStaffReference(staffID, ownerID):
            return "Organisation \(ownerID) repeats staff member \(staffID) in its staff list."
        case let .duplicateStaffEmployment(id, employers):
            return "Staff member \(id) appears at \(employers) organisations."
        case let .illegalCollegeRoster(programmeID):
            return "Programme \(programmeID) exceeds an M0 roster limit."
        case let .illegalProRoster(teamID):
            return "Pro team \(teamID) exceeds an M0 roster limit."
        case let .missingEventReference(eventID, entityID):
            return "Event \(eventID) references missing entity \(entityID)."
        case let .missingScheduledParticipant(gameID, participantID):
            return "Game \(gameID) references missing participant \(participantID)."
        case let .duplicateScheduledGame(gameID):
            return "Game identifier \(gameID) appears more than once in the current schedule."
        case let .invalidScheduledGame(gameID):
            return "Game \(gameID) violates its tier, week, participant, or result contract."
        case let .invalidPostseason(tier, stage):
            return "The \(tier.rawValue) \(stage.rawValue) field is malformed or unearned."
        case .standingsDoNotMatchResults:
            return "Stored standings or rankings do not derive from completed games."
        case .statisticsDoNotMatchResults:
            return "Stored team or player statistics do not derive from completed games."
        case let .missingPositionalCoverage(organisationID, position):
            return "Organisation \(organisationID) lacks playable coverage at \(position.rawValue)."
        case .competitionArchiveLimitExceeded:
            return "Competition history exceeds its bounded archive limit."
        case let .invalidSeasonArchive(season):
            return "The competition archive for season \(season) has invalid references or totals."
        case let .invalidCompetitionRecord(gameID):
            return "Competition record \(gameID) has invalid historical context."
        case let .missingPlayerLifecycle(playerID):
            return "Player \(playerID) has no lifecycle state."
        case let .orphanPlayerLifecycle(playerID):
            return "Lifecycle state references missing player \(playerID)."
        case let .missingPlayerCareer(playerID):
            return "Player \(playerID) has no career record."
        case let .orphanPlayerCareer(playerID):
            return "Career state references missing player \(playerID)."
        case let .missingStaffCareer(staffID):
            return "Staff member \(staffID) has no career record."
        case let .orphanStaffCareer(staffID):
            return "Career state references missing staff member \(staffID)."
        case let .missingStaffRole(organisationID, role, group):
            let groupText = group.map { " for \($0.rawValue)" } ?? ""
            return "Organisation \(organisationID) lacks exactly one \(role.rawValue)\(groupText)."
        case let .invalidStaffProfile(staffID):
            return "Staff member \(staffID) violates age, role, rating, or career-employment rules."
        case let .invalidPlayerLifecycle(playerID):
            return "Player \(playerID) violates tier, eligibility, availability, or departure state."
        case let .invalidPlayerCareer(playerID):
            return "Player \(playerID) has malformed or unresolved career history."
        case let .missingProgrammeRecruitingState(programmeID):
            return "Programme \(programmeID) has no college management state."
        case let .orphanProgrammeRecruitingState(programmeID):
            return "College management state references missing programme \(programmeID)."
        case let .invalidProgrammeRecruitingState(programmeID):
            return "Programme \(programmeID) violates recruiting, scholarship, or resource rules."
        case let .invalidRedshirtPlan(playerID):
            return "Player \(playerID) has an invalid current-season redshirt plan."
        case let .invalidRecruitingCyclePhase(phase):
            return "The stable college root cannot persist the \(phase.rawValue) recruiting phase."
        case let .invalidProspect(prospectID):
            return "Prospect \(prospectID) violates identity, origin, or recruitment rules."
        case let .missingProspect(prospectID, ownerID):
            return "Programme \(ownerID) references missing prospect \(prospectID)."
        case let .invalidScoutingObservation(observerID, prospectID):
            return "Observer \(observerID) has invalid knowledge for prospect \(prospectID)."
        case .invalidPortalState:
            return "The college portal disagrees with its stable season, phase, or summary."
        case let .invalidPortalOwner(playerID, expectedProgrammeID):
            return "Portal player \(playerID) is not owned exactly once by \(expectedProgrammeID)."
        case let .invalidPortalScholarship(playerID):
            return "Portal player \(playerID) disagrees with the durable scholarship outcome."
        case let .invalidPortalNIL(playerID):
            return "Portal player \(playerID) disagrees with the durable roster NIL outcome."
        case let .invalidPortalCareer(playerID):
            return "Portal player \(playerID) is missing or repeats a durable window record."
        case let .invalidPortalReservation(programmeID):
            return "Programme \(programmeID) retains a transient portal NIL reservation."
        case let .invalidPortalCapacity(targetSeason, window):
            return "Portal capacity is inconsistent for season \(targetSeason) \(window.rawValue)."
        case let .invalidPortalEvent(eventID):
            return "Portal event \(eventID) disagrees with durable career history."
        case let .invalidPortalKnowledge(observerID, playerID):
            return "Programme \(observerID) retains invalid portal knowledge for \(playerID)."
        case let .invalidHistoricalEvent(eventID):
            return "Event \(eventID) violates its immutable domain context."
        case .invalidCareerControl:
            return "The controlled coaching career disagrees with staff employment or authority."
        case .invalidCareerArc:
            return "The coaching career arc has invalid employment, support, or opportunity history."
        case let .invalidProfessionalCap(teamID):
            return "Pro team \(teamID) exceeds its salary cap or has malformed contracts."
        case .invalidProfessionalMarket:
            return "The professional free-agency or draft market is malformed or out of phase."
        case let .invalidMandatoryDecision(decisionID):
            return "Mandatory decision \(decisionID) references invalid authority or state."
        case .invalidTacticalState:
            return "Tactical plans, scouting, or game-plan reviews disagree with the authoritative world."
        case .calendarDisagreement:
            return "The root and league calendars disagree or are outside the shared season."
        case .historyLimitExceeded:
            return "The hot event ledger exceeds its retention bound."
        }
    }
}

public struct IntegrityReport: Sendable, Equatable {
    public let issues: [IntegrityIssue]
    public let activeChecks: [IntegrityCheck]
    public let inactiveChecks: [IntegrityCheck]

    public init(
        issues: [IntegrityIssue],
        activeChecks: [IntegrityCheck],
        inactiveChecks: [IntegrityCheck]
    ) {
        self.issues = issues
        self.activeChecks = activeChecks
        self.inactiveChecks = inactiveChecks
    }

    public var isValid: Bool { issues.isEmpty }
}

public enum WorldIntegrity {
    public static let activeChecks: [IntegrityCheck] = [
        .conferenceMembership,
        .divisionMembership,
        .identities,
        .rivalryMembership,
        .playerOwnership,
        .staffEmployment,
        .rosterLimits,
        .scheduleReferences,
        .standingsDerivation,
        .statisticsDerivation,
        .positionalCoverage,
        .competitionHistory,
        .peopleState,
        .staffCoverage,
        .collegeState,
        .portalState,
        .portalHistory,
        .portalKnowledge,
        .careerControl,
        .careerArc,
        .salaryCap,
        .professionalMarket,
        .tacticalState,
        .observerKnowledge,
        .eligibilityTransitions,
        .eventReferences,
        .calendarAgreement,
        .historyBound,
    ]

    public static let inactiveChecks: [IntegrityCheck] = IntegrityCheck.allCases.filter {
        !activeChecks.contains($0)
    }

    public static func check(_ state: GameState) -> IntegrityReport {
        var issues: [IntegrityIssue] = []
        let organisationIDs = state.programmes.ids + state.proTeams.ids
        let organisationIDSet = Set(organisationIDs)
        let programmeIDSet = Set(state.programmes.ids)
        let proTeamIDSet = Set(state.proTeams.ids)

        for conference in state.league.conferences {
            let legalMembers = conference.tier == .college
                ? programmeIDSet
                : proTeamIDSet
            for memberID in conference.memberIDs where !legalMembers.contains(memberID) {
                issues.append(.missingConferenceMember(
                    conferenceID: conference.id,
                    memberID: memberID
                ))
            }
        }

        for programme in state.programmes.values {
            let memberships = state.league.conferences.filter {
                $0.tier == .college && $0.memberIDs.contains(programme.id)
            }
            guard let conferenceID = programme.conferenceID,
                  memberships.count == 1,
                  memberships[0].id == conferenceID else {
                issues.append(.conferenceMembershipMismatch(organisationID: programme.id))
                continue
            }
        }
        for team in state.proTeams.values {
            let memberships = state.league.conferences.filter {
                $0.tier == .pro && $0.memberIDs.contains(team.id)
            }
            guard let conferenceID = team.conferenceID,
                  memberships.count == 1,
                  memberships[0].id == conferenceID else {
                issues.append(.conferenceMembershipMismatch(organisationID: team.id))
                continue
            }
        }


        checkSchedule(state, issues: &issues)
        checkPostseason(state, issues: &issues)
        checkPositionalCoverage(state, issues: &issues)
        checkCompetitionHistory(state, issues: &issues)
        checkPeopleState(state, issues: &issues)
        checkStaffCoverage(state, issues: &issues)
        checkCollegeState(state, issues: &issues)
        checkPortalState(state, issues: &issues)
        checkCareerControl(state, issues: &issues)
        checkCareerArc(state, issues: &issues)
        checkProfessionalCap(state, issues: &issues)
        checkProfessionalMarket(state, issues: &issues)
        checkMandatoryDecisions(state, issues: &issues)
        checkTacticalState(state, issues: &issues)

        let derived = CompetitionReducer.rebuild(from: state)
        if state.competition.standings != derived.standings
            || state.competition.rankings != derived.rankings {
            issues.append(.standingsDoNotMatchResults)
        }
        if state.competition.teamStatistics != derived.teamStatistics
            || state.competition.playerStatistics != derived.playerStatistics {
            issues.append(.statisticsDoNotMatchResults)
        }

        for division in state.league.divisions {
            for memberID in division.memberIDs where !proTeamIDSet.contains(memberID) {
                issues.append(.missingDivisionMember(divisionID: division.id, memberID: memberID))
            }
        }
        for team in state.proTeams.values {
            let memberships = state.league.divisions.filter { $0.memberIDs.contains(team.id) }
            guard let divisionID = team.divisionID,
                  memberships.count == 1,
                  memberships[0].id == divisionID else {
                issues.append(.divisionMembershipMismatch(teamID: team.id))
                continue
            }
        }

        for ownerID in organisationIDs where state.identities[ownerID] == nil {
            issues.append(.missingIdentity(ownerID: ownerID))
        }
        for rivalry in state.rivalries.values {
            for memberID in [rivalry.sideA, rivalry.sideB]
                where !organisationIDSet.contains(memberID) {
                issues.append(.missingRivalryMember(rivalryID: rivalry.id, memberID: memberID))
            }
        }

        var playerOwners: [UUID: Int] = [:]
        var staffEmployers: [UUID: Int] = [:]
        for programme in state.programmes.values {
            inspectPlayerIDs(
                programme.rosterIDs,
                ownerID: programme.id,
                state: state,
                counts: &playerOwners,
                issues: &issues
            )
            inspectStaffIDs(
                programme.staffIDs,
                ownerID: programme.id,
                state: state,
                counts: &staffEmployers,
                issues: &issues
            )
            if !programme.rosterLegality.isLegal {
                issues.append(.illegalCollegeRoster(programmeID: programme.id))
            }
        }
        for team in state.proTeams.values {
            inspectPlayerIDs(
                team.rosterIDs + team.practiceSquadIDs,
                ownerID: team.id,
                state: state,
                counts: &playerOwners,
                issues: &issues
            )
            inspectStaffIDs(
                team.staffIDs,
                ownerID: team.id,
                state: state,
                counts: &staffEmployers,
                issues: &issues
            )
            if !team.rosterLegality.isLegal {
                issues.append(.illegalProRoster(teamID: team.id))
            }
        }
        for id in playerOwners.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let owners = playerOwners[id], owners > 1 else { continue }
            issues.append(.duplicatePlayerOwnership(id: id, owners: owners))
        }
        for id in staffEmployers.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let employers = staffEmployers[id], employers > 1 else { continue }
            issues.append(.duplicateStaffEmployment(id: id, employers: employers))
        }

        let allEntityIDs = organisationIDSet
            .union(state.players.ids)
            .union(state.people.departedPlayers.keys)
            .union(state.prospects.ids)
            .union(state.college.archivedProspects.keys)
            .union(state.staff.ids)
            .union(state.rivalries.ids)
            .union(state.competition.currentSchedule.games.map(\.id))
            .union(state.proMarket.draftClass.map(\.id))
            .union(state.proMarket.archivedDraftProspectIDs)
        var redshirtResolutionSeasonsByPlayer: [UUID: Set<Int>] = [:]
        for event in state.history.recent {
            for entityID in event.payload.referencedEntityIDs where !allEntityIDs.contains(entityID) {
                issues.append(.missingEventReference(eventID: event.id, entityID: entityID))
            }
            var historicalEventIsValid = !occurs(state.calendar, before: event.occurredAt)
            switch event.payload {
            case let .redshirtResolved(
                playerID,
                programmeID,
                appearances,
                plannedAppearanceLimit,
                outcome
            ):
                let outcomeMatchesUsage = (outcome == .preservedCompetitionSeason
                    && appearances <= CollegeRules.maximumRedshirtAppearances)
                    || (outcome == .burnedByUsage
                        && appearances > CollegeRules.maximumRedshirtAppearances)
                let careerMatches = state.people.playerCareers[playerID]?.seasons.contains {
                    season in
                    season.season == event.occurredAt.season
                        && season.organisationID == programmeID
                        && season.tier == .college
                        && season.games == appearances
                        && season.redshirtResolution?.outcome == outcome
                        && season.redshirtResolution?.plannedAppearanceLimit
                            == plannedAppearanceLimit
                } == true
                let isUniqueResolution = redshirtResolutionSeasonsByPlayer[
                    playerID,
                    default: []
                ].insert(event.occurredAt.season).inserted
                historicalEventIsValid = historicalEventIsValid
                    && event.occurredAt.week == SharedRules.inSeasonWeeks
                    && (0...CollegeRules.maximumGamesPerSeason).contains(appearances)
                    && CollegeRules.redshirtAppearanceLimitRange.contains(
                        plannedAppearanceLimit
                    )
                    && outcomeMatchesUsage
                    && careerMatches
                    && isUniqueResolution
            case let .prospectCommitted(prospectID, context):
                let activeRecruitmentMatches = state.prospects[prospectID] != nil
                    && state.college.prospectRecruitment[prospectID]?
                        .commitmentHistory.contains(context) == true
                let playerOriginMatches = (state.players[prospectID] != nil
                    || state.people.departedPlayers[prospectID] != nil)
                    && state.people.playerCareers[prospectID]?.recruitingOrigin?
                        .commitmentHistory.contains(context) == true
                let archivedIdentityMatches = state.college.archivedProspects[prospectID]?
                    .recruitingSeason == context.committedAt.season
                historicalEventIsValid = historicalEventIsValid
                    && context.isValid
                    && event.occurredAt == context.committedAt
                    && (activeRecruitmentMatches
                        || playerOriginMatches
                        || archivedIdentityMatches)
            case let .commitmentResolved(prospectID, programmeID, outcome):
                let career = state.people.playerCareers[prospectID]
                let isPlayerIdentity = state.players[prospectID] != nil
                    || state.people.departedPlayers[prospectID] != nil
                let terminalCategoryIsValid: Bool
                switch outcome {
                case .signed:
                    terminalCategoryIsValid = isPlayerIdentity
                        && state.prospects[prospectID] == nil
                        && career?.recruitingOrigin?.programmeID == programmeID
                        && career?.recruitingOrigin?.signedAt == event.occurredAt
                case .released:
                    terminalCategoryIsValid = !isPlayerIdentity
                        && state.prospects[prospectID] == nil
                        && state.college.archivedProspects[prospectID]?.recruitingSeason
                            == event.occurredAt.season
                }
                historicalEventIsValid = historicalEventIsValid && terminalCategoryIsValid
            default:
                break
            }
            if !historicalEventIsValid {
                issues.append(.invalidHistoricalEvent(eventID: event.id))
            }
        }

        if state.calendar.season != state.league.season
            || state.calendar.week != state.league.week
            || !(1...SharedRules.inSeasonWeeks).contains(state.calendar.week) {
            issues.append(.calendarDisagreement)
        }
        if state.history.recent.count > state.history.retentionLimit {
            issues.append(.historyLimitExceeded)
        }

        return IntegrityReport(
            issues: issues,
            activeChecks: activeChecks,
            inactiveChecks: inactiveChecks
        )
    }

    private static func checkTacticalState(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        guard state.tactical.calendar == state.calendar else {
            issues.append(.invalidTacticalState)
            return
        }
        let organisationIDs = Set(state.programmes.ids + state.proTeams.ids)
        for (organisationID, record) in state.tactical.plansByOrganisation {
            if !organisationIDs.contains(organisationID) || record.calendar != state.calendar {
                issues.append(.invalidTacticalState)
            }
        }
        for (organisationID, record) in state.tactical.practicePlansByOrganisation {
            if !organisationIDs.contains(organisationID) || record.calendar != state.calendar {
                issues.append(.invalidTacticalState)
            }
        }
        for (opponentID, snapshot) in state.tactical.opponentScouting {
            if !organisationIDs.contains(opponentID)
                || !isCalendar(onOrBefore: snapshot.observedThrough, state.calendar) {
                issues.append(.invalidTacticalState)
            }
        }
        for review in state.tactical.reviews {
            if !organisationIDs.contains(review.organisationID)
                || !organisationIDs.contains(review.opponentID)
                || !isCalendar(onOrBefore: review.calendar, state.calendar) {
                issues.append(.invalidTacticalState)
            }
        }
    }

    private static func isCalendar(
        onOrBefore lhs: CalendarState,
        _ rhs: CalendarState
    ) -> Bool {
        lhs.season < rhs.season
            || (lhs.season == rhs.season && lhs.week <= rhs.week)
    }

    private static func inspectPlayerIDs(
        _ ids: [UUID],
        ownerID: UUID,
        state: GameState,
        counts: inout [UUID: Int],
        issues: inout [IntegrityIssue]
    ) {
        var seen: Set<UUID> = []
        for id in ids {
            guard seen.insert(id).inserted else {
                issues.append(.duplicatePlayerReference(playerID: id, ownerID: ownerID))
                continue
            }
            counts[id, default: 0] += 1
            if state.players[id] == nil {
                issues.append(.missingPlayer(playerID: id, ownerID: ownerID))
            }
        }
    }

    private static func inspectStaffIDs(
        _ ids: [UUID],
        ownerID: UUID,
        state: GameState,
        counts: inout [UUID: Int],
        issues: inout [IntegrityIssue]
    ) {
        var seen: Set<UUID> = []
        for id in ids {
            guard seen.insert(id).inserted else {
                issues.append(.duplicateStaffReference(staffID: id, ownerID: ownerID))
                continue
            }
            counts[id, default: 0] += 1
            if state.staff[id] == nil {
                issues.append(.missingStaff(staffID: id, ownerID: ownerID))
            }
        }
    }

    private static func checkSchedule(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        var gameIDs: Set<UUID> = []
        var weeklyParticipants: Set<ScheduleAppearance> = []
        let collegeIDs = Set(state.programmes.ids)
        let proTeamIDs = Set(state.proTeams.ids)
        let scheduleSeasonIsCurrent = state.competition.currentSchedule.season == state.calendar.season
            || (state.calendar.week == SharedRules.inSeasonWeeks
                && state.competition.currentSchedule.season == state.calendar.season + 1)
        if !scheduleSeasonIsCurrent {
            for game in state.competition.currentSchedule.games {
                issues.append(.invalidScheduledGame(gameID: game.id))
            }
        }

        for game in state.competition.currentSchedule.games {
            if !gameIDs.insert(game.id).inserted {
                issues.append(.duplicateScheduledGame(gameID: game.id))
            }
            let legalIDs = game.tier == .college ? collegeIDs : proTeamIDs
            for participantID in [game.homeID, game.awayID] where !legalIDs.contains(participantID) {
                issues.append(.missingScheduledParticipant(
                    gameID: game.id,
                    participantID: participantID
                ))
            }
            let resultIsValid = game.result.map {
                $0.homeScore != $0.awayScore
                    && $0.homeStatistics.points == $0.homeScore
                    && $0.awayStatistics.points == $0.awayScore
                    && $0.homeStatistics.passingYards + $0.homeStatistics.rushingYards
                        == $0.homeStatistics.offensiveYards
                    && $0.awayStatistics.passingYards + $0.awayStatistics.rushingYards
                        == $0.awayStatistics.offensiveYards
                    && CompetitionRules.offensiveYardRange.contains(
                        $0.homeStatistics.offensiveYards
                    )
                    && CompetitionRules.offensiveYardRange.contains(
                        $0.awayStatistics.offensiveYards
                    )
                    && CompetitionRules.turnoverRange.contains($0.homeStatistics.turnovers)
                    && CompetitionRules.turnoverRange.contains($0.awayStatistics.turnovers)
                    && validResultParticipants($0, game: game, state: state)
            } ?? true
            if game.homeID == game.awayID
                || game.season != state.competition.currentSchedule.season
                || !validWeek(game.week, stage: game.stage, tier: game.tier)
                || !resultIsValid {
                issues.append(.invalidScheduledGame(gameID: game.id))
            }
            for participantID in [game.homeID, game.awayID] {
                let appearance = ScheduleAppearance(
                    season: game.season,
                    week: game.week,
                    tier: game.tier,
                    participantID: participantID
                )
                if !weeklyParticipants.insert(appearance).inserted {
                    issues.append(.invalidScheduledGame(gameID: game.id))
                }
            }
        }
    }

    private static func validResultParticipants(
        _ result: GameSummary,
        game: ScheduledGame,
        state: GameState
    ) -> Bool {
        let homeRoster: Set<UUID>
        let awayRoster: Set<UUID>
        switch game.tier {
        case .college:
            homeRoster = Set(state.programmes[game.homeID]?.rosterIDs ?? [])
            awayRoster = Set(state.programmes[game.awayID]?.rosterIDs ?? [])
        case .pro:
            homeRoster = Set(state.proTeams[game.homeID]?.rosterIDs ?? [])
            awayRoster = Set(state.proTeams[game.awayID]?.rosterIDs ?? [])
        }
        let homeParticipants = Set(result.homeParticipantIDs)
        let awayParticipants = Set(result.awayParticipantIDs)
        let participants = homeParticipants.union(awayParticipants)
        let lineIDs = result.playerStatistics.map(\.playerID)

        // FSC-013. Checking participants against the roster an organisation holds *now* is truthful
        // only while ownership never changes inside a live season. The moment anything releases a
        // player mid-season — a trade, a cut, or a contract expiring in the final week — every game
        // they had already played became invalid, which is a false accusation about the past rather
        // than a real defect in it.
        //
        // A player's career record already says which organisation they belonged to in which season,
        // bounded and persisted since M2, so no new state is needed. Tenure legalises a *departure*,
        // never an impostor: it must name this organisation and this season.
        func belonged(_ playerID: UUID, to organisationID: UUID) -> Bool {
            state.people.playerCareers[playerID]?.seasons.contains {
                $0.organisationID == organisationID && $0.season == game.season
            } ?? false
        }

        return homeParticipants.allSatisfy {
            homeRoster.contains($0) || belonged($0, to: game.homeID)
        }
            && awayParticipants.allSatisfy {
                awayRoster.contains($0) || belonged($0, to: game.awayID)
            }
            && participants.allSatisfy { state.players[$0] != nil }
            && Set(lineIDs).count == lineIDs.count
            && Set(lineIDs).isSubset(of: participants)
    }

    private static func checkCompetitionHistory(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        if state.competition.archives.count > CompetitionState.archiveLimit {
            issues.append(.competitionArchiveLimitExceeded)
        }

        let collegeIDs = Set(state.programmes.ids)
        let proTeamIDs = Set(state.proTeams.ids)
        let playerIDs = Set(state.players.ids).union(state.people.departedPlayers.keys)
        var archiveSeasons: Set<Int> = []
        for archive in state.competition.archives {
            let rankingsAreValid = archive.finalCollegeRanking.count == collegeIDs.count
                && Set(archive.finalCollegeRanking) == collegeIDs
                && archive.finalProRanking.count == proTeamIDs.count
                && Set(archive.finalProRanking) == proTeamIDs
            let awardKeys = archive.awards.map { "\($0.tier.rawValue)|\($0.kind.rawValue)" }
            let awardsAreValid = archive.awards.count == Tier.allCases.count
                    * SeasonAwardKind.allCases.count
                && Set(awardKeys).count == archive.awards.count
                && archive.awards.allSatisfy { award in
                switch (award.kind, award.tier) {
                case (.champion, .college):
                    return award.winnerID == archive.collegeChampionID
                case (.champion, .pro):
                    return award.winnerID == archive.proChampionID
                case (.topOffense, .college):
                    return collegeIDs.contains(award.winnerID)
                case (.topOffense, .pro):
                    return proTeamIDs.contains(award.winnerID)
                case (.playerOfTheYear, _):
                    return playerIDs.contains(award.winnerID)
                }
            }
            if !archiveSeasons.insert(archive.season).inserted
                || !collegeIDs.contains(archive.collegeChampionID)
                || !proTeamIDs.contains(archive.proChampionID)
                || !rankingsAreValid
                || !awardsAreValid
                || archive.gamesPlayed == 0
                || archive.totalPoints == 0 {
                issues.append(.invalidSeasonArchive(season: archive.season))
            }
        }

        for record in [
            state.competition.recordBook.highestTeamScore,
            state.competition.recordBook.mostTeamYards,
        ].compactMap({ $0 }) where !validRecord(record, state: state) {
            issues.append(.invalidCompetitionRecord(gameID: record.gameID))
        }
    }

    private static func validRecord(_ record: TeamGameRecordEntry, state: GameState) -> Bool {
        guard record.teamID != record.opponentID,
              validWeek(record.week, stage: record.stage, tier: record.tier) else {
            return false
        }
        switch record.tier {
        case .college:
            return state.programmes[record.teamID] != nil
                && state.programmes[record.opponentID] != nil
        case .pro:
            return state.proTeams[record.teamID] != nil
                && state.proTeams[record.opponentID] != nil
        }
    }

    private static func checkPeopleState(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let playerIDs = Set(state.players.ids)
        let departedPlayerIDs = Set(state.people.departedPlayers.keys)
        let allPlayerIDs = playerIDs.union(departedPlayerIDs)
        let lifecycleIDs = Set(state.people.playerLifecycle.keys)
        let playerCareerIDs = Set(state.people.playerCareers.keys)
        for id in playerIDs.subtracting(lifecycleIDs).sorted(by: uuidLessThan) {
            issues.append(.missingPlayerLifecycle(playerID: id))
        }
        for id in lifecycleIDs.subtracting(playerIDs).sorted(by: uuidLessThan) {
            issues.append(.orphanPlayerLifecycle(playerID: id))
        }
        for id in allPlayerIDs.subtracting(playerCareerIDs).sorted(by: uuidLessThan) {
            issues.append(.missingPlayerCareer(playerID: id))
        }
        for id in playerCareerIDs.subtracting(allPlayerIDs).sorted(by: uuidLessThan) {
            issues.append(.orphanPlayerCareer(playerID: id))
        }
        for id in departedPlayerIDs.intersection(playerIDs).sorted(by: uuidLessThan) {
            issues.append(.invalidPlayerLifecycle(playerID: id))
        }

        let staffIDs = Set(state.staff.ids)
        let staffCareerIDs = Set(state.people.staffCareers.keys)
        for id in staffIDs.subtracting(staffCareerIDs).sorted(by: uuidLessThan) {
            issues.append(.missingStaffCareer(staffID: id))
        }
        for id in staffCareerIDs.subtracting(staffIDs).sorted(by: uuidLessThan) {
            issues.append(.orphanStaffCareer(staffID: id))
        }

        let collegeRosterIDs = Set(state.programmes.values.flatMap(\.rosterIDs))
        let programmeIDs = Set(state.programmes.ids)
        let cityIDs = Set(state.map.cities.map(\.id))
        let proRosterIDs = Set(state.proTeams.values.flatMap {
            $0.rosterIDs + $0.practiceSquadIDs
        })
        let careerHistoryIsValid: (PlayerCareerRecord) -> Bool = { career in
            let seasonsAreChronological = zip(career.seasons, career.seasons.dropFirst())
                .allSatisfy { pair in pair.0.season < pair.1.season }
            let seasonsAreValid = career.seasons.allSatisfy { season in
                let organisationMatchesTier: Bool
                switch season.tier {
                case .college:
                    organisationMatchesTier = state.programmes[season.organisationID] != nil
                case .pro:
                    organisationMatchesTier = state.proTeams[season.organisationID] != nil
                }
                return organisationMatchesTier && season.season < state.calendar.season
            }
            let endIsValid = career.endedAt.map { endedAt in
                guard !occurs(state.calendar, before: endedAt),
                      let lastSeason = career.seasons.last else { return false }
                return endedAt.season == lastSeason.season
                    && endedAt.week == SharedRules.inSeasonWeeks
            } ?? true
            return seasonsAreChronological && seasonsAreValid && endIsValid
        }
        let recruitingOriginIsValid: (PlayerRecruitingOrigin?) -> Bool = { origin in
            origin.map { origin in
                let referencedProgrammeIDs = Set(origin.commitmentHistory.flatMap { context in
                    [context.winner.programmeID]
                        + (context.runnerUp.map { [$0.programmeID] } ?? [])
                        + (context.previousWinner.map { [$0.programmeID] } ?? [])
                        + {
                            if case let .capacityFallback(blockedPreferred)
                                = context.selectionReason {
                                return [blockedPreferred.programmeID]
                            }
                            return []
                        }()
                })
                let signingIsNotFuture = origin.signedAt.season < state.calendar.season
                    || (origin.signedAt.season == state.calendar.season
                        && origin.signedAt.week <= state.calendar.week)
                return origin.isValid
                    && cityIDs.contains(origin.originCityID)
                    && referencedProgrammeIDs.isSubset(of: programmeIDs)
                    && signingIsNotFuture
            } ?? true
        }
        for id in playerIDs.sorted(by: uuidLessThan) {
            guard let player = state.players[id],
                  let lifecycle = state.people.playerLifecycle[id],
                  let career = state.people.playerCareers[id] else { continue }
            let ageShapeIsValid = PeopleRules.playerAgeRange.contains(player.age)
            let collegeShapeIsValid = !collegeRosterIDs.contains(id)
                || (player.eligibility?.isExhausted == false
                    && player.eligibility?.isValidForActiveCollegeRoot == true
                    && player.contract == nil
                    && lifecycle.status == .active)
            let proShapeIsValid = !proRosterIDs.contains(id)
                || (player.eligibility == nil && lifecycle.status == .active)
            let departureShapeIsValid = lifecycle.status == .active
                ? career.endedAt == nil && career.endStatus == nil
                : career.endedAt != nil
                    && career.endStatus == lifecycle.status
                    && !collegeRosterIDs.contains(id)
                    && !proRosterIDs.contains(id)
            if !ageShapeIsValid
                || !collegeShapeIsValid
                || !proShapeIsValid
                || !departureShapeIsValid
                || !recruitingOriginIsValid(career.recruitingOrigin) {
                issues.append(.invalidPlayerLifecycle(playerID: id))
            }
            if !careerHistoryIsValid(career) {
                issues.append(.invalidPlayerCareer(playerID: id))
            }
        }
        for id in departedPlayerIDs.sorted(by: uuidLessThan) {
            guard let identity = state.people.departedPlayers[id],
                  let career = state.people.playerCareers[id] else { continue }
            if lifecycleIDs.contains(id)
                || career.endedAt == nil
                || career.endStatus != identity.status
                || identity.status == .active
                || !recruitingOriginIsValid(career.recruitingOrigin)
                || !careerHistoryIsValid(career) {
                issues.append(.invalidPlayerCareer(playerID: id))
            }
        }
    }

    private static func checkStaffCoverage(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let organisations = state.programmes.values.map { ($0.id, $0.staffIDs) }
            + state.proTeams.values.map { ($0.id, $0.staffIDs) }
        for (organisationID, staffIDs) in organisations {
            let staff = staffIDs.compactMap { state.staff[$0] }
            for role in [.headCoach] + StaffRole.coordinators where staff.filter({
                $0.role == role
            }).count != 1 {
                issues.append(.missingStaffRole(
                    organisationID: organisationID,
                    role: role,
                    group: nil
                ))
            }
            for group in PositionGroup.allCases where staff.filter({
                $0.role == .positionCoach && $0.positionGroup == group
            }).count != 1 {
                issues.append(.missingStaffRole(
                    organisationID: organisationID,
                    role: .positionCoach,
                    group: group
                ))
            }
            for member in staff {
                let roleShapeIsValid = member.role == .positionCoach
                    ? member.positionGroup != nil
                    : member.positionGroup == nil
                let careerMatches = state.people.staffCareers[member.id]?.assignments.last.map {
                    $0.organisationID == organisationID && $0.role == member.role
                } ?? false
                if !PeopleRules.staffAgeRange.contains(member.age)
                    || !roleShapeIsValid
                    || !CoachAttribute.allCases.allSatisfy({
                        SharedRules.ratingRange.contains(member.rating($0).value)
                    })
                    || !careerMatches {
                    issues.append(.invalidStaffProfile(staffID: member.id))
                }
            }
        }
    }

    private static func checkCollegeState(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let programmeIDs = Set(state.programmes.ids)
        let collegeProgrammeIDs = Set(state.college.programmes.keys)
        let prospectIDs = Set(state.prospects.ids)
        let archivedProspectIDs = Set(state.college.archivedProspects.keys)
        let playerIdentityIDs = Set(state.players.ids).union(state.people.departedPlayers.keys)
        let requiredArchivedProspectIDs = Set(
            state.history.recent.flatMap { $0.payload.referencedProspectIDs }
        )
            .subtracting(prospectIDs)
            .subtracting(playerIdentityIDs)
        let recruitmentIDs = Set(state.college.prospectRecruitment.keys)
        let cityIDs = Set(state.map.cities.map(\.id))

        for playerID in state.college.redshirtPlans.keys.sorted(by: uuidLessThan) {
            guard let plan = state.college.redshirtPlans[playerID] else { continue }
            let player = state.players[playerID]
            let lifecycle = state.people.playerLifecycle[playerID]
            let eligibility = player?.eligibility
            if playerID != plan.playerID
                || !plan.isStructurallyValid
                || plan.season != state.college.recruitingSeason
                || plan.season != state.calendar.season
                || state.programmes[plan.programmeID]?.rosterIDs.contains(playerID) != true
                || state.college.programmes[plan.programmeID] == nil
                || lifecycle?.status != .active
                || eligibility.map(CollegeRedshirtSystem.hasSpareClockYear) != true {
                issues.append(.invalidRedshirtPlan(playerID: playerID))
            }
        }

        if state.college.phase != .active {
            issues.append(.invalidRecruitingCyclePhase(state.college.phase))
        }
        if state.college.recruitingSeason != state.calendar.season {
            issues.append(.calendarDisagreement)
        }

        for id in programmeIDs.subtracting(collegeProgrammeIDs).sorted(by: uuidLessThan) {
            issues.append(.missingProgrammeRecruitingState(programmeID: id))
        }
        for id in collegeProgrammeIDs.subtracting(programmeIDs).sorted(by: uuidLessThan) {
            issues.append(.orphanProgrammeRecruitingState(programmeID: id))
        }

        for id in programmeIDs.intersection(collegeProgrammeIDs).sorted(by: uuidLessThan) {
            guard let programme = state.programmes[id],
                  let recruiting = state.college.programmes[id] else { continue }
            let boardSet = Set(recruiting.boardIDs)
            let relationshipIDs = Set(recruiting.relationships.keys)
            let scholarshipSet = Set(recruiting.scholarshipPlayerIDs)
            let rosterNILIDs = Set(recruiting.nilState.rosterAllocations.keys)
            let recruitingNILIDs = Set(recruiting.nilState.recruitingReservations.keys)
            let committedNIL = recruiting.nilState.rosterAllocations.values.reduce(0, +)
                + recruiting.nilState.recruitingReservations.values.reduce(0, +)
                + recruiting.nilState.portalReservations.values.reduce(0, +)
            let availableNIL = programme.resources.value
                * CollegeRules.nilBudgetPerResourcePoint
            let commitmentCapacity = CollegeCommitmentCapacitySystem.capacity(
                programmeID: id,
                in: state,
                college: state.college
            )
            if recruiting.programmeID != id
                || recruiting.nilState.programmeID != id
                || recruiting.nilState.season != state.college.recruitingSeason
                || recruiting.nilState.annualBudget != availableNIL
                || !recruiting.nilState.isValid
                || !rosterNILIDs.isSubset(of: Set(programme.rosterIDs))
                || !recruitingNILIDs.isSubset(of: boardSet)
                || !recruiting.nilState.portalReservations.isEmpty
                || recruiting.nilState.remaining + committedNIL != availableNIL
                || recruiting.boardIDs.count > CollegeRules.recruitingBoardLimit
                || boardSet.count != recruiting.boardIDs.count
                || relationshipIDs != boardSet
                || recruiting.scholarshipPlayerIDs.count > CollegeRules.scholarshipLimit
                || scholarshipSet.count != recruiting.scholarshipPlayerIDs.count
                || !scholarshipSet.isSubset(of: Set(programme.rosterIDs))
                || recruiting.scholarshipPlayerIDs.count != programme.scholarshipCount
                || !(0...CollegeRules.weeklyRecruitingContactPoints).contains(
                    recruiting.contactPointsRemaining
                )
                || recruiting.nilState.remaining < 0 {
                issues.append(.invalidProgrammeRecruitingState(programmeID: id))
            }
            if commitmentCapacity.map({
                $0.activeReservations > $0.maximumReservations
                    || !$0.preservesMinimumPositionCoverage
            }) ?? true {
                issues.append(.invalidProgrammeRecruitingState(programmeID: id))
            }
            for prospectID in boardSet.subtracting(prospectIDs).sorted(by: uuidLessThan) {
                issues.append(.missingProspect(prospectID: prospectID, ownerID: id))
            }
        }

        for id in prospectIDs.sorted(by: uuidLessThan) {
            guard let prospect = state.prospects[id] else { continue }
            let recruitment = state.college.prospectRecruitment[id]
            let programmeIsValid = recruitment?.programmeID.map(programmeIDs.contains) ?? true
            let commitmentShapeIsValid = recruitment.map { recruitment in
                guard recruitment.isValid else { return false }
                let historicalContextsAreValid = recruitment.commitmentHistory.allSatisfy {
                    context in
                    let referencedProgrammeIDs = Set(
                        [context.winner.programmeID]
                            + (context.runnerUp.map { [$0.programmeID] } ?? [])
                            + (context.previousWinner.map { [$0.programmeID] } ?? [])
                            + {
                                if case let .capacityFallback(blockedPreferred)
                                    = context.selectionReason {
                                    return [blockedPreferred.programmeID]
                                }
                                return []
                            }()
                    )
                    let calendarIsNotFuture = context.committedAt.season < state.calendar.season
                        || (context.committedAt.season == state.calendar.season
                            && context.committedAt.week <= state.calendar.week)
                    return context.committedAt.season == state.college.recruitingSeason
                        && context.committedAt.week >= CollegeRules.minimumCommitmentWeek
                        && referencedProgrammeIDs.isSubset(of: programmeIDs)
                        && calendarIsNotFuture
                }
                let finalWinnerOfferIsValid: Bool
                switch recruitment.phase {
                case .committed:
                    finalWinnerOfferIsValid = recruitment.commitmentContext.map { context in
                        guard let relationship = state.college
                            .programmes[context.winner.programmeID]?
                            .relationships[id] else { return false }
                        return relationship.scholarshipOffered
                            && relationship.interest == context.winner.relationshipInterest
                            && state.college.programmes[context.winner.programmeID]?
                                .nilAllocation(for: id) == context.winner.nilAllocation
                            && relationship.visitScheduled == context.winner.visitScheduled
                    } ?? false
                case .available:
                    finalWinnerOfferIsValid = true
                case .signed, .released:
                    finalWinnerOfferIsValid = false
                }
                return historicalContextsAreValid && finalWinnerOfferIsValid
            } ?? false
            if !CollegeRules.prospectAgeRange.contains(prospect.age)
                || !cityIDs.contains(prospect.originCityID)
                || recruitment == nil
                || recruitment?.prospectID != id
                || !programmeIsValid
                || !commitmentShapeIsValid {
                issues.append(.invalidProspect(prospectID: id))
            }
        }
        for id in recruitmentIDs.subtracting(prospectIDs).sorted(by: uuidLessThan) {
            issues.append(.invalidProspect(prospectID: id))
        }
        for id in prospectIDs.intersection(archivedProspectIDs).sorted(by: uuidLessThan) {
            issues.append(.invalidProspect(prospectID: id))
        }
        for id in prospectIDs.intersection(playerIdentityIDs).sorted(by: uuidLessThan) {
            issues.append(.invalidProspect(prospectID: id))
        }
        for id in archivedProspectIDs.intersection(playerIdentityIDs).sorted(by: uuidLessThan) {
            issues.append(.invalidProspect(prospectID: id))
        }
        for id in archivedProspectIDs.symmetricDifference(requiredArchivedProspectIDs)
            .sorted(by: uuidLessThan) {
            issues.append(.invalidProspect(prospectID: id))
        }
        if state.college.archivedProspects.count > state.history.retentionLimit {
            issues.append(.historyLimitExceeded)
        }
        for id in archivedProspectIDs.sorted(by: uuidLessThan) {
            guard let archived = state.college.archivedProspects[id] else { continue }
            if archived.id != id
                || !cityIDs.contains(archived.originCityID)
                || archived.recruitingSeason >= state.college.recruitingSeason {
                issues.append(.invalidProspect(prospectID: id))
            }
        }

        for observerID in state.scouting.observationsByObserver.keys.sorted(by: uuidLessThan) {
            for prospectID in (state.scouting.observationsByObserver[observerID] ?? [:]).keys
                .sorted(by: uuidLessThan) {
                let observation = state.scouting.observationsByObserver[observerID]?[prospectID]
                if !programmeIDs.contains(observerID)
                    || !prospectIDs.contains(prospectID)
                    || observation?.prospectID != prospectID {
                    issues.append(.invalidScoutingObservation(
                        observerID: observerID,
                        prospectID: prospectID
                    ))
                }
            }
        }
        for assignment in state.scouting.pendingEvaluations {
            if !programmeIDs.contains(assignment.observerID)
                || !prospectIDs.contains(assignment.prospectID)
                || !(1...CollegeRules.weeklyRecruitingContactPoints).contains(assignment.effort) {
                issues.append(.invalidScoutingObservation(
                    observerID: assignment.observerID,
                    prospectID: assignment.prospectID
                ))
            }
        }
    }

    private struct PortalCapacityKey: Hashable {
        let targetSeason: Int
        let window: CollegePortalWindow
        let destinationProgrammeID: UUID
    }

    private struct PortalRecordSourceKey: Hashable {
        let playerID: UUID
        let sourceProgrammeID: UUID
        let targetSeason: Int
        let window: CollegePortalWindow
    }

    private struct PortalKnowledgeKey: Hashable {
        let observerProgrammeID: UUID
        let playerID: UUID
        let sourceProgrammeID: UUID
        let targetSeason: Int
        let window: CollegePortalWindow
    }

    private enum PortalEventFactKind: String, Hashable {
        case entered
        case retention
        case offer
        case transfer
        case completion
    }

    private struct PortalEventFactKey: Hashable {
        let kind: PortalEventFactKind
        let playerID: UUID?
        let destinationProgrammeID: UUID?
        let targetSeason: Int
        let window: CollegePortalWindow
    }

    private static func checkPortalState(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let portal = state.college.portal
        let hasPortalCareerHistory = state.people.playerCareers.values.contains {
            !$0.portalWindows.isEmpty
        }
        let hasPortalEvents = state.history.recent.contains { event in
            switch event.payload {
            case .portalEntered,
                 .portalRetentionResolved,
                 .portalOfferMade,
                 .playerTransferred,
                 .portalWindowCompleted:
                return true
            default:
                return false
            }
        }
        if portal.entries.isEmpty,
           portal.summaries.isEmpty,
           state.scouting.portalKnowledgeByObserver.isEmpty,
           !hasPortalCareerHistory,
           !hasPortalEvents {
            if portal.targetSeason != state.college.recruitingSeason
                || portal.phase != .closed {
                issues.append(.invalidPortalState)
            }
            for programmeID in state.college.programmes.keys.sorted(by: uuidLessThan) {
                if state.college.programmes[programmeID]?
                    .nilState.portalReservations.isEmpty == false {
                    issues.append(.invalidPortalReservation(programmeID: programmeID))
                }
            }
            return
        }
        let programmeIDs = Set(state.programmes.ids)
        let playerIDs = Set(state.players.ids).union(state.people.departedPlayers.keys)
        let allCareerRecords = state.people.playerCareers.keys.sorted(by: uuidLessThan).flatMap {
            state.people.playerCareers[$0]?.portalWindows ?? []
        }.sorted {
            if $0.targetSeason != $1.targetSeason { return $0.targetSeason < $1.targetSeason }
            if $0.window != $1.window { return $0.window.order < $1.window.order }
            return uuidLessThan($0.playerID, $1.playerID)
        }

        var portalShapeIsValid = portal.targetSeason == state.college.recruitingSeason
        switch portal.phase {
        case .awaitingSpring:
            portalShapeIsValid = portalShapeIsValid
                && state.calendar == CalendarState(season: portal.targetSeason, week: 1)
                && portal.summaries.map(\.window) == [.postseason]
                && portal.entries.values.allSatisfy { $0.window == .postseason }
                && !state.competition.currentSchedule.games.contains {
                    $0.season == portal.targetSeason && $0.result != nil
                }
        case .closed:
            if portal.summaries.isEmpty {
                portalShapeIsValid = portalShapeIsValid && portal.entries.isEmpty
            } else {
                portalShapeIsValid = portalShapeIsValid
                    && state.calendar.season == portal.targetSeason
                    && portal.summaries.map(\.window) == [.postseason, .spring]
                    && portal.entries.values.allSatisfy { $0.window == .spring }
            }
        case .postseasonOpen, .springOpen:
            portalShapeIsValid = false
        }
        if !portalShapeIsValid {
            issues.append(.invalidPortalState)
        }

        for programmeID in state.college.programmes.keys.sorted(by: uuidLessThan) {
            if state.college.programmes[programmeID]?.nilState.portalReservations.isEmpty == false {
                issues.append(.invalidPortalReservation(programmeID: programmeID))
            }
        }

        let currentTargetRecords = allCareerRecords.filter {
            $0.targetSeason == portal.targetSeason
        }
        if portal.summaries.isEmpty && !currentTargetRecords.isEmpty {
            issues.append(.invalidPortalState)
        }
        var latestCurrentRecordByPlayer: [UUID: CollegePortalWindowRecord] = [:]
        for record in currentTargetRecords.sorted(by: {
            $0.window.order == $1.window.order
                ? uuidLessThan($0.playerID, $1.playerID)
                : $0.window.order < $1.window.order
        }) {
            latestCurrentRecordByPlayer[record.playerID] = record
        }
        for record in latestCurrentRecordByPlayer.values.sorted(by: {
            uuidLessThan($0.playerID, $1.playerID)
        }) {
            let owners = state.programmes.values.filter { $0.rosterIDs.contains(record.playerID) }
            if owners.count != 1 || owners.first?.id != record.finalProgrammeID {
                issues.append(.invalidPortalOwner(
                    playerID: record.playerID,
                    expectedProgrammeID: record.finalProgrammeID
                ))
            }
            let recruiting = state.college.programmes[record.finalProgrammeID]
            if recruiting?.scholarshipPlayerIDs.contains(record.playerID)
                != record.finalIsScholarship {
                issues.append(.invalidPortalScholarship(playerID: record.playerID))
            }
            let actualNIL = recruiting?.nilState.rosterAllocations[record.playerID] ?? 0
            if actualNIL != record.finalRosterNIL {
                issues.append(.invalidPortalNIL(playerID: record.playerID))
            }
        }
        for record in portal.entries.values.sorted(by: { uuidLessThan($0.playerID, $1.playerID) }) {
            let careerMatches = state.people.playerCareers[record.playerID]?.portalWindows.filter {
                $0 == record
            }.count ?? 0
            if careerMatches != 1 {
                issues.append(.invalidPortalCareer(playerID: record.playerID))
            }
        }

        let currentWindow = portal.summaries.last?.window
        if let currentWindow {
            let durableCurrentRecords = currentTargetRecords.filter { $0.window == currentWindow }
                .sorted { uuidLessThan($0.playerID, $1.playerID) }
            let liveCurrentRecords = portal.entries.values.sorted {
                uuidLessThan($0.playerID, $1.playerID)
            }
            if liveCurrentRecords != durableCurrentRecords {
                issues.append(.invalidPortalState)
            }
        }
        for summary in portal.summaries {
            let records = currentTargetRecords.filter { $0.window == summary.window }
            let expectedRetained = records.filter { $0.outcome == .retainedBySource }.count
            let expectedTransferred = records.filter {
                if case .transferred = $0.outcome { return true }
                return false
            }.count
            let expectedReturned = records.filter { $0.outcome == .returnedToSource }.count
            let expectedOffers = records.reduce(0) { $0 + $1.offers.count }
            if summary.entrantCount != records.count
                || summary.retainedCount != expectedRetained
                || summary.transferredCount != expectedTransferred
                || summary.returnedCount != expectedReturned
                || summary.offerCount != expectedOffers {
                issues.append(.invalidPortalState)
            }
        }

        var recordsByKey: [String: [CollegePortalWindowRecord]] = [:]
        var recordsByWindow: [String: [CollegePortalWindowRecord]] = [:]
        var transfersByPlayerAndTarget: [UUID: [Int: Int]] = [:]
        for record in allCareerRecords {
            let key = portalRecordKey(
                playerID: record.playerID,
                targetSeason: record.targetSeason,
                window: record.window
            )
            recordsByKey[key, default: []].append(record)
            recordsByWindow[portalWindowKey(
                targetSeason: record.targetSeason,
                window: record.window
            ), default: []].append(record)
            if case .transferred = record.outcome {
                transfersByPlayerAndTarget[record.playerID, default: [:]][
                    record.targetSeason,
                    default: 0
                ] += 1
            }
            if !playerIDs.contains(record.playerID)
                || !programmeIDs.contains(record.sourceProgrammeID)
                || !programmeIDs.contains(record.finalProgrammeID) {
                issues.append(.invalidPortalCareer(playerID: record.playerID))
            }
        }
        let duplicateRecordGroups = recordsByKey.values.filter { $0.count != 1 }.sorted {
            uuidLessThan($0[0].playerID, $1[0].playerID)
        }
        for records in duplicateRecordGroups {
            if let playerID = records.first?.playerID {
                issues.append(.invalidPortalCareer(playerID: playerID))
            }
        }
        let repeatedTransferPlayerIDs = transfersByPlayerAndTarget.keys.filter { playerID in
            transfersByPlayerAndTarget[playerID]?.values.contains(where: { $0 > 1 }) == true
        }.sorted(by: uuidLessThan)
        for playerID in repeatedTransferPlayerIDs {
            issues.append(.invalidPortalCareer(playerID: playerID))
        }
        checkPortalCapacity(allCareerRecords, issues: &issues)
        checkPortalEvents(
            state.history.recent,
            recordsByKey: recordsByKey,
            recordsByWindow: recordsByWindow,
            issues: &issues
        )
        checkPortalKnowledge(
            state,
            allCareerRecords: allCareerRecords,
            recordIdentities: Set(allCareerRecords.map {
                PortalRecordSourceKey(
                    playerID: $0.playerID,
                    sourceProgrammeID: $0.sourceProgrammeID,
                    targetSeason: $0.targetSeason,
                    window: $0.window
                )
            }),
            issues: &issues
        )
    }

    private static func checkPortalCapacity(
        _ records: [CollegePortalWindowRecord],
        issues: inout [IntegrityIssue]
    ) {
        var offersByCapacity: [String: [CollegePortalOffer]] = [:]
        var acceptedPositionsByCapacity: [String: [Position]] = [:]
        var capacityContextByKey: [String: PortalCapacityKey] = [:]
        for record in records {
            for offer in record.offers {
                let context = PortalCapacityKey(
                    targetSeason: record.targetSeason,
                    window: record.window,
                    destinationProgrammeID: offer.destinationProgrammeID
                )
                let key = portalCapacityKey(context)
                offersByCapacity[key, default: []].append(offer)
                capacityContextByKey[key] = context
            }
            if case let .transferred(destinationID) = record.outcome {
                let context = PortalCapacityKey(
                    targetSeason: record.targetSeason,
                    window: record.window,
                    destinationProgrammeID: destinationID
                )
                let key = portalCapacityKey(context)
                if let acceptedOffer = record.offers.first(where: {
                    $0.destinationProgrammeID == destinationID
                }) {
                    acceptedPositionsByCapacity[key, default: []].append(
                        acceptedOffer.knowledge.position
                    )
                }
                capacityContextByKey[key] = context
            }
        }
        let capacityKeys = offersByCapacity.keys.sorted()
        for key in capacityKeys {
            let offers = offersByCapacity[key] ?? []
            guard let capacity = offers.first?.fixedCapacity,
                  let context = capacityContextByKey[key] else { continue }
            let exactTerm = min(
                CollegePortalPolicyV1.maximumOfferNIL,
                capacity.nilRemaining / offers.count / 100 * 100
            )
            let reservationTotal = offers.reduce(0) { $0 + $1.nilReservation }
            let acceptedPositions = acceptedPositionsByCapacity[key] ?? []
            if !offers.allSatisfy({
                $0.fixedCapacity == capacity && $0.nilReservation == exactTerm
            }) || reservationTotal > capacity.nilRemaining
                || offers.count > min(
                    capacity.rosterOpenings,
                    capacity.scholarshipOpenings
                ) * CollegePortalPolicyV1.admissionCandidatesPerOpening
                || !capacity.acceptsPortalPositions(acceptedPositions) {
                issues.append(.invalidPortalCapacity(
                    targetSeason: context.targetSeason,
                    window: context.window
                ))
            }
        }
    }

    private static func checkPortalEvents(
        _ events: [DomainEvent],
        recordsByKey: [String: [CollegePortalWindowRecord]],
        recordsByWindow: [String: [CollegePortalWindowRecord]],
        issues: inout [IntegrityIssue]
    ) {
        var retainedFacts: Set<PortalEventFactKey> = []
        for event in events {
            let isValid: Bool
            let factKey: PortalEventFactKey?
            switch event.payload {
            case let .portalEntered(playerID, sourceID, target, window, intent):
                let key = portalRecordKey(playerID: playerID, targetSeason: target, window: window)
                isValid = recordsByKey[key]?.contains {
                    $0.sourceProgrammeID == sourceID
                        && $0.intent == intent
                        && event.occurredAt == $0.openedAt
                } ?? false
                factKey = PortalEventFactKey(
                    kind: .entered,
                    playerID: playerID,
                    destinationProgrammeID: nil,
                    targetSeason: target,
                    window: window
                )
            case let .portalRetentionResolved(
                playerID,
                sourceID,
                target,
                window,
                resolution
            ):
                let key = portalRecordKey(playerID: playerID, targetSeason: target, window: window)
                isValid = recordsByKey[key]?.contains {
                    $0.sourceProgrammeID == sourceID
                        && $0.retention == resolution
                        && event.occurredAt == $0.openedAt
                } ?? false
                factKey = PortalEventFactKey(
                    kind: .retention,
                    playerID: playerID,
                    destinationProgrammeID: nil,
                    targetSeason: target,
                    window: window
                )
            case let .portalOfferMade(playerID, sourceID, target, window, offer):
                let key = portalRecordKey(playerID: playerID, targetSeason: target, window: window)
                isValid = recordsByKey[key]?.contains {
                    $0.sourceProgrammeID == sourceID
                        && $0.offers.contains(offer)
                        && event.occurredAt == $0.openedAt
                } ?? false
                factKey = PortalEventFactKey(
                    kind: .offer,
                    playerID: playerID,
                    destinationProgrammeID: offer.destinationProgrammeID,
                    targetSeason: target,
                    window: window
                )
            case let .playerTransferred(
                playerID,
                sourceID,
                destinationID,
                target,
                window,
                sourceWasScholarship,
                finalNIL
            ):
                let key = portalRecordKey(playerID: playerID, targetSeason: target, window: window)
                isValid = recordsByKey[key]?.contains { record in
                    record.sourceProgrammeID == sourceID
                        && record.sourceWasScholarship == sourceWasScholarship
                        && record.finalRosterNIL == finalNIL
                        && record.outcome == .transferred(
                            destinationProgrammeID: destinationID
                        )
                        && event.occurredAt == record.openedAt
                } ?? false
                factKey = PortalEventFactKey(
                    kind: .transfer,
                    playerID: playerID,
                    destinationProgrammeID: destinationID,
                    targetSeason: target,
                    window: window
                )
            case let .portalWindowCompleted(summary):
                let records = recordsByWindow[portalWindowKey(
                    targetSeason: summary.targetSeason,
                    window: summary.window
                )] ?? []
                isValid = summary.completedAt
                    == summary.window.expectedCalendar(targetSeason: summary.targetSeason)
                    && event.occurredAt == summary.completedAt
                    && summary.entrantCount == records.count
                    && summary.retainedCount
                        == records.filter { $0.outcome == .retainedBySource }.count
                    && summary.transferredCount == records.filter {
                        if case .transferred = $0.outcome { return true }
                        return false
                    }.count
                    && summary.returnedCount
                        == records.filter { $0.outcome == .returnedToSource }.count
                    && summary.offerCount == records.reduce(0) { $0 + $1.offers.count }
                factKey = PortalEventFactKey(
                    kind: .completion,
                    playerID: nil,
                    destinationProgrammeID: nil,
                    targetSeason: summary.targetSeason,
                    window: summary.window
                )
            default:
                continue
            }
            let isUnique = factKey.map { retainedFacts.insert($0).inserted } ?? true
            if !isValid || !isUnique {
                issues.append(.invalidPortalEvent(eventID: event.id))
            }
        }
    }

    private static func checkPortalKnowledge(
        _ state: GameState,
        allCareerRecords: [CollegePortalWindowRecord],
        recordIdentities: Set<PortalRecordSourceKey>,
        issues: inout [IntegrityIssue]
    ) {
        let programmeIDs = Set(state.programmes.ids)
        let playerIDs = Set(state.players.ids).union(state.people.departedPlayers.keys)
        var durableOfferKnowledge: [String: [CollegePortalKnowledgeSnapshot]] = [:]
        for record in allCareerRecords {
            for offer in record.offers {
                let key = portalKnowledgeKey(PortalKnowledgeKey(
                    observerProgrammeID: offer.destinationProgrammeID,
                    playerID: record.playerID,
                    sourceProgrammeID: record.sourceProgrammeID,
                    targetSeason: record.targetSeason,
                    window: record.window
                ))
                durableOfferKnowledge[key, default: []].append(offer.knowledge)
            }
        }
        let storedSnapshots = state.scouting.portalKnowledgeByObserver.keys.sorted(
            by: uuidLessThan
        ).flatMap { observerID in
            state.scouting.portalKnowledgeByObserver[observerID] ?? []
        }.sorted { lhs, rhs in
            if lhs.observerProgrammeID != rhs.observerProgrammeID {
                return uuidLessThan(lhs.observerProgrammeID, rhs.observerProgrammeID)
            }
            if lhs.targetSeason != rhs.targetSeason { return lhs.targetSeason < rhs.targetSeason }
            if lhs.window != rhs.window { return lhs.window.order < rhs.window.order }
            if lhs.playerID != rhs.playerID { return uuidLessThan(lhs.playerID, rhs.playerID) }
            return uuidLessThan(lhs.sourceProgrammeID, rhs.sourceProgrammeID)
        }
        for snapshot in storedSnapshots {
            let occursInFuture = occurs(state.calendar, before: snapshot.lastUpdated)
            let hasEntrantRecord = recordIdentities.contains(PortalRecordSourceKey(
                playerID: snapshot.playerID,
                sourceProgrammeID: snapshot.sourceProgrammeID,
                targetSeason: snapshot.targetSeason,
                window: snapshot.window
            ))
            if !programmeIDs.contains(snapshot.observerProgrammeID)
                || !programmeIDs.contains(snapshot.sourceProgrammeID)
                || !playerIDs.contains(snapshot.playerID)
                || snapshot.targetSeason != state.college.portal.targetSeason
                || !hasEntrantRecord
                || occursInFuture {
                issues.append(.invalidPortalKnowledge(
                    observerID: snapshot.observerProgrammeID,
                    playerID: snapshot.playerID
                ))
                continue
            }
            let key = portalKnowledgeKey(PortalKnowledgeKey(
                observerProgrammeID: snapshot.observerProgrammeID,
                playerID: snapshot.playerID,
                sourceProgrammeID: snapshot.sourceProgrammeID,
                targetSeason: snapshot.targetSeason,
                window: snapshot.window
            ))
            let durableKnowledge = durableOfferKnowledge[key] ?? []
            if !durableKnowledge.isEmpty
                && !durableKnowledge.allSatisfy({ $0 == snapshot }) {
                issues.append(.invalidPortalKnowledge(
                    observerID: snapshot.observerProgrammeID,
                    playerID: snapshot.playerID
                ))
            }
        }
        for record in allCareerRecords where record.targetSeason == state.college.portal.targetSeason {
            for offer in record.offers {
                let stored = state.scouting.portalKnowledge(
                    observerProgrammeID: offer.destinationProgrammeID,
                    playerID: record.playerID,
                    sourceProgrammeID: record.sourceProgrammeID,
                    targetSeason: record.targetSeason,
                    window: record.window
                )
                if stored != offer.knowledge {
                    issues.append(.invalidPortalKnowledge(
                        observerID: offer.destinationProgrammeID,
                        playerID: record.playerID
                    ))
                }
            }
        }
    }

    private static func portalRecordKey(
        playerID: UUID,
        targetSeason: Int,
        window: CollegePortalWindow
    ) -> String {
        "\(playerID.uuidString)|\(targetSeason)|\(window.rawValue)"
    }

    private static func portalWindowKey(
        targetSeason: Int,
        window: CollegePortalWindow
    ) -> String {
        "\(targetSeason)|\(window.rawValue)"
    }

    private static func portalCapacityKey(_ key: PortalCapacityKey) -> String {
        "\(key.targetSeason)|\(key.window.rawValue)|\(key.destinationProgrammeID.uuidString)"
    }

    private static func portalKnowledgeKey(_ key: PortalKnowledgeKey) -> String {
        "\(key.observerProgrammeID.uuidString)|\(key.playerID.uuidString)"
            + "|\(key.sourceProgrammeID.uuidString)|\(key.targetSeason)|\(key.window.rawValue)"
    }

    private static func uuidLessThan(_ lhs: UUID, _ rhs: UUID) -> Bool {
        lhs.uuidString < rhs.uuidString
    }

    private static func occurs(_ lhs: CalendarState, before rhs: CalendarState) -> Bool {
        lhs.season < rhs.season || (lhs.season == rhs.season && lhs.week < rhs.week)
    }

    private static func checkCareerControl(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        guard let control = state.career.college else { return }
        guard let programme = state.programmes[control.programmeID],
              programme.staffIDs.contains(control.coachID),
              state.staff[control.coachID]?.role == .headCoach,
              Set(control.responsibilityOwners.keys)
                == Set(CollegeCareerResponsibility.allCases),
              !occurs(state.calendar, before: control.startedAt),
              control.responsibilityOwners.values.allSatisfy({ owner in
                  switch owner {
                  case .user:
                      return true
                  case let .delegated(staffID):
                      return programme.staffIDs.contains(staffID)
                          && state.staff[staffID] != nil
                  }
              }) else {
            issues.append(.invalidCareerControl)
            return
        }
    }

    private static func checkCareerArc(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let arc = state.careerArc
        let organisationIDs = Set(state.programmes.ids).union(state.proTeams.ids)
        let collegeIDs = Set(state.programmes.ids)
        let proIDs = Set(state.proTeams.ids)
        let historyIsChronological = zip(arc.jobHistory, arc.jobHistory.dropFirst())
            .allSatisfy { first, second in
                !occurs(second.job.startedAt, before: first.endedAt)
            }
        let historyIsBounded = arc.jobHistory.allSatisfy { entry in
            organisationIDs.contains(entry.job.organisationID)
                && !occurs(state.calendar, before: entry.endedAt)
                && !occurs(entry.endedAt, before: entry.job.startedAt)
        }
        let currentJobIsBound = arc.currentJob.map { job in
            organisationIDs.contains(job.organisationID)
                && !occurs(state.calendar, before: job.startedAt)
                && (job.tier == .college
                    ? collegeIDs.contains(job.organisationID)
                    : proIDs.contains(job.organisationID))
        } ?? true
        let opportunitiesAreBound = arc.opportunities.allSatisfy { opportunity in
            let tierMatches = opportunity.tier == .college
                ? collegeIDs.contains(opportunity.organisationID)
                : proIDs.contains(opportunity.organisationID)
            return tierMatches
                && !occurs(state.calendar, before: opportunity.offeredAt)
                && !occurs(opportunity.expiresAt, before: opportunity.offeredAt)
        }
        let controlMatchesJob: Bool
        if let control = state.career.college {
            controlMatchesJob = arc.currentJob.map {
                $0.tier == .college && $0.organisationID == control.programmeID
            } ?? true
        } else {
            controlMatchesJob = arc.currentJob?.tier != .college
        }
        guard historyIsChronological,
              historyIsBounded,
              currentJobIsBound,
              opportunitiesAreBound,
              controlMatchesJob else {
            issues.append(.invalidCareerArc)
            return
        }
    }

    private static func checkProfessionalCap(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        for team in state.proTeams.values {
            let hasCapData = team.deadMoney != 0
                || (team.rosterIDs + team.practiceSquadIDs).contains {
                    state.players[$0]?.contract != nil
                }
            guard hasCapData else { continue }
            let contractsHavePlausibleTerms = (team.rosterIDs + team.practiceSquadIDs).allSatisfy { playerID in
                guard let contract = state.players[playerID]?.contract,
                      let signedSeason = contract.signedSeason else { return true }
                return signedSeason >= 0
                    && signedSeason <= state.calendar.season + 1
                    && state.calendar.season < signedSeason + contract.years
            }
            guard contractsHavePlausibleTerms else {
                issues.append(.invalidProfessionalCap(teamID: team.id))
                continue
            }
            do {
                let cap = try ProManagementSystem.capSnapshot(teamID: team.id, in: state)
                if !cap.isWithinCap {
                    issues.append(.invalidProfessionalCap(teamID: team.id))
                }
            } catch {
                issues.append(.invalidProfessionalCap(teamID: team.id))
            }
        }
    }

    private static func checkProfessionalMarket(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let market = state.proMarket
        let seasonIsPlausible: Bool
        if market.phase == .closed {
            seasonIsPlausible = market.season >= max(0, state.calendar.season - 1)
                && market.season <= state.calendar.season + 1
        } else {
            seasonIsPlausible = market.season == state.calendar.season
                || market.season == state.calendar.season + 1
        }
        let proTeamIDs = Set(state.proTeams.ids)
        let draftIDs = market.draftClass.map(\.id)
        let draftIDSet = Set(draftIDs)
        let archivedDraftIDSet = Set(market.archivedDraftProspectIDs)
        let ownedIDs = Set(state.programmes.values.flatMap(\.rosterIDs))
            .union(state.proTeams.values.flatMap { $0.rosterIDs + $0.practiceSquadIDs })
        let draftOrderIsValid = market.phase == .closed
            ? market.draftOrder.isEmpty
            : market.draftOrder.count == ProRules.draftPickCount
                && market.draftOrder.allSatisfy(proTeamIDs.contains)
        let draftClassIsValid = market.phase == .closed
            ? market.draftClass.isEmpty
            : market.draftClass.count == ProRules.draftPickCount
                && draftIDSet.count == draftIDs.count
                && draftIDSet.isDisjoint(with: archivedDraftIDSet)
                && market.draftClass.allSatisfy {
                    let prospectID = $0.id
                    let drafted = market.draftedProspectIDs.contains(prospectID)
                    let rootPlayer = state.players[prospectID]
                    let ownerCount = state.proTeams.values.reduce(into: 0) { count, team in
                        count += team.rosterIDs.contains(prospectID) ? 1 : 0
                    }
                    return $0.draftSeason == market.season
                        && $0.player.id == $0.id
                        && $0.player.eligibility == nil
                        && (drafted
                            ? rootPlayer?.contract != nil && ownerCount == 1
                            : $0.player.contract == nil && rootPlayer == nil)
                }
        let freeAgentsAreValid = market.freeAgentIDs.count <= ProMarketState.maximumFreeAgentIDs
            && Set(market.freeAgentIDs).count == market.freeAgentIDs.count
            && market.freeAgentIDs.allSatisfy { playerID in
                guard let player = state.players[playerID] else { return false }
                return player.eligibility == nil
                    && player.contract == nil
                    && !ownedIDs.contains(playerID)
                    && !draftIDSet.contains(playerID)
            }
        let observationsAreValid = market.observations.count <= ProMarketState.maximumObservations
            && Set(market.observations.map(\.id)).count == market.observations.count
            && market.observations.allSatisfy { observation in
                observation.season == market.season
                    && proTeamIDs.contains(observation.teamID)
                    && draftIDSet.contains(observation.prospectID)
            }
        let waiversAreValid = market.waivers.count <= ProMarketState.maximumWaivers
            && Set(market.waivers.map(\.id)).count == market.waivers.count
            && Set(market.waivers.map(\.playerID)).count == market.waivers.count
            && market.waivers.allSatisfy { waiver in
                guard let source = state.proTeams[waiver.sourceTeamID],
                      let player = state.players[waiver.playerID] else { return false }
                let sourceOwnsPlayer = source.rosterIDs.contains(waiver.playerID)
                    || source.practiceSquadIDs.contains(waiver.playerID)
                let openedSeasonIsPlausible = waiver.openedAt.season >= max(0, state.calendar.season - 1)
                    && waiver.openedAt.season <= state.calendar.season + 1
                return sourceOwnsPlayer
                    && player.eligibility == nil
                    && player.contract != nil
                    && !market.freeAgentIDs.contains(waiver.playerID)
                    && !draftIDSet.contains(waiver.playerID)
                    && waiver.claimDeadline == waiver.openedAt.advancedWeek()
                    && openedSeasonIsPlausible
            }
        let phaseShapeIsValid: Bool
        switch market.phase {
        case .closed:
            phaseShapeIsValid = market.nextPick == 0
                && market.draftedProspectIDs.isEmpty
                && market.observations.isEmpty
        case .freeAgency:
            phaseShapeIsValid = market.nextPick == 0
                && market.draftedProspectIDs.isEmpty
        case .draft, .rosterBuild:
            phaseShapeIsValid = (0...market.draftClass.count).contains(market.nextPick)
                && market.draftedProspectIDs.count == market.nextPick
                && Set(market.draftedProspectIDs).count == market.draftedProspectIDs.count
                && Set(market.draftedProspectIDs).isSubset(of: draftIDSet)
                && (market.phase == .rosterBuild
                    ? market.nextPick == market.draftClass.count
                    : market.nextPick < market.draftClass.count)
        }
        guard seasonIsPlausible,
              draftOrderIsValid,
              draftClassIsValid,
              freeAgentsAreValid,
              observationsAreValid,
              waiversAreValid,
              phaseShapeIsValid else {
            issues.append(.invalidProfessionalMarket)
            return
        }
    }

    private static func checkMandatoryDecisions(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        guard let control = state.career.college else {
            for decision in state.pending.mandatoryDecisions {
                issues.append(.invalidMandatoryDecision(decisionID: decision.id))
            }
            for resolution in state.career.mandatoryDecisionResolutions {
                issues.append(.invalidMandatoryDecision(decisionID: resolution.decisionID))
            }
            return
        }
        let programme = state.programmes[control.programmeID]
        let knownEntityIDs = Set(state.programmes.ids)
            .union(state.proTeams.ids)
            .union(state.players.ids)
            .union(state.staff.ids)
            .union(state.prospects.ids)
        for decision in state.pending.mandatoryDecisions {
            let subjectExists: Bool
            switch decision.subject {
            case let .recruiting(prospectID):
                subjectExists = state.prospects[prospectID] != nil
                    && state.college.prospectRecruitment[prospectID] != nil
            case let .portalRetention(playerID, _),
                 let .redshirt(playerID),
                 let .nilAllocation(playerID):
                subjectExists = state.players[playerID] != nil
                    && programme?.rosterIDs.contains(playerID) == true
            }
            let relatedEntitiesExist = decision.reasons.allSatisfy {
                $0.relatedEntityID.map(knownEntityIDs.contains) ?? true
            }
            guard decision.programmeID == control.programmeID,
                  control.responsibilityOwners[decision.responsibility] == decision.owner,
                  !occurs(state.calendar, before: decision.createdAt),
                  !occurs(decision.deadline, before: state.calendar),
                  subjectExists,
                  relatedEntitiesExist else {
                issues.append(.invalidMandatoryDecision(decisionID: decision.id))
                continue
            }
        }
        for resolution in state.career.mandatoryDecisionResolutions {
            guard state.programmes[resolution.programmeID] != nil,
                  !occurs(state.calendar, before: resolution.decidedAt),
                  MandatoryDecision.actionIsValid(
                      resolution.action,
                      for: resolution.subject
                  ) else {
                issues.append(.invalidMandatoryDecision(decisionID: resolution.decisionID))
                continue
            }
        }
    }

    private struct ScheduleAppearance: Hashable {
        let season: Int
        let week: Int
        let tier: Tier
        let participantID: UUID
    }

    private static func checkPostseason(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let schedule = state.competition.currentSchedule.games
        let collegeConferenceGames = schedule.filter {
            $0.tier == .college && $0.stage == .conferenceChampionship
        }
        if !collegeConferenceGames.isEmpty {
            let conferenceByProgramme = Dictionary(uniqueKeysWithValues:
                state.programmes.values.compactMap { programme in
                    programme.conferenceID.map { (programme.id, $0) }
                }
            )
            let conferences = collegeConferenceGames.compactMap {
                conferenceByProgramme[$0.homeID] == conferenceByProgramme[$0.awayID]
                    ? conferenceByProgramme[$0.homeID]
                    : nil
            }
            if collegeConferenceGames.count != CollegeRules.conferenceCount
                || Set(conferences).count != CollegeRules.conferenceCount {
                issues.append(.invalidPostseason(
                    tier: .college,
                    stage: .conferenceChampionship
                ))
            }
        }

        checkOpeningBracket(tier: .college, state: state, issues: &issues)
        checkOpeningBracket(tier: .pro, state: state, issues: &issues)
        checkWinnerRound(
            tier: .college,
            source: .quarterfinal,
            target: .semifinal,
            state: state,
            issues: &issues
        )
        checkWinnerRound(
            tier: .college,
            source: .semifinal,
            target: .championship,
            state: state,
            issues: &issues
        )
        checkWinnerRound(
            tier: .pro,
            source: .quarterfinal,
            target: .semifinal,
            state: state,
            issues: &issues
        )
        checkWinnerRound(
            tier: .pro,
            source: .semifinal,
            target: .championship,
            state: state,
            issues: &issues
        )
        checkChampion(tier: .college, state: state, issues: &issues)
        checkChampion(tier: .pro, state: state, issues: &issues)
    }

    private static func checkOpeningBracket(
        tier: Tier,
        state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let games = state.competition.currentSchedule.games.filter {
            $0.tier == tier && $0.stage == .quarterfinal
        }
        guard !games.isEmpty else { return }
        let participants = games.flatMap { [$0.homeID, $0.awayID] }
        let ranking = state.competition.rankings[tier] ?? []
        let expected: Set<UUID>
        switch tier {
        case .college:
            expected = Set(ranking.prefix(CollegeRules.bracketTeams))
        case .pro:
            expected = Set(state.league.conferences(in: .pro).flatMap { conference in
                ranking.filter(conference.memberIDs.contains).prefix(4)
            })
        }
        if games.count != 4
            || Set(participants).count != participants.count
            || Set(participants) != expected {
            issues.append(.invalidPostseason(tier: tier, stage: .quarterfinal))
        }
    }

    private static func checkWinnerRound(
        tier: Tier,
        source: CompetitionStage,
        target: CompetitionStage,
        state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let schedule = state.competition.currentSchedule.games
        let sourceGames = schedule.filter { $0.tier == tier && $0.stage == source }
        let targetGames = schedule.filter { $0.tier == tier && $0.stage == target }
        guard !targetGames.isEmpty else { return }
        let winners = sourceGames.compactMap(winnerID)
        let targetParticipants = targetGames.flatMap { [$0.homeID, $0.awayID] }
        let expectedGameCount = source == .quarterfinal ? 2 : 1
        if sourceGames.contains(where: { $0.result == nil })
            || targetGames.count != expectedGameCount
            || Set(targetParticipants).count != targetParticipants.count
            || Set(targetParticipants) != Set(winners) {
            issues.append(.invalidPostseason(tier: tier, stage: target))
        }

        if tier == .pro && target == .semifinal {
            let conferenceByTeam = Dictionary(uniqueKeysWithValues:
                state.proTeams.values.compactMap { team in
                    team.conferenceID.map { (team.id, $0) }
                }
            )
            if targetGames.contains(where: {
                conferenceByTeam[$0.homeID] != conferenceByTeam[$0.awayID]
            }) {
                issues.append(.invalidPostseason(tier: tier, stage: target))
            }
        }
    }

    private static func checkChampion(
        tier: Tier,
        state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        let championship = state.competition.currentSchedule.games.first {
            $0.tier == tier && $0.stage == .championship
        }
        let storedChampion = tier == .college
            ? state.competition.collegeChampionID
            : state.competition.proChampionID
        if let storedChampion,
           championship.flatMap(winnerID) != storedChampion {
            issues.append(.invalidPostseason(tier: tier, stage: .championship))
        }
    }

    private static func winnerID(_ game: ScheduledGame) -> UUID? {
        guard let result = game.result else { return nil }
        return result.homeScore > result.awayScore ? game.homeID : game.awayID
    }

    private static func validWeek(
        _ week: Int,
        stage: CompetitionStage,
        tier: Tier
    ) -> Bool {
        switch (tier, stage) {
        case (.college, .regularSeason):
            return (1...CollegeRules.regularSeasonWeeks).contains(week)
        case (.college, .conferenceChampionship):
            return week == CollegeRules.regularSeasonWeeks + 1
        case (.college, .quarterfinal): return week == CollegeRules.seasonWeeks - 2
        case (.college, .semifinal): return week == CollegeRules.seasonWeeks - 1
        case (.college, .championship): return week == CollegeRules.seasonWeeks
        case (.pro, .regularSeason):
            return (1...ProRules.regularSeasonWeeks).contains(week)
        case (.pro, .quarterfinal): return week == ProRules.seasonWeeks - 2
        case (.pro, .semifinal): return week == ProRules.seasonWeeks - 1
        case (.pro, .championship): return week == ProRules.seasonWeeks
        case (.pro, .conferenceChampionship): return false
        }
    }

    private static func checkPositionalCoverage(
        _ state: GameState,
        issues: inout [IntegrityIssue]
    ) {
        for (organisationID, rosterIDs) in state.programmes.values.map({ ($0.id, $0.rosterIDs) })
            + state.proTeams.values.map({ ($0.id, $0.rosterIDs) }) {
            var counts: [Position: Int] = [:]
            for id in rosterIDs {
                guard let position = state.players[id]?.position else { continue }
                counts[position, default: 0] += 1
            }
            for position in Position.allCases
            where (counts[position] ?? 0)
                < (SharedRules.minimumPlayableRosterByPosition[position] ?? 0) {
                issues.append(.missingPositionalCoverage(
                    organisationID: organisationID,
                    position: position
                ))
            }
        }
    }
}
