import XCTest
@testable import GreatsOfBharathaTV

final class TVLearningContentTests: XCTestCase {
    private let canonicalIDs = [
        "scene-1-shivneri",
        "scene-2-torna-rajgad",
        "scene-3-pratapgad-turning-point",
        "scene-4-purandar-agra",
        "scene-5-rajgad-recovery",
        "scene-6-raigad-coronation"
    ]

    func testSixTVChaptersResolveToCanonicalLessonsAndRewards() throws {
        let content = SampleContent.shivajiVerticalSlice
        XCTAssertEqual(TVLearningContent.chapters.map(\.id), canonicalIDs)
        XCTAssertEqual(TVLearningContent.chapters.map(\.number), Array(1...6))
        for chapter in TVLearningContent.chapters {
            let canonical = try XCTUnwrap(content.scenes.first { $0.id == chapter.id })
            XCTAssertEqual(chapter.scene.id, canonical.id)
            XCTAssertEqual(chapter.pilot.id, canonical.id)
            XCTAssertEqual(chapter.pilot.chronicleEntry.id, canonical.rewardID)
            XCTAssertFalse(chapter.storyBeats.isEmpty, chapter.id)
            XCTAssertFalse(chapter.discoveries.isEmpty, chapter.id)
            XCTAssertFalse(chapter.placeClues.isEmpty, chapter.id)
            XCTAssertFalse(chapter.familyPrompt.isEmpty, chapter.id)
            XCTAssertNotNil(TVLearningContent.chapter(sceneID: canonical.id))
        }
        XCTAssertNil(TVLearningContent.chapter(sceneID: "unknown-scene"))
    }

    func testTeachingExplainsEachAnswerBeforeRecall() throws {
        let requiredFacts = [
            ["Shivneri", "born"],
            ["Torna", "Rajgad", "capital"],
            ["Pratapgad", "turning point"],
            ["Purandar", "Agra"],
            ["rebuilt", "reorganized"],
            ["Raigad", "crowned"]
        ]
        var artwork: Set<String> = []
        for (index, chapter) in TVLearningContent.chapters.enumerated() {
            for fact in requiredFacts[index] {
                XCTAssertTrue(chapter.plan.teachingText.localizedCaseInsensitiveContains(fact), "\(chapter.id): \(fact)")
            }
            XCTAssertTrue(artwork.insert(try XCTUnwrap(chapter.plan.imageAsset)).inserted)
            let correct = try XCTUnwrap(chapter.plan.correctChoice)
            XCTAssertEqual(chapter.plan.choices.filter(\.isCorrect).count, 1)
            XCTAssertEqual(Set(chapter.plan.choices.map { LessonRecallEngine.normalized($0.title) }).count,
                           chapter.plan.choices.count)
            XCTAssertTrue(LessonRecallEngine.answerMatches(correct.title, challenge: chapter.pilot.quiz.challenge))
        }
    }

    func testMatchingTilesHaveUnambiguousLabelsAndCanonicalRewardSubjects() {
        var pairIDs: Set<String> = []
        for chapter in TVLearningContent.chapters {
            guard case let .match(pairs) = chapter.puzzle else { continue }
            XCTAssertFalse(pairs.isEmpty, chapter.id)
            XCTAssertEqual(Set(pairs.map { LessonRecallEngine.normalized($0.leftText) }).count, pairs.count)
            XCTAssertEqual(Set(pairs.map { LessonRecallEngine.normalized($0.rightText) }).count, pairs.count)
            for pair in pairs {
                XCTAssertTrue(pairIDs.insert(pair.id).inserted, "Duplicate pair \(pair.id)")
                XCTAssertFalse(pair.teachingClue.isEmpty)
                XCTAssertNotEqual(pair.leftID, pair.rightID)
            }
            XCTAssertTrue(chapter.pilot.reviewCards.allSatisfy { $0.sceneID == chapter.id })
        }
        XCTAssertFalse(pairIDs.isEmpty)
    }

    func testTornaAndRajgadHaveSeparatePlaceClues() throws {
        let chapter = try XCTUnwrap(TVLearningContent.chapter(sceneID: "scene-2-torna-rajgad"))
        let torna = try XCTUnwrap(chapter.placeClues.first { $0.id == "place-torna" })
        let rajgad = try XCTUnwrap(chapter.placeClues.first { $0.id == "place-rajgad" })
        XCTAssertNotEqual(LessonRecallEngine.normalized(torna.clue), LessonRecallEngine.normalized(rajgad.clue))
        XCTAssertTrue(torna.clue.localizedCaseInsensitiveContains("first"))
        XCTAssertTrue(rajgad.clue.localizedCaseInsensitiveContains("capital"))
        XCTAssertFalse(rajgad.clue.localizedCaseInsensitiveContains("birth"))
        XCTAssertEqual(LessonRecallEngine.normalized(rajgad.answer), LessonRecallEngine.normalized("Rajgad"))
    }

    func testTimelineCoversEveryCanonicalHistoricalEventExactlyOnce() {
        let events = TVLearningContent.timelineEvents
        XCTAssertEqual(events.map(\.id), SampleContent.shivajiVerticalSlice.activeHeroArc.timelineEvents.map(\.id))
        XCTAssertEqual(Set(events.map(\.id)).count, 7)
        XCTAssertEqual(Set(events.map(\.sceneID)), Set(canonicalIDs))
        XCTAssertTrue(events.allSatisfy { !$0.title.isEmpty && !$0.teachingText.isEmpty })
        let rounds = TVLearningContent.fullTimelineRounds
        XCTAssertTrue(rounds.allSatisfy { (2...3).contains($0.count) })
        XCTAssertEqual(Set(rounds.flatMap { $0 }.map(\.id)), Set(events.map(\.id)))
    }

    func testTimelineUnlockRequiresCheckedLearningRatherThanStoryExposure() throws {
        let suite = "gob.tv.timeline-content." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        for chapter in TVLearningContent.chapters.prefix(3) { store.recordStoryExposure(for: chapter.id) }
        XCTAssertTrue(TVLearningContent.timelineRounds(store: store).isEmpty)
        for chapter in TVLearningContent.chapters.prefix(2) {
            store.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: true)
        }
        XCTAssertTrue(TVLearningContent.timelineRounds(store: store).isEmpty)
        store.recordLearningOutcome(subjectID: canonicalIDs[2], activity: .recall, wasSuccessful: true, support: .hinted)
        XCTAssertEqual(TVLearningContent.timelineRounds(store: store).flatMap { $0 }.map(\.id),
                       Array(TVLearningContent.timelineEvents.prefix(3)).map(\.id))
        for chapter in TVLearningContent.chapters.suffix(3) {
            store.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: true)
        }
        XCTAssertEqual(TVLearningContent.timelineRounds(store: store), TVLearningContent.fullTimelineRounds)
    }

    func testImportedOrSelfReportedRecognitionKeepsRewardsWithoutUnlockingTheTimeline() throws {
        let suite = "gob.tv.timeline-import." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let firstChapters = Array(TVLearningContent.chapters.prefix(3))
        defaults.set(Dictionary(uniqueKeysWithValues: firstChapters.map { ($0.id, MasteryState.understood.rawValue) }),
                     forKey: "shivajiLessonStore.masteryByScene")
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        for chapter in firstChapters {
            XCTAssertEqual(store.mastery(for: chapter.id), .understood)
            let reward = try XCTUnwrap(SampleContent.shivajiVerticalSlice.rewards.first { $0.id == chapter.scene.rewardID })
            XCTAssertTrue(store.isUnlocked(reward), "Imported earned rewards remain earned")
            XCTAssertFalse(TVLearningContent.hasCheckedLearning(chapter, store: store))
            store.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: true, support: .selfReported)
            XCTAssertFalse(TVLearningContent.hasCheckedLearning(chapter, store: store))
        }
        XCTAssertTrue(TVLearningContent.timelineRounds(store: store).isEmpty)
        for (index, chapter) in firstChapters.enumerated() {
            store.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: true,
                                        support: index == 0 ? .rescued : .hinted)
            XCTAssertTrue(TVLearningContent.hasCheckedLearning(chapter, store: store))
        }
        XCTAssertEqual(TVLearningContent.timelineRounds(store: store), TVLearningContent.openingTimelineRounds)
    }
}
