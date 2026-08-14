import Foundation

/// The game's own vocabulary, defined in one place. `04` §7.3.
///
/// `docs/briefs/2026-08-12-density-model.md` records that the reference product needed an in-game
/// glossary and calls that "the failure bound made visible": a dense game teaches a vocabulary, and
/// a player in season nine still meets a word they have not seen. This product ships 62 dense screen
/// families and had nowhere to look one up — onboarding (D9) teaches the first week, not the
/// vocabulary afterwards.
///
/// **Definitions, not documentation.** Each one is a sentence a player can read while deciding
/// something, in the plain register `04` requires. A paragraph here would be a manual, and nobody
/// reads a manual mid-decision.
public struct GlossaryTerm: Sendable, Equatable, Identifiable {
    public var id: String { term }
    public let term: String
    public let definition: String
    /// Where a reader most likely met it, so the glossary can be entered from a screen.
    public let area: GlossaryArea

    public init(term: String, definition: String, area: GlossaryArea) {
        self.term = term
        self.definition = definition
        self.area = area
    }
}

public enum GlossaryArea: String, Sendable, CaseIterable {
    case match
    case roster
    case college
    case professional
    case career
}

public enum Glossary {
    /// The longest a definition may be. A sentence, not a paragraph — and a bound rather than a
    /// habit, because the difference is what a contract test can hold.
    public static let maximumDefinitionCharacters = 160

    public static let terms: [GlossaryTerm] = [
        GlossaryTerm(
            term: "Call-in",
            definition: "A moment in the match where your coordinator stops and asks you. Taking "
                + "their recommendation is a real answer, not a skipped one.",
            area: .match
        ),
        GlossaryTerm(
            term: "Game plan",
            definition: "The lean you set before kickoff: run or pass, tempo, and how hard your "
                + "defence comes. Your coordinator calls plays inside it.",
            area: .match
        ),
        GlossaryTerm(
            term: "Scheme fit",
            definition: "How well a player suits the scheme you run. It moves every matchup they "
                + "are in, so a roster that fits punches above its ratings.",
            area: .roster
        ),
        GlossaryTerm(
            term: "Conversion",
            definition: "The try after a touchdown: kick it for one, or go for two from the two. "
                + "The chart says go for two when one point would not change the game.",
            area: .match
        ),
        GlossaryTerm(
            term: "Overtime",
            definition: "College teams alternate possessions from the 25 until one leads after "
                + "both have had the ball. The pro game plays a timed period.",
            area: .match
        ),
        GlossaryTerm(
            term: "Potential",
            definition: "How good a player could become. You never see it exactly — only an "
                + "estimate that narrows as your staff work with them.",
            area: .roster
        ),
        GlossaryTerm(
            term: "Development trait",
            definition: "A behaviour with mechanical bite: a workhorse improves faster in practice, "
                + "an ironman misses fewer weeks, a volatile player draws more flags.",
            area: .roster
        ),
        GlossaryTerm(
            term: "Depth chart",
            definition: "Who plays, in order, at each position. Anyone unavailable drops to the "
                + "bottom rather than disappearing, so you can see who you are missing.",
            area: .roster
        ),
        GlossaryTerm(
            term: "Redshirt",
            definition: "Holding a player out of most of a season so it does not count against "
                + "their eligibility. Four appearances or fewer keeps the year.",
            area: .college
        ),
        GlossaryTerm(
            term: "Eligibility",
            definition: "Four seasons of competition inside a five-year clock. The redshirt year is "
                + "the difference between them.",
            area: .college
        ),
        GlossaryTerm(
            term: "The portal",
            definition: "Two windows a year where players can leave for another programme, or "
                + "arrive from one. You decide who is worth keeping.",
            area: .college
        ),
        GlossaryTerm(
            term: "NIL",
            definition: "A scarce pot you allocate across your roster and your recruits. Getting it "
                + "wrong loses players to the portal.",
            area: .college
        ),
        GlossaryTerm(
            term: "Scholarship",
            definition: "One of 85. A recruit you sign spends one, and a commitment reserves one "
                + "before they have signed anything.",
            area: .college
        ),
        GlossaryTerm(
            term: "Walk-on",
            definition: "A player on no scholarship. Cheaper, and rated lower than the recruits you "
                + "sign, but they fill a roster.",
            area: .college
        ),
        GlossaryTerm(
            term: "Contact budget",
            definition: "The hours you spend on recruits each week. Visits cost more than calls, "
                + "and the pot resets on Monday.",
            area: .college
        ),
        GlossaryTerm(
            term: "Salary cap",
            definition: "The most a professional roster may cost. You must be legal by the "
                + "compliance date, and releasing a player does not release all of their money.",
            area: .professional
        ),
        GlossaryTerm(
            term: "Dead money",
            definition: "Signing-bonus money still on your books for a player you have released. "
                + "It is why cutting somebody is rarely free.",
            area: .professional
        ),
        GlossaryTerm(
            term: "Practice squad",
            definition: "Sixteen players outside the active roster who can be promoted. Somebody "
                + "else can sign them away.",
            area: .professional
        ),
        GlossaryTerm(
            term: "Waivers",
            definition: "A released player other clubs may claim before they reach free agency. "
                + "Claims resolve on a deadline, not instantly.",
            area: .professional
        ),
        GlossaryTerm(
            term: "Prestige",
            definition: "How your programme is seen. It moves a point a season toward where your "
                + "results put you, and it decides who takes your call.",
            area: .career
        ),
        GlossaryTerm(
            term: "Expectation",
            definition: "What your athletic director thinks this season should look like. Job "
                + "security moves against this, not against your raw record.",
            area: .career
        ),
        GlossaryTerm(
            term: "Job security",
            definition: "How safe you are, updated every week. Overperforming a bad job is worth "
                + "more than underperforming a good one.",
            area: .career
        ),
        GlossaryTerm(
            term: "Reputation",
            definition: "What follows you between jobs: results against expectation, titles, and "
                + "who you developed. It is what earns a professional job.",
            area: .career
        ),
    ]

    /// Terms for one area, alphabetically — the order a reader scanning for a word expects.
    public static func terms(in area: GlossaryArea) -> [GlossaryTerm] {
        terms.filter { $0.area == area }.sorted { $0.term < $1.term }
    }

    public static func definition(of term: String) -> String? {
        terms.first { $0.term.caseInsensitiveCompare(term) == .orderedSame }?.definition
    }
}
