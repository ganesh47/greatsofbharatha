import SwiftUI

struct TVTimelineView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var checkpoint = TVTimelineCheckpoint()
    @State private var sequence = TVSequenceState(cardCount: 3)
    @State private var teachingComplete = false
    @State private var loaded = false
    @FocusState private var focus: String?

    private var rounds: [[TVSequenceCard]] { TVLearningContent.timelineRounds(store: appModel.lessonStore) }
    private var hostSceneID: String { checkpoint.mode == "full" ? "scene-6-raigad-coronation" : "scene-3-pratapgad-turning-point" }
    private var cards: [TVSequenceCard] { rounds.indices.contains(checkpoint.roundIndex) ? rounds[checkpoint.roundIndex] : [] }
    private var isComplete: Bool { !rounds.isEmpty && checkpoint.completedRoundIndices.count >= rounds.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Put our story in order").font(.system(size: 46, weight: .bold))
                if rounds.isEmpty {
                    TVFireflyGuide(message: "Learn the first three chapters and check an answer in each. Then we can put that part of the story in order together.")
                    Button("Back to adventures") { dismiss() }.buttonStyle(TVCardButtonStyle())
                        .accessibilityIdentifier("tv-timeline-back")
                } else if isComplete {
                    completion
                } else if !teachingComplete {
                    teaching
                } else {
                    TVFireflyGuide(message: "Choose a story card on the left, then choose First, Then, or After that on the right. The cards that belong stay in place. Help is here whenever you want.")
                    TVSequencePuzzle(cards: cards, state: $sequence, onChange: savePuzzle)
                    if TVSequenceEngine.isComplete(state: sequence, cards: cards) {
                        Button(checkpoint.roundIndex == rounds.count - 1 ? "Finish our story" : "Next part of our story") { nextRound() }
                            .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "timeline-next")
                            .accessibilityIdentifier("tv-timeline-next")
                    }
                }
            }
            .padding(.horizontal, 86).padding(.vertical, 45)
            .frame(maxWidth: 1740).frame(maxWidth: .infinity)
        }
        .background(TVTheme.background)
        .foregroundStyle(TVTheme.paper)
        .navigationTitle("Story timeline")
        .onAppear(perform: restore)
        .onDisappear { save(); narrator.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { save(); narrator.stop() } }
        .onPlayPauseCommand {
            guard appModel.parentSettings.narrationEnabled else { return }
            if narrator.activeCardID != nil { narrator.togglePlayback() } else {
                let text = isComplete ? "Our story belongs together. Retell it with someone if you want."
                    : (teachingComplete ? sequence.feedback ?? "Choose a story card, then its place in the story." : cards.map(\.teachingText).joined(separator: " "))
                narrator.speak(id: "timeline-visible-\(checkpoint.roundIndex)", text: text)
            }
        }
        .onExitCommand {
            narrator.stop()
            if sequence.selectedCardID != nil {
                sequence.selectedCardID = nil
                checkpoint.selectedCardID = nil
                save()
            } else { save(); dismiss() }
        }
    }

    private var teaching: some View {
        VStack(alignment: .leading, spacing: 26) {
            TVFireflyGuide(message: "Let's look back at this little part before we play. You can pass the remote and retell it together.")
            HStack(alignment: .top, spacing: 26) {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: 18) {
                        Image(systemName: card.symbol).font(.system(size: 38))
                        Text(card.title).font(.system(size: 29, weight: .bold))
                        Text(card.teachingText).font(.system(size: 26))
                    }
                    .padding(26).frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
                    .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: 20))
                }
            }
            TVNarrationControls(id: "timeline-teaching-\(checkpoint.mode)-\(checkpoint.roundIndex)", text: cards.map(\.teachingText).joined(separator: " "))
            Button("Ready to put them in order") {
                recordTeaching()
                teachingComplete = true
                narrator.stop()
                save()
            }
            .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "timeline-start")
            .accessibilityIdentifier("tv-timeline-start")
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 26) {
            Label(checkpoint.mode == "full" ? "The whole journey belongs together." : "The opening story belongs together.", systemImage: "book.closed.fill")
                .font(.system(size: 38, weight: .bold)).accessibilityIdentifier("tv-timeline-success")
            Text(checkpoint.mode == "full"
                 ? "Shivneri, early forts, Pratapgad, Purandar, Agra and return, recovery, and Raigad. Each little part connects to the next."
                 : "The journey begins at Shivneri, grows through the early forts, and reaches a turning point at Pratapgad.")
                .font(.system(size: 30))
            TVFireflyGuide(message: "If you want, retell the story to someone. You can point to a place, share its memory hook, or talk about how planning helped.")
            HStack(spacing: 26) {
                Button("All done") { dismiss() }.buttonStyle(TVCardButtonStyle())
                    .focused($focus, equals: "timeline-done").accessibilityIdentifier("tv-timeline-done")
                Button("Explore again") {
                    checkpoint = TVTimelineCheckpoint(mode: checkpoint.mode)
                    discardPreviousTimelineSession()
                    teachingComplete = false
                    sequence = TVSequenceState(cardCount: 3)
                    save()
                    focus = "timeline-start"
                }.buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-timeline-again")
            }
        }
    }

    private func restore() {
        guard !loaded else { return }
        loaded = true
        // A locked preview is read-only; it must not become a later chapter's resume point.
        guard !rounds.isEmpty else { return }
        let mode = rounds.count > 1 ? "full" : "opening"
        let host = mode == "full" ? "scene-6-raigad-coronation" : "scene-3-pratapgad-turning-point"
        if let prior = appModel.lessonStore.resumePoint(for: host)?.tvCheckpoint?.timelineCheckpoint, prior.mode == mode {
            checkpoint = prior
        } else {
            checkpoint = TVTimelineCheckpoint(mode: mode)
            discardPreviousTimelineSession()
        }
        checkpoint.roundIndex = min(max(checkpoint.roundIndex, 0), max(rounds.count - 1, 0))
        let stored = checkpoint.slots.count == cards.count ? checkpoint.slots : Array(repeating: nil, count: cards.count)
        let slots = stored.enumerated().map { index, id in id == cards[index].id ? id : nil }
        sequence = TVSequenceState(slots: slots, selectedCardID: checkpoint.selectedCardID, hintLevel: checkpoint.hintLevel,
                                   helped: checkpoint.helpedRoundIndices.contains(checkpoint.roundIndex),
                                   rescued: appModel.lessonStore.resumePoint(for: host)?.tvCheckpoint?.helpedActivityIDs.contains(rescueKey) == true)
        teachingComplete = isComplete || appModel.lessonStore.resumePoint(for: host)?.tvCheckpoint?.completedActivityIDs
            .contains(teachingKey) == true
        focus = isComplete ? "timeline-done" : (teachingComplete ? nil : "timeline-start")
        save()
    }

    private var teachingKey: String { "timeline-teaching-\(checkpoint.mode)-\(checkpoint.sessionID)-\(checkpoint.roundIndex)" }
    private var rescueKey: String { "timeline-rescued-\(checkpoint.sessionID)-\(checkpoint.roundIndex)" }

    private func recordTeaching() {
        for card in cards {
            record(key: "timeline-exposure-\(checkpoint.sessionID)-" + card.sceneID, subjectID: card.sceneID, type: .scene,
                   activity: .storyExposure, successful: false, detail: "TV timeline recap: " + card.title)
        }
        var point = appModel.lessonStore.resumePoint(for: hostSceneID) ?? LessonResumePoint(sceneID: hostSceneID)
        var tv = point.tvCheckpoint ?? TVActivityCheckpoint()
        tv.completedActivityIDs.insert(teachingKey)
        point.tvCheckpoint = tv
        appModel.lessonStore.saveResumePoint(point)
    }

    private func savePuzzle() {
        checkpoint.slots = sequence.slots
        checkpoint.selectedCardID = sequence.selectedCardID
        checkpoint.hintLevel = sequence.hintLevel
        if sequence.helped { checkpoint.helpedRoundIndices.insert(checkpoint.roundIndex) }
        if sequence.rescued {
            var point = appModel.lessonStore.resumePoint(for: hostSceneID) ?? LessonResumePoint(sceneID: hostSceneID)
            var tv = point.tvCheckpoint ?? TVActivityCheckpoint()
            tv.helpedActivityIDs.insert(rescueKey)
            point.tvCheckpoint = tv
            appModel.lessonStore.saveResumePoint(point)
        }
        if TVSequenceEngine.isComplete(state: sequence, cards: cards) {
            let support: LearningSupport = sequence.rescued ? .rescued : (sequence.helped ? .hinted : .independent)
            for card in cards {
                record(key: "timeline-review-\(checkpoint.mode)-\(checkpoint.sessionID)-r\(checkpoint.roundIndex)-" + card.id,
                       subjectID: card.id, type: .timeline, activity: .timelinePlacement, successful: true,
                       support: support, detail: "Ordered a taught TV timeline review round")
            }
            checkpoint.completedRoundIndices.insert(checkpoint.roundIndex)
            focus = "timeline-next"
        }
        save()
    }

    private func nextRound() {
        guard TVSequenceEngine.isComplete(state: sequence, cards: cards) else { return }
        narrator.stop()
        if checkpoint.roundIndex < rounds.count - 1 {
            checkpoint.roundIndex += 1
            checkpoint.slots = []
            checkpoint.selectedCardID = nil
            checkpoint.hintLevel = 0
            teachingComplete = false
            sequence = TVSequenceState(cardCount: cards.count)
            focus = "timeline-start"
        } else { focus = "timeline-done" }
        save()
    }

    private func record(key: String, subjectID: String, type: MasterySubjectType,
                        activity: LearningActivityKind, successful: Bool, support: LearningSupport = .independent,
                        detail: String) {
        var point = appModel.lessonStore.resumePoint(for: hostSceneID) ?? LessonResumePoint(sceneID: hostSceneID)
        var tv = point.tvCheckpoint ?? TVActivityCheckpoint()
        guard !tv.completedActivityIDs.contains(key) else { return }
        let id = tv.eventID(for: key)
        point.tvCheckpoint = tv
        appModel.lessonStore.saveResumePoint(point)
        let recorded = appModel.lessonStore.recordLearningOutcome(subjectID: subjectID, subjectType: type,
                                                                  activity: activity, wasSuccessful: successful, support: support,
                                                                  promptType: .sequenceSlot, detail: detail,
                                                                  eventID: id, sessionID: checkpoint.sessionID)
        if recorded || appModel.lessonStore.masteryRecord(for: subjectID)?.evidenceLog.contains(where: { $0.eventID == id }) == true {
            tv.completedActivityIDs.insert(key)
            point.tvCheckpoint = tv
            appModel.lessonStore.saveResumePoint(point)
        }
    }

    private func save() {
        guard loaded, !rounds.isEmpty else { return }
        var point = appModel.lessonStore.resumePoint(for: hostSceneID) ?? LessonResumePoint(sceneID: hostSceneID)
        var tv = point.tvCheckpoint ?? TVActivityCheckpoint()
        checkpoint.slots = sequence.slots
        checkpoint.selectedCardID = sequence.selectedCardID
        checkpoint.hintLevel = sequence.hintLevel
        tv.timelineCheckpoint = checkpoint
        point.tvCheckpoint = tv
        point.updatedAt = Date()
        appModel.lessonStore.saveResumePoint(point)
    }

    /// Retain the current review checkpoint within the bounded snapshot; prior-session
    /// learning evidence stays in the shared store, rather than accumulating old puzzle IDs.
    private func discardPreviousTimelineSession() {
        var point = appModel.lessonStore.resumePoint(for: hostSceneID) ?? LessonResumePoint(sceneID: hostSceneID)
        var progress = point.tvCheckpoint ?? TVActivityCheckpoint()
        progress.completedActivityIDs = Set(progress.completedActivityIDs.filter { !$0.hasPrefix("timeline-") })
        progress.helpedActivityIDs = Set(progress.helpedActivityIDs.filter { !$0.hasPrefix("timeline-") })
        progress.completionEventIDs = progress.completionEventIDs.filter { !$0.key.hasPrefix("timeline-") }
        progress.timelineCheckpoint = checkpoint
        point.tvCheckpoint = progress
        appModel.lessonStore.saveResumePoint(point)
    }
}
