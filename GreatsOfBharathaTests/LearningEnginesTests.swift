import XCTest
@testable import Greats_Of_Bharatha

final class LearningEnginesTests: XCTestCase {
    func testQuizEngineAcceptsNormalizedCorrectAnswerWithoutHint() {
        let result = ChronicleQuizEngine.evaluate(
            state: ChronicleQuizState(),
            challenge: shivneriChallenge,
            typedAnswer: "  shivneri fort! "
        )

        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.kind, .correctWithoutHint)
        XCTAssertEqual(result.masteryAwarded, .understood)
        XCTAssertFalse(result.shouldUseSoonReview)
    }

    func testQuizEngineProgressesThroughHintLadderThenRecognitionRescue() {
        var state = ChronicleQuizState()

        let firstMiss = ChronicleQuizEngine.evaluate(state: state, challenge: shivneriChallenge, typedAnswer: "Rajgad")
        XCTAssertFalse(firstMiss.isCorrect)
        XCTAssertEqual(firstMiss.kind, .incorrect)
        XCTAssertEqual(firstMiss.nextState.revealedHintCount, 1)
        XCTAssertFalse(firstMiss.nextState.recognitionRescueUnlocked)
        XCTAssertTrue(firstMiss.feedback.contains("Birth Fort"))

        state = firstMiss.nextState
        state = ChronicleQuizEngine.evaluate(state: state, challenge: shivneriChallenge, typedAnswer: "Torna").nextState
        state = ChronicleQuizEngine.evaluate(state: state, challenge: shivneriChallenge, typedAnswer: "Pratapgad").nextState
        let rescued = ChronicleQuizEngine.evaluate(state: state, challenge: shivneriChallenge, typedAnswer: "Raigad")

        XCTAssertFalse(rescued.isCorrect)
        XCTAssertEqual(rescued.kind, .rescuedRecognition)
        XCTAssertEqual(rescued.nextState.revealedHintCount, 3)
        XCTAssertTrue(rescued.nextState.recognitionRescueUnlocked)
        XCTAssertEqual(rescued.feedback, "Shivneri is the Birth Fort where the journey begins.")
    }

    func testQuizEngineMarksCorrectAnswerAfterHintAsCorrectWithHint() {
        let hintedState = ChronicleQuizState(revealedHintCount: 1)

        let result = ChronicleQuizEngine.evaluate(
            state: hintedState,
            challenge: rajgadChallenge,
            typedAnswer: "Rajgad"
        )

        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.kind, .correctWithHint)
        XCTAssertTrue(result.shouldUseSoonReview)
    }

    func testMatchEngineCompletesPairAndFullSet() {
        var state = ChronicleMatchState()

        state = ChronicleMatchEngine.select(tileID: "place-shivneri", state: state, pairs: matchPairs)
        XCTAssertEqual(state.selectedTileID, "place-shivneri")

        state = ChronicleMatchEngine.select(tileID: "hook-birth-fort", state: state, pairs: matchPairs)
        XCTAssertEqual(state.completedPairIDs, ["shivneri-birth-fort"])
        XCTAssertNil(state.selectedTileID)

        guard case let .matched(pairID, _, completedSet)? = state.lastOutcome else {
            return XCTFail("Expected matched outcome")
        }
        XCTAssertEqual(pairID, "shivneri-birth-fort")
        XCTAssertFalse(completedSet)

        state = ChronicleMatchEngine.select(tileID: "place-rajgad", state: state, pairs: matchPairs)
        state = ChronicleMatchEngine.select(tileID: "hook-early-capital", state: state, pairs: matchPairs)

        guard case let .matched(_, _, completedSet)? = state.lastOutcome else {
            return XCTFail("Expected matched outcome")
        }
        XCTAssertTrue(completedSet)
        XCTAssertEqual(state.completedPairIDs.count, 2)
    }

    func testMatchEngineMismatchReturnsClueWithoutCompletingPair() {
        var state = ChronicleMatchState()

        state = ChronicleMatchEngine.select(tileID: "place-shivneri", state: state, pairs: matchPairs)
        state = ChronicleMatchEngine.select(tileID: "hook-early-capital", state: state, pairs: matchPairs)

        XCTAssertEqual(state.completedPairIDs.count, 0)
        XCTAssertEqual(state.mismatchCount, 1)
        XCTAssertNil(state.selectedTileID)

        guard case let .mismatched(clue)? = state.lastOutcome else {
            return XCTFail("Expected mismatch outcome")
        }
        XCTAssertEqual(clue, "Shivneri is remembered as the Birth Fort.")
    }

    func testMatchEngineIgnoresAlreadyCompletedPair() {
        var state = ChronicleMatchState(completedPairIDs: ["shivneri-birth-fort"])

        state = ChronicleMatchEngine.select(tileID: "place-shivneri", state: state, pairs: matchPairs)

        XCTAssertNil(state.selectedTileID)
        XCTAssertEqual(state.completedPairIDs, ["shivneri-birth-fort"])
        XCTAssertEqual(state.lastOutcome, .ignored)
    }

    func testReviewSchedulerSchedulesNoHintSuccessForTomorrowAndRotatesPrompt() {
        let now = Date(timeIntervalSince1970: 1_800_000)
        let schedule = baseSchedule(nextDueAt: now)
        let quizResult = ChronicleQuizResult(
            kind: .correctWithoutHint,
            isCorrect: true,
            masteryAwarded: .understood,
            feedback: "Yes.",
            nextState: ChronicleQuizState()
        )

        let result = SpacedReviewScheduler.schedule(
            schedule,
            after: quizResult,
            promptHistory: [.openPrompt],
            now: now,
            calendar: gregorianUTC
        )

        XCTAssertEqual(result.schedule.intervalIndex, 1)
        XCTAssertEqual(result.schedule.stabilityBand, .warming)
        XCTAssertEqual(result.nextPromptType, .eventToPlaceMatch)
        XCTAssertFalse(result.shouldReviewInCurrentSession)
        XCTAssertEqual(result.schedule.nextDueAt, gregorianUTC.date(byAdding: .day, value: 1, to: now))
    }

    func testReviewSchedulerSchedulesHintedAndRescuedWorkSooner() {
        let now = Date(timeIntervalSince1970: 1_800_000)
        let schedule = baseSchedule(nextDueAt: now)

        let hinted = SpacedReviewScheduler.schedule(
            schedule,
            after: .neededClue,
            promptHistory: [.eventToPlaceMatch],
            now: now,
            calendar: gregorianUTC
        )
        XCTAssertEqual(hinted.schedule.intervalIndex, 1)
        XCTAssertEqual(hinted.schedule.nextDueAt, gregorianUTC.date(byAdding: .hour, value: 4, to: now))
        XCTAssertEqual(hinted.nextPromptType, .sequenceSlot)
        XCTAssertFalse(hinted.shouldReviewInCurrentSession)

        let rescued = SpacedReviewScheduler.schedule(
            hinted.schedule,
            after: .teachAgain,
            promptHistory: [.sequenceSlot],
            now: now,
            calendar: gregorianUTC
        )
        XCTAssertEqual(rescued.schedule.intervalIndex, 0)
        XCTAssertEqual(rescued.schedule.nextDueAt, now)
        XCTAssertEqual(rescued.schedule.stabilityBand, .new)
        XCTAssertEqual(rescued.nextPromptType, .compareFromMemory)
        XCTAssertTrue(rescued.shouldReviewInCurrentSession)
    }

    func testReviewSchedulerReturnsDueReviewsInStableOrder() {
        let now = Date(timeIntervalSince1970: 1_800_000)
        let dueLater = baseSchedule(subjectID: "scene-b", nextDueAt: now.addingTimeInterval(10))
        let dueNowB = baseSchedule(subjectID: "scene-b", nextDueAt: now)
        let dueNowA = baseSchedule(subjectID: "scene-a", nextDueAt: now)

        let due = SpacedReviewScheduler.dueReviews(from: [dueLater, dueNowB, dueNowA], now: now)

        XCTAssertEqual(due.map(\.subjectID), ["scene-a", "scene-b"])
    }

    func testChronicleProgressEngineTransitionsFromSilhouetteToRememberedAgain() {
        let now = Date(timeIntervalSince1970: 1_800_000)
        let entry = ChronicleEntry(
            id: "reward-birth-fort-card",
            title: "Birth Fort",
            keepsakeTitle: "Birth Fort Chronicle Card",
            meaningStatement: "Shivneri anchors the beginning.",
            linkedSceneID: "scene-1-shivneri",
            linkedPlaceID: "place-shivneri",
            linkedTimelineEventID: "timeline-born-at-shivneri",
            unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .observedClosely)
        )

        var progress = ChronicleProgressEngine.initialProgress(for: entry)
        XCTAssertEqual(progress.detailLevel, .hidden)
        XCTAssertEqual(progress.unlockState, .silhouette)

        progress = ChronicleProgressEngine.apply(.lessonSeen, to: progress, at: now)
        XCTAssertEqual(progress.detailLevel, .silhouette)
        XCTAssertEqual(progress.unlockState, .silhouette)

        progress = ChronicleProgressEngine.apply(.recallCorrect, to: progress, at: now)
        XCTAssertEqual(progress.detailLevel, .inked)
        XCTAssertEqual(progress.unlockState, .unlocked)

        progress = ChronicleProgressEngine.apply(.matchCompleted, to: progress, at: now)
        XCTAssertEqual(progress.detailLevel, .sealed)
        XCTAssertEqual(progress.unlockState, .enriched)

        progress = ChronicleProgressEngine.apply(.reviewCorrect, to: progress, at: now)
        XCTAssertEqual(progress.detailLevel, .rememberedAgain)
        XCTAssertEqual(progress.unlockState, .enriched)
        XCTAssertEqual(progress.completedEvents, [.lessonSeen, .recallCorrect, .matchCompleted, .reviewCorrect])
    }

    private var shivneriChallenge: RecallChallenge {
        RecallChallenge(
            id: "scene-1-shivneri-recall",
            promptType: .openPrompt,
            prompt: "Which fort is Shivaji Maharaj's birth place?",
            correctAnswers: ["Shivneri Fort", "Shivneri"],
            hintLadder: [
                RecallHint(level: 1, title: "Anchor hint", body: "Think about the Birth Fort."),
                RecallHint(level: 2, title: "Place hint", body: "It is near Junnar."),
                RecallHint(level: 3, title: "Category hint", body: "It is a hill fort."),
            ],
            feedback: RecallFeedback(
                success: "Yes. Shivneri Fort is remembered as Shivaji Maharaj's birth place.",
                recovery: "Shivneri is the Birth Fort where the journey begins."
            ),
            masteryContribution: .understood
        )
    }

    private var rajgadChallenge: RecallChallenge {
        RecallChallenge(
            id: "scene-2-rajgad-recall",
            promptType: .compareFromMemory,
            prompt: "Which fort became an early capital?",
            correctAnswers: ["Rajgad"],
            hintLadder: [RecallHint(level: 1, title: "Pair hint", body: "It came after Torna.")],
            feedback: RecallFeedback(success: "Yes. Rajgad became an early capital.", recovery: "Rajgad is the early capital."),
            masteryContribution: .observedClosely
        )
    }

    private var matchPairs: [ChronicleMatchPair] {
        [
            ChronicleMatchPair(
                id: "shivneri-birth-fort",
                leftID: "place-shivneri",
                leftText: "Shivneri",
                rightID: "hook-birth-fort",
                rightText: "Birth Fort",
                kind: .placeToHook,
                teachingClue: "Shivneri is remembered as the Birth Fort."
            ),
            ChronicleMatchPair(
                id: "rajgad-early-capital",
                leftID: "place-rajgad",
                leftText: "Rajgad",
                rightID: "hook-early-capital",
                rightText: "Early Capital",
                kind: .placeToHook,
                teachingClue: "Rajgad became an early capital and planning base."
            ),
        ]
    }

    private var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func baseSchedule(subjectID: String = "scene-1-shivneri", nextDueAt: Date) -> ReviewSchedule {
        ReviewSchedule(
            subjectID: subjectID,
            subjectType: .scene,
            nextDueAt: nextDueAt,
            intervalIndex: 0,
            stabilityBand: .new,
            difficultyAdjustment: 0,
            cadenceDays: [0, 1, 3, 7, 14]
        )
    }
}
