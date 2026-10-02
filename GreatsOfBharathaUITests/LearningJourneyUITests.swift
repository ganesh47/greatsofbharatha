import XCTest

@MainActor
final class LearningJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    private func configureApplication() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.ui.\(UUID().uuidString)"
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launchEnvironment["GOB_NAV_TRACE"] = "1"
        addTeardownBlock { @MainActor [weak self] () async throws -> Void in
            self?.captureNavigationTrace()
        }
    }

    private func captureNavigationTrace() {
        if let app {
            let probe = app.descendants(matching: .any)["gob-nav-trace"].firstMatch
            let text = probe.exists ? (probe.value as? String ?? "trace-value-missing") : "trace-probe-missing\n" + app.debugDescription
            let attachment = XCTAttachment(string: text)
            attachment.name = "synthetic-navigation-trace"
            attachment.lifetime = .keepAlways
            add(attachment)
            print("GOB_NAV_TRACE\n" + text)
        }
    }

    private func launch(largeText: Bool = false, pilot: Bool = false) {
        configureApplication()
        if pilot { app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "1" }
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = app.buttons[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
        XCTAssertTrue(element.isEnabled, "Disabled \(identifier)", file: file, line: line)
        element.tap()
    }

    private func openParentSettings() {
        app.buttons["Parent settings"].tap()
        let question = app.staticTexts["parent-gate-question"]
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        let numbers = question.label.split { !$0.isNumber }.compactMap { Int($0) }
        XCTAssertEqual(numbers.count, 2)
        guard numbers.count == 2 else { return }
        let answer = app.textFields["parent-gate-answer"]
        answer.tap()
        answer.typeText(String(numbers.reduce(0, +)) + "\n")
        tap("parent-gate-confirm")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testRetryRewardAndProgressSurviveRelaunch() {
        launch()
        capture("01-home")
        tap("home-primary-lesson")
        tap("story-discovery-hill")
        tap("story-discovery-gate")
        tap("story-discovery-book")
        capture("02-discover-shivneri")
        tap("story-move-to-place-clues-button")
        capture("03-offline-fort-challenge")
        tap("fort-choice-place-shivneri")
        tap("place-clues-got-it-button")
        tap("recall-choice-scene-1-shivneri-rajgad")
        tap("recall-check-button")
        XCTAssertFalse(app.buttons["recall-reward-button"].exists)
        capture("04-gentle-retry")
        tap("recall-choice-scene-1-shivneri-shivneri")
        tap("recall-check-button")
        tap("recall-reward-button")
        capture("05-earned-keepsake")
        tap("reward-album-button")
        tap("album-place-reward-birth-fort-card")
        XCTAssertTrue(app.staticTexts["album-placed-reward-birth-fort-card"].exists || app.otherElements["album-placed-reward-birth-fort-card"].exists)
        capture("06-album")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home-primary-lesson"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["home-primary-lesson"].label.localizedCaseInsensitiveContains("Torna"),
                      "The next chapter should remain unlocked after a cold launch")
        capture("07-next-chapter-after-relaunch")
    }

    func testNarrationPreferenceSurvivesRelaunch() {
        launch()
        app.buttons["Album"].firstMatch.tap()
        openParentSettings()
        let narration = app.switches["parent-narration-toggle"]
        XCTAssertTrue(narration.waitForExistence(timeout: 10))
        for _ in 0..<8 {
            if narration.isHittable { break }
            app.swipeUp()
        }
        XCTAssertEqual(narration.value as? String, "1")
        narration.tap()
        XCTAssertEqual(narration.value as? String, "0")
        capture("08-functional-parent-settings")
        app.terminate()
        app.launch()
        app.buttons["Album"].firstMatch.tap()
        openParentSettings()
        XCTAssertTrue(narration.waitForExistence(timeout: 10))
        XCTAssertEqual(narration.value as? String, "0")
        tap("Done")
        app.buttons["Story"].firstMatch.tap()
        tap("home-primary-lesson")
        XCTAssertFalse(app.buttons["listen-scene-1-shivneri-story"].exists)
        XCTAssertTrue(app.staticTexts["Read-aloud is off in parent settings."].firstMatch.exists)
    }

    func testConnectedQuizAndMatchingSurviveRelaunch() {
        launch(pilot: true)
        tap("pilot-home-continue")
        tap("pilot-quiz-me")
        tap("pilot-choice-shivneri")
        tap("Play a matching game")
        tap("match-tile-match-shivneri-birth-fort-left")
        tap("match-tile-match-shivneri-birth-fort-right")
        XCTAssertTrue(app.staticTexts["All pairs matched. Your Chronicle remembers this activity."].exists)
        capture("10-connected-matching")
        tap("matching-done")
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["matching-done"].exists, "Done must leave the nested quiz and matching destinations")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pilot-home-continue"].label.contains("Torna"))
    }

    func testMatchingSwitchRetrySelectionAndDoneSurviveRelaunch() {
        launch(pilot: true)
        openSecondMatchingAdventure()
        XCTAssertTrue(app.otherElements["matching-board-horizontal"].exists)
        capture("matching-initial-two-panels")
        let torna = "match-tile-match-torna-first-big-fort-left"
        let rajgad = "match-tile-match-rajgad-early-capital-left"
        tap(torna)
        XCTAssertEqual(app.buttons[torna].value as? String, "Selected")
        capture("matching-selected")
        tap(rajgad)
        XCTAssertEqual(app.buttons[torna].value as? String, "Available")
        XCTAssertEqual(app.buttons[rajgad].value as? String, "Selected")
        XCTAssertFalse(app.descendants(matching: .any)["matching-feedback"].firstMatch.label.contains("Try another partner"),
                       "Switching in one panel must not produce retry feedback")
        tap("match-tile-match-torna-first-big-fort-right")
        XCTAssertEqual(app.buttons[rajgad].value as? String, "Selected", "A wrong partner keeps the child's chosen source")
        XCTAssertEqual(app.buttons["match-tile-match-torna-first-big-fort-right"].value as? String, "Available")
        capture("matching-gentle-mismatch")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pilot-home-continue"].label.contains("Torna"), "Resume the partial matching adventure")
        tap("pilot-home-continue")
        XCTAssertTrue(app.buttons[rajgad].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons[rajgad].value as? String, "Selected")
        tap("matching-cancel-selection")
        XCTAssertEqual(app.buttons[rajgad].value as? String, "Available")
        tap(torna)
        tap("match-tile-match-torna-first-big-fort-right")
        tap(rajgad)
        tap("match-tile-match-rajgad-early-capital-right")
        XCTAssertEqual(app.buttons[torna].value as? String, "Matched")
        XCTAssertEqual(app.buttons[rajgad].value as? String, "Matched")
        XCTAssertTrue(app.descendants(matching: .any)["matching-recap-match-torna-first-big-fort"].firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["matching-recap-match-rajgad-early-capital"].firstMatch.exists)
        capture("matching-completed-associations")
        tap("matching-done")
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pilot-home-continue"].label.contains("Pratapgad"))
        XCTAssertFalse(app.buttons["matching-done"].exists)
    }

    func testLargeTextMatchingUsesStackedPanelsAndReachableCompletion() {
        launch(largeText: true, pilot: true)
        openSecondMatchingAdventure()
        XCTAssertTrue(app.otherElements["matching-board-stacked"].exists)
        XCTAssertFalse(app.otherElements["matching-board-horizontal"].exists)
        tap("listen-matching-instructions")
        XCTAssertTrue(app.buttons["stop-matching-instructions"].isEnabled)
        tap("stop-matching-instructions")
        capture("matching-accessibility-text-stacked")
        tap("match-tile-match-torna-first-big-fort-left")
        tap("match-tile-match-torna-first-big-fort-right")
        tap("match-tile-match-rajgad-early-capital-left")
        tap("match-tile-match-rajgad-early-capital-right")
        XCTAssertTrue(app.buttons["matching-done"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["matching-done"].isHittable, "Completion must clear the real tab bar safe area")
        capture("matching-accessibility-text-completed")
        tap("matching-done")
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
    }

    func testMatchingMotionAndNarrationFollowParentSettings() {
        launch(pilot: true)
        app.buttons["Album"].firstMatch.tap()
        openParentSettings()
        let narration = app.switches["parent-narration-toggle"]
        for _ in 0..<8 {
            if narration.isHittable { break }
            app.swipeUp()
        }
        XCTAssertEqual(narration.value as? String, "1")
        narration.tap()
        XCTAssertEqual(narration.value as? String, "0")
        let calm = app.switches["parent-calm-toggle"]
        XCTAssertTrue(calm.waitForExistence(timeout: 10))
        XCTAssertEqual(calm.value as? String, "1")
        calm.tap()
        XCTAssertEqual(calm.value as? String, "0")
        tap("Done")
        app.buttons["Learn"].firstMatch.tap()
        tap("pilot-home-continue")
        tap("pilot-quiz-me")
        tap("pilot-choice-shivneri")
        tap("Play a matching game")
        XCTAssertFalse(app.buttons["listen-matching-instructions"].exists)
        XCTAssertTrue(app.staticTexts["Read-aloud is off in parent settings."].firstMatch.exists)
        tap("match-tile-match-shivneri-birth-fort-left")
        tap("match-tile-match-shivneri-birth-fort-right")
        XCTAssertTrue(app.descendants(matching: .any)["matching-recap-match-shivneri-birth-fort"].firstMatch.exists)
        capture("matching-motion-enabled-narration-off-recap")
        tap("matching-done")
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pilot-home-continue"].label.contains("Torna"))
    }

    private func openSecondMatchingAdventure() {
        tap("pilot-home-continue")
        tap("pilot-quiz-me")
        tap("pilot-choice-shivneri")
        tap("Play a matching game")
        tap("match-tile-match-shivneri-birth-fort-left")
        tap("match-tile-match-shivneri-birth-fort-right")
        tap("matching-done")
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        tap("pilot-home-continue")
        tap("pilot-quiz-me")
        tap("pilot-choice-rajgad")
        tap("Play a matching game")
    }

    func testLandscapeJourneyCanReachQuiz() {
        launch()
        tap("home-primary-lesson")
        XCUIDevice.shared.orientation = .landscapeLeft
        let orientation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.windows.firstMatch.frame.width > self.app.windows.firstMatch.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [orientation], timeout: 10), .completed)
        defer { XCUIDevice.shared.orientation = .portrait }
        completeRecognition()
        capture("11-landscape-quiz")
    }

    func testLargeTextJourneyCanReachQuiz() {
        launch(largeText: true)
        tap("home-primary-lesson")
        completeRecognition()
        tap("listen-scene-1-shivneri-question")
        XCTAssertTrue(app.buttons["stop-scene-1-shivneri-question"].isEnabled)
        tap("stop-scene-1-shivneri-question")
        XCTAssertFalse(app.buttons["stop-scene-1-shivneri-question"].isEnabled)
        capture("09-large-text-quiz")
    }

    private func completeRecognition() {
        tap("story-move-to-place-clues-button")
        tap("fort-choice-place-shivneri")
        tap("place-clues-got-it-button")
        tap("recall-choice-scene-1-shivneri-shivneri")
        tap("recall-check-button")
        XCTAssertTrue(app.buttons["recall-reward-button"].waitForExistence(timeout: 10))
    }
}
