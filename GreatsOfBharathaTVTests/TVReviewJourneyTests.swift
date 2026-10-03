import XCTest
@testable import GreatsOfBharathaTV

final class TVReviewJourneyTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var card: TVReviewJourneyCard {
        let review = ReviewJourneyCard(id: "synthetic-card", sceneID: "synthetic-scene", promptType: .openPrompt,
            front: "Synthetic question", back: "Synthetic answer", meaning: "Synthetic meaning", checkPrompts: [
                ReviewJourneyCheckPrompt(id: "synthetic-prompt-one", text: "First synthetic question", promptType: .openPrompt, acceptedAnswers: ["Synthetic answer"]),
                ReviewJourneyCheckPrompt(id: "synthetic-prompt-two", text: "Second synthetic question", promptType: .compareFromMemory, acceptedAnswers: ["Synthetic answer"])
            ], cadenceDays: [0, 1, 3, 7, 14])
        return TVReviewJourneyCard(review: review, sceneTitle: "Synthetic chapter", choices: [
            AuthoredLessonChoice(id: "synthetic-right", title: "Synthetic answer", isCorrect: true),
            AuthoredLessonChoice(id: "synthetic-other", title: "Another answer", isCorrect: false)
        ], teaching: "Synthetic teaching", clue: "Synthetic clue")
    }
    private func start(_ archive: ReviewJourneyArchive = ReviewJourneyArchive(), date: Date? = nil) -> ReviewJourneyArchive {
        TVReviewJourneyAdapter.start(archive: archive, cards: [card], learnedSceneIDs: [card.review.sceneID],
            sceneSchedules: [:], now: date ?? now)
    }
    private func selected(_ archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        TVReviewJourneyAdapter.select("synthetic-right", in: archive, card: card)
    }

    func testRemoteSelectionAloneDoesNotCheckOrEmitEvidence() {
        let original = start()
        let next = selected(original)
        XCTAssertEqual(next.checkpoint?.phase, .prompt)
        XCTAssertEqual(next.checkpoint?.selectedChoiceID, "synthetic-right")
        XCTAssertEqual(next.checkpoint?.typedAnswer, "")
        XCTAssertTrue(next.pendingEvidence.isEmpty)
        XCTAssertEqual(next.schedulesByCardID, original.schedulesByCardID)
        XCTAssertEqual(TVReviewJourneyAdapter.select("unknown", in: next, card: card), next)
    }

    func testCheckRequiresAnExplicitSelection() {
        let original = start()
        XCTAssertEqual(TVReviewJourneyAdapter.check(original, card: card, now: now), original)
    }

    func testNoClueFamilyRecognitionIsFreshCheckedButNeverIndependentRecall() throws {
        let checked = TVReviewJourneyAdapter.check(selected(start()), card: card, now: now)
        let event = try XCTUnwrap(checked.checkpoint?.currentEvidence)
        XCTAssertEqual(event.kind, .freshChecked)
        XCTAssertEqual(event.support, .independent)
        XCTAssertEqual(event.responseContext, .sharedFamilyRecognition)
        XCTAssertEqual(event.selectedChoiceID, "synthetic-right")
        XCTAssertTrue(event.wasSuccessful)
        XCTAssertFalse(event.hasValidLaterIndependentWitness)
        XCTAssertTrue(checked.independentWitnessesByCardID.isEmpty)
        XCTAssertNil(checked.checkpoint?.selectedChoiceID)
        XCTAssertEqual(checked.checkpoint?.typedAnswer, "")
    }

    func testFamilyChoiceCannotBorrowOlderIndividualWitnessToClaimLaterRecall() {
        var archive = ReviewJourneyArchive()
        let old = ReviewJourneyRecallWitness(sessionID: UUID(), recordedAt: now.addingTimeInterval(-86400), promptID: "synthetic-prompt-one")
        archive.independentWitnessesByCardID[card.id] = old
        let checked = TVReviewJourneyAdapter.check(selected(start(archive)), card: card, now: now)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .freshChecked)
        XCTAssertEqual(checked.independentWitnessesByCardID[card.id], old)
        XCTAssertNil(checked.checkpoint?.currentEvidence?.priorIndependentWitness)
    }

    func testClueStaysStickyThroughSelectionAndIsSeparateFromFamilyCaption() {
        let helped = TVReviewJourneyAdapter.requestHelp(start())
        XCTAssertEqual(helped.checkpoint?.helpWasRequested, true)
        XCTAssertEqual(helped.checkpoint?.sharedFamilyResponse, true)
        XCTAssertTrue(helped.pendingEvidence.isEmpty)
        let checked = TVReviewJourneyAdapter.check(selected(helped), card: card, now: now)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .helpedChecked)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.support, .hinted)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.responseContext, .sharedFamilyRecognition)
        XCTAssertTrue(checked.independentWitnessesByCardID.isEmpty)
        XCTAssertEqual(checked.schedulesByCardID[card.id]?.nextDueAt, now.addingTimeInterval(4 * 3600))
    }

    func testWrongRemoteChoiceDoesNotCreateSuccessOrExtendDueInterval() {
        let original = start()
        let wrong = TVReviewJourneyAdapter.select("synthetic-other", in: original, card: card)
        let checked = TVReviewJourneyAdapter.check(wrong, card: card, now: now)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .incorrectChecked)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.wasSuccessful, false)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.selectedChoiceID, "synthetic-other")
        XCTAssertTrue(checked.independentWitnessesByCardID.isEmpty)
        XCTAssertEqual(checked.schedulesByCardID[card.id]?.intervalIndex, 0)
        XCTAssertEqual(checked.schedulesByCardID[card.id]?.nextDueAt, now)
    }

    func testSelfReportNeverCountsAsCheckedFamilyChoice() {
        let revealed = ReviewJourneyEngine.reveal(selected(start()))
        let reported = ReviewJourneyEngine.selfReport(.knewIt, archive: revealed, card: card.review, now: now)
        XCTAssertEqual(reported.checkpoint?.currentEvidence?.kind, .selfReported)
        XCTAssertEqual(reported.checkpoint?.currentEvidence?.support, .selfReported)
        XCTAssertEqual(reported.checkpoint?.currentEvidence?.wasSuccessful, false)
        XCTAssertEqual(reported.checkpoint?.currentEvidence?.responseContext, .sharedFamilyRecognition)
        XCTAssertNil(reported.checkpoint?.currentEvidence?.selectedChoiceID)
        XCTAssertTrue(reported.independentWitnessesByCardID.isEmpty)
    }

    func testFamilyPromptRotatesAfterAcknowledgementWithoutAnIndividualWitness() throws {
        let first = TVReviewJourneyAdapter.check(selected(start()), card: card, now: now)
        let priorPromptID = try XCTUnwrap(first.checkpoint?.currentEvidence?.checkedPromptID)
        let acknowledged = first.pendingEvidence.reduce(first) { ReviewJourneyEngine.acknowledge($1.id, in: $0) }
        let next = start(acknowledged, date: now.addingTimeInterval(86400))
        XCTAssertNotEqual(next.checkpoint?.currentTurn?.checkedPromptID, priorPromptID)
        XCTAssertTrue(next.independentWitnessesByCardID.isEmpty)
        let checked = TVReviewJourneyAdapter.check(selected(next), card: card, now: now.addingTimeInterval(86400))
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .freshChecked)
        XCTAssertNil(checked.checkpoint?.currentEvidence?.priorIndependentWitness)
    }

    func testTeachingRequeuesOnceAndRemoteRevisitIsRescued() {
        var archive = ReviewJourneyEngine.selfReport(.teachAgain, archive: ReviewJourneyEngine.reveal(start()), card: card.review, now: now)
        archive = ReviewJourneyEngine.continueAfterResult(archive)
        XCTAssertEqual(archive.checkpoint?.phase, .teaching)
        archive = ReviewJourneyEngine.finishTeaching(archive, card: card.review, now: now)
        XCTAssertEqual(archive.checkpoint?.queue.count, 2)
        XCTAssertEqual(archive.checkpoint?.currentTurn?.isTaughtRevisit, true)
        XCTAssertEqual(archive.checkpoint?.sharedFamilyResponse, true)
        let checked = TVReviewJourneyAdapter.check(selected(archive), card: card, now: now)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.support, .rescued)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .helpedChecked)
        XCTAssertTrue(checked.independentWitnessesByCardID.isEmpty)
        let completed = ReviewJourneyEngine.continueAfterResult(checked)
        XCTAssertEqual(completed.checkpoint?.phase, .complete)
        XCTAssertEqual(completed.checkpoint?.queue.count, 2)
    }

    func testSelectionAndHelpResumeWithoutRequiringTextOrPhone() throws {
        let original = selected(TVReviewJourneyAdapter.requestHelp(start()))
        let decoded = try JSONDecoder().decode(ReviewJourneyArchive.self, from: JSONEncoder().encode(original))
        let resumed = TVReviewJourneyAdapter.resume(decoded, cards: [card], learnedSceneIDs: [card.review.sceneID])
        XCTAssertEqual(resumed.checkpoint?.selectedChoiceID, "synthetic-right")
        XCTAssertEqual(resumed.checkpoint?.helpWasRequested, true)
        XCTAssertEqual(resumed.checkpoint?.sharedFamilyResponse, true)
        XCTAssertEqual(resumed.checkpoint?.currentTurn?.id, original.checkpoint?.currentTurn?.id)
        XCTAssertEqual(resumed.checkpoint?.typedAnswer, "")
        XCTAssertTrue(resumed.pendingEvidence.isEmpty)
    }

    func testUnknownResumedSelectionIsClearedBeforeCheck() {
        var original = start()
        original.checkpoint?.selectedChoiceID = "unknown"
        let resumed = TVReviewJourneyAdapter.resume(original, cards: [card], learnedSceneIDs: [card.review.sceneID])
        XCTAssertNil(resumed.checkpoint?.selectedChoiceID)
        XCTAssertEqual(TVReviewJourneyAdapter.check(resumed, card: card, now: now), resumed)
    }

    func testChoicesMustMatchAuthoredCorrectFlagAndHaveUniqueLabels() throws {
        let prompt = try XCTUnwrap(card.review.checkPrompts.first)
        XCTAssertTrue(TVReviewJourneyAdapter.validChoices(card.choices, for: prompt))
        XCTAssertFalse(TVReviewJourneyAdapter.validChoices([AuthoredLessonChoice(id: "one", title: "Synthetic answer", isCorrect: false),
            AuthoredLessonChoice(id: "two", title: "Another answer", isCorrect: true)], for: prompt))
        XCTAssertFalse(TVReviewJourneyAdapter.validChoices([AuthoredLessonChoice(id: "one", title: "Synthetic answer", isCorrect: true),
            AuthoredLessonChoice(id: "two", title: "Synthetic ANSWER", isCorrect: false)], for: prompt))
    }

    @MainActor
    func testCallbackFailureAndRelaunchCannotStartANewFamilySessionBeforeAcknowledgement() throws {
        let proposed = TVReviewJourneyAdapter.check(selected(start()), card: card, now: now)
        var durable = ReviewJourneyArchive()
        var shouldReject = true
        var recordedIDs: Set<UUID> = []
        let hooks = ReviewJourneyHooks(load: { durable }, save: { durable = $0; return true }, record: { event in
            if shouldReject { return false }
            recordedIDs.insert(event.id)
            return true
        })
        let saved = try XCTUnwrap(ReviewJourneyPersistence.saveAndReplay(proposed, hooks: hooks))
        XCTAssertEqual(saved.pendingEvidence.count, 1)
        let relaunched = try JSONDecoder().decode(ReviewJourneyArchive.self, from: JSONEncoder().encode(hooks.load()))
        let attemptedStart = start(relaunched, date: now.addingTimeInterval(86400))
        XCTAssertEqual(attemptedStart.checkpoint, relaunched.checkpoint)
        XCTAssertEqual(attemptedStart.pendingEvidence, relaunched.pendingEvidence)
        shouldReject = false
        let replayed = try XCTUnwrap(ReviewJourneyPersistence.saveAndReplay(relaunched, hooks: hooks))
        XCTAssertTrue(replayed.pendingEvidence.isEmpty)
        XCTAssertEqual(recordedIDs, Set(proposed.pendingEvidence.map(\.id)))
        XCTAssertEqual(TVReviewJourneyAdapter.check(replayed, card: card, now: now), replayed)
    }

#if os(tvOS)
    func testProductionTVReviewOnlyUsesExistingAuthoredChoicesAndCanonicalSubjects() throws {
        let sourceCards = LearnQuizPilotData.reviewCards
        XCTAssertEqual(TVReviewJourneyContent.cards.map(\.id), sourceCards.map(\.id))
        for card in TVReviewJourneyContent.cards {
            let chapter = try XCTUnwrap(TVLearningContent.chapter(sceneID: card.review.sceneID))
            XCTAssertEqual(card.review.back, sourceCards.first { $0.id == card.id }?.back)
            XCTAssertEqual(card.teaching, chapter.storyBeats.map(\.text).joined(separator: "\n\n"))
            for prompt in card.review.checkPrompts {
                XCTAssertEqual(card.choices, chapter.plan.choices)
                XCTAssertEqual(prompt.acceptedAnswers, chapter.pilot.quiz.challenge.correctAnswers)
                XCTAssertTrue(TVReviewJourneyAdapter.validChoices(card.choices, for: prompt))
                let authoredIDs = Set(chapter.pilot.reviewCards.map(\.id) + [chapter.pilot.quiz.challenge.id])
                XCTAssertTrue(authoredIDs.contains(prompt.id))
            }
        }
        let eligibleScenes = Set(TVReviewJourneyContent.cards.filter { !$0.review.checkPrompts.isEmpty }.map { $0.review.sceneID })
        XCTAssertEqual(eligibleScenes, Set(TVLearningContent.chapters.map(\.id)))
    }
#endif
}
