import Foundation

enum ChapterKnowledgeResponseContext: String, Codable, Sendable {
    case individualRecognition, sharedFamilyRecognition
}

enum ChapterKnowledgeCheckSupport: String, Codable, Sendable {
    case noClue, withClue, answerSeen
}

enum ChapterKnowledgeEvidenceKind: String, Codable, Sendable {
    case teachingExposure, choiceCheck
}

struct ChapterKnowledgeEvidence: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: ChapterKnowledgeEvidenceKind
    let sceneID: String
    let sessionID: UUID
    let recordedAt: Date
    let claimIDs: [String]
    var beatID: String?
    var questionID: String?
    var turnID: UUID?
    var selectedChoiceID: String?
    var wasSuccessful = false
    var support: ChapterKnowledgeCheckSupport = .noClue
    var responseContext: ChapterKnowledgeResponseContext?
}

struct ChapterKnowledgeTeachingCheckpoint: Codable, Equatable, Sendable {
    let sceneID: String
    var activeBeatID: String?
    var shownBeatIDs: Set<String> = []
    var taughtClaimIDs: Set<String> = []
    var evidence: [ChapterKnowledgeEvidence] = []
}

enum ChapterKnowledgePracticePhase: String, Codable, Sendable {
    case needsTeaching, prompt, result, complete, unavailable
}

struct ChapterKnowledgePracticeTurn: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let questionID: String
    var helpWasRequested = false
    var hintLevel = 0
    var answerWasSeen = false
    var wasPreviouslyChecked = false
    var checks: [ChapterKnowledgeEvidence] = []
}

struct ChapterKnowledgePracticeCheckpoint: Codable, Equatable, Sendable {
    let sceneID: String
    let sessionID: UUID
    let responseContext: ChapterKnowledgeResponseContext
    var queue: [ChapterKnowledgePracticeTurn]
    var cursor = 0
    var phase: ChapterKnowledgePracticePhase = .needsTeaching
    var selectedChoiceID: String?

    var currentTurn: ChapterKnowledgePracticeTurn? { queue.indices.contains(cursor) ? queue[cursor] : nil }
    var currentResult: ChapterKnowledgeEvidence? { currentTurn?.checks.last }
    var canTryAgain: Bool {
        phase == .result && currentResult?.wasSuccessful == false &&
            (currentTurn?.checks.count ?? .max) < ChapterKnowledgeJourney.maximumAttemptsPerTurn
    }
}

/// Opaque storage is kept outside chapter continuation. No raw answer text is retained.
struct ChapterKnowledgeArchive: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var teachingBySceneID: [String: ChapterKnowledgeTeachingCheckpoint] = [:]
    var practiceBySceneID: [String: ChapterKnowledgePracticeCheckpoint] = [:]
    var checkedQuestionIDs: Set<String> = []
    var pendingEvidence: [ChapterKnowledgeEvidence] = []

    var retainedEvidence: [ChapterKnowledgeEvidence] {
        teachingBySceneID.values.flatMap(\.evidence) + practiceBySceneID.values.flatMap { $0.queue.flatMap(\.checks) }
    }

    var isSupported: Bool {
        guard schemaVersion == 1, teachingBySceneID.count <= 6, practiceBySceneID.count <= 6,
              checkedQuestionIDs.count <= 48, pendingEvidence.count <= 1 else { return false }
        for (sceneID, point) in teachingBySceneID {
            guard !sceneID.isEmpty, sceneID == point.sceneID, point.shownBeatIDs.count <= 32,
                  point.taughtClaimIDs.count <= 48, point.evidence.count <= 48,
                  point.evidence.allSatisfy({ $0.sceneID == sceneID && $0.kind == .teachingExposure }) else { return false }
        }
        for (sceneID, point) in practiceBySceneID {
            guard !sceneID.isEmpty, sceneID == point.sceneID, point.queue.count <= 8,
                  Set(point.queue.map(\.id)).count == point.queue.count,
                  Set(point.queue.map(\.questionID)).count == point.queue.count,
                  (0...point.queue.count).contains(point.cursor) else { return false }
            for turn in point.queue {
                guard !turn.questionID.isEmpty, (0...3).contains(turn.hintLevel),
                      turn.checks.count <= ChapterKnowledgeJourney.maximumAttemptsPerTurn,
                      turn.checks.allSatisfy({ $0.sceneID == sceneID && $0.sessionID == point.sessionID &&
                          $0.kind == .choiceCheck && $0.questionID == turn.questionID && $0.turnID == turn.id &&
                          $0.responseContext == point.responseContext && $0.selectedChoiceID != nil }) else { return false }
            }
        }
        let retained = retainedEvidence
        return Set(retained.map(\.id)).count == retained.count && pendingEvidence.allSatisfy(retained.contains)
    }
}

enum ChapterKnowledgeJourney {
    static let maximumAttemptsPerTurn = 3

    static func begin(_ archive: ChapterKnowledgeArchive, definition: ChapterKnowledgeDefinition,
                      sessionID: UUID, context: ChapterKnowledgeResponseContext,
                      restartCompleted: Bool = false) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition) else { return archive }
        if let existing = archive.practiceBySceneID[definition.sceneID],
           existing.phase != .complete || !restartCompleted {
            return resume(archive, definition: definition)
        }
        let approved = definition.questionsEligible(afterShownBeatIDs: Set(definition.beats.map(\.id)),
                                                   taughtClaimIDs: Set(definition.claims.map(\.id)))
        guard !approved.isEmpty, approved.count <= 8 else { return archive }
        var next = archive
        next.practiceBySceneID[definition.sceneID] = ChapterKnowledgePracticeCheckpoint(sceneID: definition.sceneID,
            sessionID: sessionID, responseContext: context, queue: approved.map {
                ChapterKnowledgePracticeTurn(id: UUID(), questionID: $0.id, answerWasSeen: archive.checkedQuestionIDs.contains($0.id),
                                             wasPreviouslyChecked: archive.checkedQuestionIDs.contains($0.id))
            })
        return resume(next, definition: definition)
    }

    static func resume(_ archive: ChapterKnowledgeArchive, definition: ChapterKnowledgeDefinition) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), var point = archive.practiceBySceneID[definition.sceneID] else { return archive }
        var next = archive
        if point.currentTurn == nil {
            point.phase = .complete
        } else if !definition.questionsEligible(afterShownBeatIDs: Set(definition.beats.map(\.id)),
            taughtClaimIDs: Set(definition.claims.map(\.id))).contains(where: { $0.id == point.currentTurn?.questionID }) {
            point.phase = .unavailable
        } else if point.phase == .needsTeaching || point.phase == .unavailable {
            let teaching = next.teachingBySceneID[definition.sceneID]
            let eligible = definition.questionsEligible(afterShownBeatIDs: teaching?.shownBeatIDs ?? [],
                                                        taughtClaimIDs: teaching?.taughtClaimIDs ?? [])
            point.phase = eligible.contains { $0.id == point.currentTurn?.questionID } ? .prompt : .needsTeaching
        }
        next.practiceBySceneID[definition.sceneID] = point
        return next
    }

    /// The view calls this only after these specific fact cards were presented, not on scene entry.
    static func presentedBeat(_ beatID: String, visibleClaimIDs: Set<String>, sessionID: UUID,
                              archive: ChapterKnowledgeArchive, definition: ChapterKnowledgeDefinition,
                              now: Date) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), let beat = definition.beats.first(where: { $0.id == beatID }),
              visibleClaimIDs == Set(beat.claimIDs), !visibleClaimIDs.isEmpty,
              definition.claims.filter({ visibleClaimIDs.contains($0.id) }).allSatisfy({ $0.reviewStatus == .approved }) else { return archive }
        var next = archive
        var teaching = next.teachingBySceneID[definition.sceneID] ?? ChapterKnowledgeTeachingCheckpoint(sceneID: definition.sceneID)
        guard teaching.evidence.count < 48 else { return archive }
        let newlyTaught = visibleClaimIDs.subtracting(teaching.taughtClaimIDs)
        teaching.activeBeatID = beatID
        teaching.shownBeatIDs.insert(beatID)
        teaching.taughtClaimIDs.formUnion(visibleClaimIDs)
        if !newlyTaught.isEmpty {
            let event = ChapterKnowledgeEvidence(id: UUID(), kind: .teachingExposure, sceneID: definition.sceneID,
                sessionID: sessionID, recordedAt: now, claimIDs: newlyTaught.sorted(), beatID: beatID)
            teaching.evidence.append(event)
            next.pendingEvidence.append(event)
        }
        next.teachingBySceneID[definition.sceneID] = teaching
        return next
    }

    static func select(_ choiceID: String?, archive: ChapterKnowledgeArchive,
                       definition: ChapterKnowledgeDefinition) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), var point = archive.practiceBySceneID[definition.sceneID],
              point.phase == .prompt, let question = definition.questions.first(where: { $0.id == point.currentTurn?.questionID }),
              choiceID == nil || question.choices.contains(where: { $0.id == choiceID }) else { return archive }
        var next = archive
        point.selectedChoiceID = choiceID
        next.practiceBySceneID[definition.sceneID] = point
        return next
    }

    static func requestHelp(_ archive: ChapterKnowledgeArchive,
                            definition: ChapterKnowledgeDefinition) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), var point = archive.practiceBySceneID[definition.sceneID],
              point.phase == .prompt, let question = definition.questions.first(where: { $0.id == point.currentTurn?.questionID }) else { return archive }
        point.queue[point.cursor].helpWasRequested = true
        point.queue[point.cursor].hintLevel = min(point.queue[point.cursor].hintLevel + 1, min(question.hints.count, 3))
        var next = archive
        next.practiceBySceneID[definition.sceneID] = point
        return next
    }

    static func check(_ archive: ChapterKnowledgeArchive, definition: ChapterKnowledgeDefinition,
                      now: Date) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), var point = archive.practiceBySceneID[definition.sceneID],
              point.phase == .prompt, let turn = point.currentTurn, turn.checks.count < maximumAttemptsPerTurn,
              let question = definition.questions.first(where: { $0.id == turn.questionID }),
              let selected = point.selectedChoiceID, question.choices.contains(where: { $0.id == selected }) else { return archive }
        let teaching = archive.teachingBySceneID[definition.sceneID]
        guard definition.questionsEligible(afterShownBeatIDs: teaching?.shownBeatIDs ?? [],
              taughtClaimIDs: teaching?.taughtClaimIDs ?? []).contains(where: { $0.id == question.id }) else { return archive }
        let success = selected == question.correctChoiceID
        let support: ChapterKnowledgeCheckSupport = turn.answerWasSeen ? .answerSeen : (turn.helpWasRequested ? .withClue : .noClue)
        let event = ChapterKnowledgeEvidence(id: success ? turn.id : UUID(), kind: .choiceCheck, sceneID: definition.sceneID,
            sessionID: point.sessionID, recordedAt: now, claimIDs: question.claimIDs, questionID: question.id,
            turnID: turn.id, selectedChoiceID: selected, wasSuccessful: success, support: support, responseContext: point.responseContext)
        point.queue[point.cursor].checks.append(event)
        point.queue[point.cursor].answerWasSeen = true
        point.phase = .result
        point.selectedChoiceID = nil
        var next = archive
        next.checkedQuestionIDs.insert(question.id)
        next.practiceBySceneID[definition.sceneID] = point
        next.pendingEvidence.append(event)
        return next
    }

    static func tryAgain(_ archive: ChapterKnowledgeArchive,
                         definition: ChapterKnowledgeDefinition) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), var point = archive.practiceBySceneID[definition.sceneID],
              point.canTryAgain else { return archive }
        point.phase = .prompt
        point.selectedChoiceID = nil
        var next = archive
        next.practiceBySceneID[definition.sceneID] = point
        return next
    }

    static func advance(_ archive: ChapterKnowledgeArchive,
                        definition: ChapterKnowledgeDefinition) -> ChapterKnowledgeArchive {
        guard canChange(archive, definition: definition), var point = archive.practiceBySceneID[definition.sceneID],
              point.phase == .result else { return archive }
        point.cursor += 1
        point.selectedChoiceID = nil
        point.phase = .needsTeaching
        var next = archive
        next.practiceBySceneID[definition.sceneID] = point
        return resume(next, definition: definition)
    }

    static func acknowledge(_ eventID: UUID, archive: ChapterKnowledgeArchive) -> ChapterKnowledgeArchive {
        var next = archive
        next.pendingEvidence.removeAll { $0.id == eventID }
        return next
    }

    private static func canChange(_ archive: ChapterKnowledgeArchive, definition: ChapterKnowledgeDefinition) -> Bool {
        archive.isSupported && archive.pendingEvidence.isEmpty && definition.validationIssues.isEmpty
    }
}

@MainActor
struct ChapterKnowledgeHooks {
    let load: () -> ChapterKnowledgeArchive
    let save: (ChapterKnowledgeArchive) -> Bool
    let record: (ChapterKnowledgeEvidence) -> Bool
}

@MainActor
enum ChapterKnowledgePersistence {
    /// UI state advances only to a confirmed archive. Any unacknowledged event remains replayable.
    static func saveAndReplay(_ proposed: ChapterKnowledgeArchive, hooks: ChapterKnowledgeHooks) -> ChapterKnowledgeArchive? {
        guard hooks.save(proposed) else { return nil }
        var confirmed = proposed
        for event in proposed.pendingEvidence {
            guard hooks.record(event) else { break }
            let acknowledged = ChapterKnowledgeJourney.acknowledge(event.id, archive: confirmed)
            guard hooks.save(acknowledged) else { break }
            confirmed = acknowledged
        }
        return confirmed
    }
}
