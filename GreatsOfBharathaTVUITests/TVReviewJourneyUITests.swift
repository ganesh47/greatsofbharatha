import XCTest

@MainActor
final class TVReviewJourneyUITests: XCTestCase {
    private var app: XCUIApplication!
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.tv.ui.review." + UUID().uuidString
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launchEnvironment["GOB_UI_TEST_SEED_THROUGH_CHAPTER"] = "3"
    }

    private func launch() {
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
        XCTAssertTrue(app.buttons["tv-home-review"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tv-home-review"].isEnabled)
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

    private func openReview() {
        select("tv-home-review")
        XCTAssertTrue(app.buttons["tv-review-finish"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Shared family review · choosing from answers"].exists)
        // The chapter seed may have future due dates. Optional practice is an explicit remote action.
        if app.buttons["tv-review-practice"].exists { select("tv-review-practice") }
        XCTAssertTrue(app.staticTexts["tv-review-prompt"].waitForExistence(timeout: 10))
    }

    private func reopenReview() {
        launch()
        select("tv-home-review")
        XCTAssertTrue(app.buttons["tv-review-finish"].waitForExistence(timeout: 10))
    }

    private func reachCheckedCard() {
        openReview()
        // Cards without authored choices stay honest memory reports. Do not invent a check fixture.
        for _ in 0..<32 {
            if app.buttons["tv-review-check"].exists { return }
            select("tv-review-reveal")
            select("tv-review-report-clue")
            select("tv-review-continue")
        }
        XCTFail("No authored choice card was reachable in the bounded learned-card queue")
    }

    private func correctChoiceID() throws -> String {
        // These are the existing authored correct choice IDs in the three seeded chapters.
        let identifiers = ["tv-review-choice-scene-1-shivneri-shivneri",
                           "tv-review-choice-scene-2-torna-rajgad-rajgad",
                           "tv-review-choice-scene-3-pratapgad-turning-point-pratapgad"]
        return try XCTUnwrap(identifiers.first { app.buttons[$0].exists }, "Missing a canonical authored choice")
    }

    private var progress: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Card ' AND label CONTAINS ' of '")).firstMatch
    }

    private func queuePosition() throws -> (cursor: Int, count: Int) {
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        let parts = progress.label.components(separatedBy: " ")
        XCTAssertGreaterThan(parts.count, 3)
        let cursor = try XCTUnwrap(parts.indices.contains(1) ? Int(parts[1]) : nil)
        let count = try XCTUnwrap(parts.indices.contains(3) ? Int(parts[3]) : nil)
        return (cursor, count)
    }

    private func waitForFocus(_ identifier: String) {
        let button = app.buttons[identifier]
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: button)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: 5), .completed)
    }

    private func assertUnchecked(_ choiceID: String, selected: Bool, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(app.buttons[choiceID].value as? String, selected ? "Selected" : "Available", file: file, line: line)
        XCTAssertEqual(app.buttons["tv-review-check"].isEnabled, selected, file: file, line: line)
        XCTAssertFalse(app.staticTexts["tv-review-result"].exists, file: file, line: line)
        XCTAssertFalse(app.buttons["tv-review-continue"].exists, file: file, line: line)
    }

    func testRemoteFocusAndSelectionRequireSeparateCheck() throws {
        launch()
        focus("tv-home-review")
        XCTAssertTrue(app.buttons["tv-home-continue"].exists, "Focus alone must not open review")
        XCTAssertFalse(app.buttons["tv-review-finish"].exists)
        reachCheckedCard()
        let choiceID = try correctChoiceID()
        let prompt = app.staticTexts["tv-review-prompt"].label
        let cardProgress = progress.label
        focus(choiceID)
        assertUnchecked(choiceID, selected: false)
        remote.press(.select)
        waitForFocus("tv-review-check")
        assertUnchecked(choiceID, selected: true)
        XCTAssertEqual(app.staticTexts["tv-review-prompt"].label, prompt)
        XCTAssertEqual(progress.label, cardProgress, "Selection must not advance the queue")
        capture("review-selected-before-check")
        remote.press(.select)
        let result = app.staticTexts["tv-review-result"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertEqual(result.label, "Family choice checked")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'without opening a clue'")).firstMatch.exists)
        capture("review-family-choice-checked")
        select("tv-review-finish")
        XCTAssertTrue(app.buttons["tv-home-review"].waitForExistence(timeout: 10))
    }

    func testRelaunchKeepsSelectionAndBackClearsWithoutCheckOrAdvancement() throws {
        launch()
        let chapterContinuation = app.buttons["tv-home-continue"].label
        reachCheckedCard()
        let choiceID = try correctChoiceID()
        let prompt = app.staticTexts["tv-review-prompt"].label
        let cardProgress = progress.label
        select(choiceID)
        assertUnchecked(choiceID, selected: true)
        app.terminate()
        reopenReview()
        XCTAssertTrue(app.buttons[choiceID].waitForExistence(timeout: 10))
        assertUnchecked(choiceID, selected: true)
        waitForFocus("tv-review-check")
        XCTAssertEqual(app.staticTexts["tv-review-prompt"].label, prompt)
        XCTAssertEqual(progress.label, cardProgress)
        capture("review-selection-restored-before-back")
        remote.press(.menu)
        XCTAssertTrue(app.buttons["tv-review-finish"].exists, "First Back clears the selection and stays in review")
        assertUnchecked(choiceID, selected: false)
        XCTAssertEqual(progress.label, cardProgress, "Back must not check, teach, or advance a card")
        app.terminate()
        reopenReview()
        XCTAssertTrue(app.buttons[choiceID].waitForExistence(timeout: 10))
        assertUnchecked(choiceID, selected: false)
        XCTAssertEqual(progress.label, cardProgress, "Cleared selection must persist after relaunch")
        capture("review-cleared-selection-restored")
        remote.press(.menu)
        XCTAssertTrue(app.buttons["tv-home-review"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["tv-home-continue"].label, chapterContinuation,
                       "Review selection/Back must preserve the original chapter continuation")
    }

    func testClueCaptionsAndHelpSurviveRelaunchBeforeFamilyCheck() throws {
        launch()
        reachCheckedCard()
        let choiceID = try correctChoiceID()
        select("tv-review-help")
        let clueCaption = "A clue is open. This choice will be saved with help."
        XCTAssertTrue(app.staticTexts[clueCaption].waitForExistence(timeout: 10))
        let clueReadAloud = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tv-listen-' AND identifier ENDSWITH '-review-clue'")).firstMatch
        XCTAssertTrue(clueReadAloud.exists, "The clue must have captions and optional read-aloud")
        assertUnchecked(choiceID, selected: false)
        capture("review-clue-caption")
        app.terminate()
        reopenReview()
        XCTAssertTrue(app.staticTexts[clueCaption].waitForExistence(timeout: 10))
        select(choiceID)
        select("tv-review-check")
        let result = app.staticTexts["tv-review-result"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertEqual(result.label, "Family choice checked with help")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'with a clue or after teaching'")).firstMatch.exists)
        capture("review-helped-family-choice")
        select("tv-review-finish")
        XCTAssertTrue(app.buttons["tv-home-review"].waitForExistence(timeout: 10))
    }

    func testTeachingAddsOneTailRevisitAndRepeatTeachingCanFinish() throws {
        launch()
        let chapterContinuation = app.buttons["tv-home-continue"].label
        reachCheckedCard()
        let original = try queuePosition()
        select("tv-review-reveal")
        XCTAssertTrue(app.staticTexts["This is your family’s own memory report. It is separate from a checked choice."].exists)
        select("tv-review-report-teach")
        XCTAssertTrue(app.staticTexts["tv-review-result"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["tv-review-result"].label, "Family memory report saved")
        select("tv-review-continue")
        XCTAssertTrue(app.buttons["tv-review-teaching-continue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["We’ll offer this card once more after the other cards."].exists)
        let teachingReadAloud = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tv-listen-' AND identifier ENDSWITH '-review-teaching'")).firstMatch
        XCTAssertTrue(teachingReadAloud.exists, "Actual teaching captions must support read-aloud")
        let storyCaptions = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Shivaji'")).allElementsBoundByIndex.map(\.label)
        XCTAssertGreaterThan(storyCaptions.map(\.count).max() ?? 0, 200, "The authored story beats must appear as teaching captions")
        capture("review-authored-teaching")
        select("tv-review-teaching-continue")
        let afterTeaching = try queuePosition()
        XCTAssertEqual(afterTeaching.count, original.count + 1)
        XCTAssertEqual(afterTeaching.cursor, original.cursor + 1)
        try finishOtherCardsBeforeTailRevisit(expectedCount: original.count + 1)
        XCTAssertTrue(app.staticTexts["A small practice after teaching. This revisit stays helped family practice."].exists)
        capture("review-rescued-tail-revisit")
        select("tv-review-reveal")
        select("tv-review-report-teach")
        select("tv-review-continue")
        XCTAssertTrue(app.staticTexts["You’ve practised this once already. You can finish and return another time."].waitForExistence(timeout: 10))
        XCTAssertEqual(try queuePosition().count, original.count + 1, "Repeat teaching must not append another turn")
        select("tv-review-teaching-continue")
        XCTAssertTrue(app.staticTexts["tv-review-complete"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tv-review-chapter"].exists)
        XCTAssertTrue(app.buttons["tv-review-done"].exists)
        focus("tv-review-chapter")
        focus("tv-review-done")
        capture("review-bounded-completion")
        select("tv-review-finish")
        XCTAssertTrue(app.buttons["tv-home-review"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["tv-home-continue"].label, chapterContinuation)
    }

    private func finishOtherCardsBeforeTailRevisit(expectedCount: Int) throws {
        for _ in 0..<32 {
            let position = try queuePosition()
            XCTAssertEqual(position.count, expectedCount)
            if position.cursor == position.count { return }
            select("tv-review-reveal")
            select("tv-review-report-clue")
            select("tv-review-continue")
        }
        XCTFail("The bounded review queue never reached its single taught tail turn")
    }
}
