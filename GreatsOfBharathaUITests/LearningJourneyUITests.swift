import XCTest

@MainActor
final class LearningJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.ui.\(UUID().uuidString)"
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
    }

    private func launch(largeText: Bool = false) {
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let element = app.buttons[identifier].firstMatch
        _ = element.waitForExistence(timeout: 2)
        for _ in 0..<24 {
            if element.exists && element.isHittable { break }
            let scroll = app.scrollViews.firstMatch
            if element.exists && !element.frame.isEmpty && element.frame.minY < scroll.frame.midY {
                scroll.swipeDown()
            } else {
                scroll.swipeUp()
            }
        }
        if !element.exists || !element.isHittable { capture("unreachable-" + identifier) }
        XCTAssertTrue(element.exists, "Missing \(identifier)", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Cannot reach \(identifier)", file: file, line: line)
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
        app.tabBars.buttons["Album"].tap()
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
        app.tabBars.buttons["Album"].tap()
        openParentSettings()
        XCTAssertTrue(narration.waitForExistence(timeout: 10))
        XCTAssertEqual(narration.value as? String, "0")
    }

    func testConnectedQuizAndMatchingSurviveRelaunch() {
        app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "1"
        launch()
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
        launch(largeText: true)
        tap("home-primary-lesson")
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        completeRecognition()
        capture("11-landscape-quiz")
    }

    func testLargeTextJourneyCanReachQuiz() {
        launch(largeText: true)
        tap("home-primary-lesson")
        completeRecognition()
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
