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

/// The seed for sweep league `index`. Multiplied by an odd constant so consecutive indices are not
/// consecutive seeds — a sweep over 0, 1, 2 exercises neighbouring RNG streams rather than
/// independent ones, which is a weaker test than it looks.
func sweepSeed(_ index: Int) -> UInt64 { UInt64(index) &* 0x9E37_79B9_7F4A_7C15 }

/// The swept worlds, generated once.
///
/// Three tests here plus IdentityDistributionTests all want the same 200 leagues, and generating
/// them per test made the suite four times slower for no extra coverage. Computed lazily so a run
/// that skips these suites does not pay for them.
let sweptWorlds: [GeneratedWorld] = (0..<LEGAL_SWEEP_LEAGUES).map {
    LeagueGenerator.generate(seed: sweepSeed($0))
}

func runLegalTests() {
    suite("Legal: name collision") {
        test("no generated name in any of the swept leagues is a real name") {
            var offenders: [String] = []
            for (index, world) in sweptWorlds.enumerated() {
                for name in world.everyGeneratedName where Blocklist.blocks(name) {
                    offenders.append("seed \(index): \(name)")
                }
            }
            expect(offenders.isEmpty,
                   "generated names collide with real ones: "
                       + offenders.prefix(10).joined(separator: ", "))
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
                         world.programmes[0].cityName, world.proTeams[0].nickname,
                         world.map.regions[0].name, world.league.conferences[0].name] {
                expect(names.contains(name), "\(name) is generated but not swept")
            }
            let identity = world.identities[world.programmes[0].id]!
            expect(names.contains(identity.venueName), "a venue name is generated but not swept")
            expect(names.contains(identity.traditions[0].name),
                   "a tradition name is generated but not swept")
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

        test("a real name hidden inside a longer one is still blocked") {
            // "Clemson Valley" is not saved by the extra word, and a generator that concatenates is
            // exactly how one would appear.
            expect(Blocklist.blocks("Clemson Valley"), "an embedded real name was not blocked")
            expect(Blocklist.blocks("North Alabama Technical"), "an embedded institution was missed")
        }

        test("no morpheme the grammar can emit is itself a blocked name") {
            // By construction, and stronger than the sweep above. A generated name is a
            // concatenation of these, so a blocked word anywhere in a pool is a collision waiting
            // for the right seed — and 200 leagues is a sample, not a proof. "Crimson" sat in the
            // nickname adjectives until the sweep happened to surface it; a rarer word might not
            // have appeared at all.
            let offenders = NameGrammar.allMorphemes
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .filter { Blocklist.blocks($0) }
            expect(offenders.isEmpty,
                   "these grammar morphemes are real names: " + offenders.joined(separator: ", "))
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
