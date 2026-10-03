import Foundation

@MainActor
enum ChapterKnowledgeAdapters {
    static func hooks(store: ShivajiLessonStore, definitions: [ChapterKnowledgeDefinition]) -> ChapterKnowledgeHooks {
        ChapterKnowledgeHooks(load: {
            guard store.activityStateIsAvailable(for: .knowledge) else { return ChapterKnowledgeArchive(schemaVersion: 0) }
            return store.activityState(ChapterKnowledgeArchive.self, for: .knowledge) ?? ChapterKnowledgeArchive()
        }, save: { archive in
            guard archive.isSupported else { return false }
            let ids = Set(archive.retainedEvidence.map(\.id) + archive.pendingEvidence.map(\.id))
            return store.saveActivityState(archive, for: .knowledge, retainingEventIDs: ids)
        }, record: { event in
            record(event, store: store, definitions: definitions)
        })
    }

    static func record(_ event: ChapterKnowledgeEvidence, store: ShivajiLessonStore,
                       definitions: [ChapterKnowledgeDefinition]) -> Bool {
        guard store.activityStateIsAvailable(for: .knowledge),
              let saved = store.activityState(ChapterKnowledgeArchive.self, for: .knowledge), saved.isSupported,
              saved.pendingEvidence.contains(event), saved.retainedEvidence.contains(event),
              let definition = definitions.first(where: { $0.sceneID == event.sceneID }),
              definition.validationIssues.isEmpty, valid(event, archive: saved, definition: definition) else { return false }
        if store.hasRecordedLearningEvent(event.id) { return store.confirmOptionalLearningEvent(event.id, for: .knowledge) }
        switch event.kind {
        case .teachingExposure:
            store.recordStoryExposure(for: event.sceneID, detail: "Knowledge beat " + (event.beatID ?? ""),
                eventID: event.id, sessionID: event.sessionID, at: event.recordedAt)
        case .choiceCheck:
            let support: LearningSupport
            switch event.support {
            case .noClue: support = .independent
            case .withClue: support = .hinted
            case .answerSeen: support = .rescued
            }
            let kind: ReviewJourneyEvidenceKind = !event.wasSuccessful ? .incorrectChecked :
                (event.support == .noClue ? .freshChecked : .helpedChecked)
            // These are recognition checks. They never create a typed recall witness or later-review award.
            store.recordLearningOutcome(subjectID: event.sceneID, activity: .recall, wasSuccessful: event.wasSuccessful,
                support: support, promptType: .recognitionChoice, detail: "Knowledge recognition " + (event.questionID ?? ""),
                eventID: event.id, sessionID: event.sessionID, at: event.recordedAt,
                checkedPromptID: event.questionID, reviewKind: kind,
                participation: event.responseContext == .sharedFamilyRecognition ? .sharedFamilyRecognition : .individualRecognition)
        }
        return store.confirmOptionalLearningEvent(event.id, for: .knowledge)
    }

    private static func valid(_ event: ChapterKnowledgeEvidence, archive: ChapterKnowledgeArchive,
                              definition: ChapterKnowledgeDefinition) -> Bool {
        let approvedIDs = Set(definition.claims.filter { $0.reviewStatus == .approved }.map(\.id))
        guard !event.claimIDs.isEmpty, Set(event.claimIDs).isSubset(of: approvedIDs) else { return false }
        switch event.kind {
        case .teachingExposure:
            guard let beatID = event.beatID, let beat = definition.beats.first(where: { $0.id == beatID }),
                  let teaching = archive.teachingBySceneID[event.sceneID], teaching.evidence.contains(event),
                  teaching.shownBeatIDs.contains(beatID), Set(event.claimIDs).isSubset(of: teaching.taughtClaimIDs),
                  Set(event.claimIDs).isSubset(of: Set(beat.claimIDs)) else { return false }
            return !event.wasSuccessful && event.questionID == nil && event.turnID == nil && event.selectedChoiceID == nil &&
                event.responseContext == nil && event.support == .noClue
        case .choiceCheck:
            return validCheck(event, archive: archive, definition: definition)
        }
    }

    private static func validCheck(_ event: ChapterKnowledgeEvidence, archive: ChapterKnowledgeArchive,
                                   definition: ChapterKnowledgeDefinition) -> Bool {
        guard let point = archive.practiceBySceneID[event.sceneID], point.sessionID == event.sessionID,
              let turn = point.queue.first(where: { $0.id == event.turnID }),
              turn.checks.contains(event), let checkIndex = turn.checks.firstIndex(of: event),
              event.beatID == nil, event.responseContext == point.responseContext,
              let question = definition.questions.first(where: { $0.id == event.questionID && $0.id == turn.questionID }),
              let choice = question.choices.first(where: { $0.id == event.selectedChoiceID }),
              event.wasSuccessful == (choice.id == question.correctChoiceID),
              Set(event.claimIDs) == Set(question.claimIDs) else { return false }
#if os(tvOS)
        guard event.responseContext == .sharedFamilyRecognition else { return false }
#else
        guard event.responseContext == .individualRecognition else { return false }
#endif
        let teaching = archive.teachingBySceneID[event.sceneID]
        guard definition.questionsEligible(afterShownBeatIDs: teaching?.shownBeatIDs ?? [],
            taughtClaimIDs: teaching?.taughtClaimIDs ?? []).contains(where: { $0.id == question.id }) else { return false }
        switch event.support {
        case .noClue: return !turn.wasPreviouslyChecked && checkIndex == 0 && !turn.helpWasRequested
        case .withClue: return !turn.wasPreviouslyChecked && checkIndex == 0 && turn.helpWasRequested
        case .answerSeen: return turn.wasPreviouslyChecked || checkIndex > 0
        }
    }
}
