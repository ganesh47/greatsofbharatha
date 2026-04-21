import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasScenes() {
        let model = AppModel()
        XCTAssertFalse(model.content.scenes.isEmpty)
        XCTAssertEqual(model.content.scenes.first?.title, "Shivneri, where Shivaji Maharaj's story begins")
    }

    func testLessonStoreTracksProgress() {
        let store = ShivajiLessonStore(defaults: UserDefaults(suiteName: #function)!)
        XCTAssertEqual(store.completedScenes, 0)
        store.markScene("scene-1-shivneri", mastery: .witnessed)
        XCTAssertEqual(store.completedScenes, 1)
        XCTAssertNotNil(store.nextSceneID)
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

    func testLessonStoreUnlocksOnlyNextSceneByDefault() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertTrue(store.isSceneUnlocked(SampleContent.scene1))
        XCTAssertFalse(store.isSceneUnlocked(SampleContent.scene2))

        store.markScene(SampleContent.scene1.id, mastery: .understood)

        XCTAssertTrue(store.isSceneUnlocked(SampleContent.scene2))
    }
}
