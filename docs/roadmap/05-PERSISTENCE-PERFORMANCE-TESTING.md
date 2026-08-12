# Persistence, Performance and Testing

## 1. Current architectural strengths

The current repository already has unusually valuable foundations:
- pure simulation module
- deterministic hierarchical RNG
- centralized tier rules
- cross-process determinism testing
- explicit bounded loops
- source scans protecting architecture
- versioned-save intent
- headless test harness

These should be preserved.

---

## 2. Save architecture recommendation

The current single JSON-save concept is viable for early development, but a decades-long FM-style world will put pressure on it.

Recommended evolution:

```text
SaveEnvelope
├── metadata/header
├── compressed authoritative snapshot
├── bounded recent domain-event journal
├── historical aggregate archive
└── rebuildable search/read indexes (optional cache)
```

Do not immediately introduce SQLite or a third-party database.

First measure:
- encoded size at 1, 5, 20, 50 seasons
- load time
- save time
- migration cost
- history query cost

If the snapshot becomes too large or historical queries become too expensive, move history/indexes to an Apple-native persistence layer or a custom chunked format while preserving deterministic core state.

---

## 3. Performance budgets

Measure at:
- week advance
- full non-user slate
- recruiting resolution
- free-agent wave
- draft round
- save
- load
- search query
- read-model construction
- 2D match rendering

Use three scales:
- minimum test world
- target world
- stress world

For the target world, 134 college programmes + 32 pro teams must remain viable.

---

## 4. Test pyramid

### Unit
- rules
- formulas
- relationships
- cap/proration
- eligibility
- development
- interest
- scouting confidence

### Property
- roster legality
- no negative money
- deterministic seed behavior
- bounds
- monotonic rules where applicable

### System
- one week
- one season
- offseason
- recruiting cycle
- draft/free agency cycle
- job carousel

### Calibration
- football statistical bands
- player lifecycle bands
- recruiting distribution
- staff churn
- career mobility
- parity/dynasty distribution

### Soak
At least:
- 20 seasons on every backend milestone
- 50+ season stress soak before final
- save/load at repeated intervals
- deterministic replay fingerprints

---

## 5. New integrity assertions

At every week boundary:
- every rostered player belongs to exactly one team
- every employed staff member has one employer
- every scheduled game references valid teams
- all standings derive from completed games
- all scholarship/cap constraints hold
- no expired contract remains active
- no player exceeds eligibility without transition
- no event references missing IDs
- no history collection exceeds policy
- no observer knowledge exceeds truth constraints improperly
- no team is left without required positional coverage after AI processing
