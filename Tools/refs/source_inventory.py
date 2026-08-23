"""The source inventory, transcribed from the "Two Registers" design artifact.

`claude.ai/code/artifact/34b9992d-8d69-40f0-a2f3-b8e1c15b3311`, read 2026-08-22. Its
inventory table assigns a lean ("lean") to all 62 registry numbers, and that
assignment is the design decision -- not this generator's to make. The first build of
this module invented five of them and flattened three of the four ceremony surfaces out
of the Broadcast lean entirely, which is how a document called "Two Registers"
ended up drawing one.

`state` is the source's own reading of the Swift (Built >=180 lines, Thin 100-179, Stub
under 100). It is recorded for comparison but NOT used: `Surface.status` is re-derived
from source with file:line evidence, because line count is not build state.
"""

from __future__ import annotations

#: registry number -> (lean, the source's build state)
SOURCE_LEAN: dict[int, tuple[str, str]] = {
     1: ("BROADCAST", "THIN"),  # Title / Continue
     2: ("DESK", "BUILT"),  # New Career & Coach Identity
     3: ("DESK", "ALIAS"),  # Job Board alias → Career Hub
     4: ("DOSSIER", "ALIAS"),  # Offer alias → Career Hub
     5: ("BROADCAST", "ALIAS"),  # Appointment alias → Career Hub
     6: ("DESK", "STUB"),  # Settings & Accessibility
     7: ("DESK", "BUILT"),  # World Search
     8: ("DESK", "BUILT"),  # Coaching HQ
     9: ("DESK", "BUILT"),  # Inbox
    10: ("DESK", "BUILT"),  # Opponent Report / Film Room
    11: ("DESK", "BUILT"),  # Game Plan
    12: ("DESK", "BUILT"),  # Practice Plan
    13: ("DESK", "BUILT"),  # Team Health
    14: ("MATCH_DAY", "BUILT"),  # Match Day
    15: ("BROADCAST", "BUILT"),  # Aftermath
    16: ("DESK", "BUILT"),  # Roster
    17: ("DESK", "BUILT"),  # Depth Chart
    18: ("DOSSIER", "BUILT"),  # Player Profile
    19: ("DESK", "BUILT"),  # Development Plan
    20: ("DESK", "BUILT"),  # Staff Room
    21: ("DOSSIER", "ALIAS"),  # Staff Market & Profile alias → Staff Room
    22: ("DESK", "ALIAS"),  # Scheme Book alias → Game Plan
    23: ("DESK", "ALIAS"),  # Personnel Packages alias → Depth Chart
    24: ("DESK", "BUILT"),  # Recruiting Board
    25: ("DOSSIER", "BUILT"),  # Prospect Profile
    26: ("DESK", "BUILT"),  # Shortlist
    27: ("DESK", "BUILT"),  # Contact & Visit Planner
    28: ("DESK", "BUILT"),  # Class Overview
    29: ("BROADCAST", "STUB"),  # Signing Day
    30: ("DESK", "ALIAS"),  # Portal Hub alias → College Offseason
    31: ("DESK", "ALIAS"),  # Retention Decisions alias → College Offseason
    32: ("DESK", "ALIAS"),  # Portal Market alias → College Offseason
    33: ("DESK", "ALIAS"),  # NIL Allocation alias → College Offseason
    34: ("DESK", "BUILT"),  # Cap & Contracts
    35: ("DOSSIER", "BUILT"),  # Contract Negotiation
    36: ("DESK", "BUILT"),  # Roster Cuts & Transactions
    37: ("DESK", "ALIAS"),  # Pro Scouting Board alias → Pro Offseason
    38: ("DESK", "ALIAS"),  # Draft Board alias → Pro Offseason
    39: ("BROADCAST", "STUB"),  # Draft Room
    40: ("DESK", "ALIAS"),  # Free Agency alias → Pro Offseason
    41: ("DESK", "BUILT"),  # League Map
    42: ("DOSSIER", "BUILT"),  # Team / Programme Profile
    43: ("DESK", "BUILT"),  # Standings
    44: ("DESK", "BUILT"),  # Schedule
    45: ("DESK", "BUILT"),  # Rankings & Playoff Picture
    46: ("DESK", "BUILT"),  # Bracket / Postseason
    47: ("DESK", "BUILT"),  # Game Detail / Box Score
    48: ("DESK", "THIN"),  # Statistics & Leaders
    49: ("BROADCAST", "THIN"),  # Awards & Honours
    50: ("DESK", "THIN"),  # News
    51: ("BROADCAST", "STUB"),  # Realignment Event
    52: ("DESK", "BUILT"),  # Career Hub
    53: ("DESK", "ALIAS"),  # Job Security alias → Career Hub
    54: ("DESK", "STUB"),  # Stakeholders
    55: ("BROADCAST", "STUB"),  # Promotion Decision
    56: ("DESK", "ALIAS"),  # Coaching Carousel alias → Career Hub
    57: ("DESK", "THIN"),  # Record Book
    58: ("DESK", "THIN"),  # Rivalries
    59: ("DESK", "THIN"),  # Career Line
    60: ("DESK", "THIN"),  # Coaching Tree
    61: ("DESK", "BUILT"),  # College Offseason
    62: ("DESK", "BUILT"),  # Pro Offseason
}


#: The twelve the source says must exist and do not: eight missing registry screens
#: (M1-M8, each needing a `CoachWorldScreenID` case) and four missing overlay layers
#: (O1-O4, which carry no screen ID because they render over any surface).
#:
#: Numbers 63-74 are this generator's; the source names the surfaces, not the rawValues.
#: The first build invented nine of these twelve without reading the list.
SOURCE_MISSING: dict[int, tuple[str, str, str, str]] = {
    63: ("M1", "Responsibilities", "career", "DESK"),
    64: ("M2", "Championship Result", "league", "BROADCAST"),
    65: ("M3", "Season Expectations", "career", "DOSSIER"),
    66: ("M4", "Season Review", "career", "BROADCAST"),
    67: ("M5", "While You Were Away", "weeklyCommand", "DESK"),
    68: ("M6", "Compare", "personnel", "DESK"),
    69: ("M7", "Save & Continuity", "career", "DESK"),
    70: ("M8", "Appearance", "career", "DESK"),
    71: ("O1", "First Run", "entry", "OVERLAY"),
    72: ("O2", "Teaching", "career", "OVERLAY"),
    73: ("O3", "Failure", "career", "OVERLAY"),
    74: ("O4", "System State", "career", "OVERLAY"),
}
