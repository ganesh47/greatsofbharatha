import XCTest

@MainActor
final class LearningAtlasUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(route: String? = "places-hub", largeText: Bool = false, seedThroughChapter: Int? = nil) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        if let route { app.launchEnvironment["GOB_CAPTURE_ROUTE"] = route }
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.ui.enrichment.atlas.\(UUID().uuidString)"
        if let seedThroughChapter {
            app.launchEnvironment["GOB_UI_TEST_SEED_THROUGH_CHAPTER"] = String(seedThroughChapter)
        }
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "0"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func reveal(_ element: XCUIElement, in scroll: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        for attempt in 0...64 {
            let measuredFrame = element.exists ? element.frame : nil
            let targetFrame = measuredFrame.flatMap { $0.isEmpty || $0.isNull ? nil : $0 }
            let frames = scrollFrames(in: scroll)
            let viewport = frames.viewport
            let isButton = targetFrame != nil && element.elementType == .button
            if let targetFrame, frames.isVisible(targetFrame, isButton: isButton), element.isHittable {
                return
            }
            guard attempt < 64 else { break }
            guard !viewport.isNull else { continue }
            let towardEnd = targetFrame.map { $0.midY > viewport.midY } ?? (attempt < 32)
            let distance = frames.dragDistance(to: targetFrame, isButton: isButton)
            let startY = viewport.midY + (towardEnd ? distance / 2 : -distance / 2)
            let endY = viewport.midY + (towardEnd ? -distance / 2 : distance / 2)
            let start = scroll.coordinate(withNormalizedOffset: CGVector(
                dx: (viewport.midX - frames.scroll.minX) / frames.scroll.width,
                dy: (startY - frames.scroll.minY) / frames.scroll.height))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(
                dx: (viewport.midX - frames.scroll.minX) / frames.scroll.width,
                dy: (endY - frames.scroll.minY) / frames.scroll.height))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        captureInteractionFailure(element, in: scroll)
        XCTFail("Could not reach \(element)", file: file, line: line)
    }

    private func scrollFrames(in scroll: XCUIElement) -> DiscoveryScrollFrames {
        func frame(_ element: XCUIElement) -> CGRect? { element.exists ? element.frame : nil }
        return DiscoveryScrollFrames(
            window: app.windows.firstMatch.frame,
            scroll: frame(scroll) ?? .null,
            navigationBar: frame(app.navigationBars.firstMatch),
            tabBar: frame(app.tabBars.firstMatch),
            keyboard: frame(app.keyboards.firstMatch))
    }

    private func captureInteractionFailure(_ element: XCUIElement, in scroll: XCUIElement, expectedValue: String? = nil) {
        let frames = scrollFrames(in: scroll)
        let windows = app.windows.allElementsBoundByIndex.enumerated().map { index, window in
            "window[\(index)] frame=\(window.frame)"
        }.joined(separator: "\n")
        let target = element.exists
            ? "target id=\(element.identifier) frame=\(element.frame) enabled=\(element.isEnabled) hittable=\(element.isHittable) value=\(String(describing: element.value))"
            : "target absent: \(element)"
        let scrollState = scroll.exists
            ? "scroll id=\(scroll.identifier) frame=\(scroll.frame) hittable=\(scroll.isHittable)"
            : "scroll absent: \(scroll)"
        let attachment = XCTAttachment(string: """
            deviceOrientation=\(XCUIDevice.shared.orientation.rawValue)
            \(windows)
            \(frames.description)
            \(scrollState)
            \(target)
            expectedValue=\(expectedValue ?? "not applicable")

            \(app.debugDescription)
            """)
        attachment.name = "discovery-interaction-live-AX-and-frames"
        attachment.lifetime = .keepAlways
        add(attachment)
        capture("discovery-interaction-screenshot")
    }

    private func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier].firstMatch
        reveal(button, in: app.scrollViews.firstMatch, file: file, line: line)
        XCTAssertTrue(button.isEnabled, identifier, file: file, line: line)
        button.tap()
    }

    private func tapTab(_ title: String) {
        let tab = app.buttons[title].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 10), title)
        XCTAssertTrue(tab.isEnabled && tab.isHittable, title)
        tab.tap()
    }

    private func goBack() {
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
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

    func testStandaloneMapActivityRestoresUncheckedChoiceAfterRelaunch() {
        launch(route: nil)
        tapTab("Map")
        tap("map-pin-place-shivneri")
        tap("atlas-open-selected-place")
        tap("fort-choice-place-torna")
        XCTAssertEqual(app.buttons["fort-choice-place-torna"].value as? String, "Chosen")
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        app.terminate()
        app.launch()
        tapTab("Map")
        tap("map-pin-place-shivneri")
        tap("atlas-open-selected-place")
        XCTAssertEqual(app.buttons["fort-choice-place-torna"].value as? String, "Chosen")
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        tap("fort-check-button")
        XCTAssertTrue(app.staticTexts["fort-feedback"].label.contains("Let's look again"))
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        capture("atlas-standalone-unchecked-choice-relaunch")
    }

    func testFreshMapBrowseAndChoiceKeepStoryAtItsFirstStep() {
        launch(route: nil)
        let primary = app.buttons["home-primary-lesson"]
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        let initialTitle = primary.label
        tapTab("Map")
        tap("map-pin-place-shivneri")
        tap("atlas-open-selected-place")
        tap("fort-choice-place-torna")
        goBack()
        tapTab("Story")
        XCTAssertEqual(primary.label, initialTitle)
        tap("home-primary-lesson")
        XCTAssertEqual(app.staticTexts["scene-phase-progress"].label, "Step 1 of 4: Discover the story")
        XCTAssertTrue(app.buttons["story-discovery-hill"].exists)
        capture("atlas-fresh-map-keeps-story-step-one")
    }

    func testEarlierMapActivityPreservesLaterStoryContinuationAcrossRelaunch() {
        launch(route: nil, seedThroughChapter: 1)
        tap("home-primary-lesson")
        tap("story-move-to-place-clues-button")
        XCTAssertEqual(app.staticTexts["scene-phase-progress"].label, "Step 2 of 4: Fort detective")
        goBack()
        let primary = app.buttons["home-primary-lesson"]
        let continuationTitle = primary.label
        XCTAssertTrue(continuationTitle.contains("Torna"))
        tapTab("Map")
        tap("map-pin-place-shivneri")
        tap("atlas-open-selected-place")
        tap("fort-choice-place-shivneri")
        tap("fort-check-button")
        XCTAssertTrue(app.staticTexts["fort-found-place-shivneri"].exists)
        goBack()
        tapTab("Story")
        XCTAssertEqual(primary.label, continuationTitle)
        app.terminate()
        app.launch()
        XCTAssertTrue(primary.waitForExistence(timeout: 10))
        XCTAssertEqual(primary.label, continuationTitle)
        tap("home-primary-lesson")
        XCTAssertEqual(app.staticTexts["scene-phase-progress"].label, "Step 2 of 4: Fort detective")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "fort-challenge-place-torna").firstMatch.exists)
        capture("atlas-earlier-map-keeps-later-story-continuation")
    }

    func testPictureChoiceRequiresConfirmationAndResumesSolvedPlace() {
        launch(route: nil)
        tap("home-primary-lesson")
        tap("story-move-to-place-clues-button")
        tap("fort-choice-place-shivneri")
        XCTAssertEqual(app.buttons["fort-choice-place-shivneri"].value as? String, "Chosen")
        XCTAssertFalse(app.staticTexts["fort-found-place-shivneri"].exists)
        app.terminate()
        app.launch()
        tap("home-primary-lesson")
        XCTAssertEqual(app.buttons["fort-choice-place-shivneri"].value as? String, "Chosen")
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
private struct DiscoveryScrollFrames {
    let window: CGRect
    let scroll: CGRect
    let navigationBar: CGRect?
    let tabBar: CGRect?
    let keyboard: CGRect?

    var viewport: CGRect {
        let intersection = window.intersection(scroll)
        guard !intersection.isNull else { return .null }
        var minY = intersection.minY
        var maxY = intersection.maxY
        if let navigationBar, navigationBar.intersects(intersection) {
            minY = max(minY, navigationBar.maxY)
        }
        for obstruction in [tabBar, keyboard].compactMap({ $0 }) where obstruction.intersects(intersection) {
            maxY = min(maxY, obstruction.minY)
        }
        guard intersection.width > 16, maxY - minY > 16 else { return .null }
        return CGRect(x: intersection.minX, y: minY, width: intersection.width, height: maxY - minY).insetBy(dx: 8, dy: 8)
    }

    func isVisible(_ targetFrame: CGRect, isButton: Bool) -> Bool {
        let visible = viewport
        guard !visible.isNull, !targetFrame.isNull, !targetFrame.isEmpty,
              visible.contains(CGPoint(x: targetFrame.midX, y: targetFrame.midY)) else { return false }
        // Native hittability can accept a button clipped by the home indicator.
        if isButton, targetFrame.height <= visible.height {
            return targetFrame.minY >= visible.minY && targetFrame.maxY <= visible.maxY
        }
        return true
    }

    func dragDistance(to targetFrame: CGRect?, isButton: Bool = false) -> CGFloat {
        let visible = viewport
        let nearDistance = min(76, visible.height * 0.4)
        if let targetFrame {
            let gap = abs(targetFrame.midY - visible.midY)
            if gap > visible.height { return min(gap, visible.height * 0.7) }
            if isButton, targetFrame.height <= visible.height { return min(nearDistance, gap) }
        }
        return nearDistance
    }

    var description: String {
        """
        window=\(window) scroll=\(scroll)
        navigationBar=\(String(describing: navigationBar))
        tabBar=\(String(describing: tabBar))
        keyboard=\(String(describing: keyboard))
        usableViewport=\(viewport)
        """
    }
}
