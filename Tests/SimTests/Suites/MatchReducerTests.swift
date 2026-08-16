import Foundation
import FootballSimCore
import ProFootballCoachUI
import CoachWorldApp

func runMatchReducerTests() {
    suite("Resumable match reducer") {
        test("game evidence preserves bounded injury receipts") {
            let playerID = UUID(uuidString: "00000000-0000-4000-8000-000000008101")!
            let injury = GameInjuryEvidence(
                playerID: playerID,
                side: .home,
                area: .ankle,
                severity: .moderate,
                weeks: 3,
                occurredAt: CalendarState(season: 0, week: 8)
            )
            let evidence = GameEvidence(
                fixtureID: UUID(uuidString: "00000000-0000-4000-8000-000000008102")!,
                record: GameRecord(homeScore: 0, awayScore: 0, drives: [], tier: .college),
                homeParticipantIDs: [playerID],
                awayParticipantIDs: [],
                callInReceipts: [],
                injuries: [injury]
            )
            let restored = try! JSONDecoder.stable().decode(
                GameEvidence.self,
                from: JSONEncoder.stable().encode(evidence)
            )
            expectEqual(restored.injuries, [injury])
            expectEqual(restored.injuries.first?.playerID, playerID)
            var legacyObject = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(evidence)
            ) as! [String: Any]
            legacyObject.removeValue(forKey: "injuries")
            let legacyData = try! JSONSerialization.data(withJSONObject: legacyObject)
            let legacy = try! JSONDecoder.stable().decode(GameEvidence.self, from: legacyData)
            expectEqual(legacy.injuries, [])

            let foreign = GameInjuryEvidence(
                playerID: UUID(uuidString: "00000000-0000-4000-8000-000000008103")!,
                side: .away,
                area: .knee,
                severity: .minor,
                weeks: 1,
                occurredAt: CalendarState(season: 0, week: 8)
            )
            let forged = GameEvidence(
                record: evidence.record,
                homeParticipantIDs: [playerID],
                awayParticipantIDs: [],
                callInReceipts: [],
                injuries: [foreign]
            )
            do {
                _ = try JSONDecoder.stable().decode(
                    GameEvidence.self,
                    from: JSONEncoder.stable().encode(forged)
                )
                expect(false, "a foreign injury must not cross the evidence trust boundary")
            } catch {
                expect(true)
            }
        }

        test("headless reducer and public game driver are deterministic") {
            let personnel = testPersonnel(offenseSkill: 72, defenseSkill: 72)
            let direct = GameEngine.play(tier: .pro, home: personnel, away: personnel, seed: 8_101)
            let reduced = MatchReducer.playToCompletion(
                tier: .pro, home: personnel, away: personnel, seed: 8_101
            ).record
            expectEqual(reduced, direct)
            expectEqual(reduced.playByPlayFingerprint, direct.playByPlayFingerprint)
        }

        test("a controlled call-in pauses before a real snap and changes only its side plan") {
            let personnel = testPersonnel(offenseSkill: 72, defenseSkill: 72)
            let stateSituation = Situation(
                down: 4, distance: 2, yardLine: 72, possession: .home,
                homeScore: 14, awayScore: 17, quarter: 4, secondsRemainingInQuarter: 80,
                timeoutsRemaining: [.home: 3, .away: 3]
            )
            var state = MatchReducer.start(
                tier: .pro, home: personnel, away: personnel, seed: 8_102,
                controlledSide: .home, initialSituation: stateSituation
            )
            let pause = try! MatchReducer.reduce(.advance, state: &state)
            expectEqual(pause.boundary, .callIn)
            expectEqual(state.revision, 1)
            expectEqual(pause.proposal?.trigger, .fourthDown)
            let homeBefore = state.homePlan
            let awayBefore = state.awayPlan
            let resolved = try! MatchReducer.reduce(.chooseCallIn(.attack), state: &state)
            expectEqual(resolved.callIn?.side, .home)
            expectEqual(resolved.callIn?.action, .attack)
            expect(state.homePlan != homeBefore, "the selected call-in did not install a plan")
            expectEqual(state.awayPlan, awayBefore)
            expect(resolved.play != nil, "a call-in did not resolve the paused snap")
            expectEqual(state.callInReceipts.count, 1)
        }

        test("a cold resume preserves the pending call-in and final fingerprint") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let situation = Situation(down: 4, distance: 1, yardLine: 78, possession: .away,
                                      quarter: 1, secondsRemainingInQuarter: 300,
                                      timeoutsRemaining: [.home: 3, .away: 3])
            var original = MatchReducer.start(
                tier: .college, home: personnel, away: personnel, seed: 8_103,
                controlledSide: .away, initialSituation: situation
            )
            _ = try! MatchReducer.reduce(.advance, state: &original)
            let data = try! JSONEncoder.stable().encode(original)
            var resumed = try! JSONDecoder.stable().decode(MatchSessionState.self, from: data)
            expectEqual(resumed, original)
            while !resumed.completed {
                let action: MatchAction = resumed.pendingCallIn == nil
                    ? .advance : .chooseCallIn(.trustCoordinator)
                _ = try! MatchReducer.reduce(action, state: &resumed)
            }
            expectEqual(resumed.completion?.fingerprint,
                        MatchCompletionReceipt(
                            record: resumed.completion!.record,
                            callInReceipts: resumed.callInReceipts
                        ).fingerprint)
            expect(resumed.callInReceipts.allSatisfy { $0.side == .away })
        }

        test("pause is persisted and prevents a snap until resumed") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let situation = Situation(
                down: 1,
                distance: 10,
                yardLine: 25,
                possession: .away,
                quarter: 1,
                secondsRemainingInQuarter: 300,
                timeoutsRemaining: [.home: 3, .away: 3]
            )
            var state = MatchReducer.start(
                tier: .pro,
                home: personnel,
                away: personnel,
                seed: 8_111,
                controlledSide: .home,
                initialSituation: situation
            )
            _ = try! MatchReducer.reduce(.togglePause, state: &state)
            expect(state.isPaused)
            let reopened = try! JSONDecoder.stable().decode(
                MatchSessionState.self,
                from: JSONEncoder.stable().encode(state)
            )
            expectEqual(reopened, state)
            do {
                _ = try MatchReducer.reduce(.advance, state: &state)
                expect(false, "a paused match accepted a snap")
            } catch MatchReducerError.paused {
                expect(true)
            } catch {
                expect(false, "paused match returned the wrong error")
            }
            _ = try! MatchReducer.reduce(.togglePause, state: &state)
            expect(!state.isPaused)
            let resumed = try! MatchReducer.reduce(.advance, state: &state)
            expect(resumed.play != nil || resumed.proposal != nil)
        }

        test("takeover hand-back is persisted and gates only future call-ins") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let situation = Situation(
                down: 4,
                distance: 2,
                yardLine: 72,
                possession: .home,
                homeScore: 14,
                awayScore: 17,
                quarter: 4,
                secondsRemainingInQuarter: 80,
                timeoutsRemaining: [.home: 3, .away: 3]
            )
            var state = MatchReducer.start(
                tier: .pro,
                home: personnel,
                away: personnel,
                seed: 8_112,
                controlledSide: .home,
                initialSituation: situation
            )
            expect(state.isTakeover, "a controlled match should begin in coach control")
            _ = try! MatchReducer.reduce(.toggleTakeover, state: &state)
            expect(!state.isTakeover, "hand-back did not return the side to coordinator control")
            let reopened = try! JSONDecoder.stable().decode(
                MatchSessionState.self,
                from: JSONEncoder.stable().encode(state)
            )
            expectEqual(reopened, state)
            let delegatedSnap = try! MatchReducer.reduce(.advance, state: &state)
            expect(delegatedSnap.play != nil, "hand-back did not let the coordinator resolve the snap")
            expectEqual(state.pendingCallIn, nil)
            _ = try! MatchReducer.reduce(.toggleTakeover, state: &state)
            expect(state.isTakeover)
        }

        test("legacy controlled checkpoints default to coach takeover") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let state = MatchReducer.start(
                tier: .pro,
                home: personnel,
                away: personnel,
                seed: 8_113,
                controlledSide: .away
            )
            var object = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(state)
            ) as! [String: Any]
            object.removeValue(forKey: "isTakeover")
            object.removeValue(forKey: "revision")
            let legacy = try! JSONSerialization.data(withJSONObject: object)
            let reopened = try! JSONDecoder.stable().decode(
                MatchSessionState.self,
                from: legacy
            )
            expect(reopened.isTakeover, "old controlled checkpoints lost coach control")
            expectEqual(reopened.revision, 0)
        }

        test("a pending call-in cannot be detached from its current controlled snap") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let situation = Situation(
                down: 4,
                distance: 2,
                yardLine: 72,
                possession: .home,
                homeScore: 14,
                awayScore: 17,
                quarter: 4,
                secondsRemainingInQuarter: 80,
                timeoutsRemaining: [.home: 3, .away: 3]
            )
            var state = MatchReducer.start(
                tier: .pro,
                home: personnel,
                away: personnel,
                seed: 8_114,
                controlledSide: .home,
                initialSituation: situation
            )
            _ = try! MatchReducer.reduce(.advance, state: &state)
            state.isTakeover = false
            do {
                _ = try JSONDecoder.stable().decode(
                    MatchSessionState.self,
                    from: JSONEncoder.stable().encode(state)
                )
                expect(false, "a detached pending call-in checkpoint decoded")
            } catch is DecodingError {
                expect(true)
            } catch {
                expect(false, "the malformed checkpoint returned the wrong error: \(error)")
            }

            state.isTakeover = true
            state.isPaused = true
            do {
                _ = try JSONDecoder.stable().decode(
                    MatchSessionState.self,
                    from: JSONEncoder.stable().encode(state)
                )
                expect(false, "a paused pending call-in checkpoint decoded")
            } catch is DecodingError {
                expect(true)
            } catch {
                expect(false, "the paused checkpoint returned the wrong error: \(error)")
            }
            state.isPaused = false
            state.currentDrive = nil
            let receiptsBefore = state.callInReceipts.count
            do {
                _ = try MatchReducer.reduce(.chooseCallIn(.attack), state: &state)
                expect(false, "a call-in without its current drive was accepted")
            } catch MatchReducerError.invalidCallInState {
                expectEqual(state.callInReceipts.count, receiptsBefore)
                expect(state.pendingCallIn != nil, "an invalid call-in mutated the pending prompt")
            } catch {
                expect(false, "the malformed call-in returned the wrong error: \(error)")
            }
        }

        test("legacy match checkpoints default the new stage and overtime fields") {
            let personnel = testPersonnel(offenseSkill: 70, defenseSkill: 70)
            let state = MatchReducer.start(
                tier: .pro,
                home: personnel,
                away: personnel,
                seed: 8_108
            )
            var object = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(state)
            ) as! [String: Any]
            object.removeValue(forKey: "stage")
            object.removeValue(forKey: "overtimePeriod")
            object.removeValue(forKey: "overtimePossessions")
            let legacy = try! JSONSerialization.data(withJSONObject: object)
            let reopened = try! JSONDecoder.stable().decode(
                MatchSessionState.self,
                from: legacy
            )
            expectEqual(reopened.stage, .regularSeason)
            expectEqual(reopened.overtimePeriod, 0)
            expect(reopened.overtimePossessions.isEmpty)
        }

        test("completion is exactly once and rejects a second mutation") {
            let personnel = testPersonnel(offenseSkill: 68, defenseSkill: 68)
            var state = MatchReducer.start(tier: .pro, home: personnel, away: personnel, seed: 8_104)
            while !state.completed {
                _ = try! MatchReducer.reduce(.advance, state: &state)
            }
            let receipt = state.completion
            expect(receipt != nil)
            expectEqual(receipt?.record, state.completion?.record)
            expectEqual(receipt?.evidence.record, receipt?.record)
            expect(receipt?.evidence.homeParticipantIDs.isEmpty == false)
            do {
                _ = try MatchReducer.reduce(.advance, state: &state)
                expect(false, "completed match accepted another action")
            } catch MatchReducerError.completed {
                expect(true)
            } catch {
                expect(false, "completed match returned the wrong error")
            }
        }

        test("overtime policy is tier and stage aware") {
            let personnel = testPersonnel(offenseSkill: 50, defenseSkill: 50)
            let regulationEnd = Situation(
                possession: .home,
                quarter: 4,
                secondsRemainingInQuarter: 1,
                timeoutsRemaining: [.home: 3, .away: 3]
            )
            let puntCaller = PuntOnlyCaller()

            let pro = MatchReducer.playToCompletion(
                tier: .pro,
                stage: .regularSeason,
                home: personnel,
                away: personnel,
                caller: puntCaller,
                seed: 8_107,
                initialSituation: regulationEnd
            )
            expectEqual(pro.record.winner, nil,
                        "a bounded pro regular-season overtime should be allowed to end tied")

            for (tier, stage) in [
                (Tier.college, CompetitionStage.regularSeason),
                (Tier.pro, CompetitionStage.quarterfinal)
            ] {
                let completion = MatchReducer.playToCompletion(
                    tier: tier,
                    stage: stage,
                    home: personnel,
                    away: personnel,
                    caller: puntCaller,
                    seed: 8_107,
                    initialSituation: regulationEnd
                )
                expect(completion.record.winner != nil,
                       "\(tier.rawValue) \(stage.rawValue) overtime must produce a winner")
            }
        }

        test("a drive-budget boundary cannot leave a winner-required tie") {
            let personnel = testPersonnel(offenseSkill: 50, defenseSkill: 50)
            var state = MatchReducer.start(
                tier: .college,
                stage: .regularSeason,
                home: personnel,
                away: personnel,
                seed: 8_109
            )
            state.nextDriveIndex = MatchupRules.maximumDrivesPerGame - 1
            state.situation.down = 4
            state.situation.distance = 10
            let completion = try! MatchReducer.reduce(.advance, state: &state).completion
            expect(completion?.record.winner != nil)
            expect(state.drives.count <= MatchupRules.maximumDrivesPerGame)
        }

        test("completion rejects evidence with a different call-in ledger") {
            let personnel = testPersonnel(offenseSkill: 68, defenseSkill: 68)
            var state = MatchReducer.start(tier: .pro, home: personnel, away: personnel,
                                            seed: 8_105)
            while !state.completed {
                _ = try! MatchReducer.reduce(.advance, state: &state)
            }
            guard let completion = state.completion else {
                expect(false, "completed match produced no receipt")
                return
            }
            var payload = try! JSONSerialization.jsonObject(
                with: JSONEncoder.stable().encode(completion)
            ) as! [String: Any]
            payload["callInReceipts"] = [["side": "home", "situation": NSNull(),
                                          "action": "attack", "trigger": "fourthDown"]]
            let tampered = try! JSONSerialization.data(withJSONObject: payload)
            do {
                _ = try JSONDecoder.stable().decode(MatchCompletionReceipt.self, from: tampered)
                expect(false, "mismatched call-in ledger was accepted")
            } catch {
                expect(true)
            }
        }

        test("detailed high-scoring summaries survive a save round trip") {
            let detailed = GameSummary(
                homeScore: 100,
                awayScore: 98,
                homeStatistics: TeamGameStatistics(
                    points: 100, offensiveYards: 600, passingYards: 400,
                    rushingYards: 200, turnovers: 0
                ),
                awayStatistics: TeamGameStatistics(
                    points: 98, offensiveYards: 590, passingYards: 390,
                    rushingYards: 200, turnovers: 0
                ),
                playerStatistics: [],
                source: .detailed
            )
            let reopened = try! JSONDecoder.stable().decode(
                GameSummary.self,
                from: JSONEncoder.stable().encode(detailed)
            )
            expectEqual(reopened, detailed)
        }

        test("controlled fixture pauses in the world and finalizes once") {
            let source = GameState.bootstrap(seed: 8_106)
            let programmeID = source.competition.currentSchedule.games.first(where: {
                $0.season == source.calendar.season
                    && $0.week == source.calendar.week
                    && $0.result == nil
            }).map { source.programmes[$0.homeID] != nil ? $0.homeID : $0.awayID }
                ?? source.programmes.ids[0]
            let started = try CareerControlSystem.startCollegeCareer(at: programmeID, in: source).state
            let prepared = try WorldScheduler.prepareControlledMatch(in: started)
            guard let checkpoint = prepared.matchSession,
                  let fixtureID = checkpoint.fixtureID else {
                expect(false, "the controlled fixture was abstracted instead of checkpointed")
                return
            }
            expectEqual(
                prepared.competition.currentSchedule.games.first { $0.id == fixtureID }?.result,
                nil
            )
            let reopened = try JSONDecoder.stable().decode(
                GameState.self,
                from: JSONEncoder.stable().encode(prepared)
            )
            expectEqual(reopened.matchSession, checkpoint)

            var finished = checkpoint
            while !finished.completed {
                let action: MatchAction = finished.pendingCallIn == nil
                    ? .advance
                    : .chooseCallIn(.trustCoordinator)
                _ = try! MatchReducer.reduce(action, state: &finished)
            }
            var completedState = prepared
            completedState.matchSession = finished
            let finalized = try WorldScheduler.finalizeControlledMatch(
                finished.completion!,
                in: completedState
            )
            expectEqual(finalized.matchSession, nil)
            let finalizedGame = finalized.competition.currentSchedule.games.first {
                $0.id == fixtureID
            }
            expect(finalizedGame?.result != nil)
            expectEqual(finalizedGame?.result?.source, .detailed)
            expectEqual(finalizedGame?.result?.evidence, finished.completion?.evidence)
            let reopenedSummary = try! JSONDecoder.stable().decode(
                GameSummary.self,
                from: JSONEncoder.stable().encode(finalizedGame!.result!)
            )
            expectEqual(reopenedSummary.evidence, finalizedGame?.result?.evidence)
            guard let aftermath = CoachWorldReadModelProvider.aftermath(from: finalized) else {
                expect(false, "finalized detailed evidence did not reach Aftermath")
                return
            }
            expectEqual(aftermath.provenance, .simulationSnapshot)
            expectEqual(aftermath.recordedOutcomeID, fixtureID.uuidString)

            // Persisted lines are a trust boundary: a hostile counter must stay within the
            // rules-owned, bounded rating projection rather than overflowing in the UI provider.
            guard let sourceLine = finalizedGame?.result?.playerStatistics.first,
                  let sourcePlayer = finalized.players[sourceLine.playerID] else {
                expect(false, "controlled evidence did not retain a player line")
                return
            }
            let hostileSummary = GameSummary(
                homeScore: finalizedGame!.result!.homeScore,
                awayScore: finalizedGame!.result!.awayScore,
                homeStatistics: finalizedGame!.result!.homeStatistics,
                awayStatistics: finalizedGame!.result!.awayStatistics,
                homeParticipantIDs: finalizedGame!.result!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.awayParticipantIDs,
                playerStatistics: [PlayerGameStatistics(
                    playerID: sourcePlayer.id,
                    passingYards: Int.max,
                    touchdowns: Int.max
                )],
                source: .detailed,
                evidence: finalizedGame!.result!.evidence
            )
            var hostileState = finalized
            var hostileGame = finalizedGame!
            hostileGame.result = hostileSummary
            expect(hostileState.competition.currentSchedule.replace(hostileGame))
            expectEqual(
                CoachWorldReadModelProvider.aftermath(from: hostileState)?.grades.first?.rating,
                SharedRules.ratingRange.upperBound
            )
            let participantIDs = Set(
                finalizedGame!.result!.homeParticipantIDs
                    + finalizedGame!.result!.awayParticipantIDs
            )
            guard let foreignPlayerID = finalized.players.ids.first(where: {
                !participantIDs.contains($0)
            }) else {
                expect(false, "controlled world did not retain a non-participant player")
                return
            }
            let foreignSummary = GameSummary(
                homeScore: finalizedGame!.result!.homeScore,
                awayScore: finalizedGame!.result!.awayScore,
                homeStatistics: finalizedGame!.result!.homeStatistics,
                awayStatistics: finalizedGame!.result!.awayStatistics,
                homeParticipantIDs: finalizedGame!.result!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.awayParticipantIDs,
                playerStatistics: [PlayerGameStatistics(playerID: foreignPlayerID)],
                source: .detailed,
                evidence: finalizedGame!.result!.evidence
            )
            var foreignState = finalized
            var foreignGame = finalizedGame!
            foreignGame.result = foreignSummary
            expect(foreignState.competition.currentSchedule.replace(foreignGame))
            expectEqual(
                CoachWorldReadModelProvider.aftermath(from: foreignState)?.grades,
                []
            )
            let foreignInjury = GameInjuryEvidence(
                playerID: foreignPlayerID,
                side: .home,
                area: .knee,
                severity: .minor,
                weeks: 1,
                occurredAt: finalized.calendar
            )
            let forgedEvidence = GameEvidence(
                fixtureID: fixtureID,
                record: finalizedGame!.result!.evidence!.record,
                homeParticipantIDs: finalizedGame!.result!.evidence!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.evidence!.awayParticipantIDs,
                callInReceipts: finalizedGame!.result!.evidence!.callInReceipts,
                injuries: [foreignInjury]
            )
            let injurySummary = GameSummary(
                homeScore: finalizedGame!.result!.homeScore,
                awayScore: finalizedGame!.result!.awayScore,
                homeStatistics: finalizedGame!.result!.homeStatistics,
                awayStatistics: finalizedGame!.result!.awayStatistics,
                homeParticipantIDs: finalizedGame!.result!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.awayParticipantIDs,
                playerStatistics: finalizedGame!.result!.playerStatistics,
                source: .detailed,
                evidence: forgedEvidence
            )
            var injuryState = finalized
            var injuryGame = finalizedGame!
            injuryGame.result = injurySummary
            expect(injuryState.competition.currentSchedule.replace(injuryGame))
            expectEqual(
                CoachWorldReadModelProvider.aftermath(from: injuryState)?.injuries,
                []
            )
            guard let evidenceOnlyPlayerID = finalizedGame!.result!.homeParticipantIDs.first else {
                expect(false, "controlled evidence did not retain a home participant")
                return
            }
            let evidenceOnlyInjury = GameInjuryEvidence(
                playerID: evidenceOnlyPlayerID,
                side: .home,
                area: .shoulder,
                severity: .minor,
                weeks: 1,
                occurredAt: finalized.calendar
            )
            let mismatchedParticipantsEvidence = GameEvidence(
                fixtureID: fixtureID,
                record: finalizedGame!.result!.evidence!.record,
                homeParticipantIDs: Array(finalizedGame!.result!.evidence!.homeParticipantIDs.dropFirst()),
                awayParticipantIDs: finalizedGame!.result!.evidence!.awayParticipantIDs,
                callInReceipts: finalizedGame!.result!.evidence!.callInReceipts,
                injuries: [evidenceOnlyInjury]
            )
            let mismatchedParticipantsSummary = GameSummary(
                homeScore: finalizedGame!.result!.homeScore,
                awayScore: finalizedGame!.result!.awayScore,
                homeStatistics: finalizedGame!.result!.homeStatistics,
                awayStatistics: finalizedGame!.result!.awayStatistics,
                homeParticipantIDs: finalizedGame!.result!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.awayParticipantIDs,
                playerStatistics: finalizedGame!.result!.playerStatistics,
                source: .detailed,
                evidence: mismatchedParticipantsEvidence
            )
            var mismatchedParticipantsState = finalized
            var mismatchedParticipantsGame = finalizedGame!
            mismatchedParticipantsGame.result = mismatchedParticipantsSummary
            expect(mismatchedParticipantsState.competition.currentSchedule.replace(mismatchedParticipantsGame))
            expectEqual(
                CoachWorldReadModelProvider.aftermath(from: mismatchedParticipantsState)?.injuries,
                []
            )
            let mismatchedEvidence = GameEvidence(
                fixtureID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                record: finalizedGame!.result!.evidence!.record,
                homeParticipantIDs: finalizedGame!.result!.evidence!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.evidence!.awayParticipantIDs,
                callInReceipts: finalizedGame!.result!.evidence!.callInReceipts
            )
            let mismatchedSummary = GameSummary(
                homeScore: finalizedGame!.result!.homeScore,
                awayScore: finalizedGame!.result!.awayScore,
                homeStatistics: finalizedGame!.result!.homeStatistics,
                awayStatistics: finalizedGame!.result!.awayStatistics,
                homeParticipantIDs: finalizedGame!.result!.homeParticipantIDs,
                awayParticipantIDs: finalizedGame!.result!.awayParticipantIDs,
                playerStatistics: finalizedGame!.result!.playerStatistics,
                source: .detailed,
                evidence: mismatchedEvidence
            )
            var mismatchedState = finalized
            var mismatchedGame = finalizedGame!
            mismatchedGame.result = mismatchedSummary
            expect(mismatchedState.competition.currentSchedule.replace(mismatchedGame))
            expectEqual(
                CoachWorldReadModelProvider.aftermath(from: mismatchedState),
                nil
            )
            expectEqual(
                finalized.history.recent.filter {
                    if case let .gameCompleted(gameID, _, _, _, _, _) = $0.payload,
                       gameID == fixtureID {
                        return true
                    }
                    return false
                }.count,
                1
            )
            do {
                _ = try WorldScheduler.finalizeControlledMatch(
                    finished.completion!,
                    in: finalized
                )
                expect(false, "a finalized controlled fixture was applied twice")
            } catch {
                expect(true)
            }
            do {
                let forged = MatchCompletionReceipt(
                    record: finished.completion!.record,
                    callInReceipts: []
                )
                _ = try WorldScheduler.finalizeControlledMatch(forged, in: completedState)
                expect(false, "a completion with a mismatched immutable ledger was accepted")
            } catch {
                expect(true)
            }
        }
    }
}

private struct PuntOnlyCaller: PlayCaller, Sendable {
    func offensiveCall(for situation: Situation, rules: any ClockRules.Type) -> OffensiveCall {
        OffensiveCall(playType: .punt)
    }

    func defensiveCall(for situation: Situation, rules: any ClockRules.Type) -> DefensiveCall {
        DefensiveCall(coverage: .zoneUnder, rushers: MatchupRules.baseRushers)
    }
}
