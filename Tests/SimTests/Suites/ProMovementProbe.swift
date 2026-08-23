import Foundation
import FootballSimCore

/// Attribution probe for "1,476 free-agency signings relocate nobody".
///
/// The churn band measured professional `moved` as exactly zero at every season boundary across ten
/// seasons and 32 clubs, while `--pro-soak` counted 1,476 `proPlayerSigned` events over the same
/// span. Both numbers are solid and they look contradictory, because a season-boundary snapshot
/// cannot see what happened between two boundaries: a signing that returns a player to the club
/// they left is invisible to it, and so is a signing whose player is gone again before the next
/// boundary.
///
/// So this watches every week rather than every season, and classifies each signing against the
/// club that last owned the player. It reports, per season:
///
///   - expiries, and the club each player left
///   - signings split into `returned` (same club) and `relocated` (different club)
///   - whether a signed player lands on the active roster or the practice squad, since the churn
///     snapshot reads `rosterIDs` only and a practice-squad landing would read as a departure
///   - the free-agent pool depth each week free agency runs, and who is left in it at season end
///
/// Written as a probe rather than as assertions in the ten-season band suite for the reason
/// `--pro-draft-probe` exists: that suite takes sixteen minutes and answers "something is wrong",
/// and this takes a fraction of it and answers "this is the wrong thing".
func runProMovementProbe() {
    let seasons = ProcessInfo.processInfo.environment["PRO_MOVEMENT_SEASONS"]
        .flatMap(Int.init) ?? 3
    var state = GameState.bootstrap(seed: 96_001)
    var ownerByPlayer = proOwnership(state)

    print("PROBE: bootstrap rosters=\(ownerByPlayer.count) freeAgents=\(state.proMarket.freeAgentIDs.count)")

    for targetSeason in 1...seasons {
        var expired = 0
        var returned = 0
        var relocated = 0
        var signedToPracticeSquad = 0
        var signedWithNoPriorClub = 0
        var retiredOrGone = 0
        var poolDepths: [Int] = []
        var drafted = 0
        var phaseWeeks: [ProMarketPhase: Int] = [:]
        var midSeasonActive = -1

        while state.calendar.season < targetSeason {
            let transition: WorldTransition
            do {
                transition = try WorldScheduler.advanceWeek(state)
            } catch {
                print("PROBE: advanceWeek failed at \(state.calendar): \(error)")
                return
            }
            let before = state
            state = transition.state

            if before.proMarket.phase == .freeAgency {
                poolDepths.append(before.proMarket.freeAgentIDs.count)
            }
            phaseWeeks[before.proMarket.phase, default: 0] += 1
            // Mid-season, well clear of both ends: the boundary week is the league at its emptiest
            // — expiry has run and the market has not reopened — and every per-season figure below
            // is taken there. This is the same population a week later in the calendar and a whole
            // offseason later in the market's life.
            if state.calendar.week == 12 {
                midSeasonActive = state.proTeams.values.reduce(0) { $0 + $1.rosterIDs.count }
            }

            for event in transition.emittedEvents {
                switch event.payload {
                case .proContractExpired:
                    // The payload names only the player, so the club comes from the ownership map,
                    // which already holds whoever last rostered them.
                    expired += 1
                case let .proPlayerSigned(playerID, teamID, _, _):
                    switch ownerByPlayer[playerID] {
                    case .none: signedWithNoPriorClub += 1
                    case .some(teamID): returned += 1
                    case .some: relocated += 1
                    }
                    if state.proTeams[teamID]?.practiceSquadIDs.contains(playerID) == true {
                        signedToPracticeSquad += 1
                    }
                    ownerByPlayer[playerID] = teamID
                case let .proDraftPick(prospectID, teamID, _, _):
                    drafted += 1
                    ownerByPlayer[prospectID] = teamID
                default:
                    break
                }
            }
        }

        let nowOwned = proOwnership(state)
        retiredOrGone = ownerByPlayer.keys.filter { nowOwned[$0] == nil }.count
        let poolSummary = poolDepths.isEmpty
            ? "free agency never ran"
            : "weeks=\(poolDepths.count) depth min=\(poolDepths.min() ?? 0) max=\(poolDepths.max() ?? 0)"

        // Active seats separately from ownership: `proOwnership` counts the practice squad too, and
        // the roster-legality rule and the age-curve band both read `rosterIDs` alone. A league that
        // is short only because its rookies are parked would look full here and empty to them.
        let active = state.proTeams.values.reduce(0) { $0 + $1.rosterIDs.count }
        let squad = state.proTeams.values.reduce(0) { $0 + $1.practiceSquadIDs.count }
        let shortfalls = state.proTeams.values
            .map { ProRules.activeRosterLimit - $0.rosterIDs.count }
            .filter { $0 > 0 }
        let phases = ProMarketPhase.allCases
            .map { "\($0.rawValue)=\(phaseWeeks[$0] ?? 0)" }
            .joined(separator: " ")

        print("""
        PROBE season \(targetSeason): expired=\(expired) \
        returned=\(returned) relocated=\(relocated) drafted=\(drafted) \
        noPriorClub=\(signedWithNoPriorClub) toPracticeSquad=\(signedToPracticeSquad)
        PROBE season \(targetSeason): rosters=\(nowOwned.count) \
        unaccounted=\(retiredOrGone) poolLeft=\(state.proMarket.freeAgentIDs.count) \
        freeAgency \(poolSummary)
        PROBE season \(targetSeason): active=\(active)/\(32 * ProRules.activeRosterLimit) \
        midSeasonActive=\(midSeasonActive) \
        practiceSquad=\(squad) shortTeams=\(shortfalls.count) \
        shortBy min=\(shortfalls.min() ?? 0) max=\(shortfalls.max() ?? 0) \
        weeks \(phases)
        """)
        ownerByPlayer = nowOwned.merging(ownerByPlayer) { current, _ in current }
    }
}

/// Which club owns each professional right now, active roster and practice squad alike.
private func proOwnership(_ state: GameState) -> [UUID: UUID] {
    var owner: [UUID: UUID] = [:]
    for team in state.proTeams.values {
        for playerID in team.rosterIDs + team.practiceSquadIDs { owner[playerID] = team.id }
    }
    return owner
}

/// Attribution probe for "the draft takes zero picks in ten seasons while starting nine times".
///
/// `--pro-draft-probe` says a draft immediately after expiry succeeds — `ProMarketSystem.draft`
/// works, in isolation, right after `expireContracts`. But the live scheduler does not begin the
/// draft there: `ProRosterAISystem.signFreeAgents` runs free agency first, refilling rosters toward
/// 53 for as many weeks as it keeps signing someone, and only calls `beginDraft` on the first week
/// that signs nobody. By then the roster state the draft actually starts from may look nothing like
/// the probe's fixture. `ProRosterAISystem.makeDraftPicks` also swallows its own failure — any
/// thrown error just `break`s the loop with no record of what it was — so the live scheduler cannot
/// itself say why. This calls `ProMarketSystem.draft` the same way that loop does, the moment the
/// real scheduler enters `.draft`, and prints what it throws.
func runProDraftStallProbe() {
    let seasons = ProcessInfo.processInfo.environment["PRO_MOVEMENT_SEASONS"]
        .flatMap(Int.init) ?? 3
    var state = GameState.bootstrap(seed: 96_001)
    var reportedSeasons = 0

    while reportedSeasons < seasons {
        let before = state
        let transition: WorldTransition
        do {
            transition = try WorldScheduler.advanceWeek(state)
        } catch {
            print("PROBE: advanceWeek failed at \(state.calendar): \(error)")
            return
        }
        state = transition.state

        let justEnteredDraft = before.proMarket.phase != .draft && state.proMarket.phase == .draft
        guard justEnteredDraft else { continue }
        reportedSeasons += 1

        guard let teamID = state.proMarket.currentPickTeamID else {
            print("PROBE season \(reportedSeasons): entered draft with no team on the clock, "
                + "draftOrder empty=\(state.proMarket.draftOrder.isEmpty)")
            continue
        }
        let team = state.proTeams[teamID]
        let takenIDs = Set(state.proMarket.draftedProspectIDs)
        let best = state.proMarket.draftClass
            .filter { !takenIDs.contains($0.id) }
            .min { lhs, rhs in
                lhs.player.overall.value == rhs.player.overall.value
                    ? lhs.id.uuidString < rhs.id.uuidString
                    : lhs.player.overall.value > rhs.player.overall.value
            }
        guard let prospect = best else {
            print("PROBE season \(reportedSeasons): draft class exhausted immediately, "
                + "class=\(state.proMarket.draftClass.count) taken=\(takenIDs.count)")
            continue
        }
        _ = prospect
        _ = team

        // Walk the loop `makeDraftPicks` walks, with the same call it makes, and report where it
        // stops and why. The first pick succeeding says nothing about the run: the live draft takes
        // fifteen weeks to make two hundred picks, which is a loop that breaks and restarts, not one
        // that runs.
        var walk = state
        var picks = 0
        while walk.proMarket.phase == .draft, let onClock = walk.proMarket.currentPickTeamID {
            let taken = Set(walk.proMarket.draftedProspectIDs)
            guard let next = walk.proMarket.draftClass
                .filter({ !taken.contains($0.id) })
                .min(by: {
                    $0.player.overall.value == $1.player.overall.value
                        ? $0.id.uuidString < $1.id.uuidString
                        : $0.player.overall.value > $1.player.overall.value
                }) else {
                print("PROBE season \(reportedSeasons): class exhausted after \(picks) picks")
                break
            }
            do {
                // The public entry point rather than the scheduler's: `draftForScheduler`
                // is internal to the engine module. It differs only by an extra whole-root check,
                // which can make a pick fail but never make one succeed, so a refusal here is a
                // refusal there.
                walk = try ProMarketSystem.draft(
                    prospectID: next.id,
                    for: onClock,
                    contract: ProMarketSystem.rookieContract(for: next.player),
                    in: walk
                )
                picks += 1
            } catch {
                let cap = (try? ProManagementSystem.capSnapshot(teamID: onClock, in: walk))
                let club = walk.proTeams[onClock]
                let deal = ProMarketSystem.rookieContract(for: next.player)
                let cost = (deal.baseSalaryByYear.first ?? 0) + deal.annualBonusProration
                print("""
                PROBE season \(reportedSeasons): draft stopped after \(picks) picks — \(error) \
                team=\(onClock) roster=\(club?.rosterIDs.count ?? -1)/\(ProRules.activeRosterLimit) \
                practiceSquad=\(club?.practiceSquadIDs.count ?? -1)/\(ProRules.practiceSquadLimit) \
                committedCap=\(cap?.committedCap ?? -1)/\(cap?.capLimit ?? -1) \
                pickCost=\(cost) classLeft=\(walk.proMarket.draftClass.count - taken.count)
                """)
                break
            }
        }
        if walk.proMarket.phase != .draft {
            print("PROBE season \(reportedSeasons): draft ran to completion in \(picks) picks")
        }
    }
}
