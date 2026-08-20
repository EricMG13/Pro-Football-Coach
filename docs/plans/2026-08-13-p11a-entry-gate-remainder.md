# P11a entry gate — remaining half Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the two P11a gate conditions that are still prose — G-09's `SmallestDeviceLayoutTest` and G-12's AX5 reflow contract — so M8 production UI, and specifically the nineteen registry-type extractions, is unblocked.

**Architecture:** Both land as new suites inside the existing `Tests/SimTests/Suites/DesignContractTests.swift`, which already declares itself the M8 entry gate and already holds G-07, G-08 and G-09's orientation half. Each suite reads its expectation out of `docs/04-UX-AND-DESIGN-SYSTEM.md` at run time rather than restating it, enumerates its file set by walking `Sources/ProFootballCoachUI` rather than from a hand list, and ships a planted-offender self-test so the scan is proven to fail before it is trusted. No new file, no new registration in `main.swift` — `runDesignContractTests()` is already called at line 52.

**Tech Stack:** Swift 6.3.3, the hand-rolled `TestKit` harness (`suite` / `test` / `expect`), `NSRegularExpression`, `FileManager`. Zero dependencies.

## Global Constraints

- iOS 26+, Swift 5.10+, SwiftUI. iPhone-only, **landscape-only**. Offline. Zero third-party app dependencies.
- Supported window: **844 x 390 install floor** through **956 x 440 ceiling**, with **852 x 393** the promise floor (`04` §7, D15).
- A test that hard-codes a value canon states is a second copy of canon. Parse it.
- Coverage boundary is not the quality boundary: a test that checks a class of surfaces enumerates that class **by construction**, so a new surface is covered the day it is added.
- No emoji in code, UI copy, commits or docs.
- Engine code is TDD. These are tests about the view layer; the discipline here is red-then-green against a planted offender.
- Conventional Commits. One task, one commit.

---

### Task 1: `SmallestDeviceLayoutTest` — G-09's second half

The install floor is the smallest window the app is ever installed into. Nothing in the tree currently
stops a view declaring a fixed width row that cannot fit it. Four `.frame(width:)` literals exist
today and all are small, so this lands green — it is a regression guard, and it is the instrument the
extraction work will be checked against as fixed-width components multiply.

**Files:**
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift` (append two suites before the closing brace of `runDesignContractTests()`)

**Interfaces:**
- Consumes: `packageRoot()` and `swiftFiles(under:)` from `Tests/SimTests/Suites/ContractTests.swift`; the file-private `canonText()` and `matches(of:in:)` already in `DesignContractTests.swift`; `CoachWorldScreenID` from `ProFootballCoachUI`.
- Produces: `canonSupportedWidths(_:) -> [Int]`, a file-private canon reader later tasks may reuse.

- [ ] **Step 1: Write the failing test**

Append this canon reader to the `// MARK: - Canon readers` section, after `canonSymbolClasses`:

```swift
/// The supported window widths `04` section 7 states, ascending.
///
/// Parsed rather than restated: D15 moved these once already and a hard-coded 844 would have
/// survived the move silently.
private func canonSupportedWidths(_ canon: String) -> [Int] {
    let widths = matches(of: "\\b(8[0-9]{2}|9[0-9]{2}) ?[x×]", in: canon).compactMap(Int.init)
    return Array(Set(widths)).sorted()
}
```

Append this suite inside `runDesignContractTests()`:

```swift
    suite("Smallest device layout") {
        // G-09's second half. 04 section 7 promises 852 x 393 and installs at 844 x 390; a row of
        // fixed columns that sums past the floor clips on every phone that hits it, and nothing
        // noticed until someone opened the smallest device.
        test("04 section 7 states widths this test can read") {
            let widths = canonSupportedWidths(canon)
            expect(widths.contains(844) && widths.contains(852) && widths.contains(956),
                   "parsed \(widths) from 04 section 7; the install floor, promise floor and "
                       + "ceiling are all binding and all three must be machine-readable")
        }

        test("no view declares fixed widths that cannot fit the install floor") {
            let installFloor = canonSupportedWidths(canon).first ?? 844

            for file in swiftFiles(under: "Sources/ProFootballCoachUI") {
                // A computed property is the unit a row is built in, so it is the unit whose fixed
                // widths are summed. Splitting on the declaration keyword is coarse and deliberate:
                // it over-groups rather than under-groups, so it cannot miss an overflow.
                let properties = file.text.components(separatedBy: "private var ")
                for property in properties {
                    let name = property.prefix(while: { $0.isLetter || $0.isNumber })
                    let widths = matches(of: "\\.frame\\(width: ([0-9]+)", in: property)
                        .compactMap(Int.init)
                    guard !widths.isEmpty else { continue }
                    let total = widths.reduce(0, +)
                    expect(total <= installFloor,
                           "\(file.path) property \(name) declares fixed widths summing to \(total) "
                               + "against an install floor of \(installFloor). A fixed row that "
                               + "cannot fit 844 clips on the smallest supported window (04 "
                               + "section 7, D15).")
                }
            }
        }

        test("every shipped view names a screen family the registry holds") {
            // Coverage by construction: the file set is the directory, and every view in it must map
            // onto CoachWorldScreenID. A view added tomorrow is checked tomorrow, not the day
            // somebody remembers to add it to a list.
            let families = Set(CoachWorldScreenID.allCases.map {
                $0.canonicalName.filter { $0.isLetter }.lowercased()
            })
            // RootView is the app shell, not a screen family; 04 section 8 does not list it.
            let shell: Set<String> = ["RootView"]

            for file in swiftFiles(under: "Sources/ProFootballCoachUI") {
                let base = (file.path as NSString).lastPathComponent
                    .replacingOccurrences(of: ".swift", with: "")
                guard base.hasSuffix("View"), !shell.contains(base) else { continue }
                let stem = base.replacingOccurrences(of: "View", with: "").lowercased()
                expect(families.contains(where: { $0.hasPrefix(stem) || stem.hasPrefix($0) }),
                       "\(base) does not map onto any CoachWorldScreenID canonical name. Every "
                           + "production view is a screen family in 04 section 8 or it is "
                           + "unaccounted for.")
            }
        }

        test("the scan would notice a fixed row that overflows the floor") {
            let planted = """
            private var overflowingRow: some View {
                HStack { a.frame(width: 500); b.frame(width: 400) }
            }
            """
            let widths = matches(of: "\\.frame\\(width: ([0-9]+)", in: planted).compactMap(Int.init)
            expect(widths.reduce(0, +) > 844,
                   "the predicate the real assertion uses must catch a planted 900pt row")
        }
    }
```

- [ ] **Step 2: Run the suite to verify the planted-offender test is meaningful and the real ones pass**

Run: `swift run SimTests 2>&1 | grep -A3 "Smallest device layout"`
Expected: all four tests pass. If `04 section 7 states widths this test can read` fails, the parser is what failed — fix the regex, not canon.

- [ ] **Step 3: Prove the real assertion fails against a real offender**

Temporarily append to `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift`:

```swift
private var plantedOverflowRow: some View {
    HStack { Color.clear.frame(width: 500); Color.clear.frame(width: 400) }
}
```

Run: `swift run SimTests 2>&1 | grep "install floor"`
Expected: FAIL naming `CoachWorldDeskComponents.swift property plantedOverflowRow` and the total 900.

- [ ] **Step 4: Remove the planted offender and re-run**

Delete the `plantedOverflowRow` property.
Run: `./scripts/verify.sh`
Expected: build green, suite green, no regression in the existing count.

- [ ] **Step 5: Commit**

```bash
git add Tests/SimTests/Suites/DesignContractTests.swift
git commit -m "test: assert the install floor fits every fixed row (G-09)"
```

---

### Task 2: The AX5 reflow contract — G-12

`04` §4.5 and §7 say AX5 reflows to one column **preserving order and dropping nothing**. Four of the
five shipped views branch on `dynamicTypeSize.isAccessibilitySize`; nothing checks that the branch
they reflow into still carries every datum the dense composition carried. This is the assertion that
makes "drops nothing" mechanical.

**Files:**
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift` (append one suite)

**Interfaces:**
- Consumes: `swiftFiles(under:)`, `matches(of:in:)`, `canonText()`.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Write the failing test**

Append inside `runDesignContractTests()`:

```swift
    suite("AX5 reflow contract") {
        // G-12. 04 section 4.5: "At AX5 the composition reflows to one column preserving order and
        // dropping nothing." Order is not mechanically checkable from source; dropping is, and
        // dropping is the failure that loses data rather than merely rearranging it.
        test("04 states the reflow contract this test enforces") {
            expect(canon.contains("reflows to one column"),
                   "04 no longer states the AX5 reflow contract in the words this test reads; "
                       + "update the test with canon, not canon with the test")
        }

        test("every view with a dense composition has an accessible path") {
            for file in viewFiles() {
                let base = (file.path as NSString).lastPathComponent
                expect(file.text.contains("dynamicTypeSize.isAccessibilitySize"),
                       "\(base) never branches on isAccessibilitySize, so it cannot reflow at AX5. "
                           + "04 section 7 makes the reflow binding on every family.")
                expect(file.text.contains("accessibleLayout"),
                       "\(base) declares no accessibleLayout. The reflowed composition is a named "
                           + "property so this scan, and a reader, can find it.")
            }
        }

        test("the accessible path drops no datum the dense path shows") {
            for file in viewFiles() {
                let base = (file.path as NSString).lastPathComponent
                let accessible = accessibleRegions(of: file.text)
                guard !accessible.isEmpty else { continue }
                let accessibleFields = Set(matches(of: "model\\.([a-zA-Z][a-zA-Z0-9]*)",
                                                   in: accessible.joined(separator: "\n")))

                // The dense path is everything that is not an accessible region, so a view that
                // renames its standard property is still covered. PlayerProfileView has no
                // standardLayout and this is why.
                var dense = file.text
                for region in accessible { dense = dense.replacingOccurrences(of: region, with: "") }
                let denseFields = Set(matches(of: "model\\.([a-zA-Z][a-zA-Z0-9]*)", in: dense))

                let dropped = denseFields.subtracting(accessibleFields).sorted()
                expect(dropped.isEmpty,
                       "\(base) shows \(dropped.count) datum/data in its dense composition that the "
                           + "AX5 path never reads: \(dropped.joined(separator: ", ")). 04 section "
                           + "4.5 permits reflow, never loss.")
            }
        }

        test("the scan would notice a datum dropped at AX5") {
            let planted = """
            private var standardLayout: some View { Text(model.injuryCount.description) }
            private var accessibleLayout: some View { Text(model.rosterLimit.description) }
            """
            let accessible = accessibleRegions(of: planted)
            let accessibleFields = Set(matches(of: "model\\.([a-zA-Z][a-zA-Z0-9]*)",
                                               in: accessible.joined(separator: "\n")))
            var dense = planted
            for region in accessible { dense = dense.replacingOccurrences(of: region, with: "") }
            let denseFields = Set(matches(of: "model\\.([a-zA-Z][a-zA-Z0-9]*)", in: dense))
            expect(!denseFields.subtracting(accessibleFields).isEmpty,
                   "a planted AX5 path that drops injuryCount must not be reported as complete")
        }
    }
```

Append these two helpers to the `// MARK: - Canon readers` section:

```swift
/// Every production view file, enumerated by walking the directory rather than from a list.
private func viewFiles() -> [(path: String, text: String)] {
    swiftFiles(under: "Sources/ProFootballCoachUI").filter {
        let base = ($0.path as NSString).lastPathComponent
        return base.hasSuffix("View.swift") && base != "RootView.swift"
    }
}

/// The source of every property whose name marks it as the AX5 path.
///
/// A region runs from its `private var accessible…` declaration to the next `private var`, which is
/// how this file's views are written. Coarse by design: over-including source can only make the
/// scan more permissive about the dense side, never blind to a dropped datum.
private func accessibleRegions(of source: String) -> [String] {
    var regions: [String] = []
    let parts = source.components(separatedBy: "private var ")
    for part in parts where part.hasPrefix("accessible") {
        regions.append("private var " + part)
    }
    return regions
}
```

- [ ] **Step 2: Run the suite**

Run: `swift run SimTests 2>&1 | grep -A5 "AX5 reflow contract"`
Expected: the first, second and fourth tests pass. **The third may legitimately fail** — if it names dropped fields, that is a real G-12 finding in a shipped view, not a test bug. Record what it names before changing anything.

- [ ] **Step 3: Resolve whatever the third test names**

If it reports dropped fields, for each one either add it to that view's `accessibleLayout` or, where the datum is genuinely presentational and carries no information (a spacer count, a layout constant), rename the reference so it is not read as a model datum. Do not weaken the assertion to make it pass.

Run: `swift run SimTests 2>&1 | grep "permits reflow, never loss"`
Expected: no output.

- [ ] **Step 4: Full gate**

Run: `./scripts/verify.sh`
Expected: build green, all suites green, test count higher than the 620 baseline by the number of tests added.

- [ ] **Step 5: Commit**

```bash
git add Tests/SimTests/Suites/DesignContractTests.swift Sources/ProFootballCoachUI
git commit -m "test: assert AX5 reflow drops no datum (G-12)"
```

---

### Task 3: Record the gate as closed

**Files:**
- Modify: `docs/STATUS.md`
- Modify: `docs/05-IMPLEMENTATION-PLAN.md:343-346` (the status note under "Amendment: P11 entry conditions")

- [ ] **Step 1: Update the plan's status note**

Replace the 2026-08-12 status paragraph with one dated 2026-08-13 stating which of G-07, G-08, G-09, G-12 now have both halves, and naming any G-12 finding Task 2 surfaced.

- [ ] **Step 2: Update `docs/STATUS.md`**

Add P11a to the verified list with the test count from `./scripts/verify.sh`, and state plainly that G-13 (failure-set designs carried into the view layer) remains open, because it lands as families land rather than as one phase.

- [ ] **Step 3: Commit**

```bash
git add docs/STATUS.md docs/05-IMPLEMENTATION-PLAN.md
git commit -m "docs: record P11a's remaining gate conditions as closed"
```

---

## Self-review

**Spec coverage.** P11a lists five conditions. G-07, G-08 and G-09's orientation half are already green in `DesignContractTests.swift`. Task 1 closes G-09's `SmallestDeviceLayoutTest`; Task 2 closes G-12. **G-13 is not covered by this plan and cannot be** — the phase text says it "carries them into the view layer as families land", which is per-family M8 work, not a gate test. Task 3 records that explicitly rather than letting it read as done.

**Known limits, stated rather than hidden.** Task 1 sums fixed widths per computed property, which over-groups; it cannot produce a false pass but can produce a false failure on a property holding two unrelated rows, and the message names the property so that is cheap to resolve. Task 2 checks *dropping*, not *order* — reading order at AX5 is not recoverable from source and stays a review obligation under `04b`. Neither test renders SwiftUI, because the harness is a plain executable with no Xcode; both are source contracts in the established idiom of this file, and that limit is the same one `ArchitectureTests` and `LegalTests` already carry.
