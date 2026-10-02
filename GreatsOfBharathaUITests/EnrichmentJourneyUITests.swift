import XCTest

@MainActor
final class EnrichmentJourneyUITests: XCTestCase {
    private var app: XCUIApplication!
    private func launch(chapters: Int, large: Bool = false) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchEnvironment = ["GOB_UI_TEST_SUITE": "gob.ui.enrichment." + UUID().uuidString,
            "GOB_UI_TEST_RESET": "1", "GOB_UI_TEST_SEED_THROUGH_CHAPTER": String(chapters)]
        app.launchArguments = ["-UIPreferredContentSizeCategoryName",
            large ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }
    private func reveal(_ element: XCUIElement, in scroll: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        for attempt in 0...64 {
            let measuredFrame = element.exists ? element.frame : nil
            let targetFrame = measuredFrame.flatMap { $0.isEmpty || $0.isNull ? nil : $0 }
            let frames = scrollFrames(in: scroll)
            let viewport = frames.viewport
            if let targetFrame, viewport.contains(CGPoint(x: targetFrame.midX, y: targetFrame.midY)), element.isHittable {
                return
            }
            guard attempt < 64, !viewport.isNull else { break }
            let towardEnd = targetFrame.map { $0.midY > viewport.midY } ?? (attempt < 32)
            let distance = frames.dragDistance(to: targetFrame)
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

    private func scrollFrames(in scroll: XCUIElement) -> EnrichmentScrollFrames {
        func frame(_ element: XCUIElement) -> CGRect? { element.exists ? element.frame : nil }
        return EnrichmentScrollFrames(
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

    private func tap(_ id: String, scroll: String = "") {
        let button = app.buttons[id].firstMatch
        let rootTab = ["Story", "Learn", "Map", "Timeline", "Album"].contains(id)
        if rootTab || id == "review-dismiss-keyboard" {
            XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing " + id)
        } else {
            let container = scroll.isEmpty ? app.scrollViews.firstMatch : app.scrollViews[scroll].firstMatch
            reveal(button, in: container)
        }
        XCTAssertTrue(button.isHittable, "Unreachable " + id)
        XCTAssertTrue(button.isEnabled, "Disabled " + id)
        button.tap()
    }
    private func capture(_ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot())
        item.name = name
        item.lifetime = .keepAlways
        add(item)
    }
    func testSuspendedReviewAnswerSurvivesEntryThroughAnotherChapter() {
        launch(chapters: 1)
        app.terminate()
        app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "1"
        app.launch()
        tap("pilot-home-review", scroll: "pilot-home-scroll")
        if app.buttons["review-practice"].waitForExistence(timeout: 3) { tap("review-practice", scroll: "review-journey-scroll") }
        let answer = app.descendants(matching: .any)["review-answer"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        answer.tap()
        answer.typeText("interrupted answer")
        tap("review-dismiss-keyboard")
        XCTAssertEqual(answer.value as? String, "interrupted answer")
        XCTAssertFalse(app.staticTexts["review-result-title"].exists)
        tap("review-finish-for-now", scroll: "review-journey-scroll")
        tap("pilot-home-continue", scroll: "pilot-home-scroll")
        tap("pilot-scene-review", scroll: "pilot-scene-scroll")
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        XCTAssertEqual(answer.value as? String, "interrupted answer")
        XCTAssertFalse(app.staticTexts["review-result-title"].exists)
        capture("review-resumed-through-another-chapter")
    }
    func testTimelineThreeRoundsPreserveSelectionAndLockedSlotsAcrossRelaunch() {
        launch(chapters: 6)
        tap("Timeline")
        tap("timeline-start")
        let born = "timeline-card-timeline-born-at-shivneri"
        tap(born)
        app.terminate()
        app.launch()
        tap("Timeline")
        XCTAssertTrue(app.staticTexts["timeline-selected-card"].waitForExistence(timeout: 10))
        tap("timeline-slot-0")
        XCTAssertFalse(app.buttons["timeline-slot-0"].isEnabled)
        capture("timeline-first-slot-restored")
        let sequences = [["timeline-early-forts", "timeline-pratapgad-turning-point"],
            ["timeline-pratapgad-turning-point", "timeline-pressure-at-purandar", "timeline-agra-and-return"],
            ["timeline-agra-and-return", "timeline-comeback-and-rebuilding", "timeline-raigad-coronation"]]
        for (round, sequence) in sequences.enumerated() {
            if round > 0 { tap("timeline-next"); tap("timeline-start") }
            for (index, id) in sequence.enumerated() {
                tap("timeline-card-" + id)
                tap("timeline-slot-\(round == 0 ? index + 1 : index)")
            }
            capture("timeline-round-\(round + 1)-checked")
        }
        XCTAssertTrue(app.staticTexts["timeline-success"].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        tap("Timeline")
        XCTAssertTrue(app.staticTexts["timeline-success"].waitForExistence(timeout: 10))
    }
    func testLargeTextTimelineHelpAndReviewReteachingRemainReachable() {
        launch(chapters: 3, large: true)
        tap("Timeline")
        tap("timeline-start")
        tap("timeline-hint")
        capture("timeline-large-text-help")
        tap("Story")
        tap("home-review-cards", scroll: "home-story-scroll")
        if app.buttons["review-practice"].waitForExistence(timeout: 3) { tap("review-practice", scroll: "review-journey-scroll") }
        tap("review-reveal", scroll: "review-journey-scroll")
        app.terminate()
        app.launch()
        tap("home-review-cards", scroll: "home-story-scroll")
        tap("review-teach-again", scroll: "review-journey-scroll")
        tap("review-continue", scroll: "review-journey-scroll")
        XCTAssertTrue(app.buttons["review-teaching-continue"].waitForExistence(timeout: 10))
        capture("review-large-text-real-teaching")
        tap("review-teaching-continue", scroll: "review-journey-scroll")
        tap("review-finish-for-now", scroll: "review-journey-scroll")
        XCTAssertTrue(app.buttons["home-primary-lesson"].waitForExistence(timeout: 10))
    }
}

private struct EnrichmentScrollFrames {
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

    func dragDistance(to targetFrame: CGRect?) -> CGFloat {
        let visible = viewport
        if let targetFrame {
            let gap = abs(targetFrame.midY - visible.midY)
            if gap > visible.height { return min(gap, visible.height * 0.7) }
        }
        return min(76, visible.height * 0.4)
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
