import Foundation
import FootballSimCore
import ProFootballCoachUI

public extension CoachWorldReadModelProvider {
    /// Which routes exist in this world, answered from the authoritative root.
    ///
    /// The chrome asks this on every render — the icon rail, the sibling links and the task list
    /// all need it — and it used to be answered by building every screen and testing the result for
    /// nil. That made the cheapest question in the application cost the most expensive answer:
    /// 1.59 s per intent at season 0, dominated by screens nobody was looking at.
    ///
    /// So each route is answered by the same guard its provider opens with, read straight off the
    /// root. Four models are still consulted, and deliberately: the college offseason and its
    /// signing day, the draft room, the promotion decision and the realignment event are gated on a
    /// *phase* rather than on a structure, and reproducing a phase here would be a second copy of a
    /// rule rather than a cheaper reading of one. They are among the cheapest models, and the
    /// store memoises them, so each is built at most once per world.
    ///
    /// `CoachWorldAvailabilityTests` asserts this agrees with the models over every
    /// `CoachWorldScreenID`, in every career shape, so a guard cannot drift away from its screen.
    static func availableScreens(from state: GameState) -> Set<CoachWorldScreenID> {
        var available: Set<CoachWorldScreenID> = []
        func add(_ screen: CoachWorldScreenID, when condition: Bool) {
            guard condition else { return }
            available.insert(screen)
        }

        let coach = state.career.coachID.flatMap { state.staff[$0] }
        let collegeControl = state.career.college.flatMap { control -> CollegeControl? in
            guard state.programmes[control.programmeID] != nil,
                  state.staff[control.coachID] != nil else { return nil }
            return CollegeControl(programmeID: control.programmeID)
        }
        let proJob = state.career.college == nil ? state.careerArc.currentJob : nil
        let proControl = proJob.flatMap { job -> ProControl? in
            guard job.tier == .professional,
                  let team = state.proTeams[job.organisationID],
                  coach != nil || team.staffIDs.contains(where: { state.staff[$0] != nil })
            else { return nil }
            return ProControl(teamID: team.id)
        }
        // `controlledOrganisationID` in the shared provider, plus the resolution its callers do.
        let controlledID: UUID? = collegeControl?.programmeID ?? proControl?.teamID
        let hasOrganisation = controlledID != nil
        let tier: Tier = collegeControl != nil ? .college
            : (state.careerArc.currentJob?.tier == .professional ? .pro : .college)

        // Weekly command.
        add(.coachingHQ, when: hasOrganisation)
        add(.inbox, when: hasOrganisation)
        add(.opponentReportFilmRoom, when: hasOrganisation)
        add(.gamePlan, when: hasOrganisation)
        add(.practicePlan, when: hasOrganisation)
        add(.matchDay, when: state.matchSession != nil)
        let hasAftermath = controlledID.map { id in
            state.competition.currentSchedule.games.contains {
                $0.result?.source == .detailed
                    && $0.result?.evidence != nil
                    && ($0.homeID == id || $0.awayID == id)
            }
        } ?? false
        add(.aftermath, when: hasAftermath)
        add(.gameDetailBoxScore, when: hasAftermath)

        // Personnel. The roster is the college programme's or the professional team's, and team
        // health is a projection of it, so they stand or fall together.
        let rosterPlayerCount = collegeControl.flatMap { state.programmes[$0.programmeID]?.rosterIDs.count }
            ?? proControl.flatMap { control in
                state.proTeams[control.teamID].map { $0.rosterIDs.count + $0.practiceSquadIDs.count }
            }
        let hasRoster = rosterPlayerCount != nil
        add(.roster, when: hasRoster)
        add(.developmentPlan, when: hasRoster)
        add(.teamHealth, when: hasRoster)
        add(.playerProfile, when: (rosterPlayerCount ?? 0) > 0)
        add(.depthChart, when: hasOrganisation)
        let staffIDs = controlledID.flatMap {
            state.programmes[$0]?.staffIDs ?? state.proTeams[$0]?.staffIDs
        }
        add(.staffRoom, when: staffIDs.map { ids in
            coach != nil || ids.contains { state.staff[$0] != nil }
        } ?? false)

        // Recruiting. Every board route shares the recruiting provider's guard.
        let hasRecruiting = collegeControl.map { state.college.programmes[$0.programmeID] != nil } ?? false
        for screen in [CoachWorldScreenID.recruitingBoard, .prospectProfile, .shortlist,
                       .contactVisitPlanner, .classOverview] {
            add(screen, when: hasRecruiting)
        }
        // The offseason shell is gated on a phase — it exists only once the cycle leaves active,
        // the portal opens, or a decision is waiting — so it is read rather than reproduced, and
        // signing day comes off the same model.
        let offseason = collegeOffseason(from: state)
        add(.collegeOffseason, when: offseason != nil)
        add(.signingDay, when: offseason?.cyclePhase == .signing)

        // Pro management.
        add(.capContracts, when: proControl != nil)
        add(.contractNegotiation, when: proControl != nil)
        add(.rosterCutsTransactions, when: proControl != nil)
        add(.proOffseason, when: proControl != nil)
        add(.draftRoom, when: proOffseason(from: state)?.phase == .draft)

        // League.
        add(.leagueMap, when: collegeControl != nil)
        add(.teamProgrammeProfile, when: controlledID != nil)
        add(.standings, when: state.competition.standings[tier] != nil)
        // The schedule provider never refuses: with no appointment it is the league's fixture list
        // rather than the coach's, which is a surface the world search can reach.
        add(.schedule, when: true)
        add(.rankingsPlayoffPicture, when: true)
        add(.bracketPostseason, when: true)
        add(.worldSearch, when: true)
        add(.statisticsLeaders, when: coach != nil && controlledID != nil)
        add(.awardsHonours, when: coach != nil)
        add(.news, when: state.career.coachID != nil)
        add(.realignmentEvent, when: realignment(from: state)?.event != nil)

        // Career.
        add(.careerHub, when: coach != nil)
        add(.stakeholders, when: coach != nil)
        add(.promotionDecision, when: careerHub(from: state)?
            .opportunities.contains { $0.canAccept } == true)
        let hasLegacy = coach != nil && controlledID != nil
        for screen in [CoachWorldScreenID.recordBook, .rivalries, .careerLine, .coachingTree] {
            add(screen, when: hasLegacy)
        }

        return available
    }

    private struct CollegeControl { let programmeID: UUID }
    private struct ProControl { let teamID: UUID }
}
