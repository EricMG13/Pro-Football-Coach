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
