import XCTest

@MainActor
final class AtlasRemoteUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(route: String = "place-shivneri") {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.tv.atlas.\(UUID().uuidString)"
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launchEnvironment["GOB_CAPTURE_ROUTE"] = route
        app.launch()
    }

    private func focus(_ identifier: String, direction: XCUIRemote.Button = .down) {
        let target = app.buttons[identifier].firstMatch
        for _ in 0..<20 {
            if target.exists { break }
            XCUIRemote.shared.press(.down)
        }
        XCTAssertTrue(target.exists, "Missing \(identifier)")
        for _ in 0..<30 {
            if target.hasFocus { return }
            if let current = app.buttons.allElementsBoundByIndex.first(where: { $0.hasFocus }) {
                let dx = target.frame.midX - current.frame.midX
                let dy = target.frame.midY - current.frame.midY
                if abs(dy) > max(30, current.frame.height / 2) {
                    XCUIRemote.shared.press(dy > 0 ? .down : .up)
                } else if abs(dx) > 30 {
                    XCUIRemote.shared.press(dx > 0 ? .right : .left)
                } else {
                    XCUIRemote.shared.press(direction)
                }
            } else {
                XCUIRemote.shared.press(direction)
            }
        }
        XCTFail("Could not focus \(identifier)")
    }

    func testRemoteCanSwitchRegionsAndOpenCloseUp() {
        launch(route: "places-hub")
        focus("atlas-region-sahyadri")
        XCUIRemote.shared.press(.right)
        XCTAssertTrue(app.buttons["atlas-region-agra"].hasFocus)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Around Agra"].firstMatch.waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.left)
        XCTAssertTrue(app.buttons["atlas-region-sahyadri"].hasFocus)
        XCUIRemote.shared.press(.select)
        focus("atlas-close-up")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Torna & Rajgad close-up"].firstMatch.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "TV atlas close-up"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["atlas-close-up"].label.contains("close-up"))
    }

    func testRemotePicturePinSelectsOnlyOnActivation() {
        launch(route: "places-hub")
        focus("map-pin-place-shivneri")
        XCTAssertFalse(app.buttons["map-pin-place-shivneri"].value as? String == "Selected")
        XCUIRemote.shared.press(.select)
        XCTAssertEqual(app.buttons["map-pin-place-shivneri"].value as? String, "Selected")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "TV picture pin selected"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testRemoteFocusDoesNotAnswerAndSelectionWorks() {
        launch()
        focus("fort-choice-place-shivneri")
        XCTAssertFalse(app.staticTexts["fort-feedback"].exists)
        XCUIRemote.shared.press(.select)
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        let check = app.buttons["fort-check-button"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        if !check.hasFocus { focus("fort-check-button") }
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].label.contains("Found it!"))
    }
}
