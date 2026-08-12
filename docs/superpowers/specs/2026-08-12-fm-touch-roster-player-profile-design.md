# FM-Touch Personnel Example Screens

Date: 2026-08-12
Status: owner direction approved; implementation awaits written-spec review

## Goal

Build two connected SwiftUI examples for an iPhone Pro Max in landscape:

1. a dense roster workspace; and
2. a player-profile dossier opened from the selected roster row without losing roster context.

The examples use Football Manager Touch as a density and information-behaviour reference. They keep
the project's fictional identity, offline boundary, immutable UI projections, accessibility
contracts and existing Coach's World navigation.

## Chosen direction

Use a task-specific workspace system. Shared navigation, typography, table rhythm, rating cells and
state badges provide consistency. The roster remains a comparison table; the player profile remains
a person-led dossier. Neither screen is forced into a generic card dashboard.

The implementation will reuse existing Coach World components and tokens before adding anything.
No package or runtime dependency is required.

## Platform and adaptation

- Primary proof device: iPhone 17 Pro Max simulator, landscape.
- Minimum OS: iOS 26.
- The normal-size layout is optimized for the Pro Max viewport.
- The existing 844 x 390 landscape floor remains a regression check from the build plan.
- Default Dynamic Type uses the dense multi-pane composition.
- Accessibility sizes reflow into one scrolling reading order rather than clipping or shrinking text.
- The app remains iPhone-only and landscape-only.

## Screen 1: Roster

The dominant object is a sortable team sheet.

### Composition

- Existing world strip: programme, coach, season/week, record and Continue.
- Personnel-local route bar: Roster, Depth, Development and Staff. Only Roster is implemented in
  this example; unavailable routes remain visibly disabled rather than pretending to navigate.
- Compact summary ribbon: scholarship or roster count, class balance, injuries and open needs.
- Main roster table: number, player, position, year, role, overall, development, scheme fit and
  condition. Numeric columns use monospaced digits. Ratings use restrained heatmap cells with text
  values so color is never the only signal.
- Context inspector: selected player's identity, role, key strengths, concern, availability and an
  `Open dossier` action.

The table occupies 64 percent of the available width and the inspector 36 percent. Table cells use
28-point visual content inside 44-point semantic action rows, zero card spacing and hairline seams.
Selection, sorting and scrolling remain local to the screen.

### Interaction

- Tapping a row changes the inspector selection.
- Tapping a sortable heading toggles ascending/descending order and announces the new order.
- `Open dossier` presents the player profile contextually. Dismissing it restores the exact selected
  row, sort and scroll state.
- Continue and unavailable local routes follow the existing callback/status-receipt pattern.

## Screen 2: Player profile

The dominant object is the player, not a grid of equal cards.

### Composition

- Identity band: blank-photo fallback, name, number, position, year, hometown, roster role and
  availability.
- Compact local tabs: Overview, Attributes, Development and History. Overview is implemented for
  the example.
- Attribute body: three football-native groups—Athletic, Technical and Mental—with aligned rating
  cells, role-relevant highlights and uncertainty labels where the read model does not own an exact
  value.
- Evidence rail: position diagram, condition, recent form, scheme fit and staff summary.
- Bottom action area: one primary contextual action and secondary close/back control. It is not a
  generic fixed action rail.

On the Pro Max viewport, identity and attributes remain visible together. At accessibility sizes,
the evidence rail follows the attribute groups in a single vertical reading order.

### Interaction

- Tabs preserve the same player identity and profile context.
- Attribute cells expose label, value, category and evaluation confidence to VoiceOver.
- Closing the dossier returns to the roster with its prior state intact.

## Components and data flow

Use the existing world-strip, navigation, palette and blank-photo components where their contracts
fit. Add only the smallest personnel-specific views needed for the table, inspector, rating cell and
dossier layout.

`RosterReadModel` owns immutable team summary, stable player-row IDs and the profile projection for
each row. `PlayerProfileReadModel` owns identity, grouped attributes, condition, form, fit and staff
summary. SwiftUI owns only ephemeral presentation state: selected player, sort descriptor, active
profile tab and sheet presentation. No view imports, stores or derives `GameState`.

DEBUG sample data provides a coherent fictional roster and can open the roster directly for proof
capture. Production callbacks remain explicit so the sample UI cannot mutate simulation truth.

## Accessibility

- All controls use `Button` or native presentation APIs, never gesture-only activation.
- Controls meet the 44-point target contract even when their visible table content is denser.
- Text uses semantic styles and scaled metrics; normal-size micro-type remains within the project's
  10–12 point reference range while AX sizes reflow.
- Ratings combine number, label and color. State icons receive localized labels.
- Rows present a concise combined VoiceOver label and expose profile opening as a named action.
- Sort state, selection and sheet presentation remain usable with VoiceOver, Voice Control, Switch
  Control and Full Keyboard Access.
- Light/dark contrast, Increase Contrast, Differentiate Without Color and Reduce Motion are honored.

## Empty and failure states

- An empty roster shows one in-context explanation and no fabricated rows.
- A selected player missing from a refreshed projection clears the selection and chooses the first
  stable remaining row.
- An unavailable profile or stale action preserves roster state and reports the failure through the
  existing status receipt.
- Long names truncate visually but remain complete in accessibility labels.

## Verification

1. Build both Swift package targets and run the existing TestKit suite.
2. Add the smallest contract checks needed for stable row IDs, screen-registry coverage, design-token
   use and accessibility labels.
3. Launch the app on the installed iPhone Pro Max simulator in landscape.
4. Capture Roster and Player Profile in light/default and dark/AX5 configurations.
5. Inspect the accessibility hierarchy and manually verify selection, sorting, dossier presentation,
   dismissal and state restoration.
6. Run the project accessibility-matrix verification for the two registered screens.

## Explicitly excluded

- Production roster mutations, roster cuts, depth-chart editing and player development decisions.
- Portrait, iPad and Mac-specific compositions.
- Custom fonts, third-party table libraries, remote imagery and copied Football Manager assets.
- Additional personnel destinations beyond the two approved examples.
