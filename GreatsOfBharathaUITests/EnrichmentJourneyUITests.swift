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
    private func tap(_ id: String, scroll: String = "") {
        let button = app.buttons[id].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing " + id)
        for _ in 0..<16 {
            if button.exists && button.isHittable { break }
            if scroll.isEmpty { app.swipeUp() } else { app.scrollViews[scroll].firstMatch.swipeUp() }
        }
        for _ in 0..<16 {
            if button.exists && button.isHittable { break }
            if scroll.isEmpty { app.swipeDown() } else { app.scrollViews[scroll].firstMatch.swipeDown() }
        }
        if !button.isHittable {
            capture("unreachable-" + id)
            let detail = XCTAttachment(string: "Window: \(app.windows.firstMatch.frame)\nTarget: \(button.frame)\n" + app.debugDescription)
            detail.name = "unreachable-" + id + "-hierarchy"
            detail.lifetime = .keepAlways
            add(detail)
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
