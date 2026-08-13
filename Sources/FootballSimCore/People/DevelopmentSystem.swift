import Foundation

public struct DevelopmentTransition: Sendable, Equatable {
    public let players: EntityStore<Player>
    public let people: PeopleState
    public let eventPayloads: [DomainEventPayload]

    public init(
        players: EntityStore<Player>,
        people: PeopleState,
        eventPayloads: [DomainEventPayload]
    ) {
        self.players = players
        self.people = people
        self.eventPayloads = eventPayloads
    }
}

public enum DevelopmentSystem {
    public static func practice(at calendar: CalendarState, in state: GameState) -> DevelopmentTransition {
        practice(at: calendar, in: state, tactical: state.tactical)
    }

    public static func practice(
        at calendar: CalendarState,
        in state: GameState,
        tactical: TacticalState
    ) -> DevelopmentTransition {
        guard PeopleRules.inSeasonDevelopmentWeeks.contains(calendar.week) else {
            return DevelopmentTransition(players: state.players, people: state.people, eventPayloads: [])
        }
        var players = state.players
        var people = state.people
        var payloads: [DomainEventPayload] = []
        let context = developmentContext(state, tactical: tactical)

        for id in state.players.ids {
            guard let player = players[id],
                  people.playerLifecycle[id]?.status == .active else { continue }
            let components = componentsFor(
                player,
                coachRating: context.coachRatingByPlayer[id] ?? SharedRules.ratingRange.lowerBound,
                practiceValue: context.practiceValueByPlayer[id] ?? TacticalPracticePlan.balanced.developmentValue(for: player),
                played: (state.competition.playerStatistics[id]?.games ?? 0) > 0,
                facilities: context.facilityRatingByPlayer[id] ?? SharedRules.ratingRange.lowerBound
            )
            let score = components.reduce(0) { $0 + $1.value }
            let delta = score >= PeopleRules.developmentThreshold ? 1 : (score < 0 ? -1 : 0)
            guard delta != 0, let attribute = developmentAttribute(player, delta: delta) else {
                people.updatePlayerLifecycle(id) {
                    $0.recordDevelopment(DevelopmentSummary(
                        occurredAt: calendar,
                        components: components,
                        attributeChanges: []
                    ))
                }
                continue
            }
            let oldRating = player.attributes[attribute]
            let upperBound = delta > 0 ? player.potential.value : SharedRules.ratingRange.upperBound
            let newValue = min(upperBound, max(
                SharedRules.ratingRange.lowerBound,
                oldRating.value + delta
            ))
            let applied = newValue - oldRating.value
            guard applied != 0 else {
                people.updatePlayerLifecycle(id) {
                    $0.recordDevelopment(DevelopmentSummary(
                        occurredAt: calendar,
                        components: components,
                        attributeChanges: []
                    ))
                }
                continue
            }
            players.update(id) { $0.attributes[attribute] = Rating(newValue) }
            let summary = DevelopmentSummary(
                occurredAt: calendar,
                components: components,
                attributeChanges: [AttributeDevelopment(attribute: attribute, delta: applied)]
            )
            people.updatePlayerLifecycle(id) { $0.recordDevelopment(summary) }
            payloads.append(.playerDeveloped(
                playerID: id,
                attribute: attribute,
                delta: applied,
                components: components
            ))
        }
        return DevelopmentTransition(players: players, people: people, eventPayloads: payloads)
    }

    private struct Context {
        let coachRatingByPlayer: [UUID: Int]
        let practiceValueByPlayer: [UUID: Int]
        let facilityRatingByPlayer: [UUID: Int]
    }

    private static func developmentContext(
        _ state: GameState,
        tactical: TacticalState
    ) -> Context {
        var coachByOrganisationAndGroup: [String: Int] = [:]
        var practiceValueByPlayer: [UUID: Int] = [:]
        let organisations = state.programmes.values.map { ($0.id, $0.rosterIDs, $0.staffIDs) }
            + state.proTeams.values.map { ($0.id, $0.rosterIDs, $0.staffIDs) }
        var ratingByPlayer: [UUID: Int] = [:]
        for (organisationID, rosterIDs, staffIDs) in organisations {
            for staffID in staffIDs {
                guard let member = state.staff[staffID],
                      member.role == .positionCoach,
                      let group = member.positionGroup else { continue }
                coachByOrganisationAndGroup["\(organisationID.uuidString)|\(group.rawValue)"] =
                    member.rating(.development).value
            }
            let practicePlan = tactical.practicePlan(for: organisationID, at: state.calendar)
                ?? .balanced
            for playerID in rosterIDs {
                guard let player = state.players[playerID] else { continue }
                ratingByPlayer[playerID] = coachByOrganisationAndGroup[
                    "\(organisationID.uuidString)|\(player.position.group.rawValue)"
                ]
                practiceValueByPlayer[playerID] = practicePlan.developmentValue(for: player)
            }
        }
        // `02` §10. Where each player trains, resolved once per week rather than per player: the
        // whole point of the context object is that a 15,766-player loop does not walk 166 rosters
        // once each.
        var facilityByPlayer: [UUID: Int] = [:]
        for programme in state.programmes.values {
            let rating = programme.finances(defaultingFor: .college).facilities.value
            for playerID in programme.rosterIDs { facilityByPlayer[playerID] = rating }
        }
        for team in state.proTeams.values {
            let rating = team.finances(defaultingFor: .pro).facilities.value
            for playerID in team.rosterIDs + team.practiceSquadIDs {
                facilityByPlayer[playerID] = rating
            }
        }
        return Context(
            coachRatingByPlayer: ratingByPlayer,
            practiceValueByPlayer: practiceValueByPlayer,
            facilityRatingByPlayer: facilityByPlayer
        )
    }

    private static func componentsFor(
        _ player: Player,
        coachRating: Int,
        practiceValue: Int,
        played: Bool,
        facilities: Int
    ) -> [DevelopmentComponent] {
        let ageValue: Int
        if player.isDeclining {
            ageValue = -2
        } else if player.age <= 21 {
            ageValue = 2
        } else {
            ageValue = 1
        }
        let workEthic = player.attributes[.workEthic].value
        let workValue: Int
        if workEthic >= PeopleRules.strongWorkEthicRating {
            workValue = 2
        } else if workEthic >= PeopleRules.adequateWorkEthicRating {
            workValue = 1
        } else if workEthic < PeopleRules.poorWorkEthicRating {
            workValue = -1
        } else {
            workValue = 0
        }
        let coachValue = coachRating >= PeopleRules.strongCoachRating
            ? 2
            : (coachRating >= PeopleRules.competentCoachRating ? 1 : 0)
        return [
            DevelopmentComponent(reason: player.isDeclining ? .decline : .ageCurve, value: ageValue),
            DevelopmentComponent(reason: .practice, value: practiceValue),
            DevelopmentComponent(reason: .playingTime, value: played ? 1 : 0),
            DevelopmentComponent(reason: .coaching, value: coachValue),
            DevelopmentComponent(
                reason: .schemeFit,
                value: player.attributes[.schemeFit].value >= PeopleRules.schemeFitDevelopmentRating ? 1 : 0
            ),
            DevelopmentComponent(reason: .workEthic, value: workValue),
            // `02` §10. Buildings help; coaching helps more. A facility bonus that outweighed a
            // position coach would make the staff decorative, so it is one point at the top of the
            // scale and nothing below it.
            DevelopmentComponent(
                reason: .facilities,
                value: facilities >= FinanceRules.strongFacilityRating
                    ? FinanceRules.facilityDevelopmentBonus
                    : 0
            ),
        ]
    }

    private static func developmentAttribute(_ player: Player, delta: Int) -> Attribute? {
        let attributes = player.position.ratedAttributes
        if delta > 0 {
            return attributes
                .filter { player.attributes[$0].value < player.potential.value }
                .sorted {
                    let lhs = player.attributes[$0].value
                    let rhs = player.attributes[$1].value
                    return lhs == rhs ? $0.rawValue < $1.rawValue : lhs < rhs
                }
                .first
        }
        return attributes.sorted {
            let lhs = player.attributes[$0].value
            let rhs = player.attributes[$1].value
            return lhs == rhs ? $0.rawValue < $1.rawValue : lhs > rhs
        }.first
    }
}
