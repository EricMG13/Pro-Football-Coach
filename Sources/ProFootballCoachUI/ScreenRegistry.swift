/// The six management families plus entry, `FLOODLIT-SURFACES.md` section 3.
///
/// This is what the identity header's second row names, and what its sibling links enumerate.
/// `entry` covers the surfaces that reach the world before a coaching week exists; they carry no
/// family navigation because there is nowhere sideways to go from them yet.
public enum CoachWorldSurfaceFamily: String, CaseIterable, Sendable, Equatable {
    case weeklyCommand
    case personnel
    case recruiting
    case proManagement
    case league
    case career
    case entry

    /// Written sentence case and uppercased on render, per `04` section 6.1c's Label3 rule.
    public var canonicalName: String {
        switch self {
        case .weeklyCommand: "This week"
        case .personnel: "Personnel"
        case .recruiting: "Recruiting"
        case .proManagement: "Pro management"
        case .league: "League"
        case .career: "Career"
        case .entry: "Entry"
        }
    }

    /// The family's surfaces, in registry order — the header's sibling links.
    public var surfaces: [CoachWorldScreenID] {
        CoachWorldScreenID.allCases.filter { $0.family == self }
    }
}

public enum CoachWorldScreenID: Int, CaseIterable, Sendable {
    case titleContinue = 1
    case newCareerCoachIdentity = 2
    case jobBoard = 3
    case offer = 4
    case appointment = 5
    case settingsAccessibility = 6
    case worldSearch = 7
    case coachingHQ = 8
    case inbox = 9
    case opponentReportFilmRoom = 10
    case gamePlan = 11
    case practicePlan = 12
    case teamHealth = 13
    case matchDay = 14
    case aftermath = 15
    case roster = 16
    case depthChart = 17
    case playerProfile = 18
    case developmentPlan = 19
    case staffRoom = 20
    case staffMarketProfile = 21
    case schemeBook = 22
    case personnelPackages = 23
    case recruitingBoard = 24
    case prospectProfile = 25
    case shortlist = 26
    case contactVisitPlanner = 27
    case classOverview = 28
    case signingDay = 29
    case portalHub = 30
    case retentionDecisions = 31
    case portalMarket = 32
    case nilAllocation = 33
    case capContracts = 34
    case contractNegotiation = 35
    case rosterCutsTransactions = 36
    case proScoutingBoard = 37
    case draftBoard = 38
    case draftRoom = 39
    case freeAgency = 40
    case leagueMap = 41
    case teamProgrammeProfile = 42
    case standings = 43
    case schedule = 44
    case rankingsPlayoffPicture = 45
    case bracketPostseason = 46
    case gameDetailBoxScore = 47
    case statisticsLeaders = 48
    case awardsHonours = 49
    case news = 50
    case realignmentEvent = 51
    case careerHub = 52
    case jobSecurity = 53
    case stakeholders = 54
    case promotionDecision = 55
    case coachingCarousel = 56
    case recordBook = 57
    case rivalries = 58
    case careerLine = 59
    case coachingTree = 60
    case collegeOffseason = 61
    case proOffseason = 62

    public var number: Int { rawValue }

    /// Which family a surface belongs to (`FLOODLIT-SURFACES.md` section 3).
    ///
    /// The identity header's second row is the whole of this game's navigation: the family name,
    /// then that family's siblings as links. So the grouping has to live somewhere both the header
    /// and the icon rail can read, and the registry is the only thing that already knows every
    /// surface. Derived from the screen rather than stored beside it, so a new case cannot be added
    /// without the compiler asking which family it joins.
    public var family: CoachWorldSurfaceFamily {
        switch self {
        case .coachingHQ, .inbox, .opponentReportFilmRoom, .gamePlan, .practicePlan,
             .teamHealth, .matchDay, .aftermath, .gameDetailBoxScore:
            return .weeklyCommand
        case .roster, .depthChart, .playerProfile, .developmentPlan, .staffRoom,
             .staffMarketProfile, .schemeBook, .personnelPackages:
            return .personnel
        case .recruitingBoard, .prospectProfile, .shortlist, .contactVisitPlanner,
             .classOverview, .signingDay, .portalHub, .retentionDecisions, .portalMarket,
             .nilAllocation, .collegeOffseason:
            return .recruiting
        case .capContracts, .contractNegotiation, .rosterCutsTransactions, .proOffseason,
             .proScoutingBoard, .draftBoard, .draftRoom, .freeAgency:
            return .proManagement
        case .leagueMap, .teamProgrammeProfile, .standings, .schedule, .rankingsPlayoffPicture,
             .bracketPostseason, .statisticsLeaders, .awardsHonours, .news, .realignmentEvent,
             .worldSearch:
            return .league
        case .careerHub, .careerLine, .jobSecurity, .stakeholders, .promotionDecision,
             .jobBoard, .offer, .recordBook, .rivalries, .titleContinue,
             .settingsAccessibility, .coachingCarousel, .coachingTree:
            return .career
        case .newCareerCoachIdentity, .appointment:
            return .entry
        }
    }

    /// The short form the identity header's sibling row prints (`FLOODLIT-SURFACES.md` §1).
    ///
    /// Distinct from `canonicalName`, which is the registry's full title and stays the accessible
    /// name. The reference prints `FILM ROOM`, `PLAYER`, `DEVELOPMENT` where the registry says
    /// "Opponent Report / Film Room", "Player Profile", "Development Plan" — the long forms
    /// overflow a 16 pt row and push the rest of the family off the end of it.
    public var navigationName: String {
        switch self {
        case .coachingHQ: "Hub"
        case .opponentReportFilmRoom: "Film room"
        case .practicePlan: "Practice"
        case .gamePlan: "Game plan"
        case .gameDetailBoxScore: "Box score"
        case .playerProfile: "Player"
        case .developmentPlan: "Development"
        case .staffMarketProfile: "Staff market"
        case .personnelPackages: "Packages"
        case .recruitingBoard: "Board"
        case .prospectProfile: "Prospect"
        case .contactVisitPlanner: "Visits"
        case .classOverview: "Class"
        case .retentionDecisions: "Retention"
        case .nilAllocation: "NIL"
        case .collegeOffseason: "Offseason"
        case .capContracts: "Cap"
        case .contractNegotiation: "Negotiation"
        case .rosterCutsTransactions: "Roster cuts"
        case .proScoutingBoard: "Pro scouting"
        case .rankingsPlayoffPicture: "Rankings"
        case .bracketPostseason: "Bracket"
        case .statisticsLeaders: "Statistics"
        case .awardsHonours: "Awards"
        case .realignmentEvent: "Realignment"
        case .teamProgrammeProfile: "Team"
        case .leagueMap: "Map"
        case .settingsAccessibility: "Settings"
        case .newCareerCoachIdentity: "Coach identity"
        case .promotionDecision: "Promotion"
        case .coachingCarousel: "Carousel"
        case .titleContinue: "Title"
        default: canonicalName
        }
    }

    /// The three surfaces that sit outside the coaching week and so carry no icon rail
    /// (`FLOODLIT-SURFACES.md` section 3). They start at the rail-free leading edge instead.
    public var showsIconRail: Bool {
        switch self {
        case .titleContinue, .jobBoard, .offer: false
        default: true
        }
    }

    public var canonicalName: String {
        switch self {
        case .titleContinue: return "Title / Continue"
        case .newCareerCoachIdentity: return "New Career & Coach Identity"
        case .jobBoard: return "Job Board"
        case .offer: return "Offer"
        case .appointment: return "Appointment"
        case .settingsAccessibility: return "Settings & Accessibility"
        case .worldSearch: return "World Search"
        case .coachingHQ: return "Coaching HQ"
        case .inbox: return "Inbox"
        case .opponentReportFilmRoom: return "Opponent Report / Film Room"
        case .gamePlan: return "Game Plan"
        case .practicePlan: return "Practice Plan"
        case .teamHealth: return "Team Health"
        case .matchDay: return "Match Day"
        case .aftermath: return "Aftermath"
        case .roster: return "Roster"
        case .depthChart: return "Depth Chart"
        case .playerProfile: return "Player Profile"
        case .developmentPlan: return "Development Plan"
        case .staffRoom: return "Staff Room"
        case .staffMarketProfile: return "Staff Market & Profile"
        case .schemeBook: return "Scheme Book"
        case .personnelPackages: return "Personnel Packages"
        case .recruitingBoard: return "Recruiting Board"
        case .prospectProfile: return "Prospect Profile"
        case .shortlist: return "Shortlist"
        case .contactVisitPlanner: return "Contact & Visit Planner"
        case .classOverview: return "Class Overview"
        case .signingDay: return "Signing Day"
        case .portalHub: return "Portal Hub"
        case .retentionDecisions: return "Retention Decisions"
        case .portalMarket: return "Portal Market"
        case .nilAllocation: return "NIL Allocation"
        case .capContracts: return "Cap & Contracts"
        case .contractNegotiation: return "Contract Negotiation"
        case .rosterCutsTransactions: return "Roster Cuts & Transactions"
        case .proScoutingBoard: return "Pro Scouting Board"
        case .draftBoard: return "Draft Board"
        case .draftRoom: return "Draft Room"
        case .freeAgency: return "Free Agency"
        case .leagueMap: return "League Map"
        case .teamProgrammeProfile: return "Team / Programme Profile"
        case .standings: return "Standings"
        case .schedule: return "Schedule"
        case .rankingsPlayoffPicture: return "Rankings & Playoff Picture"
        case .bracketPostseason: return "Bracket / Postseason"
        case .gameDetailBoxScore: return "Game Detail / Box Score"
        case .statisticsLeaders: return "Statistics & Leaders"
        case .awardsHonours: return "Awards & Honours"
        case .news: return "News"
        case .realignmentEvent: return "Realignment Event"
        case .careerHub: return "Career Hub"
        case .jobSecurity: return "Job Security"
        case .stakeholders: return "Stakeholders"
        case .promotionDecision: return "Promotion Decision"
        case .coachingCarousel: return "Coaching Carousel"
        case .recordBook: return "Record Book"
        case .rivalries: return "Rivalries"
        case .careerLine: return "Career Line"
        case .coachingTree: return "Coaching Tree"
        case .collegeOffseason: return "College Offseason"
        case .proOffseason: return "Pro Offseason"
        }
    }
}
