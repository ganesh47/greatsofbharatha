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
        for attempt in 0...64 {
            let measuredFrame = element.exists ? element.frame : nil
            let targetFrame = measuredFrame.flatMap { $0.isEmpty || $0.isNull ? nil : $0 }
            let frames = scrollFrames(in: scroll)
            let viewport = frames.viewport
            let isButton = targetFrame != nil && (element.elementType == .button || element.elementType == .switch)
            if let targetFrame, frames.isVisible(targetFrame, isButton: isButton), element.isHittable {
                return
            }
            guard attempt < 64 else { break }
            // Native navigation can expose a target before its new scroll viewport settles.
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

    private func tap(_ identifier: String, scrollID: String = "scene-lesson-scroll", file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier].firstMatch
        reveal(button, in: app.scrollViews[scrollID].firstMatch, file: file, line: line)
        XCTAssertTrue(button.isEnabled, file: file, line: line)
        button.tap()
    }

    private func assertRevealedText(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let text = app.staticTexts[identifier].firstMatch
        let scroll = app.scrollViews["scene-lesson-scroll"].firstMatch
        reveal(text, in: scroll, file: file, line: line)
        let appeared = text.exists
        if !appeared { captureInteractionFailure(text, in: scroll) }
        XCTAssertTrue(appeared, "Missing revealed story text \(identifier)", file: file, line: line)
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
            let toggle = app.switches[identifier].firstMatch
            let expectedValue = enabled ? "1" : "0"
            guard toggle.waitForExistence(timeout: 10) else {
                captureInteractionFailure(toggle, in: app.scrollViews.firstMatch, expectedValue: expectedValue)
                XCTFail("Missing parent preference \(identifier)")
                return
            }
            reveal(toggle, in: app.scrollViews.firstMatch)
            guard toggle.isHittable else {
                captureInteractionFailure(toggle, in: app.scrollViews.firstMatch, expectedValue: expectedValue)
                XCTFail("Unreachable parent preference \(identifier)")
                return
            }
            if toggle.value as? String != expectedValue {
                toggle.tap()
                let changed = XCTNSPredicateExpectation(predicate: NSPredicate { object, _ in
                    (object as? XCUIElement)?.value as? String == expectedValue
                }, object: toggle)
                guard XCTWaiter.wait(for: [changed], timeout: 5) == .completed else {
                    captureInteractionFailure(toggle, in: app.scrollViews.firstMatch, expectedValue: expectedValue)
                    XCTFail("Parent preference \(identifier) did not become \(expectedValue); actual \(String(describing: toggle.value))")
                    return
                }
            }
            XCTAssertEqual(toggle.value as? String, expectedValue)
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
                assertRevealedText("chapter-discovery-text-" + chapterID + "-discovery-\(number)")
            }
            tap("chapter-family-reflection-" + chapterID)
            assertRevealedText("chapter-family-prompt-" + chapterID)
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
            for (placeIndex, placeID) in placeIDs[index].enumerated() {
                let challenge = app.otherElements["fort-challenge-" + placeID].firstMatch
                let button = challenge.buttons["fort-choice-" + placeID].firstMatch
                reveal(button, in: app.scrollViews["scene-lesson-scroll"].firstMatch)
                XCTAssertTrue(button.isEnabled)
                button.tap()
                tap("fort-check-button")
                if placeIndex < placeIDs[index].count - 1 { tap("place-clues-next-button") }
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
        let initialDetail = app.staticTexts["chapter-discovery-text-scene-1-shivneri-discovery-1"]
        reveal(initialDetail, in: app.scrollViews["scene-lesson-scroll"].firstMatch)
        XCTAssertTrue(initialDetail.exists, "The first discovery tap must reveal its text before testing relaunch")
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
