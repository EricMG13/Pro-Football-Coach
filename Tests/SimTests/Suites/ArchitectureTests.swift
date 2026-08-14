import Foundation
import FootballSimCore

private struct MutableArchitectureEntity: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var value: Int
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
/// The application root then moved from schema 11 to schema 12; these values were independently
/// reproduced after that migration and are intentionally pinned to the new root contract.
private let pinnedRootFingerprint: UInt64 = 11_754_806_364_418_451_928

private let pinnedAdvancedRootFingerprint: UInt64 = 696_885_492_462_968_224

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
