import XCTest

@MainActor
final class TVLearningJourneyUITests: XCTestCase {
    private var app: XCUIApplication!
    private let remote = XCUIRemote.shared

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["GOB_UI_TEST_SUITE"] = "gob.tv.ui." + UUID().uuidString
        app.launchEnvironment["GOB_UI_TEST_RESET"] = "1"
    }

    private func launch() {
        app.launch()
        app.launchEnvironment.removeValue(forKey: "GOB_UI_TEST_RESET")
        XCTAssertTrue(app.buttons["tv-home-continue"].waitForExistence(timeout: 10))
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
        let exists = target.waitForExistence(timeout: 10)
        if !exists {
            capture("missing-" + identifier)
            print("Missing remote target \(identifier):\n" + app.debugDescription)
        }
        XCTAssertTrue(exists, "Missing \(identifier)", file: file, line: line)
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

    private func reachFirstRecall() {
        select("tv-home-continue")
        TVKnowledgeUITestJourney.finishStory(app: app, select: { select($0) })
        select("tv-discovery-continue")
        select("tv-fort-place-shivneri")
        select("tv-fort-check")
        select("tv-fort-continue")
        XCTAssertTrue(app.buttons["tv-recall-scene-1-shivneri-shivneri"].waitForExistence(timeout: 10))
    }

    private func reachFirstMatching() {
        reachFirstRecall()
        select("tv-recall-scene-1-shivneri-shivneri")
        select("tv-recall-check")
        select("tv-recall-continue")
        TVKnowledgeUITestJourney.finishPractice(app: app, select: { select($0) })
        XCTAssertTrue(app.staticTexts["tv-match-left-title"].waitForExistence(timeout: 10))
    }

    private func expectFocus(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: app.buttons[identifier])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, "Expected focus on \(identifier)", file: file, line: line)
    }

    func testMatchingPanelsKeepChosenSeparateFromFocusAndRestoreAfterRelaunch() {
        launch()
        reachFirstMatching()
        let birth = "tv-puzzle-left-match-shivneri-birth-fort"
        let mother = "tv-puzzle-left-tv-match-jijabai-guidance"
        let birthClue = "tv-puzzle-right-match-shivneri-birth-fort"
        let guidance = "tv-puzzle-right-tv-match-jijabai-guidance"
        XCTAssertEqual(app.staticTexts["tv-match-left-title"].label, "People and places")
        XCTAssertEqual(app.staticTexts["tv-match-right-title"].label, "Story clues")
        capture("matching-panels-entry")

        focus(birth)
        XCTAssertEqual(app.buttons[birth].value as? String, "Available", "Remote focus must not choose a source")
        remote.press(.select)
        XCTAssertEqual(app.buttons[birth].value as? String, "Selected")
        expectFocus(guidance)
        XCTAssertEqual(app.buttons[guidance].value as? String, "Available", "A focused partner is not a submitted answer")
        capture("matching-chosen-source-focused-partner")

        // Choosing a different source is a replacement, not a failed association.
        select(mother)
        XCTAssertEqual(app.buttons[mother].value as? String, "Selected")
        XCTAssertEqual(app.buttons[birth].value as? String, "Available")
        XCTAssertFalse(app.staticTexts["tv-puzzle-feedback"].label.contains("look again"))
        select(birth)
        expectFocus(guidance)
        remote.press(.select)
        XCTAssertEqual(app.buttons[birth].value as? String, "Selected", "A wrong partner must retain the chosen source")
        XCTAssertEqual(app.buttons[guidance].value as? String, "Available")
        XCTAssertTrue(app.buttons[guidance].hasFocus, "A rejected partner must retain actual remote focus")
        XCTAssertFalse(app.buttons["tv-puzzle-continue"].exists)
        capture("matching-gentle-retry-retains-source")

        remote.press(.menu)
        XCTAssertEqual(app.buttons[birth].value as? String, "Available", "Back first puts the choice away")
        XCTAssertTrue(app.staticTexts["tv-match-left-title"].exists, "Back must not exit while clearing a choice")
        select(birth)
        app.terminate()
        app.launch()
        select("tv-home-continue")
        XCTAssertTrue(app.staticTexts["tv-match-left-title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons[birth].value as? String, "Selected")
        expectFocus(guidance)
        capture("matching-selected-source-restored")

        select(birthClue) // Submit the retained source without toggling it off.
        XCTAssertEqual(app.buttons[birth].value as? String, "Matched")
        select(mother)
        select(guidance)
        let recap = app.staticTexts["tv-match-recap"]
        XCTAssertTrue(recap.waitForExistence(timeout: 10))
        XCTAssertTrue(recap.label.contains("Shivneri — Birth Fort"))
        XCTAssertTrue(recap.label.contains("Jijabai — Guidance and care"))
        expectFocus("tv-puzzle-continue")
        capture("matching-readable-completed-story-links")
    }

    func testMatchingClueAndSharedPlacementRemainUsableWithGentleMotionAndNarrationOff() {
        launch()
        select("tv-home-parent")
        select("tv-parent-narration")
        select("tv-parent-calm")
        XCTAssertEqual(app.buttons["tv-parent-narration"].value as? String, "Off")
        XCTAssertEqual(app.buttons["tv-parent-calm"].value as? String, "Off")
        remote.press(.menu)
        reachFirstMatching()
        select("tv-puzzle-right-tv-match-jijabai-guidance")
        select("tv-puzzle-help")
        XCTAssertEqual(app.buttons["tv-puzzle-right-tv-match-jijabai-guidance"].value as? String, "Selected")
        XCTAssertTrue(app.staticTexts["tv-puzzle-feedback"].label.contains("Choose Jijabai"), "Help should teach the chosen source's pair")
        select("tv-puzzle-rescue")
        XCTAssertEqual(app.buttons["tv-puzzle-left-tv-match-jijabai-guidance"].value as? String, "Matched")
        XCTAssertEqual(app.buttons["tv-puzzle-left-match-shivneri-birth-fort"].value as? String, "Available")
        capture("matching-firefly-shared-link")
        select("tv-puzzle-left-match-shivneri-birth-fort")
        select("tv-puzzle-right-match-shivneri-birth-fort")
        XCTAssertTrue(app.staticTexts["tv-match-recap"].waitForExistence(timeout: 10))
        select("tv-puzzle-continue")
        XCTAssertTrue(app.buttons["tv-keepsake-select"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tv-listen-'")).firstMatch.exists)
    }

    func testThreePairMatchingRecapAndContinueFitTheScreen() {
        app.launchEnvironment["GOB_UI_TEST_SEED_THROUGH_CHAPTER"] = "3"
        launch()
        let chapter = chapters[2]
        select("tv-home-chapter-" + chapter.id)
        TVKnowledgeUITestJourney.finishStory(app: app, select: { select($0) })
        select("tv-discovery-continue")
        select("tv-fort-place-pratapgad")
        select("tv-fort-check")
        select("tv-fort-continue")
        select("tv-recall-" + chapter.id + "-pratapgad")
        select("tv-recall-check")
        select("tv-recall-continue")
        TVKnowledgeUITestJourney.finishPractice(app: app, select: { select($0) })
        XCTAssertEqual(app.staticTexts["tv-match-left-title"].label, "Story cards")
        XCTAssertEqual(app.staticTexts["tv-match-right-title"].label, "What they mean")
        capture("matching-three-pairs-readable-entry")
        for pairID in chapter.pairIDs {
            select("tv-puzzle-left-" + pairID)
            select("tv-puzzle-right-" + pairID)
            XCTAssertEqual(app.buttons["tv-puzzle-left-" + pairID].value as? String, "Matched")
        }
        let recap = app.staticTexts["tv-match-recap"]
        XCTAssertTrue(recap.waitForExistence(timeout: 10))
        XCTAssertTrue(recap.label.contains("Pratapgad"))
        let continuation = app.buttons["tv-puzzle-continue"]
        expectFocus("tv-puzzle-continue")
        let safeFrame = app.frame.insetBy(dx: 72, dy: 44)
        for element in [recap, continuation] {
            XCTAssertGreaterThanOrEqual(element.frame.minX, safeFrame.minX)
            XCTAssertLessThanOrEqual(element.frame.maxX, safeFrame.maxX)
            XCTAssertGreaterThanOrEqual(element.frame.minY, safeFrame.minY)
            XCTAssertLessThanOrEqual(element.frame.maxY, safeFrame.maxY, "All three links and Continue must fit without scrolling")
        }
        capture("matching-three-pairs-readable-completion")
    }

    func testFocusNeedsSelectAndParentPreferencesPersist() {
        launch()
        capture("01-tv-home")
        focus("tv-home-album")
        XCTAssertTrue(app.buttons["tv-home-continue"].exists, "Moving focus must not navigate")
        XCTAssertFalse(app.staticTexts["My storybook Album"].exists)
        remote.press(.select)
        let lockedReward = app.buttons["tv-album-reward-birth-fort-card"]
        XCTAssertTrue(lockedReward.waitForExistence(timeout: 10))
        XCTAssertFalse(lockedReward.isEnabled)
        remote.press(.menu)
        select("tv-home-parent")
        for identifier in ["tv-parent-narration", "tv-parent-assist", "tv-parent-calm"] {
            XCTAssertEqual(app.buttons[identifier].value as? String, "On")
            select(identifier)
            XCTAssertEqual(app.buttons[identifier].value as? String, "Off")
        }
        capture("02-tv-parent-settings-off")
        app.terminate()
        app.launch()
        select("tv-home-parent")
        for identifier in ["tv-parent-narration", "tv-parent-assist", "tv-parent-calm"] {
            XCTAssertEqual(app.buttons[identifier].value as? String, "Off")
        }
        remote.press(.menu)
        select("tv-home-continue")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tv-listen-'")).firstMatch.exists)
        XCTAssertTrue(app.buttons["tv-lesson-story-next"].exists, "The core story remains usable without narration")
    }

    func testBackClearsChoiceAndRelaunchResumesRecallWithoutAward() {
        launch()
        reachFirstRecall()
        let choiceID = "tv-recall-scene-1-shivneri-shivneri"
        focus(choiceID)
        XCTAssertFalse(app.buttons["tv-recall-continue"].exists, "Focus must not count as an answer")
        remote.press(.select)
        XCTAssertEqual(app.buttons[choiceID].value as? String, "Selected")
        remote.press(.menu)
        XCTAssertEqual(app.buttons[choiceID].value as? String, "Available")
        XCTAssertFalse(app.buttons["tv-recall-continue"].exists)
        remote.press(.menu)
        XCTAssertTrue(app.buttons["tv-home-continue"].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        select("tv-home-continue")
        XCTAssertTrue(app.buttons[choiceID].waitForExistence(timeout: 10), "Continue must restore the recall stage")
        XCTAssertEqual(app.buttons[choiceID].value as? String, "Available")
        XCTAssertFalse(app.buttons["tv-recall-continue"].exists)
        capture("03-tv-resumed-recall")
    }

    func testRemotePlayPauseControlsNarration() {
        launch()
        select("tv-home-continue")
        select("tv-listen-scene-1-shivneri-story")
        let pause = app.buttons["tv-narration-pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        remote.press(.playPause)
        let paused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS 'Keep listening'"), object: pause)
        XCTAssertEqual(XCTWaiter.wait(for: [paused], timeout: 5), .completed)
        capture("04-tv-narration-paused")
        remote.press(.playPause)
        let resumed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS 'Pause'"), object: pause)
        XCTAssertEqual(XCTWaiter.wait(for: [resumed], timeout: 5), .completed)
        remote.press(.menu)
        XCTAssertTrue(app.buttons["tv-home-continue"].waitForExistence(timeout: 10))
    }

    func testLockedTimelineCannotStartALaterChapter() {
        launch()
        select("tv-home-timeline")
        XCTAssertTrue(app.buttons["tv-timeline-back"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tv-timeline-start"].exists)
        remote.press(.menu)
        let continuation = app.buttons["tv-home-continue"]
        XCTAssertTrue(continuation.waitForExistence(timeout: 10))
        XCTAssertTrue(continuation.label.contains("Shivneri"))
        XCTAssertFalse(app.buttons["tv-home-chapter-scene-3-pratapgad-turning-point"].isEnabled)
        app.terminate()
        app.launch()
        XCTAssertTrue(continuation.waitForExistence(timeout: 10))
        XCTAssertTrue(continuation.label.contains("Shivneri"), "An unopened timeline must not create later chapter progress")
        select("tv-home-continue")
        XCTAssertTrue(app.staticTexts["Shivneri - Birth Fort"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tv-lesson-story-next"].exists)
    }

    func testChapterFourOrderingRemainsReachableAfterWrongChoiceAndTwoPlacements() {
        app.launchEnvironment["GOB_UI_TEST_SEED_THROUGH_CHAPTER"] = "3"
        launch()
        XCTAssertTrue(app.buttons["tv-home-continue"].label.contains("Purandar"))
        select("tv-home-continue")
        TVKnowledgeUITestJourney.finishStory(app: app, select: { select($0) })
        select("tv-discovery-continue")
        select("tv-fort-place-purandar")
        select("tv-fort-check")
        select("tv-fort-place-agra")
        select("tv-fort-check")
        select("tv-fort-continue")
        select("tv-recall-scene-4-purandar-agra-purandar")
        select("tv-recall-check")
        select("tv-recall-continue")
        TVKnowledgeUITestJourney.finishPractice(app: app, select: { select($0) })
        select("tv-sequence-card-timeline-agra-and-return")
        select("tv-sequence-slot-0")
        XCTAssertFalse(app.buttons["tv-puzzle-continue"].exists)
        select("tv-sequence-help")
        let events = ["timeline-pratapgad-turning-point", "timeline-pressure-at-purandar", "timeline-agra-and-return"]
        for (slot, eventID) in events.enumerated() {
            if slot == 2 {
                XCTAssertEqual(app.buttons["tv-sequence-card-" + eventID].value as? String, "Selected",
                               "Submit the restored selection without toggling it off")
            } else {
                select("tv-sequence-card-" + eventID)
            }
            select("tv-sequence-slot-" + String(slot))
            XCTAssertEqual(app.buttons["tv-sequence-card-" + eventID].value as? String, "Placed")
            if slot == 1 {
                remote.press(.menu)
                XCTAssertTrue(app.buttons["tv-home-continue"].waitForExistence(timeout: 10))
                app.terminate()
                app.launch()
                select("tv-home-continue")
                for placedID in events.prefix(2) {
                    XCTAssertEqual(app.buttons["tv-sequence-card-" + placedID].value as? String, "Placed")
                }
                let remainingCard = app.buttons["tv-sequence-card-" + events[2]]
                XCTAssertEqual(remainingCard.value as? String, "Available")
                let restoredCardFocus = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: remainingCard)
                XCTAssertEqual(XCTWaiter.wait(for: [restoredCardFocus], timeout: 5), .completed,
                               "A partial puzzle should focus its first available card on entry")
                capture("chapter-4-partial-order-restored-focus")
                remote.press(.select)
                XCTAssertEqual(remainingCard.value as? String, "Selected")
                app.terminate()
                app.launch()
                select("tv-home-continue")
                XCTAssertEqual(remainingCard.value as? String, "Selected")
                let remainingSlot = app.buttons["tv-sequence-slot-2"]
                capture("chapter-4-selected-order-before-focus-check")
                let restoredSlotFocus = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasFocus == true"), object: remainingSlot)
                XCTAssertEqual(XCTWaiter.wait(for: [restoredSlotFocus], timeout: 5), .completed,
                               "A restored selected card should focus the first empty slot")
                capture("chapter-4-selected-order-native-focused")
            }
        }
        XCTAssertTrue(app.staticTexts["tv-puzzle-success"].waitForExistence(timeout: 10))
        capture("chapter-4-ordering-focus-regression")
        select("tv-puzzle-continue")
        XCTAssertTrue(app.buttons["tv-keepsake-select"].waitForExistence(timeout: 10))
        focus("tv-keepsake-select")
        capture("chapter-4-keepsake-ready")
    }

    func testAllSixChaptersRetryMatchOrderKeepAndRelaunch() {
        launch()
        select("tv-home-continue")
        for (index, chapter) in chapters.enumerated() {
            XCTAssertTrue(app.buttons["tv-lesson-story-next"].waitForExistence(timeout: 10))
            capture("story-chapter-" + String(index + 1))
            TVKnowledgeUITestJourney.finishStory(app: app, select: { select($0) })
            select("tv-discovery-" + chapter.id + "-discovery-1")
            XCTAssertTrue(app.buttons["tv-discovery-close"].waitForExistence(timeout: 10))
            remote.press(.menu)
            select("tv-discovery-continue")
            for placeID in chapter.places {
                select("tv-fort-" + placeID)
                select("tv-fort-check")
            }
            select("tv-fort-continue")
            if index == 0 {
                select("tv-recall-scene-1-shivneri-rajgad")
                select("tv-recall-check")
                XCTAssertTrue(app.staticTexts["tv-recall-feedback"].waitForExistence(timeout: 10))
                XCTAssertFalse(app.buttons["tv-recall-continue"].exists)
                XCTAssertFalse(app.buttons["tv-keepsake-place"].exists)
                capture("05-tv-gentle-retry")
                select("tv-recall-help")
            }
            select("tv-recall-" + chapter.id + "-" + chapter.answer)
            select("tv-recall-check")
            XCTAssertTrue(app.staticTexts["tv-recall-success"].waitForExistence(timeout: 10))
            select("tv-recall-continue")
        TVKnowledgeUITestJourney.finishPractice(app: app, select: { select($0) })
            if !chapter.pairIDs.isEmpty {
                if index == 0 {
                    select("tv-puzzle-left-" + chapter.pairIDs[0])
                    select("tv-puzzle-right-" + chapter.pairIDs[1])
                    XCTAssertFalse(app.buttons["tv-puzzle-continue"].exists)
                    XCTAssertTrue(app.staticTexts["tv-puzzle-feedback"].label.contains("look again"))
                    XCTAssertEqual(app.buttons["tv-puzzle-left-" + chapter.pairIDs[0]].value as? String, "Selected")
                }
                for pairID in chapter.pairIDs {
                    if app.buttons["tv-puzzle-left-" + pairID].value as? String != "Selected" {
                        select("tv-puzzle-left-" + pairID)
                    }
                    select("tv-puzzle-right-" + pairID)
                    XCTAssertEqual(app.buttons["tv-puzzle-left-" + pairID].value as? String, "Matched")
                }
                capture("matching-chapter-" + String(index + 1))
            } else {
                if index == 3 {
                    select("tv-sequence-card-" + chapter.sequenceIDs[2])
                    select("tv-sequence-slot-0")
                    XCTAssertFalse(app.buttons["tv-puzzle-continue"].exists)
                    XCTAssertTrue(app.staticTexts["tv-sequence-feedback"].waitForExistence(timeout: 10))
                    select("tv-sequence-help")
                }
                for (slot, eventID) in chapter.sequenceIDs.enumerated() {
                    select("tv-sequence-card-" + eventID)
                    select("tv-sequence-slot-" + String(slot))
                    XCTAssertEqual(app.buttons["tv-sequence-card-" + eventID].value as? String, "Placed")
                }
                capture("06-tv-ordering-chapter-" + String(index + 1))
            }
            XCTAssertTrue(app.staticTexts["tv-puzzle-success"].waitForExistence(timeout: 10))
            select("tv-puzzle-continue")
            XCTAssertFalse(app.buttons["tv-keepsake-place"].isEnabled)
            select("tv-keepsake-select")
            select("tv-keepsake-place")
            XCTAssertTrue(app.staticTexts["tv-keepsake-success"].waitForExistence(timeout: 10))
            if index == chapters.count - 1 { capture("final-chapter-keepsake-placed") }
            if index == 0 {
                select("tv-all-done")
                let continuation = app.buttons["tv-home-continue"]
                XCTAssertTrue(continuation.waitForExistence(timeout: 10))
                XCTAssertTrue(continuation.label.contains("Torna"), "All done must lead to the next useful chapter")
                select("tv-home-continue")
            } else if index < chapters.count - 1 {
                select("tv-next-chapter")
            } else {
                verifyFinalAdventureReturnsToKeepsake()
                // A nested timeline save must survive the older lesson checkpoint saving on return and All done.
                select("tv-open-timeline")
                select("tv-timeline-start")
                select("tv-sequence-card-" + fullTimelineRounds[0][0])
                select("tv-sequence-slot-0")
                remote.press(.menu)
                XCTAssertTrue(app.staticTexts["tv-keepsake-success"].waitForExistence(timeout: 10))
                select("tv-all-done")
                app.terminate()
                app.launch()
            }
        }
        XCTAssertTrue(app.buttons["tv-home-continue"].waitForExistence(timeout: 10))
        select("tv-home-continue")
        XCTAssertTrue(app.buttons["tv-lesson-story-next"].waitForExistence(timeout: 10),
                      "After the final chapter, the primary action must start a useful replay")
        remote.press(.menu)
        completeRestoredFullTimeline()
        select("tv-home-album")
        let birthKeepsake = app.buttons["tv-album-reward-birth-fort-card"]
        XCTAssertTrue(birthKeepsake.waitForExistence(timeout: 10))
        XCTAssertTrue(birthKeepsake.isEnabled)
        XCTAssertTrue(birthKeepsake.label.contains("Placed on my chapter page"))
        capture("08-tv-earned-album")
        app.terminate()
        app.launch()
        select("tv-home-album")
        XCTAssertTrue(birthKeepsake.label.contains("Placed on my chapter page"))
        select("tv-album-reward-birth-fort-card")
        XCTAssertTrue(app.descendants(matching: .any)["tv-album-placed"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tv-album-place"].exists, "Relaunch must not offer to award the same placement again")
        capture("09-tv-album-after-relaunch")
    }

}

private extension TVLearningJourneyUITests {
    func completeRestoredFullTimeline() {
        select("tv-home-timeline")
        for (roundIndex, round) in fullTimelineRounds.enumerated() {
            if roundIndex == 0 {
                XCTAssertTrue(app.buttons["tv-sequence-card-" + round[0]].waitForExistence(timeout: 10))
                XCTAssertFalse(app.buttons["tv-timeline-start"].exists,
                               "A taught partial timeline should resume its puzzle directly")
            } else {
                select("tv-timeline-start")
            }
            for (slot, eventID) in round.enumerated() {
                if roundIndex == 0 && slot == 0 {
                    XCTAssertEqual(app.buttons["tv-sequence-card-" + eventID].value as? String, "Placed",
                                   "Partial timeline placement must survive returning to the lesson, All done and relaunch")
                    continue
                }
                select("tv-sequence-card-" + eventID)
                select("tv-sequence-slot-" + String(slot))
            }
            if roundIndex < fullTimelineRounds.count - 1 { select("tv-timeline-next") }
        }
        XCTAssertTrue(app.descendants(matching: .any)["tv-timeline-success"].waitForExistence(timeout: 10))
        capture("07-tv-seven-event-timeline")
        select("tv-timeline-done")
    }

    func verifyFinalAdventureReturnsToKeepsake() {
        select("tv-next-chapter")
        XCTAssertTrue(app.staticTexts["Explore the fort board"].waitForExistence(timeout: 10),
                      "The final chapter's next adventure should open the fort board")
        XCTAssertTrue(app.buttons["tv-map-place-raigad"].exists)
        capture("final-next-adventure-fort-board")
        remote.press(.menu)
        XCTAssertTrue(app.staticTexts["tv-keepsake-success"].waitForExistence(timeout: 10))
    }

    struct ChapterFixture {
        let id: String
        let places: [String]
        let answer: String
        let pairIDs: [String]
        var sequenceIDs: [String] = []
    }

    var chapters: [ChapterFixture] {
        [
            ChapterFixture(id: "scene-1-shivneri", places: ["place-shivneri"], answer: "shivneri",
                           pairIDs: ["match-shivneri-birth-fort", "tv-match-jijabai-guidance"]),
            ChapterFixture(id: "scene-2-torna-rajgad", places: ["place-torna", "place-rajgad"], answer: "rajgad",
                           pairIDs: ["match-torna-first-big-fort", "match-rajgad-early-capital"]),
            ChapterFixture(id: "scene-3-pratapgad-turning-point", places: ["place-pratapgad"], answer: "pratapgad",
                           pairIDs: ["match-pratapgad-turning-point", "tv-match-terrain-shape", "tv-match-preparation-plan"]),
            ChapterFixture(id: "scene-4-purandar-agra", places: ["place-purandar", "place-agra"], answer: "purandar", pairIDs: [],
                           sequenceIDs: ["timeline-pratapgad-turning-point", "timeline-pressure-at-purandar", "timeline-agra-and-return"]),
            ChapterFixture(id: "scene-5-rajgad-recovery", places: ["place-rajgad"], answer: "rebuilt",
                           pairIDs: ["match-rajgad-comeback", "tv-match-rebuilding-strength"]),
            ChapterFixture(id: "scene-6-raigad-coronation", places: ["place-raigad"], answer: "raigad", pairIDs: [],
                           sequenceIDs: ["timeline-agra-and-return", "timeline-comeback-and-rebuilding", "timeline-raigad-coronation"])
        ]
    }

    var fullTimelineRounds: [[String]] {
        [
            ["timeline-born-at-shivneri", "timeline-early-forts", "timeline-pratapgad-turning-point"],
            ["timeline-pratapgad-turning-point", "timeline-pressure-at-purandar", "timeline-agra-and-return"],
            ["timeline-agra-and-return", "timeline-comeback-and-rebuilding", "timeline-raigad-coronation"]
        ]
    }
}
