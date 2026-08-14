import Foundation

/// What a team did in one game.
///
/// The four new counters — sacks, interceptions and the two penalty numbers — are the ones a box
/// score is unreadable without and that both models can produce honestly. Everything else a real box
/// score carries (first downs, third-down conversions, time of possession) needs per-drive
/// accounting, which `docs/OPEN-DECISIONS.md` D2 has open, and inventing them from a yardage total
/// would be a number that looks like evidence and is not.
public struct TeamGameStatistics: Codable, Sendable, Equatable {
    public let points: Int
    public let offensiveYards: Int
    public let passingYards: Int
    public let rushingYards: Int
    public let turnovers: Int
    public let sacksAllowed: Int
    public let interceptionsThrown: Int
    public let penalties: Int
    public let penaltyYards: Int

    public init(
        points: Int,
        offensiveYards: Int,
        passingYards: Int,
        rushingYards: Int,
        turnovers: Int,
        sacksAllowed: Int = 0,
        interceptionsThrown: Int = 0,
        penalties: Int = 0,
        penaltyYards: Int = 0
    ) {
        self.points = max(0, points)
        self.offensiveYards = max(0, offensiveYards)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.turnovers = max(0, turnovers)
        self.sacksAllowed = max(0, sacksAllowed)
        self.interceptionsThrown = max(0, interceptionsThrown)
        self.penalties = max(0, penalties)
        self.penaltyYards = max(0, penaltyYards)
    }
}

/// One player's line from one game.
///
/// **Before 2026-08-13 this was four numbers**: passing, rushing and receiving yards, and
/// touchdowns. All three yardage figures are offensive, so every defender and every specialist in
/// the world accumulated nothing at all, and no rate statistic was computable from any of it — there
/// were no attempts to divide by. That capped awards, records, scouting and player valuation at the
/// offensive skill positions, permanently and invisibly.
///
/// **Sparsely encoded.** A line is written with only its non-zero counters, because the overwhelming
/// majority of these fields are zero for any given player: a cornerback has no passing attempts and
/// a quarterback makes no tackles. `docs/FUTURE-SIMULATION-CONTRACT.md` FSC-003 is a release blocker
/// about save size, so widening a per-player-per-game record from four fields to twenty-six without
/// this would have been a straightforward way to make that worse.
public struct PlayerGameStatistics: Codable, Sendable, Equatable {
    public let playerID: UUID

    // Passing. `passingTouchdowns` are thrown; `touchdowns` are scored. They are different things
    // and a box score that added them together would double-count every scoring pass.
    public let passAttempts: Int
    public let completions: Int
    public let passingYards: Int
    public let passingTouchdowns: Int
    public let interceptionsThrown: Int
    public let sacksTaken: Int

    // Rushing.
    public let carries: Int
    public let rushingYards: Int

    // Receiving.
    public let targets: Int
    public let receptions: Int
    public let receivingYards: Int

    /// Touchdowns this player scored, by any route to the end zone.
    public let touchdowns: Int
    public let fumblesLost: Int

    // Defence. The half of the sport that had no record at all.
    public let tackles: Int
    public let sacks: Int
    public let interceptions: Int
    public let passesDefended: Int
    public let forcedFumbles: Int

    // Kicking and returns.
    public let fieldGoalsAttempted: Int
    public let fieldGoalsMade: Int
    public let extraPointsAttempted: Int
    public let extraPointsMade: Int
    public let punts: Int
    public let puntYards: Int
    public let kickReturns: Int
    public let kickReturnYards: Int

    public init(
        playerID: UUID,
        passAttempts: Int = 0,
        completions: Int = 0,
        passingYards: Int = 0,
        passingTouchdowns: Int = 0,
        interceptionsThrown: Int = 0,
        sacksTaken: Int = 0,
        carries: Int = 0,
        rushingYards: Int = 0,
        targets: Int = 0,
        receptions: Int = 0,
        receivingYards: Int = 0,
        touchdowns: Int = 0,
        fumblesLost: Int = 0,
        tackles: Int = 0,
        sacks: Int = 0,
        interceptions: Int = 0,
        passesDefended: Int = 0,
        forcedFumbles: Int = 0,
        fieldGoalsAttempted: Int = 0,
        fieldGoalsMade: Int = 0,
        extraPointsAttempted: Int = 0,
        extraPointsMade: Int = 0,
        punts: Int = 0,
        puntYards: Int = 0,
        kickReturns: Int = 0,
        kickReturnYards: Int = 0
    ) {
        self.playerID = playerID
        self.passAttempts = max(0, passAttempts)
        self.completions = max(0, completions)
        self.passingYards = max(0, passingYards)
        self.passingTouchdowns = max(0, passingTouchdowns)
        self.interceptionsThrown = max(0, interceptionsThrown)
        self.sacksTaken = max(0, sacksTaken)
        self.carries = max(0, carries)
        self.rushingYards = max(0, rushingYards)
        self.targets = max(0, targets)
        self.receptions = max(0, receptions)
        self.receivingYards = max(0, receivingYards)
        self.touchdowns = max(0, touchdowns)
        self.fumblesLost = max(0, fumblesLost)
        self.tackles = max(0, tackles)
        self.sacks = max(0, sacks)
        self.interceptions = max(0, interceptions)
        self.passesDefended = max(0, passesDefended)
        self.forcedFumbles = max(0, forcedFumbles)
        self.fieldGoalsAttempted = max(0, fieldGoalsAttempted)
        self.fieldGoalsMade = max(0, fieldGoalsMade)
        self.extraPointsAttempted = max(0, extraPointsAttempted)
        self.extraPointsMade = max(0, extraPointsMade)
        self.punts = max(0, punts)
        self.puntYards = max(0, puntYards)
        self.kickReturns = max(0, kickReturns)
        self.kickReturnYards = max(0, kickReturnYards)
    }

    /// Written by hand because both `init(from:)` and `encode(to:)` below are hand-written — Swift
    /// only synthesizes `CodingKeys` as a byproduct of synthesizing the coding methods themselves,
    /// and with both provided there is nothing left to synthesize.
    private enum CodingKeys: String, CodingKey {
        case playerID
        case passAttempts, completions, passingYards, passingTouchdowns, interceptionsThrown,
            sacksTaken
        case carries, rushingYards
        case targets, receptions, receivingYards
        case touchdowns, fumblesLost
        case tackles, sacks, interceptions, passesDefended, forcedFumbles
        case fieldGoalsAttempted, fieldGoalsMade, extraPointsAttempted, extraPointsMade
        case punts, puntYards, kickReturns, kickReturnYards
    }

    /// Sparse decoding: an absent counter is zero, which is also what makes a line written before
    /// this vocabulary existed still readable.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func count(_ key: CodingKeys) throws -> Int {
            try container.decodeIfPresent(Int.self, forKey: key) ?? 0
        }
        self.init(
            playerID: try container.decode(UUID.self, forKey: .playerID),
            passAttempts: try count(.passAttempts),
            completions: try count(.completions),
            passingYards: try count(.passingYards),
            passingTouchdowns: try count(.passingTouchdowns),
            interceptionsThrown: try count(.interceptionsThrown),
            sacksTaken: try count(.sacksTaken),
            carries: try count(.carries),
            rushingYards: try count(.rushingYards),
            targets: try count(.targets),
            receptions: try count(.receptions),
            receivingYards: try count(.receivingYards),
            touchdowns: try count(.touchdowns),
            fumblesLost: try count(.fumblesLost),
            tackles: try count(.tackles),
            sacks: try count(.sacks),
            interceptions: try count(.interceptions),
            passesDefended: try count(.passesDefended),
            forcedFumbles: try count(.forcedFumbles),
            fieldGoalsAttempted: try count(.fieldGoalsAttempted),
            fieldGoalsMade: try count(.fieldGoalsMade),
            extraPointsAttempted: try count(.extraPointsAttempted),
            extraPointsMade: try count(.extraPointsMade),
            punts: try count(.punts),
            puntYards: try count(.puntYards),
            kickReturns: try count(.kickReturns),
            kickReturnYards: try count(.kickReturnYards)
        )
    }

    /// Writes only what happened. See the type's note on FSC-003.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerID, forKey: .playerID)
        func put(_ value: Int, _ key: CodingKeys) throws {
            guard value != 0 else { return }
            try container.encode(value, forKey: key)
        }
        try put(passAttempts, .passAttempts)
        try put(completions, .completions)
        try put(passingYards, .passingYards)
        try put(passingTouchdowns, .passingTouchdowns)
        try put(interceptionsThrown, .interceptionsThrown)
        try put(sacksTaken, .sacksTaken)
        try put(carries, .carries)
        try put(rushingYards, .rushingYards)
        try put(targets, .targets)
        try put(receptions, .receptions)
        try put(receivingYards, .receivingYards)
        try put(touchdowns, .touchdowns)
        try put(fumblesLost, .fumblesLost)
        try put(tackles, .tackles)
        try put(sacks, .sacks)
        try put(interceptions, .interceptions)
        try put(passesDefended, .passesDefended)
        try put(forcedFumbles, .forcedFumbles)
        try put(fieldGoalsAttempted, .fieldGoalsAttempted)
        try put(fieldGoalsMade, .fieldGoalsMade)
        try put(extraPointsAttempted, .extraPointsAttempted)
        try put(extraPointsMade, .extraPointsMade)
        try put(punts, .punts)
        try put(puntYards, .puntYards)
        try put(kickReturns, .kickReturns)
        try put(kickReturnYards, .kickReturnYards)
    }

    /// Whether this line records anything at all. A player who was on the field and did nothing
    /// measurable still has an appearance; the appearance lives on the season record, not here.
    public var isEmpty: Bool {
        passAttempts == 0 && completions == 0 && passingYards == 0 && passingTouchdowns == 0
            && interceptionsThrown == 0 && sacksTaken == 0 && carries == 0 && rushingYards == 0
            && targets == 0 && receptions == 0 && receivingYards == 0 && touchdowns == 0
            && fumblesLost == 0 && tackles == 0 && sacks == 0 && interceptions == 0
            && passesDefended == 0 && forcedFumbles == 0 && fieldGoalsAttempted == 0
            && fieldGoalsMade == 0 && extraPointsAttempted == 0 && extraPointsMade == 0
            && punts == 0 && puntYards == 0 && kickReturns == 0 && kickReturnYards == 0
    }

    /// Two lines for the same player, added. What a box score builder does when a player appears in
    /// several plays, and what a season record does across games.
    public static func + (lhs: PlayerGameStatistics, rhs: PlayerGameStatistics)
        -> PlayerGameStatistics {
        PlayerGameStatistics(
            playerID: lhs.playerID,
            passAttempts: lhs.passAttempts + rhs.passAttempts,
            completions: lhs.completions + rhs.completions,
            passingYards: lhs.passingYards + rhs.passingYards,
            passingTouchdowns: lhs.passingTouchdowns + rhs.passingTouchdowns,
            interceptionsThrown: lhs.interceptionsThrown + rhs.interceptionsThrown,
            sacksTaken: lhs.sacksTaken + rhs.sacksTaken,
            carries: lhs.carries + rhs.carries,
            rushingYards: lhs.rushingYards + rhs.rushingYards,
            targets: lhs.targets + rhs.targets,
            receptions: lhs.receptions + rhs.receptions,
            receivingYards: lhs.receivingYards + rhs.receivingYards,
            touchdowns: lhs.touchdowns + rhs.touchdowns,
            fumblesLost: lhs.fumblesLost + rhs.fumblesLost,
            tackles: lhs.tackles + rhs.tackles,
            sacks: lhs.sacks + rhs.sacks,
            interceptions: lhs.interceptions + rhs.interceptions,
            passesDefended: lhs.passesDefended + rhs.passesDefended,
            forcedFumbles: lhs.forcedFumbles + rhs.forcedFumbles,
            fieldGoalsAttempted: lhs.fieldGoalsAttempted + rhs.fieldGoalsAttempted,
            fieldGoalsMade: lhs.fieldGoalsMade + rhs.fieldGoalsMade,
            extraPointsAttempted: lhs.extraPointsAttempted + rhs.extraPointsAttempted,
            extraPointsMade: lhs.extraPointsMade + rhs.extraPointsMade,
            punts: lhs.punts + rhs.punts,
            puntYards: lhs.puntYards + rhs.puntYards,
            kickReturns: lhs.kickReturns + rhs.kickReturns,
            kickReturnYards: lhs.kickReturnYards + rhs.kickReturnYards
        )
    }
}

public struct StandingRow: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public private(set) var wins: Int
    public private(set) var losses: Int
    public private(set) var conferenceWins: Int
    public private(set) var conferenceLosses: Int
    public private(set) var pointsFor: Int
    public private(set) var pointsAgainst: Int

    public init(
        id: UUID,
        wins: Int = 0,
        losses: Int = 0,
        conferenceWins: Int = 0,
        conferenceLosses: Int = 0,
        pointsFor: Int = 0,
        pointsAgainst: Int = 0
    ) {
        self.id = id
        self.wins = max(0, wins)
        self.losses = max(0, losses)
        self.conferenceWins = max(0, conferenceWins)
        self.conferenceLosses = max(0, conferenceLosses)
        self.pointsFor = max(0, pointsFor)
        self.pointsAgainst = max(0, pointsAgainst)
    }

    public var games: Int { wins + losses }
    public var conferenceGames: Int { conferenceWins + conferenceLosses }
    public var pointDifferential: Int { pointsFor - pointsAgainst }

    public mutating func record(win: Bool, conference: Bool, pointsFor: Int, pointsAgainst: Int) {
        if win { wins += 1 } else { losses += 1 }
        if conference {
            if win { conferenceWins += 1 } else { conferenceLosses += 1 }
        }
        self.pointsFor += max(0, pointsFor)
        self.pointsAgainst += max(0, pointsAgainst)
    }
}

public struct TeamSeasonStatistics: Codable, Sendable, Equatable {
    public private(set) var games: Int
    public private(set) var points: Int
    public private(set) var offensiveYards: Int
    public private(set) var passingYards: Int
    public private(set) var rushingYards: Int
    public private(set) var turnovers: Int
    public private(set) var sacksAllowed: Int
    public private(set) var interceptionsThrown: Int
    public private(set) var penalties: Int
    public private(set) var penaltyYards: Int

    public init(
        games: Int = 0,
        points: Int = 0,
        offensiveYards: Int = 0,
        passingYards: Int = 0,
        rushingYards: Int = 0,
        turnovers: Int = 0,
        sacksAllowed: Int = 0,
        interceptionsThrown: Int = 0,
        penalties: Int = 0,
        penaltyYards: Int = 0
    ) {
        self.games = max(0, games)
        self.points = max(0, points)
        self.offensiveYards = max(0, offensiveYards)
        self.passingYards = max(0, passingYards)
        self.rushingYards = max(0, rushingYards)
        self.turnovers = max(0, turnovers)
        self.sacksAllowed = max(0, sacksAllowed)
        self.interceptionsThrown = max(0, interceptionsThrown)
        self.penalties = max(0, penalties)
        self.penaltyYards = max(0, penaltyYards)
    }

    /// Sparse decoding, for the same reason the player line has it: a record written before the
    /// counters existed still reads, with zeros where the counters would be.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func count(_ key: CodingKeys) throws -> Int {
            try container.decodeIfPresent(Int.self, forKey: key) ?? 0
        }
        self.init(
            games: try count(.games),
            points: try count(.points),
            offensiveYards: try count(.offensiveYards),
            passingYards: try count(.passingYards),
            rushingYards: try count(.rushingYards),
            turnovers: try count(.turnovers),
            sacksAllowed: try count(.sacksAllowed),
            interceptionsThrown: try count(.interceptionsThrown),
            penalties: try count(.penalties),
            penaltyYards: try count(.penaltyYards)
        )
    }

    public mutating func record(_ game: TeamGameStatistics) {
        games += 1
        points += game.points
        offensiveYards += game.offensiveYards
        passingYards += game.passingYards
        rushingYards += game.rushingYards
        turnovers += game.turnovers
        sacksAllowed += game.sacksAllowed
        interceptionsThrown += game.interceptionsThrown
        penalties += game.penalties
        penaltyYards += game.penaltyYards
    }
}

public struct PlayerSeasonStatistics: Codable, Sendable, Equatable {
    public let playerID: UUID
    public private(set) var games: Int
    /// Everything else, in the same vocabulary a single game is recorded in — so a season is the sum
    /// of its games rather than a second, differently-shaped record that has to be kept in step.
    public private(set) var totals: PlayerGameStatistics

    public init(playerID: UUID, games: Int = 0, totals: PlayerGameStatistics? = nil) {
        self.playerID = playerID
        self.games = max(0, games)
        self.totals = totals ?? PlayerGameStatistics(playerID: playerID)
    }

    /// Reads both shapes: the nested one this type writes now, and the flat four-counter one it
    /// wrote before the vocabulary widened.
    ///
    /// **This is a migration, done in place, and it is why the root schema version does not move.**
    /// `GameState` requires an exact version match with no migration path, so a bump would reject
    /// every existing save outright. Reading the old keys costs six lines and keeps them loadable;
    /// the alternative was to strand them for a widened box score.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .playerID)
        let played = try container.decodeIfPresent(Int.self, forKey: .games) ?? 0
        if let totals = try container.decodeIfPresent(PlayerGameStatistics.self, forKey: .totals) {
            self.init(playerID: id, games: played, totals: totals)
            return
        }
        let legacy = try decoder.container(keyedBy: LegacyKeys.self)
        func count(_ key: LegacyKeys) throws -> Int {
            try legacy.decodeIfPresent(Int.self, forKey: key) ?? 0
        }
        self.init(playerID: id, games: played, totals: PlayerGameStatistics(
            playerID: id,
            passingYards: try count(.passingYards),
            rushingYards: try count(.rushingYards),
            receivingYards: try count(.receivingYards),
            touchdowns: try count(.touchdowns)
        ))
    }

    /// The four counters a season record carried before 2026-08-13.
    private enum LegacyKeys: String, CodingKey {
        case passingYards, rushingYards, receivingYards, touchdowns
    }

    /// The counters, read straight through, so callers that only want yardage do not have to know
    /// about `totals`.
    public var passAttempts: Int { totals.passAttempts }
    public var completions: Int { totals.completions }
    public var passingYards: Int { totals.passingYards }
    public var passingTouchdowns: Int { totals.passingTouchdowns }
    public var interceptionsThrown: Int { totals.interceptionsThrown }
    public var carries: Int { totals.carries }
    public var rushingYards: Int { totals.rushingYards }
    public var targets: Int { totals.targets }
    public var receptions: Int { totals.receptions }
    public var receivingYards: Int { totals.receivingYards }
    public var touchdowns: Int { totals.touchdowns }
    public var tackles: Int { totals.tackles }
    public var sacks: Int { totals.sacks }
    public var interceptions: Int { totals.interceptions }
    public var passesDefended: Int { totals.passesDefended }
    public var forcedFumbles: Int { totals.forcedFumbles }
    public var fieldGoalsAttempted: Int { totals.fieldGoalsAttempted }
    public var fieldGoalsMade: Int { totals.fieldGoalsMade }
    public var punts: Int { totals.punts }
    public var kickReturnYards: Int { totals.kickReturnYards }

    /// Yards from scrimmage: the number a running back and a receiver are actually compared on.
    public var scrimmageYards: Int { totals.rushingYards + totals.receivingYards }

    public mutating func recordAppearance() {
        games += 1
    }

    public mutating func recordProduction(_ game: PlayerGameStatistics) {
        totals = totals + game
    }
}
