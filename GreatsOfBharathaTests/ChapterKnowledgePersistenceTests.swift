import XCTest
@testable import Greats_Of_Bharatha

@MainActor
final class ChapterKnowledgePersistenceTests: XCTestCase {
    func testLegacyJSONResumesOriginalBeatAndPreservesChapterAndTVState() throws {
        var point = LessonResumePoint(sceneID: "scene-4-purandar-agra", phase: .story,
            storyCardIndex: 1, revealedHintLevel: 2, recallCompleted: true, completedMatchPairIDs: ["pair"],
            selectedMatchTileID: "tile", discoveredDetailIDs: ["discovery"], selectedDiscoveryDetailID: "discovery")
        var television = TVActivityCheckpoint()
        television.storyBeatIndex = 1
        television.completedActivityIDs = ["story-beat-0", "recall"]
        television.completionEventIDs = ["story-beat-0": UUID()]
        television.timelineCheckpoint = TVTimelineCheckpoint()
        point.tvCheckpoint = television
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(point)) as? [String: Any])
        legacy.removeValue(forKey: "storyBeatID")
        var legacyTV = try XCTUnwrap(legacy["tvCheckpoint"] as? [String: Any])
        legacyTV.removeValue(forKey: "storyBeatID")
        legacy["tvCheckpoint"] = legacyTV
        let restored = try JSONDecoder().decode(LessonResumePoint.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(restored, point)
        let ordered = [point.sceneID + "-story", point.sceneID + "-knowledge-extra", point.sceneID + "-memory", point.sceneID + "-meaning"]
        let result = ChapterStoryBeatMigration.resolve(sceneID: point.sceneID, persistedBeatID: restored.storyBeatID,
            legacyIndex: restored.tvCheckpoint?.storyBeatIndex ?? restored.storyCardIndex, availableBeatIDs: ordered)
        XCTAssertEqual(result.beatID, point.sceneID + "-memory")
        XCTAssertEqual(restored.sessionID, point.sessionID)
        XCTAssertEqual(restored.tvCheckpoint?.completionEventIDs, television.completionEventIDs)
        XCTAssertEqual(restored.tvCheckpoint?.timelineCheckpoint, television.timelineCheckpoint)
    }

    func testStableTeachingCheckpointReopensAfterConfirmedCompactSave() throws {
        let suite = "gob.knowledge.stable." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        var point = LessonResumePoint(sceneID: "scene-1-shivneri", storyCardIndex: 0,
            discoveredDetailIDs: ["detail"], selectedDiscoveryDetailID: "detail", storyBeatID: "scene-1-shivneri-knowledge-water")
        var television = TVActivityCheckpoint()
        television.storyBeatID = point.storyBeatID
        point.tvCheckpoint = television
        XCTAssertTrue(store.saveResumePointConfirmed(point))
        let reopened = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(reopened.resumePoint(for: point.sceneID), point)
        XCTAssertTrue(reopened.persistenceDiagnostics.isWithinBudget)
    }

    func testRecognitionReceiptsSurviveRelaunchWithoutReplacingContinuationOrClaimingLaterRecall() throws {
        let suite = "gob.knowledge.receipts." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let definition = ChapterKnowledgeTestContent.definition()
        let point = LessonResumePoint(sceneID: definition.sceneID, phase: .place, revealedHintLevel: 2, selectedMatchTileID: "tile")
        XCTAssertTrue(store.saveResumePointConfirmed(point))
        let hooks = ChapterKnowledgeAdapters.hooks(store: store, definitions: [definition])
        var archive = hooks.load()
        for beat in definition.beats {
            let presented = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs),
                sessionID: point.sessionID, archive: archive, definition: definition, now: Date())
            archive = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(presented, hooks: hooks))
        }
        archive = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: point.sessionID, context: .individualRecognition)
        archive = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: archive, definition: definition)
        archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: Date())
        let checked = try XCTUnwrap(archive.pendingEvidence.first)
        archive = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(archive, hooks: hooks))
        XCTAssertTrue(archive.pendingEvidence.isEmpty)
        let reopened = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(reopened.resumePoint(for: point.sceneID), point)
        XCTAssertEqual(reopened.activityState(ChapterKnowledgeArchive.self, for: .knowledge), archive)
        let evidence = try XCTUnwrap(reopened.masteryRecord(for: point.sceneID)?.evidenceLog.first { $0.eventID == checked.id })
        XCTAssertEqual(evidence.promptType, .recognitionChoice)
        XCTAssertEqual(evidence.participation, .individualRecognition)
        XCTAssertEqual(evidence.reviewKind, .freshChecked)
        XCTAssertFalse(ChapterLearningSummary(record: reopened.masteryRecord(for: point.sceneID)).laterCardRecall)
        XCTAssertEqual(reopened.masteryRecord(for: point.sceneID)?.state, .understood)
        XCTAssertTrue(reopened.hasRecordedLearningEvent(checked.id))
        XCTAssertTrue(reopened.persistenceDiagnostics.isWithinBudget)
    }

    func testUnsupportedKnowledgePayloadAndChapterRemainByteSafeThroughOtherWrites() throws {
        for payload in [Data("not-json".utf8), Data("{\"schemaVersion\":99,\"futureField\":\"preserve\"}".utf8)] {
            let suite = "gob.knowledge.opaque." + UUID().uuidString
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
            let point = LessonResumePoint(sceneID: "scene-1-shivneri", phase: .recall)
            store.saveResumePoint(point)
            var snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: "shivajiLessonStore.snapshot.v1"))) as? [String: Any])
            snapshot["activityStateData"] = [LessonActivityStateKey.knowledge.rawValue: payload.base64EncodedString()]
            defaults.set(try JSONSerialization.data(withJSONObject: snapshot), forKey: "shivajiLessonStore.snapshot.v1")
            let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
            let hooks = ChapterKnowledgeAdapters.hooks(store: restored, definitions: [ChapterKnowledgeTestContent.definition()])
            XCTAssertFalse(hooks.load().isSupported)
            XCTAssertFalse(hooks.save(ChapterKnowledgeArchive()))
            restored.recordStoryExposure(for: "scene-2-torna-rajgad")
            let reopened = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
            XCTAssertEqual(reopened.activityStateData[LessonActivityStateKey.knowledge.rawValue], payload)
            XCTAssertEqual(reopened.resumePoint(for: point.sceneID), point)
        }
    }
}
