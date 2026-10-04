import XCTest

/// Shared traversal keeps legacy puzzle/map/album assertions behind the real expanded teaching.
@MainActor
enum TVKnowledgeUITestJourney {
    private static let correctChoices: [String: String] = [
        "scene-1-shivneri-knowledge-question-mother": "scene-1-shivneri-knowledge-question-mother-choice-1",
        "scene-1-shivneri-knowledge-question-junnar": "scene-1-shivneri-knowledge-question-junnar-choice-1",
        "scene-1-shivneri-knowledge-question-gates": "scene-1-shivneri-knowledge-question-gates-choice-2",
        "scene-1-shivneri-knowledge-question-cistern": "scene-1-shivneri-knowledge-question-cistern-choice-1",
        "scene-2-torna-rajgad-knowledge-question-torna-name": "scene-2-torna-rajgad-knowledge-question-torna-name-choice-1",
        "scene-2-torna-rajgad-knowledge-question-machis": "scene-2-torna-rajgad-knowledge-question-machis-choice-2",
        "scene-2-torna-rajgad-knowledge-question-capital": "scene-2-torna-rajgad-knowledge-question-capital-choice-1",
        "scene-2-torna-rajgad-knowledge-question-masons": "scene-2-torna-rajgad-knowledge-question-masons-choice-1",
        "scene-3-pratapgad-turning-point-knowledge-question-year-gap": "scene-3-pratapgad-turning-point-knowledge-question-year-gap-choice-2",
        "scene-3-pratapgad-turning-point-knowledge-question-before": "scene-3-pratapgad-turning-point-knowledge-question-before-choice-1",
        "scene-3-pratapgad-turning-point-knowledge-question-bijapur": "scene-3-pratapgad-turning-point-knowledge-question-bijapur-choice-1",
        "scene-3-pratapgad-turning-point-knowledge-question-terrain": "scene-3-pratapgad-turning-point-knowledge-question-terrain-choice-1",
        "scene-4-purandar-agra-knowledge-question-forts": "scene-4-purandar-agra-knowledge-question-forts-choice-2",
        "scene-4-purandar-agra-knowledge-question-year-gap": "scene-4-purandar-agra-knowledge-question-year-gap-choice-1",
        "scene-4-purandar-agra-knowledge-question-sambhaji": "scene-4-purandar-agra-knowledge-question-sambhaji-choice-1",
        "scene-4-purandar-agra-knowledge-question-river": "scene-4-purandar-agra-knowledge-question-river-choice-1",
        "scene-5-rajgad-recovery-knowledge-question-offices": "scene-5-rajgad-recovery-knowledge-question-offices-choice-2",
        "scene-5-rajgad-recovery-knowledge-question-stores": "scene-5-rajgad-recovery-knowledge-question-stores-choice-1",
        "scene-5-rajgad-recovery-knowledge-question-crop-relief": "scene-5-rajgad-recovery-knowledge-question-crop-relief-choice-1",
        "scene-5-rajgad-recovery-knowledge-question-recovery": "scene-5-rajgad-recovery-knowledge-question-recovery-choice-1",
        "scene-6-raigad-coronation-knowledge-question-ministers": "scene-6-raigad-coronation-knowledge-question-ministers-choice-2",
        "scene-6-raigad-coronation-knowledge-question-shivrai": "scene-6-raigad-coronation-knowledge-question-shivrai-choice-1",
        "scene-6-raigad-coronation-knowledge-question-year": "scene-6-raigad-coronation-knowledge-question-year-choice-3",
        "scene-6-raigad-coronation-knowledge-question-accounts": "scene-6-raigad-coronation-knowledge-question-accounts-choice-1"
    ]
    static func finishStory(app: XCUIApplication, nextID: String = "tv-lesson-story-next", untilTitle: String? = nil,
                            select: (String) -> Void) {
        for _ in 0..<32 {
            if let untilTitle, app.staticTexts[untilTitle].exists { return }
            if app.buttons["tv-discovery-continue"].exists || app.staticTexts["tv-knowledge-family-context"].exists { return }
            let next = app.buttons[nextID]
            XCTAssertTrue(next.waitForExistence(timeout: 10), "Missing real story card: " + nextID)
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next)
            XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 10), .completed, "Story text must be presented before advancing")
            select(nextID)
        }
        XCTFail("Expanded story did not finish within 32 cards.\n" + app.debugDescription)
    }

    static func finishPractice(app: XCUIApplication, select: (String) -> Void) {
        XCTAssertTrue(app.staticTexts["tv-knowledge-family-context"].waitForExistence(timeout: 10))
        for _ in 0..<32 {
            if app.staticTexts["tv-knowledge-practice-complete"].exists {
                select("tv-knowledge-practice-finish")
                let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                       object: app.staticTexts["tv-knowledge-family-context"])
                XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 10), .completed)
                return
            }
            if app.staticTexts["tv-knowledge-practice-needs-teaching"].exists {
                select("tv-knowledge-practice-teach")
                finishStory(app: app, nextID: "tv-knowledge-teaching-next", select: select)
            } else if app.staticTexts["tv-knowledge-practice-result"].exists {
                let next = app.buttons["tv-knowledge-practice-next"]
                let read = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next)
                XCTAssertEqual(XCTWaiter.wait(for: [read], timeout: 10), .completed)
                select("tv-knowledge-practice-next")
            } else {
                let prompt = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tv-knowledge-question-")).firstMatch
                XCTAssertTrue(prompt.waitForExistence(timeout: 10))
                let id = String(prompt.identifier.dropFirst("tv-knowledge-question-".count))
                guard let answer = correctChoices[id] else { XCTFail("Unknown authored question: " + id); return }
                select("tv-knowledge-choice-" + answer)
                XCTAssertFalse(app.staticTexts["tv-knowledge-practice-result"].exists, "Selection alone is not a check")
                select("tv-knowledge-practice-check")
                XCTAssertTrue(app.staticTexts["tv-knowledge-explanation-" + id].waitForExistence(timeout: 10))
                XCTAssertTrue(app.staticTexts["tv-knowledge-practice-result"].label.contains("family choice matched"))
            }
        }
        XCTFail("The family set did not finish within the bounded four questions.\n" + app.debugDescription)
    }
}
