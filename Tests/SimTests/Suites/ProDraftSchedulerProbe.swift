import Foundation
import FootballSimCore

/// Why the scheduler's draft starts and never picks.
///
/// `ProRosterAISystem.makeDraftPicks` catches every error `ProMarketSystem.draft` throws and breaks
/// the run, so a refused pick leaves no event, no error and no log line — the soak sees only
/// `proDraftStarted` with `draftedFinal=0`. This walks the scheduler until the market reaches the
/// draft, then attempts the exact pick that pass would attempt and reports the thrown reason
/// alongside the roster and cap state that produced it.
func runProDraftSchedulerProbe() {
    var state = GameState.bootstrap(seed: 96_005)
    let weekBudget = SharedRules.inSeasonWeeks * 3
    var reachedDraft = false

    for step in 0..<weekBudget {
        if state.proMarket.phase == .draft {
            reachedDraft = true
            reportPick(at: state, afterWeeks: step)
            break
        }
        let before = state.calendar
        let rosterTotal = state.proTeams.values.reduce(0) { $0 + $1.rosterIDs.count }
        let contracted = state.proTeams.values.reduce(0) { total, team in
            total + team.rosterIDs.filter { state.players[$0]?.contract != nil }.count
        }
        print("PROBE: s\(before.season)w\(before.week) phase=\(state.proMarket.phase) "
            + "rosterTotal=\(rosterTotal) contracted=\(contracted) "
            + "freeAgents=\(state.proMarket.freeAgentIDs.count)")
        do {
            state = try WorldScheduler.advanceWeek(state).state
        } catch {
            print("PROBE: advanceWeek threw at s\(state.calendar.season)w\(state.calendar.week): \(error)")
            return
        }
    }

    if !reachedDraft {
        print("PROBE: the market never reached the draft phase within \(weekBudget) weeks; "
            + "phase=\(state.proMarket.phase)")
    }
}

private func reportPick(at state: GameState, afterWeeks: Int) {
    let market = state.proMarket
    print("PROBE: draft phase reached at s\(state.calendar.season)w\(state.calendar.week) "
        + "after \(afterWeeks) weeks, marketSeason=\(market.season) nextPick=\(market.nextPick) "
        + "draftClass=\(market.draftClass.count) freeAgents=\(market.freeAgentIDs.count)")

    // The roster headcount canon 02 section 8 says expiry is supposed to have freed before the
    // draft opens, across every team rather than only the one on the clock.
    let counts = state.proTeams.values.map { $0.rosterIDs.count }.sorted()
    let full = counts.filter { $0 >= ProRules.activeRosterLimit }.count
    print("PROBE: active rosters min=\(counts.first ?? -1) max=\(counts.last ?? -1) "
        + "at-or-over-limit=\(full)/\(state.proTeams.ids.count) limit=\(ProRules.activeRosterLimit)")

    guard let teamID = market.currentPickTeamID else {
        print("PROBE: no team is on the clock")
        return
    }
    let takenIDs = Set(market.draftedProspectIDs)
    guard let prospect = market.draftClass
        .filter({ !takenIDs.contains($0.id) })
        .min(by: { lhs, rhs in
            lhs.player.overall.value == rhs.player.overall.value
                ? lhs.id.uuidString < rhs.id.uuidString
                : lhs.player.overall.value > rhs.player.overall.value
        }) else {
        print("PROBE: no undrafted prospect remains")
        return
    }

    let team = state.proTeams[teamID]
    let cap = try? ProManagementSystem.capSnapshot(teamID: teamID, in: state)
    print("PROBE: on the clock roster=\(team?.rosterIDs.count ?? -1)/\(ProRules.activeRosterLimit) "
        + "practiceSquad=\(team?.practiceSquadIDs.count ?? -1)/\(ProRules.practiceSquadLimit) "
        + "committedCap=\(cap?.committedCap ?? -1)/\(cap?.capLimit ?? -1)")

    do {
        _ = try ProMarketSystem.draft(
            prospectID: prospect.id,
            for: teamID,
            contract: ProMarketSystem.rookieContract(for: prospect.player),
            in: state
        )
        print("PROBE: the pick the scheduler would attempt SUCCEEDS here")
    } catch {
        print("PROBE: the pick the scheduler would attempt threw \(error)")
    }
}
