import XCTest

@MainActor
final class AtlasRemoteUITests: XCTestCase {
    private var app: XCUIApplication!

    private let remote = XCUIRemote.shared
    private func launch(map: Bool = true) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.tv.ui.atlas." + UUID().uuidString
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
        XCTAssertTrue(app.buttons["tv-home-continue"].waitForExistence(timeout: 10))
        if map {
            select("tv-home-map")
        } else {
            select("tv-home-continue")
            TVKnowledgeUITestJourney.finishStory(app: app, select: { select($0) })
            select("tv-discovery-continue")
        }
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Exercise the actual directional focus engine. No element.tap(), pointer, or debug route bypasses navigation.
    private func focus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier].firstMatch
        let exists = target.waitForExistence(timeout: 10)
        if !exists {
            capture("missing-" + identifier)
            print("Missing remote target \(identifier):\n" + app.debugDescription)
        }
        XCTAssertTrue(exists, "Missing \(identifier)", file: file, line: line)
        XCTAssertTrue(target.isEnabled, "Disabled \(identifier)", file: file, line: line)
        var attemptedDirections: [String: Set<String>] = [:]
        var recoveryIndex = 0
        var capturedLostFocus = false
        let recoveryDirections: [XCUIRemote.Button] = [.up, .down, .left, .right]
        for _ in 0..<45 {
            if target.hasFocus { return }
            let current = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            if !current.exists {
                if !capturedLostFocus {
                    capture("focus-transition-" + identifier)
                    print("Before focus recovery for \(identifier):\n" + app.debugDescription)
                    capturedLostFocus = true
                }
                // Let the native focus and scroll transition settle before sending another direction.
                let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: current)
                if XCTWaiter.wait(for: [settled], timeout: 1) == .completed { continue }
                remote.press(recoveryDirections[recoveryIndex % recoveryDirections.count])
                recoveryIndex += 1
                continue
            }
            let deltaX = target.frame.midX - current.frame.midX
            let deltaY = target.frame.midY - current.frame.midY
            let horizontal: (String, XCUIRemote.Button) = deltaX >= 0 ? ("right", .right) : ("left", .left)
            let vertical: (String, XCUIRemote.Button) = deltaY >= 0 ? ("down", .down) : ("up", .up)
            let ordered = abs(deltaY) > 65
                ? [vertical, horizontal, ("down", .down), ("up", .up), ("left", .left), ("right", .right)]
                : [horizontal, vertical, ("down", .down), ("up", .up), ("left", .left), ("right", .right)]
            let key = current.identifier + "@" + String(Int(current.frame.midY))
            let tried = attemptedDirections[key, default: []]
            guard let direction = ordered.first(where: { !tried.contains($0.0) }) else { break }
            attemptedDirections[key, default: []].insert(direction.0)
            remote.press(direction.1)
        }
        capture("focus-failure-" + identifier)
        XCTFail("Remote cannot focus \(identifier).\n" + app.debugDescription, file: file, line: line)
    }

    private func select(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        focus(identifier, file: file, line: line)
        XCTAssertTrue(app.buttons[identifier].hasFocus, file: file, line: line)
        remote.press(.select)
    }

    func testRemoteCanSwitchRegionsAndOpenCloseUp() {
        launch()
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
        focus("map-pin-place-torna")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "TV atlas close-up"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        focus("atlas-close-up")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["atlas-close-up"].label.contains("close-up"))
    }

    func testRemotePicturePinSelectsOnlyOnActivation() {
        launch()
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
        launch(map: false)
        focus("tv-fort-place-shivneri")
        XCTAssertFalse(app.staticTexts["tv-fort-feedback"].exists)
        XCUIRemote.shared.press(.select)
        XCTAssertFalse(app.buttons["tv-fort-continue"].exists)
        XCTAssertEqual(app.buttons["tv-fort-place-shivneri"].value as? String, "Chosen")
        app.terminate()
        app.launch()
        select("tv-home-continue")
        XCTAssertEqual(app.buttons["tv-fort-place-shivneri"].value as? String, "Chosen")
        XCTAssertFalse(app.buttons["tv-fort-continue"].exists)
        capture("TV unchecked atlas choice restored before Check")
        let check = app.buttons["tv-fort-check"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        if !check.hasFocus { focus("tv-fort-check") }
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["tv-fort-continue"].waitForExistence(timeout: 5))
    }
}
