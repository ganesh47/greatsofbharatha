import XCTest

@MainActor
final class StoryRemoteJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(route: String? = nil) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.tv.story.\(UUID().uuidString)"
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        // TV must ignore the optional experimental root.
        app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "1"
        if let route { app.launchEnvironment["GOB_CAPTURE_ROUTE"] = route }
        app.launch()
    }

    private func moveFocus(to identifier: String, direction: XCUIRemote.Button = .down,
                           file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
        for _ in 0..<30 {
            if target.hasFocus { return }
            if let current = app.buttons.allElementsBoundByIndex.first(where: { $0.hasFocus }) {
                let destination = target.frame
                let origin = current.frame
                let vertical = destination.midY - origin.midY
                let horizontal = destination.midX - origin.midX
                if abs(vertical) > max(30, origin.height / 2) {
                    XCUIRemote.shared.press(vertical > 0 ? .down : .up)
                } else if abs(horizontal) > 30 {
                    XCUIRemote.shared.press(horizontal > 0 ? .right : .left)
                } else {
                    XCUIRemote.shared.press(direction)
                }
            } else {
                XCUIRemote.shared.press(direction)
            }
        }
        XCTFail("Remote could not focus \(identifier)", file: file, line: line)
    }

    private func choose(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        moveFocus(to: identifier, file: file, line: line)
        XCUIRemote.shared.press(.select)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDefaultStoryRootIgnoresExperimentalFlag() {
        launch()
        XCTAssertTrue(app.buttons["home-primary-lesson"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["pilot-home-continue"].exists)
        moveFocus(to: "home-primary-lesson")
        XCTAssertTrue(app.buttons["home-primary-lesson"].hasFocus)
        capture("tv-story-home-focused")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["story-move-to-place-clues-button"].waitForExistence(timeout: 10))
        capture("tv-story-discovery")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["home-primary-lesson"].waitForExistence(timeout: 10))
    }

    func testDefaultChapterJourneyRetryResumeAndAlbumPlacement() {
        launch()
        choose("home-primary-lesson")
        choose("story-discovery-hill")
        XCTAssertEqual(app.buttons["story-discovery-hill"].value as? String, "Discovered")
        XCUIRemote.shared.press(.menu)
        choose("home-primary-lesson")
        XCTAssertEqual(app.buttons["story-discovery-hill"].value as? String, "Discovered")
        choose("story-move-to-place-clues-button")
        choose("fort-choice-place-shivneri")
        XCTAssertTrue(app.buttons["fort-check-button"].hasFocus)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["place-clues-got-it-button"].hasFocus)
        XCUIRemote.shared.press(.select)
        choose("recall-choice-scene-1-shivneri-rajgad")
        XCTAssertTrue(app.buttons["recall-check-button"].hasFocus)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["recall-feedback"].label.contains("Let's look again"))
        XCTAssertFalse(app.buttons["recall-reward-button"].exists)
        capture("tv-gentle-recall-retry")
        choose("recall-choice-scene-1-shivneri-shivneri")
        choose("recall-check-button")
        XCTAssertTrue(app.buttons["recall-reward-button"].waitForExistence(timeout: 10))
        choose("recall-reward-button")
        capture("tv-earned-keepsake")
        choose("reward-album-button")
        choose("album-place-reward-birth-fort-card")
        XCTAssertTrue(app.staticTexts["album-placed-reward-birth-fort-card"].waitForExistence(timeout: 10))
        capture("tv-album-placement")
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home-primary-lesson"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["home-primary-lesson"].label.contains("Torna"))
    }

    func testFortFocusAndSelectionRequireExplicitCheck() {
        launch(route: "place-shivneri")
        moveFocus(to: "fort-choice-place-shivneri")
        capture("tv-fort-choice-focused")
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        XCUIRemote.shared.press(.select)
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        moveFocus(to: "fort-check-button")
        XCTAssertTrue(app.buttons["fort-check-button"].isEnabled)
        capture("tv-fort-selected-before-check")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].waitForExistence(timeout: 10))
        capture("tv-fort-found")
    }
}
