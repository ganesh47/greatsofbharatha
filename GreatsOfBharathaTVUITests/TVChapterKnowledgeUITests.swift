import XCTest

@MainActor
final class TVChapterKnowledgeUITests: XCTestCase {
    private var app: XCUIApplication!
    private let remote = XCUIRemote.shared
    private let chapters: [(id: String, questions: [(id: String, correct: String)])] = [
        ("scene-1-shivneri", [
            ("scene-1-shivneri-knowledge-question-mother", "scene-1-shivneri-knowledge-question-mother-choice-1"),
            ("scene-1-shivneri-knowledge-question-junnar", "scene-1-shivneri-knowledge-question-junnar-choice-1"),
            ("scene-1-shivneri-knowledge-question-gates", "scene-1-shivneri-knowledge-question-gates-choice-2"),
            ("scene-1-shivneri-knowledge-question-cistern", "scene-1-shivneri-knowledge-question-cistern-choice-1")
        ]),
        ("scene-2-torna-rajgad", [
            ("scene-2-torna-rajgad-knowledge-question-torna-name", "scene-2-torna-rajgad-knowledge-question-torna-name-choice-1"),
            ("scene-2-torna-rajgad-knowledge-question-machis", "scene-2-torna-rajgad-knowledge-question-machis-choice-2"),
            ("scene-2-torna-rajgad-knowledge-question-capital", "scene-2-torna-rajgad-knowledge-question-capital-choice-1"),
            ("scene-2-torna-rajgad-knowledge-question-masons", "scene-2-torna-rajgad-knowledge-question-masons-choice-1")
        ]),
        ("scene-3-pratapgad-turning-point", [
            ("scene-3-pratapgad-turning-point-knowledge-question-year-gap", "scene-3-pratapgad-turning-point-knowledge-question-year-gap-choice-2"),
            ("scene-3-pratapgad-turning-point-knowledge-question-before", "scene-3-pratapgad-turning-point-knowledge-question-before-choice-1"),
            ("scene-3-pratapgad-turning-point-knowledge-question-bijapur", "scene-3-pratapgad-turning-point-knowledge-question-bijapur-choice-1"),
            ("scene-3-pratapgad-turning-point-knowledge-question-terrain", "scene-3-pratapgad-turning-point-knowledge-question-terrain-choice-1")
        ]),
        ("scene-4-purandar-agra", [
            ("scene-4-purandar-agra-knowledge-question-forts", "scene-4-purandar-agra-knowledge-question-forts-choice-2"),
            ("scene-4-purandar-agra-knowledge-question-year-gap", "scene-4-purandar-agra-knowledge-question-year-gap-choice-1"),
            ("scene-4-purandar-agra-knowledge-question-sambhaji", "scene-4-purandar-agra-knowledge-question-sambhaji-choice-1"),
            ("scene-4-purandar-agra-knowledge-question-river", "scene-4-purandar-agra-knowledge-question-river-choice-1")
        ]),
        ("scene-5-rajgad-recovery", [
            ("scene-5-rajgad-recovery-knowledge-question-offices", "scene-5-rajgad-recovery-knowledge-question-offices-choice-2"),
            ("scene-5-rajgad-recovery-knowledge-question-stores", "scene-5-rajgad-recovery-knowledge-question-stores-choice-1"),
            ("scene-5-rajgad-recovery-knowledge-question-crop-relief", "scene-5-rajgad-recovery-knowledge-question-crop-relief-choice-1"),
            ("scene-5-rajgad-recovery-knowledge-question-recovery", "scene-5-rajgad-recovery-knowledge-question-recovery-choice-1")
        ]),
        ("scene-6-raigad-coronation", [
            ("scene-6-raigad-coronation-knowledge-question-ministers", "scene-6-raigad-coronation-knowledge-question-ministers-choice-2"),
            ("scene-6-raigad-coronation-knowledge-question-shivrai", "scene-6-raigad-coronation-knowledge-question-shivrai-choice-1"),
            ("scene-6-raigad-coronation-knowledge-question-year", "scene-6-raigad-coronation-knowledge-question-year-choice-3"),
            ("scene-6-raigad-coronation-knowledge-question-accounts", "scene-6-raigad-coronation-knowledge-question-accounts-choice-1")
        ])
    ]

    private func launch(sceneID: String, entry: String) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = [
            "GOB_UI_TEST_SUITE": "gob.tv.ui.knowledge." + UUID().uuidString,
            "GOB_UI_TEST_RESET": "1",
            "GOB_UI_TEST_KNOWLEDGE_SCENE_ID": sceneID,
            "GOB_UI_TEST_KNOWLEDGE_ENTRY": entry,
            "GOB_UI_TEST_KNOWLEDGE_ROUTE": "story"
        ]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func launchCompatibility(_ mode: String, opaque: String = "future") {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment = [
            "GOB_UI_TEST_SUITE": "gob.tv.ui.knowledge." + UUID().uuidString,
            "GOB_UI_TEST_RESET": "1",
            "GOB_UI_TEST_KNOWLEDGE_COMPATIBILITY": mode,
            "GOB_UI_TEST_KNOWLEDGE_OPAQUE": opaque
        ]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    func testOpaqueKnowledgePreservesNativeStoryAndCompletedRecallContinuation() {
        for opaque in ["future", "corrupt"] {
            launchCompatibility("story", opaque: opaque)
            XCTAssertTrue(app.buttons["tv-lesson-story-next"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.staticTexts["tv-knowledge-teaching-progress"].exists)
            for _ in 0..<3 { select("tv-lesson-story-next") }
            XCTAssertTrue(app.staticTexts["Chapter 1 · Discover"].waitForExistence(timeout: 10))
            app.terminate()
            app.launch()
            XCTAssertTrue(app.staticTexts["Chapter 1 · Discover"].waitForExistence(timeout: 10))
            capture("tv-knowledge-" + opaque + "-legacy-story-continuation")

            launchCompatibility("recall", opaque: opaque)
            let continuation = app.buttons["tv-recall-continue"]
            XCTAssertTrue(continuation.waitForExistence(timeout: 10))
            XCTAssertEqual(continuation.label, "Continue to the little puzzle")
            select("tv-recall-continue")
            XCTAssertTrue(app.staticTexts["Chapter 1 · Little puzzle"].waitForExistence(timeout: 10))
            app.terminate()
            app.launch()
            XCTAssertTrue(app.staticTexts["Chapter 1 · Little puzzle"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.staticTexts["tv-knowledge-family-context"].exists)
            capture("tv-knowledge-" + opaque + "-legacy-recall-continuation")
        }
    }

    func testExplicitExploreAgainStartsAtOpeningKnowledgeBeat() {
        launchCompatibility("replay")
        select("tv-explore-again")
        XCTAssertTrue(app.staticTexts["tv-knowledge-beat-scene-1-shivneri-story"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["tv-knowledge-teaching-progress"].label, "Part 1 of 3 · Card 1 of 3")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-knowledge-beat-scene-1-shivneri-story"].waitForExistence(timeout: 10))
        capture("tv-knowledge-explicit-replay-opening")
    }

    private func capture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    /// Exercise the actual directional focus engine. No element.tap(), pointer, or debug route bypasses navigation.
    private func focus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = app.buttons[identifier].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 10), "Missing \(identifier)", file: file, line: line)
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

    private func finishTeaching() {
        for _ in 0..<32 {
            if app.staticTexts["tv-knowledge-family-context"].exists { return }
            let next = app.buttons["tv-knowledge-teaching-next"]
            XCTAssertTrue(next.waitForExistence(timeout: 10))
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next)
            guard XCTWaiter.wait(for: [ready], timeout: 10) == .completed else {
                let hierarchy = XCTAttachment(string: app.debugDescription)
                hierarchy.name = "tv-knowledge-live-AX-caption-failure"
                hierarchy.lifetime = .keepAlways
                add(hierarchy)
                capture("tv-knowledge-caption-failure")
                XCTFail("The full caption must be visible before Next: " + String(describing: next.value))
                return
            }
            select("tv-knowledge-teaching-next")
        }
        XCTFail("Teaching did not reach practice within the bounded caption pages.\n" + app.debugDescription)
    }

    func testAllSixUnseededChaptersTeachBeforeAllFourFamilyQuestions() {
        for (index, chapter) in chapters.enumerated() {
            launch(sceneID: chapter.id, entry: "teaching")
            finishTeaching()
            for (questionIndex, question) in chapter.questions.enumerated() {
                XCTAssertTrue(app.staticTexts["tv-knowledge-question-" + question.id].waitForExistence(timeout: 10))
                XCTAssertEqual(app.staticTexts["tv-knowledge-practice-progress"].label, "Question \(questionIndex + 1) of 4")
                XCTAssertFalse(app.buttons["tv-knowledge-practice-check"].isEnabled)
                select("tv-knowledge-choice-" + question.correct)
                XCTAssertFalse(app.staticTexts["tv-knowledge-practice-result"].exists)
                XCTAssertEqual(app.buttons["tv-knowledge-choice-" + question.correct].value as? String, "Selected")
                select("tv-knowledge-practice-check")
                XCTAssertTrue(app.staticTexts["tv-knowledge-explanation-" + question.id].waitForExistence(timeout: 10))
                XCTAssertEqual(app.staticTexts["tv-knowledge-practice-result"].label, "Our family choice matched")
                if questionIndex == 3 { capture("tv-knowledge-chapter-\(index + 1)-fourth-explanation") }
                select("tv-knowledge-practice-next")
            }
            XCTAssertTrue(app.staticTexts["tv-knowledge-practice-complete"].waitForExistence(timeout: 10))
            capture("tv-knowledge-chapter-\(index + 1)-complete")
        }
    }

    func testUntaughtPracticeRequiresTeachingAndSelectionRelaunchBackIsSeparateFromCheck() {
        let chapter = chapters[0]
        let question = chapter.questions[0]
        launch(sceneID: chapter.id, entry: "practice")
        XCTAssertTrue(app.staticTexts["tv-knowledge-practice-needs-teaching"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tv-knowledge-practice-check"].exists)
        select("tv-knowledge-practice-teach")
        finishTeaching()
        select("tv-knowledge-choice-" + question.correct)
        app.terminate()
        app.launch()
        let selected = app.buttons["tv-knowledge-choice-" + question.correct]
        XCTAssertTrue(selected.waitForExistence(timeout: 10))
        XCTAssertEqual(selected.value as? String, "Selected")
        XCTAssertFalse(app.staticTexts["tv-knowledge-practice-result"].exists)
        remote.press(.menu)
        let cleared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Available"), object: selected)
        XCTAssertEqual(XCTWaiter.wait(for: [cleared], timeout: 5), .completed)
        XCTAssertFalse(app.buttons["tv-knowledge-practice-check"].isEnabled)
        app.terminate()
        app.launch()
        XCTAssertTrue(selected.waitForExistence(timeout: 10))
        XCTAssertEqual(selected.value as? String, "Available")
        XCTAssertEqual(app.staticTexts["tv-knowledge-practice-progress"].label, "Question 1 of 4")
        capture("tv-knowledge-back-clears-without-check")
    }

    func testFamilyClueWrongAnswerAndCheckedResultRemainSupportedAfterRelaunch() {
        let chapter = chapters[0]
        let question = chapter.questions[0]
        launch(sceneID: chapter.id, entry: "teaching")
        finishTeaching()
        select("tv-knowledge-practice-help")
        select("tv-knowledge-choice-" + question.id + "-choice-2")
        app.launchEnvironment["GOB_UI_TEST_KNOWLEDGE_ENTRY"] = "practice"
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-knowledge-practice-hint"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["tv-knowledge-choice-" + question.id + "-choice-2"].value as? String, "Selected")
        select("tv-knowledge-practice-check")
        XCTAssertEqual(app.staticTexts["tv-knowledge-practice-result"].label, "Let’s look together")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["tv-knowledge-explanation-" + question.id].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tv-knowledge-practice-check"].exists)
        select("tv-knowledge-practice-try-again")
        XCTAssertTrue(app.staticTexts["tv-knowledge-practice-seen-answer"].exists)
        XCTAssertTrue(app.staticTexts["tv-knowledge-practice-hint"].exists)
        select("tv-knowledge-choice-" + question.correct)
        select("tv-knowledge-practice-check")
        XCTAssertEqual(app.staticTexts["tv-knowledge-practice-result"].label, "Our family choice matched after seeing the answer")
        capture("tv-knowledge-supported-family-check")
    }
}
