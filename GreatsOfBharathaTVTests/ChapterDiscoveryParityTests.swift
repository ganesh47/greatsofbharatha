import XCTest
@testable import GreatsOfBharathaTV

final class ChapterDiscoveryParityTests: XCTestCase {
    func testSharedDiscoveriesAndApprovedTeachingPreserveAllSixLegacyChapters() throws {
        XCTAssertEqual(ChapterDiscoveryContent.chapters.map(\.id), TVLearningContent.chapters.map(\.id))
        for chapter in TVLearningContent.chapters {
            let shared = try XCTUnwrap(ChapterDiscoveryContent.chapter(sceneID: chapter.id))
            let definition = try XCTUnwrap(ChapterKnowledgeCatalog.definition(sceneID: chapter.id))
            XCTAssertEqual(chapter.storyBeats.map(\.id), definition.beats.map(\.id))
            XCTAssertEqual(chapter.storyBeats.map(\.title), definition.beats.map(\.title))
            XCTAssertEqual(chapter.storyBeats.map(\.text), definition.beats.map(\.text))
            XCTAssertTrue(chapter.storyBeats[0].text.hasPrefix(chapter.pilot.story))
            XCTAssertTrue(chapter.storyBeats[1].text.hasPrefix(chapter.plan.teachingText + " " + shared.teachingText))
            XCTAssertTrue(chapter.storyBeats[2].text.hasPrefix(chapter.pilot.meaning))
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
