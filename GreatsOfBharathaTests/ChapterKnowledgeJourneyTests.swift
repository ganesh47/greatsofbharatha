import XCTest
@testable import Greats_Of_Bharatha

@MainActor
final class ChapterKnowledgeJourneyTests: XCTestCase {
    private let definition = ChapterKnowledgeTestContent.definition()
    private let now = Date(timeIntervalSince1970: 1_000)

    func testDirectPracticeRequiresTeachingEvenWithApprovedContent() {
        let archive = begin(ChapterKnowledgeArchive())
        XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.phase, .needsTeaching)
        XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.queue.count, 4)
        XCTAssertTrue(archive.pendingEvidence.isEmpty)
    }

    func testPartialOrUnknownFactPresentationCreatesNoReceipt() {
        let original = ChapterKnowledgeArchive()
        let result = ChapterKnowledgeJourney.presentedBeat(definition.beats[0].id, visibleClaimIDs: [],
            sessionID: UUID(), archive: original, definition: definition, now: now)
        XCTAssertEqual(result, original)
        XCTAssertEqual(ChapterKnowledgeJourney.presentedBeat("missing", visibleClaimIDs: [], sessionID: UUID(),
            archive: original, definition: definition, now: now), original)
    }

    func testTeachingExposureIsIdempotentAndNeverSuccessfulAssessment() throws {
        let beat = definition.beats[0]
        let first = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(),
            archive: ChapterKnowledgeArchive(), definition: definition, now: now)
        let event = try XCTUnwrap(first.pendingEvidence.first)
        XCTAssertEqual(event.kind, .teachingExposure)
        XCTAssertFalse(event.wasSuccessful)
        XCTAssertNil(event.questionID)
        let acknowledged = ChapterKnowledgeJourney.acknowledge(event.id, archive: first)
        let repeated = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(),
            archive: acknowledged, definition: definition, now: now)
        XCTAssertEqual(repeated, acknowledged)
    }

    func testAllFourQuestionsReachableWithSeparateSelectAndCheck() throws {
        var archive = begin(taughtArchive())
        var reached: [String] = []
        for question in definition.questions {
            XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.phase, .prompt)
            XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.currentTurn?.questionID, question.id)
            let selected = ChapterKnowledgeJourney.select(question.correctChoiceID, archive: archive, definition: definition)
            XCTAssertTrue(selected.pendingEvidence.isEmpty)
            XCTAssertEqual(selected.practiceBySceneID[definition.sceneID]?.cursor, reached.count)
            let checked = ChapterKnowledgeJourney.check(selected, definition: definition, now: now)
            let event = try XCTUnwrap(checked.pendingEvidence.first)
            XCTAssertTrue(event.wasSuccessful)
            XCTAssertEqual(event.selectedChoiceID, question.correctChoiceID)
            XCTAssertEqual(ChapterKnowledgeJourney.advance(checked, definition: definition), checked)
            reached.append(question.id)
            archive = ChapterKnowledgeJourney.advance(ChapterKnowledgeJourney.acknowledge(event.id, archive: checked), definition: definition)
        }
        XCTAssertEqual(reached, definition.questions.map(\.id))
        XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.phase, .complete)
        XCTAssertTrue(archive.isSupported)
    }

    func testSelectionAndStickyHelpSurviveRoundTripWithoutEvidence() throws {
        var archive = begin(taughtArchive())
        archive = ChapterKnowledgeJourney.requestHelp(archive, definition: definition)
        archive = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: archive, definition: definition)
        let reopened = try JSONDecoder().decode(ChapterKnowledgeArchive.self, from: JSONEncoder().encode(archive))
        XCTAssertEqual(reopened, archive)
        XCTAssertEqual(reopened.practiceBySceneID[definition.sceneID]?.selectedChoiceID, definition.questions[0].correctChoiceID)
        XCTAssertTrue(reopened.practiceBySceneID[definition.sceneID]?.currentTurn?.helpWasRequested == true)
        XCTAssertTrue(reopened.pendingEvidence.isEmpty)
        XCTAssertEqual(ChapterKnowledgeJourney.check(reopened, definition: definition, now: now).pendingEvidence.first?.support, .withClue)
    }

    func testAnyPendingEventBlocksNewChapterAndSelectionUntilAcknowledged() throws {
        let beat = definition.beats[0]
        let pending = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(),
            archive: ChapterKnowledgeArchive(), definition: definition, now: now)
        XCTAssertNotNil(pending.pendingEvidence.first)
        let other = ChapterKnowledgeTestContent.definition(sceneID: "scene-2-torna-rajgad")
        XCTAssertEqual(ChapterKnowledgeJourney.begin(pending, definition: other, sessionID: UUID(), context: .individualRecognition), pending)
        XCTAssertEqual(ChapterKnowledgeJourney.select("choice", archive: pending, definition: definition), pending)
        XCTAssertEqual(ChapterKnowledgeJourney.resume(pending, definition: definition), pending)
    }

    func testIncorrectAnswerThenRetryIsSeenAnswerRatherThanFreshCheck() throws {
        var archive = begin(taughtArchive())
        let question = definition.questions[0]
        archive = ChapterKnowledgeJourney.select(question.choices[1].id, archive: archive, definition: definition)
        archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: now)
        let wrong = try XCTUnwrap(archive.pendingEvidence.first)
        XCTAssertFalse(wrong.wasSuccessful)
        archive = ChapterKnowledgeJourney.tryAgain(ChapterKnowledgeJourney.acknowledge(wrong.id, archive: archive), definition: definition)
        archive = ChapterKnowledgeJourney.select(question.correctChoiceID, archive: archive, definition: definition)
        archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: now)
        let corrected = try XCTUnwrap(archive.pendingEvidence.first)
        XCTAssertTrue(corrected.wasSuccessful)
        XCTAssertEqual(corrected.support, .answerSeen)
        XCTAssertNotEqual(corrected.id, wrong.id)
    }

    func testThreeIncorrectAttemptsOfferBoundedMoveOnWithoutInventingSuccess() throws {
        var archive = begin(taughtArchive())
        let question = definition.questions[0]
        for attempt in 0..<3 {
            archive = ChapterKnowledgeJourney.select(question.choices[1].id, archive: archive, definition: definition)
            archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: now)
            let event = try XCTUnwrap(archive.pendingEvidence.first)
            XCTAssertFalse(event.wasSuccessful)
            archive = ChapterKnowledgeJourney.acknowledge(event.id, archive: archive)
            if attempt < 2 { archive = ChapterKnowledgeJourney.tryAgain(archive, definition: definition) }
        }
        XCTAssertFalse(archive.practiceBySceneID[definition.sceneID]?.canTryAgain == true)
        XCTAssertEqual(ChapterKnowledgeJourney.tryAgain(archive, definition: definition), archive)
        let advanced = ChapterKnowledgeJourney.advance(archive, definition: definition)
        XCTAssertEqual(advanced.practiceBySceneID[definition.sceneID]?.cursor, 1)
        XCTAssertFalse(advanced.retainedEvidence.contains { $0.kind == .choiceCheck && $0.wasSuccessful })
    }

    func testCompletedPracticeRetainsSessionUnlessExplicitlyRestartedAndMarksSeenQuestions() throws {
        var archive = begin(taughtArchive())
        let originalSession = archive.practiceBySceneID[definition.sceneID]?.sessionID
        for question in definition.questions {
            archive = ChapterKnowledgeJourney.select(question.correctChoiceID, archive: archive, definition: definition)
            archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: now)
            let event = try XCTUnwrap(archive.pendingEvidence.first)
            archive = ChapterKnowledgeJourney.advance(ChapterKnowledgeJourney.acknowledge(event.id, archive: archive), definition: definition)
        }
        XCTAssertEqual(begin(archive).practiceBySceneID[definition.sceneID]?.sessionID, originalSession)
        let restarted = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: UUID(),
            context: .individualRecognition, restartCompleted: true)
        XCTAssertTrue(restarted.practiceBySceneID[definition.sceneID]?.queue.allSatisfy(\.wasPreviouslyChecked) == true)
        let selected = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: restarted, definition: definition)
        XCTAssertEqual(ChapterKnowledgeJourney.check(selected, definition: definition, now: now).pendingEvidence.first?.support, .answerSeen)
    }

    func testFamilyRecognitionContextSurvivesChoiceCheck() throws {
        var archive = ChapterKnowledgeJourney.begin(taughtArchive(), definition: definition, sessionID: UUID(), context: .sharedFamilyRecognition)
        archive = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: archive, definition: definition)
        let event = try XCTUnwrap(ChapterKnowledgeJourney.check(archive, definition: definition, now: now).pendingEvidence.first)
        XCTAssertEqual(event.responseContext, .sharedFamilyRecognition)
        XCTAssertEqual(event.kind, .choiceCheck)
    }

    func testUnsupportedAndSemanticallyDamagedArchivesCannotBeChanged() {
        let future = ChapterKnowledgeArchive(schemaVersion: 99)
        XCTAssertFalse(future.isSupported)
        XCTAssertEqual(begin(future), future)
        var damaged = begin(taughtArchive())
        damaged.practiceBySceneID[definition.sceneID]?.cursor = -1
        XCTAssertFalse(damaged.isSupported)
        XCTAssertEqual(ChapterKnowledgeJourney.resume(damaged, definition: definition), damaged)
    }

    func testRetiredQuestionReportsUnavailableAndRetainsQueue() {
        let archive = begin(taughtArchive())
        let changed = ChapterKnowledgeDefinition(sceneID: definition.sceneID, claims: definition.claims,
            beats: definition.beats, questions: Array(definition.questions.dropFirst()))
        let restored = ChapterKnowledgeJourney.resume(archive, definition: changed)
        XCTAssertEqual(restored.practiceBySceneID[definition.sceneID]?.phase, .unavailable)
        XCTAssertEqual(restored.practiceBySceneID[definition.sceneID]?.queue, archive.practiceBySceneID[definition.sceneID]?.queue)
    }

    func testFailedSaveDoesNotDeliverEvidence() {
        let selected = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: begin(taughtArchive()), definition: definition)
        let pending = ChapterKnowledgeJourney.check(selected, definition: definition, now: now)
        var callbacks = 0
        let hooks = ChapterKnowledgeHooks(load: { ChapterKnowledgeArchive() }, save: { _ in false }, record: { _ in callbacks += 1; return true })
        XCTAssertFalse(pending.pendingEvidence.isEmpty)
        XCTAssertNil(ChapterKnowledgePersistence.saveAndReplay(pending, hooks: hooks))
        XCTAssertEqual(callbacks, 0)
    }

    func testFailedAcknowledgementKeepsExactOutboxAndBlocksAdvance() throws {
        var archive = begin(taughtArchive())
        archive = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: archive, definition: definition)
        let checked = ChapterKnowledgeJourney.check(archive, definition: definition, now: now)
        var saved = ChapterKnowledgeArchive()
        let hooks = ChapterKnowledgeHooks(load: { saved }, save: { saved = $0; return true }, record: { _ in false })
        let confirmed = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(checked, hooks: hooks))
        XCTAssertEqual(confirmed, checked)
        XCTAssertEqual(saved.pendingEvidence, checked.pendingEvidence)
        XCTAssertEqual(ChapterKnowledgeJourney.advance(confirmed, definition: definition), confirmed)
    }

    func testFailedAcknowledgementSaveReplaysSameEventWithoutDuplicateEffect() throws {
        let selected = ChapterKnowledgeJourney.select(definition.questions[0].correctChoiceID, archive: begin(taughtArchive()), definition: definition)
        let pending = ChapterKnowledgeJourney.check(selected, definition: definition, now: now)
        var durable = ChapterKnowledgeArchive()
        var saves = 0
        var recordedIDs: Set<UUID> = []
        let hooks = ChapterKnowledgeHooks(load: { durable }, save: { point in
            saves += 1
            guard saves != 2 else { return false }
            durable = point
            return true
        }, record: { event in recordedIDs.insert(event.id); return true })
        let interrupted = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(pending, hooks: hooks))
        XCTAssertEqual(interrupted.pendingEvidence, pending.pendingEvidence)
        XCTAssertEqual(durable.pendingEvidence, pending.pendingEvidence)
        let replayed = try XCTUnwrap(ChapterKnowledgePersistence.saveAndReplay(hooks.load(), hooks: hooks))
        XCTAssertTrue(replayed.pendingEvidence.isEmpty)
        XCTAssertEqual(recordedIDs.count, 1)
    }

    private func begin(_ archive: ChapterKnowledgeArchive) -> ChapterKnowledgeArchive {
        ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: UUID(), context: .individualRecognition)
    }

    private func taughtArchive() -> ChapterKnowledgeArchive {
        var archive = ChapterKnowledgeArchive()
        for beat in definition.beats {
            archive = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(),
                archive: archive, definition: definition, now: now)
            if let event = archive.pendingEvidence.first { archive = ChapterKnowledgeJourney.acknowledge(event.id, archive: archive) }
        }
        return archive
    }
}

enum ChapterKnowledgeTestContent {
    static func definition(sceneID: String = "scene-1-shivneri") -> ChapterKnowledgeDefinition {
        let roles: [LegacyChapterStoryRole] = [.story, .memory, .meaning]
        let claims = roles.enumerated().map { index, role in
            ChapterKnowledgeClaim(id: sceneID + "-fact-fixture-\(index)", kind: .vocabulary,
                statement: "Synthetic fixture; not historical content.",
                citations: [ChapterKnowledgeCitation(sourceID: "fixture", locator: "fixture")],
                taughtBeatIDs: [role.beatID(sceneID: sceneID)], reviewStatus: .approved)
        }
        let beats = roles.enumerated().map { index, role in
            ChapterKnowledgeBeat(id: role.beatID(sceneID: sceneID), title: "Fixture", text: "Fixture teaching", claimIDs: [claims[index].id])
        }
        let questions = (0..<4).map { index in
            ChapterKnowledgeQuestion(id: sceneID + "-question-fixture-\(index)", kind: .meaning, prompt: "Fixture question",
                choices: [ChapterKnowledgeChoice(id: "fixture-\(index)-a", text: "Choice A"),
                          ChapterKnowledgeChoice(id: "fixture-\(index)-b", text: "Choice B")],
                correctChoiceID: "fixture-\(index)-a", claimIDs: [claims[index % 3].id], requiredBeatIDs: [beats[index % 3].id],
                explanation: "Fixture explanation", hints: ["Fixture hint"], retryFeedback: "Try the clue")
        }
        return ChapterKnowledgeDefinition(sceneID: sceneID, claims: claims, beats: beats, questions: questions)
    }
}
