import Foundation

public struct HealthTransition: Sendable, Equatable {
    public let people: PeopleState
    public let eventPayloads: [DomainEventPayload]

    public init(people: PeopleState, eventPayloads: [DomainEventPayload]) {
        self.people = people
        self.eventPayloads = eventPayloads
    }
}

public enum PeopleLifecycleSystem {
    public static func processHealth(
        at calendar: CalendarState,
        in state: GameState
    ) -> HealthTransition {
        var people = state.people
        var payloads: [DomainEventPayload] = []
        var recoveredIDs: Set<UUID> = []

        for id in state.players.ids {
            people.updatePlayerLifecycle(id) { lifecycle in
                if lifecycle.recoverWeek() {
                    recoveredIDs.insert(id)
                    payloads.append(.playerRecovered(playerID: id))
                }
                // Time served counts down on the same tick, because there is exactly one place in
                // this game where a week passes for a player and a suspension that expired anywhere
                // else would be a second calendar to keep in step. `02` §5.2.
                if lifecycle.serveSuspensionWeek() {
                    payloads.append(.playerReinstated(playerID: id))
                }
            }
        }

        guard calendar.week > 1 else {
            return HealthTransition(people: people, eventPayloads: payloads)
        }
        let workloadCalendar = CalendarState(season: calendar.season, week: calendar.week - 1)
        let games = state.competition.currentSchedule.games.filter {
            $0.season == workloadCalendar.season
                && $0.week == workloadCalendar.week
                && $0.result != nil
        }
        var workloadByPlayer: [UUID: Int] = [:]
        for game in games {
            for id in (game.result?.homeParticipantIDs ?? [])
                + (game.result?.awayParticipantIDs ?? []) {
                workloadByPlayer[id, default: 0] += PeopleRules.gameFatigueLoad
            }
            for line in game.result?.playerStatistics ?? [] {
                let yards = line.passingYards + line.rushingYards + line.receivingYards
                workloadByPlayer[line.playerID, default: 0] += min(
                    PeopleRules.statisticalWorkloadFatigueMaximum,
                    yards / 100
                )
            }
        }

        for id in workloadByPlayer.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard !recoveredIDs.contains(id),
                  let player = state.players[id],
                  people.playerLifecycle[id]?.isAvailable == true else { continue }
            people.updatePlayerLifecycle(id) {
                $0.applyWorkload(workloadByPlayer[id] ?? 0)
            }
            guard let lifecycle = people.playerLifecycle[id] else { continue }
            var rng = SeededRandom(seed: healthSeed(
                root: state.league.seed,
                calendar: workloadCalendar,
                playerID: id
            ))
            let probability = PeopleRules.injuryProbability(
                fatigue: lifecycle.fatigue,
                durability: player.attributes[.durability]
            )
            guard rng.chance(probability) else { continue }
            // The ladder is `PeopleRules`' now rather than four literals here, because the match
            // engine's in-play injuries (`02` §3.8) need the same one and a hand-copied duplicate is
            // two ladders that nothing asserts agree.
            let ladder = PeopleRules.injurySeverity(roll: rng.double01())
            let severity = ladder.severity
            let weeks = PeopleRules.injuryWeeks(rng.int(in: ladder.weeks),
                                                ironman: player.has(.ironman))
            let injury = PlayerInjury(
                area: rng.pick(InjuryArea.allCases),
                severity: severity,
                occurredAt: workloadCalendar,
                originalWeeks: weeks,
                weeksRemaining: weeks
            )
            people.updatePlayerLifecycle(id) { $0.sustain(injury) }
            payloads.append(.playerInjured(
                playerID: id,
                area: injury.area,
                severity: injury.severity,
                weeks: injury.originalWeeks
            ))
        }
        return HealthTransition(people: people, eventPayloads: payloads)
    }

    private static func healthSeed(
        root: UInt64,
        calendar: CalendarState,
        playerID: UUID
    ) -> UInt64 {
        let season = SeededRandom.derive(from: root, scope: .season, ordinal: calendar.season)
        let week = SeededRandom.derive(from: season, scope: .week, ordinal: calendar.week)
        return SeededRandom.derive(from: week, scope: .personnel, identifier: playerID)
    }
}
