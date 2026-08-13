import Foundation
import FootballSimCore

/// Helpers for suites that build a root at a later season without running the scheduler to get
/// there.
///
/// Jumping the calendar is legitimate — a college test should not have to simulate twenty-one weeks
/// of professional football to reach season two — but the root it lands on must still be one the
/// engine could have produced. Two things have to move with the calendar, and both were learned the
/// hard way:
///
/// 1. The professional market's season, or M6's ±1-season plausibility window rejects the root.
///    Fixed 2026-08-12; `docs/STATUS.md` records it.
/// 2. Professional contracts, which is this file. A contract is valid only while the season is
///    inside its term (`WorldIntegrity.checkProfessionalCap`), so a root that jumps two seasons
///    carries thirty-two teams' worth of deals that ended in the past. That was invisible until
///    `0deb629` made a generated world issue contracts at all, and then it broke three college
///    suites for a professional reason.
func professionalContractsRolled(to season: Int, in state: GameState) -> GameState {
    var next = state
    for team in state.proTeams.values {
        for playerID in team.rosterIDs + team.practiceSquadIDs {
            guard let contract = state.players[playerID]?.contract,
                  let signedSeason = contract.signedSeason,
                  season >= signedSeason + contract.years else { continue }
            // The same re-signing `02` §4.2a states, applied to everyone rather than to the last
            // body at a position: one year at the last base salary, no bonus. Nobody leaves, so a
            // college suite's roster expectations are untouched, and because every contract this
            // project issues is flat-salaried the cap hit never rises.
            let salary = contract.baseSalaryByYear.last ?? 0
            next.players.update(playerID) {
                $0.contract = Contract(
                    years: 1,
                    baseSalaryByYear: [salary],
                    signingBonus: 0
                ).withSignedSeason(season)
            }
        }
    }
    return next
}
