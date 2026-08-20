import Foundation
import FootballSimCore

private struct MutableArchitectureEntity: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var value: Int
}

/// `NewsItem` is deliberately not `Codable` — "Derived, never stored" per its own doc comment, so a
/// headline is never the source of truth a save persists. That means it cannot be handed to
/// `architectureFingerprint` directly; this private, test-only DTO carries the same facts through
/// `Encodable` so the read-model's *rendering* can be pinned without adding persistence surface to
/// production `NewsItem`/`NewsFeedReadModel`.
private struct NewsItemFingerprintDTO: Codable, Equatable {
    let eventID: UUID
    let occurredAt: CalendarState
    let weight: Int
    let headline: String

    init(_ item: NewsItem) {
        eventID = item.eventID
        occurredAt = item.occurredAt
        weight = item.weight
        headline = item.headline
    }
}

/// Both pins moved twice on 2026-08-12. First when schema 10 became schema 11: when
/// `DomainEventLedger` gained its bounded season archive. The version and the ledger's shape are
/// both inside the encoded root, so *every* root fingerprint moves — including a freshly
/// bootstrapped one that has archived nothing yet. That is why the root pin moves here and did not
/// move for the rivalry-ordering change, which touched a step rather than a persisted type.
/// Then again when this stopped hashing the save envelope and started hashing the canonical JSON
/// body, so a compressed envelope cannot make a determinism pin depend on zlib.
///
/// And a third time on 2026-08-12, when bootstrap began issuing professional contracts
/// (`02` section 4.2a). That is a change to the generated *state*, which is exactly what this pin
/// exists to notice, so re-pinning is the correct response rather than a workaround — unlike the
/// compression move above, where the state was identical and only its encoding had changed. The
/// generation-body pin did not move, and should not have: it hashes `LeagueGenerator.generate`,
/// and contracts are issued during bootstrap rather than league generation. Both new values were
/// reproduced in two independent processes before being written here.
/// The application root then moved from schema 11 to schema 12, and schema 13 added the durable
/// professional negotiation ledger; these values were independently reproduced after each
/// migration and are intentionally pinned to the current root contract.
/// Tactical state now also persists the bounded personnel and practice-consumption ledgers; the
/// values below were reproduced in two independent release-process invocations.
/// The advanced pin moved again when completed summaries gained an explicit abstracted/detailed
/// source discriminator, so the new controlled detailed path cannot be mistaken for an abstract
/// result after reload.
/// Both pins moved again on 2026-08-20, when `CareerArcState` gained a persisted
/// `stakeholderLastMovement` field: `careerArc` is a required, non-optional property of `GameState`
/// itself (not something that exists only once a career starts), so the new key appears in every
/// encoded root's JSON body -- including a freshly bootstrapped one where the dictionary is empty --
/// exactly the same class of move as the `DomainEventLedger` archive above, not a determinism
/// regression. Unlike the moves above, these two values were not independently reproduced across
/// two local processes before being written here -- no Swift toolchain exists in this environment
/// (`CLAUDE.md`) -- they are copied verbatim from a single CI run's own actual output for this exact
/// commit (`.github/workflows/tests.yml`, run 32319402462, job 96278385220). Cross-process
/// reproduction of a hash over a fixed seed is precisely the property this test exists to check, so
/// a second confirming run is what would actually validate that guarantee, not a second manual
/// re-derivation of the same single number.
private let pinnedRootFingerprint: UInt64 = 13_271_746_992_715_500_232

private let pinnedAdvancedRootFingerprint: UInt64 = 2_051_777_162_885_451_912

/// The professional contract-negotiation ledger (`ProMarketState.contractNegotiations`) is part of
/// the schema-13 root, but neither pin above ever exercises it: bootstrap starts with it empty, and
/// `WorldScheduler.advanceWeek` never opens, counters or settles a negotiation on its own — only
/// `ProManagementSystem` does, and that is a career-control action, not a scheduler step. A root
/// that carried a corrupted offer history, a wrong negotiation status, or a mis-ordered ledger
/// after decode would still satisfy both fingerprints above. This pin walks the ledger through
/// open, counter and settle and hashes the result, so its cross-process byte-identity is actually
/// asserted rather than assumed from the root pins. Reproduced in two independent processes before
/// being written here.
/// Moved on 2026-08-20 for the same reason the root pins did: `careerArc` is a required property of
/// every `GameState`, so `CareerArcState`'s new `stakeholderLastMovement` field shifted this pin's
/// JSON body too, not only the two above. Copied from a single CI run's own output (run 32322631469,
/// job 96287645557), not independently reproduced -- no toolchain exists here to do that.
private let pinnedNegotiationLedgerFingerprint: UInt64 = 7_453_535_852_306_487_647

/// `GameState.matchSession` is part of the schema-13 root, but neither pin above ever exercises a
/// populated one: `bootstrap` leaves it `nil` by construction, and `WorldScheduler.advanceWeek`
/// never calls `prepareControlledMatch`, so the advanced pin's session stays `nil` too. A root that
/// carried a corrupted `SnapPersonnel`, a wrong in-drive `Situation`, or a mis-ordered call-in
/// proposal after decode would still satisfy both fingerprints above. This pin drives a controlled
/// fixture through `prepareControlledMatch` and one `.advance`, reaching the mid-match,
/// pending-call-in shape, and hashes the result, so its cross-process byte-identity is actually
/// asserted rather than assumed from the root pins. Reproduced in two independent processes before
/// being written here.
/// Moved on 2026-08-20 for the same reason as the negotiation-ledger pin above:
/// `CareerArcState.stakeholderLastMovement`, copied verbatim from the same CI run, same caveat.
private let pinnedMatchSessionFingerprint: UInt64 = 3_423_278_094_891_302_957

/// `NewsFeedReadModel` is derived from `GameState.history`, not stored in it, so none of the three
/// pins above ever exercise it: they hash the root or a projection of it, never the read-model
/// built on top. The domain-event ledger's own byte-identity is covered by those root pins, but the
/// *rendering* step — `NewsFeedReadModel.build`'s dedup, headline lookup and sort into `[NewsItem]`
/// — is a separate piece of logic with its own determinism risk (a `Dictionary`-derived lookup used
/// the wrong way, a sort comparator that stops being total) that no root fingerprint can see. This
/// pin drives a small fixed ledger through `build(from:)` and hashes the resulting items, so the
/// read-model's cross-process byte-identity is actually asserted rather than assumed from the root
/// pins. Reproduced in two independent processes before being written here.
/// Moved on 2026-08-20 for the same reason as the two pins above: `CareerArcState.stakeholderLastMovement`,
/// copied verbatim from the same CI run, same caveat.
private let pinnedNewsFeedFingerprint: UInt64 = 10_333_429_696_101_465_295

/// `DomainEventLedger` has carried a bounded `archive` of `SeasonHistoryDigest` since schema 11, and
/// it sits inside the root every pin above hashes — but none of them ever exercises it non-empty.
/// Bootstrap starts with a fresh, single-event ledger; `WorldScheduler.advanceWeek` from a fresh
/// bootstrap doesn't emit enough events to overflow the default 4,096-event retention limit; and the
/// negotiation-ledger, match-session and news-feed pins above either never touch `state.history` or
/// replace it outright with a small ledger that stays well under retention. A root whose archived
/// digest carried a corrupted `archivedCount`, a `notableEvents` entry that failed the
/// `historicalWeight`-based notability filter, or an archive mis-ordered by season after decode would
/// still satisfy every pin above. This pin builds a `DomainEventLedger(retentionLimit: 1)`, appends
/// three events spanning two seasons so two are forced into a season-3 archive digest (one notable
/// `.seasonCompleted`, one non-notable `.integrityChecked`) while the third stays in `recent`, and
/// hashes the resulting root, so the archive path's cross-process byte-identity is actually asserted
/// rather than assumed from the root pins. Reproduced in two independent processes before being
/// written here.
/// Moved on 2026-08-20 for the same reason as the three pins above: `CareerArcState.stakeholderLastMovement`,
/// copied verbatim from the same CI run, same caveat.
private let pinnedArchivedLedgerFingerprint: UInt64 = 11_401_939_783_798_285_572

/// Hashes the canonical JSON body, not the save envelope.
///
/// It hashed the envelope until 2026-08-12, when the body became zlib-compressed. That would have
/// made this pin depend on the compression library's output as well as on the world, so a zlib
/// change in a future OS would break a determinism gate for a reason that has nothing to do with
/// determinism. What the pin is for is that a given seed produces a given *state*; compression is
/// transport. `SaveEnvelope`'s own suite owns the round trip.
private func architectureFingerprint<T: Encodable>(_ value: T) throws -> UInt64 {
    let bytes = try JSONEncoder.stable().encode(value)
    return bytes.reduce(0xCBF2_9CE4_8422_2325) { value, byte in
        (value ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
    }
}

func runArchitectureTests() {
    suite("Authoritative game state") {
        test("a generated world bootstraps into normalized stores exactly once") {
            let state = GameState.bootstrap(seed: 20_260_810)

            expectEqual(state.programmes.count, CollegeRules.programmeCount)
            expectEqual(state.proTeams.count, ProRules.teamCount)
            expectEqual(
                state.staff.count,
                (CollegeRules.programmeCount + ProRules.teamCount)
                    * PeopleRules.staffPerOrganisation
            )
            expectEqual(Set(state.programmes.ids).count, state.programmes.count)
            expectEqual(Set(state.proTeams.ids).count, state.proTeams.count)

            for programme in state.programmes.values {
                expectEqual(state.programmes[programme.id], programme)
            }
            for team in state.proTeams.values {
                expectEqual(state.proTeams[team.id], team)
            }
        }

        test("the same seed produces byte-identical root state") {
            let first = GameState.bootstrap(seed: 7)
            let second = GameState.bootstrap(seed: 7)
            expectEqual(try SaveEnvelope.encode(first), try SaveEnvelope.encode(second))
        }


        test("root and scheduler fingerprints are pinned across processes") {
            let root = GameState.bootstrap(seed: 20_260_810)
            let advanced = try WorldScheduler.advanceWeek(root)
            expectEqual(try architectureFingerprint(root), pinnedRootFingerprint)
            expectEqual(try architectureFingerprint(advanced), pinnedAdvancedRootFingerprint)
        }

        test("the professional negotiation ledger is pinned across processes") {
            var state = GameState.bootstrap(seed: 20_260_819)
            let teamID = state.proTeams.ids[0]
            let playerID = state.proTeams[teamID]!.rosterIDs[0]
            state.careerArc = CareerArcState(
                currentJob: CareerJob(
                    organisationID: teamID,
                    tier: .professional,
                    startedAt: state.calendar
                ),
                status: .employed
            )
            let current = state.players[playerID]!.contract!
            let opened = try ProManagementSystem.beginNegotiation(
                playerID: playerID,
                teamID: teamID,
                offer: current,
                deadline: state.calendar.advancedWeek().advancedWeek(),
                in: state
            )
            let countered = try ProManagementSystem.counterNegotiation(
                negotiationID: opened.negotiation.id,
                offer: current,
                in: opened.state
            )
            let settled = try ProManagementSystem.settleNegotiation(
                negotiationID: opened.negotiation.id,
                as: .accepted,
                in: countered.state
            )
            expectEqual(settled.state.proMarket.contractNegotiations.count, 1)
            expectEqual(
                try architectureFingerprint(settled.state),
                pinnedNegotiationLedgerFingerprint
            )
        }

        test("the match session is pinned across processes") {
            let source = GameState.bootstrap(seed: 20_260_820)
            guard let game = source.competition.currentSchedule.games.first(where: {
                $0.season == source.calendar.season
                    && $0.week == source.calendar.week
                    && $0.result == nil
                    && source.programmes[$0.homeID] != nil
            }) else {
                expect(false, "the generated fixture had no controlled college side")
                return
            }
            let started = try CareerControlSystem.startCollegeCareer(at: game.homeID, in: source).state
            var prepared = try WorldScheduler.prepareControlledMatch(in: started)
            guard var checkpoint = prepared.matchSession else {
                expect(false, "prepareControlledMatch did not install a match session")
                return
            }
            while !checkpoint.completed {
                let step = try MatchReducer.reduce(.advance, state: &checkpoint)
                if step.proposal != nil { break }
            }
            prepared.matchSession = checkpoint

            expectEqual(prepared.matchSession?.controlledSide, .home)
            expectEqual(prepared.matchSession?.isTakeover, true)
            expectEqual(prepared.matchSession?.pendingCallIn?.options.isEmpty, false)
            expectEqual(prepared.matchSession?.home.offense.isEmpty, false)
            expectEqual(prepared.matchSession?.away.defense.isEmpty, false)
            expectEqual(
                try architectureFingerprint(prepared),
                pinnedMatchSessionFingerprint
            )
        }

        test("the news feed is pinned across processes") {
            var state = GameState.bootstrap(seed: 20_260_821)
            let college = state.programmes.ids[0]
            let otherCollege = state.programmes.ids[1]
            let pro = state.proTeams.ids[0]
            let staffID = state.staff.ids[0]
            let playerID = state.players.ids[0]

            var ledger = DomainEventLedger()
            expect(ledger.append(contentsOf: [
                DomainEvent(
                    id: DomainEvent.deterministicID(rootSeed: 20_260_821, sequence: 0),
                    sequence: 0,
                    occurredAt: CalendarState(season: 3, week: 1),
                    payload: .seasonCompleted(
                        season: 3,
                        collegeChampionID: college,
                        proChampionID: pro
                    )
                ),
                DomainEvent(
                    id: DomainEvent.deterministicID(rootSeed: 20_260_821, sequence: 1),
                    sequence: 1,
                    occurredAt: CalendarState(season: 4, week: 1),
                    payload: .staffHired(
                        staffID: staffID,
                        organisationID: college,
                        role: .headCoach
                    )
                ),
                DomainEvent(
                    id: DomainEvent.deterministicID(rootSeed: 20_260_821, sequence: 2),
                    sequence: 2,
                    occurredAt: CalendarState(season: 4, week: 1),
                    payload: .playerTransferred(
                        playerID: playerID,
                        sourceProgrammeID: college,
                        destinationProgrammeID: otherCollege,
                        targetSeason: 4,
                        window: .postseason,
                        sourceWasScholarship: true,
                        finalNIL: 0
                    )
                ),
            ]), "ledger construction for the news-feed fixture was rejected")
            state.history = ledger

            let items = NewsFeedReadModel.build(from: state).items
            expectEqual(items.count, 3)
            expectEqual(items.map(\.weight), [40, 35, 100],
                        "within season 4 the transfer (40) must lead the hire (35)")
            expectEqual(items.map(\.occurredAt.season), [4, 4, 3])
            expect(!items[0].headline.isEmpty && !items[1].headline.isEmpty
                    && items[0].headline != items[1].headline,
                   "both season-4 headlines should resolve distinct real names")

            let dtoItems = items.map(NewsItemFingerprintDTO.init)
            expectEqual(try architectureFingerprint(dtoItems), pinnedNewsFeedFingerprint)
        }

        test("the archived-season ledger is pinned across processes") {
            var state = GameState.bootstrap(seed: 20_260_822)
            let college = state.programmes.ids[0]
            let pro = state.proTeams.ids[0]
            let staffID = state.staff.ids[0]

            var ledger = DomainEventLedger(retentionLimit: 1)
            expect(ledger.append(contentsOf: [
                DomainEvent(
                    id: DomainEvent.deterministicID(rootSeed: 20_260_822, sequence: 0),
                    sequence: 0,
                    occurredAt: CalendarState(season: 3, week: 1),
                    payload: .seasonCompleted(
                        season: 3,
                        collegeChampionID: college,
                        proChampionID: pro
                    )
                ),
                DomainEvent(
                    id: DomainEvent.deterministicID(rootSeed: 20_260_822, sequence: 1),
                    sequence: 1,
                    occurredAt: CalendarState(season: 3, week: 1),
                    payload: .integrityChecked(issueCount: 0)
                ),
                DomainEvent(
                    id: DomainEvent.deterministicID(rootSeed: 20_260_822, sequence: 2),
                    sequence: 2,
                    occurredAt: CalendarState(season: 4, week: 1),
                    payload: .staffHired(
                        staffID: staffID,
                        organisationID: college,
                        role: .headCoach
                    )
                ),
            ]), "ledger construction for the archived-history fixture was rejected")
            state.history = ledger

            expectEqual(state.history.recent.count, 1)
            expectEqual(state.history.archive.count, 1)
            expectEqual(state.history.archive.first?.season, 3)
            expectEqual(state.history.archive.first?.archivedCount, 2)
            expectEqual(state.history.archive.first?.notableEvents.count, 1)
            expectEqual(state.history.archivedCount, 2)
            expectEqual(state.history.totalCount, 3)

            expectEqual(
                try architectureFingerprint(state),
                pinnedArchivedLedgerFingerprint
            )
        }

        test("the authoritative root survives the save envelope") {
            let state = GameState.bootstrap(seed: 99)
            let restored = try SaveEnvelope.decode(
                GameState.self,
                from: SaveEnvelope.encode(state)
            )
            expectEqual(restored, state)
        }

        test("a persisted root with an unsupported internal version is rejected") {
            let encoded = try JSONEncoder().encode(GameState.bootstrap(seed: 100))
            var object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            object["version"] = GameState.schemaVersion + 1
            let corrupted = try JSONSerialization.data(withJSONObject: object)

            do {
                _ = try JSONDecoder().decode(GameState.self, from: corrupted)
                expect(false, "a root with a future internal version decoded")
            } catch {
                expect(true)
            }
        }

        test("a persisted root with broken cross-references is rejected at decode") {
            var state = GameState.bootstrap(seed: 101)
            state.league.conferences[0].memberIDs.append(
                UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFFE")!
            )
            let corrupted = try JSONEncoder().encode(state)

            do {
                _ = try JSONDecoder().decode(GameState.self, from: corrupted)
                expect(false, "a root with broken cross-references decoded")
            } catch {
                expect(true)
            }
        }

        test("entity-store values have deterministic identifier order") {
            let world = LeagueGenerator.generate(seed: 42)
            let store = EntityStore(world.programmes.reversed())
            expectEqual(store.ids, store.ids.sorted { $0.uuidString < $1.uuidString })
        }

        test("a decoded entity-store rejects a key that disagrees with the entity ID") {
            let entityID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
            let wrongKey = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
            let store = EntityStore([MutableArchitectureEntity(id: entityID, value: 7)])
            var encoded = String(
                data: try JSONEncoder().encode(store),
                encoding: .utf8
            )!
            guard let keyRange = encoded.range(of: entityID.uuidString) else {
                expect(false, "the encoded store did not contain its key")
                return
            }
            encoded.replaceSubrange(keyRange, with: wrongKey.uuidString)

            do {
                _ = try JSONDecoder().decode(
                    EntityStore<MutableArchitectureEntity>.self,
                    from: Data(encoded.utf8)
                )
                expect(false, "a store with mismatched key and entity ID decoded")
            } catch {
                expect(true)
            }
        }

        test("an update cannot move an entity underneath its existing store key") {
            let entityID = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!
            let movedID = UUID(uuidString: "00000000-0000-4000-8000-000000000004")!
            var store = EntityStore([MutableArchitectureEntity(id: entityID, value: 1)])

            expect(!store.update(entityID) { $0.id = movedID })
            expectEqual(store[entityID]?.id, entityID)
            expectEqual(store[movedID], nil)
        }
    }

    suite("Domain event ledger") {
        test("bootstrap emits structured world-created history") {
            let state = GameState.bootstrap(seed: 11)
            expectEqual(state.history.recent.count, 1)
            guard let event = state.history.recent.first else { return }
            expectEqual(event.sequence, 0)
            expectEqual(event.occurredAt, CalendarState())
            guard case let .worldCreated(programmes, proTeams) = event.payload else {
                expect(false, "bootstrap emitted the wrong event: \(event.payload)")
                return
            }
            expectEqual(programmes, CollegeRules.programmeCount)
            expectEqual(proTeams, ProRules.teamCount)
        }

        test("event retention is bounded and accounts for archived events") {
            var ledger = DomainEventLedger(retentionLimit: 2)
            for sequence in 0..<5 {
                ledger.append(DomainEvent(
                    id: UUID(uuidString: String(
                        format: "00000000-0000-4000-8000-%012X",
                        sequence
                    ))!,
                    sequence: sequence,
                    occurredAt: CalendarState(),
                    payload: .integrityChecked(issueCount: 0)
                ))
            }
            expectEqual(ledger.recent.map(\.sequence), [3, 4])
            expectEqual(ledger.archivedCount, 3)
            expectEqual(ledger.totalCount, 5)
        }

        test("duplicate or out-of-order event sequences are refused") {
            var ledger = DomainEventLedger(retentionLimit: 4)
            let first = DomainEvent(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
                sequence: 0,
                occurredAt: CalendarState(),
                payload: .integrityChecked(issueCount: 0)
            )
            expect(ledger.append(first), "the first event was refused")
            expect(!ledger.append(first), "a duplicate event was accepted")
        }

        test("a malformed persisted ledger is rejected instead of normalized silently") {
            var ledger = DomainEventLedger(retentionLimit: 2)
            ledger.append(DomainEvent(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000010")!,
                sequence: 0,
                occurredAt: CalendarState(),
                payload: .integrityChecked(issueCount: 0)
            ))
            let encoded = try JSONEncoder().encode(ledger)
            var object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            object["archivedCount"] = -1
            let corrupted = try JSONSerialization.data(withJSONObject: object)

            do {
                _ = try JSONDecoder().decode(DomainEventLedger.self, from: corrupted)
                expect(false, "a ledger with negative archive accounting decoded")
            } catch {
                expect(true)
            }
        }

        test("persisted calendar values outside the shared season are rejected") {
            let invalid = Data(#"{"season":0,"week":22}"#.utf8)
            do {
                _ = try JSONDecoder().decode(CalendarState.self, from: invalid)
                expect(false, "an invalid persisted calendar decoded")
            } catch {
                expect(true)
            }
        }
    }

    suite("World scheduler") {
        test("the scheduler order is the master blueprint order") {
            expectEqual(WorldScheduler.steps, [
                .expiringInboundEvents,
                .injuriesAndRecovery,
                .practiceAndDevelopment,
                .scoutingKnowledge,
                .marketInteractions,
                .aiDecisions,
                .nonUserGames,
                .userGame,
                .standingsAndRankings,
                .statisticsAndRecords,
                .relationshipsAndStakeholders,
                .newsAndNarrative,
                .jobAndStaffMarkets,
                .saveGrowthAndIntegrity,
                .weekSnapshot,
            ])
            expectEqual(Set(WorldScheduler.steps).count, WorldStep.allCases.count)
        }

        test("one week advances through the scheduler truthfully") {
            let before = GameState.bootstrap(seed: 123)
            let transition = try WorldScheduler.advanceWeek(before)

            expectEqual(transition.state.calendar, CalendarState(season: 0, week: 2))
            expectEqual(transition.snapshot.completed, CalendarState(season: 0, week: 1))
            expectEqual(transition.snapshot.next, CalendarState(season: 0, week: 2))
            expectEqual(transition.stepRecords.map(\.step), WorldScheduler.steps)
            expectEqual(
                transition.stepRecords.filter { $0.status == .executed }.map(\.step),
                [
                    .injuriesAndRecovery,
                    .practiceAndDevelopment,
                    .scoutingKnowledge,
                    .marketInteractions,
                    .aiDecisions,
                    .nonUserGames,
                    .standingsAndRankings,
                    .statisticsAndRecords,
                    .relationshipsAndStakeholders,
                    .jobAndStaffMarkets,
                    .saveGrowthAndIntegrity,
                    .weekSnapshot,
                ]
            )
            expectEqual(
                transition.stepRecords.filter { $0.status == .inactive }.count,
                WorldScheduler.steps.count - 12
            )
        }

        test("equal states advance to byte-identical states and snapshots") {
            let first = try WorldScheduler.advanceWeek(GameState.bootstrap(seed: 321))
            let second = try WorldScheduler.advanceWeek(GameState.bootstrap(seed: 321))
            expectEqual(try SaveEnvelope.encode(first.state), try SaveEnvelope.encode(second.state))
            expectEqual(first.snapshot, second.snapshot)
            expectEqual(first.stepRecords, second.stepRecords)
        }

        test("the shared calendar rolls from week twenty-one into a new season") {
            expectEqual(
                CalendarState(season: 2, week: SharedRules.inSeasonWeeks).advancedWeek(),
                CalendarState(season: 3, week: 1)
            )
        }
    }

    suite("Intent and projection boundary") {
        test("advance week refuses unresolved mandatory decisions") {
            var state = GameState.bootstrap(seed: 55)
            let decisionID = UUID(uuidString: "00000000-0000-4000-8000-0000000000AA")!
            let optionA = UUID(uuidString: "00000000-0000-4000-8000-0000000000AB")!
            let optionB = UUID(uuidString: "00000000-0000-4000-8000-0000000000AC")!
            let programmeID = state.programmes.ids[0]
            let prospectID = state.prospects.ids[0]
            _ = state.pending.enqueue(MandatoryDecision(
                id: decisionID,
                programmeID: programmeID,
                subject: .recruiting(prospectID: prospectID),
                createdAt: state.calendar,
                deadline: state.calendar,
                owner: .user,
                options: [
                    MandatoryDecisionOption(id: optionA, action: .recruiting(.offerScholarship)),
                    MandatoryDecisionOption(id: optionB, action: .recruiting(.withdraw)),
                ],
                recommendedOptionID: optionA,
                reasons: [MandatoryDecisionReason(code: .deadline, value: 0)]
            ))
            do {
                _ = try IntentResolver.resolve(.advanceWeek, in: state)
                expect(false, "advance week bypassed a mandatory decision")
            } catch let error as IntentResolutionError {
                expectEqual(error, .unresolvedMandatoryDecisions(count: 1))
            }
        }

        test("advance week returns a projection and events, not invented UI state") {
            let state = GameState.bootstrap(seed: 56)
            let scheduledThisWeek = state.competition.currentSchedule.games.filter {
                $0.season == state.calendar.season && $0.week == state.calendar.week
            }.count
            let resolved = try IntentResolver.resolve(.advanceWeek, in: state)
            switch resolved.result {
            case let .weekAdvanced(snapshot, emittedEvents):
                expectEqual(snapshot.next.week, 2)
                let recruitingInteractions = emittedEvents.filter {
                    if case .recruitingInteraction = $0.payload { return true }
                    return false
                }.count
                let boardAdditions = emittedEvents.filter {
                    if case let .recruitingInteraction(_, _, action, _, _) = $0.payload,
                       action == .addToBoard {
                        return true
                    }
                    return false
                }.count
                expectEqual(
                    boardAdditions,
                    state.programmes.count * CollegeRules.aiWeeklyBoardGrowth
                )
                expect(recruitingInteractions >= boardAdditions)
                expect(
                    recruitingInteractions <= state.programmes.count * (
                        CollegeRules.aiWeeklyBoardGrowth
                            + CollegeRules.aiWeeklyInvestmentActionLimit
                    )
                )
                expectEqual(
                    emittedEvents.count,
                    scheduledThisWeek + recruitingInteractions + 2
                )
            case .recruitingUpdated:
                expect(false, "advance-week intent returned a recruiting result")
            case .tacticalUpdated:
                expect(false, "advance-week intent returned a tactical result")
            case .careerUpdated:
                expect(false, "advance-week intent returned a career result")
            case .proManagementUpdated:
                expect(false, "advance-week intent returned a professional-management result")
            case .proMarketUpdated:
                expect(false, "advance-week intent returned a professional-market result")
            }
            expectEqual(resolved.state.calendar.week, 2)
        }
    }

    suite("World integrity") {
        test("a generated target-scale root passes every active M0 check") {
            let report = WorldIntegrity.check(GameState.bootstrap(seed: 808))
            expect(report.isValid, report.issues.map(\.description).joined(separator: ", "))
            expectEqual(Set(report.activeChecks).count, report.activeChecks.count)
            expect(!report.inactiveChecks.isEmpty,
                   "future checks vanished instead of remaining explicitly inactive")
            expect(report.activeChecks.contains(.eventReferences),
                   "entity-linked game events are not covered by integrity")
        }

        test("an unresolved conference member is reported") {
            var state = GameState.bootstrap(seed: 809)
            state.league.conferences[0].memberIDs.append(
                UUID(uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFFF")!
            )
            let report = WorldIntegrity.check(state)
            expect(report.issues.contains { issue in
                if case .missingConferenceMember = issue { return true }
                return false
            }, "a missing conference member passed integrity")
        }

        test("an organisation whose conference back-reference disagrees is reported") {
            var state = GameState.bootstrap(seed: 811)
            let programmeID = state.programmes.ids[0]
            let wrongConferenceID = state.league.conferences.first { $0.tier == .pro }!.id
            state.programmes.update(programmeID) { $0.conferenceID = wrongConferenceID }

            let report = WorldIntegrity.check(state)
            expect(report.issues.contains { issue in
                if case .conferenceMembershipMismatch(organisationID: programmeID) = issue {
                    return true
                }
                return false
            }, "a conflicting organisation conference passed integrity")
        }

        test("one player on two rosters is reported") {
            var state = GameState.bootstrap(seed: 810)
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-00000000BEEF")!
            let player = Player(
                id: playerID,
                firstName: "Test",
                lastName: "Player",
                position: .quarterback,
                age: 20,
                attributes: Attributes(),
                potential: Rating(70),
                eligibility: Eligibility()
            )
            state.players.insert(player)
            let ids = state.programmes.ids
            state.programmes.update(ids[0]) { $0.rosterIDs.append(playerID) }
            state.programmes.update(ids[1]) { $0.rosterIDs.append(playerID) }

            let report = WorldIntegrity.check(state)
            expect(report.issues.contains { issue in
                if case .duplicatePlayerOwnership(id: playerID, owners: 2) = issue { return true }
                return false
            }, "duplicate ownership passed integrity")
        }

        test("a repeated roster reference is not misreported as two owners") {
            var state = GameState.bootstrap(seed: 812)
            let programmeID = state.programmes.ids[0]
            let playerID = state.programmes[programmeID]!.rosterIDs[0]
            state.programmes.update(programmeID) { $0.rosterIDs.append(playerID) }

            let issues = WorldIntegrity.check(state).issues
            expect(issues.contains { issue in
                if case .duplicatePlayerReference(
                    playerID: playerID,
                    ownerID: programmeID
                ) = issue { return true }
                return false
            }, "the repeated roster reference was not reported")
            expect(!issues.contains { issue in
                if case .duplicatePlayerOwnership(id: playerID, owners: 2) = issue { return true }
                return false
            }, "one roster was falsely reported as two owners")
        }
    }
}
