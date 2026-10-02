import XCTest
@testable import Greats_Of_Bharatha

final class TimelineActivityTests: XCTestCase {
    private var events: [TimelineEvent] { SampleContent.shivajiVerticalSlice.activeHeroArc.timelineEvents }
    private var rounds: [TimelineActivityRound] { TimelineActivityCatalog.allRounds(events: events) }
    private var first: TimelineActivityRound { rounds[0] }

    private func started() -> TimelineActivityCheckpoint {
        var checkpoint = TimelineActivityCheckpoint()
        TimelineActivityEngine.begin(round: first, checkpoint: &checkpoint)
        return checkpoint
    }

    private func place(_ index: Int, round: TimelineActivityRound, checkpoint: inout TimelineActivityCheckpoint) -> TimelinePlacementCheck? {
        TimelineActivityEngine.select(cardID: round.cards[index].id, round: round, checkpoint: &checkpoint)
        return TimelineActivityEngine.place(slotIndex: index, round: round, checkpoint: &checkpoint)
    }

    private func roundTrip(_ checkpoint: TimelineActivityCheckpoint) throws -> TimelineActivityCheckpoint {
        try JSONDecoder().decode(TimelineActivityCheckpoint.self, from: JSONEncoder().encode(checkpoint))
    }

    func testSevenCanonicalEventsPreserveAuthoredDatesAndRecoveryWithoutYear() throws {
        let cards = TimelineActivityCatalog.cards(events: events.reversed())
        let canonical = events.sorted { $0.orderIndex < $1.orderIndex }
        XCTAssertEqual(cards.map(\.id), canonical.map(\.id))
        XCTAssertEqual(cards.map(\.title), canonical.map(\.title))
        XCTAssertEqual(cards.map(\.yearLabel), canonical.map(\.yearLabel))
        XCTAssertEqual(cards.count, 7)
        XCTAssertEqual(cards[0].yearLabel, "commonly commemorated as 1630")
        XCTAssertEqual(cards[1].yearLabel, "c. 1646 to 1654")
        XCTAssertNil(try XCTUnwrap(cards.first { $0.id == "timeline-comeback-and-rebuilding" }).yearLabel)
        XCTAssertEqual(Set(cards.map(\.sceneID)).count, 6)
    }

    func testThreeOverlappingRoundsConnectAllSevenEventsLikeTV() {
        let cards = TimelineActivityCatalog.cards(events: events)
        XCTAssertEqual(rounds.map { $0.cards.map(\.id) }, [Array(cards[0...2]), Array(cards[2...4]), Array(cards[4...6])].map { $0.map(\.id) })
        XCTAssertEqual(rounds[0].cards.last, rounds[1].cards.first)
        XCTAssertEqual(rounds[1].cards.last, rounds[2].cards.first)
        XCTAssertEqual(Set(rounds.flatMap { $0.cards.map(\.id) }).count, 7)
    }

    func testOpeningAndFullGatesRequireCheckedCanonicalChapters() {
        let sceneIDs = TimelineActivityCatalog.cards(events: events).map(\.sceneID)
        XCTAssertTrue(TimelineActivityCatalog.availableRounds(events: events, checkedSceneIDs: []).isEmpty)
        XCTAssertTrue(TimelineActivityCatalog.availableRounds(events: events, checkedSceneIDs: Set(sceneIDs.prefix(2))).isEmpty)
        XCTAssertEqual(TimelineActivityCatalog.availableRounds(events: events, checkedSceneIDs: Set(sceneIDs.prefix(3))), [first])
        XCTAssertEqual(TimelineActivityCatalog.availableRounds(events: events, checkedSceneIDs: Set(sceneIDs)), rounds)
        XCTAssertTrue(TimelineActivityCatalog.availableRounds(events: events, checkedSceneIDs: ["reset-scene-1-shivneri"]).isEmpty)
    }

    func testExposureReflectionFailureAndSelfReportCannotOpenCheckedRounds() {
        for type in [MasteryEvidenceType.storyExposure, .chronicleReflection, .recallAttempt, .selfReportedReview, .timelinePlacementSuccess] {
            let evidence = MasteryEvidence(type: type, recordedAt: .distantPast, detail: "Synthetic")
            XCTAssertFalse(TimelineActivityCatalog.hasCheckedLearning(evidence: [evidence]))
        }
        for type in [MasteryEvidenceType.recallSuccess, .reviewSuccess] {
            let selfReport = MasteryEvidence(type: type, recordedAt: .distantPast, detail: "Synthetic", support: .selfReported)
            XCTAssertFalse(TimelineActivityCatalog.hasCheckedLearning(evidence: [selfReport]))
            let checked = MasteryEvidence(type: type, recordedAt: .distantPast, detail: "Synthetic", support: .hinted)
            XCTAssertTrue(TimelineActivityCatalog.hasCheckedLearning(evidence: [checked]))
        }
    }

    func testIncompleteCatalogDoesNotShiftHistoricalEventsIntoWrongSlots() {
        XCTAssertTrue(TimelineActivityCatalog.allRounds(events: Array(events.dropFirst())).isEmpty)
    }

    func testTeachingAndSelectionProduceNoCheckedPlacement() {
        var checkpoint = TimelineActivityCheckpoint()
        TimelineActivityEngine.select(cardID: first.cards[0].id, round: first, checkpoint: &checkpoint)
        XCTAssertNil(checkpoint.rounds[first.id]?.selectedCardID)
        TimelineActivityEngine.begin(round: first, checkpoint: &checkpoint)
        TimelineActivityEngine.select(cardID: first.cards[0].id, round: first, checkpoint: &checkpoint)
        XCTAssertEqual(checkpoint.rounds[first.id]?.selectedCardID, first.cards[0].id)
        XCTAssertEqual(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: checkpoint), [])
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: first, checkpoint: checkpoint))
    }

    func testCorrectPlacementLocksCardAndCannotAwardTwice() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        XCTAssertEqual(check.eventSubjectID, first.cards[0].id)
        XCTAssertEqual(check.support, .independent)
        XCTAssertNil(TimelineActivityEngine.place(slotIndex: 0, round: first, checkpoint: &checkpoint))
        TimelineActivityEngine.select(cardID: first.cards[0].id, round: first, checkpoint: &checkpoint)
        XCTAssertNil(checkpoint.rounds[first.id]?.selectedCardID)
        XCTAssertEqual(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: checkpoint), [check])
    }

    func testGentleRetryRetainsCorrectSlotAndSelectedCardWithoutReceipt() throws {
        var checkpoint = started()
        _ = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        TimelineActivityEngine.select(cardID: first.cards[2].id, round: first, checkpoint: &checkpoint)
        XCTAssertNil(TimelineActivityEngine.place(slotIndex: 1, round: first, checkpoint: &checkpoint))
        let progress = try XCTUnwrap(checkpoint.rounds[first.id])
        XCTAssertEqual(progress.slots, [first.cards[0].id, nil, nil])
        XCTAssertEqual(progress.selectedCardID, first.cards[2].id)
        XCTAssertEqual(progress.retryCount, 1)
        XCTAssertEqual(progress.support, .hinted)
        XCTAssertEqual(progress.checksByCardID.count, 1)
        let checked = try XCTUnwrap(TimelineActivityEngine.place(slotIndex: 2, round: first, checkpoint: &checkpoint))
        XCTAssertEqual(checked.support, .hinted)
    }

    func testHintsNeverFillSlotsAndNeverClaimIndependentCompletion() throws {
        var checkpoint = started()
        _ = place(1, round: first, checkpoint: &checkpoint)
        for _ in 0..<4 { TimelineActivityEngine.hint(round: first, checkpoint: &checkpoint) }
        XCTAssertEqual(checkpoint.rounds[first.id]?.slots, [nil, first.cards[1].id, nil])
        XCTAssertEqual(checkpoint.rounds[first.id]?.hintLevel, 3)
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: first, checkpoint: checkpoint))
        let helped = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        XCTAssertEqual(helped.support, .hinted)
        _ = place(2, round: first, checkpoint: &checkpoint)
        XCTAssertTrue(TimelineActivityEngine.isComplete(round: first, checkpoint: checkpoint))
    }

    func testInvalidIndicesAndUnknownSelectionHaveNoEffect() {
        var checkpoint = started()
        TimelineActivityEngine.select(cardID: "unknown", round: first, checkpoint: &checkpoint)
        let untouched = checkpoint
        XCTAssertNil(TimelineActivityEngine.place(slotIndex: 0, round: first, checkpoint: &checkpoint))
        XCTAssertEqual(checkpoint, untouched)
        TimelineActivityEngine.select(cardID: first.cards[0].id, round: first, checkpoint: &checkpoint)
        let selected = checkpoint
        for index in [-1, 3, 999] {
            XCTAssertNil(TimelineActivityEngine.place(slotIndex: index, round: first, checkpoint: &checkpoint))
            XCTAssertEqual(checkpoint, selected)
        }
    }

    func testDifferentSubjectCannotReuseAnotherPlacementsEventID() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        TimelineActivityEngine.select(cardID: first.cards[1].id, round: first, checkpoint: &checkpoint)
        let before = checkpoint
        XCTAssertNil(TimelineActivityEngine.place(slotIndex: 1, round: first, checkpoint: &checkpoint, eventID: check.eventID))
        XCTAssertEqual(checkpoint, before)
    }

    func testCorruptedDuplicateReceiptCannotRestoreCheckedCompletion() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        for index in 1...2 { _ = place(index, round: first, checkpoint: &checkpoint) }
        checkpoint.rounds[first.id]?.checksByCardID[first.cards[1].id] = TimelinePlacementCheck(
            eventID: check.eventID, sessionID: checkpoint.sessionID, roundID: first.id,
            eventSubjectID: first.cards[1].id, slotIndex: 1, support: .independent)
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: first, checkpoint: checkpoint))
        let restored = TimelineActivityEngine.restored(try roundTrip(checkpoint), allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(restored.rounds[first.id]?.slots, [first.cards[0].id, nil, first.cards[2].id])
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: first, checkpoint: restored))
    }

    func testSelectedCardPartialPlacementSupportAndReceiptsSurviveRelaunch() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        TimelineActivityEngine.acknowledge(check, checkpoint: &checkpoint)
        TimelineActivityEngine.hint(round: first, checkpoint: &checkpoint)
        TimelineActivityEngine.select(cardID: first.cards[2].id, round: first, checkpoint: &checkpoint)
        let restored = TimelineActivityEngine.restored(try roundTrip(checkpoint), allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(restored.rounds[first.id], checkpoint.rounds[first.id])
        XCTAssertEqual(restored.sessionID, checkpoint.sessionID)
        XCTAssertEqual(restored.currentRoundID, first.id)
        XCTAssertTrue(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: restored).isEmpty)
    }

    func testPendingReceiptKeepsSameEventIDAcrossCrashAndAcknowledgement() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        var restored = TimelineActivityEngine.restored(try roundTrip(checkpoint), allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: restored), [check])
        TimelineActivityEngine.acknowledge(check, checkpoint: &restored)
        let relaunched = TimelineActivityEngine.restored(try roundTrip(restored), allRounds: rounds, availableRounds: rounds)
        XCTAssertTrue(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: relaunched).isEmpty)
        XCTAssertEqual(relaunched.rounds[first.id]?.checksByCardID[first.cards[0].id]?.eventID, check.eventID)
    }

    func testSlotsWithoutChecksAndSelfReportedChecksCannotRestoreCompletion() throws {
        var checkpoint = started()
        for index in first.cards.indices { _ = place(index, round: first, checkpoint: &checkpoint) }
        XCTAssertTrue(TimelineActivityEngine.isComplete(round: first, checkpoint: checkpoint))
        checkpoint.rounds[first.id]?.checksByCardID.removeValue(forKey: first.cards[0].id)
        checkpoint.rounds[first.id]?.checksByCardID[first.cards[1].id] = TimelinePlacementCheck(
            eventID: UUID(), sessionID: checkpoint.sessionID, roundID: first.id,
            eventSubjectID: first.cards[1].id, slotIndex: 1, support: .selfReported)
        let restored = TimelineActivityEngine.restored(try roundTrip(checkpoint), allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(restored.rounds[first.id]?.slots, [nil, nil, first.cards[2].id])
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: first, checkpoint: restored))
    }

    func testMalformedSelectedCardSessionSlotsAndRoundAreSanitized() {
        var checkpoint = started()
        _ = place(0, round: first, checkpoint: &checkpoint)
        checkpoint.sessionID = UUID()
        checkpoint.currentRoundID = "unknown-round"
        checkpoint.rounds[first.id]?.slots = [first.cards[0].id, first.cards[0].id]
        checkpoint.rounds[first.id]?.selectedCardID = "unknown-card"
        checkpoint.rounds[first.id]?.hintLevel = -3
        checkpoint.rounds["unknown-round"] = TimelineRoundProgress()
        let restored = TimelineActivityEngine.restored(checkpoint, allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(restored.currentRoundID, first.id)
        XCTAssertEqual(restored.rounds[first.id]?.slots, [nil, nil, nil])
        XCTAssertNil(restored.rounds[first.id]?.selectedCardID)
        XCTAssertEqual(restored.rounds[first.id]?.hintLevel, 0)
        XCTAssertNil(restored.rounds["unknown-round"])
    }

    func testSavedRoundCannotSkipEarlierUncheckedParts() {
        var checkpoint = started()
        checkpoint.currentRoundID = rounds[2].id
        let restored = TimelineActivityEngine.restored(checkpoint, allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(restored.currentRoundID, first.id)
    }

    func testCannotAdvanceUntilAllThreePlacementsAreChecked() {
        var checkpoint = started()
        TimelineActivityEngine.advance(rounds: rounds, checkpoint: &checkpoint)
        XCTAssertEqual(checkpoint.currentRoundID, first.id)
        for index in first.cards.indices { _ = place(index, round: first, checkpoint: &checkpoint) }
        TimelineActivityEngine.advance(rounds: rounds, checkpoint: &checkpoint)
        XCTAssertEqual(checkpoint.currentRoundID, rounds[1].id)
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: rounds[1], checkpoint: checkpoint))
    }

    func testOpeningCompletionSurvivesFullJourneyUnlockWithoutNewAward() {
        var checkpoint = started()
        for index in first.cards.indices { _ = place(index, round: first, checkpoint: &checkpoint) }
        let opening = TimelineActivityEngine.restored(checkpoint, allRounds: rounds, availableRounds: [first])
        let full = TimelineActivityEngine.restored(opening, allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(full, opening)
        XCTAssertTrue(TimelineActivityEngine.isComplete(round: first, checkpoint: full))
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: rounds[1], checkpoint: full))
    }

    func testUnsupportedCheckpointVersionStartsFreshWithoutInventingChecks() {
        var checkpoint = started()
        _ = place(0, round: first, checkpoint: &checkpoint)
        checkpoint.schemaVersion = 99
        let restored = TimelineActivityEngine.restored(checkpoint, allRounds: rounds, availableRounds: rounds)
        XCTAssertNotEqual(restored.sessionID, checkpoint.sessionID)
        XCTAssertTrue(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: restored).isEmpty)
        XCTAssertFalse(TimelineActivityEngine.isComplete(round: first, checkpoint: restored))
    }

    func testFailedDurableSaveDoesNotDeliverOrAcknowledgeEvidence() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        var checkCalls = 0
        let result = TimelineActivityEngine.synchronize(rounds: rounds, checkpoint: &checkpoint,
            onSave: { _ in false }, onCheck: { _ in checkCalls += 1; return true })
        XCTAssertEqual(result, .saveFailed)
        XCTAssertEqual(checkCalls, 0)
        XCTAssertEqual(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: checkpoint), [check])
        XCTAssertFalse(TimelineActivityEngine.isRecorded(round: first, checkpoint: checkpoint))
    }

    func testSuccessfulDurableIntentPrecedesEvidenceAndAcknowledgementSave() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        var durable: TimelineActivityCheckpoint?
        var operations: [String] = []
        let result = TimelineActivityEngine.synchronize(rounds: rounds, checkpoint: &checkpoint,
            onSave: { point in durable = point; operations.append("save"); return true },
            onCheck: { receipt in
                operations.append("check")
                XCTAssertEqual(durable?.rounds[self.first.id]?.checksByCardID[receipt.eventSubjectID], receipt)
                return true
            })
        XCTAssertEqual(result, .saved)
        XCTAssertEqual(operations, ["save", "check", "save"])
        XCTAssertTrue(durable?.rounds[first.id]?.acknowledgedEventIDs.contains(check.eventID) == true)
        XCTAssertTrue(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: checkpoint).isEmpty)
    }

    func testUnacknowledgedCorrectOrderCannotClaimRecordedCompletion() {
        var checkpoint = started()
        for index in first.cards.indices { _ = place(index, round: first, checkpoint: &checkpoint) }
        let result = TimelineActivityEngine.synchronize(rounds: rounds, checkpoint: &checkpoint,
            onSave: { _ in true }, onCheck: { _ in false })
        XCTAssertEqual(result, .checksPending)
        XCTAssertTrue(TimelineActivityEngine.isComplete(round: first, checkpoint: checkpoint))
        XCTAssertFalse(TimelineActivityEngine.isRecorded(round: first, checkpoint: checkpoint))
        XCTAssertEqual(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: checkpoint).count, 3)
    }

    func testFailedAcknowledgementSaveRetainsDurablePendingIdentityForCrashRetry() throws {
        var checkpoint = started()
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        var durable: TimelineActivityCheckpoint?
        var saves = 0
        let result = TimelineActivityEngine.synchronize(rounds: rounds, checkpoint: &checkpoint,
            onSave: { point in
                saves += 1
                guard saves == 1 else { return false }
                durable = point
                return true
            }, onCheck: { _ in true })
        XCTAssertEqual(result, .saveFailed)
        var relaunched = TimelineActivityEngine.restored(try roundTrip(XCTUnwrap(durable)), allRounds: rounds, availableRounds: rounds)
        XCTAssertEqual(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: relaunched), [check])
        var retriedIDs: [UUID] = []
        let retry = TimelineActivityEngine.synchronize(rounds: rounds, checkpoint: &relaunched,
            onSave: { _ in true }, onCheck: { retriedIDs.append($0.eventID); return true })
        XCTAssertEqual(retry, .saved)
        XCTAssertEqual(retriedIDs, [check.eventID])
    }

    func testOnlyAcknowledgedCheckedOrderIsRecordedComplete() {
        var checkpoint = started()
        for index in first.cards.indices { _ = place(index, round: first, checkpoint: &checkpoint) }
        XCTAssertFalse(TimelineActivityEngine.isRecorded(round: first, checkpoint: checkpoint))
        let result = TimelineActivityEngine.synchronize(rounds: rounds, checkpoint: &checkpoint,
            onSave: { _ in true }, onCheck: { _ in true })
        XCTAssertEqual(result, .saved)
        XCTAssertTrue(TimelineActivityEngine.isRecorded(round: first, checkpoint: checkpoint))
    }

    func testStoreDeduplicatesPendingPlacementAfterCrashWithoutChangingEvidenceKind() throws {
        let suite = "GreatsOfBharatha.TimelineActivityTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var checkpoint = started()
        TimelineActivityEngine.hint(round: first, checkpoint: &checkpoint)
        let check = try XCTUnwrap(place(0, round: first, checkpoint: &checkpoint))
        let store = ShivajiLessonStore(defaults: defaults)
        XCTAssertTrue(store.recordLearningOutcome(subjectID: check.eventSubjectID, subjectType: .timeline,
            activity: .timelinePlacement, wasSuccessful: true, support: check.support, promptType: .sequenceSlot,
            eventID: check.eventID, sessionID: check.sessionID))
        let restored = TimelineActivityEngine.restored(try roundTrip(checkpoint), allRounds: rounds, availableRounds: rounds)
        let pending = try XCTUnwrap(TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: restored).first)
        let relaunchedStore = ShivajiLessonStore(defaults: defaults)
        XCTAssertFalse(relaunchedStore.recordLearningOutcome(subjectID: pending.eventSubjectID, subjectType: .timeline,
            activity: .timelinePlacement, wasSuccessful: true, support: pending.support, promptType: .sequenceSlot,
            eventID: pending.eventID, sessionID: pending.sessionID))
        let record = try XCTUnwrap(relaunchedStore.masteryRecord(for: check.eventSubjectID))
        XCTAssertEqual(record.evidenceLog.count, 1)
        XCTAssertEqual(record.evidenceLog.first?.type, .timelinePlacementSuccess)
        XCTAssertEqual(record.evidenceLog.first?.support, .hinted)
        XCTAssertEqual(record.evidenceLog.first?.activity, .timelinePlacement)
        XCTAssertEqual(record.state, .understood)
        XCTAssertFalse(record.evidenceLog.contains { $0.type == .reviewSuccess })
    }
}
