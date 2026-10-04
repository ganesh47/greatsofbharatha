import XCTest
@testable import GreatsOfBharathaTV

@MainActor
final class TVChapterKnowledgeTests: XCTestCase {
    func testEmptySiblingPreferencesCannotEraseTheTVCaptionFrame() {
        let actual = TVKnowledgeTextFrame(id: "caption", frame: CGRect(x: 76, y: 300, width: 1000, height: 240))
        var reduced = TVKnowledgeTextFrameKey.defaultValue
        TVKnowledgeTextFrameKey.reduce(value: &reduced) { actual }
        TVKnowledgeTextFrameKey.reduce(value: &reduced) { TVKnowledgeTextFrameKey.defaultValue }
        XCTAssertEqual(reduced, actual)
    }

    func testUnsupportedOptionalDataKeepsFreshStoryAndCompletedRecallContinuations() throws {
        for payload in [Data("not-json".utf8), Data("{\"schemaVersion\":99,\"futureField\":\"preserve\"}".utf8)] {
            for stage in [TVActivityStage.story, .recall] {
                let suite = "gob.tv.knowledge.fallback." + UUID().uuidString
                let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
                defer { defaults.removePersistentDomain(forName: suite) }
                let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
                let definition = ChapterKnowledgeCatalog.definitions[0]
                var point = LessonResumePoint(sceneID: definition.sceneID)
                var checkpoint = TVActivityCheckpoint()
                checkpoint.stage = stage
                if stage == .recall {
                    checkpoint.completedActivityIDs = ["recall"]
                    checkpoint.knowledgePracticePending = true
                }
                point.tvCheckpoint = checkpoint
                XCTAssertTrue(store.saveResumePointConfirmed(point))
                var snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with:
                    XCTUnwrap(defaults.data(forKey: "shivajiLessonStore.snapshot.v1"))) as? [String: Any])
                snapshot["activityStateData"] = [LessonActivityStateKey.knowledge.rawValue: payload.base64EncodedString()]
                defaults.set(try JSONSerialization.data(withJSONObject: snapshot), forKey: "shivajiLessonStore.snapshot.v1")
                let reopened = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
                XCTAssertFalse(TVChapterKnowledgeContinuation.isAvailable(store: reopened, definition: definition))
                XCTAssertTrue(TVChapterKnowledgeContinuation.restartTeachingPosition(store: reopened, definition: definition))
                XCTAssertEqual(reopened.resumePoint(for: point.sceneID), point)
                point.tvCheckpoint?.stage = stage == .story ? .discover : .puzzle
                XCTAssertTrue(reopened.saveResumePointConfirmed(point))
                let afterContinuation = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
                XCTAssertEqual(afterContinuation.resumePoint(for: point.sceneID), point)
                XCTAssertEqual(afterContinuation.activityStateData[LessonActivityStateKey.knowledge.rawValue], payload)
            }
        }
    }

    func testExplicitReplayOnlyResetsActiveKnowledgePositionAndPreservesTimeline() throws {
        let suite = "gob.tv.knowledge.replay." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let definition = ChapterKnowledgeCatalog.definitions[0]
        let hooks = ChapterKnowledgeAdapters.hooks(store: store, definitions: ChapterKnowledgeCatalog.definitions)
        var archive = hooks.load()
        for beat in definition.beats {
            archive = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(ChapterKnowledgeJourney.presentedBeat(beat.id,
                visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(), archive: archive,
                definition: definition, now: Date()), hooks: hooks))
        }
        XCTAssertEqual(archive.teachingBySceneID[definition.sceneID]?.activeBeatID, definition.beats.last?.id)
        let before = archive
        XCTAssertTrue(TVChapterKnowledgeContinuation.restartTeachingPosition(store: store, definition: definition))
        archive = hooks.load()
        var expected = before
        expected.teachingBySceneID[definition.sceneID]?.activeBeatID = definition.beats[0].id
        XCTAssertEqual(archive, expected)
        var prior = TVActivityCheckpoint()
        prior.stage = .keepsake
        prior.timelineCheckpoint = TVTimelineCheckpoint()
        prior.completedActivityIDs = ["recall", "timeline-round-1"]
        prior.helpedActivityIDs = ["puzzle", "timeline-round-1"]
        prior.completionEventIDs = ["recall": UUID(), "timeline-round-1": UUID()]
        let restarted = TVChapterKnowledgeContinuation.restartedCheckpoint(preserving: prior)
        XCTAssertEqual(restarted.stage, .story)
        XCTAssertEqual(restarted.completedActivityIDs, ["timeline-round-1"])
        XCTAssertEqual(restarted.helpedActivityIDs, ["timeline-round-1"])
        XCTAssertEqual(restarted.completionEventIDs, prior.completionEventIDs.filter { $0.key.hasPrefix("timeline-") })
        XCTAssertEqual(restarted.timelineCheckpoint, prior.timelineCheckpoint)
    }
    func testCaptionPagesKeepEveryNarrativeAndFactWordBeforeReceipt() {
        for definition in ChapterKnowledgeCatalog.definitions {
            for beat in definition.beats {
                let pages = TVKnowledgeReadingPage.pages(beat: beat, definition: definition)
                XCTAssertEqual(Set(pages.map(\.id)).count, pages.count)
                XCTAssertTrue(pages.allSatisfy { $0.text.split(whereSeparator: \.isWhitespace).count <= 55 })
                let original = ChapterKnowledgeTeachingPage.pages(beat: beat, definition: definition)
                XCTAssertEqual(pages.flatMap { $0.text.split(whereSeparator: \.isWhitespace).map(String.init) },
                    original.flatMap { $0.text.split(whereSeparator: \.isWhitespace).map(String.init) })
                XCTAssertEqual(Set(pages.compactMap { $0.claim?.id }), Set(beat.claimIDs))
            }
        }
    }

    func testLegacyCheckpointDecodesWithoutNewStableOrPracticeFields() throws {
        var point = TVActivityCheckpoint()
        point.storyBeatIndex = 1
        point.completedActivityIDs = ["story-beat-0", "recall"]
        point.timelineCheckpoint = TVTimelineCheckpoint()
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(point)) as? [String: Any])
        legacy.removeValue(forKey: "storyBeatID")
        legacy.removeValue(forKey: "knowledgePracticePending")
        let restored = try JSONDecoder().decode(TVActivityCheckpoint.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(restored, point)
        let definition = ChapterKnowledgeCatalog.definitions[0]
        XCTAssertEqual(ChapterStoryBeatMigration.resolve(sceneID: definition.sceneID, persistedBeatID: nil,
            legacyIndex: restored.storyBeatIndex, availableBeatIDs: definition.beats.map(\.id)).beatID, definition.sceneID + "-memory")
    }

    func testRealFamilyChoiceReceiptPreservesContinuationAndNeverClaimsLaterRecall() throws {
        let suite = "gob.tv.knowledge.receipts." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let definition = ChapterKnowledgeCatalog.definitions[0]
        let continuation = LessonResumePoint(sceneID: definition.sceneID, phase: .place, revealedHintLevel: 2,
                                            selectedMatchTileID: "tile")
        XCTAssertTrue(store.saveResumePointConfirmed(continuation))
        let hooks = ChapterKnowledgeAdapters.hooks(store: store, definitions: ChapterKnowledgeCatalog.definitions)
        var archive = hooks.load()
        for beat in definition.beats {
            archive = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(ChapterKnowledgeJourney.presentedBeat(beat.id,
                visibleClaimIDs: Set(beat.claimIDs), sessionID: continuation.sessionID, archive: archive,
                definition: definition, now: Date()), hooks: hooks))
        }
        archive = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: continuation.sessionID,
                                                context: .sharedFamilyRecognition)
        archive = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: archive, definition: definition)
        archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: Date())
        let event = try XCTUnwrap(archive.pendingEvidence.first)
        archive = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(archive, hooks: hooks))
        XCTAssertTrue(archive.pendingEvidence.isEmpty)
        let reopened = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(reopened.resumePoint(for: definition.sceneID), continuation)
        let evidence = try XCTUnwrap(reopened.masteryRecord(for: definition.sceneID)?.evidenceLog.first { $0.eventID == event.id })
        XCTAssertEqual(evidence.promptType, .recognitionChoice)
        XCTAssertEqual(evidence.participation, .sharedFamilyRecognition)
        XCTAssertEqual(evidence.reviewKind, .freshChecked)
        XCTAssertFalse(ChapterLearningSummary(record: reopened.masteryRecord(for: definition.sceneID)).laterCardRecall)
        XCTAssertEqual(reopened.masteryRecord(for: definition.sceneID)?.state, .understood)
        XCTAssertTrue(reopened.persistenceDiagnostics.isWithinBudget)
    }
}
