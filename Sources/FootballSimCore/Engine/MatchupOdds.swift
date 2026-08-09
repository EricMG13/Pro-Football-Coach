import Foundation

/// What the numbers say about a game before it is played.
///
/// This lived in the view layer, which hand-typed its own `e` (`2.718_281_8`) and derived a
/// spread from a magic multiplier. Odds are a rule of the game, not a presentation detail: the
/// hub, the matchup preview and any future betting-style display must all agree, and a rule the
/// UI invents cannot be calibrated or tested.
public enum MatchupOdds {

    /// Rating advantage to the home side, home-field bonus included.
    public static func edge(home: Team, away: Team) -> Double {
        home.overallRating + Double(PlayMatrix.homeFieldRatingBonus) - away.overallRating
    }

    /// How much one point of rating edge moves the odds.
    ///
    /// Anchored to the simulator rather than chosen: `GameSimulatorTests` calibrates the engine's
    /// home win rate to 0.50–0.60, and home field is worth `PlayMatrix.homeFieldRatingBonus`
    /// (4.2) of rating, so two identical teams must land inside that same band. The value the UI
    /// used to hard-code, 0.16, put them at 0.66 and made a ten-point rating gap look like an
    /// 83% lock — football is never that certain, and the engine never said it was.
    static let logisticSlope = 0.048

    /// Logistic map from rating edge to the home side's win probability.
    public static func homeWinProbability(home: Team, away: Team) -> Double {
        1 / (1 + exp(-edge(home: home, away: away) * logisticSlope))
    }

    /// The points the home side is favoured by. Negative means the visitors are favoured.
    public static func spread(home: Team, away: Team) -> Double {
        edge(home: home, away: away) * 0.55
    }

    /// One plain sentence about the matchup, in the coordinator's voice.
    ///
    /// Replaces the LINE / WIN % / EDGE pill row inherited from the reference app: three numbers
    /// a player has to assemble into a meaning. This states the meaning and keeps the number.
    public static func summary(home: Team, away: Team, userTeamID: UUID) -> String {
        let favouringHome = spread(home: home, away: away) >= 0
        let favourite = favouringHome ? home : away
        let underdog = favouringHome ? away : home
        let margin = abs(spread(home: home, away: away))
        let userIsFavourite = favourite.id == userTeamID
        let userInvolved = home.id == userTeamID || away.id == userTeamID

        let points = margin < 0.5
            ? "level"
            : "\(String(format: "%.1f", margin)) point\(margin < 1.5 ? "" : "s")"

        if margin < 0.5 {
            return "Nothing between them on paper. Whoever wins the turnover battle wins the game."
        }

        guard userInvolved else {
            return "\(favourite.name) by \(points) on paper."
        }

        if userIsFavourite {
            return favourite.id == home.id
                ? "You are \(points) better on paper, and you are at home."
                : "You are \(points) better on paper — on the road, which takes some of it back."
        }
        return underdog.id == home.id
            ? "\(favourite.name) are \(points) better on paper. Home field is the argument against them."
            : "\(favourite.name) are \(points) better on paper, and you are travelling."
    }
}
