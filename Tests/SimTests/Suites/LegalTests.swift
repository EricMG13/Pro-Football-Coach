import Foundation
import FootballSimCore

// The two Tier A tests from CLAUDE.md's legal guardrail, at the thresholds 02 section 11.3.5 fixes.
//
// These are the only two limbs of the guardrail that are tests. Everything else in it is a review
// checklist item, and CLAUDE.md says so explicitly: "Do not describe prose as if it were a test."
//
// docs/PORT-LOG.md records what these exist to catch, in shipped code: a colleges array commented
// "Fictional alma maters" holding six real institutions, under a file header asserting that no real
// player was referenced. The lesson it draws is the design of these tests:
//
//   "The collision test enumerates the generated output, not the source arrays. Reading a list and
//    judging it fictional is what produced both failures."

/// `02` §11.3.5. One sweep serves both these tests and D6's falsifier.
let LEGAL_SWEEP_LEAGUES = 200

/// The seed for sweep league `index`.
///
/// This was `UInt64(index) &* 0x9E37_79B9_7F4A_7C15` — SplitMix64's own gamma, the exact constant
/// `SeededRandom.next()` adds to its state. So league *i*'s stream was league 0's stream shifted
/// forward by *i* draws, and the sweep was one stream read at 200 offsets. Measured: 795 distinct
/// colour pairs across 33,200 identities instead of 33,200, with leagues 6 through 200 contributing
/// 408 new pairs between them. **The trade-dress sweep was worth about five independent leagues**,
/// and unlike the collision test it has no by-construction limb behind it — the sweep *is* the
/// trade-dress test.
///
/// Running the index through one round of SplitMix64 decorrelates it: verified at 33,200 distinct
/// pairs, matching an independent-FNV baseline. The docstring that used to sit here claimed exactly
/// the property the constant destroyed.
func sweepSeed(_ index: Int) -> UInt64 {
    var generator = SeededRandom(seed: UInt64(index))
    return generator.next()
}

/// The swept worlds, generated once.
///
/// Three tests here plus IdentityDistributionTests all want the same 200 leagues, and generating
/// them per test made the suite four times slower for no extra coverage. Computed lazily so a run
/// that skips these suites does not pay for them.
let sweptWorlds: [GeneratedWorld] = (0..<LEGAL_SWEEP_LEAGUES).map {
    LeagueGenerator.generate(seed: sweepSeed($0))
}

/// The one file exempt from the shipped-copy scan, because it *is* the list of real names.
let blocklistSourcePath = "Generation/Blocklist.swift"

/// Every string literal in `text`, comments discarded.
///
/// The inverse of ContractTests' scanner, which keeps the code and blanks the literals to look for
/// forbidden calls. This one keeps the literals and throws the code away, because the guardrail is
/// about the strings the app shows a player.
///
/// Two deliberate limits, both safe in the direction that matters. An interpolation segment is kept
/// as its raw source text, so `"#\(model.number)"` is swept as `#model.number)` — identifier words,
/// which cannot spell a real programme. And a nested block comment ends at its first `*/`, leaving
/// the rest to be read as code; that can only add literals to the sweep, never hide one.
///
/// The one limit that is *not* safe: a raw string literal (`#"..."#`) would have its backslashes
/// read as escapes, and a swallowed closing quote hides every literal after it in that file. No
/// source file uses one today. There is no assertion against it because the opener `#"` is
/// indistinguishable by substring from an ordinary literal holding a `#`, which `RosterView` has.
func stringLiterals(in text: String) -> [String] {
    enum Mode { case code, lineComment, blockComment, literal, multilineLiteral }
    let characters = Array(text)
    var literals: [String] = []
    var current = ""
    var mode = Mode.code
    var index = 0

    func lookahead(_ offset: Int) -> Character? {
        let position = index + offset
        return position < characters.count ? characters[position] : nil
    }
    func opensMultiline() -> Bool {
        lookahead(0) == "\"" && lookahead(1) == "\"" && lookahead(2) == "\""
    }

    while index < characters.count {
        let character = characters[index]
        switch mode {
        case .code:
            if character == "/", lookahead(1) == "/" {
                mode = .lineComment
                index += 2
                continue
            }
            if character == "/", lookahead(1) == "*" {
                mode = .blockComment
                index += 2
                continue
            }
            if opensMultiline() { mode = .multilineLiteral; current = ""; index += 3; continue }
            if character == "\"" { mode = .literal; current = ""; index += 1; continue }
        case .lineComment:
            if character == "\n" { mode = .code }
        case .blockComment:
            if character == "*", lookahead(1) == "/" {
                mode = .code
                index += 2
                continue
            }
        case .literal:
            if character == "\\" { index += 2; continue }
            if character == "\"" { literals.append(current); mode = .code; index += 1; continue }
            current.append(character)
        case .multilineLiteral:
            if character == "\\" { index += 2; continue }
            if opensMultiline() {
                literals.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                mode = .code
                index += 3
                continue
            }
            current.append(character)
        }
        index += 1
    }
    return literals
}

func runLegalTests() {
    suite("Legal: name collision") {
        test("no generated institution name in any of the swept leagues is a real one") {
            var offenders: [String] = []
            for (index, world) in sweptWorlds.enumerated() {
                for name in world.everyGeneratedInstitutionName where Blocklist.blocks(name) {
                    offenders.append("seed \(index): \(name)")
                }
            }
            expect(offenders.isEmpty,
                   "generated institution names collide with real ones: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("no place a member can be sited in heads a blocked institution name") {
            // A public name begins with its city, so a city that is also a real programme is a
            // blocked school name the moment a member is put there. Enumerated over the whole
            // pool rather than over swept worlds: 570 places against 166 members means a sample
            // of 200 leagues leaves most of the list untouched, and the one it misses ships.
            var offenders: [String] = []
            for place in NameGrammar.everyPlace {
                let city = NameGrammar.cityWithoutState(place)
                if Blocklist.blocks(city) { offenders.append(place) }
            }
            expect(offenders.isEmpty,
                   "\(offenders.count) places are blocked as institution names: "
                       + offenders.prefix(5).joined(separator: ", "))
        }

        test("no generated place name is a real venue mark or a real person") {
            var offenders: [String] = []
            for (index, world) in sweptWorlds.enumerated() {
                for name in world.everyGeneratedPlaceName where Blocklist.blocksPlaceName(name) {
                    offenders.append("seed \(index): \(name)")
                }
            }
            expect(offenders.isEmpty,
                   "generated place names collide with a mark or a person: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("the place boundary is exactly the names that are both a city and a programme") {
            // Derived from the two lists rather than transcribed, so the count CLAUDE.md and STATUS
            // quote cannot drift away from the lists they describe. Transcribing it by hand gave six,
            // then seven; it is eight. Kansas City is the one both hand counts missed, because it is
            // refused for containing the institution word "Kansas" rather than for being a listed
            // institution itself — which is a thing exact-string comparison cannot see and the word
            // sequence matcher can.
            let dualUse = Blocklist.realCities.filter(Blocklist.blocks).sorted()
            expectEqual(
                dualUse,
                ["Buffalo", "Cincinnati", "Houston", "Kansas City", "Miami", "Pittsburgh", "Tulsa",
                 "Washington"],
                "the set of names that are both a real city and a real programme has moved, so "
                    + "CLAUDE.md's guardrail and STATUS's decision entry are now out of date"
            )
            for city in Blocklist.realCities {
                expect(!Blocklist.blocksPlaceName(city),
                       "\(city) is a real city, and real cities are permitted as places")
            }
        }

        test("a real city is allowed as a place and refused as an institution") {
            // The owner's decision of 2026-08-12, as an assertion rather than a comment. Real
            // location names are permitted, so a city called Columbus is fine. The school is not
            // the real school, so Ohio State is still refused, and the six names that are both a
            // real city and a real programme - Buffalo, Cincinnati, Houston, Miami, Pittsburgh,
            // Tulsa - are refused as a programme name and allowed as the city it plays in.
            for city in ["Columbus", "Nashville", "Baltimore", "Green Bay", "Houston", "Miami"] {
                expect(!Blocklist.blocksPlaceName(city),
                       "\(city) is a real place and real places are permitted")
            }
            for institution in ["Houston", "Miami", "Buffalo", "Cincinnati", "Pittsburgh", "Tulsa"] {
                expect(Blocklist.blocks(institution),
                       "\(institution) is a real programme as well as a real city")
            }
            expect(Blocklist.blocks("Ohio State"))
            expect(!Blocklist.blocks("Columbus Technical"),
                   "a fictional school in a real city is the point of the decision")
            for mark in ["Rose Bowl", "Death Valley", "Lambeau", "Nick Saban"] {
                expect(Blocklist.blocksPlaceName(mark),
                       "\(mark) is a mark or a person, not a location")
            }
        }

        test("generated places and bowl titles use generic naming") {
            var rng = SeededRandom(seed: 20_260_820)
            let places = NameGrammar.distinctPlaceNames(using: &rng)
            expectEqual(places.count, 570)
            expect(places.allSatisfy { $0.contains(", ") },
                   "a generated place is missing its state qualification")
            let bowls = places.prefix(32).map {
                NameGrammar.bowlName(place: $0, using: &rng)
            }
            expect(bowls.allSatisfy { !Blocklist.blocks($0) },
                   "a generic bowl title collided with the protected-name screen")
        }

        test("the sweep actually looks at every kind of generated name") {
            // The guard against the sweep passing because it swept nothing. Named kinds rather
            // than a count, because "there were some strings" would still be satisfied by a world
            // that generated no nicknames at all.
            let world = LeagueGenerator.generate(seed: 7)
            let names = world.everyGeneratedName
            expect(names.count > CollegeRules.programmeCount,
                   "only \(names.count) names swept, which cannot cover 134 programmes")
            for name in [world.programmes[0].name, world.programmes[0].nickname,
                         world.proTeams[0].nickname, world.league.conferences[0].name] {
                expect(world.everyGeneratedInstitutionName.contains(name),
                       "\(name) is an institution name and is not swept as one")
            }
            for name in [world.programmes[0].cityName, world.map.regions[0].name] {
                expect(world.everyGeneratedPlaceName.contains(name),
                       "\(name) is a place name and is not swept as one")
            }
            let identity = world.identities[world.programmes[0].id]!
            expect(world.everyGeneratedInstitutionName.contains(identity.venueName),
                   "a venue name is generated but not swept as an institution name")
            expect(world.everyGeneratedInstitutionName.contains(identity.traditions[0].name),
                   "a tradition name is generated but not swept as an institution name")
            // Neither kind may quietly drop a name: the split has to partition the sweep, not
            // sample it.
            expectEqual(
                Set(names),
                Set(world.everyGeneratedInstitutionName).union(world.everyGeneratedPlaceName),
                "a generated name belongs to neither kind, so nothing checks it"
            )
        }

        test("the collision test catches a planted real name") {
            // A scan that has never failed is not known to be a scan. These are the exact strings
            // that shipped in the prior build's "fictional alma maters" list.
            for planted in ["Delta State", "Pine Bluff", "Western Reserve", "Old Dominion",
                            "Ohio State", "Crimson Tide", "Nick Saban"] {
                expect(Blocklist.blocks(planted), "\(planted) is real and was not blocked")
            }
        }

        test("blocking survives spacing, case and punctuation") {
            // A blocklist compared without normalising is theatre: "Ohio State", "ohio state" and
            // "Ohio-State" are three strings and one entry.
            for spelling in ["ohio state", "OHIO STATE", "Ohio-State", "OhioState", " Ohio  State "] {
                expect(Blocklist.blocks(spelling), "\(spelling) evaded the blocklist")
            }
        }

        test("a real name hidden inside a longer one is still blocked, including multi-word ones") {
            // The previous version of this test was titled for this case and could not see it. Both
            // its examples — "Clemson Valley", "North Alabama Technical" — hit on a single word, so
            // deleting the multi-word capability entirely left it green.
            //
            // The decisive case is the one PORT-LOG.md names: "Old Dominion Tech" is one of the six
            // real institutions the prior build shipped under a comment reading "Fictional alma
            // maters", and blocks() returned false for it while returning true for the bare
            // "Old Dominion" this test used to plant.
            // "Coastal Green Bay" was here and moved out on 2026-08-12: Green Bay is a city, real
            // location names are permitted, and a school in a real city is the point of the owner's
            // decision. "Coastal Boston College" replaces it and keeps the multi-word case, because
            // a school named after a real school is still refused.
            for planted in ["Clemson Valley", "North Alabama Technical",
                            "Old Dominion Tech", "Delta State Tech",
                            "Ohio State Technical", "North Notre Dame", "Upper Boise State",
                            "The Ohio State University", "Nick Saban Field",
                            "Coastal Boston College", "Kyle Field Stadium"] {
                expect(Blocklist.blocks(planted), "\(planted) contains a real name and was not blocked")
            }
        }

        test("every blocklist entry is still blocked with a word attached at either end") {
            // By construction over the whole list rather than over remembered examples. 114 of the
            // entries are multi-word, and every one of them was invisible the moment a word was
            // attached.
            var offenders: [String] = []
            for entry in Blocklist.entries.map({ $0.joined(separator: " ") }) {
                if !Blocklist.blocks(entry + " Technical") { offenders.append("\(entry) + suffix") }
                if !Blocklist.blocks("North " + entry) { offenders.append("prefix + \(entry)") }
            }
            expect(offenders.isEmpty,
                   "these entries stop being blocked once a word is attached: "
                       + offenders.prefix(8).joined(separator: ", "))
        }

        test("no word any generator can emit is itself a blocked name") {
            // By construction, and stronger than the sweep above, which is a sample. CLAUDE.md's
            // guardrail says no generated name matches a real one "at any seed" — that is a claim
            // about the reachable set, and only exhaustion proves it.
            //
            // The first version of this test read one file's pools and missed 505 of the 638
            // reachable words, including all 464 surnames, which reach a stadium name. It also
            // listed surname stems and endings separately while the generator concatenates them
            // into one word, and the concatenation is the unit Blocklist splits on.
            let words = GenerationVocabulary.everyEmittableWord
            expect(words.count > 600,
                   "only \(words.count) emittable words — a pool is not contributing")
            let offenders = words
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .filter { Blocklist.blocks($0) }
            expect(offenders.isEmpty,
                   "these generator words are real names: "
                       + Array(Set(offenders)).sorted().joined(separator: ", "))
        }

        test("the vocabulary covers the words the sweep actually produced") {
            // The guard on the guard. GenerationVocabulary is contributed to by hand, one pool per
            // type, so a phase that adds a pool and forgets is the remaining hole. This closes it
            // from the other side: every word the generator was observed emitting must be in the
            // declared vocabulary, or the vocabulary is out of date.
            let declared = Set(GenerationVocabulary.everyEmittableWord.map(Blocklist.normalised))
            var missing: Set<String> = []
            for world in sweptWorlds.prefix(25) {
                for name in world.everyGeneratedName {
                    for word in name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                        let normalised = Blocklist.normalised(String(word))
                        if !normalised.isEmpty, !declared.contains(normalised) {
                            missing.insert(String(word))
                        }
                    }
                }
            }
            expect(missing.isEmpty,
                   "the generator emitted words the vocabulary does not declare, so the "
                       + "by-construction legal check does not cover them: "
                       + missing.sorted().prefix(12).joined(separator: ", "))
        }

        test("the morpheme check would catch a planted real word") {
            // The self-test for the test above: if Blocklist.blocks returned false for everything,
            // the assertion would pass vacuously over a clean-looking pool.
            expect(Blocklist.blocks("Crimson"),
                   "the exact word the sweep caught is not blocked, so the morpheme check is inert")
            expect(Blocklist.blocks("Buckeyes"), "a single-word real nickname is not blocked")
        }

        test("an invented name is not blocked, so the test can pass at all") {
            // The other direction. A blocklist that matched everything would make the sweep above
            // meaningless in the way that always-failing gates are meaningless.
            for invented in ["Thornby Ridge", "Ashen Falls Polytechnic", "Iron Kestrels"] {
                expect(!Blocklist.blocks(invented), "\(invented) is invented and was blocked")
            }
        }
    }

    suite("Legal: shipped copy") {
        // The generated-name sweep covers what the generator emits. It cannot see a real name typed
        // straight into a source file, and that is the exact failure this file's header records:
        // "Reading a list and judging it fictional is what produced both failures." The DEBUG screen
        // fixtures were read and judged fictional, and shipped three cities off the blocklist below.
        //
        // Enumerated by walking Sources, not by naming the fixture files, so a screen added tomorrow
        // is swept the day it is added rather than the day someone remembers it.
        //
        // This uses the institution-kind check, because a literal has no kind: the scanner sees a
        // string, not whether it is a hometown or a team name. That is the safe direction — it still
        // catches a real school typed into source, which is what the sweep exists for — at the cost
        // of refusing the eight dual-use names in hand-written copy. If a fixture wants a player
        // from Miami or Kansas City, that is the message it will get, and the fix is to use the
        // read model's typed place field rather than to weaken this to the place-kind check.
        test("no string literal anywhere in Sources is a real name") {
            var offenders: [String] = []
            for file in swiftFiles(under: "Sources") where !file.path.hasSuffix(blocklistSourcePath) {
                for literal in stringLiterals(in: file.text) where Blocklist.blocks(literal) {
                    offenders.append("\(file.path): \(literal)")
                }
            }
            expect(offenders.isEmpty,
                   "shipped copy collides with real names: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("the scan reads literals, ignores comments, and catches a planted real name") {
            // The self-test the other scans in this repository ship: a scan that has never failed is
            // not known to be a scan. Comments are excluded deliberately — canon cites real
            // programmes by name to say what must never be generated.
            let planted = """
            // Ohio State named in a comment is not shipped copy
            let team = "Carson Tech"
            /* Michigan */
            let rival = "Notre Dame"
            """
            let found = stringLiterals(in: planted)
            expectEqual(found, ["Carson Tech", "Notre Dame"])
            expect(found.filter(Blocklist.blocks) == ["Notre Dame"],
                   "the planted real programme was not the one and only literal caught")
        }

        test("the scan reaches the fixtures that carry player-facing copy") {
            // The guard against the sweep passing because it swept nothing.
            let fixtures = swiftFiles(under: "Sources/ProFootballCoachUI")
                .filter { $0.text.contains("CoachWorldSampleData") }
            expect(!fixtures.isEmpty, "no sample-fixture file was scanned")
            let literals = fixtures.flatMap { stringLiterals(in: $0.text) }
            expect(literals.contains("Carson Tech"),
                   "the scan did not reach the fixture team name")
        }
    }

    suite("Legal: trade dress") {
        test("no generated colour pair in any swept league sits within delta E of a real pair") {
            var offenders: [String] = []
            for (index, world) in sweptWorlds.enumerated() {
                for (_, identity) in world.identities
                where ColourGenerator.collidesWithTradeDress(identity.colours.primary,
                                                             identity.colours.secondary) {
                    offenders.append("seed \(index): \(identity.colours.primary.hex)/"
                        + identity.colours.secondary.hex)
                }
            }
            expect(offenders.isEmpty,
                   "generated pairs sit inside a real programme's trade dress: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("the trade-dress test catches a planted real pair") {
            let real = Blocklist.tradeDress[0]
            expect(ColourGenerator.collidesWithTradeDress(real.primary, real.secondary),
                   "an exact copy of a real pair was not caught")
            // And a near copy, which is the case a hex-equality check would miss entirely.
            let nudged = Colour(red: real.primary.red + 4,
                                green: real.primary.green + 4,
                                blue: real.primary.blue + 4)
            expect(ColourGenerator.collidesWithTradeDress(nudged, real.secondary),
                   "a nudged copy of a real pair was not caught")
        }

        test("a swapped real pair is still a real pair") {
            let real = Blocklist.tradeDress[0]
            expect(ColourGenerator.collidesWithTradeDress(real.secondary, real.primary),
                   "swapping primary and secondary evaded the trade-dress test")
        }

        test("sharing one colour with a real pair is not trade dress") {
            // The threshold has to allow this or the generator has nothing to work with: half the
            // sport wears navy, and a rule that rejected navy would reject most of colour space.
            let real = Blocklist.tradeDress[0]
            let unrelated = Colour(hex: "2E8B57")
            expect(!ColourGenerator.collidesWithTradeDress(real.primary, unrelated),
                   "one shared colour was treated as trade dress")
        }

        test("every generated pair carries legible text") {
            // 04 section 2.1 requires the contrast contract to hold AT GENERATION TIME. This is the
            // structural fix for the prior build's whole "white on the team gradient" class: a pair
            // that cannot carry text is never constructed, so no call site has to remember.
            var worstText = Double.infinity
            var worstSecondary = Double.infinity
            for world in sweptWorlds {
                for (_, identity) in world.identities {
                    worstText = Swift.min(worstText, identity.colours.textContrast)
                    worstSecondary = Swift.min(worstSecondary, identity.colours.secondaryContrast)
                }
            }
            expect(worstText >= ColourGenerator.textContrastFloor,
                   "the worst generated pair carries text at \(worstText):1, under the "
                       + "\(ColourGenerator.textContrastFloor):1 floor")
            expect(worstSecondary >= ColourGenerator.secondaryContrastFloor,
                   "the worst generated secondary reads at \(worstSecondary):1 on its primary, "
                       + "under the \(ColourGenerator.secondaryContrastFloor):1 floor")
        }

        test("every fallback pair passes both tests, so the escape hatch is not the hole") {
            // ColourGenerator falls back after a bounded number of retries. A fallback that had not
            // been checked would be a way for an unchecked pair to reach a surface precisely when
            // the constraints were hardest to satisfy.
            for index in 0..<ColourGenerator.fallbackCount {
                let pair = ColourGenerator.fallback(index)
                expect(!ColourGenerator.collidesWithTradeDress(pair.primary, pair.secondary),
                       "fallback \(index) collides with real trade dress")
                expect(ColourGenerator.satisfiesContrastContract(pair),
                       "fallback \(index) carries text at \(pair.textContrast):1 and shows its "
                           + "secondary at \(pair.secondaryContrast):1")
                expect(!Blocklist.tradeDress.contains { $0.primary == pair.primary
                           && $0.secondary == pair.secondary },
                       "fallback \(index) is an exact real pair")
            }
        }
    }
}
