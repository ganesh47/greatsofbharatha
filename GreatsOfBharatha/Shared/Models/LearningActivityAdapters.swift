import Foundation

@MainActor
enum LearningActivityAdapters {
    static func saveTimeline(_ point: TimelineActivityCheckpoint, store: ShivajiLessonStore) -> Bool {
        let ids = Set(point.rounds.values.flatMap { $0.checksByCardID.values.map(\.eventID) })
        return store.saveActivityState(point, for: .timeline, retainingEventIDs: ids)
    }

    static func recordTimeline(_ check: TimelinePlacementCheck, store: ShivajiLessonStore, content: AppContent) -> Bool {
        guard let saved = store.activityState(TimelineActivityCheckpoint.self, for: .timeline), saved.schemaVersion == 1,
              let progress = saved.rounds[check.roundID], progress.teachingSeen,
              progress.checksByCardID[check.eventSubjectID] == check,
              progress.slots.indices.contains(check.slotIndex), progress.slots[check.slotIndex] == check.eventSubjectID else { return false }
        let checked = Set(content.scenes.compactMap { scene -> String? in
            TimelineActivityCatalog.hasCheckedLearning(evidence: store.masteryRecord(for: scene.id)?.evidenceLog ?? []) ? scene.id : nil
        })
        guard let round = TimelineActivityCatalog.availableRounds(events: content.activeHeroArc.timelineEvents,
            checkedSceneIDs: checked).first(where: { $0.id == check.roundID }),
              check.isValid(round: round, sessionID: saved.sessionID) else { return false }
        if !store.hasRecordedLearningEvent(check.eventID) {
            store.recordLearningOutcome(subjectID: check.eventSubjectID, subjectType: .timeline,
                activity: .timelinePlacement, wasSuccessful: true, support: check.support,
                promptType: .sequenceSlot, detail: "Checked authored story ordering: " + check.roundID,
                eventID: check.eventID, sessionID: check.sessionID)
        }
        return store.confirmOptionalLearningEvent(check.eventID, for: .timeline)
    }

    static func reviewHooks(store: ShivajiLessonStore) -> ReviewJourneyHooks {
        ReviewJourneyHooks(load: {
            let saved = store.activityState(ReviewJourneyArchive.self, for: .review)
            return saved?.schemaVersion == 1 ? saved ?? ReviewJourneyArchive() : ReviewJourneyArchive()
        }, save: { archive in
            guard archive.schemaVersion == 1 else { return false }
            let ids = Set((archive.checkpoint?.evidence.map(\.id) ?? []) + archive.pendingEvidence.map(\.id))
            return store.saveActivityState(archive, for: .review, retainingEventIDs: ids)
        }, record: { event in recordReview(event, store: store) })
    }

    private static func recordReview(_ event: ReviewJourneyEvidence, store: ShivajiLessonStore) -> Bool {
        guard let archive = store.activityState(ReviewJourneyArchive.self, for: .review), archive.schemaVersion == 1,
              archive.pendingEvidence.contains(event),
              let card = LearnQuizPilotData.reviewCards.first(where: { $0.id == event.cardID && $0.sceneID == event.sceneID }),
              archive.checkpoint?.evidence.contains(event) == true, archive.checkpoint?.sessionID == event.sessionID,
              (store.mastery(for: event.sceneID) ?? .witnessed) >= .understood, validReview(event, card: card) else { return false }
        if store.hasRecordedLearningEvent(event.id) { return store.confirmOptionalLearningEvent(event.id, for: .review) }
        let detail = "Story card " + event.cardID + "; authored prompt " + (event.checkedPromptID ?? "self-report")
        switch event.kind {
        case .selfReported:
            guard let response = event.response else { return false }
            store.recordReviewResponse(subjectID: event.sceneID, response: response, promptType: event.promptType,
                eventID: event.id, sessionID: event.sessionID, at: event.recordedAt,
                cardID: event.cardID, participation: .typedResponse)
        case .reteachingExposure:
            store.recordStoryExposure(for: event.sceneID, detail: "Retaught " + detail,
                eventID: event.id, sessionID: event.sessionID, at: event.recordedAt)
        case .freshChecked, .helpedChecked, .incorrectChecked, .laterIndependentRecall:
            store.recordLearningOutcome(subjectID: event.sceneID,
                activity: event.kind == .laterIndependentRecall ? .review : .recall,
                wasSuccessful: event.wasSuccessful, support: event.support, promptType: event.promptType,
                detail: detail, eventID: event.id, sessionID: event.sessionID, at: event.recordedAt,
                cardID: event.cardID, checkedPromptID: event.checkedPromptID, reviewKind: event.kind, participation: .typedResponse)
        }
        return store.confirmOptionalLearningEvent(event.id, for: .review)
    }

    private static func validReview(_ event: ReviewJourneyEvidence, card: LearnQuizReviewCard) -> Bool {
        switch event.kind {
        case .selfReported:
            return event.support == .selfReported && !event.wasSuccessful && event.response != nil && event.checkedPromptID == nil
        case .reteachingExposure:
            return event.support == .rescued && !event.wasSuccessful && event.checkedPromptID == nil
        case .freshChecked:
            return event.wasSuccessful && event.support == .independent && knownPrompt(event, card: card)
        case .helpedChecked:
            return event.wasSuccessful && (event.support == .hinted || event.support == .rescued) && knownPrompt(event, card: card)
        case .incorrectChecked:
            return !event.wasSuccessful && event.support != .selfReported && knownPrompt(event, card: card)
        case .laterIndependentRecall:
            return false // Requires the follow-up's persisted prior-card witness before enabling.
        }
    }

    private static func knownPrompt(_ event: ReviewJourneyEvidence, card: LearnQuizReviewCard) -> Bool {
        guard let id = event.checkedPromptID else { return false }
        if let alternate = LearnQuizPilotData.reviewCards.first(where: { $0.id == id && $0.sceneID == card.sceneID }) {
            return alternate.promptType == event.promptType
                && ChronicleQuizEngine.normalizedAnswer(alternate.back) == ChronicleQuizEngine.normalizedAnswer(card.back)
                && ChronicleQuizEngine.normalizedAnswer(alternate.front) != ChronicleQuizEngine.normalizedAnswer(card.front)
        }
        guard let challenge = LearnQuizPilotData.scenes.first(where: { $0.id == card.sceneID })?.quiz.challenge else { return false }
        return challenge.id == id && challenge.promptType == event.promptType && challenge.correctAnswers.contains {
            ChronicleQuizEngine.normalizedAnswer($0) == ChronicleQuizEngine.normalizedAnswer(card.back)
        }
    }
}
