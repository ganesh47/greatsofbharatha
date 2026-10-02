import XCTest

@MainActor
final class ChapterDiscoveryUITests: XCTestCase {
    private var app: XCUIApplication!
    private let chapterIDs = [
        "scene-1-shivneri", "scene-2-torna-rajgad", "scene-3-pratapgad-turning-point",
        "scene-4-purandar-agra", "scene-5-rajgad-recovery", "scene-6-raigad-coronation"
    ]

    private func launch(largeText: Bool = false) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.ui.discovery." + UUID().uuidString
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
        app.launchEnvironment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] = "0"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName",
            largeText ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
    }

    private func reveal(_ element: XCUIElement, in scroll: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<20 {
            if element.exists && element.isHittable { return }
            scroll.swipeUp()
        }
        for _ in 0..<20 {
            if element.exists && element.isHittable { return }
            scroll.swipeDown()
        }
        XCTAssertTrue(element.isHittable, "Could not reach \(element.identifier)", file: file, line: line)
    }

    private func tap(_ identifier: String, scrollID: String = "scene-lesson-scroll", file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier].firstMatch
        reveal(button, in: app.scrollViews[scrollID].firstMatch, file: file, line: line)
        XCTAssertTrue(button.isEnabled, file: file, line: line)
        button.tap()
    }

    private func discoveryButtonID(chapterIndex: Int, detailNumber: Int) -> String {
        if chapterIndex == 0 { return ["story-discovery-hill", "story-discovery-book", "story-discovery-gate"][detailNumber - 1] }
        return "story-discovery-" + chapterIDs[chapterIndex] + "-discovery-\(detailNumber)"
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func setParentPreferences(narrationEnabled: Bool, calmEnabled: Bool) {
        app.buttons["Album"].firstMatch.tap()
        app.buttons["Parent settings"].tap()
        let question = app.staticTexts["parent-gate-question"]
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        let numbers = question.label.split { !$0.isNumber }.compactMap { Int($0) }
        XCTAssertEqual(numbers.count, 2)
        guard numbers.count == 2 else { return }
        let answer = app.textFields["parent-gate-answer"]
        answer.tap()
        answer.typeText(String(numbers.reduce(0, +)) + "\n")
        app.buttons["parent-gate-confirm"].tap()
        for (identifier, enabled) in [("parent-narration-toggle", narrationEnabled), ("parent-calm-toggle", calmEnabled)] {
            let toggle = app.switches[identifier]
            XCTAssertTrue(toggle.waitForExistence(timeout: 10))
            for _ in 0..<20 {
                if toggle.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(toggle.isHittable)
            if (toggle.value as? String == "1") != enabled { toggle.tap() }
            XCTAssertEqual(toggle.value as? String, enabled ? "1" : "0")
        }
        app.buttons["Done"].tap()
        app.buttons["Story"].firstMatch.tap()
    }

    func testAllSixStoryChaptersTeachDiscoverAndTransferBeforeRecall() {
        launch()
        setParentPreferences(narrationEnabled: true, calmEnabled: false)
        tap("home-primary-lesson", scrollID: "home-story-scroll")
        let placeIDs = [["place-shivneri"], ["place-torna", "place-rajgad"], ["place-pratapgad"],
                        ["place-purandar", "place-agra"], ["place-rajgad"], ["place-raigad"]]
        let answers = ["shivneri", "rajgad", "pratapgad", "purandar", "rebuilt", "raigad"]
        for (index, chapterID) in chapterIDs.enumerated() {
            reveal(app.staticTexts["chapter-teaching-" + chapterID], in: app.scrollViews["scene-lesson-scroll"].firstMatch)
            XCTAssertFalse(app.buttons["recall-check-button"].exists)
            for number in 1...3 {
                tap(discoveryButtonID(chapterIndex: index, detailNumber: number))
                XCTAssertTrue(app.staticTexts["chapter-discovery-text-" + chapterID + "-discovery-\(number)"].exists)
            }
            tap("chapter-family-reflection-" + chapterID)
            XCTAssertTrue(app.staticTexts["chapter-family-prompt-" + chapterID].exists)
            capture("discovery-chapter-\(index + 1)-family-transfer")
            if index == 1 {
                app.terminate()
                app.launch()
                tap("home-primary-lesson", scrollID: "home-story-scroll")
                reveal(app.staticTexts["chapter-discovery-text-" + chapterID + "-discovery-3"], in: app.scrollViews["scene-lesson-scroll"].firstMatch)
                XCTAssertFalse(app.buttons["recall-reward-button"].exists)
                capture("discovery-chapter-2-selected-detail-relaunch")
            }
            tap("story-move-to-place-clues-button")
            for placeID in placeIDs[index] {
                let challenge = app.otherElements["fort-challenge-" + placeID].firstMatch
                let button = challenge.buttons["fort-choice-" + placeID].firstMatch
                reveal(button, in: app.scrollViews["scene-lesson-scroll"].firstMatch)
                XCTAssertTrue(button.isEnabled)
                button.tap()
            }
            tap("place-clues-got-it-button")
            if index == 2 {
                tap("Help me remember")
                XCTAssertTrue(app.staticTexts["recall-feedback"].exists)
            }
            tap("recall-choice-" + chapterID + "-" + answers[index])
            tap("recall-check-button")
            tap("recall-reward-button")
            if index < chapterIDs.count - 1 { tap("reward-next-button") }
        }
        capture("discovery-all-six-checked-journey")
        tap("reward-done-button")
    }

    func testLargeTextLandscapeDiscoveryResumesAndCanBeSkipped() {
        launch(largeText: true)
        setParentPreferences(narrationEnabled: false, calmEnabled: true)
        defer { XCUIDevice.shared.orientation = .portrait }
        tap("home-primary-lesson", scrollID: "home-story-scroll")
        XCUIDevice.shared.orientation = .landscapeLeft
        let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.windows.firstMatch.frame.width > self.app.windows.firstMatch.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
        tap("story-discovery-hill")
        XCTAssertFalse(app.buttons["listen-scene-1-shivneri-discovery-1"].exists)
        capture("discovery-accessibility-text-landscape")
        app.terminate()
        app.launch()
        tap("home-primary-lesson", scrollID: "home-story-scroll")
        let savedDetail = app.staticTexts["chapter-discovery-text-scene-1-shivneri-discovery-1"]
        reveal(savedDetail, in: app.scrollViews["scene-lesson-scroll"].firstMatch)
        XCTAssertFalse(app.staticTexts["chapter-discovery-text-scene-1-shivneri-discovery-2"].exists)
        XCTAssertFalse(app.buttons["recall-reward-button"].exists)
        tap("story-move-to-place-clues-button")
        XCTAssertTrue(app.staticTexts["fort-detective-clue"].firstMatch.waitForExistence(timeout: 10))
        capture("discovery-resumed-exposure-can-continue")
    }
}
