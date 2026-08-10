import Foundation
import FootballSimCore

func runGenerationTests() {
    suite("Colour maths") {
        test("Lab conversion matches known reference values") {
            // Pinned against published sRGB-to-Lab conversions rather than against itself. A
            // round-trip test would pass just as happily with the matrix transposed.
            let (whiteL, whiteA, whiteB) = Colour.white.lab
            expectClose(whiteL, 100.0, 0.2, "white L")
            expectClose(whiteA, 0.0, 0.2, "white a")
            expectClose(whiteB, 0.0, 0.2, "white b")

            let (blackL, _, _) = Colour.black.lab
            expectClose(blackL, 0.0, 0.2, "black L")

            let (redL, redA, redB) = Colour(hex: "FF0000").lab
            expectClose(redL, 53.24, 0.5, "red L")
            expectClose(redA, 80.09, 0.5, "red a")
            expectClose(redB, 67.20, 0.5, "red b")

            let (blueL, blueA, blueB) = Colour(hex: "0000FF").lab
            expectClose(blueL, 32.30, 0.5, "blue L")
            expectClose(blueA, 79.19, 0.5, "blue a")
            expectClose(blueB, -107.86, 0.5, "blue b")
        }

        test("delta E is zero to itself, symmetric, and large across the gamut") {
            let a = Colour(hex: "123456"), b = Colour(hex: "FEDCBA")
            expectClose(a.deltaE(to: a), 0, 0.000_001, "a colour is not identical to itself")
            expectClose(a.deltaE(to: b), b.deltaE(to: a), 0.000_001, "delta E is not symmetric")
            expect(Colour.white.deltaE(to: .black) > 99, "white and black are not far apart")
        }

        test("contrast ratio matches the WCAG worked examples") {
            expectClose(Colour.white.contrastRatio(against: .black), 21.0, 0.01)
            expectClose(Colour.white.contrastRatio(against: .white), 1.0, 0.001)
            // Order-independent, which is what the formula's max/min is for.
            expectClose(Colour.black.contrastRatio(against: .white), 21.0, 0.01)
            // A mid grey against white, from the WCAG worked set.
            expectClose(Colour(hex: "767676").contrastRatio(against: .white), 4.54, 0.05)
        }

        test("hex parsing round-trips and refuses to trap on rubbish") {
            expectEqual(Colour(hex: "1A2B3C").hex, "1A2B3C")
            expectEqual(Colour(hex: "#1A2B3C").hex, "1A2B3C")
            // The blocklist is hand-edited, so a malformed entry must be black rather than a crash.
            expectEqual(Colour(hex: "nonsense").hex, "000000")
            expectEqual(Colour(hex: "").hex, "000000")
            expectEqual(Colour(hex: "12345").hex, "000000")
        }

        test("channels clamp rather than wrapping") {
            expectEqual(Colour(red: 300, green: -20, blue: 128).hex, "FF0080")
        }

        test("HSL lands where it should at the corners") {
            expectEqual(Colour(hue: 0, saturation: 1, lightness: 0.5).hex, "FF0000")
            expectEqual(Colour(hue: 120, saturation: 1, lightness: 0.5).hex, "00FF00")
            expectEqual(Colour(hue: 240, saturation: 1, lightness: 0.5).hex, "0000FF")
            expectEqual(Colour(hue: 0, saturation: 0, lightness: 1).hex, "FFFFFF")
            expectEqual(Colour(hue: 0, saturation: 0, lightness: 0).hex, "000000")
        }
    }

    suite("Colour generation") {
        test("every generated pair satisfies both constraints") {
            var rng = SeededRandom(seed: 99)
            for index in 0..<2_000 {
                let pair = ColourGenerator.pair(using: &rng, fallbackIndex: index)
                expect(!ColourGenerator.collidesWithTradeDress(pair.primary, pair.secondary),
                       "pair \(index) collides with real trade dress")
                expect(ColourGenerator.satisfiesContrastContract(pair),
                       "pair \(index) fails the contrast contract at "
                           + "\(pair.textContrast)/\(pair.secondaryContrast)")
            }
        }

        test("the retry budget is not being exhausted at ordinary seeds") {
            // A generator that silently slid onto the fallback would look fine — the fallbacks pass
            // both tests — while producing eight colour schemes for a 134-programme league. The
            // symptom is duplicates, so that is what this measures.
            var rng = SeededRandom(seed: 4242)
            var pairs: [ColourPair] = []
            for index in 0..<500 {
                pairs.append(ColourGenerator.pair(using: &rng, fallbackIndex: index))
            }
            let fallbacks = (0..<ColourGenerator.fallbackCount).map { ColourGenerator.fallback($0) }
            let usedFallback = pairs.filter { pair in fallbacks.contains(pair) }.count
            expect(usedFallback == 0,
                   "\(usedFallback) of 500 pairs fell back, so the constraints are too tight for "
                       + "the retry budget")
            expect(Set(pairs.map(\.primary)).count > 400,
                   "only \(Set(pairs.map(\.primary)).count) distinct primaries in 500 draws")
        }

        test("the fallback index wraps in both directions rather than trapping") {
            expectEqual(ColourGenerator.fallback(0), ColourGenerator.fallback(ColourGenerator.fallbackCount))
            expectEqual(ColourGenerator.fallback(-1),
                        ColourGenerator.fallback(ColourGenerator.fallbackCount - 1))
        }

        test("generation is a pure function of the stream") {
            var a = SeededRandom(seed: 7), b = SeededRandom(seed: 7)
            for index in 0..<50 {
                expectEqual(ColourGenerator.pair(using: &a, fallbackIndex: index),
                            ColourGenerator.pair(using: &b, fallbackIndex: index))
            }
        }
    }

    suite("League generation") {
        let world = LeagueGenerator.generate(seed: 20_260_810)

        test("the same seed produces the same world") {
            expectEqual(LeagueGenerator.generate(seed: 20_260_810), world,
                        "generation is not reproducible from its seed")
        }

        test("a different seed produces a different world") {
            expect(LeagueGenerator.generate(seed: 20_260_811) != world,
                   "two seeds produced the same world, so the seed is not being read")
        }

        test("the world survives the save envelope byte-identically") {
            // The whole point of P0's envelope and P1's CodingKeyRepresentable work, exercised on
            // the largest structure the game has.
            let encoded = try SaveEnvelope.encode(world)
            expectEqual(try SaveEnvelope.encode(world), encoded, "encoding is not byte-stable")
            expectEqual(try SaveEnvelope.decode(GeneratedWorld.self, from: encoded), world)
        }

        test("the league holds exactly the members the rules require") {
            expectEqual(world.programmes.count, CollegeRules.programmeCount)
            expectEqual(world.proTeams.count, ProRules.teamCount)
            expectEqual(world.league.conferences(in: .college).count, CollegeRules.conferenceCount)
            expectEqual(world.league.conferences(in: .pro).count, ProRules.conferenceCount)
            expectEqual(world.league.divisions.count,
                        ProRules.conferenceCount * ProRules.divisionsPerConference)
        }

        test("every conference is inside its legal size and they sum to the league") {
            let college = world.league.conferences(in: .college)
            for conference in college {
                expect(CollegeRules.conferenceSizeRange.contains(conference.memberIDs.count),
                       "\(conference.name) holds \(conference.memberIDs.count) programmes")
            }
            expectEqual(college.reduce(0) { $0 + $1.memberIDs.count }, CollegeRules.programmeCount)
        }

        test("conference sizes vary between seeds rather than being an even split") {
            // 02 section 11.4 leaves composition to generation deliberately, so that every save's
            // map is not the same map. An even split would satisfy the size range and defeat the
            // point.
            var shapes: Set<[Int]> = []
            for seed in 0..<20 {
                var rng = SeededRandom(seed: UInt64(seed) &+ 1)
                shapes.insert(LeagueGenerator.collegeConferenceSizes(using: &rng))
            }
            expect(shapes.count > 10, "only \(shapes.count) distinct conference shapes in 20 seeds")
            for shape in shapes {
                expectEqual(shape.reduce(0, +), CollegeRules.programmeCount,
                            "a generated shape does not hold 134 programmes")
            }
        }

        test("every pro division holds four teams and every conference sixteen") {
            for division in world.league.divisions {
                expectEqual(division.memberIDs.count, ProRules.teamsPerDivision)
            }
            for conference in world.league.conferences(in: .pro) {
                expectEqual(conference.memberIDs.count,
                            ProRules.divisionsPerConference * ProRules.teamsPerDivision)
            }
        }

        test("every member has a distinct identity, city and set of ids") {
            expectEqual(world.identities.count, world.programmes.count + world.proTeams.count)
            let ids = world.programmes.map(\.id) + world.proTeams.map(\.id)
            expectEqual(Set(ids).count, ids.count, "two members share an id")
            let cities = world.identities.values.map(\.homeCityID)
            expectEqual(Set(cities).count, cities.count, "two members share a home city")
        }

        test("every member sits inside a conference that lists it back") {
            for programme in world.programmes {
                guard let conferenceID = programme.conferenceID,
                      let conference = world.league.conferences.first(where: { $0.id == conferenceID })
                else {
                    expect(false, "\(programme.name) has no conference")
                    continue
                }
                expect(conference.memberIDs.contains(programme.id),
                       "\(programme.name) names a conference that does not list it")
            }
        }

        test("every programme carries traditions, and each has a real effect") {
            // D6 clause 4: "A tradition the player cannot feel in the simulation is decoration."
            for programme in world.programmes {
                guard let identity = world.identities[programme.id] else {
                    expect(false, "\(programme.name) has no identity")
                    continue
                }
                expect(TraditionGrammar.perProgrammeRange.contains(identity.traditions.count),
                       "\(programme.name) has \(identity.traditions.count) traditions")
                for tradition in identity.traditions {
                    expect(tradition.effect.magnitude > 0,
                           "\(tradition.name) has an effect of zero, which is decoration")
                    expect(!tradition.blurb.isEmpty, "\(tradition.name) has no blurb")
                }
            }
        }

        test("a home-field tradition names a week that exists in its tier") {
            for programme in world.programmes {
                for tradition in world.identities[programme.id]?.traditions ?? [] {
                    if case let .homeFieldInWeek(week, _) = tradition.effect {
                        expect((1...CollegeRules.seasonWeeks).contains(week),
                               "\(tradition.name) fires in week \(week) of a 17-week season")
                    }
                }
            }
        }

        test("a recruiting tradition names a region that exists on the map") {
            let regionIDs = Set(world.map.regions.map(\.id))
            for programme in world.programmes {
                for tradition in world.identities[programme.id]?.traditions ?? [] {
                    if case let .recruitingInRegion(regionID, _) = tradition.effect {
                        expect(regionIDs.contains(regionID),
                               "\(tradition.name) boosts recruiting in a region that does not exist")
                    }
                }
            }
        }

        test("no programme carries more rivals than the bound") {
            for programme in world.programmes {
                expect(programme.rivalIDs.count <= SharedRules.rivalriesPerProgramme,
                       "\(programme.name) carries \(programme.rivalIDs.count) rivals")
                expect(!programme.rivalIDs.contains(programme.id),
                       "\(programme.name) is its own rival")
            }
        }

        test("every rivalry is within one tier and is stored once") {
            let programmeIDs = Set(world.programmes.map(\.id))
            let teamIDs = Set(world.proTeams.map(\.id))
            var keys: Set<String> = []
            for rivalry in world.rivalries {
                let bothCollege = programmeIDs.contains(rivalry.sideA)
                    && programmeIDs.contains(rivalry.sideB)
                let bothPro = teamIDs.contains(rivalry.sideA) && teamIDs.contains(rivalry.sideB)
                expect(bothCollege || bothPro,
                       "a rivalry crosses tiers, so it can never be added to")
                expect(rivalry.sideA != rivalry.sideB, "a member is its own rival")
                expect(rivalry.sideA.uuidString < rivalry.sideB.uuidString,
                       "a rivalry is not in canonical order, so it can exist twice")
                expect(keys.insert(rivalry.sideA.uuidString + rivalry.sideB.uuidString).inserted,
                       "the same rivalry is stored twice")
            }
        }

        test("every city is on the map and inside its bounds") {
            expectEqual(world.map.cities.count,
                        CollegeRules.programmeCount + ProRules.teamCount)
            let regionIDs = Set(world.map.regions.map(\.id))
            for city in world.map.cities {
                expect((0...GameMap.width).contains(city.x), "\(city.name) is off the map in x")
                expect((0...GameMap.height).contains(city.y), "\(city.name) is off the map in y")
                expect(regionIDs.contains(city.regionID), "\(city.name) is in no region")
            }
        }

        test("cities cluster by region rather than scattering uniformly") {
            // Geography is a mechanic (D6 clause 2), and a geography-seeded rivalry means nothing
            // on a map of uniformly scattered points. Members of a region must sit closer to each
            // other than to the map at large.
            var withinRegion = 0.0, withinCount = 0.0
            var acrossRegions = 0.0, acrossCount = 0.0
            for (indexA, cityA) in world.map.cities.enumerated() {
                for cityB in world.map.cities[(indexA + 1)...] {
                    let distance = Double(cityA.squaredDistance(to: cityB))
                    if cityA.regionID == cityB.regionID {
                        withinRegion += distance; withinCount += 1
                    } else {
                        acrossRegions += distance; acrossCount += 1
                    }
                }
            }
            let within = withinRegion / withinCount, across = acrossRegions / acrossCount
            expect(within < across / 2,
                   "mean within-region distance \(within) is not clearly under the "
                       + "across-region \(across), so the map does not cluster")
        }

        test("every archetype appears somewhere in a 134-programme league") {
            // An archetype that never generates is dead capability with a name.
            let used = Set(world.programmes.map(\.archetypeID))
            expectEqual(used.count, Archetype.all.count,
                        "only \(used.count) of \(Archetype.all.count) archetypes were used")
        }

        test("every programme's scheme is one its archetype leans toward") {
            for programme in world.programmes {
                let archetype = Archetype.with(id: programme.archetypeID)
                expect(archetype.offensiveLean.contains(programme.scheme.offense),
                       "\(programme.name) runs a scheme its archetype does not lean toward")
                expect(archetype.defensiveLean.contains(programme.scheme.defense),
                       "\(programme.name) plays a defence its archetype does not lean toward")
            }
        }

        test("prestige stays inside its archetype's stated band") {
            for programme in world.programmes {
                let archetype = Archetype.with(id: programme.archetypeID)
                expect((archetype.prestigeFloor...archetype.prestigeCeiling)
                    .contains(programme.prestige.value),
                       "\(programme.name) has prestige \(programme.prestige.value), outside "
                           + "\(archetype.name)'s band")
            }
        }

        test("archetype lookup wraps rather than trapping on a corrupt id") {
            expectEqual(Archetype.with(id: Archetype.all.count).id, 0)
            expectEqual(Archetype.with(id: -1).id, Archetype.all.count - 1)
        }
    }
}
