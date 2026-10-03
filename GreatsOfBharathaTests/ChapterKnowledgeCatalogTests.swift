import XCTest
@testable import Greats_Of_Bharatha

final class ChapterKnowledgeCatalogTests: XCTestCase {
    func testAllAuthoredChaptersHaveCompleteResolvableCatalogs() {
        XCTAssertEqual(ChapterKnowledgeCatalog.definitions.count, 6)
        XCTAssertEqual(ChapterKnowledgeCatalog.definitions.flatMap(\.claims).count, 36)
        XCTAssertEqual(ChapterKnowledgeCatalog.definitions.flatMap(\.questions).count, 24)
        XCTAssertTrue(ChapterKnowledgeCatalog.validationIssues.isEmpty, ChapterKnowledgeCatalog.validationIssues.joined(separator: "\n"))
        for definition in ChapterKnowledgeCatalog.definitions {
            XCTAssertEqual(definition.beats.count, 3)
            XCTAssertEqual(definition.questions.count, 4)
            XCTAssertEqual(ChapterKnowledgeCatalog.definition(sceneID: definition.sceneID), definition)
        }
        XCTAssertNil(ChapterKnowledgeCatalog.definition(sceneID: "unknown-scene"))
    }

    func testPendingChildCopyCannotStartPracticeOrAwardTeaching() {
        for approved in ChapterKnowledgeCatalog.definitions {
            let definition = ChapterKnowledgeDefinition(sceneID: approved.sceneID, claims: approved.claims.map {
                ChapterKnowledgeClaim(id: $0.id, kind: $0.kind, statement: $0.statement, citations: $0.citations,
                    taughtBeatIDs: $0.taughtBeatIDs, reviewStatus: .pendingIndependentReview)
            }, beats: approved.beats, questions: approved.questions)
            let archive = ChapterKnowledgeArchive()
            let begun = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: UUID(), context: .individualRecognition)
            XCTAssertEqual(begun, archive)
            for beat in definition.beats {
                let proposed = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(),
                    archive: archive, definition: definition, now: .distantPast)
                XCTAssertEqual(proposed, archive)
            }
            XCTAssertTrue(definition.claims.allSatisfy { $0.reviewStatus == .pendingIndependentReview })
        }
    }

    func testEveryChapterPresentsFourQuestionsAfterActualTeachingInBothContexts() throws {
        for authored in ChapterKnowledgeCatalog.definitions {
            let definition = approvedFixture(authored)
            for context in [ChapterKnowledgeResponseContext.individualRecognition, .sharedFamilyRecognition] {
                let sessionID = UUID()
                var archive = ChapterKnowledgeJourney.begin(ChapterKnowledgeArchive(), definition: definition,
                                                           sessionID: sessionID, context: context)
                XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.phase, .needsTeaching)
                archive = teachAll(definition, sessionID: sessionID, archive: archive)
                archive = ChapterKnowledgeJourney.resume(archive, definition: definition)
                var visited = Set<String>()
                for question in definition.questions {
                    let point = try XCTUnwrap(archive.practiceBySceneID[definition.sceneID])
                    XCTAssertEqual(point.phase, .prompt)
                    XCTAssertEqual(point.currentTurn?.questionID, question.id)
                    XCTAssertEqual(point.responseContext, context)
                    XCTAssertEqual(point.sessionID, sessionID)
                    visited.insert(question.id)
                    archive = ChapterKnowledgeJourney.select(question.correctChoiceID, archive: archive, definition: definition)
                    XCTAssertTrue(archive.pendingEvidence.isEmpty)
                    archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: .distantPast)
                    let result = try XCTUnwrap(archive.pendingEvidence.first)
                    XCTAssertTrue(result.wasSuccessful)
                    XCTAssertEqual(result.responseContext, context)
                    XCTAssertEqual(result.support, .noClue)
                    archive = ChapterKnowledgeJourney.acknowledge(result.id, archive: archive)
                    archive = ChapterKnowledgeJourney.advance(archive, definition: definition)
                }
                XCTAssertEqual(visited.count, 4)
                XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.phase, .complete)
                XCTAssertTrue(archive.isSupported)
            }
        }
    }

    func testOldBeatReceiptsWithoutNewFactExposureStayAtTeachingGate() {
        for authored in ChapterKnowledgeCatalog.definitions {
            let definition = approvedFixture(authored)
            var archive = ChapterKnowledgeArchive()
            archive.teachingBySceneID[definition.sceneID] = ChapterKnowledgeTeachingCheckpoint(sceneID: definition.sceneID,
                shownBeatIDs: Set(definition.beats.map(\.id)))
            archive = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: UUID(), context: .individualRecognition)
            XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.phase, .needsTeaching)
            XCTAssertTrue(archive.pendingEvidence.isEmpty)
        }
    }

    func testAuthoredWrongHelpedRetryStaysTruthfulAfterRoundTrip() throws {
        for authored in ChapterKnowledgeCatalog.definitions {
            let definition = approvedFixture(authored)
            let sessionID = UUID()
            var archive = teachAll(definition, sessionID: sessionID, archive: ChapterKnowledgeArchive())
            archive = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: sessionID, context: .sharedFamilyRecognition)
            let question = try XCTUnwrap(definition.questions.first)
            let wrongChoice = try XCTUnwrap(question.choices.first { $0.id != question.correctChoiceID })
            archive = ChapterKnowledgeJourney.requestHelp(archive, definition: definition)
            archive = ChapterKnowledgeJourney.select(wrongChoice.id, archive: archive, definition: definition)
            archive = try JSONDecoder().decode(ChapterKnowledgeArchive.self, from: JSONEncoder().encode(archive))
            XCTAssertEqual(archive.practiceBySceneID[definition.sceneID]?.selectedChoiceID, wrongChoice.id)
            archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: .distantPast)
            let wrong = try XCTUnwrap(archive.pendingEvidence.first)
            XCTAssertFalse(wrong.wasSuccessful)
            XCTAssertEqual(wrong.support, .withClue)
            archive = ChapterKnowledgeJourney.acknowledge(wrong.id, archive: archive)
            archive = ChapterKnowledgeJourney.tryAgain(archive, definition: definition)
            archive = ChapterKnowledgeJourney.select(question.correctChoiceID, archive: archive, definition: definition)
            archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: .distantPast)
            let correct = try XCTUnwrap(archive.pendingEvidence.first)
            XCTAssertTrue(correct.wasSuccessful)
            XCTAssertEqual(correct.support, .answerSeen)
            XCTAssertEqual(correct.responseContext, .sharedFamilyRecognition)
            XCTAssertNotEqual(correct.id, wrong.id)
        }
    }

    func testActiveTeachingPositionDoesNotCreateExposureAndPreservesOtherChapters() {
        let definition = ChapterKnowledgeCatalog.definitions[0]
        var archive = ChapterKnowledgeArchive()
        let otherScene = ChapterKnowledgeCatalog.definitions[1].sceneID
        archive.teachingBySceneID[otherScene] = ChapterKnowledgeTeachingCheckpoint(sceneID: otherScene, activeBeatID: otherScene + "-memory")
        let active = ChapterKnowledgeJourney.activateTeachingBeat(definition.beats[1].id, archive: archive, definition: definition)
        XCTAssertEqual(active.teachingBySceneID[definition.sceneID]?.activeBeatID, definition.beats[1].id)
        XCTAssertTrue(active.teachingBySceneID[definition.sceneID]?.shownBeatIDs.isEmpty == true)
        XCTAssertTrue(active.teachingBySceneID[definition.sceneID]?.taughtClaimIDs.isEmpty == true)
        XCTAssertTrue(active.retainedEvidence.isEmpty)
        XCTAssertTrue(active.pendingEvidence.isEmpty)
        XCTAssertEqual(active.teachingBySceneID[otherScene], archive.teachingBySceneID[otherScene])
        XCTAssertEqual(ChapterKnowledgeJourney.activateTeachingBeat("retired", archive: active, definition: definition), active)
        archive.schemaVersion = 99
        XCTAssertEqual(ChapterKnowledgeJourney.activateTeachingBeat(definition.beats[0].id, archive: archive, definition: definition), archive)
    }

    func testActiveTeachingPositionCannotBypassPendingOutbox() throws {
        let definition = approvedFixture(ChapterKnowledgeCatalog.definitions[0])
        let beat = definition.beats[0]
        let archive = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: UUID(),
            archive: ChapterKnowledgeArchive(), definition: definition, now: .distantPast)
        XCTAssertNotNil(try XCTUnwrap(archive.pendingEvidence.first))
        XCTAssertEqual(ChapterKnowledgeJourney.activateTeachingBeat(definition.beats[1].id, archive: archive, definition: definition), archive)
    }

    func testAllSixBoundedRetryJourneysFitExistingOptionalStorageBudget() throws {
        var archive = ChapterKnowledgeArchive()
        for authored in ChapterKnowledgeCatalog.definitions {
            let definition = approvedFixture(authored)
            let sessionID = UUID()
            archive = teachAll(definition, sessionID: sessionID, archive: archive)
            archive = ChapterKnowledgeJourney.begin(archive, definition: definition, sessionID: sessionID, context: .sharedFamilyRecognition)
            for question in definition.questions {
                let wrong = try XCTUnwrap(question.choices.first { $0.id != question.correctChoiceID })
                for attempt in 0..<ChapterKnowledgeJourney.maximumAttemptsPerTurn {
                    archive = ChapterKnowledgeJourney.select(attempt == 2 ? question.correctChoiceID : wrong.id,
                                                             archive: archive, definition: definition)
                    archive = ChapterKnowledgeJourney.check(archive, definition: definition, now: Date())
                    XCTAssertTrue(archive.isSupported)
                    XCTAssertLessThanOrEqual(try JSONEncoder().encode(archive).count, 64 * 1024)
                    let event = try XCTUnwrap(archive.pendingEvidence.first)
                    archive = ChapterKnowledgeJourney.acknowledge(event.id, archive: archive)
                    if attempt < 2 { archive = ChapterKnowledgeJourney.tryAgain(archive, definition: definition) }
                }
                archive = ChapterKnowledgeJourney.advance(archive, definition: definition)
            }
        }
        XCTAssertEqual(archive.practiceBySceneID.count, 6)
        XCTAssertEqual(archive.retainedEvidence.count, 90)
        XCTAssertTrue(archive.practiceBySceneID.values.allSatisfy { $0.phase == .complete })
    }

    func testSourceRegisterRetainsQualifiedEditionsAndResolvesEveryCitation() throws {
        XCTAssertEqual(ChapterKnowledgeSourceCatalog.sources.count, 8)
        XCTAssertEqual(Set(ChapterKnowledgeSourceCatalog.sources.map(\.id)).count, 8)
        let standardFour = try XCTUnwrap(ChapterKnowledgeSourceCatalog.source(id: "balbharati-std4"))
        XCTAssertTrue(standardFour.edition?.contains("revised September 2016") == true)
        for claim in ChapterKnowledgeCatalog.definitions.flatMap(\.claims) {
            for citation in claim.citations {
                let source = try XCTUnwrap(ChapterKnowledgeSourceCatalog.source(id: citation.sourceID))
                XCTAssertEqual(source.url.scheme, "https")
                XCTAssertFalse(source.title.isEmpty)
                XCTAssertFalse(source.publisher.isEmpty)
                XCTAssertFalse(citation.locator.isEmpty)
            }
        }
    }

    private func approvedFixture(_ original: ChapterKnowledgeDefinition) -> ChapterKnowledgeDefinition {
        // Construct an explicit approved fixture so status changes can be tested separately from the engine.
        ChapterKnowledgeDefinition(sceneID: original.sceneID, claims: original.claims.map {
            ChapterKnowledgeClaim(id: $0.id, kind: $0.kind, statement: $0.statement, citations: $0.citations,
                                  taughtBeatIDs: $0.taughtBeatIDs, reviewStatus: .approved)
        }, beats: original.beats, questions: original.questions)
    }

    private func teachAll(_ definition: ChapterKnowledgeDefinition, sessionID: UUID,
                          archive: ChapterKnowledgeArchive) -> ChapterKnowledgeArchive {
        var next = archive
        for beat in definition.beats {
            next = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: sessionID,
                archive: next, definition: definition, now: .distantPast)
            for event in next.pendingEvidence { next = ChapterKnowledgeJourney.acknowledge(event.id, archive: next) }
        }
        return next
    }
}
