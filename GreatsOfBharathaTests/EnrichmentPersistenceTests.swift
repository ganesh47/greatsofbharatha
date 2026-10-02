import XCTest
@testable import Greats_Of_Bharatha

final class EnrichmentPersistenceTests: XCTestCase {
    func testFutureAndDamagedOptionalPayloadsStayOpaqueAcrossOpeningAndSaveAttempts() throws {
        for key in [LessonActivityStateKey.timeline, .review] {
            for payload in [Data("{\"schemaVersion\":99,\"futureValue\":\"keep\"}".utf8), Data("not-json".utf8)] {
                let suite = "gob.enrichment.opaque." + UUID().uuidString
                let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
                defer { defaults.removePersistentDomain(forName: suite) }
                let initial = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
                let chapter = LessonResumePoint(sceneID: "scene-1-shivneri", phase: .recall)
                initial.saveResumePoint(chapter)
                let snapshot = try XCTUnwrap(defaults.data(forKey: "shivajiLessonStore.snapshot.v1"))
                var json = try XCTUnwrap(JSONSerialization.jsonObject(with: snapshot) as? [String: Any])
                json["activityStateData"] = [key.rawValue: payload.base64EncodedString()]
                defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: "shivajiLessonStore.snapshot.v1")
                let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
                XCTAssertFalse(restored.activityStateIsAvailable(for: key))
                XCTAssertFalse(restored.saveActivityState(ReviewJourneyArchive(), for: key))
                XCTAssertEqual(restored.activityStateData[key.rawValue], payload)
                XCTAssertEqual(restored.resumePoint(for: chapter.sceneID), chapter)
                let reopened = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
                XCTAssertEqual(reopened.activityStateData[key.rawValue], payload)
                XCTAssertEqual(reopened.resumePoint(for: chapter.sceneID), chapter)
            }
        }
    }

    func testCompactCorruptionRecoveryPreservesTypedReviewProvenance() throws {
        let suite = "gob.enrichment.provenance." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let sceneID = "scene-1-shivneri"
        let now = Date()
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
            sessionID: UUID(), at: now.addingTimeInterval(-172_800))
        let eventID = UUID()
        store.recordLearningOutcome(subjectID: sceneID, activity: .review, wasSuccessful: true,
            eventID: eventID, sessionID: UUID(), at: now, cardID: "review-shivneri-birth-fort",
            checkedPromptID: "review-shivneri-event-to-place", reviewKind: .laterIndependentRecall, participation: .typedResponse)
        defaults.set(Data("damaged".utf8), forKey: "shivajiLessonStore.snapshot.v1")
        let recovered = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let event = try XCTUnwrap(recovered.masteryRecord(for: sceneID)?.evidenceLog.last { $0.eventID == eventID })
        XCTAssertEqual(event.cardID, "review-shivneri-birth-fort")
        XCTAssertEqual(event.checkedPromptID, "review-shivneri-event-to-place")
        XCTAssertEqual(event.reviewKind, .laterIndependentRecall)
        XCTAssertEqual(event.participation, .typedResponse)
        XCTAssertTrue(ChapterLearningSummary(record: recovered.masteryRecord(for: sceneID)).laterCardRecall)
        XCTAssertTrue(recovered.persistenceDiagnostics.isWithinBudget)
    }

    func testOptionalReceiptPreventsDuplicateAfterCompactHistoryRotates() throws {
        let suite = "gob.enrichment.receipts." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let eventID = UUID()
        XCTAssertTrue(store.recordStoryExposure(for: "scene-1-shivneri", eventID: eventID))
        XCTAssertTrue(store.confirmOptionalLearningEvent(eventID, for: .review))
        for _ in 0..<270 { store.recordStoryExposure(for: "scene-1-shivneri") }
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let count = restored.masteryRecord(for: "scene-1-shivneri")?.exposureCount
        XCTAssertTrue(restored.hasRecordedLearningEvent(eventID))
        XCTAssertFalse(restored.recordStoryExposure(for: "scene-1-shivneri", eventID: eventID))
        XCTAssertEqual(restored.masteryRecord(for: "scene-1-shivneri")?.exposureCount, count)
        XCTAssertTrue(restored.persistenceDiagnostics.isWithinBudget)
    }

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
        var activity = TimelineActivityCheckpoint()
        activity.currentRoundID = "ios-timeline-middle"
        XCTAssertTrue(store.saveActivityState(activity, for: .timeline))
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(restored.activityState(TimelineActivityCheckpoint.self, for: .timeline), activity)
        XCTAssertEqual(restored.resumePoint(for: point.sceneID)?.sessionID, point.sessionID)
        defaults.set(Data("corrupt".utf8), forKey: "shivajiLessonStore.snapshot.v1")
        let recovered = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(recovered.activityState(TimelineActivityCheckpoint.self, for: .timeline), activity)
        XCTAssertEqual(recovered.resumePoint(for: point.sceneID)?.sessionID, point.sessionID)
        XCTAssertTrue(recovered.persistenceDiagnostics.isWithinBudget)
    }

    func testOversizedOptionalWritePreservesLastDurableActivity() throws {
        let suite = "gob.enrichment.bounds." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let activity = ReviewJourneyArchive()
        XCTAssertTrue(store.saveActivityState(activity, for: .review))
        XCTAssertFalse(store.saveActivityState(String(repeating: "x", count: 70_000), for: .review))
        XCTAssertEqual(store.activityState(ReviewJourneyArchive.self, for: .review), activity)
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(restored.activityState(ReviewJourneyArchive.self, for: .review), activity)
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
