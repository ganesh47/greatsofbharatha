import Combine
import XCTest
@testable import Greats_Of_Bharatha

final class StateReliabilityTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private let sceneID = "scene-1-shivneri"
    private let now = Date(timeIntervalSince1970: 1_900_000_000)

    override func setUp() {
        super.setUp()
        suiteName = "GreatsOfBharatha.StateReliabilityTests." + UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testNormalAppRecreationPreservesProgressSettingsScheduleAndResume() throws {
        let model = AppModel(defaults: defaults)
        let session = UUID()
        model.parentSettings.narrationEnabled = false
        model.parentSettings.assistModeEnabled = false
        model.lessonStore.recordStoryExposure(for: sceneID, sessionID: session, at: now)
        model.lessonStore.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                               mastery: .remembered, sessionID: session, at: now)
        model.lessonStore.saveResumePoint(LessonResumePoint(sceneID: sceneID, phase: .reward, sessionID: session,
                                                           recallCompleted: true, updatedAt: now))
        let before = try XCTUnwrap(model.lessonStore.reviewSchedule(for: sceneID))
        let restored = AppModel(defaults: defaults)

        XCTAssertEqual(restored.lessonStore.mastery(for: sceneID), .understood)
        XCTAssertTrue(restored.lessonStore.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(restored.lessonStore.nextSceneID, "scene-2-torna-rajgad")
        XCTAssertEqual(restored.lessonStore.reviewSchedule(for: sceneID), before)
        XCTAssertEqual(restored.lessonStore.resumePoint(for: sceneID)?.sessionID, session)
        XCTAssertEqual(restored.lessonStore.resumePoint(for: sceneID)?.recallCompleted, true)
        XCTAssertFalse(restored.parentSettings.narrationEnabled)
        XCTAssertFalse(restored.parentSettings.assistModeEnabled)
    }

    func testExplicitCaptureSeedingCannotEraseInjectedRealStorage() {
        let model = AppModel(defaults: defaults)
        model.lessonStore.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true, at: now)
        _ = AppModel(defaults: defaults, captureSeedProfile: .pristine)
        let restored = AppModel(defaults: defaults)
        XCTAssertEqual(restored.lessonStore.mastery(for: sceneID), .understood)
    }

    func testDebugUITestSuiteResetIsExplicitAndRelaunchPreservesIt() {
        let testDefaults = AppLaunchConfiguration.defaults(environment: ["GOB_UI_TEST_SUITE": suiteName, "GOB_UI_TEST_RESET": "1"])
        testDefaults.set("persisted", forKey: "marker")
        let relaunched = AppLaunchConfiguration.defaults(environment: ["GOB_UI_TEST_SUITE": suiteName])
        XCTAssertEqual(relaunched.string(forKey: "marker"), "persisted")
        let reset = AppLaunchConfiguration.defaults(environment: ["GOB_UI_TEST_SUITE": suiteName, "GOB_UI_TEST_RESET": "1"])
        XCTAssertNil(reset.string(forKey: "marker"))
    }

    func testNestedStoreChangesNotifyAppModelAndReplacementContinuesObservation() {
        let model = AppModel(defaults: defaults)
        var changes = 0
        let token = model.objectWillChange.sink { changes += 1 }
        model.lessonStore.recordStoryExposure(for: sceneID)
        XCTAssertGreaterThan(changes, 0)
        model.content = SampleContent.shivajiVerticalSlice
        let afterReplacement = changes
        model.lessonStore.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true)
        XCTAssertGreaterThan(changes, afterReplacement)
        withExtendedLifetime(token) {}
    }

    func testUnseenBlueprintsAreNotReportedAsDueOrUpcomingLearning() {
        let store = ShivajiLessonStore(defaults: defaults)
        XCTAssertEqual(store.dueReviews(referenceDate: .distantFuture), [])
        XCTAssertEqual(store.upcomingReviews(referenceDate: .distantPast), [])
        store.recordStoryExposure(for: sceneID, at: now)
        XCTAssertEqual(store.dueReviews(referenceDate: .distantFuture).map(\.subjectID), [sceneID])
    }

    func testDuplicateOutcomeIsIgnoredAcrossRelaunch() throws {
        let eventID = UUID()
        let store = ShivajiLessonStore(defaults: defaults)
        XCTAssertTrue(store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                                  eventID: eventID, at: now))
        let schedule = try XCTUnwrap(store.reviewSchedule(for: sceneID))
        let relaunched = ShivajiLessonStore(defaults: defaults)
        XCTAssertFalse(relaunched.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                                        eventID: eventID, at: now.addingTimeInterval(100)))
        XCTAssertEqual(relaunched.reviewSchedule(for: sceneID), schedule)
        XCTAssertEqual(relaunched.masteryRecord(for: sceneID)?.successfulReviewCount, 1)
        XCTAssertEqual(relaunched.masteryRecord(for: sceneID)?.evidenceLog.count, 1)
    }

    func testInterruptedCompletionReusesCheckpointEventRatherThanAwardingAgain() throws {
        let store = ShivajiLessonStore(defaults: defaults)
        let point = LessonResumePoint(sceneID: sceneID, phase: .recall, updatedAt: now)
        store.saveResumePoint(point)
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                    eventID: point.recallEventID, sessionID: point.sessionID, at: now)
        // Simulate termination after evidence was saved but before recallCompleted was set.
        let relaunched = ShivajiLessonStore(defaults: defaults)
        let restoredPoint = try XCTUnwrap(relaunched.resumePoint(for: sceneID))
        XCTAssertFalse(restoredPoint.recallCompleted)
        XCTAssertFalse(relaunched.recordLearningOutcome(subjectID: sceneID, activity: .review,
            wasSuccessful: true, eventID: restoredPoint.recallEventID, sessionID: restoredPoint.sessionID,
            at: now.addingTimeInterval(10)))
        XCTAssertEqual(relaunched.masteryRecord(for: sceneID)?.successfulReviewCount, 1)
        XCTAssertEqual(relaunched.mastery(for: sceneID), .understood)
    }

    func testSharedResumeRetainsMatchingIntentAndTVCheckpointAcrossBothStoragePolicies() throws {
        for policy in [LessonPersistencePolicy.standard, .compactTV] {
            defaults.removePersistentDomain(forName: suiteName)
            let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: policy)
            let sessionID = UUID()
            let matchID = UUID()
            var checkpoint = TVActivityCheckpoint(stage: .puzzle)
            checkpoint.matchedPairIDs = ["match-shivneri-birth-fort"]
            checkpoint.selectedTileID = "tv-match-jijabai-guidance-left"
            let point = LessonResumePoint(sceneID: sceneID, phase: .recall, sessionID: sessionID,
                completedMatchPairIDs: checkpoint.matchedPairIDs, matchEventID: matchID,
                preferredActivity: .match, tvCheckpoint: checkpoint, updatedAt: now)
            store.saveResumePoint(point)
            XCTAssertTrue(store.recordLearningOutcome(subjectID: sceneID, activity: .match,
                wasSuccessful: true, eventID: matchID, sessionID: sessionID, at: now))

            let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: policy)
            XCTAssertEqual(restored.resumePoint(for: sceneID), point)
            XCTAssertFalse(restored.recordLearningOutcome(subjectID: sceneID, activity: .match,
                wasSuccessful: true, eventID: matchID, sessionID: sessionID, at: now.addingTimeInterval(10)))
            XCTAssertEqual(restored.masteryRecord(for: sceneID)?.successfulReviewCount, 1)
        }
    }

    func testFirstRecallCannotClaimRepeatedMemoryAndSameSessionReviewDoesNotEnrich() throws {
        let store = ShivajiLessonStore(defaults: defaults)
        let sessionID = UUID()
        let entry = try XCTUnwrap(SampleContent.shivajiHeroArc.chronicleEntry(withID: "reward-birth-fort-card"))
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                    mastery: .remembered, sessionID: sessionID, at: now)
        XCTAssertEqual(store.mastery(for: sceneID), .understood)
        XCTAssertEqual(store.chronicleProgress(for: entry).detailLevel, .inked)
        store.recordLearningOutcome(subjectID: sceneID, activity: .review, wasSuccessful: true,
                                    mastery: .remembered, sessionID: sessionID, at: now.addingTimeInterval(30))
        XCTAssertEqual(store.mastery(for: sceneID), .understood)
        XCTAssertEqual(store.chronicleProgress(for: entry).detailLevel, .inked)
        store.recordLearningOutcome(subjectID: sceneID, activity: .review, wasSuccessful: true,
                                    sessionID: UUID(), at: now.addingTimeInterval(60))
        XCTAssertEqual(store.mastery(for: sceneID), .remembered)
        XCTAssertEqual(store.chronicleProgress(for: entry).detailLevel, .rememberedAgain)
    }

    func testHintedAndRescuedOutcomesUseTheirOwnScheduleWithoutFakingPlaceKnowledge() throws {
        let store = ShivajiLessonStore(defaults: defaults)
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true, at: now)
        let independent = try XCTUnwrap(store.reviewSchedule(for: sceneID))
        XCTAssertEqual(independent.nextDueAt, Calendar.current.date(byAdding: .day, value: 1, to: now))
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true, support: .hinted, at: now)
        XCTAssertEqual(store.reviewSchedule(for: sceneID)?.nextDueAt, Calendar.current.date(byAdding: .hour, value: 4, to: now))
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true, support: .rescued, at: now)
        XCTAssertEqual(store.reviewSchedule(for: sceneID)?.intervalIndex, 0)
        XCTAssertEqual(store.reviewSchedule(for: sceneID)?.nextDueAt, now)
        let place = try XCTUnwrap(SampleContent.shivajiVerticalSlice.corePlaces.first { $0.id == "place-shivneri" })
        XCTAssertEqual(store.progress(for: place), .readyToLearn)
        XCTAssertFalse(store.recordLearningOutcome(subjectID: sceneID, activity: .mapPlacement, wasSuccessful: true))
        store.recordLearningOutcome(subjectID: place.id, subjectType: .location, activity: .mapPlacement,
                                    wasSuccessful: true, at: now)
        XCTAssertEqual(store.progress(for: place), .masteredLightly)
    }

    func testExposureAndFailedRecallDoNotUnlockRewardsOrIncreaseSuccessfulReviews() {
        let store = ShivajiLessonStore(defaults: defaults)
        store.recordStoryExposure(for: sceneID, at: now)
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: false,
                                    mastery: .chronicled, at: now)
        XCTAssertFalse(store.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(store.mastery(for: sceneID), .witnessed)
        XCTAssertEqual(store.masteryRecord(for: sceneID)?.exposureCount, 1)
        XCTAssertEqual(store.masteryRecord(for: sceneID)?.successfulReviewCount, 0)
    }

    func testMatchCannotAwardAlbumBeforeRecallButPersistsAfterRecall() throws {
        let store = ShivajiLessonStore(defaults: defaults)
        let entry = try XCTUnwrap(SampleContent.shivajiHeroArc.chronicleEntry(withID: "reward-birth-fort-card"))
        store.recordLearningOutcome(subjectID: sceneID, activity: .match, wasSuccessful: true, at: now)
        XCTAssertFalse(store.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(store.chronicleProgress(for: entry).unlockState, .silhouette)
        store.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true, at: now)
        let restored = ShivajiLessonStore(defaults: defaults)
        XCTAssertTrue(restored.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(restored.chronicleProgress(for: entry).detailLevel, .sealed)
    }

    func testSelfReportedFlashcardsPersistSchedulingButCannotClaimIndependentRecall() throws {
        let store = ShivajiLessonStore(defaults: defaults)
        let eventID = UUID()
        let first = try XCTUnwrap(store.recordReviewResponse(subjectID: sceneID, response: .knewIt, eventID: eventID, at: now))
        let restored = ShivajiLessonStore(defaults: defaults)
        let second = try XCTUnwrap(restored.recordReviewResponse(subjectID: sceneID, response: .knewIt, at: now.addingTimeInterval(100)))
        XCTAssertEqual(first.schedule.intervalIndex, 1)
        XCTAssertEqual(second.schedule.intervalIndex, 2)
        XCTAssertNil(restored.recordReviewResponse(subjectID: sceneID, response: .knewIt, eventID: eventID))
        XCTAssertEqual(restored.mastery(for: sceneID), .witnessed)
        XCTAssertFalse(restored.isUnlocked(SampleContent.birthFortCard))
    }

    func testMultipleCardsInOneSessionCannotSimulateSpacedRevisits() throws {
        let store = ShivajiLessonStore(defaults: defaults)
        let sessionID = UUID()
        let first = try XCTUnwrap(store.recordReviewResponse(subjectID: sceneID, response: .knewIt,
                                                            sessionID: sessionID, at: now))
        let relaunched = ShivajiLessonStore(defaults: defaults)
        let second = try XCTUnwrap(relaunched.recordReviewResponse(subjectID: sceneID, response: .knewIt,
                                                                 sessionID: sessionID, at: now.addingTimeInterval(60)))
        XCTAssertEqual(second.schedule, first.schedule)
        let hinted = try XCTUnwrap(relaunched.recordReviewResponse(subjectID: sceneID, response: .neededClue,
                                                                 sessionID: sessionID, at: now.addingTimeInterval(120)))
        XCTAssertEqual(hinted.schedule.intervalIndex, 1)
        XCTAssertEqual(hinted.schedule.nextDueAt, Calendar.current.date(byAdding: .hour, value: 4, to: now.addingTimeInterval(120)))
        let revisit = try XCTUnwrap(relaunched.recordReviewResponse(subjectID: sceneID, response: .knewIt,
                                                                  sessionID: UUID(), at: now.addingTimeInterval(24 * 60 * 60)))
        XCTAssertEqual(revisit.schedule.intervalIndex, 2)
        XCTAssertEqual(relaunched.mastery(for: sceneID), .witnessed)
    }

    func testLegacyRecordsMigrateAndCorruptSnapshotKeepsHealthyLegacyBackup() throws {
        defaults.set([sceneID: MasteryState.understood.rawValue], forKey: "shivajiLessonStore.masteryByScene")
        var store = ShivajiLessonStore(defaults: defaults)
        XCTAssertEqual(store.mastery(for: sceneID), .understood)
        XCTAssertTrue(store.isUnlocked(SampleContent.birthFortCard))
        store.recordStoryExposure(for: sceneID, at: now)
        XCTAssertTrue(store.isUnlocked(SampleContent.birthFortCard))
        let entry = try XCTUnwrap(SampleContent.shivajiHeroArc.chronicleEntry(withID: "reward-birth-fort-card"))
        XCTAssertEqual(store.chronicleProgress(for: entry).detailLevel, .inked)
        let corrupt = Data("broken snapshot".utf8)
        defaults.set(corrupt, forKey: "shivajiLessonStore.snapshot.v1")
        store = ShivajiLessonStore(defaults: defaults)
        XCTAssertEqual(store.mastery(for: sceneID), .understood)
        XCTAssertEqual(defaults.data(forKey: "shivajiLessonStore.snapshot.v1.recovery"), corrupt)
    }

    func testOldEvidenceAndResumeDecodeWithoutNewOptionalFields() throws {
        let evidence = Data("{\"type\":\"recallSuccess\",\"recordedAt\":0,\"detail\":\"old\"}".utf8)
        let decoded = try JSONDecoder().decode(MasteryEvidence.self, from: evidence)
        XCTAssertNil(decoded.eventID)
        XCTAssertNil(decoded.support)
        let resume = Data("{\"sceneID\":\"scene-1-shivneri\",\"phase\":\"recall\"}".utf8)
        let point = try JSONDecoder().decode(LessonResumePoint.self, from: resume)
        XCTAssertFalse(point.recallCompleted)
        XCTAssertEqual(point.phase, .recall)
        XCTAssertEqual(point.completedMatchPairIDs, [])
        XCTAssertEqual(point.matchMismatchCount, 0)
    }

    func testAuthoredAliasesRequireCompleteAnswerAndMalformedScheduleDoesNotCrash() throws {
        let challenge = try XCTUnwrap(SampleContent.shivajiHeroArc.scene(withID: sceneID)?.primaryRecallChallenge)
        XCTAssertFalse(ChronicleQuizEngine.answerMatches("Shiv", challenge: challenge))
        XCTAssertFalse(ChronicleQuizEngine.answerMatches("Shivneri Fort Rajgad", challenge: challenge))
        XCTAssertTrue(ChronicleQuizEngine.answerMatches(" shivneri fort! ", challenge: challenge))
        let schedule = ReviewSchedule(subjectID: sceneID, subjectType: .scene, nextDueAt: now,
                                      intervalIndex: 999, stabilityBand: .new, difficultyAdjustment: 0, cadenceDays: [0, 1, 3])
        let result = SpacedReviewScheduler.schedule(schedule, after: .neededClue, promptHistory: [], now: now)
        XCTAssertEqual(result.schedule.intervalIndex, 2)
    }
}
