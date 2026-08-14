import Foundation

/// Reads what a programme's traditions actually do. `02` §8.1.
///
/// `TraditionGrammar` generated four kinds of effect and **nothing read any of them**, which made
/// every tradition in every world exactly the decoration D6 clause 4 forbids: "a tradition the
/// player cannot feel in the simulation is decoration". The type system was doing its job — a
/// tradition without an effect does not compile — and the consumption side simply did not exist.
///
/// *Recorded because an earlier note in this session got it wrong.* `docs/STATUS.md` and `02` §6
/// briefly said `Programme` does not persist traditions and that wiring them was a schema change.
/// They are persisted, in `GameState.identities`, and always were. The claim was checked against
/// the wrong type and is corrected here rather than quietly dropped, in the same way `02` §4.3
/// records the recruiting-budget mistake.
public enum TraditionEffects {
    /// Extra home-field advantage, in rating points, for a home team in a given week against a
    /// given opponent.
    ///
    /// Both home-field kinds add: a programme whose loudest week *is* the rivalry week gets both,
    /// which is exactly the game a generated tradition set is describing.
    public static func homeFieldBonus(
        home: UUID,
        against opponentID: UUID,
        week: Int,
        in state: GameState
    ) -> Int {
        let isRival = state.programmes[home]?.rivalIDs.contains(opponentID) ?? false
        return (state.identities[home]?.traditions ?? []).reduce(0) { total, tradition in
            switch tradition.effect {
            case let .homeFieldInWeek(traditionWeek, bonus):
                return total + (traditionWeek == week ? bonus : 0)
            case let .homeFieldAgainstRival(bonus):
                return total + (isRival ? bonus : 0)
            case .recruitingInRegion, .moraleAfterResult:
                return total
            }
        }
    }

    /// Extra recruiting interest for a prospect from a region the programme has a pipeline into.
    public static func recruitingBonus(
        programmeID: UUID,
        prospectRegionID: UUID,
        in state: GameState
    ) -> Int {
        (state.identities[programmeID]?.traditions ?? []).reduce(0) { total, tradition in
            guard case let .recruitingInRegion(regionID, bonus) = tradition.effect,
                  regionID == prospectRegionID else { return total }
            return total + bonus
        }
    }

    /// What a tradition adds to morale after a result, or takes away after the other one.
    ///
    /// `02` §8 says a tradition can carry "a morale effect after a specific outcome", and §5.1 is
    /// the first thing in the game with morale for it to move.
    public static func moraleDelta(
        programmeID: UUID,
        wonLastGame: Bool,
        in state: GameState
    ) -> Int {
        (state.identities[programmeID]?.traditions ?? []).reduce(0) { total, tradition in
            guard case let .moraleAfterResult(afterWin, delta) = tradition.effect else {
                return total
            }
            return total + (afterWin == wonLastGame ? delta : -delta)
        }
    }

    /// Whether this organisation's traditions do anything at all, for the assertion that generation
    /// produced usable ones rather than for a surface.
    public static func hasEffects(_ organisationID: UUID, in state: GameState) -> Bool {
        !(state.identities[organisationID]?.traditions ?? []).isEmpty
    }
}
