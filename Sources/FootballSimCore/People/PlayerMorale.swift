import Foundation

/// Why a player feels how they feel. Causal, like development summaries, because a number a coach
/// cannot explain is a number they cannot act on.
public enum MoraleReason: String, Codable, Sendable, CaseIterable {
    case playingTime
    case teamSuccess
    case injury
    case investment
    case newArrival
}

public struct MoraleComponent: Sendable, Equatable {
    public let reason: MoraleReason
    /// Signed, in morale points.
    public let value: Int

    public init(reason: MoraleReason, value: Int) {
        self.reason = reason
        self.value = value
    }
}

/// How a player feels about where they are. `02` §5.1.
public struct MoraleReading: Sendable, Equatable {
    public let playerID: UUID
    /// 0 to 100, centred on `PeopleRules.baselineMorale`.
    public let value: Int
    public let components: [MoraleComponent]

    public init(playerID: UUID, value: Int, components: [MoraleComponent]) {
        self.playerID = playerID
        self.value = Swift.min(Swift.max(value, 0), 100)
        self.components = components
    }

    public var isUnhappy: Bool { value <= PeopleRules.unhappyMorale }
    public var isDelighted: Bool { value >= PeopleRules.delightedMorale }
}

/// Morale, derived. `02` §5.1.
///
/// There was none: `PeopleState` carried health, development and career records and no notion of how
/// a player felt, so a professional was never unhappy about anything and college dissatisfaction
/// existed only as portal intent. Every comparable game models this, and it is what makes a bench
/// full of good players a problem rather than an asset.
///
/// **Derived from what already happened**, not stored and drifted. Playing time, the team's season,
/// being hurt, and what the programme has invested in you are all facts the world already holds, so
/// a reading is a function of the save rather than a second number to keep in step with it — and it
/// cannot silently disagree with the record it is drawn from. It also costs nothing in save size,
/// which FSC-003 makes a live concern.
public enum PlayerMorale {
    public static func reading(for playerID: UUID, in state: GameState) -> MoraleReading {
        var components: [MoraleComponent] = []

        let organisationID = organisation(of: playerID, in: state)
        let teamGames = organisationID.flatMap { id in
            state.competition.standings.values.flatMap { $0 }.first { $0.id == id }
        }

        // 1. Playing time. The loudest thing in the sport: a good player who does not play is the
        //    portal's most common cause and the pro tier's most common trade request.
        let appearances = state.competition.playerStatistics[playerID]?.games ?? 0
        if let teamGames, teamGames.games > 0 {
            let share = appearances * 100 / teamGames.games
            if share >= PeopleRules.starterAppearanceShare {
                components.append(MoraleComponent(reason: .playingTime,
                                                  value: PeopleRules.moralePlayingTimeBonus))
            } else if share <= PeopleRules.benchAppearanceShare {
                components.append(MoraleComponent(reason: .playingTime,
                                                  value: -PeopleRules.moralePlayingTimeBonus))
            }
        } else {
            // Before a season has been played nobody is aggrieved about minutes they have not been
            // denied yet.
            components.append(MoraleComponent(reason: .newArrival, value: 0))
        }

        // 2. The season. Winning is worth something to everybody on the roster and losing costs
        //    everybody, which is why this is not weighted by playing time.
        if let teamGames, teamGames.games > 0 {
            let winPercent = teamGames.wins * 100 / teamGames.games
            if winPercent >= PeopleRules.contendingWinShare {
                components.append(MoraleComponent(reason: .teamSuccess,
                                                  value: PeopleRules.moraleTeamSuccessBonus))
            } else if winPercent <= PeopleRules.strugglingWinShare {
                components.append(MoraleComponent(reason: .teamSuccess,
                                                  value: -PeopleRules.moraleTeamSuccessBonus))
            }
        }

        // 3. Being hurt. Not a punishment for the player's own bad luck — it is the difference
        //    between a season and a lost one, and a coach should be able to see it coming.
        if state.people.playerLifecycle[playerID]?.injury != nil {
            components.append(MoraleComponent(reason: .injury, value: -PeopleRules.moraleInjuryCost))
        }

        // 4. What the programme has put into them. College only, because NIL is the college tier's
        //    scarce pot and the professional equivalent is a contract, which is negotiated rather
        //    than allocated.
        if let organisationID, state.programmes[organisationID] != nil {
            let allocation = state.college.programmes[organisationID]?
                .nilState.rosterAllocations[playerID] ?? 0
            if allocation > 0 {
                components.append(MoraleComponent(reason: .investment,
                                                  value: PeopleRules.moraleInvestmentBonus))
            }
        }

        // 5. What this place does after a result. `02` §8's morale tradition, and §5.1 is the
        //    first thing in the game with morale for it to move.
        if let organisationID, let won = lastResultWasWin(for: organisationID, in: state) {
            let delta = TraditionEffects.moraleDelta(
                programmeID: organisationID, wonLastGame: won, in: state
            )
            if delta != 0 {
                components.append(MoraleComponent(reason: .teamSuccess, value: delta))
            }
        }

        let total = components.reduce(PeopleRules.baselineMorale) { $0 + $1.value }
        return MoraleReading(playerID: playerID, value: total, components: components)
    }

    /// Everyone on a roster who is unhappy enough to be a problem, worst first.
    ///
    /// Bounded by the roster it reads, and ordered by identity on ties so a screen built from it does
    /// not reshuffle between rebuilds.
    public static func unhappy(in organisationID: UUID, state: GameState) -> [MoraleReading] {
        let rosterIDs = state.programmes[organisationID]?.rosterIDs
            ?? state.proTeams[organisationID]?.rosterIDs
            ?? []
        return rosterIDs
            .map { reading(for: $0, in: state) }
            .filter(\.isUnhappy)
            .sorted {
                $0.value == $1.value
                    ? $0.playerID.uuidString < $1.playerID.uuidString
                    : $0.value < $1.value
            }
    }

    /// Whether the organisation won its most recent completed game, or nil if it has not played.
    ///
    /// Latest by week rather than by array order, because a schedule is not stored in the order it
    /// is played and "the last result" that read one would be whichever fixture happened to be last
    /// in the file.
    static func lastResultWasWin(for organisationID: UUID, in state: GameState) -> Bool? {
        let played = state.competition.currentSchedule.games.filter {
            ($0.homeID == organisationID || $0.awayID == organisationID) && $0.result != nil
        }
        guard let latest = played.max(by: { $0.week < $1.week }), let result = latest.result else {
            return nil
        }
        let ours = latest.homeID == organisationID ? result.homeScore : result.awayScore
        let theirs = latest.homeID == organisationID ? result.awayScore : result.homeScore
        return ours > theirs
    }

    private static func organisation(of playerID: UUID, in state: GameState) -> UUID? {
        if let programme = state.programmes.values.first(where: {
            $0.rosterIDs.contains(playerID)
        }) { return programme.id }
        return state.proTeams.values.first { $0.rosterIDs.contains(playerID) }?.id
    }
}
