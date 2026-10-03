import XCTest
@testable import GreatsOfBharathaTV

@MainActor
final class TVChapterKnowledgeTests: XCTestCase {
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
