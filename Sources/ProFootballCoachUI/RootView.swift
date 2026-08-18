import SwiftUI

public struct RootView: View {
    public init() {}

    public var body: some View {
#if DEBUG
        DebugCoachingHQRoot()
#else
        CoachWorldFloodlitStage(palette: CoachWorldTokens.dark) {
            CoachWorldSystemState(
                .empty("No career loaded. Start or load a career to enter the coach's world."),
                palette: CoachWorldTokens.dark
            )
        }
#endif
    }
}

#if DEBUG
private struct DebugCoachingHQRoot: View {
    @State private var currentScreen: CoachWorldScreenID
    @State private var coachingHQ = CoachWorldSampleData.coachingHQ
    @State private var recruitingBoard = CoachWorldSampleData.recruitingBoard
    @State private var recruitingProspectID: String?
    private let matchDay = CoachWorldSampleData.matchDay
    private let roster = CoachWorldSampleData.roster
    private let leagueMap = CoachWorldLeagueMapSampleData.leagueMap
    @State private var statusMessage: String?

    init() {
        let proofScreen = ProcessInfo.processInfo.environment["PROOF_SCREEN"]
        let entries: [(argument: String, proofName: String, screen: CoachWorldScreenID)] = [
            ("--player-profile", "player", .playerProfile),
            ("--roster", "roster", .roster),
            ("--match-day", "match", .matchDay),
            ("--recruiting-board", "recruiting", .recruitingBoard),
            ("--league-map", "map", .leagueMap),
        ]
        let requested = entries.first {
            CommandLine.arguments.contains($0.argument) || proofScreen == $0.proofName
        }
        _currentScreen = State(initialValue: requested?.screen ?? .coachingHQ)
    }

    var body: some View {
        Group {
            if currentScreen == .matchDay {
                MatchDayView(
                    model: matchDay,
                    statusMessage: statusMessage,
                    onControl: useMatchControl,
                    onInterruption: answerMatchInterruption,
                    onExit: { currentScreen = .coachingHQ }
                )
            } else if currentScreen == .playerProfile, let profile = roster.players.first?.profile {
                PlayerProfileView(
                    model: profile,
                    team: roster.team,
                    onClose: { currentScreen = .roster },
                    onInspectDevelopment: inspectDevelopment
                )
            } else if currentScreen == .roster {
                RosterView(
                    model: roster,
                    statusMessage: statusMessage,
                    onContinue: { statusMessage = "No later personnel event is available yet" },
                    onNavigate: navigate,
                    onInspectDevelopment: inspectDevelopment
                )
            } else if currentScreen == .recruitingBoard {
                RecruitingBoardView(
                    model: recruitingBoard,
                    statusMessage: statusMessage,
                    onAction: assignRecruitingWork,
                    onContinue: { statusMessage = "No later recruiting event is available yet" },
                    onNavigate: navigate,
                    onOpenProspect: { prospectID in
                        recruitingProspectID = prospectID
                        currentScreen = .prospectProfile
                    },
                    onOpenShortlist: { currentScreen = .shortlist }
                )
            } else if currentScreen == .prospectProfile {
                ProspectProfileView(
                    model: recruitingBoard,
                    prospectID: recruitingProspectID,
                    statusMessage: statusMessage,
                    onAction: assignRecruitingWork,
                    onClose: { currentScreen = .recruitingBoard }
                )
            } else if currentScreen == .shortlist {
                ShortlistView(
                    model: recruitingBoard,
                    statusMessage: statusMessage,
                    onOpenProspect: { prospectID in
                        recruitingProspectID = prospectID
                        currentScreen = .prospectProfile
                    },
                    onClose: { currentScreen = .recruitingBoard }
                )
            } else if currentScreen == .leagueMap {
                LeagueMapView(
                    model: leagueMap,
                    statusMessage: statusMessage,
                    onContinue: { statusMessage = "No later event is available yet" },
                    onNavigate: navigate
                )
            } else {
                CoachingHQView(
                    model: coachingHQ,
                    statusMessage: statusMessage,
                    onCommit: commit,
                    onInspect: { statusMessage = "Film opened · decision unchanged" },
                    onDelegate: delegate,
                    onPrepare: { statusMessage = "Balanced preparation delegated" },
                    onContinue: { statusMessage = "No later event is available yet" },
                    onOpenCorrespondence: openCorrespondence,
                    onNavigate: navigate
                )
            }
        }
        .background(CoachWorldTokens.dark.page.color)
        .preferredColorScheme(.dark)
    }

    private func commit(_ intentID: CoachWorldIntentID) {
        guard let choice = coachingHQ.decision?.choices.first(where: {
            $0.intentID == intentID
        }) else {
            statusMessage = "That practice choice is no longer available"
            return
        }
        resolveDecision(
            receipt: "\(choice.title) set · \(choice.cost) reserved",
            minutesSpent: 120
        )
    }

    private func delegate() {
        let staffName = coachingHQ.staffRecommendation?.staff.name ?? "The coordinator"
        resolveDecision(receipt: "\(staffName) owns Tuesday's first hour", minutesSpent: 60)
    }

    private func openCorrespondence(_ stableID: String) {
        guard let item = coachingHQ.correspondence.first(where: {
            $0.stableID == stableID
        }) else {
            statusMessage = "That message is no longer available"
            return
        }
        statusMessage = "\(item.subject) opened"
    }

    private func assignRecruitingWork(
        prospectID: String,
        intentID: CoachWorldIntentID
    ) {
        guard let prospect = (recruitingBoard.prospects + recruitingBoard.discovery).first(where: {
            $0.stableID == prospectID
        }), let choice = prospect.choices.first(where: {
            $0.intentID == intentID && $0.isAvailable
        }) else {
            statusMessage = "That recruiting action is no longer available"
            return
        }
        statusMessage = "\(choice.title) assigned to \(prospect.person.name) · \(choice.cost)"
    }

    private func useMatchControl(_ intentID: CoachWorldIntentID) {
        guard let control = matchDay.controls.first(where: {
            $0.intentID == intentID && $0.isEnabled
        }) else {
            statusMessage = "That match control is no longer available"
            return
        }
        statusMessage = "\(control.id.rawValue) selected · recorded moment unchanged"
    }

    private func answerMatchInterruption(_ intentID: CoachWorldIntentID) {
        guard let action = matchDay.staffInterruption?.actions.first(where: {
            $0.intentID == intentID && $0.isEnabled
        }) else {
            statusMessage = "That call-in response is no longer available"
            return
        }
        statusMessage = "\(action.title) · \(action.consequence)"
    }

    private func inspectDevelopment(_ profileID: String) {
        guard let player = roster.players.first(where: { $0.profile.stableID == profileID }) else {
            statusMessage = "That player profile is no longer available"
            return
        }
        statusMessage = "Development evidence opened for \(player.person.name) · no changes made"
    }

    private func navigate(_ screen: CoachWorldScreenID) {
        guard screen == .coachingHQ || screen == .recruitingBoard || screen == .roster
            || screen == .prospectProfile || screen == .shortlist || screen == .leagueMap else {
            statusMessage = "\(screen.canonicalName) is not available yet"
            return
        }
        currentScreen = screen
        statusMessage = nil
    }

    private func resolveDecision(receipt: String, minutesSpent: Int) {
        coachingHQ = CoachingHQReadModel(
            snapshotID: coachingHQ.snapshotID,
            provenance: coachingHQ.provenance,
            world: coachingHQ.world,
            team: coachingHQ.team,
            coach: coachingHQ.coach,
            recordLabel: coachingHQ.recordLabel,
            rankLabel: coachingHQ.rankLabel,
            venue: coachingHQ.venue,
            week: coachingHQ.week,
            weekPlan: coachingHQ.weekPlan,
            unallocatedPracticeMinutes: max(
                coachingHQ.unallocatedPracticeMinutes - minutesSpent,
                0
            ),
            opponent: coachingHQ.opponent,
            obligations: [],
            decision: nil,
            staffRecommendation: coachingHQ.staffRecommendation,
            correspondence: coachingHQ.correspondence
        )
        statusMessage = receipt
    }
}
#endif
