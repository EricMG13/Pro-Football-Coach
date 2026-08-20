import Foundation
import FootballSimCore

/// Pinned bytes of the canonical JSON body of `LeagueGenerator.generate(seed: 20260810)`.
///
/// It pinned `SaveEnvelope.encode(...)` until 2026-08-12, when the save body became zlib-compressed
/// and this dropped from 824,938 bytes to 155,631. That is compression, not a generation change —
/// and the body pin below now also records the intentional real-place naming policy.
/// but the pin could not tell the difference, and a pin that moves when the compression library
/// moves is a cross-process assertion about zlib rather than about generation. It now hashes the
/// JSON the generator produces, which is the thing it is actually asserting.
///
/// See "the encoded world matches a pinned digest" below for why these exist and when to change
/// them.
private let PINNED_WORLD_BYTES = 825_992
private let PINNED_WORLD_DIGEST: UInt64 = 11_787_211_303_845_325_426

/// FNV-1a over the bytes, order-sensitive.
///
/// Written here rather than reached for from the engine because `SeededRandom.fnv1a` is internal
/// and `SimTests` imports `FootballSimCore` without `@testable`. Order sensitivity is the whole
/// requirement — a sum or an XOR would be blind to exactly the reordering this pin exists to catch,
/// and the self-test below swaps two bytes to prove it is not.
private func checksum(_ data: Data) -> UInt64 {
    var value: UInt64 = 0xCBF2_9CE4_8422_2325
    for byte in data { value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
    return value
}

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

        test("public team names follow college and pro reference shapes") {
            let collegeDescriptors = [
                "University", "State University", "A&M University", "Technical University",
                "Polytechnic University", "Regional University", "Research University",
                "Agricultural University", "Institute of Technology", "Technical Institute",
                "Polytechnic Institute", "Regional Institute", "Research Institute",
                "Agricultural Institute", "Maritime Institute", "Maritime College",
                "Normal University", "Technical College", "Regional College", "City College",
                "State College"
            ]
            for programme in world.programmes {
                expect(programme.name.hasPrefix(programme.cityName + " "),
                       "college name lost its location: (programme.name)")
                expect(collegeDescriptors.contains { programme.name.hasSuffix($0) },
                       "college name lost its generic institution suffix: (programme.name)")
            }
            for team in world.proTeams {
                expectEqual(team.name, "\(team.cityName) \(team.nickname)",
                            "pro team name is not location plus nickname")
                expectEqual(team.displayName, team.name,
                            "new pro team did not expose its full public name")
            }
            var legacy = world.proTeams[0]
            legacy.name = legacy.cityName
            expectEqual(legacy.displayName, "\(legacy.cityName) \(legacy.nickname)",
                        "legacy market-only pro name did not get a compatibility display name")
            var observedSuffixes = Set<String>()
            for seed in 0..<64 {
                var probe = SeededRandom(seed: UInt64(seed))
                for _ in 0..<32 {
                    let name = NameGrammar.institutionName(place: "Probe, ZZ", using: &probe)
                    for suffix in ["University", "State University", "A&M University"]
                    where name.hasSuffix(suffix) {
                        observedSuffixes.insert(suffix)
                    }
                }
            }
            for suffix in ["University", "State University", "A&M University"] {
                expect(observedSuffixes.contains(suffix),
                       "the institution grammar never emits the common college suffix (suffix)")
            }
        }

        test("the world survives the save envelope byte-identically") {
            // The whole point of P0's envelope and P1's CodingKeyRepresentable work, exercised on
            // the largest structure the game has.
            let encoded = try SaveEnvelope.encode(world)
            expectEqual(try SaveEnvelope.encode(world), encoded, "encoding is not byte-stable")
            expectEqual(try SaveEnvelope.decode(GeneratedWorld.self, from: encoded), world)
        }

        test("the encoded world matches a pinned digest, which is the cross-process assertion") {
            // Repeat-encoding and round-tripping are both blind to this class, and ModelTests
            // documents why: Set and Dictionary iteration order is constant within one process, so
            // an ordering bug reproduces perfectly until the next launch. The suite had no coverage
            // of the process boundary at all, and the commit that claimed it cited stdout being
            // identical across three runs — which TestKit prints as a count and "all passed"
            // whether or not a single save byte moved.
            //
            // A literal in a source file cannot be salted per launch, so pinning the digest is the
            // cross-process assertion, exactly as P0's golden vectors are for seeding. It was
            // watched failing: planting a Set<UUID> of nine ids on TeamIdentity gave three
            // different digests on three consecutive runs of the same binary, while the whole suite
            // still printed "all passed".
            //
            // This digest changes whenever generation changes, and that is the point — a generation
            // change must be a deliberate edit here rather than a silent one. Regenerate only when
            // the change is intended.
            let encoded = try JSONEncoder.stable().encode(world)
            expectEqual(encoded.count, PINNED_WORLD_BYTES,
                        "the encoded world changed size, so generation changed")
            expectEqual(checksum(encoded), PINNED_WORLD_DIGEST,
                        "the encoded world's bytes changed. If generation was changed deliberately, "
                            + "re-pin. If not, something in the save is ordering by a per-launch "
                            + "hash and one seed now produces a different league every launch")
        }

        test("the digest would notice a single byte moving") {
            // The self-test. A checksum that returned a constant would make the pin above green
            // forever, which is the shape of a gate that has never failed.
            let encoded = try JSONEncoder.stable().encode(world)
            var mutated = encoded
            mutated[mutated.count / 2] = mutated[mutated.count / 2] &+ 1
            expect(checksum(mutated) != checksum(encoded), "the checksum ignores a changed byte")
            var swapped = encoded
            swapped.swapAt(0, encoded.count - 1)
            expect(checksum(swapped) != checksum(encoded),
                   "the checksum ignores byte ORDER, which is the only thing this pin is for")
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

        test("no two members, cities or venues in a league share a name") {
            // Ids were asserted distinct and names never were — the coverage-boundary pattern.
            // 166 members were drawn from a 570-name space with replacement, and the birthday
            // paradox did the rest: all 200 swept leagues carried duplicate city names, 145 had two
            // programmes with the identical full name, and 23 put two identically named programmes
            // in the same conference, which is two identical rows on a standings table.
            //
            // The sharpest form is D6's: 145 leagues contained a rivalry pointing at a name two
            // programmes shared. Rivalry is the emotional payload the whole endogenous-identity
            // design rests on, and "our rival is Blackmere Hollow Inland" means nothing when two
            // of them exist.
            func duplicates(_ names: [String]) -> [String] {
                var counts: [String: Int] = [:]
                for name in names { counts[name, default: 0] += 1 }
                return counts.filter { $0.value > 1 }.keys.sorted()
            }
            for (index, world) in sweptWorlds.prefix(40).enumerated() {
                expect(duplicates(world.map.cities.map(\.name)).isEmpty,
                       "seed \(index) has duplicate city names: "
                           + duplicates(world.map.cities.map(\.name)).prefix(3).joined(separator: ", "))
                let memberNames = world.programmes.map(\.name) + world.proTeams.map(\.name)
                expect(duplicates(memberNames).isEmpty,
                       "seed \(index) has two members with the same name: "
                           + duplicates(memberNames).prefix(3).joined(separator: ", "))
                let venues = world.identities.values.map(\.venueName)
                expect(duplicates(venues).isEmpty,
                       "seed \(index) has duplicate venue names: "
                           + duplicates(venues).prefix(3).joined(separator: ", "))
            }
        }

        test("no rivalry points at an ambiguous name") {
            // The consequence that matters, asserted directly rather than inferred from the
            // uniqueness of the pool.
            for (index, world) in sweptWorlds.prefix(20).enumerated() {
                let nameByID = Dictionary(uniqueKeysWithValues: world.programmes.map { ($0.id, $0.name) })
                var counts: [String: Int] = [:]
                for name in nameByID.values { counts[name, default: 0] += 1 }
                for programme in world.programmes {
                    for rivalID in programme.rivalIDs {
                        guard let rivalName = nameByID[rivalID] else { continue }
                        expectEqual(counts[rivalName] ?? 0, 1,
                                    "seed \(index): \(programme.name)'s rival is named "
                                        + "\(rivalName), which \(counts[rivalName] ?? 0) programmes share")
                    }
                }
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
