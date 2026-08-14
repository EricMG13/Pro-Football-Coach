import Foundation

public struct PendingQueues: Codable, Sendable, Equatable {
    public static let maximumMandatoryDecisions = 512
    public private(set) var mandatoryDecisions: [MandatoryDecision]

    public init(mandatoryDecisions: [MandatoryDecision] = []) {
        precondition(
            Self.isValid(mandatoryDecisions),
            "Pending mandatory decisions are invalid."
        )
        self.mandatoryDecisions = mandatoryDecisions.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode([MandatoryDecision].self, forKey: .mandatoryDecisions)
        guard Self.isValid(decoded) else {
            throw DecodingError.dataCorruptedError(
                forKey: .mandatoryDecisions,
                in: container,
                debugDescription: "Pending mandatory decisions are invalid."
            )
        }
        mandatoryDecisions = decoded.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    @discardableResult
    public mutating func enqueue(_ decision: MandatoryDecision) -> Bool {
        guard mandatoryDecisions.count < Self.maximumMandatoryDecisions,
              !mandatoryDecisions.contains(where: { $0.id == decision.id }) else { return false }
        mandatoryDecisions.append(decision)
        mandatoryDecisions.sort { $0.id.uuidString < $1.id.uuidString }
        return true
    }

    @discardableResult
    mutating func removeDecision(id: UUID) -> MandatoryDecision? {
        guard let index = mandatoryDecisions.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return mandatoryDecisions.remove(at: index)
    }

    private static func isValid(_ decisions: [MandatoryDecision]) -> Bool {
        decisions.count <= maximumMandatoryDecisions
            && Set(decisions.map(\.id)).count == decisions.count
    }
}

/// The single authoritative root for a career save.
public struct GameState: Codable, Sendable, Equatable {
    public static let schemaVersion = 11

    public let version: Int
    public var league: League
    public let map: GameMap
    public var programmes: EntityStore<Programme>
    public var proTeams: EntityStore<ProTeam>
    public var players: EntityStore<Player>
    public var staff: EntityStore<Staff>
    public var identities: [UUID: TeamIdentity]
    public var rivalries: EntityStore<Rivalry>
    public var history: DomainEventLedger
    public var calendar: CalendarState {
        didSet { tactical.prepare(for: calendar) }
    }
    public var career: CareerControlState
    public var careerArc: CareerArcState
    public var pending: PendingQueues
    public var competition: CompetitionState
    public var people: PeopleState
    public var prospects: EntityStore<Prospect>
    public var college: CollegeState
    public var scouting: ScoutingState
    public var tactical: TacticalState
    public var proMarket: ProMarketState
    /// How hard this career is. `02` §3.16.
    ///
    /// **On the save, not on the device.** Difficulty decides the call-in rate, whether the week can
    /// be delegated and how fast a job is lost — all of which are properties of a career rather than
    /// of the phone it is played on, and none of which the engine could read from an app-layer
    /// settings file without breaking the separation `CLAUDE.md` fixes. `CoachWorldSettingsStore`
    /// keeps the *pre-career* choice, which is what a new save starts at; once a career exists this
    /// is authoritative.
    ///
    /// Optional and omitted when absent, so every save written before difficulty existed still
    /// decodes against a schema with no migration path, and a world that never set one encodes to
    /// exactly the bytes it did before.
    public var difficulty: DifficultySettings?

    /// The difficulty in force, which is the stated default when a save predates the setting.
    public var difficultyOrDefault: DifficultySettings { difficulty ?? .default }

    public init(
        version: Int = GameState.schemaVersion,
        league: League,
        map: GameMap,
        programmes: EntityStore<Programme>,
        proTeams: EntityStore<ProTeam>,
        players: EntityStore<Player> = EntityStore(),
        staff: EntityStore<Staff> = EntityStore(),
        identities: [UUID: TeamIdentity],
        rivalries: EntityStore<Rivalry>,
        history: DomainEventLedger,
        calendar: CalendarState,
        career: CareerControlState = CareerControlState(),
        careerArc: CareerArcState = CareerArcState(),
        pending: PendingQueues = PendingQueues(),
        competition: CompetitionState,
        people: PeopleState,
        prospects: EntityStore<Prospect> = EntityStore(),
        college: CollegeState,
        scouting: ScoutingState = ScoutingState(),
        tactical: TacticalState? = nil,
        proMarket: ProMarketState? = nil,
        difficulty: DifficultySettings? = nil
    ) {
        precondition(
            version == GameState.schemaVersion,
            "Game state construction requires the current schema version."
        )
        self.version = version
        self.league = league
        self.map = map
        self.programmes = programmes
        self.proTeams = proTeams
        self.players = players
        self.staff = staff
        self.identities = identities
        self.rivalries = rivalries
        self.history = history
        self.calendar = calendar
        self.career = career
        self.careerArc = careerArc
        self.pending = pending
        self.competition = competition
        self.people = people
        self.prospects = prospects
        self.college = college
        self.scouting = scouting
        self.tactical = tactical ?? TacticalState(calendar: calendar)
        self.proMarket = proMarket ?? ProMarketState(season: calendar.season)
        self.difficulty = difficulty
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decode(Int.self, forKey: .version)
        guard decodedVersion == GameState.schemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "The game-state schema version is unsupported."
            )
        }
        version = decodedVersion
        league = try container.decode(League.self, forKey: .league)
        map = try container.decode(GameMap.self, forKey: .map)
        programmes = try container.decode(EntityStore<Programme>.self, forKey: .programmes)
        proTeams = try container.decode(EntityStore<ProTeam>.self, forKey: .proTeams)
        players = try container.decode(EntityStore<Player>.self, forKey: .players)
        staff = try container.decode(EntityStore<Staff>.self, forKey: .staff)
        identities = try container.decode([UUID: TeamIdentity].self, forKey: .identities)
        rivalries = try container.decode(EntityStore<Rivalry>.self, forKey: .rivalries)
        history = try container.decode(DomainEventLedger.self, forKey: .history)
        calendar = try container.decode(CalendarState.self, forKey: .calendar)
        career = try container.decode(CareerControlState.self, forKey: .career)
        careerArc = try container.decode(CareerArcState.self, forKey: .careerArc)
        pending = try container.decode(PendingQueues.self, forKey: .pending)
        competition = try container.decode(CompetitionState.self, forKey: .competition)
        people = try container.decode(PeopleState.self, forKey: .people)
        prospects = try container.decode(EntityStore<Prospect>.self, forKey: .prospects)
        college = try container.decode(CollegeState.self, forKey: .college)
        scouting = try container.decode(ScoutingState.self, forKey: .scouting)
        tactical = try container.decode(TacticalState.self, forKey: .tactical)
        proMarket = try container.decode(ProMarketState.self, forKey: .proMarket)
        difficulty = try container.decodeIfPresent(DifficultySettings.self, forKey: .difficulty)

        let integrity = WorldIntegrity.check(self)
        guard integrity.isValid else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "The decoded game state has broken world invariants."
            )
        }
    }

    public static func bootstrap(seed: UInt64) -> GameState {
        let generated = LeagueGenerator.generate(seed: seed)
        let population = RosterPopulationGenerator.generate(
            seed: seed,
            season: generated.league.season,
            programmes: generated.programmes,
            proTeams: generated.proTeams
        )
        let staffPopulation = StaffPopulationGenerator.generate(
            seed: seed,
            programmes: generated.programmes,
            proTeams: generated.proTeams
        )
        let prospects = ProspectPopulationGenerator.generate(
            rootSeed: seed,
            season: generated.league.season,
            map: generated.map
        )
        var programmes = EntityStore(generated.programmes)
        for (id, rosterIDs) in population.programmeRosterIDs {
            programmes.update(id) {
                $0.rosterIDs = rosterIDs
                $0.scholarshipCount = CollegeRules.scholarshipLimit
                $0.staffIDs = staffPopulation.staffIDsByOrganisation[id] ?? []
            }
        }
        var proTeams = EntityStore(generated.proTeams)
        for (id, rosterIDs) in population.proRosterIDs {
            proTeams.update(id) {
                $0.rosterIDs = rosterIDs
                $0.staffIDs = staffPopulation.staffIDsByOrganisation[id] ?? []
            }
        }
        let calendar = CalendarState(season: generated.league.season, week: generated.league.week)
        var history = DomainEventLedger()
        history.append(DomainEvent(
            id: DomainEvent.deterministicID(rootSeed: seed, sequence: 0),
            sequence: 0,
            occurredAt: calendar,
            payload: .worldCreated(
                programmes: generated.programmes.count,
                proTeams: generated.proTeams.count
            )
        ))

        var state = GameState(
            league: generated.league,
            map: generated.map,
            programmes: programmes,
            proTeams: proTeams,
            players: EntityStore(population.players),
            staff: EntityStore(staffPopulation.staff),
            identities: generated.identities,
            rivalries: EntityStore(generated.rivalries),
            history: history,
            calendar: calendar,
            competition: CompetitionState.bootstrap(
                seed: seed,
                season: calendar.season,
                programmes: generated.programmes,
                proTeams: generated.proTeams
            ),
            people: PeopleState.bootstrap(
                players: population.players,
                staff: staffPopulation.staff,
                staffEmployerIDs: Dictionary(uniqueKeysWithValues:
                    staffPopulation.staffIDsByOrganisation.flatMap { organisationID, staffIDs in
                        staffIDs.map { ($0, organisationID) }
                    }
                ),
                season: calendar.season
            ),
            prospects: EntityStore(prospects),
            college: CollegeState.bootstrap(
                season: calendar.season,
                programmes: programmes.values,
                prospects: prospects
            ),
            proMarket: ProMarketState(season: calendar.season)
        )
        state.competition = CompetitionReducer.rebuild(from: state)
        return state
    }
}
