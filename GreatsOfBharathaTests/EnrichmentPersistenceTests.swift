import XCTest
@testable import Greats_Of_Bharatha

final class EnrichmentPersistenceTests: XCTestCase {
    private struct ActivityFixture: Codable, Equatable {
        let selectedID: String
        let completionIDs: [UUID]
    }

    func testOptionalActivitySurvivesCompactRecoveryWithoutClobberingChapter() throws {
        let suite = "gob.enrichment.recovery." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let point = LessonResumePoint(sceneID: "scene-4-purandar-agra", phase: .recall)
        store.saveResumePoint(point)
        let activity = ActivityFixture(selectedID: "timeline-pressure-at-purandar", completionIDs: [UUID()])
        XCTAssertTrue(store.saveActivityState(activity, for: .timeline))
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(restored.activityState(ActivityFixture.self, for: .timeline), activity)
        XCTAssertEqual(restored.resumePoint(for: point.sceneID)?.sessionID, point.sessionID)
        defaults.set(Data("corrupt".utf8), forKey: "shivajiLessonStore.snapshot.v1")
        let recovered = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(recovered.activityState(ActivityFixture.self, for: .timeline), activity)
        XCTAssertEqual(recovered.resumePoint(for: point.sceneID)?.sessionID, point.sessionID)
        XCTAssertTrue(recovered.persistenceDiagnostics.isWithinBudget)
    }

    func testOversizedOptionalWritePreservesLastDurableActivity() throws {
        let suite = "gob.enrichment.bounds." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let activity = ActivityFixture(selectedID: "card", completionIDs: [UUID()])
        XCTAssertTrue(store.saveActivityState(activity, for: .review))
        XCTAssertFalse(store.saveActivityState(String(repeating: "x", count: 70_000), for: .review))
        XCTAssertEqual(store.activityState(ActivityFixture.self, for: .review), activity)
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(restored.activityState(ActivityFixture.self, for: .review), activity)
    }

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
