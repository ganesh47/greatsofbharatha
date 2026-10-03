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
    }

    private func launch(largeText: Bool = false, pilot: Bool = false) {
        configureApplication()
        if pilot { app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "1" }
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func materialize(_ identifier: String) -> XCUIElement {
        let element = app.buttons[identifier].firstMatch
        for _ in 0..<10 {
            let scrollView = app.scrollViews.firstMatch
            let surface: XCUIElement = scrollView.exists ? scrollView : app
            let viewport = surface.frame.intersection(app.windows.firstMatch.frame).insetBy(dx: 8, dy: 12)
            if element.exists && element.isHittable {
                let frame = element.frame
                let center = CGPoint(x: frame.midX, y: frame.midY)
                let visibleHeight = frame.intersection(viewport).height
                // isHittable can be true for a sliver at the viewport edge while tap()
                // still targets the offscreen card center on landscape phones.
                if viewport.contains(center) && visibleHeight >= min(frame.height, viewport.height * 0.65) { break }
            }
            let goesDown = !element.exists || element.frame.midY >= viewport.midY
            let start = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: goesDown ? 0.80 : 0.25))
            let end = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: goesDown ? 0.25 : 0.80))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        return element
    }

    private func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = materialize(identifier)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(identifier)", file: file, line: line)
        XCTAssertTrue(element.isEnabled, "Disabled \(identifier)", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Offscreen \(identifier)", file: file, line: line)
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        XCTAssertEqual(app.buttons["story-discovery-hill"].value as? String, "Discovered")
        XCTAssertTrue(app.staticTexts["story-discovery-detail"].exists)
        capture("02-discover-shivneri")
        tap("story-move-to-place-clues-button")
        capture("03-offline-fort-challenge")
        tap("fort-choice-place-shivneri")
        XCTAssertEqual(app.buttons["fort-choice-place-shivneri"].value as? String, "Chosen")
        tap("fort-check-button")
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].exists)
        tap("place-clues-got-it-button")
        tap("recall-choice-scene-1-shivneri-rajgad")
        XCTAssertEqual(app.buttons["recall-choice-scene-1-shivneri-rajgad"].value as? String, "Selected")
        tap("recall-check-button")
        XCTAssertFalse(app.buttons["recall-reward-button"].exists)
        capture("04-gentle-retry")
        tap("recall-choice-scene-1-shivneri-shivneri")
        XCTAssertEqual(app.buttons["recall-choice-scene-1-shivneri-shivneri"].value as? String, "Selected")
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
        tap("home-primary-lesson")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "story-discovery-")).count == 3)
        tap("story-move-to-place-clues-button")
        XCTAssertTrue(materialize("fort-choice-place-torna").exists)
        XCTAssertTrue(app.buttons["fort-choice-place-rajgad"].exists)
        tap("fort-choice-place-torna")
        tap("fort-check-button")
        tap("place-clues-next-button")
        tap("fort-choice-place-rajgad")
        tap("fort-check-button")
        XCTAssertTrue(app.buttons["place-clues-got-it-button"].isEnabled)
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
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["pilot-home-continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["pilot-home-continue"].label.contains("Torna"))
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
        XCTAssertEqual(app.buttons["fort-choice-place-shivneri"].value as? String, "Chosen")
        tap("fort-check-button")
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].exists)
        tap("place-clues-got-it-button")
        tap("recall-choice-scene-1-shivneri-shivneri")
        tap("recall-check-button")
        XCTAssertTrue(app.buttons["recall-reward-button"].waitForExistence(timeout: 10))
    }
}
