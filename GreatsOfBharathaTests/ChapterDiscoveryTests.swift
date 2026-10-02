import XCTest
@testable import Greats_Of_Bharatha

@MainActor
final class ChapterDiscoveryTests: XCTestCase {
    private let canonicalIDs = [
        "scene-1-shivneri", "scene-2-torna-rajgad", "scene-3-pratapgad-turning-point",
        "scene-4-purandar-agra", "scene-5-rajgad-recovery", "scene-6-raigad-coronation"
    ]

    private func withDefaults(_ test: (UserDefaults) throws -> Void) throws {
        let suite = "gob.discovery.tests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try test(defaults)
    }

    func testAllSixChaptersHaveThreeCanonicalDiscoveriesAndTheirOwnPlaceClues() throws {
        XCTAssertEqual(ChapterDiscoveryContent.chapters.map(\.id), canonicalIDs)
        let source = SampleContent.shivajiVerticalSlice
        var discoveryIDs: Set<String> = []
        for chapter in ChapterDiscoveryContent.chapters {
            let scene = try XCTUnwrap(source.scenes.first { $0.id == chapter.id })
            XCTAssertEqual(chapter.discoveries.count, 3)
            XCTAssertEqual(chapter.discoveries.map(\.id), (1...3).map { chapter.id + "-discovery-\($0)" })
            XCTAssertEqual(Set(chapter.placeClues.map(\.id)), Set(scene.mapAnchors))
            XCTAssertFalse(chapter.teachingText.isEmpty)
            XCTAssertFalse(chapter.familyPrompt.isEmpty)
            for detail in chapter.discoveries {
                XCTAssertTrue(discoveryIDs.insert(detail.id).inserted)
                XCTAssertFalse(detail.title.isEmpty)
                XCTAssertFalse(detail.symbol.isEmpty)
                XCTAssertFalse(detail.text.isEmpty)
            }
            for clue in chapter.placeClues {
                let place = try XCTUnwrap(source.places.first { $0.id == clue.id })
                XCTAssertEqual(clue.answer, place.name)
                XCTAssertFalse(clue.clue.isEmpty)
                XCTAssertFalse(clue.hint.isEmpty)
            }
        }
        XCTAssertEqual(discoveryIDs.count, 18)
        XCTAssertNil(ChapterDiscoveryContent.chapter(sceneID: "unknown-scene"))
    }

    func testRajgadRetainsDifferentEarlyCapitalAndComebackClues() throws {
        let early = try XCTUnwrap(ChapterDiscoveryContent.chapter(sceneID: canonicalIDs[1])?.placeClue(placeID: "place-rajgad"))
        let later = try XCTUnwrap(ChapterDiscoveryContent.chapter(sceneID: canonicalIDs[4])?.placeClue(placeID: "place-rajgad"))
        XCTAssertEqual(early.id, later.id)
        XCTAssertTrue(early.clue.contains("Early Capital"))
        XCTAssertTrue(later.clue.contains("Comeback"))
        XCTAssertTrue(later.clue.contains("after Agra"))
        XCTAssertNotEqual(early.clue, later.clue)
    }

    func testDiscoveryExposurePersistsWithoutCheckedLearningOrScheduleAdvancement() throws {
        try withDefaults { defaults in
            var store = ShivajiLessonStore(defaults: defaults)
            for chapter in ChapterDiscoveryContent.chapters {
                let schedule = store.reviewSchedule(for: chapter.id)
                for detail in chapter.discoveries {
                    XCTAssertNotNil(ChapterDiscoveryInteraction.open(detail, content: chapter, store: store))
                }
                store = ShivajiLessonStore(defaults: defaults)
                let record = try XCTUnwrap(store.masteryRecord(for: chapter.id))
                XCTAssertEqual(record.state, .witnessed)
                XCTAssertEqual(record.exposureCount, 3)
                XCTAssertEqual(record.successfulReviewCount, 0)
                XCTAssertNil(record.lastReviewedAt)
                XCTAssertTrue(record.evidenceLog.allSatisfy { $0.type == .storyExposure })
                XCTAssertEqual(store.reviewSchedule(for: chapter.id), schedule)
                XCTAssertEqual(store.resumePoint(for: chapter.id)?.discoveredDetailIDs, Set(chapter.discoveries.map(\.id)))
                let scene = try XCTUnwrap(SampleContent.shivajiVerticalSlice.scenes.first { $0.id == chapter.id })
                let entry = try XCTUnwrap(SampleContent.shivajiHeroArc.chronicleEntry(withID: scene.rewardID))
                XCTAssertEqual(store.chronicleProgress(for: entry).unlockState, .silhouette)
            }
        }
    }

    func testReplayAfterRelaunchIsIdempotentAndPreservesCheckedLearning() throws {
        try withDefaults { defaults in
            let chapter = try XCTUnwrap(ChapterDiscoveryContent.chapters.first)
            let detail = try XCTUnwrap(chapter.discoveries.first)
            let store = ShivajiLessonStore(defaults: defaults)
            store.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: true, support: .hinted)
            ChapterDiscoveryInteraction.open(detail, content: chapter, store: store)
            let record = store.masteryRecord(for: chapter.id)
            let schedule = store.reviewSchedule(for: chapter.id)
            let point = store.resumePoint(for: chapter.id)
            let restored = ShivajiLessonStore(defaults: defaults)
            for _ in 0..<3 { ChapterDiscoveryInteraction.open(detail, content: chapter, store: restored) }
            XCTAssertEqual(restored.masteryRecord(for: chapter.id), record)
            XCTAssertEqual(restored.reviewSchedule(for: chapter.id), schedule)
            XCTAssertEqual(restored.resumePoint(for: chapter.id), point)
        }
    }

    func testTerminationBetweenEvidenceAndCheckpointDoesNotDuplicateExposure() throws {
        try withDefaults { defaults in
            let chapter = try XCTUnwrap(ChapterDiscoveryContent.chapters.last)
            let detail = try XCTUnwrap(chapter.discoveries.last)
            let store = ShivajiLessonStore(defaults: defaults)
            let point = LessonResumePoint(sceneID: chapter.id)
            store.saveResumePoint(point)
            let eventID = try XCTUnwrap(chapter.exposureEventID(discoveryID: detail.id, sessionID: point.sessionID))
            store.recordStoryExposure(for: chapter.id, detail: detail.text, eventID: eventID, sessionID: point.sessionID)
            // Termination before discoveredDetailIDs is saved: the next open retries the same event.
            let restored = ShivajiLessonStore(defaults: defaults)
            let recovered = try XCTUnwrap(ChapterDiscoveryInteraction.open(detail, content: chapter, store: restored))
            XCTAssertEqual(recovered.sessionID, point.sessionID)
            XCTAssertEqual(recovered.selectedDiscoveryDetailID, detail.id)
            XCTAssertEqual(recovered.discoveredDetailIDs, [detail.id])
            XCTAssertEqual(restored.masteryRecord(for: chapter.id)?.exposureCount, 1)
            XCTAssertEqual(restored.masteryRecord(for: chapter.id)?.evidenceLog.map(\.eventID), [eventID])
            XCTAssertEqual(restored.mastery(for: chapter.id), .witnessed)
        }
    }

    func testOpeningDiscoveryPreservesOtherActivitiesAndLegacyExposureIDs() throws {
        try withDefaults { defaults in
            let chapter = try XCTUnwrap(ChapterDiscoveryContent.chapters.first)
            let detail = try XCTUnwrap(chapter.discoveries.first)
            let store = ShivajiLessonStore(defaults: defaults)
            var point = LessonResumePoint(sceneID: chapter.id, phase: .recall, revealedHintLevel: 2,
                recallCompleted: true, completedMatchPairIDs: ["match-shivneri-birth-fort"], preferredActivity: .match,
                discoveredDetailIDs: ["hill", "gate", "book"], solvedPlaceIDs: ["place-shivneri"], helpedPlaceIDs: ["place-shivneri"],
                tvCheckpoint: TVActivityCheckpoint(stage: .puzzle))
            store.saveResumePoint(point)
            let result = try XCTUnwrap(ChapterDiscoveryInteraction.open(detail, content: chapter, store: store))
            point.discoveredDetailIDs.insert(detail.id)
            point.selectedDiscoveryDetailID = detail.id
            point.updatedAt = result.updatedAt
            XCTAssertEqual(result, point)
        }
    }

    func testStableExposureIdentityIsScopedToSessionAndCanonicalDiscovery() throws {
        let session = UUID()
        let anotherSession = UUID()
        var ids: Set<UUID> = []
        for chapter in ChapterDiscoveryContent.chapters {
            for detail in chapter.discoveries {
                let first = try XCTUnwrap(chapter.exposureEventID(discoveryID: detail.id, sessionID: session))
                XCTAssertEqual(first, chapter.exposureEventID(discoveryID: detail.id, sessionID: session))
                XCTAssertTrue(ids.insert(first).inserted)
                XCTAssertNotEqual(first, chapter.exposureEventID(discoveryID: detail.id, sessionID: anotherSession))
            }
            XCTAssertNil(chapter.exposureEventID(discoveryID: "unknown-discovery", sessionID: session))
        }
        XCTAssertEqual(ids.count, 18)
    }

    func testUnknownOrAlteredDiscoveryCannotCreateEvidence() throws {
        try withDefaults { defaults in
            let chapter = try XCTUnwrap(ChapterDiscoveryContent.chapters.first)
            let store = ShivajiLessonStore(defaults: defaults)
            let forged = ChapterDiscovery(id: chapter.discoveries[0].id, title: "Synthetic", symbol: "book", text: "Synthetic")
            XCTAssertNil(ChapterDiscoveryInteraction.open(forged, content: chapter, store: store))
            XCTAssertNil(store.masteryRecord(for: chapter.id))
            XCTAssertNil(store.resumePoint(for: chapter.id))
        }
    }

    func testSavedSelectionRestoresExactDetailAndLegacyExposureIsRetained() throws {
        try withDefaults { defaults in
            let chapter = try XCTUnwrap(ChapterDiscoveryContent.chapters.first)
            let store = ShivajiLessonStore(defaults: defaults)
            var legacy = LessonResumePoint(sceneID: chapter.id, discoveredDetailIDs: ["hill", "gate", "book"])
            legacy.selectedDiscoveryDetailID = "book"
            store.saveResumePoint(legacy)
            XCTAssertEqual(chapter.openedDiscoveryIDs(in: legacy.discoveredDetailIDs), Set(chapter.discoveries.map(\.id)))
            let selected = try XCTUnwrap(chapter.restoredDiscovery(id: legacy.selectedDiscoveryDetailID))
            XCTAssertEqual(selected.id, chapter.id + "-discovery-2")
            ChapterDiscoveryInteraction.open(selected, content: chapter, store: store)
            let restored = ShivajiLessonStore(defaults: defaults)
            let point = try XCTUnwrap(restored.resumePoint(for: chapter.id))
            XCTAssertEqual(point.selectedDiscoveryDetailID, selected.id)
            XCTAssertTrue(point.discoveredDetailIDs.isSuperset(of: legacy.discoveredDetailIDs))
            XCTAssertNil(restored.masteryRecord(for: chapter.id))
            XCTAssertNil(chapter.restoredDiscovery(id: "another-chapter-discovery"))
        }
    }

    func testPreparedSelectionWithoutExposureRecoversOnce() throws {
        try withDefaults { defaults in
            let chapter = try XCTUnwrap(ChapterDiscoveryContent.chapters.last)
            let detail = try XCTUnwrap(chapter.discoveries.first)
            let store = ShivajiLessonStore(defaults: defaults)
            var prepared = LessonResumePoint(sceneID: chapter.id)
            prepared.selectedDiscoveryDetailID = detail.id
            store.saveResumePoint(prepared)
            // The UI restores this prepared selection and finishes exposure after interruption.
            let restored = ShivajiLessonStore(defaults: defaults)
            ChapterDiscoveryInteraction.open(detail, content: chapter, store: restored)
            ChapterDiscoveryInteraction.open(detail, content: chapter, store: restored)
            XCTAssertEqual(restored.resumePoint(for: chapter.id)?.sessionID, prepared.sessionID)
            XCTAssertEqual(restored.resumePoint(for: chapter.id)?.selectedDiscoveryDetailID, detail.id)
            XCTAssertEqual(restored.masteryRecord(for: chapter.id)?.exposureCount, 1)
            XCTAssertEqual(restored.mastery(for: chapter.id), .witnessed)
        }
    }
}
