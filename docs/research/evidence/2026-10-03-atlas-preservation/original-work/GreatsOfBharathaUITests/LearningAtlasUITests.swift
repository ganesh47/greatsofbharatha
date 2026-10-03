import XCTest

@MainActor
final class LearningAtlasUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(route: String? = "places-hub", largeText: Bool = false) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        if let route { app.launchEnvironment["GOB_CAPTURE_ROUTE"] = route }
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.atlas.ui.\(UUID().uuidString)"
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier].firstMatch
        for _ in 0..<10 {
            if button.exists && button.isHittable { break }
            // Directional swipe helpers can retain the pre-rotation orientation and
            // synthesize a horizontal gesture on landscape phones. Explicit points
            // express a vertical drag in the current scroll viewport instead.
            let scrollView = app.scrollViews.firstMatch
            let surface = scrollView.exists ? scrollView : app!
            let goesDown = !button.exists || button.frame.midY >= surface.frame.midY
            let start = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: goesDown ? 0.80 : 0.25))
            let end = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: goesDown ? 0.25 : 0.80))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(button.waitForExistence(timeout: 5), identifier, file: file, line: line)
        XCTAssertTrue(button.isHittable, identifier, file: file, line: line)
        button.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testNamedPicturesAndBothRegionalMaps() {
        launch()
        XCTAssertTrue(app.buttons["atlas-region-sahyadri"].waitForExistence(timeout: 10))
        capture("atlas-01-sahyadri-portrait")
        tap("map-pin-place-shivneri")
        XCTAssertTrue(app.buttons["atlas-open-selected-place"].exists)
        tap("atlas-region-agra")
        XCTAssertTrue(app.buttons["map-pin-place-agra"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Mathura"].exists)
        tap("map-pin-place-agra")
        XCTAssertTrue(app.staticTexts["atlas-locked-place"].exists)
        XCTAssertFalse(app.buttons["atlas-open-selected-place"].exists)
        capture("atlas-02-agra-portrait")
    }

    func testCloseNeighboursAreSeparatelySelectable() {
        launch()
        tap("atlas-close-up")
        XCTAssertTrue(app.buttons["map-pin-place-torna"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["map-pin-place-rajgad"].exists)
        tap("map-pin-place-torna")
        XCTAssertEqual(app.buttons["map-pin-place-torna"].value as? String, "Selected")
        tap("map-pin-place-rajgad")
        XCTAssertEqual(app.buttons["map-pin-place-rajgad"].value as? String, "Selected")
        capture("atlas-03-torna-rajgad-close-up")
        tap("atlas-close-up")
        XCTAssertTrue(app.buttons["map-pin-place-shivneri"].exists)
    }

    func testLargeTextAndLandscapeAtlasControls() {
        launch(largeText: true)
        tap("atlas-region-agra")
        tap("atlas-place-place-agra")
        XCTAssertTrue(app.staticTexts["atlas-locked-place"].exists)
        capture("atlas-04-accessibility-text")
        app.terminate()
        launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 5), .completed)
        tap("atlas-close-up")
        tap("atlas-place-place-torna")
        XCTAssertEqual(app.buttons["atlas-place-place-torna"].value as? String, "Selected")
        capture("atlas-05-landscape")
    }

    func testEveryStoryPlaceCanBeSelectedOnAtlas() {
        for (region, ids) in [
            ("sahyadri", ["shivneri", "torna", "rajgad", "pratapgad", "purandar", "raigad"]),
            ("agra", ["agra"])
        ] {
            launch()
            if region == "agra" { tap("atlas-region-agra") }
            for id in ids {
                let identifier = "atlas-place-place-" + id
                tap(identifier)
                XCTAssertEqual(app.buttons[identifier].value as? String, "Selected")
            }
            capture("atlas-all-places-" + region)
            app.terminate()
        }
    }

    func testPictureChoiceRequiresConfirmationAndResumesSolvedPlace() {
        launch(route: nil)
        tap("home-primary-lesson")
        tap("story-move-to-place-clues-button")
        tap("map-pin-place-shivneri")
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        tap("fort-check-button")
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].waitForExistence(timeout: 10))
        capture("atlas-06-solved-picture-clue")
        app.terminate()
        app.launch()
        tap("home-primary-lesson")
        XCTAssertTrue(app.buttons["place-clues-got-it-button"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["place-clues-got-it-button"].isEnabled)
        XCTAssertFalse(app.buttons["fort-check-button"].exists)
    }
}
