import XCTest
@testable import GreatsOfBharathaTV

final class ChapterDiscoveryParityTests: XCTestCase {
    func testSharedDiscoveryCatalogExactlyMatchesAllSixAuthoredTVChapters() throws {
        XCTAssertEqual(ChapterDiscoveryContent.chapters.map(\.id), TVLearningContent.chapters.map(\.id))
        for chapter in TVLearningContent.chapters {
            let shared = try XCTUnwrap(ChapterDiscoveryContent.chapter(sceneID: chapter.id))
            XCTAssertEqual(chapter.storyBeats[1].text, chapter.plan.teachingText + " " + shared.teachingText)
            XCTAssertEqual(shared.familyPrompt, chapter.familyPrompt)
            XCTAssertEqual(shared.discoveries.map(\.id), chapter.discoveries.map(\.id))
            XCTAssertEqual(shared.discoveries.map(\.title), chapter.discoveries.map(\.title))
            XCTAssertEqual(shared.discoveries.map(\.symbol), chapter.discoveries.map(\.symbol))
            XCTAssertEqual(shared.discoveries.map(\.text), chapter.discoveries.map(\.text))
            XCTAssertEqual(shared.placeClues.map(\.id), chapter.placeClues.map(\.id))
            XCTAssertEqual(shared.placeClues.map(\.clue), chapter.placeClues.map(\.clue))
            XCTAssertEqual(shared.placeClues.map(\.answer), chapter.placeClues.map(\.answer))
            XCTAssertEqual(shared.placeClues.map(\.hint), chapter.placeClues.map(\.hint))
        }
    }
}
