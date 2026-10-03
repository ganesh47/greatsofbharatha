import XCTest
@testable import GreatsOfBharatha

final class ChapterKnowledgeModelsTests: XCTestCase {
    private let sceneID = "scene-1-shivneri"

    func testLegacyIndicesResolveOriginalBeatsAfterInsertionAndReordering() {
        let expandedIDs = [sceneID + "-knowledge-water", sceneID + "-meaning",
                           sceneID + "-story", sceneID + "-knowledge-gates", sceneID + "-memory"]
        for (index, role) in [LegacyChapterStoryRole.story, .memory, .meaning].enumerated() {
            let result = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: nil,
                                                          legacyIndex: index, availableBeatIDs: expandedIDs)
            XCTAssertEqual(result.beatID, role.beatID(sceneID: sceneID))
            XCTAssertEqual(result.reason, .legacyIndex)
        }
    }

    func testStableBeatIDWinsOverLegacyIndex() {
        let stableID = sceneID + "-knowledge-water"
        let result = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: stableID,
                                                      legacyIndex: 2, availableBeatIDs: [stableID, sceneID + "-story"])
        XCTAssertEqual(result, ChapterStoryBeatResolution(beatID: stableID, reason: .stableID))
    }

    func testInvalidLegacyIndexClampsWithinFrozenThreeBeats() {
        let IDs = [sceneID + "-knowledge-extra"] + LegacyChapterStoryRole.allCases.map { $0.beatID(sceneID: sceneID) }
        let low = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: nil, legacyIndex: -4, availableBeatIDs: IDs)
        let high = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: nil, legacyIndex: 100, availableBeatIDs: IDs)
        XCTAssertEqual(low, ChapterStoryBeatResolution(beatID: sceneID + "-story", reason: .clampedLegacyIndex))
        XCTAssertEqual(high, ChapterStoryBeatResolution(beatID: sceneID + "-meaning", reason: .clampedLegacyIndex))
    }

    func testRetiredStableIDHasExplicitOpeningFallback() {
        let result = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: sceneID + "-retired",
                                                      legacyIndex: 2, availableBeatIDs: [sceneID + "-story", sceneID + "-meaning"])
        XCTAssertEqual(result, ChapterStoryBeatResolution(beatID: sceneID + "-story", reason: .retiredStableID))
    }

    func testUnavailableLegacyOrRetiredBeatNeverSelectsUnrelatedExpandedBeat() {
        let IDs = [sceneID + "-knowledge-extra"]
        let legacy = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: nil, legacyIndex: 1, availableBeatIDs: IDs)
        let retired = ChapterStoryBeatMigration.resolve(sceneID: sceneID, persistedBeatID: "retired", legacyIndex: 0, availableBeatIDs: IDs)
        XCTAssertEqual(legacy, ChapterStoryBeatResolution(beatID: nil, reason: .unavailable))
        XCTAssertEqual(retired, ChapterStoryBeatResolution(beatID: nil, reason: .unavailable))
    }

    func testOldShownBeatReceiptDoesNotQualifyNewClaim() {
        let definition = fixture()
        XCTAssertTrue(definition.validationIssues.isEmpty)
        XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: []).isEmpty)
    }

    func testTaughtClaimWithoutRequiredBeatDoesNotQualify() {
        let definition = fixture()
        XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: [], taughtClaimIDs: [claim().id]).isEmpty)
    }

    func testApprovedTaughtClaimAndBeatQualify() {
        let definition = fixture()
        XCTAssertEqual(definition.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: [claim().id]),
                       definition.questions)
    }

    func testPendingHeldTraditionAndReflectionNeverQualify() {
        for status in [ChapterKnowledgeReviewStatus.pendingIndependentReview, .held] {
            let definition = fixture(claims: [claim(status: status)])
            XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: [claim().id]).isEmpty)
        }
        for kind in [ChapterKnowledgeClaimKind.tradition, .reflection] {
            let definition = fixture(claims: [claim(kind: kind)])
            XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: [claim().id]).isEmpty)
        }
    }

    func testDuplicateClaimsFailClosedWithoutDictionaryTrap() {
        let definition = fixture(claims: [claim(), claim()])
        XCTAssertFalse(definition.validationIssues.isEmpty)
        XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: [claim().id]).isEmpty)
    }

    func testUnresolvedTeachingReferenceAndMissingLegacyBeatFailClosed() {
        let wrongBeat = ChapterKnowledgeBeat(id: sceneID + "-story", title: "Fixture", text: "Fixture teaching", claimIDs: ["unknown"])
        let definition = fixture(beats: [wrongBeat])
        XCTAssertTrue(definition.validationIssues.contains { $0.hasPrefix("Missing legacy beat:") })
        XCTAssertTrue(definition.validationIssues.contains { $0.hasPrefix("Claim not taught by declared beat:") })
        XCTAssertTrue(definition.validationIssues.contains { $0.hasPrefix("Unknown beat claim:") })
        XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: [claim().id]).isEmpty)
    }

    func testQuestionCannotCheckMissingCorrectChoiceOrUntaughtCoverage() {
        let invalid = question(correctChoiceID: "missing", requiredBeatIDs: [sceneID + "-meaning"])
        let definition = fixture(questions: [invalid])
        XCTAssertTrue(definition.validationIssues.contains { $0.hasPrefix("Invalid correct choice:") })
        XCTAssertTrue(definition.validationIssues.contains { $0.hasPrefix("Question teaching coverage mismatch:") })
        XCTAssertTrue(definition.questionsEligible(afterShownBeatIDs: Set(definition.beats.map(\.id)), taughtClaimIDs: [claim().id]).isEmpty)
    }

    func testDefinitionRoundTripPreservesIdentityReviewAndCoverage() throws {
        let original = fixture(claims: [claim(status: .pendingIndependentReview)])
        let restored = try JSONDecoder().decode(ChapterKnowledgeDefinition.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        XCTAssertTrue(restored.questionsEligible(afterShownBeatIDs: [sceneID + "-story"], taughtClaimIDs: [claim().id]).isEmpty)
    }

    private func claim(status: ChapterKnowledgeReviewStatus = .approved,
                       kind: ChapterKnowledgeClaimKind = .historical) -> ChapterKnowledgeClaim {
        ChapterKnowledgeClaim(id: sceneID + "-fact-fixture", kind: kind,
                              statement: "Synthetic fixture, not an authored historical fact.",
                              citations: [ChapterKnowledgeCitation(sourceID: "fixture-source", locator: "fixture")],
                              taughtBeatIDs: [sceneID + "-story"], reviewStatus: status)
    }

    private func question(correctChoiceID: String = "fixture-choice-a", requiredBeatIDs: [String]? = nil) -> ChapterKnowledgeQuestion {
        ChapterKnowledgeQuestion(id: sceneID + "-knowledge-question-fixture", kind: .identity, prompt: "Fixture question",
                                 choices: [ChapterKnowledgeChoice(id: "fixture-choice-a", text: "Choice A"),
                                           ChapterKnowledgeChoice(id: "fixture-choice-b", text: "Choice B")],
                                 correctChoiceID: correctChoiceID, claimIDs: [claim().id],
                                 requiredBeatIDs: requiredBeatIDs ?? [sceneID + "-story"],
                                 explanation: "Fixture explanation", hints: ["Fixture hint"], retryFeedback: "Try the clue")
    }

    private func fixture(claims: [ChapterKnowledgeClaim]? = nil, beats: [ChapterKnowledgeBeat]? = nil,
                         questions: [ChapterKnowledgeQuestion]? = nil) -> ChapterKnowledgeDefinition {
        let defaultBeats = LegacyChapterStoryRole.allCases.map { role in
            ChapterKnowledgeBeat(id: role.beatID(sceneID: sceneID), title: "Fixture title", text: "Fixture teaching",
                                 claimIDs: role == .story ? [claim().id] : [])
        }
        return ChapterKnowledgeDefinition(sceneID: sceneID, claims: claims ?? [claim()],
                                          beats: beats ?? defaultBeats, questions: questions ?? [question()])
    }
}
