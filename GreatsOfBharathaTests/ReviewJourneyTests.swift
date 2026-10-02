import XCTest
@testable import Greats_Of_Bharatha

final class ReviewJourneyTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }
    private func card(_ id: String = "card-a", sceneID: String = "scene-a") -> ReviewJourneyCard {
        ReviewJourneyCard(id: id, sceneID: sceneID, promptType: .openPrompt, front: "Synthetic question",
                          back: "Synthetic answer", meaning: "Synthetic teaching", checkPrompts: [
                            ReviewJourneyCheckPrompt(id: "synthetic-first", text: "First synthetic recall", promptType: .openPrompt, acceptedAnswers: ["Synthetic answer"]),
                            ReviewJourneyCheckPrompt(id: "synthetic-second", text: "Second synthetic recall", promptType: .compareFromMemory, acceptedAnswers: ["Synthetic answer"])
                          ], cadenceDays: [0, 1, 3, 7, 14])
    }
    private func schedule(_ due: Date, sceneID: String = "scene-a") -> ReviewSchedule {
        ReviewSchedule(subjectID: sceneID, subjectType: .scene, nextDueAt: due, intervalIndex: 0,
                       stabilityBand: .new, difficultyAdjustment: 0, cadenceDays: [0, 1, 3, 7, 14])
    }
    private func start(_ cards: [ReviewJourneyCard] = [], archive: ReviewJourneyArchive = ReviewJourneyArchive(),
                       sessionID: UUID = UUID(), date: Date? = nil) -> ReviewJourneyArchive {
        let selected = cards.isEmpty ? [card()] : cards
        return ReviewJourneyEngine.start(archive: archive, cards: selected, learnedSceneIDs: Set(selected.map(\.sceneID)),
            sceneSchedules: [:], sessionID: sessionID, now: date ?? now)
    }
    private func correct(_ archive: ReviewJourneyArchive, card: ReviewJourneyCard? = nil, date: Date? = nil) -> ReviewJourneyArchive {
        let descriptor = card ?? self.card()
        return ReviewJourneyEngine.check(ReviewJourneyEngine.updateAnswer(" Synthetic ANSWER! ", in: archive),
                                         card: descriptor, now: date ?? now, calendar: utc)
    }
    private func report(_ response: LearningReviewResponse, in archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        ReviewJourneyEngine.selfReport(response, archive: ReviewJourneyEngine.reveal(archive), card: card(), now: now, calendar: utc)
    }

    func testDueQueueUsesStableCardOrderingAndExcludesUnlearnedAndFutureCards() {
        var archive = ReviewJourneyArchive()
        archive.schedulesByCardID = ["card-b": schedule(now), "card-a": schedule(now),
            "older": schedule(now.addingTimeInterval(-10)), "future": schedule(now.addingTimeInterval(10))]
        let cards = [card("card-b"), card("future"), card("card-a"), card("older"), card("unlearned", sceneID: "scene-new"), card("card-a")]
        let next = ReviewJourneyEngine.start(archive: archive, cards: cards, learnedSceneIDs: ["scene-a"], sceneSchedules: [:], now: now)
        XCTAssertEqual(next.checkpoint?.queue.map(\.cardID), ["older", "card-a", "card-b"])
        XCTAssertNil(next.schedulesByCardID["unlearned"])
    }

    func testEmptyQueueCompletesAndDoesNotManufactureEvidence() {
        let archive = ReviewJourneyEngine.start(archive: ReviewJourneyArchive(), cards: [card()], learnedSceneIDs: [], sceneSchedules: [:], now: now)
        XCTAssertEqual(archive.checkpoint?.phase, .complete)
        XCTAssertEqual(archive.checkpoint?.queue, [])
        XCTAssertTrue(archive.pendingEvidence.isEmpty)
    }

    func testFutureOnlyQueueCanBePractisedExplicitlyAndPreservesCardCadence() {
        var archive = ReviewJourneyArchive()
        archive.schedulesByCardID["card-a"] = schedule(now.addingTimeInterval(3600))
        let due = start(archive: archive)
        XCTAssertEqual(due.checkpoint?.phase, .complete)
        let practice = ReviewJourneyEngine.start(archive: due, cards: [card()], learnedSceneIDs: ["scene-a"], sceneSchedules: [:], selection: .practiceLearned, now: now)
        XCTAssertEqual(practice.checkpoint?.queue.count, 1)
        XCTAssertEqual(practice.schedulesByCardID, archive.schedulesByCardID)
    }

    func testSceneDueSeedsCardOnceWithoutMergingDifferentCards() {
        let cards = [card("one"), card("two")]
        var archive = ReviewJourneyEngine.start(archive: ReviewJourneyArchive(), cards: cards, learnedSceneIDs: ["scene-a"],
            sceneSchedules: ["scene-a": schedule(now.addingTimeInterval(-3600))], now: now)
        archive.schedulesByCardID["one"]?.nextDueAt = now.addingTimeInterval(86400)
        let restarted = ReviewJourneyEngine.start(archive: archive, cards: cards, learnedSceneIDs: ["scene-a"], sceneSchedules: [:], now: now)
        XCTAssertEqual(restarted.checkpoint?.queue.map(\.cardID), ["two"])
        XCTAssertEqual(restarted.schedulesByCardID["one"]?.nextDueAt, now.addingTimeInterval(86400))
    }

    func testKnewItIsOnlySelfReportAndDoesNotCreateIndependentRecallWitness() {
        let result = report(.knewIt, in: start())
        XCTAssertEqual(result.checkpoint?.currentEvidence?.kind, .selfReported)
        XCTAssertEqual(result.checkpoint?.currentEvidence?.support, .selfReported)
        XCTAssertEqual(result.checkpoint?.currentEvidence?.wasSuccessful, false)
        XCTAssertTrue(result.independentWitnessesByCardID.isEmpty)
        XCTAssertEqual(result.schedulesByCardID["card-a"]?.nextDueAt, utc.date(byAdding: .day, value: 1, to: now))
    }

    func testNeededClueRevisitsAfterFourHoursNotImmediately() {
        let result = report(.neededClue, in: start())
        XCTAssertEqual(result.schedulesByCardID["card-a"]?.nextDueAt, now.addingTimeInterval(4 * 3600))
        let beforeDue = start(archive: result, date: now.addingTimeInterval(4 * 3600 - 1))
        XCTAssertEqual(beforeDue.checkpoint?.phase, .complete)
        let atDue = start(archive: result, date: now.addingTimeInterval(4 * 3600))
        XCTAssertEqual(atDue.checkpoint?.queue.count, 1)
    }

    func testTeachAgainRequiresActualTeachingThenRequeuesBehindOtherCardsOnce() {
        let original = start([card(), card("card-b")])
        let result = report(.teachAgain, in: original)
        XCTAssertEqual(result.schedulesByCardID["card-a"]?.nextDueAt, now)
        XCTAssertEqual(result.checkpoint?.queue.count, 2)
        let teaching = ReviewJourneyEngine.continueAfterResult(result)
        XCTAssertEqual(teaching.checkpoint?.phase, .teaching)
        let next = ReviewJourneyEngine.finishTeaching(teaching, card: card(), now: now)
        XCTAssertEqual(next.checkpoint?.queue.map(\.cardID), ["card-a", "card-b", "card-a"])
        XCTAssertEqual(next.checkpoint?.currentTurn?.cardID, "card-b")
        XCTAssertEqual(next.pendingEvidence.last?.kind, .reteachingExposure)
        XCTAssertEqual(next.pendingEvidence.last?.wasSuccessful, false)
        XCTAssertEqual(ReviewJourneyEngine.finishTeaching(next, card: card(), now: now), next)
    }

    func testTaughtRevisitIsHelpedEvenWhenAnswerMatchesBeforeReveal() {
        let result = report(.teachAgain, in: start())
        let teaching = ReviewJourneyEngine.continueAfterResult(result)
        let revisit = ReviewJourneyEngine.finishTeaching(teaching, card: card(), now: now)
        let checked = correct(revisit, date: now.addingTimeInterval(20))
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .helpedChecked)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.support, .rescued)
        XCTAssertTrue(checked.independentWitnessesByCardID.isEmpty)
        XCTAssertEqual(checked.schedulesByCardID["card-a"]?.nextDueAt, now.addingTimeInterval(20 + 4 * 3600))
    }

    func testRepeatedTeachAgainCompletesBoundedQueueWithoutEndlessReteaching() {
        var archive = report(.teachAgain, in: start())
        archive = ReviewJourneyEngine.finishTeaching(ReviewJourneyEngine.continueAfterResult(archive), card: card(), now: now)
        archive = report(.teachAgain, in: archive)
        archive = ReviewJourneyEngine.finishTeaching(ReviewJourneyEngine.continueAfterResult(archive), card: card(), now: now)
        XCTAssertEqual(archive.checkpoint?.queue.count, 2)
        XCTAssertEqual(archive.checkpoint?.phase, .complete)
        XCTAssertEqual(archive.checkpoint?.requeuedCardIDs, ["card-a"])
        XCTAssertEqual(archive.schedulesByCardID["card-a"]?.nextDueAt, now)
    }

    func testBlankAndWrongAnswersCannotCreateRecallSuccess() {
        let original = start()
        XCTAssertEqual(ReviewJourneyEngine.check(original, card: card(), now: now), original)
        let wrong = ReviewJourneyEngine.check(ReviewJourneyEngine.updateAnswer("Other answer", in: original), card: card(), now: now)
        XCTAssertEqual(wrong.checkpoint?.currentEvidence?.kind, .incorrectChecked)
        XCTAssertEqual(wrong.checkpoint?.currentEvidence?.wasSuccessful, false)
        XCTAssertTrue(wrong.independentWitnessesByCardID.isEmpty)
        XCTAssertEqual(ReviewJourneyEngine.continueAfterResult(wrong).checkpoint?.phase, .teaching)
    }

    func testRevealBlocksAClaimOfCheckedIndependentRetrieval() {
        let revealed = ReviewJourneyEngine.reveal(ReviewJourneyEngine.updateAnswer("Synthetic answer", in: start()))
        XCTAssertEqual(ReviewJourneyEngine.check(revealed, card: card(), now: now), revealed)
        XCTAssertTrue(revealed.pendingEvidence.isEmpty)
    }

    func testFirstCheckedAnswerIsFreshAndUsesExistingDayCadence() {
        let first = correct(start())
        XCTAssertEqual(first.checkpoint?.currentEvidence?.kind, .freshChecked)
        XCTAssertEqual(first.checkpoint?.currentEvidence?.support, .independent)
        XCTAssertEqual(first.schedulesByCardID["card-a"]?.intervalIndex, 1)
        XCTAssertEqual(first.schedulesByCardID["card-a"]?.nextDueAt, now.addingTimeInterval(86400))
        let later = correct(start(archive: first, date: now.addingTimeInterval(86400)), date: now.addingTimeInterval(86400))
        XCTAssertEqual(later.checkpoint?.currentEvidence?.kind, .laterIndependentRecall)
        XCTAssertEqual(later.schedulesByCardID["card-a"]?.intervalIndex, 2)
        XCTAssertEqual(later.schedulesByCardID["card-a"]?.nextDueAt, now.addingTimeInterval(4 * 86400))
    }

    func testCheckedAndSelfReportedResultsDoNotRetainTypedChildAnswer() {
        let typed = ReviewJourneyEngine.updateAnswer("Synthetic answer", in: start())
        XCTAssertEqual(correct(typed).checkpoint?.typedAnswer, "")
        let reported = report(.knewIt, in: typed)
        XCTAssertEqual(reported.checkpoint?.typedAnswer, "")
        XCTAssertEqual(ReviewJourneyEngine.continueAfterResult(reported).checkpoint?.typedAnswer, "")
    }

    func testAnotherSessionWithinFourHoursIsFreshCheckedNotLaterRecall() {
        let first = correct(start())
        let early = ReviewJourneyEngine.start(archive: first, cards: [card()], learnedSceneIDs: ["scene-a"], sceneSchedules: [:], selection: .practiceLearned,
                                             now: now.addingTimeInterval(4 * 3600))
        let checked = correct(early, date: now.addingTimeInterval(4 * 3600))
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .freshChecked)
        XCTAssertEqual(checked.schedulesByCardID, first.schedulesByCardID)
    }

    func testRepeatedOptionalPracticeCannotExtendDueDateOrCreateLaterRecall() {
        var archive = correct(start())
        let originalSchedule = archive.schedulesByCardID
        for offset in 1...6 {
            let date = now.addingTimeInterval(TimeInterval(offset * 60))
            archive = ReviewJourneyEngine.start(archive: archive, cards: [card()], learnedSceneIDs: ["scene-a"], sceneSchedules: [:],
                                               selection: .practiceLearned, now: date)
            archive = correct(archive, date: date)
            XCTAssertEqual(archive.checkpoint?.currentEvidence?.kind, .freshChecked)
            XCTAssertEqual(archive.schedulesByCardID, originalSchedule)
        }
    }

    func testDayCadenceCapsAtFourteenDaysForGenuineLaterRevisits() {
        var archive = start()
        var date = now
        for days in [1, 3, 7, 14, 14] {
            archive = correct(archive, date: date)
            let due = utc.date(byAdding: .day, value: days, to: date)
            XCTAssertEqual(archive.schedulesByCardID["card-a"]?.nextDueAt, due)
            date = due ?? date
            archive = start(archive: archive, date: date)
        }
        XCTAssertEqual(archive.schedulesByCardID["card-a"]?.intervalIndex, 4)
    }

    func testClockRollbackCannotCreateLaterRecallOrAdvanceTheFutureSchedule() {
        let first = correct(start())
        let earlier = now.addingTimeInterval(-86400)
        let restarted = ReviewJourneyEngine.start(archive: first, cards: [card()], learnedSceneIDs: ["scene-a"], sceneSchedules: [:],
                                                 selection: .practiceLearned, now: earlier)
        let checked = correct(restarted, date: earlier)
        XCTAssertEqual(checked.checkpoint?.currentEvidence?.kind, .freshChecked)
        XCTAssertEqual(checked.schedulesByCardID, first.schedulesByCardID)
    }

    func testCheckedRetrievalRotatesAuthoredPromptAndRetainsItsActualType() {
        let first = correct(start())
        XCTAssertEqual(first.checkpoint?.currentEvidence?.checkedPromptID, "synthetic-first")
        let laterDate = now.addingTimeInterval(86400)
        let later = correct(start(archive: first, date: laterDate), date: laterDate)
        XCTAssertEqual(later.checkpoint?.currentEvidence?.checkedPromptID, "synthetic-second")
        XCTAssertEqual(later.checkpoint?.currentEvidence?.promptType, .compareFromMemory)
        XCTAssertEqual(later.checkpoint?.currentEvidence?.kind, .laterIndependentRecall)
    }

    func testSingleAuthoredPromptCannotClaimChangedPromptLaterRecall() {
        let original = card()
        let singlePrompt = ReviewJourneyCard(id: original.id, sceneID: original.sceneID, promptType: original.promptType,
            front: original.front, back: original.back, meaning: original.meaning,
            checkPrompts: Array(original.checkPrompts.prefix(1)), cadenceDays: original.cadenceDays)
        let first = correct(start([singlePrompt]), card: singlePrompt)
        let laterDate = now.addingTimeInterval(86400)
        let later = correct(start([singlePrompt], archive: first, date: laterDate), card: singlePrompt, date: laterDate)
        XCTAssertEqual(later.checkpoint?.currentEvidence?.kind, .freshChecked)
    }

    func testCardWithoutAuthoredCheckPromptSupportsReportButCannotInventRetrieval() {
        let original = card()
        let reportOnly = ReviewJourneyCard(id: original.id, sceneID: original.sceneID, promptType: original.promptType,
            front: original.front, back: original.back, meaning: original.meaning, checkPrompts: [], cadenceDays: original.cadenceDays)
        let archive = ReviewJourneyEngine.updateAnswer("Synthetic answer", in: start([reportOnly]))
        XCTAssertEqual(ReviewJourneyEngine.check(archive, card: reportOnly, now: now), archive)
        let reported = ReviewJourneyEngine.selfReport(.knewIt, archive: ReviewJourneyEngine.reveal(archive), card: reportOnly, now: now)
        XCTAssertEqual(reported.checkpoint?.currentEvidence?.kind, .selfReported)
        XCTAssertNil(reported.checkpoint?.currentEvidence?.checkedPromptID)
        XCTAssertTrue(reported.independentWitnessesByCardID.isEmpty)
    }

    func testQueueAndOutboxHaveExplicitBoundsAndNeverDiscardPendingEvidence() {
        let manyCards = (0..<100).map { card("card-\($0)") }
        var archive = start(manyCards)
        XCTAssertEqual(archive.checkpoint?.queue.count, ReviewJourneyEngine.maximumInitialCards)
        let event = ReviewJourneyEvidence(id: UUID(), sessionID: UUID(), cardID: "card-a", sceneID: "scene-a",
            promptType: .openPrompt, checkedPromptID: nil, kind: .selfReported, support: .selfReported,
            wasSuccessful: false, response: .knewIt, recordedAt: now)
        archive.pendingEvidence = (0..<ReviewJourneyEngine.maximumPendingEvidence).map { _ in
            ReviewJourneyEvidence(id: UUID(), sessionID: event.sessionID, cardID: event.cardID, sceneID: event.sceneID,
                promptType: event.promptType, checkedPromptID: nil, kind: event.kind, support: event.support,
                wasSuccessful: false, response: event.response, recordedAt: now)
        }
        let attempted = ReviewJourneyEngine.start(archive: archive, cards: [card()], learnedSceneIDs: ["scene-a"], sceneSchedules: [:], now: now)
        XCTAssertEqual(attempted, archive)
        let current = try? XCTUnwrap(archive.checkpoint?.currentTurn?.cardID)
        if let current, let descriptor = manyCards.first(where: { $0.id == current }) {
            let typed = ReviewJourneyEngine.updateAnswer("Synthetic answer", in: archive)
            XCTAssertEqual(ReviewJourneyEngine.check(typed, card: descriptor, now: now), typed)
        }
        XCTAssertEqual(archive.pendingEvidence.count, ReviewJourneyEngine.maximumPendingEvidence)
    }

    func testSameSessionAfterOneDayDoesNotBecomeLaterRecallOrAdvanceTwice() {
        let sessionID = UUID()
        let first = correct(start(sessionID: sessionID))
        let repeated = correct(start(archive: first, sessionID: sessionID, date: now.addingTimeInterval(86400)), date: now.addingTimeInterval(86400))
        XCTAssertEqual(repeated.checkpoint?.currentEvidence?.kind, .freshChecked)
        XCTAssertEqual(repeated.schedulesByCardID["card-a"], first.schedulesByCardID["card-a"])
        XCTAssertEqual(repeated.independentWitnessesByCardID["card-a"]?.recordedAt, now)
    }

    func testADifferentCardCannotBorrowAnotherCardsIndependentWitness() {
        let first = correct(start())
        let another = correct(start([card("card-b")], archive: first, date: now.addingTimeInterval(86400)), card: card("card-b"), date: now.addingTimeInterval(86400))
        XCTAssertEqual(another.checkpoint?.currentEvidence?.kind, .freshChecked)
    }

    func testResumeRoundTripRetainsTypedAnswerTurnIdentityAndHelpState() throws {
        var original = ReviewJourneyEngine.updateAnswer("Partial answer", in: start())
        let turnID = original.checkpoint?.currentTurn?.id
        let data = try JSONEncoder().encode(original)
        original = try JSONDecoder().decode(ReviewJourneyArchive.self, from: data)
        let resumed = ReviewJourneyEngine.resume(original, cards: [card()], learnedSceneIDs: ["scene-a"])
        XCTAssertEqual(resumed.checkpoint?.typedAnswer, "Partial answer")
        XCTAssertEqual(resumed.checkpoint?.currentTurn?.id, turnID)
        let revealed = ReviewJourneyEngine.reveal(resumed)
        let revealRoundTrip = try JSONDecoder().decode(ReviewJourneyArchive.self, from: JSONEncoder().encode(revealed))
        XCTAssertEqual(revealRoundTrip.checkpoint?.phase, .revealed)
        XCTAssertEqual(revealRoundTrip.checkpoint?.helped, true)
    }

    func testResumeTeachingAndSavedResultDoNotRepeatEvidence() throws {
        let result = report(.teachAgain, in: start())
        XCTAssertEqual(report(.teachAgain, in: result), result)
        let teaching = ReviewJourneyEngine.continueAfterResult(result)
        let decoded = try JSONDecoder().decode(ReviewJourneyArchive.self, from: JSONEncoder().encode(teaching))
        let next = ReviewJourneyEngine.finishTeaching(decoded, card: card(), now: now)
        XCTAssertEqual(next.pendingEvidence.count, 2)
        XCTAssertEqual(Set(next.pendingEvidence.map(\.id)).count, 2)
        XCTAssertEqual(next.checkpoint?.currentTurn?.isTaughtRevisit, true)
    }

    func testReplayAndAcknowledgeUseStableEventIDs() throws {
        let original = start()
        let checked = correct(original)
        let decoded = try JSONDecoder().decode(ReviewJourneyArchive.self, from: JSONEncoder().encode(checked))
        XCTAssertEqual(correct(decoded), decoded)
        XCTAssertEqual(decoded.pendingEvidence.first?.id, original.checkpoint?.currentTurn?.id)
        let eventID = try XCTUnwrap(decoded.pendingEvidence.first?.id)
        let acknowledged = ReviewJourneyEngine.acknowledge(eventID, in: decoded)
        XCTAssertTrue(acknowledged.pendingEvidence.isEmpty)
        XCTAssertEqual(ReviewJourneyEngine.acknowledge(eventID, in: acknowledged), acknowledged)
        XCTAssertEqual(acknowledged.checkpoint?.currentEvidence?.id, eventID)
    }

    func testRemovedOrUnlearnedCardsAreSkippedOnResume() {
        let original = start([card(), card("card-b", sceneID: "scene-b")])
        let resumed = ReviewJourneyEngine.resume(original, cards: [card("card-b", sceneID: "scene-b")], learnedSceneIDs: ["scene-b"])
        XCTAssertEqual(resumed.checkpoint?.currentTurn?.cardID, "card-b")
        let empty = ReviewJourneyEngine.resume(resumed, cards: [], learnedSceneIDs: [])
        XCTAssertEqual(empty.checkpoint?.phase, .complete)
        XCTAssertTrue(empty.pendingEvidence.isEmpty)
    }

    @MainActor
    func testFailedArchiveSaveDoesNotEmitEvidenceAndCanRetryTheSameEvent() {
        let proposed = correct(start())
        var savedArchive: ReviewJourneyArchive?
        var shouldFail = true
        var emitted: [UUID] = []
        let hooks = ReviewJourneyHooks(load: { savedArchive ?? ReviewJourneyArchive() }, save: { archive in
            if shouldFail { return false }
            savedArchive = archive
            return true
        }, record: { event in emitted.append(event.id); return true })
        XCTAssertNil(ReviewJourneyPersistence.saveAndReplay(proposed, hooks: hooks))
        XCTAssertTrue(emitted.isEmpty)
        shouldFail = false
        let result = ReviewJourneyPersistence.saveAndReplay(proposed, hooks: hooks)
        XCTAssertEqual(emitted, proposed.pendingEvidence.map(\.id))
        XCTAssertEqual(result?.pendingEvidence, [])
        XCTAssertEqual(savedArchive, result)
    }

    @MainActor
    func testInterruptedEvidenceAcknowledgementReplaysOneStableIDWithoutDoubleAward() {
        let proposed = correct(start())
        var savedArchive = ReviewJourneyArchive()
        var saveCount = 0
        var failAcknowledgement = true
        var recordedIDs: Set<UUID> = []
        var actualAwards = 0
        let hooks = ReviewJourneyHooks(load: { savedArchive }, save: { archive in
            saveCount += 1
            if failAcknowledgement && saveCount == 2 { return false }
            savedArchive = archive
            return true
        }, record: { event in
            if recordedIDs.insert(event.id).inserted { actualAwards += 1 }
            return true
        })
        let first = ReviewJourneyPersistence.saveAndReplay(proposed, hooks: hooks)
        XCTAssertEqual(first?.pendingEvidence.count, 1)
        XCTAssertEqual(actualAwards, 1)
        failAcknowledgement = false
        let resumed = ReviewJourneyPersistence.saveAndReplay(hooks.load(), hooks: hooks)
        XCTAssertEqual(resumed?.pendingEvidence, [])
        XCTAssertEqual(actualAwards, 1)
        XCTAssertEqual(recordedIDs, Set(proposed.pendingEvidence.map(\.id)))
    }

    @MainActor
    func testRejectedEvidenceStaysInDurableOutboxForRetry() {
        let proposed = correct(start())
        var savedArchive = ReviewJourneyArchive()
        let hooks = ReviewJourneyHooks(load: { savedArchive }, save: { savedArchive = $0; return true }, record: { _ in false })
        let result = ReviewJourneyPersistence.saveAndReplay(proposed, hooks: hooks)
        XCTAssertEqual(result?.pendingEvidence, proposed.pendingEvidence)
        XCTAssertEqual(savedArchive, result)
    }
}
