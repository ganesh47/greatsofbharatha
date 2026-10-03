import XCTest
@testable import Greats_Of_Bharatha

@MainActor
final class LearningActivityAdaptersTests: XCTestCase {
    private func store() throws -> ShivajiLessonStore {
        let suite = "gob.adapters." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
    }

    func testTimelineRejectsUnsavedOrLockedReceiptThenAcknowledgesOneDurablePlacement() throws {
        let store = try store()
        let content = SampleContent.shivajiVerticalSlice
        let round = try XCTUnwrap(TimelineActivityCatalog.allRounds(events: content.activeHeroArc.timelineEvents).first)
        var point = TimelineActivityCheckpoint()
        TimelineActivityEngine.begin(round: round, checkpoint: &point)
        TimelineActivityEngine.select(cardID: round.cards[0].id, round: round, checkpoint: &point)
        let check = try XCTUnwrap(TimelineActivityEngine.place(slotIndex: 0, round: round, checkpoint: &point))
        XCTAssertFalse(LearningActivityAdapters.recordTimeline(check, store: store, content: content))
        XCTAssertTrue(LearningActivityAdapters.saveTimeline(point, store: store))
        XCTAssertFalse(LearningActivityAdapters.recordTimeline(check, store: store, content: content))
        for scene in content.scenes.prefix(3) {
            store.recordLearningOutcome(subjectID: scene.id, activity: .recall, wasSuccessful: true, sessionID: UUID())
        }
        XCTAssertTrue(LearningActivityAdapters.recordTimeline(check, store: store, content: content))
        XCTAssertTrue(LearningActivityAdapters.recordTimeline(check, store: store, content: content))
        XCTAssertEqual(store.masteryRecord(for: check.eventSubjectID)?.successfulReviewCount, 1)
        XCTAssertEqual(store.masteryRecord(for: check.eventSubjectID)?.evidenceLog.last?.activity, .timelinePlacement)
    }

    func testSelfReportOutboxPreservesChapterAndDoesNotAwardLaterRecall() throws {
        let store = try store()
        let card = try XCTUnwrap(LearnQuizPilotData.reviewCards.first)
        store.recordLearningOutcome(subjectID: card.sceneID, activity: .recall, wasSuccessful: true, sessionID: UUID())
        let chapter = LessonResumePoint(sceneID: card.sceneID, phase: .place, solvedPlaceIDs: ["place-shivneri"])
        store.saveResumePoint(chapter)
        let hooks = LearningActivityAdapters.reviewHooks(store: store)
        let turn = ReviewJourneyTurn(cardID: card.id)
        var point = ReviewJourneyCheckpoint(sessionID: UUID(), startedAt: Date(), queue: [turn])
        let event = ReviewJourneyEvidence(id: turn.id, sessionID: point.sessionID, cardID: card.id,
            sceneID: card.sceneID, promptType: card.promptType, checkedPromptID: nil, kind: .selfReported,
            support: .selfReported, wasSuccessful: false, response: .knewIt, recordedAt: Date())
        point.evidence = [event]
        point.phase = .result
        var archive = ReviewJourneyArchive()
        archive.checkpoint = point
        archive.pendingEvidence = [event]
        XCTAssertFalse(hooks.record(event))
        let saved = try XCTUnwrap(ReviewJourneyPersistence.saveAndReplay(archive, hooks: hooks))
        XCTAssertTrue(saved.pendingEvidence.isEmpty)
        XCTAssertEqual(store.resumePoint(for: card.sceneID), chapter)
        XCTAssertEqual(store.mastery(for: card.sceneID), .understood)
        let evidence = try XCTUnwrap(store.masteryRecord(for: card.sceneID)?.evidenceLog.last)
        XCTAssertEqual(evidence.type, .selfReportedReview)
        XCTAssertEqual(evidence.cardID, card.id)
        XCTAssertFalse(ChapterLearningSummary(record: store.masteryRecord(for: card.sceneID)).laterCardRecall)
    }

    func testParentSummarySeparatesHelpReportAndLegacyUnknownSupport() {
        let record = MasteryRecord(subjectID: "scene-1-shivneri", subjectType: .scene, state: .understood,
            exposureCount: 1, successfulReviewCount: 1, lastReviewedAt: nil, evidenceLog: [
                MasteryEvidence(type: .recallSuccess, recordedAt: Date(), detail: "Imported; support unknown"),
                MasteryEvidence(type: .recallSuccess, recordedAt: Date(), detail: "Clue used", support: .hinted),
                MasteryEvidence(type: .selfReportedReview, recordedAt: Date(), detail: "Memory report", support: .selfReported)
            ])
        let summary = ChapterLearningSummary(record: record)
        XCTAssertTrue(summary.explored)
        XCTAssertTrue(summary.checkedWithHelp)
        XCTAssertTrue(summary.selfReported)
        XCTAssertFalse(summary.checkedWithoutClue)
        XCTAssertFalse(summary.laterCardRecall)
    }
}
