import Foundation

/// One programme that was in the race for a recruit, named.
public struct PlayerDossierContender: Sendable, Equatable, Identifiable {
    public var id: UUID { programmeID }
    public let programmeID: UUID
    public let name: String
    public let interest: Int
    public let nilAllocation: Int

    public init(programmeID: UUID, name: String, interest: Int, nilAllocation: Int) {
        self.programmeID = programmeID
        self.name = name
        self.interest = interest
        self.nilAllocation = nilAllocation
    }
}

/// How the player arrived, and what the programme believed at the time.
public struct PlayerDossierRecruitment: Sendable, Equatable {
    public let signedAt: CalendarState
    public let originCityID: UUID
    public let signedBy: PlayerDossierContender
    /// The programme that held the commitment before the flip, when there was one. `02` §8's
    /// prompt for this is the coach who remembers taking a recruit off a rival.
    public let flippedFrom: PlayerDossierContender?
    public let runnerUp: PlayerDossierContender?
    /// How many times the commitment changed hands before signing day.
    public let commitmentChanges: Int
    public let overallAtSigning: Rating
    public let scouting: ProspectScoutingSnapshot?

    public init(
        signedAt: CalendarState,
        originCityID: UUID,
        signedBy: PlayerDossierContender,
        flippedFrom: PlayerDossierContender?,
        runnerUp: PlayerDossierContender?,
        commitmentChanges: Int,
        overallAtSigning: Rating,
        scouting: ProspectScoutingSnapshot?
    ) {
        self.signedAt = signedAt
        self.originCityID = originCityID
        self.signedBy = signedBy
        self.flippedFrom = flippedFrom
        self.runnerUp = runnerUp
        self.commitmentChanges = commitmentChanges
        self.overallAtSigning = overallAtSigning
        self.scouting = scouting
    }

    /// What the estimate got wrong, signed so a reader can tell over- from under-rating. `nil` when
    /// the programme never scouted the player.
    public var scoutingError: Int? {
        scouting.map { overallAtSigning.value - $0.estimatedOverall.value }
    }

    /// Whether the truth fell inside the band the coach was shown at signing.
    public var scoutingBandHeld: Bool? {
        scouting.map { $0.bandContained(overallAtSigning) }
    }
}

/// Everything the save can honestly say about one player.
///
/// **Deliberately not `Codable`**, following `CoachingTreeReadModel`: `PeopleState` is the authority
/// and is already bounded, and a persisted second copy becomes a second authority that can disagree
/// with the first. Rebuilt on demand, one player at a time — built per-player rather than as a sweep
/// because a dossier is opened for someone, and a whole-world build would pay `NewsFeedReadModel`'s
/// full name-dictionary cost on every open.
public struct PlayerDossier: Sendable, Equatable, Identifiable {
    public var id: UUID { playerID }
    public let playerID: UUID
    public let name: String
    public let position: Position
    /// `nil` while the player is still active.
    public let departedAs: PlayerLifecycleStatus?
    public let recruitment: PlayerDossierRecruitment?
    public let seasons: [PlayerCareerSeason]
    public let developmentBeats: [DevelopmentBeat]
    public let portalWindows: [CollegePortalWindowRecord]

    public init(
        playerID: UUID,
        name: String,
        position: Position,
        departedAs: PlayerLifecycleStatus?,
        recruitment: PlayerDossierRecruitment?,
        seasons: [PlayerCareerSeason],
        developmentBeats: [DevelopmentBeat],
        portalWindows: [CollegePortalWindowRecord]
    ) {
        self.playerID = playerID
        self.name = name
        self.position = position
        self.departedAs = departedAs
        self.recruitment = recruitment
        self.seasons = seasons
        self.developmentBeats = developmentBeats
        self.portalWindows = portalWindows
    }

    public var isActive: Bool { departedAs == nil }

    /// Rating movement across the whole career, when both ends are known.
    ///
    /// Measured signing-to-latest-season rather than summed from `developmentBeats`: the ring is
    /// lossy by design, so adding it up would understate a long career and silently disagree with
    /// the season history.
    public var careerRatingDelta: Int? {
        guard let start = recruitment?.overallAtSigning.value,
              let end = seasons.last?.overallAtEnd.value else { return nil }
        return end - start
    }

    /// The single most significant development week, if the player had one.
    public var definingBeat: DevelopmentBeat? {
        developmentBeats.max { $0.significance < $1.significance }
    }
}

public enum PlayerDossierReadModel {
    /// Builds the dossier for one player, active or departed.
    ///
    /// Returns `nil` only when the identifier is not a player this world has ever had. A player who
    /// left is still a dossier — losing them from the roster is not losing them from the record, and
    /// `02` §8 wants the coach to be able to look up who they let go.
    public static func build(for playerID: UUID, in state: GameState) -> PlayerDossier? {
        guard let career = state.people.playerCareers[playerID] else { return nil }

        let name: String
        let position: Position
        let departedAs: PlayerLifecycleStatus?
        if let player = state.players[playerID] {
            name = player.fullName
            position = player.position
            // The career record's own end status is the authority, not roster presence: a player can
            // sit in `players` during the week they retire.
            departedAs = career.endStatus
        } else if let departed = state.people.departedPlayers[playerID] {
            name = departed.fullName
            position = departed.position
            departedAs = departed.status
        } else {
            return nil
        }

        return PlayerDossier(
            playerID: playerID,
            name: name,
            position: position,
            departedAs: departedAs,
            recruitment: career.recruitingOrigin.map { recruitment($0, in: state) },
            seasons: career.seasons,
            developmentBeats: career.developmentBeats,
            portalWindows: career.portalWindows
        )
    }

    private static func recruitment(
        _ origin: PlayerRecruitingOrigin,
        in state: GameState
    ) -> PlayerDossierRecruitment {
        PlayerDossierRecruitment(
            signedAt: origin.signedAt,
            originCityID: origin.originCityID,
            signedBy: contender(origin.winnerContext, in: state),
            // `previousWinner` is the flip: whoever held the commitment before the programme that
            // signed them. Read from the final commitment rather than the first, because a recruit
            // can change their mind more than once and only the last change is the one that stuck.
            flippedFrom: origin.commitmentHistory.last?.previousWinner
                .map { contender($0, in: state) },
            runnerUp: origin.runnerUpContext.map { contender($0, in: state) },
            commitmentChanges: max(0, origin.commitmentHistory.count - 1),
            overallAtSigning: origin.overallAtSigning,
            scouting: origin.scoutingAtSigning
        )
    }

    private static func contender(
        _ context: RecruitingCommitmentContenderContext,
        in state: GameState
    ) -> PlayerDossierContender {
        PlayerDossierContender(
            programmeID: context.programmeID,
            // Two lookups rather than a name dictionary: a dossier names at most three programmes,
            // and building the world-wide map to answer three questions is the cost centre
            // `NewsFeedReadModel.names(in:)` already pays on every build.
            name: state.programmes[context.programmeID]?.name
                ?? state.proTeams[context.programmeID]?.name
                ?? "Unknown",
            interest: context.relationshipInterest,
            nilAllocation: context.nilAllocation
        )
    }
}
