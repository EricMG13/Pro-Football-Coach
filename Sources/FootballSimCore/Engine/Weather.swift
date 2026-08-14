import Foundation

/// Conditions a game is played in. `02` §3.10.
///
/// `03` §1.1's Kick row named weather as an input and nothing else in the engine had ever heard of
/// it: there was no state, no derivation and no effect. Four conditions, because each one has to
/// change a decision — a fifth that read like a third of another would be flavour, and `02` §5's
/// rule against decorative traits applies to the sky as much as to a player.
public enum Weather: String, Codable, Sendable, CaseIterable {
    case clear
    case wind
    case rain
    case snow

    /// What it costs a throw, in leverage units.
    public var passPenalty: Double {
        switch self {
        case .clear: return 0
        case .wind: return MatchupRules.windPassPenalty
        case .rain: return MatchupRules.rainPassPenalty
        case .snow: return MatchupRules.snowPassPenalty
        }
    }

    /// What it costs a kick. Wind hurts a kick more than it hurts a throw, which is the whole reason
    /// the two are separate numbers rather than one weather term.
    public var kickPenalty: Double {
        switch self {
        case .clear: return 0
        case .wind: return MatchupRules.windKickPenalty
        case .rain: return MatchupRules.rainKickPenalty
        case .snow: return MatchupRules.snowKickPenalty
        }
    }

    /// How much likelier the ball is to come loose.
    public var fumbleMultiplier: Double {
        switch self {
        case .clear: return 1
        case .wind: return MatchupRules.windFumbleMultiplier
        case .rain: return MatchupRules.rainFumbleMultiplier
        case .snow: return MatchupRules.snowFumbleMultiplier
        }
    }

    public var label: String {
        switch self {
        case .clear: return "Clear"
        case .wind: return "Windy"
        case .rain: return "Rain"
        case .snow: return "Snow"
        }
    }

    /// Draws the conditions for a game.
    ///
    /// Late weeks are colder: the share of clear days falls and snow only appears at all once the
    /// season is deep enough for it. That is a season shape rather than a climate model — this game
    /// has a generated map with real regions on it (`02` §8) and tying weather to latitude is a
    /// bigger piece of work with a bigger claim behind it, so what exists here is stated as the
    /// simplification it is.
    public static func draw(week: Int, rng: inout SeededRandom) -> Weather {
        let lateness = Swift.min(Swift.max(Double(week - 1), 0), Double(MatchupRules.weatherLateWeek))
            / Double(MatchupRules.weatherLateWeek)
        let roll = rng.double01()
        let clearShare = MatchupRules.clearWeatherShare
            - lateness * MatchupRules.lateSeasonClearWeatherLoss
        if roll < clearShare { return .clear }
        let adverse = (roll - clearShare) / Swift.max(1 - clearShare, 0.000_1)
        if adverse < MatchupRules.windShareOfAdverse { return .wind }
        if adverse < MatchupRules.windShareOfAdverse + MatchupRules.rainShareOfAdverse {
            return .rain
        }
        // Snow needs the season to be late; early in the year the coldest slot is rain instead.
        return lateness >= MatchupRules.snowRequiresLateness ? .snow : .rain
    }
}
