# Match Day walkthrough script (owner action)

P13 requires an owner orientation read that no test in the plan can answer. This is the script.
Nobody but the owner can run it, and **no agent may report it as done.**

The reason it exists: the landscape field rests on `04` §5.2's arithmetic plus a soccer precedent for
a sport with the opposite field ratio, and it runs against FM's community finding that the *vertical*
pitch reads better for structure. That is a presentation judgement, and no assertion in the suite
reaches it.

## Setup

1. Build and run on an iPhone 15-generation simulator or device, landscape.
2. Start a new career, advance to the first fixture, enter Match Day.
3. Advance one snap and watch it play.

## The questions P13 asks

1. **Does the field read as a football field on a phone?** Not "can you work out what it is" — does
   it read as one at a glance, in the frame it occupies?
2. **Is the line of scrimmage legible as a line?** Both it and the first-down line are drawn. Can you
   tell which is which without being told?
3. Does the animation read as the snap the lower third describes, or as decoration?
4. At 4x, is anything still legible?
5. Under Settings > Accessibility > Motion > Reduce Motion, does the discrete path still tell you
   what happened?

## Already found by looking, 2026-08-17 — do not re-report these

A demonstration run on an iPhone 17 Pro Max simulator surfaced three defects. They are recorded in
`docs/STATUS.md` and are not fixed. Knowing them lets the read concentrate on what is genuinely
unanswered.

1. ~~The markers describe the next snap while the animation replays the last one.~~ **Fixed.** The
   field's lines now come from the same `PlayRecord` as its dots. The older conversion bug beneath it
   — offense-relative yards written straight into drawn-field space — is fixed too.
2. ~~The pre-snap field draws twenty-two dots in one vertical column.~~ **Fixed.** The pre-snap field
   uses the same §9.4 template as the animation, so both agree by construction.
3. Dots are 20 pt and overlap heavily across the interior line. **Still open** — the formation fix
   spreads them laterally and helps, but the interior line still stacks.

## Known limits of what you are looking at

State these before judging, so the read is about the right things:

- **Alignment is a template, not recorded data.** Per-snap alignment is not in the record; `03` §9.4
  explains why and what the starts are derived from instead. Formations will look generically
  correct rather than specific to the call — the same shape every snap, whatever was called.
- **Movement is sparse.** Blockers hold, rushers converge, the carrier runs to the end spot, route
  runners go to the recorded air-yard depth. Nothing else moves, because nothing else is recorded.
  `04` §9 prohibits inventing the rest.
- **One snap at a time.** Continuous drive playback and key-moment scrubbing are not in this slice.

## What to report back

For each question: yes, no, or "nearly, but". A "nearly, but" is the useful answer and the one the
next slice will act on.
