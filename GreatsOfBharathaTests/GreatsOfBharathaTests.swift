import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasShivajiArc() {
        let store = ShivajiLessonStore()
        XCTAssertFalse(store.scenes.isEmpty)
        XCTAssertEqual(store.scenes.first?.title, "Scene 1: Birth at Shivneri")
    }

    func testAppModelStartsOnStoryTab() {
        let model = AppModel()
        XCTAssertEqual(model.selectedTab, .story)
    }
}
