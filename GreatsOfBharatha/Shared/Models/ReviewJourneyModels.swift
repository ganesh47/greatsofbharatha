import Foundation

/// Content is supplied from existing authored cards. No historical answers are generated here.
struct ReviewJourneyCard: Identifiable, Codable, Equatable {
    let id: String
    let sceneID: String
    let promptType: RecallPromptType
    let front: String
    let back: String
    let meaning: String
    let checkPrompts: [ReviewJourneyCheckPrompt]
    let cadenceDays: [Int]
}

struct ReviewJourneyCheckPrompt: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let promptType: RecallPromptType
    let acceptedAnswers: [String]
}

enum ReviewJourneyEvidenceKind: String, Codable, Equatable {
    case selfReported, freshChecked, laterIndependentRecall, helpedChecked, incorrectChecked, reteachingExposure
}

enum ReviewJourneyResponseContext: String, Codable, Equatable {
    case sharedFamilyRecognition
}

struct ReviewJourneyEvidence: Identifiable, Codable, Equatable {
    let id: UUID
    let sessionID: UUID
    let cardID: String
    let sceneID: String
    let promptType: RecallPromptType
    let checkedPromptID: String?
    let kind: ReviewJourneyEvidenceKind
    let support: LearningSupport
    let wasSuccessful: Bool
    let response: LearningReviewResponse?
    let recordedAt: Date
    var priorIndependentWitness: ReviewJourneyRecallWitness?
    var responseContext: ReviewJourneyResponseContext?
    var selectedChoiceID: String?

    /// Validate a durable pending claim without consulting the witness overwritten by this response.
    var hasValidLaterIndependentWitness: Bool {
        guard kind == .laterIndependentRecall, wasSuccessful, support == .independent, responseContext == nil,
              let previous = priorIndependentWitness, let checkedPromptID,
              previous.sessionID != sessionID, previous.promptID != checkedPromptID else { return false }
        return recordedAt.timeIntervalSince(previous.recordedAt) >= 24 * 60 * 60
    }
}

struct ReviewJourneyRecallWitness: Codable, Equatable {
    let sessionID: UUID
    let recordedAt: Date
    let promptID: String
}

enum ReviewJourneyPhase: String, Codable, Equatable {
    case prompt, revealed, result, teaching, complete
}

struct ReviewJourneyTurn: Identifiable, Codable, Equatable {
    let id: UUID
    let teachingEventID: UUID
    let cardID: String
    let isTaughtRevisit: Bool
    var checkedPromptID: String?

    init(cardID: String, isTaughtRevisit: Bool = false, checkedPromptID: String? = nil) {
        id = UUID()
        teachingEventID = UUID()
        self.cardID = cardID
        self.isTaughtRevisit = isTaughtRevisit
        self.checkedPromptID = checkedPromptID
    }
}

struct ReviewJourneyCheckpoint: Codable, Equatable {
    let sessionID: UUID
    let startedAt: Date
    var queue: [ReviewJourneyTurn]
    var cursor = 0
    var phase: ReviewJourneyPhase = .prompt
    var typedAnswer = ""
    var helped = false
    var requeuedCardIDs: Set<String> = []
    var evidence: [ReviewJourneyEvidence] = []
    // Optional additions decode older archives without retaining an individual's identity or typed answer history.
    var selectedChoiceID: String?
    var helpWasRequested: Bool?
    var sharedFamilyResponse: Bool?

    var currentTurn: ReviewJourneyTurn? {
        queue.indices.contains(cursor) ? queue[cursor] : nil
    }
    var currentEvidence: ReviewJourneyEvidence? {
        guard let turn = currentTurn else { return nil }
        return evidence.first { $0.id == turn.id }
    }
}

/// Persist this separately from LessonResumePoint: review must never replace chapter/TV checkpoints.
/// The outbox makes a save-before-callback interruption safe to reconcile with the shared evidence store.
struct ReviewJourneyArchive: Codable, Equatable {
    var schemaVersion = 1
    var checkpoint: ReviewJourneyCheckpoint?
    var schedulesByCardID: [String: ReviewSchedule] = [:]
    var independentWitnessesByCardID: [String: ReviewJourneyRecallWitness] = [:]
    var lastScheduledSessionByCardID: [String: UUID] = [:]
    var pendingEvidence: [ReviewJourneyEvidence] = []
}

/// The integration owner supplies these using the same isolated defaults and TV budget as AppModel.
/// save must confirm a durable write; record returns true for a saved event OR an already-recorded ID.
@MainActor
struct ReviewJourneyHooks {
    let load: () -> ReviewJourneyArchive
    let save: (ReviewJourneyArchive) -> Bool
    let record: (ReviewJourneyEvidence) -> Bool
}

@MainActor
enum ReviewJourneyPersistence {
    /// Return only the latest confirmed archive. An unacknowledged event remains safe to replay by ID.
    static func saveAndReplay(_ proposed: ReviewJourneyArchive, hooks: ReviewJourneyHooks) -> ReviewJourneyArchive? {
        guard hooks.save(proposed) else { return nil }
        var saved = proposed
        for event in proposed.pendingEvidence {
            guard hooks.record(event) else { break }
            let acknowledged = ReviewJourneyEngine.acknowledge(event.id, in: saved)
            guard hooks.save(acknowledged) else { break }
            saved = acknowledged
        }
        return saved
    }
}

enum ReviewJourneyEngine {
    enum Selection { case due, practiceLearned }
    static let maximumInitialCards = 32
    static let maximumQueuedTurns = 64
    static let maximumPendingEvidence = 128

    static func start(
        archive: ReviewJourneyArchive,
        cards: [ReviewJourneyCard],
        learnedSceneIDs: Set<String>,
        sceneSchedules: [String: ReviewSchedule],
        selection: Selection = .due,
        sessionID: UUID = UUID(),
        now: Date
    ) -> ReviewJourneyArchive {
        var next = archive
        // An older session's durable outbox must be acknowledged before replacing its validation checkpoint.
        guard next.pendingEvidence.isEmpty else { return next }
        var uniqueIDs: Set<String> = []
        let learned = cards.filter { learnedSceneIDs.contains($0.sceneID) && uniqueIDs.insert($0.id).inserted }
        // Seed each card once. Preserve its own cadence and identity rather than repeatedly resetting it.
        for card in learned where next.schedulesByCardID[card.id] == nil {
            let inherited = sceneSchedules[card.sceneID]
            next.schedulesByCardID[card.id] = ReviewSchedule(subjectID: card.sceneID, subjectType: .scene,
                nextDueAt: inherited?.nextDueAt ?? now, intervalIndex: 0, stabilityBand: .new,
                difficultyAdjustment: 0, cadenceDays: card.cadenceDays.isEmpty ? [0, 1, 3, 7, 14] : card.cadenceDays)
        }
        let ordered = learned.filter { card in
            selection == .practiceLearned || (next.schedulesByCardID[card.id]?.nextDueAt ?? .distantFuture) <= now
        }.sorted { left, right in
            let leftDate = next.schedulesByCardID[left.id]?.nextDueAt ?? .distantFuture
            let rightDate = next.schedulesByCardID[right.id]?.nextDueAt ?? .distantFuture
            return leftDate == rightDate ? left.id < right.id : leftDate < rightDate
        }
        next.checkpoint = ReviewJourneyCheckpoint(sessionID: sessionID, startedAt: now,
            queue: ordered.prefix(maximumInitialCards).map { card in
                ReviewJourneyTurn(cardID: card.id, checkedPromptID: checkPrompt(for: card,
                    avoiding: next.independentWitnessesByCardID[card.id]?.promptID)?.id)
            })
        if ordered.isEmpty { next.checkpoint?.phase = .complete }
        return next
    }

    static func resume(_ archive: ReviewJourneyArchive, cards: [ReviewJourneyCard], learnedSceneIDs: Set<String>) -> ReviewJourneyArchive {
        var next = archive
        guard var point = next.checkpoint else { return next }
        point.queue = Array(point.queue.prefix(maximumQueuedTurns))
        let allowed = Set(cards.filter { learnedSceneIDs.contains($0.sceneID) }.map(\.id))
        // Preserve the current turn's UUID, support and phase. Removed/unlearned content cannot be reviewed.
        while let turn = point.currentTurn, !allowed.contains(turn.cardID) {
            point.cursor += 1
            resetPrompt(&point)
        }
        if point.currentTurn == nil { point.phase = .complete }
        next.checkpoint = point
        return next
    }

    static func reveal(_ archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        var next = archive
        guard next.checkpoint?.phase == .prompt else { return next }
        next.checkpoint?.helped = true
        next.checkpoint?.phase = .revealed
        return next
    }

    static func updateAnswer(_ text: String, in archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        var next = archive
        guard next.checkpoint?.phase == .prompt else { return next }
        next.checkpoint?.typedAnswer = String(text.prefix(500))
        return next
    }

    static func check(_ archive: ReviewJourneyArchive, card: ReviewJourneyCard, now: Date,
                      calendar: Calendar = .current) -> ReviewJourneyArchive {
        guard let point = archive.checkpoint, point.phase == .prompt,
              let turn = point.currentTurn, turn.cardID == card.id,
              let prompt = card.checkPrompts.first(where: { $0.id == turn.checkedPromptID }) else { return archive }
        let answer = ChronicleQuizEngine.normalizedAnswer(point.typedAnswer)
        guard !answer.isEmpty else { return archive }
        let correct = prompt.acceptedAnswers.contains { ChronicleQuizEngine.normalizedAnswer($0) == answer }
        let support: LearningSupport = turn.isTaughtRevisit ? .rescued : (point.helped ? .hinted : .independent)
        let kind: ReviewJourneyEvidenceKind
        if !correct {
            kind = .incorrectChecked
        } else if support != .independent {
            kind = .helpedChecked
        } else if point.sharedFamilyResponse != true, let previous = archive.independentWitnessesByCardID[card.id],
                  previous.sessionID != point.sessionID,
                  previous.promptID != prompt.id,
                  now.timeIntervalSince(previous.recordedAt) >= 24 * 60 * 60 {
            kind = .laterIndependentRecall
        } else {
            kind = .freshChecked
        }
        let response: LearningReviewResponse = !correct ? .teachAgain : (support == .independent ? .knewIt : .neededClue)
        return finish(archive, card: card, kind: kind, support: support, correct: correct,
                      response: response, now: now, calendar: calendar)
    }

    static func selfReport(_ response: LearningReviewResponse, archive: ReviewJourneyArchive,
                           card: ReviewJourneyCard, now: Date, calendar: Calendar = .current) -> ReviewJourneyArchive {
        guard archive.checkpoint?.phase == .revealed else { return archive }
        return finish(archive, card: card, kind: .selfReported, support: .selfReported, correct: false,
                      response: response, now: now, calendar: calendar)
    }

    static func continueAfterResult(_ archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        var next = archive
        guard var point = next.checkpoint, point.phase == .result else { return next }
        if point.currentEvidence?.response == .teachAgain {
            point.phase = .teaching
        } else {
            point.cursor += 1
            resetPrompt(&point)
        }
        next.checkpoint = point
        return next
    }

    static func finishTeaching(_ archive: ReviewJourneyArchive, card: ReviewJourneyCard, now: Date) -> ReviewJourneyArchive {
        var next = archive
        guard var point = next.checkpoint, point.phase == .teaching,
              let turn = point.currentTurn, turn.cardID == card.id,
              next.pendingEvidence.count < maximumPendingEvidence else { return next }
        let event = ReviewJourneyEvidence(id: turn.teachingEventID, sessionID: point.sessionID, cardID: card.id,
            sceneID: card.sceneID, promptType: card.promptType, checkedPromptID: nil, kind: .reteachingExposure,
            support: .rescued, wasSuccessful: false, response: nil, recordedAt: now,
            responseContext: point.sharedFamilyResponse == true ? .sharedFamilyRecognition : nil)
        if !point.evidence.contains(where: { $0.id == event.id }) {
            point.evidence.append(event)
            next.pendingEvidence.append(event)
        }
        // Exactly one later queue turn per card in this sitting, even when the revisit needs teaching too.
        if point.queue.count < maximumQueuedTurns && point.requeuedCardIDs.insert(card.id).inserted {
            point.queue.append(ReviewJourneyTurn(cardID: card.id, isTaughtRevisit: true,
                checkedPromptID: checkPrompt(for: card, avoiding: turn.checkedPromptID)?.id))
        }
        point.cursor += 1
        resetPrompt(&point)
        next.checkpoint = point
        return next
    }

    static func acknowledge(_ eventID: UUID, in archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        var next = archive
        next.pendingEvidence.removeAll { $0.id == eventID }
        return next
    }

    private static func finish(_ archive: ReviewJourneyArchive, card: ReviewJourneyCard,
                               kind: ReviewJourneyEvidenceKind, support: LearningSupport, correct: Bool,
                               response: LearningReviewResponse, now: Date, calendar: Calendar) -> ReviewJourneyArchive {
        var next = archive
        guard var point = next.checkpoint, let turn = point.currentTurn, turn.cardID == card.id,
              !point.evidence.contains(where: { $0.id == turn.id }),
              next.pendingEvidence.count < maximumPendingEvidence,
              let schedule = next.schedulesByCardID[card.id] else { return next }
        let event = ReviewJourneyEvidence(id: turn.id, sessionID: point.sessionID, cardID: card.id,
            sceneID: card.sceneID,
            promptType: kind == .selfReported ? card.promptType : (card.checkPrompts.first { $0.id == turn.checkedPromptID }?.promptType ?? card.promptType),
            checkedPromptID: kind == .selfReported ? nil : turn.checkedPromptID,
            kind: kind, support: support,
            wasSuccessful: correct, response: response, recordedAt: now,
            priorIndependentWitness: kind == .laterIndependentRecall ? archive.independentWitnessesByCardID[card.id] : nil,
            responseContext: point.sharedFamilyResponse == true ? .sharedFamilyRecognition : nil,
            selectedChoiceID: point.sharedFamilyResponse == true && kind != .selfReported ? point.selectedChoiceID : nil)
        point.evidence.append(event)
        point.phase = .result
        // Only an interrupted, unchecked prompt needs the child's input; never retain it in results/history.
        point.typedAnswer = ""
        point.selectedChoiceID = nil
        next.pendingEvidence.append(event)
        let effectiveResponse: LearningReviewResponse = turn.isTaughtRevisit && response == .knewIt ? .neededClue : response
        // Optional practice before the due time must not imitate another spaced revisit.
        if effectiveResponse != .knewIt
            || (next.lastScheduledSessionByCardID[card.id] != point.sessionID && now >= schedule.nextDueAt) {
            let history = point.evidence.filter { $0.cardID == card.id }.map(\.promptType)
            next.schedulesByCardID[card.id] = SpacedReviewScheduler.schedule(schedule, after: effectiveResponse,
                promptHistory: history, now: now, calendar: calendar).schedule
            next.lastScheduledSessionByCardID[card.id] = point.sessionID
        }
        if correct && support == .independent && point.sharedFamilyResponse != true {
            // Keep a same-session first witness so repetition cannot move its clock forward.
            if next.independentWitnessesByCardID[card.id]?.sessionID != point.sessionID {
                next.independentWitnessesByCardID[card.id] = ReviewJourneyRecallWitness(sessionID: point.sessionID,
                    recordedAt: now, promptID: turn.checkedPromptID ?? "")
            }
        }
        next.checkpoint = point
        return next
    }

    private static func resetPrompt(_ point: inout ReviewJourneyCheckpoint) {
        point.phase = point.currentTurn == nil ? .complete : .prompt
        point.typedAnswer = ""
        point.helped = false
        point.selectedChoiceID = nil
        point.helpWasRequested = false
    }

    private static func checkPrompt(for card: ReviewJourneyCard, avoiding promptID: String?) -> ReviewJourneyCheckPrompt? {
        card.checkPrompts.first { $0.id != promptID } ?? card.checkPrompts.first
    }
}
