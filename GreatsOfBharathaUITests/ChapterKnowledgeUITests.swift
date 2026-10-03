import XCTest

/// These tests require the coordinator's DEBUG-only, navigation-only entry adapter.
/// No knowledge archive, exposure, answer, unlock, or learning award is seeded here.
@MainActor
final class ChapterKnowledgeUITests: XCTestCase {
    private var app: XCUIApplication!
    private let chapters: [(id: String, questions: [(suffix: String, choice: Int)])] = [
        ("scene-1-shivneri", [("mother", 1), ("junnar", 1), ("gates", 2), ("cistern", 1)]),
        ("scene-2-torna-rajgad", [("torna-name", 1), ("machis", 2), ("capital", 1), ("masons", 1)]),
        ("scene-3-pratapgad-turning-point", [("year-gap", 2), ("before", 1), ("bijapur", 1), ("terrain", 1)]),
        ("scene-4-purandar-agra", [("forts", 2), ("year-gap", 1), ("sambhaji", 1), ("river", 1)]),
        ("scene-5-rajgad-recovery", [("offices", 2), ("stores", 1), ("crop-relief", 1), ("recovery", 1)]),
        ("scene-6-raigad-coronation", [("ministers", 2), ("shivrai", 1), ("year", 3), ("accounts", 1)])
    ]

    private func launch(sceneID: String, entry: String, route: String = "story", largeText: Bool = false) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchEnvironment = [
            "GOB_UI_TEST_SUITE": "gob.ui.knowledge." + UUID().uuidString,
            "GOB_UI_TEST_RESET": "1",
            "GOB_UI_TEST_KNOWLEDGE_SCENE_ID": sceneID,
            "GOB_UI_TEST_KNOWLEDGE_ENTRY": entry,
            "GOB_UI_TEST_KNOWLEDGE_ROUTE": route
        ]
        app.launchArguments = ["-UIPreferredContentSizeCategoryName",
            largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    func testAllSixStoryChaptersPresentFourQuestionsAfterActualTeaching() {
        allChapters(route: "story")
    }

    func testAllSixPilotChaptersUseTheSameQuestionBankAfterActualTeaching() {
        allChapters(route: "pilot")
    }

    private func allChapters(route: String) {
        for (index, chapter) in chapters.enumerated() {
            launch(sceneID: chapter.id, entry: "teaching", route: route)
            finishTeaching()
            for (questionIndex, descriptor) in chapter.questions.enumerated() {
                let id = chapter.id + "-knowledge-question-" + descriptor.suffix
                let prompt = app.staticTexts["knowledge-question-" + id]
                XCTAssertTrue(prompt.waitForExistence(timeout: 10), "Question is unreachable: " + id)
                XCTAssertEqual(app.staticTexts["knowledge-practice-progress"].label, "Question \(questionIndex + 1) of 4")
                XCTAssertFalse(app.buttons["knowledge-practice-check"].isEnabled)
                tap("knowledge-choice-" + id + "-" + id + "-choice-\(descriptor.choice)", scrollID: "knowledge-practice-scroll")
                XCTAssertFalse(app.staticTexts["knowledge-practice-result-title"].exists, "Selecting must not check the answer")
                XCTAssertEqual(app.buttons["knowledge-choice-" + id + "-" + id + "-choice-\(descriptor.choice)"].value as? String, "Selected")
                tap("knowledge-practice-check", scrollID: "knowledge-practice-scroll")
                let explanation = app.staticTexts["knowledge-explanation-" + id]
                XCTAssertTrue(explanation.waitForExistence(timeout: 10))
                traverseText(explanation, scrollID: "knowledge-practice-scroll")
                XCTAssertTrue(app.descendants(matching: .any)["knowledge-save-confirmed"].exists)
                if questionIndex == 3 { capture("knowledge-\(route)-chapter-\(index + 1)-fourth-explanation") }
                tap("knowledge-practice-next", scrollID: "knowledge-practice-scroll")
            }
            XCTAssertTrue(app.staticTexts["knowledge-practice-complete"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.keyboards.count, 0)
            capture("knowledge-\(route)-chapter-\(index + 1)-complete")
        }
    }

    func testDirectQuizTeachesMissingFactsAndInterruptedChoiceHintAndResultSurviveRelaunch() {
        let chapter = chapters[0]
        let questionID = chapter.id + "-knowledge-question-mother"
        launch(sceneID: chapter.id, entry: "practice")
        XCTAssertTrue(app.descendants(matching: .any)["knowledge-practice-needs-teaching"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["knowledge-practice-check"].exists)
        tap("knowledge-practice-teach", scrollID: "knowledge-practice-scroll")
        finishTeaching()
        tap("knowledge-practice-help", scrollID: "knowledge-practice-scroll")
        let wrongID = "knowledge-choice-" + questionID + "-" + questionID + "-choice-2"
        tap(wrongID, scrollID: "knowledge-practice-scroll")
        XCTAssertFalse(app.staticTexts["knowledge-practice-result-title"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons[wrongID].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons[wrongID].value as? String, "Selected")
        XCTAssertTrue(app.staticTexts["knowledge-practice-hint"].exists)
        tap("knowledge-practice-check", scrollID: "knowledge-practice-scroll")
        XCTAssertEqual(app.staticTexts["knowledge-practice-result-title"].label, "Let’s look together")
        app.terminate()
        app.launch()
        let explanation = app.staticTexts["knowledge-explanation-" + questionID]
        XCTAssertTrue(explanation.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["knowledge-practice-check"].exists)
        traverseText(explanation, scrollID: "knowledge-practice-scroll")
        capture("knowledge-wrong-checked-result-relaunch")
        tap("knowledge-practice-try-again", scrollID: "knowledge-practice-scroll")
        XCTAssertTrue(app.staticTexts["knowledge-practice-hint"].exists, "Help remains sticky after retry")
        XCTAssertTrue(app.staticTexts["knowledge-practice-seen-answer"].exists)
        tap("knowledge-choice-" + questionID + "-" + questionID + "-choice-1", scrollID: "knowledge-practice-scroll")
        tap("knowledge-practice-check", scrollID: "knowledge-practice-scroll")
        XCTAssertEqual(app.staticTexts["knowledge-practice-result-title"].label, "Your choice matched after seeing the answer")
        capture("knowledge-seen-answer-remains-supported")
    }

    func testLargeTextLandscapeTeachingSourcesAndPracticeActionsStayReachable() {
        launch(sceneID: chapters[0].id, entry: "teaching", largeText: true)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.windows.firstMatch.frame.width > self.app.windows.firstMatch.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
        finishTeaching(inspectSources: true)
        XCTAssertEqual(app.keyboards.count, 0)
        let id = chapters[0].id + "-knowledge-question-mother"
        tap("knowledge-choice-" + id + "-" + id + "-choice-1", scrollID: "knowledge-practice-scroll")
        tap("knowledge-practice-help", scrollID: "knowledge-practice-scroll")
        tap("knowledge-practice-check", scrollID: "knowledge-practice-scroll")
        let explanation = app.staticTexts["knowledge-explanation-" + id]
        XCTAssertTrue(explanation.waitForExistence(timeout: 10))
        traverseText(explanation, scrollID: "knowledge-practice-scroll")
        tap("knowledge-practice-next", scrollID: "knowledge-practice-scroll")
        XCTAssertTrue(app.staticTexts["knowledge-practice-progress"].label.hasPrefix("Question 2"))
        capture("knowledge-accessibility-text-landscape-next-question")
    }

    func testThreeWrongChecksOfferTeachingAndMovingOnWithoutSuccess() {
        launch(sceneID: chapters[0].id, entry: "teaching")
        finishTeaching()
        let id = chapters[0].id + "-knowledge-question-mother"
        for attempt in 0..<3 {
            tap("knowledge-choice-" + id + "-" + id + "-choice-2", scrollID: "knowledge-practice-scroll")
            tap("knowledge-practice-check", scrollID: "knowledge-practice-scroll")
            XCTAssertEqual(app.staticTexts["knowledge-practice-result-title"].label, "Let’s look together")
            traverseText(app.staticTexts["knowledge-explanation-" + id], scrollID: "knowledge-practice-scroll")
            if attempt < 2 { tap("knowledge-practice-try-again", scrollID: "knowledge-practice-scroll") }
        }
        XCTAssertFalse(app.buttons["knowledge-practice-try-again"].exists)
        reveal(app.buttons["knowledge-practice-reteach"], scrollID: "knowledge-practice-scroll")
        XCTAssertTrue(app.buttons["knowledge-practice-reteach"].isEnabled)
        capture("knowledge-three-wrong-checks-support-and-next")
        tap("knowledge-practice-next", scrollID: "knowledge-practice-scroll")
        XCTAssertEqual(app.staticTexts["knowledge-practice-progress"].label, "Question 2 of 4")
    }

    func testTeachingStableBeatAndSavedSelectionSurviveBackAndRelaunch() {
        launch(sceneID: chapters[0].id, entry: "teaching")
        for _ in 0..<3 { readTeachingCardAndContinue() }
        let beat = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "knowledge-beat-scene-")).firstMatch
        XCTAssertTrue(beat.exists)
        let stableID = beat.identifier
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts[stableID].waitForExistence(timeout: 10))
        capture("knowledge-stable-beat-relaunch")
        finishTeaching()
        let id = chapters[0].id + "-knowledge-question-mother"
        let choiceID = "knowledge-choice-" + id + "-" + id + "-choice-1"
        tap(choiceID, scrollID: "knowledge-practice-scroll")
        tap("knowledge-practice-pause", scrollID: "knowledge-practice-scroll")
        app.launchEnvironment["GOB_UI_TEST_KNOWLEDGE_ENTRY"] = "practice"
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons[choiceID].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons[choiceID].value as? String, "Selected")
        XCTAssertFalse(app.staticTexts["knowledge-practice-result-title"].exists)
        capture("knowledge-paused-selection-relaunch")
    }

    private func finishTeaching(inspectSources: Bool = false) {
        for _ in 0..<64 {
            if app.scrollViews["knowledge-practice-scroll"].exists { return }
            guard app.scrollViews["knowledge-teaching-scroll"].waitForExistence(timeout: 10) else {
                failWithEvidence("The integrated teaching route is missing")
                return
            }
            readTeachingCardAndContinue(inspectSources: inspectSources)
        }
        failWithEvidence("Teaching did not reach practice within the bounded chapter cards")
    }

    private func readTeachingCardAndContinue(inspectSources: Bool = false) {
        let text = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@ OR identifier BEGINSWITH %@",
            "knowledge-beat-text-", "knowledge-fact-")).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 10), "Authored teaching copy is unavailable or not approved")
        traverseText(text, scrollID: "knowledge-teaching-scroll")
        if inspectSources, text.identifier.hasPrefix("knowledge-fact-") {
            let claimID = String(text.identifier.dropFirst("knowledge-fact-".count))
            let source = app.descendants(matching: .any)["knowledge-sources-" + claimID].firstMatch
            reveal(source, scrollID: "knowledge-teaching-scroll")
            source.tap()
            XCTAssertTrue(app.descendants(matching: .any)["knowledge-citation-" + claimID].exists)
            capture("knowledge-large-text-source-" + claimID)
        }
        tap("knowledge-teaching-next", scrollID: "knowledge-teaching-scroll")
    }

    private func traverseText(_ text: XCUIElement, scrollID: String) {
        let scroll = app.scrollViews[scrollID].firstMatch
        var sawTop = false
        for _ in 0..<80 {
            let viewport = usableViewport(scroll)
            let frame = text.frame
            if frame.minY >= viewport.minY && frame.minY < viewport.maxY { sawTop = true }
            if sawTop && frame.maxY <= viewport.maxY && frame.maxY > viewport.minY { return }
            drag(scroll, upward: sawTop || frame.minY >= viewport.maxY, distance: viewport.height * 0.35)
        }
        failWithEvidence("Could not traverse the full authored text: " + text.identifier)
    }

    private func tap(_ id: String, scrollID: String) {
        let button = app.buttons[id].firstMatch
        guard button.waitForExistence(timeout: 10) else {
            failWithEvidence("Missing " + id)
            return
        }
        reveal(button, scrollID: scrollID)
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: button)
        guard XCTWaiter.wait(for: [enabled], timeout: 5) == .completed else {
            failWithEvidence("Disabled " + id + ": " + String(describing: button.value))
            return
        }
        button.tap()
    }

    private func reveal(_ element: XCUIElement, scrollID: String) {
        let scroll = app.scrollViews[scrollID].firstMatch
        for _ in 0..<80 {
            let viewport = usableViewport(scroll)
            let frame = element.frame
            if element.exists && element.isHittable && frame.minY >= viewport.minY && frame.maxY <= viewport.maxY { return }
            drag(scroll, upward: !element.exists || frame.midY > viewport.midY, distance: viewport.height * 0.35)
        }
        failWithEvidence("Unreachable control: " + element.identifier)
    }

    private func usableViewport(_ scroll: XCUIElement) -> CGRect {
        var frame = app.windows.firstMatch.frame.intersection(scroll.frame)
        if app.navigationBars.firstMatch.exists {
            let bar = app.navigationBars.firstMatch.frame
            if bar.intersects(frame) {
                frame = CGRect(x: frame.minX, y: max(frame.minY, bar.maxY), width: frame.width,
                    height: max(0, frame.maxY - max(frame.minY, bar.maxY)))
            }
        }
        if app.tabBars.firstMatch.exists {
            let tab = app.tabBars.firstMatch.frame
            if tab.intersects(frame) { frame.size.height = max(0, tab.minY - frame.minY) }
        }
        return frame.insetBy(dx: 8, dy: 8)
    }

    private func drag(_ scroll: XCUIElement, upward: Bool, distance: CGFloat) {
        let viewport = usableViewport(scroll)
        guard !viewport.isNull, viewport.width > 16, viewport.height > 16 else {
            failWithEvidence("No usable scroll viewport")
            return
        }
        let signed = upward ? distance : -distance
        let start = scroll.coordinate(withNormalizedOffset: CGVector(
            dx: (viewport.midX - scroll.frame.minX) / scroll.frame.width,
            dy: (viewport.midY + signed / 2 - scroll.frame.minY) / scroll.frame.height))
        let end = scroll.coordinate(withNormalizedOffset: CGVector(
            dx: (viewport.midX - scroll.frame.minX) / scroll.frame.width,
            dy: (viewport.midY - signed / 2 - scroll.frame.minY) / scroll.frame.height))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    private func capture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func failWithEvidence(_ message: String) {
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "knowledge-live-AX-failure"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        capture("knowledge-interaction-failure")
        XCTFail(message)
    }
}
