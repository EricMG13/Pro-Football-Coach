# Pro Football Coach Domain Language

Canonical language for the persistent college-to-professional coaching world. These terms keep
identity, market state, roster state, and observed knowledge distinct across simulation systems.

## College roster building

**Prospect**:
An unsigned generated player identity eligible to enter college through the current recruiting cycle.
_Avoid_: Recruit entity, incoming player

**Recruiting cycle**:
The bounded period in which programmes evaluate, contact, offer, host, and attempt to sign prospects.
_Avoid_: Recruiting season, offseason recruiting

**Recruiting board**:
A programme's bounded set of pursued prospect IDs and its programme-specific relationship state.
_Avoid_: Prospect list, watchlist

**Scholarship offer**:
A programme's revocable offer of one funded roster place to a prospect.
_Avoid_: Contract, roster offer

**Commitment**:
A prospect's pre-signing choice of programme; it can change until signing resolves.
_Avoid_: Signing, enrollment

**Commitment reservation**:
The class, scholarship, and roster-intake capacity held for a committed prospect until signing.
_Avoid_: Informal promise, board slot

**Commitment resolution**:
The signing-boundary outcome that either converts a commitment into a signed player or records an
explicit exceptional release.
_Avoid_: Silent rollover cleanup

**Commitment release**:
An explained exceptional failure to honour a commitment after authoritative capacity changed.
_Avoid_: Dropped recruit, unsigned without reason

**Signing**:
The authoritative transition that closes a prospect's recruitment and creates their persistent
college player, scholarship, lifecycle, and recruiting-history state.
_Avoid_: Commitment, intake

**Recruiting origin**:
The immutable career record of how and why a player entered a programme, retained after the
recruiting cycle and its recent events expire.
_Avoid_: Current recruiting state, event archive

**Archived prospect identity**:
A compact former-prospect identity retained only while recent world history still refers to that
unsigned prospect; it is not durable recruiting history.
_Avoid_: Recruiting origin, permanent prospect archive

**Portal entrant**:
An existing college `Player` seeking a transfer while retaining the same player and career identity.
_Avoid_: Transfer prospect, regenerated recruit

**Portal window**:
A bounded offseason period in which eligible players may enter, receive retention attempts, and
resolve a transfer destination.
_Avoid_: Recruiting cycle, unrestricted transfer market

**NIL allocation**:
Integer programme resources promised to influence recruiting or retention; it is not salary or a
professional contract.
_Avoid_: Contract value, wage

**NIL ledger**:
The single programme resource account covering prospect promises, enrolled-player allocations, and
portal offers without allowing the same budget to be spent twice.
_Avoid_: Separate recruiting pot, salary cap

**Redshirt**:
A recorded season designation that spends one eligibility-clock year without spending a season of
competition, subject to the usage rule.
_Avoid_: Inactive season, extra eligibility

**Redshirt plan**:
The current-season designation whose final outcome depends on recorded appearances and remaining
eligibility-clock capacity.
_Avoid_: Automatic zero-stat redshirt

**Appearance**:
A recorded participation in a game, whether or not the player produced a box-score statistic.
_Avoid_: Stat line, roster membership

**Participant manifest**:
The canonical home and away player identities whose availability and ability contributed to a
recorded game outcome.
_Avoid_: Box score, current roster snapshot

**Walk-on**:
An explicitly modeled non-scholarship college roster entrant used only within declared intake rules.
_Avoid_: Roster repair, replacement player

## Knowledge

**Truth**:
The authoritative hidden simulation value for a person or football fact.
_Avoid_: Actual estimate, scouted rating

**Observation**:
One programme's evidence-backed estimate of hidden truth, with confidence, evidence count, and age.
_Avoid_: Visible truth, public rating
