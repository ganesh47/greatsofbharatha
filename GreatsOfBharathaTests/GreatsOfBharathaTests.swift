import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasCanonicalSixSceneArc() {
        let model = AppModel()
        XCTAssertEqual(model.content.scenes.map(\.id), [
            "scene-1-shivneri",
            "scene-2-torna-rajgad",
            "scene-3-pratapgad-turning-point",
            "scene-4-purandar-agra",
            "scene-5-rajgad-recovery",
            "scene-6-raigad-coronation",
        ])
        XCTAssertEqual(model.content.scenes.first?.title, "Shivneri, where Shivaji Maharaj's story begins")
        XCTAssertEqual(model.content.scenes.first?.recallPrompt.answer, "Shivneri Fort")
        XCTAssertEqual(model.content.activeHeroArc.timelineEvents.map(\.id), [
            "timeline-born-at-shivneri",
            "timeline-early-forts",
            "timeline-pratapgad-turning-point",
            "timeline-pressure-at-purandar",
            "timeline-agra-and-return",
            "timeline-comeback-and-rebuilding",
            "timeline-raigad-coronation",
        ])
        XCTAssertEqual(Set(model.content.corePlaces.map(\.id)), [
            "place-shivneri",
            "place-torna",
            "place-rajgad",
            "place-pratapgad",
            "place-raigad",
        ])
    }

    func testSampleContentChronicleAndReviewBlueprintCoverage() {
        let heroArc = SampleContent.shivajiHeroArc

        XCTAssertEqual(heroArc.chronicleEntries.count, 18)
        XCTAssertEqual(Set(heroArc.chronicleEntries.map(\.linkedSceneID)), Set(heroArc.scenes.map(\.id)))
        XCTAssertEqual(Set(heroArc.locationNodes.map(\.id)), [
            "place-shivneri",
            "place-torna",
            "place-rajgad",
            "place-pratapgad",
            "place-purandar",
            "place-agra",
            "place-raigad",
        ])
        XCTAssertEqual(Set(heroArc.reviewBlueprints.filter { $0.subjectType == .scene }.map(\.subjectID)), Set(heroArc.scenes.map(\.id)))
        XCTAssertTrue(heroArc.reviewBlueprints.contains { $0.subjectID == "timeline-agra-and-return" && $0.subjectType == .timeline })
        XCTAssertTrue(heroArc.reviewBlueprints.contains { $0.subjectID == "place-raigad" && $0.subjectType == .location })
    }

    func testLessonStoreTracksProgressAndUnlocksRewards() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertEqual(store.completedScenes, 0)
        XCTAssertEqual(store.nextSceneID, "scene-1-shivneri")
        XCTAssertTrue(store.isUnlocked(SampleContent.birthFortCard))

        let guidanceEntry = SampleContent.shivajiHeroArc.chronicleEntry(withID: "reward-jijabai-guidance-badge")
        XCTAssertNotNil(guidanceEntry)
        XCTAssertEqual(store.chronicleUnlockState(for: guidanceEntry!), .silhouette)

        store.markScene("scene-1-shivneri", mastery: .understood)

        XCTAssertEqual(store.completedScenes, 1)
        XCTAssertEqual(store.nextSceneID, "scene-2-torna-rajgad")
        XCTAssertTrue(store.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(store.chronicleUnlockState(for: guidanceEntry!), .unlocked)
    }

    func testRecallEngineRevealsHintLadderBeforeRecognitionRescue() {
        let challenge = RecallChallenge(
            id: "scene-1-recall",
            promptType: .openPrompt,
            prompt: "Which fort is the birth place?",
            correctAnswers: ["Shivneri Fort"],
            hintLadder: [
                RecallHint(level: 1, title: "Anchor hint", body: "Think about the Birth Fort."),
                RecallHint(level: 2, title: "Place hint", body: "It is near Junnar."),
                RecallHint(level: 3, title: "Category hint", body: "It is a hill fort."),
            ],
            feedback: RecallFeedback(success: "Yes.", recovery: "Use recognition rescue."),
            masteryContribution: .remembered
        )

        var state = LessonRecallState()
        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        XCTAssertEqual(state.revealedHintLevel, 1)
        XCTAssertFalse(state.recognitionRescueUnlocked)
        XCTAssertEqual(LessonRecallEngine.currentHint(for: state, challenge: challenge)?.title, "Anchor hint")

        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        XCTAssertEqual(state.revealedHintLevel, 3)
        XCTAssertFalse(state.recognitionRescueUnlocked)

        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        XCTAssertTrue(state.recognitionRescueUnlocked)
        XCTAssertEqual(state.feedbackText, "Use recognition rescue.")
    }

    func testRecallEngineAwardsSuccessMasteryForTypedAnswer() {
        let challenge = RecallChallenge(
            id: "scene-2-recall",
            promptType: .openPrompt,
            prompt: "Which fort became an early capital?",
            correctAnswers: ["Rajgad"],
            hintLadder: [RecallHint(level: 1, title: "Meaning hint", body: "It came after Torna.")],
            feedback: RecallFeedback(success: "Yes. Rajgad became an early capital.", recovery: "Almost."),
            masteryContribution: .understood
        )

        let evaluation = LessonRecallEngine.submit(
            state: LessonRecallState(),
            challenge: challenge,
            typedAnswer: "Rajgad",
            selectedChoiceTitle: nil,
            successMastery: .observedClosely
        )

        XCTAssertTrue(evaluation.wasSuccessful)
        XCTAssertEqual(evaluation.masteryAwarded, .observedClosely)
        XCTAssertEqual(evaluation.feedbackText, "Yes. Rajgad became an early capital.")
    }

    func testStoreRecordRecallOutcomeAdvancesReviewSchedule() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        store.recordRecallOutcome(
            subjectID: "scene-1-shivneri",
            promptType: .openPrompt,
            wasSuccessful: true,
            mastery: .remembered,
            detail: "Test recall success"
        )

        XCTAssertEqual(store.mastery(for: "scene-1-shivneri"), .remembered)
        let record = store.masteryRecord(for: "scene-1-shivneri")
        XCTAssertEqual(record?.successfulReviewCount, 1)
        XCTAssertEqual(record?.evidenceLog.last?.type, .reviewSuccess)

        let dueReviews = store.dueReviews(referenceDate: .distantFuture)
        let schedule = dueReviews.first { $0.subjectID == "scene-1-shivneri" }
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.intervalIndex, 1)
        XCTAssertEqual(schedule?.stabilityBand, .warming)
    }
}
