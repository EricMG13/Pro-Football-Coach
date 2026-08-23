"""The Swift screen registry, transcribed.

Generated once from `Sources/ProFootballCoachUI/ScreenRegistry.swift` and frozen here.
The transcription is deliberately a *copy*, not a parse: check 2 re-parses the Swift
independently and fails the build when the two disagree, which is the whole point. A
module that parsed the registry at build time would agree with itself forever.

62 registry numbers; 15 of them are aliases that route to a canonical sibling, leaving
47 canonical tasks. The twelve surfaces numbered 63-74 have no Swift case yet -- they
are declared in `registry/` with status MISSING and are the plan's remaining work.
"""

from __future__ import annotations

from dataclasses import dataclass

FAMILIES = (
    "weeklyCommand",
    "personnel",
    "recruiting",
    "proManagement",
    "league",
    "career",
    "entry",
)


@dataclass(frozen=True)
class Screen:
    number: int
    id: str
    name: str
    family: str
    #: The canonical sibling this number routes to, or None if it is itself canonical.
    alias_of: str | None = None

    @property
    def is_canonical(self) -> bool:
        return self.alias_of is None


SCREENS: tuple[Screen, ...] = (
    Screen( 1, "titleContinue", "Title / Continue", "career", None),
    Screen( 2, "newCareerCoachIdentity", "New Career & Coach Identity", "entry", None),
    Screen( 3, "jobBoard", "Job Board", "career", "careerHub"),
    Screen( 4, "offer", "Offer", "career", "careerHub"),
    Screen( 5, "appointment", "Appointment", "entry", "careerHub"),
    Screen( 6, "settingsAccessibility", "Settings & Accessibility", "career", None),
    Screen( 7, "worldSearch", "World Search", "league", None),
    Screen( 8, "coachingHQ", "Coaching HQ", "weeklyCommand", None),
    Screen( 9, "inbox", "Inbox", "weeklyCommand", None),
    Screen(10, "opponentReportFilmRoom", "Opponent Report / Film Room", "weeklyCommand", None),
    Screen(11, "gamePlan", "Game Plan", "weeklyCommand", None),
    Screen(12, "practicePlan", "Practice Plan", "weeklyCommand", None),
    Screen(13, "teamHealth", "Team Health", "weeklyCommand", None),
    Screen(14, "matchDay", "Match Day", "weeklyCommand", None),
    Screen(15, "aftermath", "Aftermath", "weeklyCommand", None),
    Screen(16, "roster", "Roster", "personnel", None),
    Screen(17, "depthChart", "Depth Chart", "personnel", None),
    Screen(18, "playerProfile", "Player Profile", "personnel", None),
    Screen(19, "developmentPlan", "Development Plan", "personnel", None),
    Screen(20, "staffRoom", "Staff Room", "personnel", None),
    Screen(21, "staffMarketProfile", "Staff Market & Profile", "personnel", "staffRoom"),
    Screen(22, "schemeBook", "Scheme Book", "personnel", "gamePlan"),
    Screen(23, "personnelPackages", "Personnel Packages", "personnel", "depthChart"),
    Screen(24, "recruitingBoard", "Recruiting Board", "recruiting", None),
    Screen(25, "prospectProfile", "Prospect Profile", "recruiting", None),
    Screen(26, "shortlist", "Shortlist", "recruiting", None),
    Screen(27, "contactVisitPlanner", "Contact & Visit Planner", "recruiting", None),
    Screen(28, "classOverview", "Class Overview", "recruiting", None),
    Screen(29, "signingDay", "Signing Day", "recruiting", None),
    Screen(30, "portalHub", "Portal Hub", "recruiting", "collegeOffseason"),
    Screen(31, "retentionDecisions", "Retention Decisions", "recruiting", "collegeOffseason"),
    Screen(32, "portalMarket", "Portal Market", "recruiting", "collegeOffseason"),
    Screen(33, "nilAllocation", "NIL Allocation", "recruiting", "collegeOffseason"),
    Screen(34, "capContracts", "Cap & Contracts", "proManagement", None),
    Screen(35, "contractNegotiation", "Contract Negotiation", "proManagement", None),
    Screen(36, "rosterCutsTransactions", "Roster Cuts & Transactions", "proManagement", None),
    Screen(37, "proScoutingBoard", "Pro Scouting Board", "proManagement", "proOffseason"),
    Screen(38, "draftBoard", "Draft Board", "proManagement", "proOffseason"),
    Screen(39, "draftRoom", "Draft Room", "proManagement", None),
    Screen(40, "freeAgency", "Free Agency", "proManagement", "proOffseason"),
    Screen(41, "leagueMap", "League Map", "league", None),
    Screen(42, "teamProgrammeProfile", "Team / Programme Profile", "league", None),
    Screen(43, "standings", "Standings", "league", None),
    Screen(44, "schedule", "Schedule", "league", None),
    Screen(45, "rankingsPlayoffPicture", "Rankings & Playoff Picture", "league", None),
    Screen(46, "bracketPostseason", "Bracket / Postseason", "league", None),
    Screen(47, "gameDetailBoxScore", "Game Detail / Box Score", "weeklyCommand", None),
    Screen(48, "statisticsLeaders", "Statistics & Leaders", "league", None),
    Screen(49, "awardsHonours", "Awards & Honours", "league", None),
    Screen(50, "news", "News", "league", None),
    Screen(51, "realignmentEvent", "Realignment Event", "league", None),
    Screen(52, "careerHub", "Career Hub", "career", None),
    Screen(53, "jobSecurity", "Job Security", "career", "careerHub"),
    Screen(54, "stakeholders", "Stakeholders", "career", None),
    Screen(55, "promotionDecision", "Promotion Decision", "career", None),
    Screen(56, "coachingCarousel", "Coaching Carousel", "career", "careerHub"),
    Screen(57, "recordBook", "Record Book", "career", None),
    Screen(58, "rivalries", "Rivalries", "career", None),
    Screen(59, "careerLine", "Career Line", "career", None),
    Screen(60, "coachingTree", "Coaching Tree", "career", None),
    Screen(61, "collegeOffseason", "College Offseason", "recruiting", None),
    Screen(62, "proOffseason", "Pro Offseason", "proManagement", None),
)

BY_ID = {s.id: s for s in SCREENS}
CANONICAL = tuple(s for s in SCREENS if s.is_canonical)
ALIASES = tuple(s for s in SCREENS if not s.is_canonical)


def siblings(family: str) -> tuple[Screen, ...]:
    """A family's canonical tasks, in registry order -- the header's sibling links."""
    return tuple(s for s in CANONICAL if s.family == family)
