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

    func testEveryChapterHasThreeDistinctDiscoveriesAndLegacyIDsRemainStable() throws {
        let scenes = SampleContent.shivajiVerticalSlice.scenes
        for scene in scenes {
            let details = SampleContent.learningPlan(for: scene).discoveryDetails
            XCTAssertEqual(details.count, 3, scene.id)
            XCTAssertEqual(Set(details.map(\.id)).count, 3, scene.id)
            XCTAssertEqual(Set(details.map(\.title)).count, 3, scene.id)
            for detail in details {
                XCTAssertFalse(detail.text.isEmpty, scene.id)
                XCTAssertFalse(detail.symbol.isEmpty, scene.id)
                XCTAssertFalse(detail.title.hasPrefix("place-"), scene.id)
            }
        }
        let first = try XCTUnwrap(scenes.first)
        XCTAssertEqual(SampleContent.learningPlan(for: first).discoveryDetails.map(\.id), ["hill", "gate", "book"])
        let fourth = try XCTUnwrap(scenes.first { $0.number == 4 })
        let order = try XCTUnwrap(SampleContent.learningPlan(for: fourth).discoveryDetails.first { $0.id == "order" })
        XCTAssertTrue(order.text.contains("Purandar first, Agra later"))
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

    func testCombinedMatchingDisplayDisambiguatesRajgadWithoutChangingAnswerIdentities() throws {
        let pairs = LearnQuizPilotData.scenes.flatMap(\.matchPairs)
        let presentation = ChronicleMatchPresentation(pairs: pairs)
        let tiles = ChronicleMatchEngine.tiles(for: pairs)
        let leftTiles = tiles.filter { $0.side == .left }
        let rightTiles = tiles.filter { $0.side == .right }

        XCTAssertEqual(presentation.leftTitle, "Places")
        XCTAssertEqual(presentation.rightTitle, "Memory clues")
        XCTAssertEqual(leftTiles.filter { $0.text == "Rajgad" }.count, 2)
        XCTAssertEqual(Set(leftTiles.map { presentation.displayText(for: $0) }).count, pairs.count)
        XCTAssertEqual(Set(rightTiles.map { presentation.displayText(for: $0) }).count, pairs.count)
        let early = try XCTUnwrap(leftTiles.first { $0.pairID == "match-rajgad-early-capital" })
        let comeback = try XCTUnwrap(leftTiles.first { $0.pairID == "match-rajgad-comeback" })
        XCTAssertEqual(presentation.displayText(for: early), "Rajgad · early fort building")
        XCTAssertEqual(presentation.displayText(for: comeback), "Rajgad · after Agra")
        XCTAssertEqual(early.text, "Rajgad")
        XCTAssertEqual(comeback.text, "Rajgad")
        XCTAssertTrue(rightTiles.allSatisfy { presentation.displayText(for: $0) == $0.text })
        // Context labels teach which chapter a card comes from; the partner remains a choice.
        XCTAssertFalse(presentation.displayText(for: early).contains("Early Capital"))
        XCTAssertFalse(presentation.displayText(for: comeback).contains("Comeback"))
    }

    func testMatchingPanelLanguageSupportsPeopleFortsAndMixedConcepts() {
        let kinds: [(ChronicleMatchPresentationKind, (left: String, right: String))] = [
            (.peopleAndPlaces, ("People and places", "Story clues")),
            (.fortsAndMemoryClues, ("Forts", "Memory clues")),
            (.storyAndMeaning, ("Story cards", "What they mean"))
        ]
        for (kind, titles) in kinds {
            let presentation = ChronicleMatchPresentation(pairs: [], kind: kind)
            XCTAssertEqual(presentation.leftTitle, titles.left)
            XCTAssertEqual(presentation.rightTitle, titles.right)
            XCTAssertFalse(presentation.leftInstruction.isEmpty)
            XCTAssertFalse(presentation.rightInstruction.isEmpty)
            XCTAssertTrue(presentation.instruction.contains("either panel"))
        }
    }

    func testMatchingReplayFeedbackRestoresChosenContextAndRetainsAssistedTeaching() throws {
        let pairs = LearnQuizPilotData.scenes.flatMap(\.matchPairs)
        let presentation = ChronicleMatchPresentation(pairs: pairs)
        let pair = try XCTUnwrap(pairs.first { $0.id == "match-rajgad-comeback" })
        let tile = try XCTUnwrap(ChronicleMatchEngine.tiles(for: pairs).first { $0.id == pair.leftID })
        let selectedMessage = "Chosen: Rajgad · after Agra. Find its partner in the other panel."

        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(selectedTileID: tile.id)), selectedMessage)
        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(selectedTileID: tile.id, lastOutcome: .selected(tile))), selectedMessage)
        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(selectedTileID: tile.id, lastOutcome: .ignored)), selectedMessage)
        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(selectedTileID: tile.id,
            lastOutcome: .mismatched(clue: pair.teachingClue))), "Let's look again. " + pair.teachingClue)
        let rescuedMessage = "We placed this pair together. " + pair.teachingClue
        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(completedPairIDs: [pair.id],
            lastOutcome: .matched(pairID: pair.id, feedback: rescuedMessage, completedSet: false))), rescuedMessage)
        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(selectedTileID: "retired-card")), presentation.instruction)
        XCTAssertEqual(presentation.feedback(for: ChronicleMatchState(selectedTileID: tile.id,
            completedPairIDs: [pair.id])), presentation.instruction)
    }

    func testCombinedMatchingResumePrioritizesEarlierSelectedOwnerFromEitherPanel() {
        let earlier = LearnQuizPilotData.scenes[1]
        let later = LearnQuizPilotData.scenes[4]
        let pair = earlier.matchPairs[0]
        for selectedID in [pair.leftID, pair.rightID] {
            let selected = LessonResumePoint(sceneID: earlier.id, selectedMatchTileID: selectedID,
                preferredActivity: .match, updatedAt: Date(timeIntervalSince1970: 1))
            let lastWritten = LessonResumePoint(sceneID: later.id, preferredActivity: .match,
                updatedAt: Date(timeIntervalSince1970: 2))
            let next = LearnQuizMatchingResume.nextScene(in: [earlier, later], resumePoints: [selected, lastWritten])
            XCTAssertEqual(next?.id, earlier.id, "Continue must show the child's chosen source rather than the last written scene")
        }
    }

    func testCombinedMatchingResumeRejectsUnknownForeignAndCompletedSelectedSources() {
        let earlier = LearnQuizPilotData.scenes[1]
        let later = LearnQuizPilotData.scenes[4]
        let pair = earlier.matchPairs[0]
        let lastWritten = LessonResumePoint(sceneID: later.id, preferredActivity: .match, updatedAt: Date(timeIntervalSince1970: 2))
        for selectedID in ["retired-card", LearnQuizPilotData.scenes[0].matchPairs[0].leftID, pair.leftID] {
            let completed: Set<String> = selectedID == pair.leftID ? [pair.id] : []
            let invalidSource = LessonResumePoint(sceneID: earlier.id, completedMatchPairIDs: completed,
                selectedMatchTileID: selectedID, preferredActivity: .match, updatedAt: Date(timeIntervalSince1970: 1))
            let next = LearnQuizMatchingResume.nextScene(in: [earlier, later], resumePoints: [invalidSource, lastWritten])
            XCTAssertEqual(next?.id, later.id, "Unavailable sources must fall back to the most recent unfinished matching scene")
        }
    }

    func testCombinedMatchingResumeExcludesCompletedMatchingAndOtherActivities() {
        let completedScene = LearnQuizPilotData.scenes[1]
        let recallScene = LearnQuizPilotData.scenes[4]
        let completed = LessonResumePoint(sceneID: completedScene.id, completedMatchPairIDs: Set(completedScene.matchPairs.map(\.id)),
            selectedMatchTileID: completedScene.matchPairs[0].leftID, preferredActivity: .match)
        let recall = LessonResumePoint(sceneID: recallScene.id, selectedMatchTileID: recallScene.matchPairs[0].rightID,
            preferredActivity: .recall)

        XCTAssertNil(LearnQuizMatchingResume.nextScene(in: [completedScene, recallScene], resumePoints: [completed, recall]))
        XCTAssertNil(LearnQuizMatchingResume.nextScene(in: [completedScene, recallScene], resumePoints: []))
    }

    func testInterruptedCombinedCheckpointWritesChooseNewestValidSelectedOwner() {
        let earlier = LearnQuizPilotData.scenes[1]
        let later = LearnQuizPilotData.scenes[4]
        let newSelection = LessonResumePoint(sceneID: earlier.id, selectedMatchTileID: earlier.matchPairs[0].leftID,
            preferredActivity: .match, updatedAt: Date(timeIntervalSince1970: 2))
        let oldSelection = LessonResumePoint(sceneID: later.id, selectedMatchTileID: later.matchPairs[0].rightID,
            preferredActivity: .match, updatedAt: Date(timeIntervalSince1970: 1))

        XCTAssertEqual(LearnQuizMatchingResume.nextScene(in: [earlier, later], resumePoints: [newSelection, oldSelection])?.id, earlier.id)
    }
}
