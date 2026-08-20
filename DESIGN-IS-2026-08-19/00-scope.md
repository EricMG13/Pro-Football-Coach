# Scope

- **Audited product:** the current working-tree build of Pro Football Coach at `/Users/ericguei/Documents/Pro-Football-Coach` on branch `agent/floodlit-injury-evidence` (`be4f13a` plus the uncommitted UI changes present on 2026-08-19).
- **Audited surface:** all 62 `CoachWorldScreenID` entries in `Sources/ProFootballCoachUI/ScreenRegistry.swift:34-96`, including entry, weekly command, personnel, recruiting, professional management, league, and career families. Shared shell, navigation, design tokens, states, and accessibility behavior are part of the surface because they govern every screen.
- **Primary user:** one player acting as a football coach across a fictional college-to-professional career.
- **Primary task:** understand the current football state, make the next consequential coaching decision, and advance the career without losing context.
- **Constraints:** native SwiftUI; offline and single-player; iPhone-only, landscape-only, iOS 26+; no accounts, ads, analytics, IAP, subscriptions, third-party runtime dependencies, real-world identity assets, or direct arcade control. Floodlit is a dark-only presentation system. The accessibility floor includes AX5 reflow, VoiceOver, Reduce Motion, Reduce Transparency, Differentiate Without Color, meaningful 44 pt targets, and measured composited contrast.
- **Reference materials:** `README.md`; `docs/04-UX-AND-DESIGN-SYSTEM.md`; `docs/04b-AUDIT-RUBRIC.md`; `docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`; the current SwiftUI source; retained proof images under `docs/proofs/`; and the 2026-08-18 real-career critique and captures under `docs/reviews/2026-08-18-floodlit-exhaustive-design-critique.md` and `docs/proofs/2026-08-18-exhaustive-critique/`.
- **Evidence boundary:** current source and tests supersede older review claims when the implementation changed. The retained 2026-08-18 captures cover 21 live surfaces, not all 62; source-only visual claims are marked **INFERRED**. A clean cold-launch title capture was made for launch/appearance/attention measurements, but no current 62-screen screenshot set or interaction replay was produced.
- **Non-goals:** implementation changes, engine-design critique, competitive market review, and judging unfinished backend features except where the shipped UI exposes, hides, or misstates them.

## Screen inventory

1. Title / Continue
2. New Career & Coach Identity
3. Job Board
4. Offer
5. Appointment
6. Settings & Accessibility
7. World Search
8. Coaching HQ
9. Inbox
10. Opponent Report / Film Room
11. Game Plan
12. Practice Plan
13. Team Health
14. Match Day
15. Aftermath
16. Roster
17. Depth Chart
18. Player Profile
19. Development Plan
20. Staff Room
21. Staff Market & Profile
22. Scheme Book
23. Personnel Packages
24. Recruiting Board
25. Prospect Profile
26. Shortlist
27. Contact & Visit Planner
28. Class Overview
29. Signing Day
30. Portal Hub
31. Retention Decisions
32. Portal Market
33. NIL Allocation
34. Cap & Contracts
35. Contract Negotiation
36. Roster Cuts & Transactions
37. Pro Scouting Board
38. Draft Board
39. Draft Room
40. Free Agency
41. League Map
42. Team / Programme Profile
43. Standings
44. Schedule
45. Rankings & Playoff Picture
46. Bracket / Postseason
47. Game Detail / Box Score
48. Statistics & Leaders
49. Awards & Honours
50. News
51. Realignment Event
52. Career Hub
53. Job Security
54. Stakeholders
55. Promotion Decision
56. Coaching Carousel
57. Record Book
58. Rivalries
59. Career Line
60. Coaching Tree
61. College Offseason
62. Pro Offseason
