import XCTest
@testable import GreatsOfBharathaTV

final class TVPersistenceTests: XCTestCase {
    private let sceneID = "scene-1-shivneri"
    private let snapshotKey = "shivajiLessonStore.snapshot.v1"
    private let now = Date(timeIntervalSince1970: 1_780_000_000)
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "GreatsOfBharatha.TVTests." + UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func store(_ policy: LessonPersistencePolicy = .compactTV) -> ShivajiLessonStore {
        ShivajiLessonStore(defaults: defaults, persistencePolicy: policy)
    }

    private func assertWithinBudget(_ store: ShivajiLessonStore, file: StaticString = #filePath, line: UInt = #line) {
        let diagnostics = store.persistenceDiagnostics
        XCTAssertEqual(diagnostics.limitBytes, 256 * 1024, file: file, line: line)
        XCTAssertTrue(diagnostics.isWithinBudget, file: file, line: line)
        XCTAssertGreaterThan(diagnostics.snapshotBytes, 0, file: file, line: line)
        XCTAssertLessThanOrEqual(diagnostics.appOwnedDefaultsBytes, 256 * 1024, file: file, line: line)
        XCTAssertNil(diagnostics.statusMessage, file: file, line: line)
    }

    func testVersionOneMigrationPreservesLearningAndRemovesLegacyMirrorWrites() throws {
        let legacy = store(.standard)
        legacy.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                     support: .hinted, sessionID: UUID(), at: now)
        legacy.saveResumePoint(LessonResumePoint(sceneID: sceneID, phase: .reward, recallCompleted: true, updatedAt: now))
        let schedule = try XCTUnwrap(legacy.reviewSchedule(for: sceneID))
        let record = try XCTUnwrap(legacy.masteryRecord(for: sceneID))
        XCTAssertNotNil(defaults.data(forKey: "shivajiLessonStore.masteryRecords"))

        let migrated = store()
        XCTAssertEqual(migrated.masteryRecord(for: sceneID)?.state, record.state)
        XCTAssertEqual(migrated.masteryRecord(for: sceneID)?.successfulReviewCount, record.successfulReviewCount)
        XCTAssertEqual(migrated.reviewSchedule(for: sceneID), schedule)
        XCTAssertEqual(migrated.resumePoint(for: sceneID)?.recallCompleted, true)
        XCTAssertTrue(migrated.isUnlocked(SampleContent.birthFortCard))
        for key in ["shivajiLessonStore.masteryRecords", "shivajiLessonStore.reviewSchedules", "shivajiLessonStore.masteryByScene"] {
            XCTAssertNil(defaults.object(forKey: key), key)
        }
        let saved = try XCTUnwrap(defaults.data(forKey: snapshotKey))
        let document = try XCTUnwrap(JSONSerialization.jsonObject(with: saved) as? [String: Any])
        XCTAssertEqual(document["schemaVersion"] as? Int, 2)
        assertWithinBudget(migrated)
    }

    func testLegacyAchievementRemainsEarnedWithoutInventingIndependentRecall() throws {
        defaults.set([sceneID: MasteryState.understood.rawValue], forKey: "shivajiLessonStore.masteryByScene")
        let migrated = store()
        XCTAssertTrue(migrated.isUnlocked(SampleContent.birthFortCard))
        let record = try XCTUnwrap(migrated.masteryRecord(for: sceneID))
        XCTAssertEqual(record.state, .understood)
        XCTAssertFalse(record.evidenceLog.contains { $0.support == .independent })
        XCTAssertFalse(record.evidenceLog.contains { $0.type == .reviewSuccess })
        assertWithinBudget(migrated)
    }

    func testCorruptMainSnapshotRecoversHealthyLearningCheckpointAndSchedule() throws {
        let original = store()
        original.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                       sessionID: UUID(), at: now)
        var checkpoint = TVActivityCheckpoint(stage: .puzzle)
        checkpoint.storyBeatIndex = 2
        checkpoint.discoveredDetailIDs = [sceneID + "-discovery-1"]
        checkpoint.matchedPairIDs = ["match-shivneri-birth-fort"]
        original.saveResumePoint(LessonResumePoint(sceneID: sceneID, recallCompleted: true, tvCheckpoint: checkpoint, updatedAt: now))
        let schedule = try XCTUnwrap(original.reviewSchedule(for: sceneID))
        let recovery = try XCTUnwrap(defaults.data(forKey: snapshotKey + ".recovery"))
        XCTAssertLessThanOrEqual(recovery.count, 16 * 1024)
        defaults.set(Data("damaged snapshot".utf8), forKey: snapshotKey)

        let recovered = store()
        XCTAssertTrue(recovered.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(recovered.reviewSchedule(for: sceneID), schedule)
        XCTAssertEqual(recovered.resumePoint(for: sceneID)?.tvCheckpoint, checkpoint)
        assertWithinBudget(recovered)
    }

    func testFullJourneyRecoveryPreservesLatestRewardsSchedulesAndCompletedCheckpoints() throws {
        let original = store()
        for chapter in TVLearningContent.chapters {
            let sessionID = UUID()
            for beat in chapter.storyBeats {
                original.recordStoryExposure(for: chapter.id, detail: beat.text, sessionID: sessionID, at: now)
            }
            original.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: true,
                                           sessionID: sessionID, at: now)
            original.recordLearningOutcome(subjectID: chapter.id, activity: .match, wasSuccessful: true,
                                           sessionID: UUID(), at: now.addingTimeInterval(5))
            original.recordLearningOutcome(subjectID: chapter.id, activity: .review, wasSuccessful: true,
                                           sessionID: UUID(), at: now.addingTimeInterval(100))
            for clue in chapter.placeClues {
                original.recordLearningOutcome(subjectID: clue.id, subjectType: .location, activity: .mapPlacement,
                                               wasSuccessful: true, at: now)
            }
            original.recordLearningOutcome(subjectID: chapter.scene.rewardID, subjectType: .chronicle,
                                           activity: .albumPlacement, wasSuccessful: true, support: .selfReported, at: now)
            var checkpoint = TVActivityCheckpoint(stage: .keepsake, storyBeatIndex: 2)
            checkpoint.discoveredDetailIDs = Set(chapter.discoveries.map(\.id))
            checkpoint.solvedPlaceIDs = Set(chapter.placeClues.map(\.id))
            checkpoint.completedActivityIDs = Set((0..<10).map { chapter.id + "-activity-\($0)" }).union(["recall", "puzzle", "album"])
            for key in checkpoint.completedActivityIDs { _ = checkpoint.eventID(for: key) }
            if case .match(let pairs) = chapter.puzzle { checkpoint.matchedPairIDs = Set(pairs.map(\.id)) }
            if case .order(let cards) = chapter.puzzle { checkpoint.sequenceSlots = cards.map(\.id) }
            original.saveResumePoint(LessonResumePoint(sceneID: chapter.id, tvCheckpoint: checkpoint, updatedAt: now))
        }
        for card in TVLearningContent.timelineEvents {
            original.recordLearningOutcome(subjectID: card.id, subjectType: .timeline, activity: .timelinePlacement,
                                           wasSuccessful: true, at: now)
        }
        let hostID = "scene-6-raigad-coronation"
        var latest = try XCTUnwrap(original.resumePoint(for: hostID))
        var checkpoint = try XCTUnwrap(latest.tvCheckpoint)
        let timelineSession = UUID()
        for index in 0..<18 {
            let key = "timeline-review-full-\(timelineSession)-r\(index % 3)-" + TVLearningContent.timelineEvents[index % 7].id
            checkpoint.completedActivityIDs.insert(key)
            _ = checkpoint.eventID(for: key)
        }
        checkpoint.timelineCheckpoint = TVTimelineCheckpoint(mode: "full", roundIndex: 2,
            slots: TVLearningContent.fullTimelineRounds[2].map(\.id), completedRoundIndices: [0, 1, 2], sessionID: timelineSession)
        latest.tvCheckpoint = checkpoint
        latest.updatedAt = now.addingTimeInterval(200)
        original.saveResumePoint(latest)
        let expectedSchedules = original.reviewSchedulesBySubject
        let expectedPoints = original.resumePointsByScene
        let recovery = try XCTUnwrap(defaults.data(forKey: snapshotKey + ".recovery"))
        print("Full journey recovery bytes: \(recovery.count); main snapshot bytes: \(original.persistenceDiagnostics.snapshotBytes)")
        XCTAssertLessThanOrEqual(recovery.count, 16 * 1024)
        XCTAssertEqual(expectedPoints[hostID]?.tvCheckpoint?.completionEventIDs.count, 31)
        defaults.set(Data("corrupt after the complete family journey".utf8), forKey: snapshotKey)
        let restored = store()
        XCTAssertEqual(restored.reviewSchedulesBySubject, expectedSchedules)
        XCTAssertEqual(restored.resumePointsByScene, expectedPoints, "Recovery must represent the latest completed journey")
        for chapter in TVLearningContent.chapters {
            let entry = try XCTUnwrap(SampleContent.shivajiVerticalSlice.activeHeroArc.chronicleEntry(withID: chapter.scene.rewardID))
            XCTAssertEqual(restored.chronicleProgress(for: entry).detailLevel, .rememberedAgain)
            XCTAssertTrue(restored.masteryRecord(for: chapter.id)?.evidenceLog.contains {
                $0.type == .reviewSuccess && $0.support == .independent
            } ?? false)
        }
        assertWithinBudget(restored)
    }

    func testInvalidCompressedRecoveryLengthFallsBackWithoutInventingCheckedRecall() throws {
        for declaredLength: UInt32 in [0, 256 * 1024 + 1] {
            defaults.removePersistentDomain(forName: suiteName)
            defaults.set([sceneID: MasteryState.understood.rawValue], forKey: "shivajiLessonStore.masteryByScene")
            defaults.set(Data("damaged main".utf8), forKey: snapshotKey)
            var framed = Data("GBR2".utf8)
            framed.append(contentsOf: [UInt8(declaredLength >> 24), UInt8((declaredLength >> 16) & 255),
                                      UInt8((declaredLength >> 8) & 255), UInt8(declaredLength & 255)])
            framed.append(contentsOf: [0, 1, 2])
            defaults.set(framed, forKey: snapshotKey + ".recovery")
            let restored = store()
            XCTAssertTrue(restored.isUnlocked(SampleContent.birthFortCard))
            let record = try XCTUnwrap(restored.masteryRecord(for: sceneID))
            XCTAssertFalse(record.evidenceLog.contains { $0.support == .independent })
            XCTAssertFalse(TVLearningContent.hasCheckedLearning(TVLearningContent.chapters[0], store: restored))
            assertWithinBudget(restored)
        }
    }

    func testAllCheckpointStagesAndStableCompletionIDsRoundTrip() throws {
        let original = store()
        for stage in TVActivityStage.allCases {
            var checkpoint = TVActivityCheckpoint(stage: stage)
            checkpoint.storyBeatIndex = 2
            checkpoint.discoveredDetailIDs = ["hill", "guide"]
            checkpoint.solvedPlaceIDs = ["place-shivneri"]
            checkpoint.helpedActivityIDs = ["recall"]
            checkpoint.matchedPairIDs = ["match-shivneri-birth-fort"]
            checkpoint.completedActivityIDs = ["recall"]
            checkpoint.hintLevels = ["recall": 2]
            checkpoint.sequenceSlots = ["first", nil, "third"]
            checkpoint.selectedTileID = "second"
            let completionID = checkpoint.eventID(for: "recall")
            XCTAssertEqual(checkpoint.eventID(for: "recall"), completionID)
            let point = LessonResumePoint(sceneID: sceneID, recallCompleted: true, tvCheckpoint: checkpoint, updatedAt: now)
            original.saveResumePoint(point)
            let restored = try XCTUnwrap(store().resumePoint(for: sceneID))
            XCTAssertEqual(restored, point)
            XCTAssertEqual(restored.tvCheckpoint?.completionEventIDs["recall"], completionID)
        }
        let oldData = Data(#"{"sceneID":"scene-1-shivneri","phase":"recall"}"#.utf8)
        XCTAssertNil(try JSONDecoder().decode(LessonResumePoint.self, from: oldData).tvCheckpoint)
    }

    func testDuplicateSuccessfulOutcomeCannotRescheduleOrAwardTwiceAcrossRelaunch() throws {
        let eventID = UUID()
        let original = store()
        XCTAssertTrue(original.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                                     eventID: eventID, at: now))
        let before = try XCTUnwrap(original.masteryRecord(for: sceneID))
        let schedule = try XCTUnwrap(original.reviewSchedule(for: sceneID))
        let restored = store()
        XCTAssertFalse(restored.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                                      eventID: eventID, at: now.addingTimeInterval(100)))
        XCTAssertEqual(restored.masteryRecord(for: sceneID), before)
        XCTAssertEqual(restored.reviewSchedule(for: sceneID), schedule)
    }

    func testTimelineCheckpointDoesNotReplaceTheChapterPuzzle() throws {
        let original = store()
        var checkpoint = TVActivityCheckpoint(stage: .puzzle)
        checkpoint.sequenceSlots = ["chapter-first", nil, "chapter-third"]
        checkpoint.selectedTileID = "chapter-second"
        checkpoint.hintLevels = ["puzzle": 1]
        checkpoint.timelineCheckpoint = TVTimelineCheckpoint(mode: "full", roundIndex: 1,
            slots: ["timeline-pratapgad-turning-point", nil, nil], selectedCardID: "timeline-pressure-at-purandar",
            hintLevel: 2, helpedRoundIndices: [1], completedRoundIndices: [0])
        original.saveResumePoint(LessonResumePoint(sceneID: "scene-6-raigad-coronation", tvCheckpoint: checkpoint, updatedAt: now))
        let restored = try XCTUnwrap(store().resumePoint(for: "scene-6-raigad-coronation")?.tvCheckpoint)
        XCTAssertEqual(restored, checkpoint)
        XCTAssertEqual(restored.sequenceSlots, ["chapter-first", nil, "chapter-third"])
        XCTAssertEqual(restored.timelineCheckpoint?.slots, ["timeline-pratapgad-turning-point", nil, nil])
        assertWithinBudget(store())
    }

    func testRescueMarkersSurviveHintCompactionAndRelaunch() throws {
        let original = store()
        var checkpoint = TVActivityCheckpoint(stage: .puzzle)
        checkpoint.hintLevels = ["recall": 20, "puzzle": 20]
        checkpoint.helpedActivityIDs = ["recall", "recall-rescued", "puzzle", "puzzle-rescued"]
        original.saveResumePoint(LessonResumePoint(sceneID: sceneID, tvCheckpoint: checkpoint, updatedAt: now))
        original.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                       support: .rescued, at: now)
        original.recordLearningOutcome(subjectID: sceneID, activity: .match, wasSuccessful: true,
                                       support: .rescued, at: now.addingTimeInterval(5))
        let restored = store()
        let saved = try XCTUnwrap(restored.resumePoint(for: sceneID)?.tvCheckpoint)
        XCTAssertEqual(saved.hintLevels, ["recall": 3, "puzzle": 3])
        XCTAssertEqual(saved.helpedActivityIDs, checkpoint.helpedActivityIDs)
        let record = try XCTUnwrap(restored.masteryRecord(for: sceneID))
        XCTAssertTrue(record.evidenceLog.contains { $0.type == .recallSuccess && $0.support == .rescued })
        XCTAssertTrue(record.evidenceLog.contains { $0.type == .matchSuccess && $0.support == .rescued })
        XCTAssertLessThan(record.state, .remembered)
        XCTAssertFalse(record.evidenceLog.contains { $0.type == .reviewSuccess && $0.support == .independent })
        assertWithinBudget(restored)
    }

    func testCompletedCheckpointProtectsAnEventAfterRecentReplayRingRotates() throws {
        let original = store()
        var checkpoint = TVActivityCheckpoint(stage: .keepsake)
        let stableID = checkpoint.eventID(for: "keepsake")
        XCTAssertTrue(original.recordLearningOutcome(subjectID: sceneID, activity: .albumPlacement,
                                                     wasSuccessful: true, eventID: stableID, at: now))
        checkpoint.completedActivityIDs.insert("keepsake")
        original.saveResumePoint(LessonResumePoint(sceneID: sceneID, tvCheckpoint: checkpoint, updatedAt: now))
        // Remove this event from both the 256-entry recent ring and the compacted same-type witness.
        for index in 0..<300 {
            original.recordLearningOutcome(subjectID: sceneID, activity: .albumPlacement, wasSuccessful: true,
                                           eventID: UUID(), at: now.addingTimeInterval(Double(index + 1)))
        }
        let restored = store()
        XCTAssertFalse(restored.recordLearningOutcome(subjectID: sceneID, activity: .albumPlacement,
                                                      wasSuccessful: true, eventID: stableID, at: now.addingTimeInterval(400)))
        XCTAssertEqual(restored.resumePoint(for: sceneID)?.tvCheckpoint?.completionEventIDs["keepsake"], stableID)
        assertWithinBudget(restored)
    }

    func testWrongHintedAndSelfReportedActivityKeepTruthfulLearning() throws {
        let original = store()
        original.recordStoryExposure(for: sceneID, at: now)
        original.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: false, at: now)
        XCTAssertFalse(original.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(original.masteryRecord(for: sceneID)?.successfulReviewCount, 0)
        original.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true,
                                       support: .hinted, sessionID: UUID(), at: now)
        XCTAssertEqual(original.mastery(for: sceneID), .understood)
        let hinted = try XCTUnwrap(original.reviewSchedule(for: sceneID))
        XCTAssertEqual(hinted.nextDueAt, Calendar.current.date(byAdding: .hour, value: 4, to: now))
        original.recordReviewResponse(subjectID: sceneID, response: .knewIt, at: now.addingTimeInterval(100))
        let restored = store()
        XCTAssertEqual(restored.mastery(for: sceneID), .understood)
        XCTAssertFalse(restored.masteryRecord(for: sceneID)?.evidenceLog.contains { $0.type == .reviewSuccess } ?? true)
        assertWithinBudget(restored)
    }

    func testLongFamilyReplayPreservesEarnedFactsAndReviewTimingWithinBudget() throws {
        let original = store()
        let content = SampleContent.shivajiVerticalSlice
        let firstSession = UUID()
        for scene in content.scenes {
            original.recordLearningOutcome(subjectID: scene.id, activity: .recall, wasSuccessful: true,
                                           sessionID: firstSession, at: now)
            original.recordLearningOutcome(subjectID: scene.id, activity: .match, wasSuccessful: true,
                                           sessionID: firstSession, at: now.addingTimeInterval(5))
            original.recordLearningOutcome(subjectID: scene.id, activity: .review, wasSuccessful: true,
                                           sessionID: UUID(), at: now.addingTimeInterval(100))
        }
        let records = original.masteryRecordsBySubject
        let schedules = original.reviewSchedulesBySubject
        for index in 0..<3_000 {
            let scene = content.scenes[index % content.scenes.count]
            original.recordStoryExposure(for: scene.id, detail: String(repeating: "a memorable story ", count: 100),
                                         at: now.addingTimeInterval(Double(index + 200)))
            if index % 250 == 0 { assertWithinBudget(original) }
        }
        let restored = store()
        for scene in content.scenes {
            let record = try XCTUnwrap(restored.masteryRecord(for: scene.id))
            XCTAssertEqual(record.state, records[scene.id]?.state)
            XCTAssertEqual(record.successfulReviewCount, records[scene.id]?.successfulReviewCount)
            XCTAssertEqual(record.exposureCount, 500)
            XCTAssertTrue(record.evidenceLog.contains { $0.type == .recallSuccess })
            XCTAssertTrue(record.evidenceLog.contains { $0.type == .matchSuccess })
            XCTAssertTrue(record.evidenceLog.contains { $0.type == .reviewSuccess && $0.support == .independent })
            let entry = try XCTUnwrap(content.activeHeroArc.chronicleEntry(withID: scene.rewardID))
            XCTAssertEqual(restored.chronicleProgress(for: entry).detailLevel, .rememberedAgain)
        }
        XCTAssertEqual(restored.reviewSchedulesBySubject, schedules)
        XCTAssertEqual(restored.completedScenes, 6)
        assertWithinBudget(restored)
    }

    func testOverBudgetCandidateDoesNotOverwriteHealthySavedJourney() throws {
        let original = store()
        original.recordLearningOutcome(subjectID: sceneID, activity: .recall, wasSuccessful: true, at: now)
        let healthy = try XCTUnwrap(defaults.data(forKey: snapshotKey))
        defaults.set(Data(repeating: 1, count: 256 * 1024), forKey: "greatsOfBharatha.testOversizedValue")
        original.recordStoryExposure(for: sceneID, at: now.addingTimeInterval(10))
        XCTAssertEqual(defaults.data(forKey: snapshotKey), healthy)
        XCTAssertNotNil(original.persistenceDiagnostics.statusMessage)
        defaults.removeObject(forKey: "greatsOfBharatha.testOversizedValue")
        let restored = store()
        XCTAssertTrue(restored.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(restored.masteryRecord(for: sceneID)?.exposureCount, 0)
        assertWithinBudget(restored)
    }
}
