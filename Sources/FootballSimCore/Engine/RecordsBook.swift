import Foundation

/// A single-season or career mark worth chasing.
public struct LeagueRecord: Sendable, Equatable, Identifiable {
    public enum Kind: String, Sendable, CaseIterable {
        case passingYardsSeason, rushingYardsSeason, receivingYardsSeason
        case passingTouchdownsSeason, sacksSeason, interceptionsSeason
        case passingYardsCareer, rushingYardsCareer, receivingYardsCareer

        public var displayName: String {
            switch self {
            case .passingYardsSeason: "Passing Yards, Season"
            case .rushingYardsSeason: "Rushing Yards, Season"
            case .receivingYardsSeason: "Receiving Yards, Season"
            case .passingTouchdownsSeason: "Passing Touchdowns, Season"
            case .sacksSeason: "Sacks, Season"
            case .interceptionsSeason: "Interceptions, Season"
            case .passingYardsCareer: "Passing Yards, Career"
            case .rushingYardsCareer: "Rushing Yards, Career"
            case .receivingYardsCareer: "Receiving Yards, Career"
            }
        }

        public var isCareer: Bool {
            switch self {
            case .passingYardsCareer, .rushingYardsCareer, .receivingYardsCareer: true
            default: false
            }
        }
    }

    public var id: String { kind.rawValue }
    public let kind: Kind
    public let holderName: String
    public let value: Int
    public let year: Int

    public init(kind: Kind, holderName: String, value: Int, year: Int) {
        self.kind = kind
        self.holderName = holderName
        self.value = value
        self.year = year
    }
}

/// Computes the record book from what has actually happened in this league, seeded with
/// historical marks so year one already has something to chase.
public enum RecordsBook {

    /// Fictional marks predating the save, so the book is never empty.
    private static func seeded(_ kind: LeagueRecord.Kind) -> LeagueRecord {
        switch kind {
        case .passingYardsSeason: LeagueRecord(kind: kind, holderName: "Del Ashworth", value: 5_412, year: 2011)
        case .rushingYardsSeason: LeagueRecord(kind: kind, holderName: "Cyrus Bellamy", value: 2_098, year: 2004)
        case .receivingYardsSeason: LeagueRecord(kind: kind, holderName: "Trey Winslow", value: 1_889, year: 2016)
        case .passingTouchdownsSeason: LeagueRecord(kind: kind, holderName: "Del Ashworth", value: 48, year: 2011)
        case .sacksSeason: LeagueRecord(kind: kind, holderName: "Marcus Kilgore", value: 22, year: 1998)
        case .interceptionsSeason: LeagueRecord(kind: kind, holderName: "Otis Redmond", value: 13, year: 1987)
        case .passingYardsCareer: LeagueRecord(kind: kind, holderName: "Del Ashworth", value: 71_940, year: 2018)
        case .rushingYardsCareer: LeagueRecord(kind: kind, holderName: "Cyrus Bellamy", value: 17_240, year: 2012)
        case .receivingYardsCareer: LeagueRecord(kind: kind, holderName: "Trey Winslow", value: 16_105, year: 2022)
        }
    }

    private static func value(_ kind: LeagueRecord.Kind, in line: StatLine) -> Int {
        switch kind {
        case .passingYardsSeason, .passingYardsCareer: line.passingYards
        case .rushingYardsSeason, .rushingYardsCareer: line.rushingYards
        case .receivingYardsSeason, .receivingYardsCareer: line.receivingYards
        case .passingTouchdownsSeason: line.passingTouchdowns
        case .sacksSeason: line.sacks
        case .interceptionsSeason: line.interceptions
        }
    }

    /// The current holder of every record, whether that is a seeded mark or someone in this save.
    public static func current(in league: League) -> [LeagueRecord] {
        LeagueRecord.Kind.allCases.map { kind in
            var best = seeded(kind)

            if kind.isCareer {
                for team in league.teams {
                    for player in team.roster {
                        let total = value(kind, in: league.careerStats(for: player.id))
                        if total > best.value {
                            best = LeagueRecord(
                                kind: kind, holderName: player.name, value: total, year: league.year
                            )
                        }
                    }
                }
            } else {
                // Single seasons: this year plus every archived one.
                for team in league.teams {
                    for player in team.roster {
                        let total = value(kind, in: league.seasonStats(for: player.id))
                        if total > best.value {
                            best = LeagueRecord(
                                kind: kind, holderName: player.name, value: total, year: league.year
                            )
                        }
                    }
                }
                for season in league.history {
                    for (playerID, line) in season.playerStats {
                        let total = value(kind, in: line)
                        guard total > best.value else { continue }
                        let name = league.findPlayer(id: playerID)?.player.name ?? "A former player"
                        best = LeagueRecord(kind: kind, holderName: name, value: total, year: season.year)
                    }
                }
            }
            return best
        }
    }
}

/// A player enshrined after his career ended.
public struct HallOfFamer: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let position: Position
    public let inductionYear: Int
    public let careerSummary: String
    public let score: Int

    public init(
        id: UUID,
        name: String,
        position: Position,
        inductionYear: Int,
        careerSummary: String,
        score: Int
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.inductionYear = inductionYear
        self.careerSummary = careerSummary
        self.score = score
    }
}

/// Decides who deserves enshrinement when a career ends.
public enum HallOfFame {

    /// A rough career worth. The threshold is set so a handful go in each year, not a crowd.
    public static func score(player: Player, career: StatLine, championships: Int = 0) -> Int {
        var total = 0
        total += career.passingYards / 60
        total += career.passingTouchdowns * 6
        total += career.rushingYards / 25
        total += career.receivingYards / 25
        total += career.totalTouchdowns * 8
        total += career.tackles / 3
        total += Int(career.sacks) * 12
        total += career.interceptions * 14
        total += career.fieldGoalsMade / 2
        total += championships * 40
        total -= career.interceptionsThrown * 2
        return max(0, total)
    }

    public static let inductionThreshold = 320

    /// Builds the induction summary line shown on the Hall of Fame screen.
    public static func summary(for player: Player, career: StatLine) -> String {
        switch player.position {
        case .qb:
            return "\(career.passingYards) passing yards, \(career.passingTouchdowns) touchdowns"
        case .rb:
            return "\(career.rushingYards) rushing yards, \(career.rushingTouchdowns) touchdowns"
        case .wr, .te:
            return "\(career.receptions) catches, \(career.receivingYards) yards"
        case .dl, .lb:
            return "\(career.tackles) tackles, \(career.sacks) sacks"
        case .cb, .s:
            return "\(career.interceptions) interceptions, \(career.passesDefended) passes defended"
        case .k:
            return "\(career.fieldGoalsMade) field goals"
        case .p:
            return "\(career.punts) punts, \(String(format: "%.1f", career.averagePunt)) average"
        case .ol:
            return "\(career.gamesPlayed) games on the line"
        }
    }

    /// Considers a class of retiring players for enshrinement.
    public static func induct(
        retiring: [Player],
        league: League
    ) -> [HallOfFamer] {
        retiring.compactMap { player in
            let career = league.careerStats(for: player.id)
            let value = score(player: player, career: career)
            guard value >= inductionThreshold else { return nil }
            return HallOfFamer(
                id: player.id,
                name: player.name,
                position: player.position,
                inductionYear: league.year,
                careerSummary: summary(for: player, career: career),
                score: value
            )
        }
    }
}
