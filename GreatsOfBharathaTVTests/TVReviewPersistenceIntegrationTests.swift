import XCTest
@testable import GreatsOfBharathaTV

@MainActor
final class TVReviewPersistenceIntegrationTests: XCTestCase {
    private func store() throws -> ShivajiLessonStore {
        let suite = "gob.tv.review.integration." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
    }

    func testAuthoredFamilyChoiceNeedsDurableOutboxAndRetainsFamilyProvenance() throws {
        let store = try store()
        let card = try XCTUnwrap(TVReviewJourneyContent.cards.first { !$0.review.checkPrompts.isEmpty })
        let choice = try XCTUnwrap(card.choices.first(where: \.isCorrect))
        let now = Date()
        store.recordLearningOutcome(subjectID: card.review.sceneID, activity: .recall,
            wasSuccessful: true, sessionID: UUID())
        let originalChapter = LessonResumePoint(sceneID: card.review.sceneID, phase: .place,
            solvedPlaceIDs: ["place-shivneri"])
        store.saveResumePoint(originalChapter)
        let hooks = LearningActivityAdapters.reviewHooks(store: store)
        let started = TVReviewJourneyAdapter.start(archive: ReviewJourneyArchive(), cards: [card],
            learnedSceneIDs: [card.review.sceneID], sceneSchedules: [:], now: now)
        let selected = TVReviewJourneyAdapter.select(choice.id, in: started, card: card)
        XCTAssertTrue(selected.pendingEvidence.isEmpty)
        let checked = TVReviewJourneyAdapter.check(selected, card: card, now: now)
        let event = try XCTUnwrap(checked.pendingEvidence.first)
        XCTAssertFalse(hooks.record(event), "An in-memory choice cannot award learning evidence")
        let saved = try XCTUnwrap(ReviewJourneyPersistence.saveAndReplay(checked, hooks: hooks))
        XCTAssertTrue(saved.pendingEvidence.isEmpty)
        XCTAssertEqual(store.resumePoint(for: card.review.sceneID), originalChapter)
        let evidence = try XCTUnwrap(store.masteryRecord(for: card.review.sceneID)?.evidenceLog.last)
        XCTAssertEqual(evidence.participation, .sharedFamilyRecognition)
        XCTAssertEqual(evidence.reviewKind, .freshChecked)
        XCTAssertEqual(evidence.cardID, card.id)
        XCTAssertFalse(ChapterLearningSummary(record: store.masteryRecord(for: card.review.sceneID)).laterCardRecall)
        XCTAssertTrue(saved.independentWitnessesByCardID.isEmpty)
        XCTAssertEqual(saved.checkpoint?.typedAnswer, "")
        XCTAssertTrue(hooks.save(checked))
        XCTAssertTrue(hooks.record(event), "A replayed durable ID must acknowledge without a second award")
        XCTAssertEqual(store.masteryRecord(for: card.review.sceneID)?.evidenceLog.filter { $0.eventID == event.id }.count, 1)
    }

    func testDurablySavedUnknownChoiceCannotBeAcknowledged() throws {
        let store = try store()
        let card = try XCTUnwrap(TVReviewJourneyContent.cards.first { !$0.review.checkPrompts.isEmpty })
        let choice = try XCTUnwrap(card.choices.first(where: \.isCorrect))
        store.recordLearningOutcome(subjectID: card.review.sceneID, activity: .recall, wasSuccessful: true, sessionID: UUID())
        let started = TVReviewJourneyAdapter.start(archive: ReviewJourneyArchive(), cards: [card],
            learnedSceneIDs: [card.review.sceneID], sceneSchedules: [:], now: Date())
        var checked = TVReviewJourneyAdapter.check(TVReviewJourneyAdapter.select(choice.id, in: started, card: card), card: card, now: Date())
        var invalid = try XCTUnwrap(checked.pendingEvidence.first)
        invalid.selectedChoiceID = "unrecognized-choice"
        checked.pendingEvidence = [invalid]
        checked.checkpoint?.evidence = [invalid]
        let hooks = LearningActivityAdapters.reviewHooks(store: store)
        XCTAssertTrue(hooks.save(checked))
        XCTAssertFalse(hooks.record(invalid))
        XCTAssertFalse(store.hasRecordedLearningEvent(invalid.id))
        XCTAssertEqual(hooks.load().pendingEvidence, [invalid])
    }
}
