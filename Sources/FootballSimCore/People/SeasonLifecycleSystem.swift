import Foundation

/// The single college eligibility-return policy used by both recruiting projections and the
/// authoritative season rollover. Redshirt decisions will become an input to this policy rather
/// than introducing a second roster-vacancy calculation.
public enum CollegeEligibilityReturnPolicy {
    public static func advancedEligibility(
        for player: Player,
        redshirting: Bool = false
    ) -> Eligibility? {
        player.eligibility?.advanced(redshirting: redshirting)
    }

    public static func returnsAfterSeason(
        _ player: Player,
        redshirting: Bool = false
    ) -> Bool {
        advancedEligibility(for: player, redshirting: redshirting)?.isExhausted != true
    }
}

public enum PlayerDepartureReason: String, Codable, Sendable, CaseIterable, Hashable {
    case graduated
    case retired
}

public enum PlayerIntakeSource: String, Codable, Sendable, CaseIterable, Hashable {
    /// Temporary dependency bridge until M3 recruiting and M6 draft/free agency own intake.
    case provisionalReplacement
    case recruitedScholarship
    case walkOn
}

public struct PeopleSeasonTransition: Sendable, Equatable {
    public let programmes: EntityStore<Programme>
    public let proTeams: EntityStore<ProTeam>
    public let players: EntityStore<Player>
    public let staff: EntityStore<Staff>
    public let people: PeopleState
    /// Carried because a departure ends a scholarship. Returning the roster without the college
    /// state that records who holds one would leave the caller a root whose two scholarship
    /// counters disagree until something else repairs it.
    public let college: CollegeState
    public let eventPayloads: [DomainEventPayload]

    public init(
        programmes: EntityStore<Programme>,
        proTeams: EntityStore<ProTeam>,
        players: EntityStore<Player>,
        staff: EntityStore<Staff>,
        people: PeopleState,
        college: CollegeState,
        eventPayloads: [DomainEventPayload]
    ) {
        self.programmes = programmes
        self.proTeams = proTeams
        self.players = players
        self.staff = staff
        self.people = people
        self.college = college
        self.eventPayloads = eventPayloads
    }
}

public enum SeasonLifecycleError: Error, Sendable, Equatable {
    case completedCalendarMismatch
    case leagueCalendarMismatch
    case scheduleSeasonMismatch
    case collegeSeasonMismatch
}

public enum SeasonLifecycleSystem {
    public static func advance(
        after completed: CalendarState,
        in state: GameState
    ) throws -> PeopleSeasonTransition {
        guard completed == state.calendar else {
            throw SeasonLifecycleError.completedCalendarMismatch
        }
        guard state.league.season == state.calendar.season,
              state.league.week == state.calendar.week else {
            throw SeasonLifecycleError.leagueCalendarMismatch
        }
        guard state.competition.currentSchedule.season == completed.season else {
            throw SeasonLifecycleError.scheduleSeasonMismatch
        }
        guard state.college.recruitingSeason == completed.season else {
            throw SeasonLifecycleError.collegeSeasonMismatch
        }
        var programmes = state.programmes
        var proTeams = state.proTeams
        var players = state.players
        var staff = state.staff
        var people = state.people
        var college = state.college
        var payloads: [DomainEventPayload] = []
        var careerOwnedStaffIDs: Set<UUID> = []
        if let control = state.career.college {
            careerOwnedStaffIDs.insert(control.coachID)
            for owner in control.responsibilityOwners.values {
                if case let .delegated(staffID) = owner {
                    careerOwnedStaffIDs.insert(staffID)
                }
            }
        }

        if completed.week == SharedRules.inSeasonWeeks {
            advanceCollegePlayers(
                completed: completed,
                state: state,
                programmes: &programmes,
                players: &players,
                people: &people,
                college: &college,
                payloads: &payloads
            )
            advanceProPlayers(
                completed: completed,
                state: state,
                proTeams: &proTeams,
                players: &players,
                people: &people,
                payloads: &payloads
            )
            ageStaff(
                in: programmes,
                proTeams: proTeams,
                careerOwnedStaffIDs: careerOwnedStaffIDs,
                staff: &staff
            )
        }
        resolveStaffVacancies(
            season: completed.season + (completed.week == SharedRules.inSeasonWeeks ? 1 : 0),
            state: state,
            careerOwnedStaffIDs: careerOwnedStaffIDs,
            programmes: &programmes,
            proTeams: &proTeams,
            staff: &staff,
            people: &people,
            payloads: &payloads
        )
        if completed.week == SharedRules.inSeasonWeeks {
            // The one unbounded inflow in people state, bounded at the only moment it grows.
            // The protected set is read from the pre-transition root, so this season's departures
            // are still active identities there and survive their first prune by construction.
            people.pruneDepartedPlayers(protecting: retainedIdentityIDs(in: state))
            pruneSeatlessStaff(
                state: state,
                programmes: &programmes,
                proTeams: &proTeams,
                staff: &staff,
                people: &people
            )
        }
        return PeopleSeasonTransition(
            programmes: programmes,
            proTeams: proTeams,
            players: players,
            staff: staff,
            people: people,
            college: college,
            eventPayloads: payloads
        )
    }

    private static func pruneSeatlessStaff(
        state: GameState,
        programmes: inout EntityStore<Programme>,
        proTeams: inout EntityStore<ProTeam>,
        staff: inout EntityStore<Staff>,
        people: inout PeopleState
    ) {
        var projected = state
        projected.programmes = programmes
        projected.proTeams = proTeams
        projected.staff = staff
        projected.people = people
        let tree = CoachingTreeReadModel.build(from: projected)
        let namedByHistory = Set(
            tree.branches.flatMap { branch in
                [branch.mentorID] + branch.disciples.map(\.staffID)
            }
        )
        let seated = Set(
            programmes.values.flatMap(\.staffIDs)
                + proTeams.values.flatMap(\.staffIDs)
        )
        let protectedIDs = namedByHistory
            .union(seated)
            .union(retainedIdentityIDs(in: state))
            .union(state.career.coachID.map { [$0] } ?? [])
        for staffID in staff.ids where !protectedIDs.contains(staffID) {
            _ = staff.remove(staffID)
            _ = people.removeStaffCareer(staffID)
        }
    }

    /// Every identity a bounded departed set must keep, read from the authoritative root.
    ///
    /// Enumerated from the structures that name a person rather than from a hand-written list, so
    /// a new reference is covered the day the structure gains it: the retained event journal (both
    /// its generic entity references and its typed prospect references, which validate recruiting
    /// history), archived award winners, everyone still on a roster, and everyone whose portal
    /// window is still named by any live portal event — the last because `WorldIntegrity`
    /// cross-checks live-window event counts, retained capacity snapshots, and scouting knowledge
    /// against career records, and dropping one half of that pair would report as corruption.
    private static func retainedIdentityIDs(in state: GameState) -> Set<UUID> {
        var protectedIDs = Set(state.players.ids)
        var survivingPortalWindows = Set<PortalWindowKey>()
        for event in state.history.recent {
            let payload = event.payload
            protectedIDs.formUnion(payload.referencedEntityIDs)
            protectedIDs.formUnion(payload.referencedProspectIDs)
            if let portalWindow = payload.portalWindowReference {
                survivingPortalWindows.insert(
                    PortalWindowKey(
                        targetSeason: portalWindow.targetSeason,
                        window: portalWindow.window
                    )
                )
            }
        }
        for archive in state.competition.archives {
            for award in archive.awards {
                protectedIDs.insert(award.winnerID)
            }
        }
        // Every career with a record in a (season, window) that any surviving portal event still
        // names — not any career that ever touched the portal.
        //
        // `WorldIntegrity` recomputes a live window's entrant and offer counts from career records,
        // checks every retained offer's captured capacity, and checks exact NIL terms when a
        // completion summary proves every offer is present. Protecting only the player named by a
        // surviving event can therefore leave a partial live window whose aggregate no longer
        // reconciles. This reads the same bounded journal as the integrity checks, so a window falls
        // out of portal protection only once every portal event for it can no longer be consulted.
        if !survivingPortalWindows.isEmpty {
            for (playerID, career) in state.people.playerCareers {
                let matchesSurvivingWindow = career.portalWindows.contains {
                    survivingPortalWindows.contains(
                        PortalWindowKey(targetSeason: $0.targetSeason, window: $0.window)
                    )
                }
                if matchesSurvivingWindow {
                    protectedIDs.insert(playerID)
                }
            }
        }
        return protectedIDs
    }

    private struct PortalWindowKey: Hashable {
        let targetSeason: Int
        let window: CollegePortalWindow
    }

    private static func advanceCollegePlayers(
        completed: CalendarState,
        state: GameState,
        programmes: inout EntityStore<Programme>,
        players: inout EntityStore<Player>,
        people: inout PeopleState,
        college: inout CollegeState,
        payloads: inout [DomainEventPayload]
    ) {
        for programme in state.programmes.values {
            var retained: [UUID] = []
            for id in programme.rosterIDs {
                guard let player = players[id] else { continue }
                let redshirtResolution = CollegeRedshirtSystem.seasonResolution(
                    playerID: id,
                    programmeID: programme.id,
                    in: state,
                    season: completed.season,
                    college: state.college
                )
                let redshirting = redshirtResolution.outcome
                    == .preservedCompetitionSeason
                appendCareerSeason(
                    player: player,
                    organisationID: programme.id,
                    tier: .college,
                    season: completed.season,
                    state: state,
                    people: &people,
                    redshirtResolution: redshirtResolution
                )
                let appearances = state.competition.playerStatistics[id]?.games ?? 0
                if let plannedAppearanceLimit = redshirtResolution.plannedAppearanceLimit {
                    payloads.append(.redshirtResolved(
                        playerID: id,
                        programmeID: programme.id,
                        appearances: appearances,
                        plannedAppearanceLimit: plannedAppearanceLimit,
                        outcome: redshirtResolution.outcome
                    ))
                }
                var advanced = player
                advanced.age += 1
                advanced.eligibility = CollegeEligibilityReturnPolicy.advancedEligibility(
                    for: player,
                    redshirting: redshirting
                )
                if !CollegeEligibilityReturnPolicy.returnsAfterSeason(
                    player,
                    redshirting: redshirting
                ) {
                    people.updatePlayerLifecycle(id) { $0.endCareer(as: .graduated) }
                    people.updatePlayerCareer(id) {
                        $0.end(at: completed, status: .graduated)
                    }
                    payloads.append(.playerDeparted(
                        playerID: id,
                        organisationID: programme.id,
                        reason: .graduated
                    ))
                    people.archive(player: advanced, status: .graduated)
                    players.remove(id)
                } else {
                    players.update(id) { $0 = advanced }
                    retained.append(id)
                }
            }
            // The transaction that drops a departing player from the roster drops the
            // scholarship and the NIL allocation they were holding, in the same transaction.
            //
            // It used to leave both untouched and rely on `WorldScheduler` calling
            // `reconcileScholarships` several transactions later. Between the two, the root said a
            // graduated player still held a scholarship and the programme's own count disagreed
            // with the list that backs it — a breach opened and closed inside one weekly step,
            // which is exactly the interval a once-a-week integrity check cannot see.
            _ = college.updateProgramme(programme.id) {
                $0.retainScholarshipPlayers(on: retained)
                $0.reconcileNILRosterAllocations(with: retained)
            }
            let retainedScholarships = college.programmes[programme.id]?
                .scholarshipPlayerIDs.count ?? 0
            programmes.update(programme.id) {
                $0.rosterIDs = retained
                $0.scholarshipCount = retainedScholarships
            }
        }
        // Every plan has now been resolved into a career season and an advanced clock, so the
        // plans themselves are spent. `CollegeCycleSystem.closeAndOpen` cleared them several
        // transactions later, which left an interval where the root held a redshirt plan for a
        // player whose clock the very same step had just run out.
        college.clearResolvedRedshirtPlans()
    }

    private static func advanceProPlayers(
        completed: CalendarState,
        state: GameState,
        proTeams: inout EntityStore<ProTeam>,
        players: inout EntityStore<Player>,
        people: inout PeopleState,
        payloads: inout [DomainEventPayload]
    ) {
        for team in state.proTeams.values {
            var retained: [UUID] = []
            var departures: [Player] = []
            for id in team.rosterIDs {
                guard let player = players[id] else { continue }
                appendCareerSeason(
                    player: player,
                    organisationID: team.id,
                    tier: .pro,
                    season: completed.season,
                    state: state,
                    people: &people
                )
                var advanced = player
                advanced.age += 1
                if retires(advanced, season: completed.season, rootSeed: state.league.seed) {
                    departures.append(player)
                    people.updatePlayerLifecycle(id) { $0.endCareer(as: .retired) }
                    people.updatePlayerCareer(id) { $0.end(at: completed, status: .retired) }
                    payloads.append(.playerDeparted(
                        playerID: id,
                        organisationID: team.id,
                        reason: .retired
                    ))
                    people.archive(player: advanced, status: .retired)
                    players.remove(id)
                } else {
                    players.update(id) { $0 = advanced }
                    retained.append(id)
                }
            }
            let replacements = makeReplacements(
                departures: departures,
                organisationID: team.id,
                prestige: team.prestige,
                tier: .pro,
                season: completed.season + 1,
                rootSeed: state.league.seed,
                players: &players,
                people: &people,
                payloads: &payloads
            )
            proTeams.update(team.id) { $0.rosterIDs = retained + replacements }
        }
    }

    private static func appendCareerSeason(
        player: Player,
        organisationID: UUID,
        tier: Tier,
        season: Int,
        state: GameState,
        people: inout PeopleState,
        redshirtResolution: RedshirtSeasonResolution? = nil
    ) {
        let statistics = state.competition.playerStatistics[player.id]
        people.updatePlayerCareer(player.id) {
            $0.append(PlayerCareerSeason(
                season: season,
                organisationID: organisationID,
                tier: tier,
                games: statistics?.games ?? 0,
                starts: 0,
                overallAtEnd: player.overall,
                redshirtResolution: redshirtResolution
            ))
        }
    }

    private static func makeReplacements(
        departures: [Player],
        organisationID: UUID,
        prestige: Rating,
        tier: Tier,
        season: Int,
        rootSeed: UInt64,
        players: inout EntityStore<Player>,
        people: inout PeopleState,
        payloads: inout [DomainEventPayload]
    ) -> [UUID] {
        departures.enumerated().map { ordinal, departed in
            let replacement = RosterPopulationGenerator.replacement(
                rootSeed: rootSeed,
                season: season,
                organisationID: organisationID,
                position: departed.position,
                ordinal: ordinal,
                prestige: prestige,
                tier: tier
            )
            players.insert(replacement)
            people.insert(player: replacement)
            payloads.append(.playerJoined(
                playerID: replacement.id,
                organisationID: organisationID,
                source: .provisionalReplacement
            ))
            return replacement.id
        }
    }

    private static func retires(_ player: Player, season: Int, rootSeed: UInt64) -> Bool {
        let yearsAfterDecline = player.age - player.position.declineAge
        guard yearsAfterDecline >= 0 else { return false }
        if yearsAfterDecline >= PeopleRules.guaranteedRetirementYearsAfterDecline { return true }
        let seasonSeed = SeededRandom.derive(from: rootSeed, scope: .season, ordinal: season)
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: seasonSeed,
            scope: .personnel,
            identifier: player.id
        ))
        return rng.chance(
            Double(yearsAfterDecline + 1) * PeopleRules.retirementProbabilityPerYearAfterDecline
        )
    }

    private static func ageStaff(
        in programmes: EntityStore<Programme>,
        proTeams: EntityStore<ProTeam>,
        careerOwnedStaffIDs: Set<UUID>,
        staff: inout EntityStore<Staff>
    ) {
        let employed = Set(programmes.values.flatMap(\.staffIDs) + proTeams.values.flatMap(\.staffIDs))
        for id in employed {
            staff.update(id) {
                // ponytail: career markets will replace this bridge when user firing/retirement exists.
                $0.age = careerOwnedStaffIDs.contains(id)
                    ? min($0.age + 1, PeopleRules.staffAgeRange.upperBound)
                    : $0.age + 1
                $0.seasonsWithProgramme += 1
            }
        }
    }

    private static func resolveStaffVacancies(
        season: Int,
        state: GameState,
        careerOwnedStaffIDs: Set<UUID>,
        programmes: inout EntityStore<Programme>,
        proTeams: inout EntityStore<ProTeam>,
        staff: inout EntityStore<Staff>,
        people: inout PeopleState,
        payloads: inout [DomainEventPayload]
    ) {
        for programme in programmes.values {
            let resolved = resolvedStaffIDs(
                organisationID: programme.id,
                prestige: programme.prestige,
                existingIDs: programme.staffIDs,
                careerOwnedStaffIDs: careerOwnedStaffIDs,
                season: season,
                state: state,
                staff: &staff,
                people: &people,
                payloads: &payloads
            )
            programmes.update(programme.id) { $0.staffIDs = resolved }
        }
        for team in proTeams.values {
            let resolved = resolvedStaffIDs(
                organisationID: team.id,
                prestige: team.prestige,
                existingIDs: team.staffIDs,
                careerOwnedStaffIDs: careerOwnedStaffIDs,
                season: season,
                state: state,
                staff: &staff,
                people: &people,
                payloads: &payloads
            )
            proTeams.update(team.id) { $0.staffIDs = resolved }
        }
    }

    private static func resolvedStaffIDs(
        organisationID: UUID,
        prestige: Rating,
        existingIDs: [UUID],
        careerOwnedStaffIDs: Set<UUID>,
        season: Int,
        state: GameState,
        staff: inout EntityStore<Staff>,
        people: inout PeopleState,
        payloads: inout [DomainEventPayload]
    ) -> [UUID] {
        var retained = existingIDs.filter { id in
            guard let member = staff[id] else { return false }
            return careerOwnedStaffIDs.contains(id)
                || member.age <= PeopleRules.staffAgeRange.upperBound
        }
        let requirements: [(StaffRole, PositionGroup?)] = [
            (.headCoach, nil),
            (.offensiveCoordinator, nil),
            (.defensiveCoordinator, nil),
            (.specialTeamsCoordinator, nil),
            (.strengthCoordinator, nil),
        ] + PositionGroup.allCases.map { (.positionCoach, Optional($0)) }
        for (ordinal, requirement) in requirements.enumerated() {
            let present = retained.contains { id in
                staff[id]?.role == requirement.0 && staff[id]?.positionGroup == requirement.1
            }
            guard !present else { continue }
            let replacement = StaffPopulationGenerator.replacement(
                rootSeed: state.league.seed,
                season: season,
                organisationID: organisationID,
                prestige: prestige,
                role: requirement.0,
                positionGroup: requirement.1,
                ordinal: ordinal
            )
            staff.insert(replacement)
            people.insert(
                staff: replacement,
                assignment: StaffCareerAssignment(
                    season: season,
                    organisationID: organisationID,
                    role: replacement.role
                )
            )
            retained.append(replacement.id)
            payloads.append(.staffHired(
                staffID: replacement.id,
                organisationID: organisationID,
                role: replacement.role
            ))
        }
        return retained
    }
}
