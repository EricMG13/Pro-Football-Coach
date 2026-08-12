# M6 — professional management

## Goal

Give a promoted coach a truthful, cap-safe professional roster transaction boundary without creating
a second ownership or money ledger.

## Delivered in the transaction slice

- `ProManagementSystem.capSnapshot` derives cap, dead money, committed hits, and remaining cap from
  the existing `Player.contract` and `ProTeam` fields using integer arithmetic.
- `acquire` supports both free-agent and draft-labelled acquisitions, validates the player tier,
  ownership, roster opening, contract shape, and cap before committing a copied root.
- `release` removes active/practice ownership, clears the contract, and carries all uncharged signing
  bonus into team dead money.
- `draftOrder` is deterministic and uses the last archived pro ranking when available, with UUID
  order as the pre-archive fallback.
- `CoachIntent.proManagement` is legal only for a promoted professional `CareerArcState` job and
  returns an immutable cap receipt; a college-controlled root is rejected.

## M6A — persistent market activation

- Schema 10 persists a bounded `ProMarketState` with free-agency, draft, and roster-build phases,
  deterministic 224-player classes, snake draft order, capped free-agent IDs, observer-specific
  scouting observations, and a bounded closed-market prospect identity archive.
- `ProMarketSystem` opens the next-season market, records deterministic scouting, signs free
  agents, consumes draft picks, generates rookie contracts, and closes phases atomically.
- `CoachIntent.proMarket` is the professional authority boundary for opening, scouting, drafting,
  free-agent signing, and closing; each action emits a typed domain event.
- Final-week scheduler rollover closes any prior market before postseason projection, opens the next
  market after college portal/cycle work, and keeps two-season replays deterministic.
- Root integrity validates phase shape, draft order, prospect identity, free-agent ownership/cap
  eligibility, scouting references, calendar season, retained market identities, and dated waiver
  ownership/deadline records.

## M6B — roster movement

- Practice-squad moves, promotion, active-roster trades, waiver placement/claims, and expired-waiver
  release are copied-root transactions with cap and ownership validation.
- The promoted-coach intent boundary covers every movement action and emits typed domain events;
  weekly market steps resolve expired waivers before ordinary rollover and spring work.
- Waivers require a contracted professional, preserve the claim window, and return released players
  to the bounded free-agent ledger without mutating a rejected root.

## M6C — contract lifecycle and professional roster policy

- Market signings and draft acquisitions carry an optional authoritative start season; legacy
  contracts remain readable but are never expired from guessed dates.
- Season-aware cap hits and dead-money proration apply to sourced contracts; completed deals expire
  atomically at the final-week rollover and return the player to the bounded free-agent ledger.
- A deterministic professional roster policy signs at most one highest-rated legal free agent per
  AI team per week, skips the controlled professional team, and emits the typed signing event.
- A short both-tier scheduler/save check exercises professional AI alongside the college pipeline.

## Evidence

- M6 market gate: 12 tests / 58 checks.
- Portal scheduler compatibility: 9 tests / 27,823 checks.
- Portal contracts: 28 tests / 138 checks.
- Core contracts: 144 tests / 880 checks.
- Strict Swift-5 concurrency diagnostics: clean.
- Architecture: 25 tests / 222 checks in two identical rebuilt runs after the waiver schema update.

## Deliberate boundary

The full 20-season both-tier soak and cap-vs-rating calibration remain open for the next durability
slice. Dated movement transactions, sourced contract expiry, deterministic professional roster AI,
and the short both-tier scheduler gate are live and focused-tested. M7 now owns the disposable
history/search projection; this M6 plan does not claim cold event storage or generated narrative.
