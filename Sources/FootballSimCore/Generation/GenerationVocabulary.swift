import Foundation

/// Every word any generator in this module can put into a name that reaches a surface.
///
/// **Why this exists.** `CLAUDE.md`'s guardrail says no generated name matches a real one "at any
/// seed". "At any seed" is a claim about the *reachable set*, and only exhaustion proves it — a
/// 200-league sweep is a sample. An adversarial review measured the gap: the sweep reached 427 of
/// the 638 reachable words, and the 211 it missed were all surnames, which reach a real surface as
/// the donor half of a stadium name. Nothing evaluated them.
///
/// **Why it is here and not in the test.** Each pool is contributed by the type that draws from it,
/// so the vocabulary cannot fall out of step with the generator the way a list in a test file
/// would. A phase that adds a pool and forgets to contribute it is the one remaining hole, and it
/// is a visible omission in a module rather than an invisible one in a suite.
///
/// The whole space enumerates in a fraction of a second, so `LegalTests` checks all of it rather
/// than sampling it. That buys nothing against today's blocklist and everything against tomorrow's:
/// the blocklist is refreshed per release (`docs/PRE-DEPLOYMENT-CHECKLIST.md`), and a refresh is
/// exactly the event that turns a rare pool word into a collision.
public enum GenerationVocabulary {
    public static var everyEmittableWord: [String] {
        NameGrammar.emittableWords
            + GameMap.emittableWords
            + TraditionGrammar.emittableWords
    }
}
