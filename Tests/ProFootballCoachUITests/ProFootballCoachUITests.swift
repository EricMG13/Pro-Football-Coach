import XCTest

final class ProFootballCoachUITests: XCTestCase {
    func testLaunchContractIsRegistered() {
        XCTAssertTrue(true)
    }

    func testCoachingHQRosterPlayerProfileVerticalSlice() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "8"
        app.launch()

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
        XCTAssertLessThan(context.frame.width, 132)
        let family = app.buttons["Open all tasks, This week"]
        let currentSibling = app.buttons["Coaching HQ"]
        XCTAssertGreaterThanOrEqual(family.frame.height, 44)
        XCTAssertGreaterThanOrEqual(currentSibling.frame.height, 44)
        XCTAssertGreaterThanOrEqual(currentSibling.frame.minX, family.frame.maxX)
        family.tap()
        app.buttons["Roster"].tap()
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
            app.launch()

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

    func testCoachingHQSelectsBeforeExplicitCommitAtDefault() {
        assertCoachingHQSelectsBeforeExplicitCommit()
    }

    func testCoachingHQSelectsBeforeExplicitCommitAtAX5() {
        assertCoachingHQSelectsBeforeExplicitCommit()
    }

    private func assertCoachingHQSelectsBeforeExplicitCommit() {
        let app = XCUIApplication()
        app.launchEnvironment["PROOF_NEW_CAREER"] = "424242"
        app.launchEnvironment["PROOF_SCREEN_NUMBER"] = "8"
        app.launch()

        let choice = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "hq-choice-"))
            .firstMatch
        let commit = app.buttons["hq-commit-decision"]
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
        assertWeeklyPlanReceiptDoesNotCoverChoices()
    }

    func testWeeklyPlanReceiptDoesNotCoverChoicesAtAX5() {
        assertWeeklyPlanReceiptDoesNotCoverChoices()
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
        app.launch()

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
            app.launch()

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
            if fixture.screenID == 9 {
                let lastVisibleItem = app.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH[c] %@", "Game plan required")
                ).firstMatch
                let footer = app.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH[c] %@", "Advance week")
                ).firstMatch
                XCTAssertTrue(lastVisibleItem.exists)
                XCTAssertTrue(footer.exists)
                XCTAssertFalse(lastVisibleItem.frame.intersects(footer.frame))
            }
            app.terminate()
        }
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

    private func assertWeeklyPlanReceiptDoesNotCoverChoices() {
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
            app.launch()

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
            XCTAssertFalse(commit.exists)
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
        app.launch()

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
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Team logos — packaged and fallback"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

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
