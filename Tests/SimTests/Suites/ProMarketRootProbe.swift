import Foundation
import FootballSimCore

/// Attribution probe for the `professionalMarketFailed(.invalidRoot)` abort that the first full-suite
/// run since `0deb629` hit in `PortalTransactionTests`'s fixture.
///
/// `ProMarketError.invalidRoot` is thrown from twenty-odd places and carries no issue list, so the
/// error alone says only "some integrity check refused some candidate root". This walks the same
/// season the fixture walks, stops at the failing week, and reports which subsystem produced the
/// candidate and which checks refused it — before anything is changed, so the fix is aimed rather
/// than guessed (`superpowers:systematic-debugging`).
func runProMarketRootProbe() {
    var state = GameState.bootstrap(seed: 97_001)
    var advanced = 0
    while state.calendar.season == 0 {
        do {
            state = try WorldScheduler.advanceWeek(state).state
            advanced += 1
        } catch {
            report(error, at: state, afterWeeks: advanced)
            return
        }
    }
    print("PROBE: reached \(state.calendar) after \(advanced) weeks with no failure")
}

private func report(_ error: any Error, at state: GameState, afterWeeks: Int) {
    print("PROBE: advanceWeek failed at \(state.calendar) after \(afterWeeks) weeks: \(error)")
    print("PROBE: professional phase \(state.proMarket.phase), waivers \(state.proMarket.waivers.count)")

    let incoming = WorldIntegrity.check(state)
    print("PROBE: incoming root valid=\(incoming.isValid) issues=\(issueSummary(incoming))")

    let expired = state.proMarket.waivers.filter {
        $0.claimDeadline.season < state.calendar.season
            || ($0.claimDeadline.season == state.calendar.season
                && $0.claimDeadline.week < state.calendar.week)
    }
    print("PROBE: expired waivers \(expired.count)")
    if !expired.isEmpty {
        do {
            let resolved = try ProMarketSystem.resolveExpiredWaivers(at: state.calendar, in: state)
            print("PROBE: resolveExpiredWaivers succeeded, "
                + "result valid=\(WorldIntegrity.check(resolved).isValid)")
        } catch {
            print("PROBE: resolveExpiredWaivers threw \(error)")
        }
    }

    do {
        let ai = try ProRosterAISystem.process(at: state.calendar, in: state)
        let after = WorldIntegrity.check(ai.state)
        print("PROBE: ProRosterAISystem succeeded, signed=\(ai.signedPlayerIDs.count), "
            + "valid=\(after.isValid) issues=\(issueSummary(after))")
    } catch {
        print("PROBE: ProRosterAISystem threw \(error)")
    }

    guard state.calendar.week == SharedRules.inSeasonWeeks else { return }
    print("PROBE: free agents before expiry \(state.proMarket.freeAgentIDs.count)"
        + " of \(ProMarketState.maximumFreeAgentIDs)")
    print("PROBE: expiry candidates \(expiryCandidateCount(in: state))")
    do {
        let expiry = try ProMarketSystem.expireContracts(at: state.calendar, in: state)
        let after = WorldIntegrity.check(expiry.state)
        print("PROBE: expireContracts succeeded, expired=\(expiry.expiredPlayerIDs.count), "
            + "valid=\(after.isValid) issues=\(issueSummary(after))")
    } catch {
        print("PROBE: expireContracts threw \(error)")
        let candidate = applyExpiry(to: state)
        let report = WorldIntegrity.check(candidate)
        print("PROBE: candidate root valid=\(report.isValid) issues=\(issueSummary(report))")
    }

    // The portal commit checks the root *projected into the next season*. Separate the two ways a
    // team can fail the cap invariant there — a contract whose term has run out, and a genuine cap
    // excess — because they call for opposite fixes.
    var projected = applyExpiry(to: state)
    projected.calendar = CalendarState(season: state.calendar.season + 1, week: 1)
    projected.league.season = projected.calendar.season
    projected.league.week = 1
    var staleTerms = 0
    var overCap = 0
    var staleExamples: [String] = []
    for team in projected.proTeams.values {
        let owned = team.rosterIDs + team.practiceSquadIDs
        let stale = owned.filter { playerID in
            guard let contract = projected.players[playerID]?.contract,
                  let signedSeason = contract.signedSeason else { return false }
            return !(signedSeason >= 0
                && signedSeason <= projected.calendar.season + 1
                && projected.calendar.season < signedSeason + contract.years)
        }
        if !stale.isEmpty {
            staleTerms += 1
            if staleExamples.count < 3 {
                let positions = stale.compactMap { projected.players[$0]?.position.rawValue }
                staleExamples.append("\(stale.count) stale \(positions)")
            }
        } else if let snapshot = try? ProManagementSystem.capSnapshot(
            teamID: team.id,
            in: projected
        ), !snapshot.isWithinCap {
            overCap += 1
        }
    }
    print("PROBE: projected season \(projected.calendar.season) — teams with run-out terms "
        + "\(staleTerms), teams over cap \(overCap), examples \(staleExamples)")
}

/// Applies the same mutation `expireContracts` applies, so the probe can report *why* the candidate
/// root is refused. The function itself only reports that one was.
private func applyExpiry(to state: GameState) -> GameState {
    var next = state
    let nextSeason = state.calendar.season + 1
    for team in state.proTeams.values.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
        let owned = team.rosterIDs + team.practiceSquadIDs
        var remainingByPosition: [Position: Int] = [:]
        for playerID in owned {
            guard let position = state.players[playerID]?.position else { continue }
            remainingByPosition[position, default: 0] += 1
        }
        for playerID in owned {
            guard let player = state.players[playerID],
                  let contract = player.contract,
                  let signedSeason = contract.signedSeason,
                  nextSeason >= signedSeason + contract.years else { continue }
            let minimum = SharedRules.minimumPlayableRosterByPosition[player.position] ?? 0
            guard remainingByPosition[player.position, default: 0] > minimum else { continue }
            remainingByPosition[player.position, default: 0] -= 1
            next.proTeams.update(team.id) {
                $0.rosterIDs.removeAll { $0 == playerID }
                $0.practiceSquadIDs.removeAll { $0 == playerID }
            }
            next.players.update(playerID) { $0.contract = nil }
            _ = next.proMarket.addFreeAgent(playerID)
        }
    }
    return next
}

/// A replica of `expireContracts`'s candidate rule, so the probe can say how many contracts the
/// rule selects without the function having to survive its own guards to report it.
private func expiryCandidateCount(in state: GameState) -> Int {
    let nextSeason = state.calendar.season + 1
    return state.proTeams.values.reduce(into: 0) { total, team in
        let owned = team.rosterIDs + team.practiceSquadIDs
        var remainingByPosition: [Position: Int] = [:]
        for playerID in owned {
            guard let position = state.players[playerID]?.position else { continue }
            remainingByPosition[position, default: 0] += 1
        }
        for playerID in owned {
            guard let player = state.players[playerID],
                  let contract = player.contract,
                  let signedSeason = contract.signedSeason,
                  nextSeason >= signedSeason + contract.years else { continue }
            let minimum = SharedRules.minimumPlayableRosterByPosition[player.position] ?? 0
            guard remainingByPosition[player.position, default: 0] > minimum else { continue }
            remainingByPosition[player.position, default: 0] -= 1
            total += 1
        }
    }
}

private func issueSummary(_ report: IntegrityReport) -> String {
    guard !report.issues.isEmpty else { return "none" }
    var counts: [String: Int] = [:]
    for issue in report.issues {
        let name = String(describing: issue).split(separator: "(").first.map(String.init)
            ?? "unknown"
        counts[name, default: 0] += 1
    }
    let ranked = counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
    return ranked.map { "\($0.key)x\($0.value)" }.joined(separator: " ")
        + " | first: " + report.issues.prefix(3).map { String(describing: $0) }
            .joined(separator: " ; ")
}
