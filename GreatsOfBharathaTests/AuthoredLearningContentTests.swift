import XCTest
@testable import Greats_Of_Bharatha

final class AuthoredLearningContentTests: XCTestCase {
    func testSixLessonsHaveDistinctChoicesAndOneCorrectIdentity() throws {
        let content = SampleContent.shivajiVerticalSlice
        XCTAssertEqual(content.scenes.count, 6)
        for scene in content.scenes {
            let plan = SampleContent.learningPlan(for: scene)
            XCTAssertGreaterThanOrEqual(plan.choices.count, 2, scene.id)
            XCTAssertEqual(plan.choices.filter(\.isCorrect).count, 1, scene.id)
            XCTAssertEqual(Set(plan.choices.map(\.id)).count, plan.choices.count)
            XCTAssertEqual(Set(plan.choices.map { LessonRecallEngine.normalized($0.title) }).count, plan.choices.count)
            let correct = try XCTUnwrap(plan.correctChoice)
            let challenge = try XCTUnwrap(content.activeHeroArc.scene(withID: scene.id)?.primaryRecallChallenge)
            XCTAssertTrue(LessonRecallEngine.answerMatches(correct.title, challenge: challenge), scene.id)
            XCTAssertTrue(plan.isCorrect(choiceID: correct.id))
            XCTAssertFalse(plan.isCorrect(choiceID: "unknown"))
            for choice in plan.choices where !choice.isCorrect {
                XCTAssertFalse(plan.isCorrect(choiceID: choice.id))
                XCTAssertFalse(LessonRecallEngine.answerMatches(choice.title, challenge: challenge), scene.id)
            }
            XCTAssertFalse(plan.choices.contains { $0.title.hasPrefix("place-") })
        }
    }

    func testEveryQuizHasExplicitTeachingAndAppropriateSceneArt() throws {
        let content = SampleContent.shivajiVerticalSlice
        let required: [String: [String]] = [
            "scene-1-shivneri": ["Shivneri", "born"],
            "scene-2-torna-rajgad": ["Torna", "Rajgad", "capital"],
            "scene-3-pratapgad-turning-point": ["Pratapgad", "turning point"],
            "scene-4-purandar-agra": ["First", "Purandar", "later", "Agra"],
            "scene-5-rajgad-recovery": ["rebuilt", "reorganized"],
            "scene-6-raigad-coronation": ["Raigad", "crowned"],
        ]
        var assets: Set<String> = []
        for scene in content.scenes {
            let plan = SampleContent.learningPlan(for: scene)
            for fact in try XCTUnwrap(required[scene.id]) {
                XCTAssertTrue(plan.teachingText.localizedCaseInsensitiveContains(fact), "\(scene.id): \(fact)")
            }
            XCTAssertTrue(assets.insert(try XCTUnwrap(plan.imageAsset)).inserted)
        }
    }

    func testPilotSubjectsAndRewardsResolveToCanonicalRegistry() throws {
        let content = SampleContent.shivajiVerticalSlice
        XCTAssertEqual(LearnQuizPilotData.scenes.count, 6)
        for scene in LearnQuizPilotData.scenes {
            let canonical = try XCTUnwrap(content.scenes.first(where: { $0.id == scene.id }))
            XCTAssertEqual(scene.chronicleEntry.id, canonical.rewardID)
            XCTAssertEqual(scene.chronicleEntry.state, .silhouette)
            XCTAssertTrue(content.activeHeroArc.chronicleEntries.contains { $0.id == scene.chronicleEntry.id })
            XCTAssertTrue(scene.reviewCards.allSatisfy { $0.sceneID == canonical.id })
            // Repeated identical cards made the old multi-pair set ambiguous.
            XCTAssertEqual(Set(scene.matchPairs.map(\.leftText)).count, scene.matchPairs.count)
            XCTAssertEqual(Set(scene.matchPairs.map(\.rightText)).count, scene.matchPairs.count)
            XCTAssertEqual(scene.quiz.options.filter { $0 == scene.quiz.correctAnswer }.count, 1)
        }
    }
}
