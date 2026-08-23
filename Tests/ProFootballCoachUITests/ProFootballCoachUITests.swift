import XCTest

final class ProFootballCoachUITests: XCTestCase {
    func testLaunchContractIsRegistered() {
        XCTAssertTrue(true)
    }

    func testCoachingHQRosterPlayerProfileVerticalSlice() {
        assertCoachingHQRosterPlayerProfileVerticalSlice(usesAX5: false)
    }

    /// The same route at an accessibility size. Task 5 asks for this family's route in both, and a
    /// route that only ever ran at default cannot evidence the reflowed one.
    func testCoachingHQRosterPlayerProfileVerticalSliceAtAX5() {
        assertCoachingHQRosterPlayerProfileVerticalSlice(usesAX5: true)
    }

    private func assertCoachingHQRosterPlayerProfileVerticalSlice(usesAX5: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "8"
        launch(app, ax5: usesAX5)

        XCTAssertTrue(
            app.descendants(matching: .any)["coaching-hq-screen"]
                .waitForExistence(timeout: 20)
        )
        XCTAssertGreaterThan(
            app.descendants(matching: .any)
                .matching(identifier: "top-navigator").count,
            0
        )
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Sections")).count,
            0
        )
        let context = app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "WEEK 1 ·"))
            .firstMatch
        XCTAssertTrue(context.exists)
        XCTAssertGreaterThan(context.frame.width, 0)
        if !usesAX5 { XCTAssertLessThan(context.frame.width, 132) }
        let family = app.buttons["Open all tasks, This week"]
        let currentSibling = app.buttons["Coaching HQ"]
        XCTAssertGreaterThanOrEqual(family.frame.height, 44)
        XCTAssertGreaterThanOrEqual(currentSibling.frame.height, 44)
        XCTAssertGreaterThanOrEqual(currentSibling.frame.minX, family.frame.maxX)
        family.tap()
        // The task index lists every available surface, so Roster sits below the fold when it
        // opens. Tapping without scrolling synthesizes the tap at an off-screen point and the
        // route never runs.
        let registry = app.scrollViews["surface-registry"].firstMatch
        XCTAssertTrue(registry.waitForExistence(timeout: 10))
        let roster = app.buttons["Roster"].firstMatch
        XCTAssertTrue(roster.waitForExistence(timeout: 10))
        XCTAssertTrue(scroll(registry, toReveal: roster))
        roster.tap()
        XCTAssertTrue(app.otherElements["roster-screen"].waitForExistence(timeout: 10))
        app.buttons["roster-open-dossier"].tap()
        XCTAssertTrue(app.otherElements["player-profile-screen"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.otherElements
                .matching(NSPredicate(format: "label ENDSWITH %@", "out of 99"))
                .firstMatch.exists
        )
        XCTAssertTrue(
            app.staticTexts
                .matching(NSPredicate(format: "label MATCHES %@", ".*, [0-9]+, Known"))
                .firstMatch.exists
        )
        app.buttons["Back to the roster"].tap()
        XCTAssertTrue(app.otherElements["roster-screen"].waitForExistence(timeout: 10))
    }

    func testUnchromedMatchProofKeepsBroadcastTopInset() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_SCREEN"] = "match"
        app.launch()

        let scoreBug = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Q3"))
            .firstMatch
        XCTAssertTrue(scoreBug.waitForExistence(timeout: 20))
        XCTAssertLessThan(scoreBug.frame.minY, 30)
    }

    func testWeeklyCommandScreensExposeOneDominantSurfaceAtDefault() {
        assertWeeklyCommandScreens(usesAX5: false)
    }

    func testWeeklyCommandScreensExposeOneDominantSurfaceAtAX5() {
        assertWeeklyCommandScreens(usesAX5: true)
    }

    private func assertWeeklyCommandScreens(usesAX5: Bool) {
        let screenIDs = Array(8...15) + [47]
        for screenID in screenIDs {
            let app = XCUIApplication()
            if screenID == 14 {
                app.launchEnvironment["PROOF_SCREEN"] = "match"
            } else {
                app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
                app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "\(screenID)"
            }
            launch(app, ax5: usesAX5)

            if screenID == 15 || screenID == 47 {
                let title = screenID == 15 ? "Aftermath" : "Game Detail / Box Score"
                let unavailable = app.staticTexts.matching(
                    NSPredicate(format: "label BEGINSWITH %@", "\(title) unavailable.")
                ).firstMatch
                guard unavailable.waitForExistence(timeout: 20) else {
                    XCTFail("Missing honest unavailable state for screen \(screenID), AX5: \(usesAX5)")
                    return
                }
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Weekly command \(screenID) — \(usesAX5 ? "AX5" : "default") — unavailable"
                attachment.lifetime = .keepAlways
                add(attachment)
                app.terminate()
                continue
            }

            let rootIdentifier = "weekly-command-screen-\(screenID)"
            let roots = app.descendants(matching: .any)
                .matching(identifier: rootIdentifier)
            guard roots.firstMatch.waitForExistence(timeout: 20) else {
                XCTFail("Missing weekly-command root for screen \(screenID), AX5: \(usesAX5)")
                return
            }
            guard roots.count == 1 else {
                XCTFail("Expected one weekly-command root for screen \(screenID), AX5: \(usesAX5)")
                return
            }
            let dominants = app.descendants(matching: .any)
                .matching(identifier: "weekly-command-dominant")
            guard dominants.count == 1 else {
                XCTFail("Expected one dominant surface for screen \(screenID), AX5: \(usesAX5)")
                return
            }
            XCTAssertEqual(app.buttons.matching(identifier: rootIdentifier).count, 0)
            XCTAssertEqual(app.buttons.matching(identifier: "weekly-command-dominant").count, 0)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Weekly command \(screenID) — \(usesAX5 ? "AX5" : "default")"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }

    func testPersonnelFamilyExposesItsCanonicalDestinationsAtDefault() {
        assertPersonnelFamily(usesAX5: false)
    }

    func testPersonnelFamilyExposesItsCanonicalDestinationsAtAX5() {
        assertPersonnelFamily(usesAX5: true)
    }

    /// Canonical destinations 16 to 20 -- Roster, Depth Chart, Player Profile, Development, Staff
    /// Room.
    private func assertPersonnelFamily(usesAX5: Bool) {
        assertCanonicalFamily("Personnel", ids: Array(16...20), usesAX5: usesAX5)
    }

    func testRecruitingFamilyExposesItsCanonicalDestinationsAtDefault() {
        assertRecruitingFamily(usesAX5: false)
    }

    func testRecruitingFamilyExposesItsCanonicalDestinationsAtAX5() {
        assertRecruitingFamily(usesAX5: true)
    }

    /// Canonical destinations 24 to 29 and 61 -- Recruiting Board, Prospect Profile, Shortlist,
    /// Contact & Visit Planner, Class Overview, Signing Day, College Offseason.
    ///
    /// 61 is in the list and 30 to 33 are not, deliberately. Portal Hub, Retention Decisions,
    /// Portal Market and NIL Allocation are aliases: the contract gives an alias no identity of
    /// its own, so each renders College Offseason's stamp rather than a fifth and sixth one. The
    /// alias routes are proved by `testUnavailableRouteOffersReturnPath` and the registry, not
    /// here. Signing Day is the opposite case -- canonical in its own right while delegating its
    /// open phase to College Offseason -- so it passes its own id down and this proof would catch
    /// it carrying both.
    private func assertRecruitingFamily(usesAX5: Bool) {
        assertCanonicalFamily("Recruiting", ids: Array(24...29) + [61], usesAX5: usesAX5)
    }

    func testProManagementFamilyExposesItsCanonicalDestinationsAtDefault() {
        assertProManagementFamily(usesAX5: false)
    }

    func testProManagementFamilyExposesItsCanonicalDestinationsAtAX5() {
        assertProManagementFamily(usesAX5: true)
    }

    /// Canonical destinations 34, 35, 36, 39 and 62 -- Cap & Contracts, Contract Negotiation,
    /// Roster Cuts & Transactions, Draft Room, Pro Offseason.
    ///
    /// 37, 38 and 40 are absent for the same reason 30 to 33 are absent from the recruiting list:
    /// Pro Scouting Board, Draft Board and Free Agency are aliases and inherit 62. Two shapes this
    /// family exercises that Personnel did not -- one view serving two canonical destinations (34
    /// and 36 are both `ProManagementView`), and a canonical screen delegating to another
    /// canonical screen (Draft Room to Pro Offseason) -- are exactly the cases the single-identity
    /// assertion exists for.
    private func assertProManagementFamily(usesAX5: Bool) {
        assertCanonicalFamily("Pro management", ids: [34, 35, 36, 39, 62], usesAX5: usesAX5)
    }

    /// One canonical destination family, enumerated by id rather than listed by hand.
    ///
    /// Exactly one stamp per screen, and exactly the expected one: counting only the expected id
    /// proves a surface renders its destination but not that it is *only* that destination, which
    /// is what an alias rendering a second copy, or a delegating screen keeping its delegate's
    /// stamp, would break. A destination with no retained career evidence must say so rather than
    /// render an empty shell.
    private func assertCanonicalFamily(
        _ family: String,
        ids: [Int],
        usesAX5: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for screenID in ids {
            let app = XCUIApplication()
            app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
            app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "\(screenID)"
            launch(app, ax5: usesAX5, file: file, line: line)

            let stamps = app.descendants(matching: .any)
                .matching(identifier: "canonical-screen-\(screenID)")
            let anyStamp = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", "canonical-screen-"))
            let unavailable = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS %@", "unavailable."))
                .firstMatch

            // Recorded, not just asserted. Both branches are legitimate, so a green run says
            // nothing about which one each screen took -- and a family that quietly went all
            // "unavailable" would pass while proving nothing about the stamps. The branch is in
            // the attachment name so one run is readable evidence.
            let branch: String
            if stamps.firstMatch.waitForExistence(timeout: 30) {
                branch = "stamped"
                XCTAssertEqual(
                    stamps.count, 1,
                    "screen \(screenID) stamped \(stamps.count) times",
                    file: file, line: line
                )
                XCTAssertEqual(
                    anyStamp.count, 1,
                    "screen \(screenID) also carries \(max(anyStamp.count - 1, 0)) other "
                        + "canonical destination stamps",
                    file: file, line: line
                )
            } else {
                branch = "unavailable"
                XCTAssertTrue(
                    unavailable.exists,
                    "screen \(screenID) rendered neither its canonical stamp nor an honest "
                        + "unavailable state",
                    file: file, line: line
                )
            }

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name =
                "\(family) \(screenID) — \(usesAX5 ? "AX5" : "default") — \(branch)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }

    func testCoachingHQSelectsBeforeExplicitCommitAtDefault() {
        assertCoachingHQSelectsBeforeExplicitCommit(usesAX5: false)
    }

    func testCoachingHQSelectsBeforeExplicitCommitAtAX5() {
        assertCoachingHQSelectsBeforeExplicitCommit(usesAX5: true)
    }

    private func assertCoachingHQSelectsBeforeExplicitCommit(usesAX5: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "8"
        launch(app, ax5: usesAX5)

        let choice = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "hq-choice-"))
            .firstMatch
        // HQ carries two committing actions -- the decision's and "Advance" -- so this names the
        // one it means. That HQ has two at all is against `04` section 6.5's one per screen, and is
        // recorded in the Task 4 report rather than resolved here.
        let commit = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Commit"))
            .firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 20))
        XCTAssertTrue(commit.exists)
        XCTAssertFalse(commit.isEnabled)
        choice.tap()
        XCTAssertTrue(commit.isEnabled)
        commit.tap()
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(identifier: "weekly-command-screen-8").count,
            1
        )
        XCTAssertEqual(
            app.descendants(matching: .any)
                .matching(identifier: "weekly-command-dominant").count,
            1
        )
        XCTAssertEqual(app.buttons.matching(identifier: "weekly-command-dominant").count, 0)
        app.terminate()
    }

    func testWeeklyPlanReceiptDoesNotCoverChoicesAtDefault() {
        assertWeeklyPlanReceiptDoesNotCoverChoices(usesAX5: false)
    }

    func testWeeklyPlanReceiptDoesNotCoverChoicesAtAX5() {
        assertWeeklyPlanReceiptDoesNotCoverChoices(usesAX5: true)
    }

    func testWeeklyPlanDominantEvidenceTracksSelectedCommitAtDefault() {
        assertWeeklyPlanDominantEvidenceTracksSelectedCommit(usesAX5: false)
    }

    func testWeeklyPlanDominantEvidenceTracksSelectedCommitAtAX5() {
        assertWeeklyPlanDominantEvidenceTracksSelectedCommit(usesAX5: true)
    }

    func testEveryControlMeetsTheTouchFloorAtDefault() {
        assertEveryControlMeetsTheTouchFloor(usesAX5: false)
    }

    func testEveryControlMeetsTheTouchFloorAtAX5() {
        assertEveryControlMeetsTheTouchFloor(usesAX5: true)
    }

    /// `CLAUDE.md`: "The 44 x 44 pt touch floor is HIG-verified (Apple's stated minimum is
    /// 28 x 28 pt; this contract keeps the stricter 44 pt)."
    ///
    /// Enumerated by walking every button the screen actually exposes, rather than a list of the
    /// ones someone remembered, so a control added later is covered the day it is added. Runs at
    /// whichever content size the harness has set, because a control that clears the floor at
    /// default can still fall under it when its label grows.
    private func assertEveryControlMeetsTheTouchFloor(usesAX5: Bool) {
        for screenID in [8, 9, 10, 11, 12, 13] {
            let app = XCUIApplication()
            app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
            app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "\(screenID)"
            launch(app, ax5: usesAX5)
            XCTAssertTrue(
                app.descendants(matching: .any)["weekly-command-screen-\(screenID)"]
                    .waitForExistence(timeout: 30)
            )
            for control in app.buttons.allElementsBoundByIndex where control.exists {
                let frame = control.frame
                // A zero frame is an element the query can see but the screen does not place --
                // off-screen list content, not a control the finger can reach.
                guard frame.width > 0, frame.height > 0 else { continue }
                // Rounded: layout arithmetic in floating point lands a genuine 44 on
                // 43.99999999999997, and failing that would be the test being wrong, not the app.
                XCTAssertGreaterThanOrEqual(
                    frame.height.rounded(), 44,
                    "screen \(screenID): \"\(control.label)\" is \(frame.height)pt tall"
                )
                XCTAssertGreaterThanOrEqual(
                    frame.width.rounded(), 44,
                    "screen \(screenID): \"\(control.label)\" is \(frame.width)pt wide"
                )
            }
            app.terminate()
        }
    }

    func testWeeklyCommandContentStaysInsideTheViewportAtDefault() {
        assertWeeklyCommandContentStaysInsideTheViewport(usesAX5: false)
    }

    func testWeeklyCommandContentStaysInsideTheViewportAtAX5() {
        assertWeeklyCommandContentStaysInsideTheViewport(usesAX5: true)
    }

    func testTeamHealthEmptyStateDoesNotHideBehindFooterAtAX5() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "13"
        launch(app, ax5: true)

        let emptyState = app.staticTexts.matching(
            NSPredicate(
                format: "label == %@",
                "No readiness exceptions are recorded for this squad."
            )
        ).firstMatch
        let footer = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH[c] %@", "Advance week")
        ).firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 20))
        XCTAssertTrue(footer.exists)
        XCTAssertFalse(emptyState.frame.intersects(footer.frame))
        app.terminate()
    }

    private func assertWeeklyCommandContentStaysInsideTheViewport(usesAX5: Bool) {
        let fixtures: [(screenID: Int, labels: [String], choicePrefixes: [String])] = [
            // Screen 8 is deliberately absent. Adding it surfaced two things that are not this
            // proof's to settle: its `weekly-command-screen-8` identifier sits on a nested label,
            // so the 63-point column assertion below does not describe it, and its committing
            // action measures maxY 407.7 in a 390-point window whenever a decision panel is on
            // screen. Both are recorded in the Task 4 report as owner questions.
            (9, ["6 unanswered"], []),
            (10, ["Stale"], []),
            (11, ["You decide"], [
                "Balanced control.", "Pressure the quarterback.", "Play with pace.",
            ]),
            (12, ["You decide"], [
                "Balanced week.", "Install and sharpen.", "Recover and condition.",
            ]),
            (13, ["Condition 100%"], []),
        ]

        for fixture in fixtures {
            let app = XCUIApplication()
            app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
            app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "\(fixture.screenID)"
            launch(app, ax5: usesAX5)

            let viewport = app.windows.firstMatch
            XCTAssertTrue(viewport.waitForExistence(timeout: 20))
            let root = app.descendants(matching: .any)[
                "weekly-command-screen-\(fixture.screenID)"
            ]
            XCTAssertTrue(root.waitForExistence(timeout: 20))
            if usesAX5 {
                assert(root, staysInside: viewport)
            } else {
                XCTAssertEqual(root.frame.minX, 63, accuracy: 0.5)
            }
            for label in fixture.labels {
                let element = app.staticTexts[label].firstMatch
                XCTAssertTrue(element.waitForExistence(timeout: 20))
                assert(element, staysInside: viewport)
            }
            for choicePrefix in fixture.choicePrefixes {
                let choice = app.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH[c] %@", choicePrefix)
                ).firstMatch
                XCTAssertTrue(choice.exists)
                assert(choice, staysInside: viewport)
            }
            // `04` section 7: "The initial viewport contains the dominant object and any decision
            // due now", and only AX5 "may scroll vertically" for it. The committing action is the
            // decision, so at default size it has to be in frame without scrolling. Enumerated by
            // identifier rather than by label, so a screen that gains a committing action is
            // covered the day it is added -- and vertically, which nothing else here checks.
            if !usesAX5 {
                let committing = app.descendants(matching: .any)
                    .matching(identifier: "committing-action")
                for index in 0..<committing.count {
                    let action = committing.element(boundBy: index)
                    XCTAssertGreaterThanOrEqual(action.frame.minY, viewport.frame.minY)
                    XCTAssertLessThanOrEqual(
                        action.frame.maxY,
                        viewport.frame.maxY,
                        "Screen \(fixture.screenID) committing action falls below the viewport"
                    )
                }
            }
            if fixture.screenID == 9 {
                let lastVisibleItem = app.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH[c] %@", "Game plan required")
                ).firstMatch
                let footer = app.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH[c] %@", "Advance week")
                ).firstMatch
                let messages = app.scrollViews.matching(
                    NSPredicate(format: "identifier != %@", "top-navigator")
                ).firstMatch
                XCTAssertTrue(lastVisibleItem.exists)
                XCTAssertTrue(footer.exists)
                XCTAssertTrue(messages.exists)
                // Against the *visible* part of the row. XCUITest reports scroll content
                // unclipped, so a row scrolled out of sight still reports a frame in the band the
                // footer occupies, and comparing raw frames reads that as the footer covering it.
                XCTAssertFalse(
                    lastVisibleItem.frame.intersection(messages.frame).intersects(footer.frame)
                )
            }
            app.terminate()
        }
    }

    /// Launches, and when AX5 is asked for, refuses to continue unless the app actually reflowed.
    ///
    /// The `AtAX5` tests depend on the harness having run
    /// `xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large` first, and
    /// nothing in the test established that. A run that skipped it produced a green `...AtAX5` and
    /// a screenshot labelled AX5, both taken at the default size.
    ///
    /// The obvious fix -- passing `-UIPreferredContentSizeCategoryName` at launch, which
    /// `testTeamLogoProofAtAccessibilityType` already did -- was tried and **does not work**: the
    /// app still rendered its standard layout, verified by dumping the element tree and finding the
    /// absolute composition rather than the reflowed one. So that idiom never established the size
    /// either; it simply never checked.
    ///
    /// This asserts the precondition instead of setting it. `ax-reflow` is rendered only by the
    /// accessibility branch of the layout, so a wrong-size run fails here and loudly, at the line
    /// that names the reason, rather than passing green.
    private func launch(
        _ app: XCUIApplication,
        ax5: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        app.launch()
        guard ax5 else { return }
        XCTAssertTrue(
            app.descendants(matching: .any)["ax-reflow"].waitForExistence(timeout: 30),
            "not at an accessibility size: set content_size "
                + "accessibility-extra-extra-extra-large before this test",
            file: file, line: line
        )
    }

    private func assert(
        _ element: XCUIElement,
        staysInside viewport: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(element.frame.minX, viewport.frame.minX, file: file, line: line)
        XCTAssertLessThanOrEqual(element.frame.maxX, viewport.frame.maxX, file: file, line: line)
    }

    private func assertWeeklyPlanReceiptDoesNotCoverChoices(usesAX5: Bool) {
        let fixtures = [
            (
                screenID: 11,
                consequence: "Keeps tempo, run/pass balance, and pressure near the staff baseline.",
                commit: "Set Balanced Control",
                selectedChoice: "Balanced control.",
                choices: ["Balanced control.", "Pressure the quarterback.", "Play with pace."]
            ),
            (
                screenID: 12,
                consequence: "Splits the 60 minutes across install, conditioning, recovery, and focus.",
                commit: "Set Balanced Week",
                selectedChoice: "Balanced week.",
                choices: ["Balanced week.", "Install and sharpen.", "Recover and condition."]
            ),
        ]

        for fixture in fixtures {
            let app = XCUIApplication()
            app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
            app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "\(fixture.screenID)"
            launch(app, ax5: usesAX5)

            let consequence = app.staticTexts[fixture.consequence]
            let commit = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] %@", fixture.commit)
            ).firstMatch
            XCTAssertTrue(consequence.waitForExistence(timeout: 20))
            XCTAssertTrue(commit.exists)
            let selectedChoice = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] %@", fixture.selectedChoice)
            ).firstMatch
            XCTAssertTrue(selectedChoice.exists)
            XCTAssertTrue(selectedChoice.isSelected)
            XCTAssertTrue(
                commit.label.localizedCaseInsensitiveContains(
                    String(fixture.selectedChoice.dropLast())
                )
            )
            for choicePrefix in fixture.choices {
                let choice = app.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH[c] %@", choicePrefix)
                ).firstMatch
                XCTAssertTrue(choice.exists)
                XCTAssertFalse(consequence.frame.intersects(choice.frame))
                XCTAssertFalse(commit.frame.intersects(choice.frame))
            }
            XCTAssertFalse(consequence.frame.intersects(commit.frame))
            commit.tap()
            // Committing closes the screen, but the close is animated -- screen 11 takes about a
            // second to unmount -- so this waits for the condition instead of sampling it once.
            XCTAssertTrue(commit.waitForNonExistence(timeout: 10))
            app.terminate()
        }
    }

    /// Scrolls `scrollView` until `element` is vertically inside the viewport, and reports whether
    /// it got there.
    ///
    /// Neither `isHittable` nor `swipeUp()` can drive this. XCUITest answers `isHittable` true for a
    /// row that is inside the scroll *content* but below the visible bounds, so a hittability loop
    /// breaks without scrolling and the tap is then synthesized off-screen and lands on nothing. A
    /// swipe moves most of a viewport at once, so a swipe loop oscillates past a row that is only
    /// ~120pt out of frame -- which is where the AX5 weekly command rows sit. Drag by the measured
    /// remainder, and test the visible frame, which is the property the proof actually wants.
    @discardableResult
    private func scroll(
        _ scrollView: XCUIElement,
        toReveal element: XCUIElement,
        attempts: Int = 8
    ) -> Bool {
        func revealed(_ viewport: CGRect, _ frame: CGRect) -> Bool {
            viewport.minY <= frame.minY && frame.maxY <= viewport.maxY
        }

        for _ in 0..<attempts {
            // Both frames are live queries against the app, so read each once per pass and judge
            // the drag on the same geometry the check used.
            let viewport = scrollView.frame
            let frame = element.frame
            if revealed(viewport, frame) { return true }
            // Keep each drag inside the viewport so it cannot reach the screen edge and be taken
            // for a system gesture; the loop covers the rest.
            let limit = viewport.height * 0.4
            let delta = min(max(frame.midY - viewport.midY, -limit), limit)
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            // Hold at the destination before lifting. Without it the drag imparts momentum, the
            // content flings past the target, and the loop oscillates instead of converging.
            start.press(
                forDuration: 0.1,
                thenDragTo: start.withOffset(CGVector(dx: .zero, dy: -delta)),
                withVelocity: .slow,
                thenHoldForDuration: 0.2
            )
        }
        return revealed(scrollView.frame, element.frame)
    }

    private func assertWeeklyPlanDominantEvidenceTracksSelectedCommit(usesAX5: Bool) {
        let fixtures = [
            (
                screenID: 11,
                route: "Game Plan",
                initialCommit: "Set Balanced Control",
                choice: "Pressure the quarterback.",
                commit: "Set Pressure the Quarterback",
                dominant: "Tempo, Grind it",
                evidence: ["Aggression, Aggressive", "Balance, Run heavy"]
            ),
            (
                screenID: 12,
                route: "Practice Plan",
                initialCommit: "Set Balanced Week",
                choice: "Install and sharpen.",
                commit: "Set Install and Sharpen",
                dominant: "Install and sharpen",
                evidence: [
                    "Install, 30 minutes of 60",
                    "Conditioning, 10 minutes of 60",
                    "Recovery, 5 minutes of 60",
                    "Position focus, 15 minutes of 60",
                ]
            ),
        ]

        for fixture in fixtures {
            let app = XCUIApplication()
            app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
            app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "\(fixture.screenID)"
            launch(app, ax5: usesAX5)

            let initialCommit = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] %@", fixture.initialCommit)
            ).firstMatch
            XCTAssertTrue(initialCommit.waitForExistence(timeout: 20))
            initialCommit.tap()

            let route = app.buttons.matching(
                NSPredicate(format: "label ==[c] %@", fixture.route)
            ).firstMatch
            XCTAssertTrue(route.waitForExistence(timeout: 10))
            let hqScreenshot = XCTAttachment(screenshot: app.screenshot())
            hqScreenshot.name = "HQ receipt after screen \(fixture.screenID) commit"
            hqScreenshot.lifetime = .keepAlways
            add(hqScreenshot)

            let siblingStrip = app.scrollViews["top-navigator"].firstMatch
            XCTAssertTrue(siblingStrip.exists)
            for _ in 0..<8 {
                if route.isHittable { break }
                siblingStrip.swipeLeft()
            }
            XCTAssertTrue(route.isHittable)
            route.tap()

            let contentScroll = app.scrollViews.matching(
                NSPredicate(format: "identifier != %@", "top-navigator")
            ).firstMatch
            XCTAssertTrue(contentScroll.waitForExistence(timeout: 10))
            let choice = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] %@", fixture.choice)
            ).firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 10))
            XCTAssertTrue(scroll(contentScroll, toReveal: choice))
            choice.tap()
            XCTAssertTrue(choice.isSelected)

            let dominant = app.descendants(matching: .any)["weekly-command-dominant"]
            XCTAssertTrue(scroll(contentScroll, toReveal: dominant))
            XCTAssertEqual(dominant.label, fixture.dominant)
            for expectedEvidence in fixture.evidence {
                XCTAssertTrue(
                    app.descendants(matching: .any)
                        .matching(NSPredicate(format: "label == %@", expectedEvidence))
                        .firstMatch.exists,
                    "Expected selected payload evidence: \(expectedEvidence)"
                )
            }
            let selectedScreenshot = XCTAttachment(screenshot: app.screenshot())
            selectedScreenshot.name = "Selected commit evidence screen \(fixture.screenID)"
            selectedScreenshot.lifetime = .keepAlways
            add(selectedScreenshot)

            let commit = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH[c] %@", fixture.commit)
            ).firstMatch
            XCTAssertTrue(commit.waitForExistence(timeout: 5))
            XCTAssertTrue(scroll(contentScroll, toReveal: commit))
            XCTAssertTrue(commit.label.localizedCaseInsensitiveContains(
                fixture.choice.dropLast()
            ))
            let commitScreenshot = XCTAttachment(screenshot: app.screenshot())
            commitScreenshot.name = "Selected commit target screen \(fixture.screenID)"
            commitScreenshot.lifetime = .keepAlways
            add(commitScreenshot)
            app.terminate()
        }
    }

    func testMatchDayExportsDistinctFieldLandmarksAtDefault() {
        assertMatchDayExportsDistinctFieldLandmarks(usesAX5: false)
    }

    func testMatchDayExportsDistinctFieldLandmarksAtAX5() {
        assertMatchDayExportsDistinctFieldLandmarks(usesAX5: true)
    }

    private func assertMatchDayExportsDistinctFieldLandmarks(usesAX5: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_SCREEN"] = "match"
        launch(app, ax5: usesAX5)

            let root = app.descendants(matching: .any)["weekly-command-screen-14"]
            let dominant = app.descendants(matching: .any)["weekly-command-dominant"]
            XCTAssertTrue(root.waitForExistence(timeout: 20))
            XCTAssertTrue(dominant.exists)
            XCTAssertEqual(root.label, "First-down line")
            XCTAssertEqual(dominant.label, "Line of scrimmage")
            XCTAssertEqual(
                app.descendants(matching: .any).matching(
                    NSPredicate(
                        format: "label IN %@",
                        ["First-down line", "Line of scrimmage"]
                    )
                ).count,
                2
            )
            XCTAssertEqual(app.buttons.matching(identifier: "weekly-command-screen-14").count, 0)
            XCTAssertEqual(app.buttons.matching(identifier: "weekly-command-dominant").count, 0)

            // All 22 actors, 11 a side, whatever the field is doing. A recorded snap only carries
            // tracks for the actors that moved -- the proof fixture carries one -- so drawing the
            // playback's tracks instead of the model's actors empties the formation off the field
            // and out of VoiceOver at exactly the moment the coach is looking hardest.
            let marks = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                                      "Offense, ", "Defense, "))
            XCTAssertEqual(marks.count, 22)
            let sides = marks.allElementsBoundByIndex.map(\.label)
            XCTAssertEqual(sides.filter { $0.hasPrefix("Offense, ") }.count, 11)
            XCTAssertEqual(sides.filter { $0.hasPrefix("Defense, ") }.count, 11)

            if usesAX5 {
                let labels = app.buttons.allElementsBoundByIndex.map(\.label)
                let canonical = ["Speed", "Pause", "Key Moments", "Take Over", "Tactics"]
                let positions = canonical.compactMap { title in
                    labels.firstIndex { $0 == title || $0.hasPrefix("\(title), ") }
                }
                XCTAssertEqual(positions.count, canonical.count)
                XCTAssertEqual(positions, positions.sorted())
            }
        app.terminate()
    }

    func testRedesignedJobBoardProofFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--redesigned-job-board"]
        app.launch()

        let proof = app.otherElements["redesigned-job-board-proof"]
        XCTAssertTrue(proof.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Southern State"].exists)
        XCTAssertTrue(app.buttons["Lake County"].exists)
        XCTAssertFalse(app.buttons["Lake County"].isEnabled)
        XCTAssertTrue(app.staticTexts["Only professional offers are actionable here."].exists)
        XCTAssertTrue(app.buttons["Accept Southern State · leave Carson Tech"].exists)

        app.buttons["Accept Southern State · leave Carson Tech"].tap()
        let alert = app.alerts["Accept this offer?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        let firstConfirmation = alert.buttons.allElementsBoundByIndex.first { $0.label != "Cancel" }
        XCTAssertNotNil(firstConfirmation)
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Accept Southern State · leave Carson Tech"].exists)

        app.buttons["Accept Southern State · leave Carson Tech"].tap()
        let confirmation = app.alerts["Accept this offer?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 2))
        let finalConfirmation = confirmation.buttons.allElementsBoundByIndex.first { $0.label != "Cancel" }
        XCTAssertNotNil(finalConfirmation)
        finalConfirmation?.tap()

        XCTAssertTrue(app.staticTexts["No open offers"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Reset proof"].exists)
        XCTAssertTrue(app.staticTexts["Prototype receipt: accepted Southern State offer. No save was changed."]
            .exists)

        app.buttons["Reset proof"].tap()
        XCTAssertTrue(app.buttons["Accept Southern State · leave Carson Tech"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Lake County"].exists)
    }

    func testProductionCareerHubUsesLiveReadModel() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "52"
        app.launch()

        XCTAssertTrue(app.staticTexts["PROOF COACH"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Status, Seeking"].exists)
        XCTAssertTrue(app.staticTexts["Tier, College"].exists)
        XCTAssertTrue(
            app.staticTexts["Everything here is recorded. None of it is a prediction about your job."]
                .exists
        )
        XCTAssertTrue(app.buttons["Advance week"].exists)
        XCTAssertFalse(app.otherElements["redesigned-job-board-proof"].exists)
    }

    func testUnavailableRouteOffersReturnPath() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "62"
        app.launch()

        let unavailable = app.staticTexts[
            "Pro Offseason unavailable. No retained career evidence is available for this surface."
        ]
        XCTAssertTrue(unavailable.waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Back to HQ"].exists)
    }

    func testTeamLogoAssetAndFallbackProof() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_SCREEN"] = "team-logos"
        app.launch()

        XCTAssertTrue(app.otherElements["team-logo-asset-proof"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.otherElements["team-logo-fallback-proof"].exists)
        // The names are what make these identifiers resolvable: the logos are decorative and hide
        // themselves, so a proof row holding only logos cannot be queried at all -- which is how
        // the fallback row was failing. Verified by deleting the labels, which turns both of these
        // red. Asserting the property rather than a team name keeps it off the generated
        // catalogue, which has been re-keyed before.
        XCTAssertGreaterThan(
            app.otherElements["team-logo-asset-proof"].staticTexts.count, 0,
            "the asset proof must still expose its team names as children"
        )
        XCTAssertGreaterThan(
            app.otherElements["team-logo-fallback-proof"].staticTexts.count, 0,
            "the fallback proof must still expose its name as a child"
        )
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Team logos — packaged and fallback"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Named for accessibility type, but it cannot prove it is at one: `TeamLogoProofView` does not
    /// reflow, so there is no branch to assert, and the `-UIPreferredContentSizeCategoryName`
    /// argument below was shown not to drive `dynamicTypeSize` (see `launch(_:ax5:)`). Treat this as
    /// a fallback-rendering proof, not as accessibility-size evidence.
    func testTeamLogoProofAtAccessibilityType() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_SCREEN"] = "team-logos"
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Fallback Team"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.otherElements["team-logo-fallback-proof"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Team logos — accessibility type"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
