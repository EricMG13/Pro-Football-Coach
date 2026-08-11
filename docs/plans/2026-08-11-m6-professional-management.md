# M6 — professional management

## Goal

Give a promoted coach a truthful, cap-safe professional roster transaction boundary without creating
a second ownership or money ledger.

## Delivered in this slice

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

## Evidence

- M6 focused gate: 6 tests / 17 checks.
- Core contracts: 144 tests / 875 checks.
- Strict Swift-5 concurrency diagnostics: clean.
- Architecture: 25 tests / 222 checks in two rebuilt runs with identical fingerprints.

## Deliberate boundary

This slice does not claim dated free-agency waves, draft-class scouting fog, trades, contract expiry,
practice-squad rules, or a professional actor/UI. Those require authoritative market phases and are
the next M6 slice; the current transaction API is the smallest reusable foundation for them.
