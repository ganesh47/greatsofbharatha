import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasScenes() {
        let model = AppModel()
        XCTAssertFalse(model.content.scenes.isEmpty)
        XCTAssertEqual(model.content.scenes.first?.title, "Shivneri, where Shivaji Maharaj's story begins")
        XCTAssertEqual(model.content.activeHeroArc.scenes.count, 6)
    }

    func testLessonStoreTracksProgress() {
        let defaults = makeDefaults(testName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertEqual(store.completedScenes, 0)
        store.markScene("scene-1-shivneri", mastery: .witnessed)
        XCTAssertEqual(store.completedScenes, 0)

        store.markScene("scene-1-shivneri", mastery: .understood)
        XCTAssertEqual(store.completedScenes, 1)
        XCTAssertEqual(store.nextSceneID, "scene-2-torna-rajgad")
    }

    func testLessonFlowAdvancesOneStageAtATime() {
        let initial = SceneLessonFlow(
            totalStoryCards: 3,
            currentStoryCardIndex: 0,
            storyStepComplete: false,
            totalMapAnchors: 3,
            revealedMapAnchors: 0,
            hasAnsweredCorrectly: false
        )
        XCTAssertEqual(initial.activeStage, .story)
        XCTAssertEqual(initial.currentQuestStepID, "story")

        let afterStory = SceneLessonFlow(
            totalStoryCards: 3,
            currentStoryCardIndex: 2,
            storyStepComplete: true,
            totalMapAnchors: 3,
            revealedMapAnchors: 1,
            hasAnsweredCorrectly: false
        )
        XCTAssertEqual(afterStory.activeStage, .place)
        XCTAssertEqual(afterStory.currentQuestStepID, "place")

        let afterPlaces = SceneLessonFlow(
            totalStoryCards: 3,
            currentStoryCardIndex: 2,
            storyStepComplete: true,
            totalMapAnchors: 3,
            revealedMapAnchors: 3,
            hasAnsweredCorrectly: false
        )
        XCTAssertEqual(afterPlaces.activeStage, .chronicle)
        XCTAssertEqual(afterPlaces.currentQuestStepID, "chronicle")

        let completed = SceneLessonFlow(
            totalStoryCards: 3,
            currentStoryCardIndex: 2,
            storyStepComplete: true,
            totalMapAnchors: 3,
            revealedMapAnchors: 3,
            hasAnsweredCorrectly: true
        )
        XCTAssertEqual(completed.activeStage, .complete)
        XCTAssertEqual(completed.currentQuestStepID, "chronicle")
        XCTAssertEqual(completed.progressValue, 1.0)
    }

    func testLessonStoreUnlocksOnlyNextSceneAfterUnderstanding() {
        let defaults = makeDefaults(testName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        let firstScene = SampleContent.shivajiVerticalSlice.scenes[0]
        let secondScene = SampleContent.shivajiVerticalSlice.scenes[1]

        XCTAssertTrue(store.isSceneUnlocked(firstScene))
        XCTAssertFalse(store.isSceneUnlocked(secondScene))

        store.markScene(firstScene.id, mastery: .witnessed)
        XCTAssertFalse(store.isSceneUnlocked(secondScene))

        store.markScene(firstScene.id, mastery: .understood)
        XCTAssertTrue(store.isSceneUnlocked(secondScene))
    }

    func testChronicleUnlockRespectsEvidenceBasedMastery() {
        let defaults = makeDefaults(testName: #function)
        let store = ShivajiLessonStore(defaults: defaults)
        let reward = SampleContent.shivajiVerticalSlice.rewards.first { $0.id == "chronicle-birth-fort" }

        XCTAssertNotNil(reward)
        XCTAssertFalse(store.isUnlocked(reward!))

        store.markScene("scene-1-shivneri", mastery: .witnessed)
        XCTAssertFalse(store.isUnlocked(reward!))

        store.markScene("scene-1-shivneri", mastery: .understood)
        XCTAssertTrue(store.isUnlocked(reward!))
    }

    func testReviewScheduleAdvancesAfterSuccessfulRecall() {
        let defaults = makeDefaults(testName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        store.markScene("scene-1-shivneri", mastery: .understood)

        let record = store.masteryRecord(for: "scene-1-shivneri")
        let schedule = store.reviewSchedulesBySubject["scene-1-shivneri"]

        XCTAssertEqual(record?.state, .understood)
        XCTAssertEqual(record?.successfulReviewCount, 1)
        XCTAssertEqual(schedule?.intervalIndex, 1)
        XCTAssertEqual(schedule?.stabilityBand, .warming)
    }

    func testLocationAndTimelineStateProgressionUsesNewContracts() {
        let defaults = makeDefaults(testName: #function)
        let store = ShivajiLessonStore(defaults: defaults)
        let firstPlace = SampleContent.shivajiHeroArc.locationNodes.first { $0.id == "place-shivneri" }
        let firstEvent = SampleContent.timelineBirth

        XCTAssertEqual(store.locationUnlockState(for: firstPlace!), .learnable)
        XCTAssertEqual(store.timelineUnlockState(for: firstEvent), .hidden)

        store.markScene("scene-1-shivneri", mastery: .remembered)

        XCTAssertEqual(store.locationUnlockState(for: firstPlace!), .remembered)
        XCTAssertEqual(store.timelineUnlockState(for: firstEvent), .remembered)
    }

    private func makeDefaults(testName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: testName)!
        defaults.removePersistentDomain(forName: testName)
        return defaults
    }
}
