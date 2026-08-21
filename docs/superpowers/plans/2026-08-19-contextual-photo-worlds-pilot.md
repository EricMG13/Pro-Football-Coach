# Contextual Photo Worlds Pilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three generated management backdrops with three locally bundled, licence-recorded environmental American-football photographs while preserving Floodlit's hierarchy, contrast, offline contract, and existing screen-to-world mapping.

**Architecture:** Keep `FloodlitChromeReadModel.World` (`pitch`, `facility`, `film`) and `CoachWorldFloodlitStage` unchanged as the routing and composition seams. Add exactly three SwiftPM image resources named from the enum raw values, and let `CoachWorldWorldBackdrop` render them beneath the existing lamp, palette treatment, and grain. Individual screens, read models, Match Day, navigation, and simulation code remain untouched.

**Tech Stack:** Swift 5 language mode, SwiftUI, iOS 26, SwiftPM processed resources, the existing `Tests/SimTests` TestKit harness, Xcode iOS Simulator, and macOS `sips`. No runtime network access, third-party package, image-loading library, custom cache, or new rendering engine.

## Global Constraints

- Preserve the dirty worktree. Never reset, clean, stage, or rewrite unrelated owner changes.
- Before editing an indexed function, class, method, or file, run GitNexus upstream impact analysis and report direct callers, affected processes, and risk. Warn the user before continuing on HIGH or CRITICAL risk.
- Use exactly the existing `pitch`, `facility`, and `film` worlds. Do not add per-screen image selection, a fourth world, a feature flag, or a second backdrop component.
- Match Day and BROADCAST surfaces remain unchanged; the pilot affects DESK management worlds only.
- Images are bundled locally. No URL loading, cache, account, analytics, or network entitlement.
- Every depicted identity remains fictional and original. Reject visible people, faces, team or league marks, readable venue names, uniforms, sponsors, equipment brands, copyrighted wall art, and real-game footage.
- Use an environmental subject with negative space: an empty floodlit field for `pitch`, an unbranded locker/coaching facility for `facility`, and an empty projector/film room for `film`.
- Record the source page, photographer, provider, download date, provider licence URL, local filename, and SHA-256 for every shipped image in `docs/asset-licenses/world-backdrops.md`.
- Each cropped JPEG is 2880 × 1320 pixels, sRGB, progressive or baseline JPEG, at most 716,800 bytes. The three images together stay at or below 2,150,400 bytes.
- Dark-only Floodlit remains binding. The photograph is atmosphere, not a text surface or semantic signal.
- `content.primary`, `content.secondary`, and `content.quiet` must each remain at least 4.5:1 against the worst-case treated photograph. State and control boundaries remain at least 3:1.
- Preserve AX5 reflow, VoiceOver order, 44 pt targets, Reduce Transparency, Increase Contrast, Differentiate Without Color, and Reduce Motion. The photographs are static and accessibility-hidden.
- Preserve the supported landscape window: 844 × 390 install floor, 852 × 393 promise floor, and 956 × 440 ceiling.
- Do not change panel opacity to make a weak photograph more visible. If the pilot cannot read within the contrast treatment, reject the photograph.
- Do not add player portraits, team media, venue identity, animation, parallax, seasonal variants, downloads, or a photo carousel.

---

## Design Brief

**Feature summary:** A late-night coaching workspace should feel situated inside football without turning management screens into stock-photo posters. Three fixed environmental plates give the existing `pitch / facility / film` worlds material depth; restrained grading keeps the game data dominant.

**Primary user outcome:** Within two seconds, the player should recognise whether they are working beside the field, inside the facility, or in the film room, without losing the current task or reading hierarchy.

**Design direction:** Restrained dark product UI. Scene sentence: *A coach works after dark under stadium spill, institutional facility light, or a cold projector beam, focused on the next decision rather than the room itself.* Anchors are the existing Floodlit system, NFL Films' environmental-lighting discipline (mood only; no footage, marks, or identities), and Apple Sports' data-first restraint.

**Scope:** Production-ready three-world pilot inherited by existing DESK surfaces. Visual proof is mandatory on Coaching HQ (`8`), Opponent Film Room (`10`), and Roster (`16`); no individual screen redesign is in scope.

**Acceptance:**

1. All three environments are recognisable but subordinate to content.
2. Coaching HQ and Film Room feel materially richer; Roster is no less legible or dense.
3. No shipped pixel exposes a real-world identity or a licensing ambiguity.
4. The contrast-by-construction test passes against a worst-case white source image after the renderer's treatment.
5. Match Day renders identically before and after the change.

## File Map

**Create**

- `Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets/Contents.json` — asset-catalog root.
- `Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets/world-pitch.imageset/Contents.json` and `world-pitch.jpg` — empty floodlit field.
- `Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets/world-facility.imageset/Contents.json` and `world-facility.jpg` — unbranded football facility.
- `Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets/world-film.imageset/Contents.json` and `world-film.jpg` — empty projector/film room.
- `docs/asset-licenses/world-backdrops.md` — durable licence and source ledger.
- `docs/proofs/photo-world-pilot/README.md` — capture matrix and pass/fail notes.
- `docs/proofs/photo-world-pilot/*.png` — the approved pilot evidence.

**Modify**

- `Package.swift` — process `Sources/ProFootballCoachUI/Resources` in the UI target.
- `Sources/ProFootballCoachUI/DesignTokens.swift` — hold the four measurable photo-treatment values.
- `Sources/ProFootballCoachUI/FloodlitChrome.swift` — render `world-<rawValue>` and remove the superseded generated world drawings.
- `Tests/SimTests/Suites/DesignContractTests.swift` — enforce the exact asset set, byte budget, package declaration, and licence ledger.
- `Tests/SimTests/Suites/ContractTests.swift` — prove worst-case treated-photo contrast.
- `docs/04-UX-AND-DESIGN-SYSTEM.md` — replace the no-photography ambiguity with the bounded three-world rule.
- `docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md` — record the owner-approved exception for three bundled environmental plates while retaining the remote-asset ban.
- `docs/proofs/README.md` — identify the new proof set and replace the outdated “no stadium imagery” claim.

**Explicitly unchanged**

- `Sources/CoachWorldApp/CoachWorldChromeProvider.swift` — it already owns the correct screen-to-world mapping.
- `Sources/ProFootballCoachUI/CoachWorldDeskComponents.swift` — it already owns stage layering, Reduce Transparency, and grain.
- Every individual screen view, every read model, all simulation modules, Match Day, save data, and navigation.

---

### Task 1: Define and package the three licensed assets

**Files:**

- Modify: `Package.swift`
- Modify: `Tests/SimTests/Suites/DesignContractTests.swift`
- Create: `Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets/**`
- Create: `docs/asset-licenses/world-backdrops.md`

**Interfaces:**

- Consumes: `FloodlitChromeReadModel.World.allCases` and its raw values `pitch`, `facility`, `film`.
- Produces: SwiftPM resources named `world-pitch`, `world-facility`, and `world-film`; a licence ledger keyed by the matching JPEG filenames.

- [ ] **Step 1: Run the pre-edit blast-radius checks**

Run GitNexus:

```text
impact({target: "Package.swift", direction: "upstream", repo: "Pro-Football-Coach"})
impact({target: "runDesignContractTests", direction: "upstream", repo: "Pro-Football-Coach"})
```

Record direct callers, affected processes, and risk in the implementation log. If either result is HIGH or CRITICAL, warn the user before editing.

- [ ] **Step 2: Add the failing resource contract**

Append this suite inside `runDesignContractTests()`:

```swift
    suite("Bundled world photography") {
        let catalog = packageRoot().appendingPathComponent(
            "Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets"
        )
        let expectedStems = Set(
            FloodlitChromeReadModel.World.allCases.map { "world-\($0.rawValue)" }
        )

        test("every and only Floodlit world has one bundled image set") {
            let imageSets = Set(
                ((try? FileManager.default.contentsOfDirectory(atPath: catalog.path)) ?? [])
                    .filter { $0.hasSuffix(".imageset") }
                    .map { String($0.dropLast(".imageset".count)) }
            )
            expectEqual(imageSets, expectedStems)
        }

        test("world photographs stay inside the binary budget and licence ledger") {
            let ledgerURL = packageRoot().appendingPathComponent(
                "docs/asset-licenses/world-backdrops.md"
            )
            let ledger = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
            var totalBytes = 0

            for stem in expectedStems.sorted() {
                let filename = "\(stem).jpg"
                let imageURL = catalog
                    .appendingPathComponent("\(stem).imageset")
                    .appendingPathComponent(filename)
                let attributes = try? FileManager.default.attributesOfItem(atPath: imageURL.path)
                let bytes = (attributes?[.size] as? NSNumber)?.intValue ?? 0
                totalBytes += bytes

                expect(bytes > 0, "\(filename) is missing or empty")
                expect(bytes <= 716_800, "\(filename) exceeds the 700 KiB budget")
                expect(ledger.contains("`\(filename)`"), "licence ledger omits \(filename)")
            }

            expect(totalBytes <= 2_150_400, "world photographs exceed the 2.05 MiB total budget")
            expect(ledger.contains("https://www.pexels.com/legal-pages/license/")
                    || ledger.contains("https://unsplash.com/license"),
                   "the ledger names no approved provider licence")
        }

        test("SwiftPM processes the UI resource directory") {
            let manifestURL = packageRoot().appendingPathComponent("Package.swift")
            let manifest = (try? String(contentsOf: manifestURL, encoding: .utf8)) ?? ""
            expect(manifest.contains(#"resources: [.process("Resources")]"#),
                   "ProFootballCoachUI does not process its Resources directory")
        }
    }
```

- [ ] **Step 3: Run the test and confirm the intended failure**

Run:

```bash
swift run SimTests --design-contracts
```

Expected: FAIL in `Bundled world photography` because the catalog, JPEGs, ledger, and package resource declaration do not exist.

- [ ] **Step 4: Source exactly three acceptable photographs**

Use the official Pexels or Unsplash website, not an API or scraper. For each candidate:

1. Open the image's source page and the provider's current licence page.
2. Reject the image if any person, face, player number, uniform, logo, venue/team wordmark, sponsor, branded equipment, or projected game footage is visible at 200% zoom.
3. Prefer wide negative space behind the content column: field detail low/right for `pitch`, architectural depth to the right for `facility`, projector beam or seating depth centred for `film`.
4. Crop to 2880 × 1320 sRGB JPEG and compress to at most 716,800 bytes. Inspect the final JPEG, not only the source page.
5. Name the files exactly `world-pitch.jpg`, `world-facility.jpg`, and `world-film.jpg`.
6. Calculate each digest with `shasum -a 256 <file>` and record it with the source metadata.

Do not commit a candidate that is merely “probably generic.” Ambiguous depicted rights fail this step.

- [ ] **Step 5: Add the SwiftPM asset catalog**

Create `Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Each `<stem>.imageset/Contents.json` uses the same shape, substituting its real filename:

```json
{
  "images" : [
    {
      "filename" : "world-pitch.jpg",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Place each JPEG beside its matching `Contents.json`.

- [ ] **Step 6: Process the resources in SwiftPM**

Change only the `ProFootballCoachUI` target in `Package.swift`:

```swift
        .target(
            name: "ProFootballCoachUI",
            dependencies: ["FootballSimCore"],
            path: "Sources/ProFootballCoachUI",
            resources: [.process("Resources")]
        ),
```

- [ ] **Step 7: Write the completed licence ledger**

Create `docs/asset-licenses/world-backdrops.md` with one table row per JPEG and no blank metadata fields. Use the exact values collected in Step 4; do not copy a sample photographer, provider, URL, or digest from this plan.

```markdown
# World Backdrop Asset Licences

These three environmental photographs ship inside the paid, offline app. They are decorative,
contain no intended real-world identity, and are not used as team, player, venue, or product marks.

| Local file | World | Photographer | Provider | Source page | Downloaded | Licence | SHA-256 | Depicted-rights review |
|---|---|---|---|---|---|---|---|---|

The provider copyright licence does not itself clear trademarks, publicity rights, or depicted
artwork. The final column records the separate depicted-rights inspection performed on the exact
cropped file whose digest is listed.
```

Write the three rows directly from the inspected files: Pitch first, Facility second, Film third. The source page and licence cells are full HTTPS links, the downloaded cell is the actual ISO date, and the SHA-256 cell is the complete 64-character lowercase digest.

- [ ] **Step 8: Verify packaging and resource contracts**

Run:

```bash
swift build
swift run SimTests --design-contracts
```

Expected: build succeeds; `Bundled world photography` passes; no existing design-contract test regresses.

- [ ] **Step 9: Review and commit only Task 1 paths**

Run `confidence-review` because package/resource handling is code-adjacent, then GitNexus:

```text
detect_changes({scope: "unstaged", repo: "Pro-Football-Coach"})
```

Confirm the change set contains only the manifest, resource catalog, three JPEGs, ledger, and test. Then:

```bash
git add Package.swift Tests/SimTests/Suites/DesignContractTests.swift Sources/ProFootballCoachUI/Resources/WorldBackdrops.xcassets docs/asset-licenses/world-backdrops.md
git commit -m "feat: bundle licensed photo world assets"
```

---

### Task 2: Render photographs through the existing Floodlit world

**Files:**

- Modify: `Sources/ProFootballCoachUI/DesignTokens.swift`
- Modify: `Sources/ProFootballCoachUI/FloodlitChrome.swift`
- Modify: `Tests/SimTests/Suites/ContractTests.swift`

**Interfaces:**

- Consumes: `FloodlitChromeReadModel.World.rawValue`, SwiftPM's `Bundle.module`, existing `ground`, `lamp(_:)`, stage grain, and palette content roles.
- Produces: one static accessibility-hidden photo backdrop with a mathematically bounded maximum luminance.

- [ ] **Step 1: Run the renderer blast-radius checks**

Run GitNexus:

```text
impact({target: "Sources/ProFootballCoachUI/FloodlitChrome.swift", direction: "upstream", repo: "Pro-Football-Coach"})
impact({target: "CoachWorldFloodlitStage", direction: "upstream", repo: "Pro-Football-Coach"})
```

Report direct callers, affected processes, modules, and risk. If HIGH or CRITICAL, warn the user before editing.

- [ ] **Step 2: Add the failing worst-case contrast test**

Replace the existing private `contrastRatio` helper in `ContractTests.swift` with these shared local helpers:

```swift
private func linearizedContrastChannel(_ channel: Double) -> Double {
    channel <= 0.04045
        ? channel / 12.92
        : pow((channel + 0.055) / 1.055, 2.4)
}

private func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
    0.2126 * linearizedContrastChannel(red)
        + 0.7152 * linearizedContrastChannel(green)
        + 0.0722 * linearizedContrastChannel(blue)
}

private func contrastRatio(
    _ foreground: CoachWorldTokens.ColorValue,
    _ background: CoachWorldTokens.ColorValue
) -> Double {
    contrastRatio(
        foreground,
        (red: background.red, green: background.green, blue: background.blue)
    )
}

private func contrastRatio(
    _ foreground: CoachWorldTokens.ColorValue,
    _ background: (red: Double, green: Double, blue: Double)
) -> Double {
    let foregroundLuminance = relativeLuminance(
        red: foreground.red, green: foreground.green, blue: foreground.blue
    )
    let backgroundLuminance = relativeLuminance(
        red: background.red, green: background.green, blue: background.blue
    )
    return (max(foregroundLuminance, backgroundLuminance) + 0.05)
        / (min(foregroundLuminance, backgroundLuminance) + 0.05)
}
```

Then add this test beside `the production palette preserves readable role contrast`:

```swift
        test("photo worlds preserve readable text against a worst-case white source") {
            let palette = CoachWorldTokens.dark
            let cappedWhite = (
                red: CoachWorldTokens.WorldPhoto.colorMultiplier,
                green: CoachWorldTokens.WorldPhoto.colorMultiplier,
                blue: CoachWorldTokens.WorldPhoto.colorMultiplier
            )
            let opacity = CoachWorldTokens.WorldPhoto.scrimOpacity
            let treated = (
                red: cappedWhite.red + (palette.page.red - cappedWhite.red) * opacity,
                green: cappedWhite.green + (palette.page.green - cappedWhite.green) * opacity,
                blue: cappedWhite.blue + (palette.page.blue - cappedWhite.blue) * opacity
            )

            for role in [palette.contentPrimary, palette.contentSecondary, palette.contentQuiet] {
                expect(contrastRatio(role, treated) >= 4.5,
                       "every content role must remain at least 4.5:1 over a treated white photo")
            }
        }
```

- [ ] **Step 3: Run the test and confirm the intended compile failure**

Run:

```bash
swift run SimTests --core-contracts
```

Expected: compilation fails because `CoachWorldTokens.WorldPhoto` does not exist yet.

- [ ] **Step 4: Add the measurable treatment tokens**

Add this enum beside `CoachWorldTokens.Depth` in `DesignTokens.swift`:

```swift
    public enum WorldPhoto {
        /// Caps every channel in the composed world before the page scrim is applied.
        public static let colorMultiplier = 0.20
        public static let scrimOpacity = 0.50
        public static let imageOpacity = 0.82
        public static let saturation = 0.28
    }
```

The 0.20 multiplier and 0.50 page scrim are the contrast boundary. Do not lighten either value during visual tuning without first changing the worst-case test and proving all three content roles still meet 4.5:1.

- [ ] **Step 5: Replace generated drawings with the bundled world image**

In `CoachWorldWorldBackdrop.body`, retain `ground`, `lamp(_:)`, `drawingGroup()`, safe-area ownership, and accessibility hiding. Replace the `Canvas` switch with:

```swift
                Image("world-\(world.rawValue)", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .saturation(
                        world == .film ? 0 : CoachWorldTokens.WorldPhoto.saturation
                    )
                    .opacity(CoachWorldTokens.WorldPhoto.imageOpacity)
```

Apply the bounded treatment to the containing `ZStack`, after the lamp and image have composed:

```swift
            .colorMultiply(Color(white: CoachWorldTokens.WorldPhoto.colorMultiplier))
            .overlay(palette.page.color.opacity(CoachWorldTokens.WorldPhoto.scrimOpacity))
            .frame(width: size.width, height: size.height)
```

Delete `drawPitch`, `drawFacility`, `drawFilm`, `Chrome.bleed`, `Chrome.dustMotes`, and the `Chrome.Mote` type. They have no caller after the photograph replaces the generated illustration. Update the backdrop comment to say the three worlds use locally bundled, licence-recorded environmental plates and never fetch at runtime.

- [ ] **Step 6: Run focused build and contrast gates**

Run:

```bash
swift build
swift run SimTests --core-contracts
swift run SimTests --design-contracts
```

Expected: all commands pass. The new contrast test proves primary, secondary, and quiet content against the treated maximum-luminance pixel.

- [ ] **Step 7: Run the required post-edit reviews**

Run `rewrite-tournament` in no-argument post-edit mode on the changed backdrop `body` and luminance helper. Apply only a rewrite that is shorter or clearer without weakening the contrast model. Then run `confidence-review`; explicitly investigate:

- whether `Bundle.module` resolves in both SwiftPM and the generated iOS app;
- whether the asset names exactly follow all three enum raw values;
- whether the final modifier order actually caps the lamp and image together;
- whether removed drawing constants have any remaining references;
- whether BROADCAST and Match Day can reach the modified backdrop.

Patch confirmed issues, rerun the focused commands, then run:

```text
detect_changes({scope: "unstaged", repo: "Pro-Football-Coach"})
```

Expected: the UI target and design/contract tests are affected; no simulation flow or Match Day renderer changes.

- [ ] **Step 8: Commit only the renderer task**

```bash
git add Sources/ProFootballCoachUI/DesignTokens.swift Sources/ProFootballCoachUI/FloodlitChrome.swift Tests/SimTests/Suites/ContractTests.swift
git commit -m "feat: render contextual photo worlds"
```

---

### Task 3: Amend canon, capture the pilot, and make the ship/reject decision

**Files:**

- Modify: `docs/04-UX-AND-DESIGN-SYSTEM.md`
- Modify: `docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md`
- Modify: `docs/proofs/README.md`
- Create: `docs/proofs/photo-world-pilot/README.md`
- Create: `docs/proofs/photo-world-pilot/*.png`

**Interfaces:**

- Consumes: DEBUG `PROOF_NEW_CAREER=424242`, `PROOF_SCREEN_NUMBER`, the three supported viewport classes, and the finished renderer.
- Produces: owner-reviewable proof for screen 8 (`pitch`), 10 (`film`), and 16 (`facility`) plus durable canon that permits only this bounded use.

- [ ] **Step 1: Amend the design authority without opening a general photography licence**

In `docs/04-UX-AND-DESIGN-SYSTEM.md` §6.1c, immediately after “Three worlds, one variable,” add:

```markdown
**Three bundled environmental plates, not per-screen wallpaper.** `pitch`, `facility` and `film`
each resolve to one locally bundled, licence-recorded photograph. The crop contains no recognisable
person, real team or league identity, venue wordmark, sponsor, equipment brand, artwork or game
footage. The complete composed world is channel-capped and page-scrimmed before content, and the
worst-case white-source contrast calculation must keep every content role at 4.5:1. The photograph
is decorative and accessibility-hidden. Match Day remains its recorded Canvas field; no runtime
image fetch, screen-specific variant, animation, parallax or seasonal carousel is permitted.
```

In the 2026-08-15 all-surfaces spec, add an approved-decision bullet containing the same bounded rule. Keep the existing exclusion of remote assets and third-party packages.

In `docs/proofs/README.md`, link the new proof directory and replace the sentence claiming the game does not fetch stadium imagery with the precise claim: the base game never fetches imagery at runtime and ships only the three recorded environmental world plates.

- [ ] **Step 2: Build the DEBUG app for the simulator**

Run:

```bash
cd App
xcodegen generate
xcodebuild -project ProFootballCoach.xcodeproj -scheme ProFootballCoach -configuration Debug -sdk iphonesimulator -derivedDataPath build/photo-world-pilot build
cd ..
```

Expected: `** BUILD SUCCEEDED **` and the app at `App/build/photo-world-pilot/Build/Products/Debug-iphonesimulator/ProFootballCoach.app`.

- [ ] **Step 3: Capture all three worlds at the three supported widths**

Use these simulator device types and logical landscape sizes, one at a time:

- `iPhone 16e` — 844 × 390
- `iPhone 16` — 852 × 393
- `iPhone 17 Pro Max` — 956 × 440

For each device, boot it, wait until ready, remove any old proof save by uninstalling only this app, then install the fresh build. This is the 844 × 390 sequence:

```bash
xcrun simctl boot "iPhone 16e"
xcrun simctl bootstatus "iPhone 16e" -b
xcrun simctl uninstall "iPhone 16e" com.ericmg.ProFootballCoach
xcrun simctl install "iPhone 16e" App/build/photo-world-pilot/Build/Products/Debug-iphonesimulator/ProFootballCoach.app
xcrun simctl ui "iPhone 16e" content_size large
```

If uninstall reports that the app was not installed, continue; no app data exists to clear. Repeat the same commands with `iPhone 16` and `iPhone 17 Pro Max` after shutting down the previous device.

For screen numbers `8`, `10`, and `16`, launch, allow the proof route to settle, and capture:

```bash
SIMCTL_CHILD_PROOF_NEW_CAREER=424242 SIMCTL_CHILD_PROOF_SCREEN_NUMBER=8 xcrun simctl launch --terminate-running-process "iPhone 16e" com.ericmg.ProFootballCoach
sleep 2
xcrun simctl io "iPhone 16e" screenshot docs/proofs/photo-world-pilot/844-hq-default.png
```

Repeat with the correct width prefix and screen slug (`hq`, `film`, `roster`). If the framebuffer capture is portrait, rotate only that file 90° counter-clockwise with `sips -r -90 <file>` and verify its final pixel orientation with `sips -g pixelWidth -g pixelHeight <file>`.

Expected: nine default-size captures, three screens at each width.

- [ ] **Step 4: Capture AX5 at the same widths**

Set:

```bash
xcrun simctl ui "iPhone 16e" content_size accessibility-extra-extra-extra-large
```

Repeat the three launches and screenshots for every width, naming the files `<width>-<screen>-ax5.png`.

Expected: nine AX5 captures. Reset the simulator to `large` after capture.

- [ ] **Step 5: Review the 18 captures against explicit gates**

Record pass/fail in `docs/proofs/photo-world-pilot/README.md` for every width and content size:

- environment is recognisable within two seconds;
- no protected or recognisable real-world identity is visible after the final crop;
- identity header, icon rail, direct-on-world text, panels, controls, and focus marks remain legible;
- no photo subject sits beneath the primary action or creates a false affordance;
- no crop exposes an edge, stretches, or loses the environmental subject;
- Film stays cold and monochrome; Pitch and Facility remain restrained rather than full-colour stock photography;
- Roster density and row scanning are unchanged;
- AX5 remains one coherent scroll/reflow composition;
- Reduce Transparency removes grain and keeps opaque panel order; Increase Contrast and Differentiate Without Color preserve meaning;
- Match Day is visually unchanged from `docs/proofs/2026-08-18-exhaustive-critique/35-matchday.jpg` except for unrelated owner changes already present in the worktree.

If any contrast or identity gate fails, reject and replace the source asset. Do not compensate by making panels more opaque or adding a screen-specific overlay.

- [ ] **Step 6: Run the complete proportional verification**

Run:

```bash
git diff --check
swift build
swift run SimTests --design-contracts
swift run SimTests --core-contracts
swift run SimTests --legal-only
swift run SimTests
```

Expected: all focused gates and the no-argument suite pass. If the known self-re-exec scratch-path hazard appears, rerun without a custom scratch path and report the exact remaining failure rather than relabelling it green.

- [ ] **Step 7: Run final confidence and graph review**

Run `confidence-review` over the complete change. Investigate every low-confidence point to root cause, including licence metadata, resource presence in the built `.app`, pixel dimensions, aggregate bytes, contrast modifier order, the three proof mappings, and Match Day isolation. Patch confirmed issues and rerun their smallest failing checks.

Then run GitNexus:

```text
detect_changes({scope: "compare", base_ref: "main", repo: "Pro-Football-Coach"})
```

Expected: resource packaging, the shared management backdrop, contracts, and documentation only. Review every reported affected process; do not accept a simulation or BROADCAST execution-flow change.

- [ ] **Step 8: Commit the canon and proof evidence**

```bash
git add docs/04-UX-AND-DESIGN-SYSTEM.md docs/superpowers/specs/2026-08-15-floodlit-all-surfaces-design.md docs/proofs/README.md docs/proofs/photo-world-pilot
git commit -m "docs: record contextual photo world proof"
```

---

## Stop Conditions

Stop and ask the owner instead of expanding scope when:

- no acceptable logo-free, person-free image can be sourced for one of the three worlds;
- the provider page or licence record disappears or conflicts with app redistribution;
- a photo only becomes visible by weakening the contrast boundary;
- the roster remains flat and the requested outcome clearly requires foreground hierarchy changes;
- GitNexus reports HIGH or CRITICAL risk on the shared stage/backdrop path;
- the built app does not contain the three processed resources even though SwiftPM tests pass;
- any individual screen requires its own image, crop logic, or overlay to look acceptable.

The lazy completion is three good worlds through one existing seam. Anything broader is a separate design decision and a separate plan.
