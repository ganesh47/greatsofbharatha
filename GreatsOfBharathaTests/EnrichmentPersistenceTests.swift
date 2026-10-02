import XCTest
@testable import Greats_Of_Bharatha

final class EnrichmentPersistenceTests: XCTestCase {
    func testDiscoverySelectionSurvivesRelaunchWithoutCompletingChapter() throws {
        let suite = "gob.enrichment.persistence." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let sceneID = "scene-2-torna-rajgad"
        let store = ShivajiLessonStore(defaults: defaults)
        let point = LessonResumePoint(sceneID: sceneID, discoveredDetailIDs: ["fort"], selectedDiscoveryDetailID: "fort")
        store.saveResumePoint(point)
        let restored = ShivajiLessonStore(defaults: defaults)
        XCTAssertEqual(restored.resumePoint(for: sceneID)?.selectedDiscoveryDetailID, "fort")
        XCTAssertEqual(restored.resumePoint(for: sceneID)?.discoveredDetailIDs, ["fort"])
        XCTAssertNil(restored.masteryRecord(for: sceneID))
        XCTAssertEqual(restored.completedScenes, 0)
    }

    func testOlderCheckpointWithoutDiscoverySelectionRemainsReadable() throws {
        let point = LessonResumePoint(sceneID: "scene-1-shivneri", phase: .place,
                                      discoveredDetailIDs: ["hill", "gate"])
        let encoded = try JSONEncoder().encode(point)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "selectedDiscoveryDetailID")
        let restored = try JSONDecoder().decode(LessonResumePoint.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(restored.selectedDiscoveryDetailID)
        XCTAssertEqual(restored.phase, .place)
        XCTAssertEqual(restored.discoveredDetailIDs, ["hill", "gate"])
        XCTAssertFalse(restored.recallCompleted)
    }
}
