import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasScenes() {
        let model = AppModel()
        XCTAssertFalse(model.content.scenes.isEmpty)
        XCTAssertEqual(model.content.scenes.first?.title, "Shivneri, where Shivaji Maharaj's story begins")
    }

    func testLessonStoreTracksProgress() {
        let store = ShivajiLessonStore()
        XCTAssertEqual(store.completedScenes, 0)
        store.markScene("scene-1-shivneri", mastery: .witnessed)
        XCTAssertEqual(store.completedScenes, 1)
        XCTAssertNotNil(store.nextSceneID)
    }
}
