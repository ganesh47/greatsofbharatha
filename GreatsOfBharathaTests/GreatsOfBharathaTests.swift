import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasScenes() {
        let model = AppModel()
        XCTAssertFalse(model.content.scenes.isEmpty)
        XCTAssertEqual(model.content.scenes.first?.title, "Shivneri, where Shivaji Maharaj's story begins")
        XCTAssertEqual(model.content.scenes.first?.recallPrompt.answer, "Shivneri Fort")
    }

    func testLessonStoreTracksProgressAndUnlocksRewards() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertEqual(store.completedScenes, 0)
        XCTAssertEqual(store.nextSceneID, "scene-1-shivneri")
        XCTAssertFalse(store.isUnlocked(SampleContent.birthFortCard))

        store.markScene("scene-1-shivneri", mastery: .understood)

        XCTAssertEqual(store.completedScenes, 1)
        XCTAssertEqual(store.nextSceneID, "scene-2-torna-rajgad")
        XCTAssertTrue(store.isUnlocked(SampleContent.birthFortCard))
    }
}
