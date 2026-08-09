# 04b — Audit Rubric

Every phase gate in `05-IMPLEMENTATION-PLAN.md` requires touched surfaces to score **≥17/20 with
zero P0/P1**. Without this document that gate is unmeasurable, which is why it is a deliverable
rather than a reference to a tool.

---

## ⚠️ Provenance — read this before using the rubric

**This rubric is reconstructed, not captured verbatim.**

The brief asked for the five dimensions and their 0–4 anchors "captured verbatim from the tool that
produced the 9/20 baseline". That tool is `/impeccable audit`, and **it was not available in the
executing session**. Per the brief's §10 fallback, the work was done manually and is labelled as
manually produced.

What is genuinely verbatim, taken from `docs/AUDIT.md`:

- the **five dimension names**;
- the **scores** each received (1/4, 2/4, 2/4, 2/4, 2/4 → 9/20) and the total's label, *"Poor —
  major overhaul"*;
- the **four severity levels** and their counts (1 P0 · 24 P1 · 36 P2 · 17 P3);
- the specific findings and their severities, which are the evidence the anchors are inferred from.

What is **reconstructed**: the 0–4 anchor text for each dimension, and the prose definitions of P0–P3.
They are inferred by working backwards from the scores the audit actually assigned to specific
evidence — an anchor set that reproduces 9/20 on the same findings. That is a defensible
reconstruction and it is not the original.

**Consequence, stated plainly.** A future `/impeccable audit` run may score the same code
differently from this document. If that happens, **the tool wins and this file is corrected** — it
is a stand-in that exists so the gate is measurable today, not a competing standard. Logged as
**[ESCALATION-1]** in `OPEN-DECISIONS.md`: if the owner can run `/impeccable audit` once, pasting its
real anchors over §2 makes the gate exact.

---

## 1. Scoring

Five dimensions, 0–4 each, **20 total**.

| Total | Label |
|---|---|
| 18–20 | Excellent |
| 14–17 | Good, with specific gaps |
| 10–13 | Weak — significant work |
| **0–9** | **Poor — major overhaul** ← the prior build scored 9 |

### Scope: per-phase versus per-milestone

Two dimensions cannot be honestly scored on a single feature's diff, because they are properties of
the **whole app**:

| Dimension | Scope |
|---|---|
| Accessibility | **Per phase** — every surface a phase touches |
| Performance | **Per phase** |
| Appearance & Theming | **Per phase** |
| **Platform Conformance** | **Global — scored at milestone boundaries** |
| **Adaptivity** | **Global — scored at milestone boundaries** |

A single new screen cannot fix "the app declares no orientation policy", and asking a phase gate to
prove it would either block every phase or become a rubber stamp. So per-phase gates score the three
local dimensions out of 12 (**≥10/12 required, zero P0/P1**), and milestone gates score all five out
of 20 (**≥17/20 required**).

---

## 2. The five dimensions

### 2.1 Accessibility

*Can everyone use it — VoiceOver, Dynamic Type, Reduce Motion, contrast, touch targets?*

| Score | Anchor |
|---|---|
| **0** | No accessibility consideration. Icon-only unlabelled buttons; gesture-only interactions with no alternative; contrast unmeasured |
| **1** | **Commitments exist on paper with near-zero implementation.** A written requirement (Reduce Motion, VoiceOver) has 0–3 occurrences across the codebase; text truncates under Dynamic Type at many sites; contrast fails widely ← *the prior build: Reduce Motion at 0 occurrences, 3 accessibility modifiers in ~140 KB of views, hero chips at 2.77:1, 19 fixed-width frames clipping scaling text* |
| **2** | Partial and inconsistent. Some surfaces correct, whole categories missed. Stock controls carry their free traits but composed rows read as fragments |
| **3** | Broadly correct with named exceptions. Contrast measured against real composited surfaces; Dynamic Type survives XXXL; Reduce Motion honoured; targets ≥44pt. Isolated gaps, each known |
| **4** | Complete and **coverage-tested**. Every token asserted against every surface it is drawn on in both themes; motion and target rules enforced by source scan; composed rows read as sentences; gesture-only interaction does not exist |

### 2.2 Performance

*Does it stay responsive — main-actor discipline, virtualization, allocation, I/O?*

| Score | Anchor |
|---|---|
| **0** | Unusable stalls in normal operation |
| **1** | Frequent multi-hundred-millisecond blocks on common actions, no loading state |
| **2** | **Structurally sound but with a systemic blocking defect.** Correct virtualization and bounded data in most places, undermined by one pervasive pattern ← *the prior build: every league mutation performing a 2.4–3.3 MB synchronous encode + backup + write + directory rescan on the main actor at 11 sites, 84–112 ms each, some actions paying it 2–5 times* |
| **3** | Meets stated budgets on the common path. Heavy work off the main actor; long collections virtualized; no aggregation in view bodies |
| **4** | Budgets are **asserted**, not observed. Written-down targets exist for week advance, save write, render frame, save size and cold launch, and tests fail when they are missed |

### 2.3 Appearance & Theming

*Does it look like one system — tokens, contrast, light/dark, no drift?*

| Score | Anchor |
|---|---|
| **0** | No system. Ad-hoc colours and spacings throughout; one theme only |
| **1** | A system exists on paper; views largely ignore it |
| **2** | **A real system, bypassed at scale.** Tokens defined and rigorously tested *where tested*, with dozens of literal spacings, radii and font sizes at call sites, and contrast measured only inside the tested subset ← *the prior build: 43 literal spacings, 25 literal radii, 9–10 hard-coded font sizes, contrast failing at 50+ sites in four independent forms* |
| **3** | Tokens used consistently; both themes correct; contrast measured against actual composited surfaces on the surfaces that matter |
| **4** | Literals are impossible — a source scan fails the build. Every token is contrast-asserted against every surface in both themes, and the assertion set is coverage-complete |

### 2.4 Platform Conformance *(global)*

*Does it behave like an iOS app — navigation, controls, modality, HIG?*

| Score | Anchor |
|---|---|
| **0** | Reads as a ported website. Hand-rolled global navigation, non-native controls, hover-dependent affordances |
| **1** | Native in places, with pervasive violations of core patterns |
| **2** | **Genuinely native in its bones, with specific real violations.** Stock `TabView` over `NavigationStack`s, stock controls, SF Symbols throughout — but large titles on pushed detail screens, "Done" in the leading cancellation slot, sub-44pt targets, a modal with no way out ← *the prior build* |
| **3** | HIG-conformant on every surface, with any deviation deliberate and documented |
| **4** | Conformant and enforced. Navigation, modality and control choices follow the HIG, no `.system(size:)` literals exist, and the recurring violations are caught by source scan |

### 2.5 Adaptivity *(global)*

*Does it survive every screen size, orientation policy and text size it claims to support?*

| Score | Anchor |
|---|---|
| **0** | One device assumed. Fixed pixel layouts; content clipped off-screen on common devices |
| **1** | Works on the development device; breaks on the smallest and largest |
| **2** | **Chassis adapts by construction; the exceptional surfaces do not, and no orientation policy is declared** ← *the prior build: every portrait screen rotating into a broken landscape, the one landscape-specced screen losing its controls when rotated, iPhone SE dropping the field-goal and punt buttons off the bottom* |
| **3** | Every supported size and orientation works; the policy is declared explicitly rather than defaulted |
| **4** | Declared, tested and enforced: smallest and largest supported devices verified, XXXL survives everywhere, and fixed-width frames around scaling text are caught by source scan |

---

## 3. Severity

Reconstructed from the audit's own usage. Severity is about **consequence**, not about how much code
it touches.

| Level | Definition | Prior build |
|---|---|---|
| **P0 — Blocking** | Breaks a stated product commitment on the common path, for all users, with no workaround. Ships only over an explicit written decision | 1 — the main-actor save |
| **P1 — Major** | Makes a feature unusable for an identifiable group, or violates a written-down project commitment at many sites. **Blocks a phase gate** | 24 |
| **P2 — Minor** | A real defect with limited blast radius, or a violation that is cosmetic in effect. Does not block a gate; goes on the list | 36 |
| **P3 — Polish** | Correct but improvable. Never blocks anything | 17 |

**The gate uses P0/P1 only.** A phase closes with zero P0 and zero P1 on the surfaces it touched.
P2/P3 accumulate in `STATUS.md` and are cleared at milestone boundaries.

---

## 4. How an audit is run

The rubric is only as good as the process, and the prior audit's process is the part most worth
copying:

1. **Five dimension finders run independently** — one per dimension, each blind to the others, so a
   finding is not lost because another lens already looked at the file.
2. **Every finding is re-opened at its cited line by an adversarial verifier instructed to refute
   it.** The prior audit raised 84, refuted 6, confirmed 78 — and **kept the six refutations in an
   appendix**, because what an audit got wrong is as useful as what it found. Keep that practice.
3. **Every finding carries**: location with line, category, impact with measured numbers where
   measurable, the guideline it violates *quoted*, and a concrete recommendation.
4. **Positive findings are recorded too.** The prior audit's positives are what stopped its 9/20
   being read as "this code is bad" — the codebase was structurally sound, and the score was low for
   specific, nameable reasons. A rubric that only records defects produces a distorted picture.

### 4.1 The rule that makes the score mean something

> *"The defect is not ignorance of contrast; it is that the test's coverage boundary became the
> quality boundary."* — `AUDIT.md`, Patterns & Systemic Issues

**A dimension cannot score 4 on the strength of a rigorous test with a narrow scope.** Scoring 4
requires the assertion set to be coverage-complete over its category, or to name its exclusions at
the assertion site. This single rule is the difference between the prior build's 1/4 accessibility
score and the 4 it believed it was earning.
