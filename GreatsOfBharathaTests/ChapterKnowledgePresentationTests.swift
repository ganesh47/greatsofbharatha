import XCTest
@testable import Greats_Of_Bharatha

@MainActor
final class ChapterKnowledgePresentationTests: XCTestCase {
    private let definition = ChapterKnowledgeTestContent.definition()
    private let now = Date(timeIntervalSince1970: 2_000)

    func testFailedSelectionSaveKeepsConfirmedChoiceAndRetryPreservesProposal() throws {
        let store = PresentationTestStore(archive: taughtPractice())
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertTrue(session.reload())
        let original = session.archive
        let choice = definition.questions[0].correctChoiceID
        let proposed = ChapterKnowledgeJourney.select(choice, archive: original, definition: definition)
        store.failSave = true
        XCTAssertFalse(session.commit(proposed))
        XCTAssertEqual(session.archive, original)
        XCTAssertFalse(session.saveIsConfirmed)
        XCTAssertFalse(session.confirmBeforeLeaving())
        XCTAssertFalse(session.reload(), "An appearance must not discard a failed proposal")
        store.failSave = false
        XCTAssertTrue(session.retry())
        XCTAssertEqual(session.archive.practiceBySceneID[definition.sceneID]?.selectedChoiceID, choice)
        XCTAssertTrue(session.archive.pendingEvidence.isEmpty)
        XCTAssertTrue(store.delivered.isEmpty)
    }

    func testFailedAcknowledgementBlocksAdvanceAndReplaysSameResultAfterRelaunch() throws {
        let store = PresentationTestStore(archive: taughtPractice())
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertTrue(session.reload())
        let selected = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID,
            archive: session.archive, definition: definition)
        XCTAssertTrue(session.commit(selected))
        store.failRecord = true
        let checked = ChapterKnowledgeJourney.check(session.archive, definition: definition, now: now)
        XCTAssertFalse(session.commit(checked))
        let id = try XCTUnwrap(session.archive.pendingEvidence.first?.id)
        XCTAssertTrue(session.isBlocked)
        XCTAssertFalse(session.commit(ChapterKnowledgeJourney.advance(session.archive, definition: definition)))
        XCTAssertEqual(session.archive.practiceBySceneID[definition.sceneID]?.cursor, 0)
        let relaunched = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertFalse(relaunched.reload())
        XCTAssertEqual(relaunched.archive.pendingEvidence.first?.id, id)
        store.failRecord = false
        XCTAssertTrue(relaunched.retry())
        XCTAssertEqual(relaunched.archive.practiceBySceneID[definition.sceneID]?.currentResult?.id, id)
        XCTAssertEqual(store.delivered, [id])
        XCTAssertTrue(relaunched.reload())
        XCTAssertEqual(store.delivered, [id])
    }

    func testAcknowledgementSaveFailureRetriesWithoutDuplicateDelivery() throws {
        let store = PresentationTestStore(archive: taughtPractice())
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertTrue(session.reload())
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID,
            archive: session.archive, definition: definition)))
        store.failAcknowledgementSave = true
        XCTAssertFalse(session.commit(ChapterKnowledgeJourney.check(session.archive, definition: definition, now: now)))
        let id = try XCTUnwrap(session.archive.pendingEvidence.first?.id)
        XCTAssertEqual(store.delivered, [id])
        XCTAssertTrue(session.isBlocked)
        store.failAcknowledgementSave = false
        XCTAssertTrue(session.retry())
        XCTAssertEqual(store.delivered, [id])
        XCTAssertTrue(session.saveIsConfirmed)
    }

    func testUnsupportedArchiveStaysReadOnlyWithoutWrites() {
        let store = PresentationTestStore(archive: ChapterKnowledgeArchive(schemaVersion: 9))
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertFalse(session.reload())
        XCTAssertTrue(session.isReadOnly)
        XCTAssertFalse(session.retry())
        XCTAssertFalse(session.commit(ChapterKnowledgeArchive()))
        XCTAssertEqual(store.saveCount, 0)
        XCTAssertEqual(store.archive.schemaVersion, 9)
    }

    func testActiveBeatSaveAndPauseDoNotInferFactExposureOrResetAnotherScene() {
        let other = ChapterKnowledgeTestContent.definition(sceneID: "scene-2-torna-rajgad")
        var original = ChapterKnowledgeArchive()
        original = ChapterKnowledgeJourney.begin(original, definition: other, sessionID: UUID(), context: .individualRecognition)
        let store = PresentationTestStore(archive: original)
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertTrue(session.reload())
        var proposed = session.archive
        proposed.teachingBySceneID[definition.sceneID] = ChapterKnowledgeTeachingCheckpoint(sceneID: definition.sceneID,
            activeBeatID: definition.beats[1].id)
        XCTAssertTrue(session.commit(proposed))
        XCTAssertTrue(session.confirmBeforeLeaving())
        XCTAssertEqual(session.archive.practiceBySceneID[other.sceneID], original.practiceBySceneID[other.sceneID])
        XCTAssertEqual(session.archive.teachingBySceneID[definition.sceneID]?.taughtClaimIDs, [])
        XCTAssertEqual(session.archive.teachingBySceneID[definition.sceneID]?.shownBeatIDs, [])
        XCTAssertTrue(session.archive.retainedEvidence.isEmpty)
    }

    func testWrongHelpedRetryAndSeenAnswerRemainTruthfulThroughPresentationSaves() throws {
        let store = PresentationTestStore(archive: taughtPractice())
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertTrue(session.reload())
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.requestHelp(session.archive, definition: definition)))
        let question = definition.questions[0]
        let wrong = try XCTUnwrap(question.choices.first { $0.id != question.correctChoiceID })
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.select(wrong.id, archive: session.archive, definition: definition)))
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.check(session.archive, definition: definition, now: now)))
        let wrongResult = try XCTUnwrap(session.archive.practiceBySceneID[definition.sceneID]?.currentResult)
        XCTAssertFalse(wrongResult.wasSuccessful)
        XCTAssertEqual(wrongResult.support, .withClue)
        XCTAssertEqual(wrongResult.responseContext, .individualRecognition)
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.tryAgain(session.archive, definition: definition)))
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.select(question.correctChoiceID, archive: session.archive, definition: definition)))
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.check(session.archive, definition: definition, now: now)))
        XCTAssertEqual(session.archive.practiceBySceneID[definition.sceneID]?.currentResult?.support, .answerSeen)
        XCTAssertEqual(session.archive.practiceBySceneID[definition.sceneID]?.currentTurn?.helpWasRequested, true)
        XCTAssertEqual(store.delivered.count, 2)
    }

    func testUntaughtDirectEntryCannotSelectOrCheckThroughPresentation() {
        let store = PresentationTestStore(archive: ChapterKnowledgeArchive())
        let session = ChapterKnowledgePresentationSession(hooks: store.hooks)
        XCTAssertTrue(session.reload())
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.begin(session.archive, definition: definition,
            sessionID: UUID(), context: .individualRecognition)))
        XCTAssertEqual(session.archive.practiceBySceneID[definition.sceneID]?.phase, .needsTeaching)
        let before = session.archive
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID,
            archive: session.archive, definition: definition)))
        XCTAssertTrue(session.commit(ChapterKnowledgeJourney.check(session.archive, definition: definition, now: now)))
        XCTAssertEqual(session.archive, before)
        XCTAssertTrue(store.delivered.isEmpty)
    }

    func testTeachingPagesCarryExactAuthoredCopyAndClaimOrder() {
        let beat = definition.beats[0]
        let pages = ChapterKnowledgeTeachingPage.pages(beat: beat, definition: definition)
        XCTAssertEqual(pages.first?.text, beat.text)
        XCTAssertNil(pages.first?.claim)
        XCTAssertEqual(pages.compactMap { $0.claim?.id }, beat.claimIDs)
        XCTAssertEqual(pages.dropFirst().map(\.text), beat.claimIDs.compactMap { id in
            definition.claims.first { $0.id == id }?.statement
        })
    }

    func testOffscreenAndHorizontallyClippedTextNeverQualifies() {
        var coverage = ChapterKnowledgeTextCoverage()
        let text = CGRect(x: 20, y: 300, width: 160, height: 100)
        coverage.observe(textFrame: text, viewport: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertFalse(coverage.isComplete)
        coverage.observe(textFrame: text, viewport: CGRect(x: 40, y: 300, width: 140, height: 100))
        XCTAssertFalse(coverage.isComplete)
        coverage.observe(textFrame: text, viewport: CGRect(x: 0, y: 300, width: 200, height: 100))
        XCTAssertTrue(coverage.isComplete)
    }

    func testLongTextRequiresWholeCoverageAndDoesNotBridgeAnUnseenGap() {
        var coverage = ChapterKnowledgeTextCoverage()
        let text = CGRect(x: 20, y: 0, width: 160, height: 600)
        coverage.observe(textFrame: text, viewport: CGRect(x: 0, y: 0, width: 200, height: 200))
        coverage.observe(textFrame: text, viewport: CGRect(x: 0, y: 400, width: 200, height: 200))
        XCTAssertFalse(coverage.isComplete, "The middle of this large text has never been visible")
        coverage.observe(textFrame: text, viewport: CGRect(x: 0, y: 200, width: 200, height: 200))
        XCTAssertTrue(coverage.isComplete)
    }

    func testTextReflowRequiresNewCoverageInsteadOfReusingOldGeometry() {
        var coverage = ChapterKnowledgeTextCoverage()
        coverage.observe(textFrame: CGRect(x: 0, y: 0, width: 200, height: 100),
            viewport: CGRect(x: 0, y: 0, width: 200, height: 100))
        XCTAssertTrue(coverage.isComplete)
        coverage.observe(textFrame: CGRect(x: 0, y: 0, width: 160, height: 400),
            viewport: CGRect(x: 0, y: 0, width: 200, height: 100))
        XCTAssertFalse(coverage.isComplete)
    }

    private func taughtPractice() -> ChapterKnowledgeArchive {
        var archive = ChapterKnowledgeArchive()
        archive.teachingBySceneID[definition.sceneID] = ChapterKnowledgeTeachingCheckpoint(sceneID: definition.sceneID,
            shownBeatIDs: Set(definition.beats.map(\.id)), taughtClaimIDs: Set(definition.claims.map(\.id)))
        return ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: UUID(), context: .individualRecognition)
    }
}

@MainActor
private final class PresentationTestStore {
    var archive: ChapterKnowledgeArchive
    var failSave = false
    var failRecord = false
    var failAcknowledgementSave = false
    var saveCount = 0
    var delivered: Set<UUID> = []

    init(archive: ChapterKnowledgeArchive) { self.archive = archive }

    var hooks: ChapterKnowledgeHooks {
        ChapterKnowledgeHooks(load: { self.archive }, save: { proposed in
            self.saveCount += 1
            if self.failSave { return false }
            if self.failAcknowledgementSave && !self.archive.pendingEvidence.isEmpty && proposed.pendingEvidence.isEmpty { return false }
            self.archive = proposed
            return true
        }, record: { event in
            if self.failRecord { return false }
            self.delivered.insert(event.id)
            return true
        })
    }
}
