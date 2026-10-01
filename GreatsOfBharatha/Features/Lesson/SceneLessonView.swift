import SwiftUI

struct SceneLessonView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let scene: StoryScene
    @State private var point: LessonResumePoint?
    @State private var selectedChoiceID: String?
    @State private var feedback: String?
    @State private var correct = false
    @State private var usedHelp = false
    @State private var completed = false
    @State private var detailText: String?
    @State private var shuffledChoices: [AuthoredLessonChoice] = []
    @State private var completionEventID = UUID()

    private var plan: SceneLearningPlan { SampleContent.learningPlan(for: scene) }
    private var phase: LessonResumePhase { point?.phase ?? .story }
    private var calm: Bool { reduceMotion || appModel.parentSettings.calmTransitionsEnabled }
    private var challenge: RecallChallenge? {
        appModel.content.activeHeroArc.scene(withID: scene.id)?.primaryRecallChallenge
    }
    private var places: [Place] {
        scene.mapAnchors.compactMap { id in appModel.content.places.first(where: { $0.id == id }) }
    }
    private var nextScene: StoryScene? {
        guard let index = appModel.content.scenes.firstIndex(where: { $0.id == scene.id }),
              appModel.content.scenes.indices.contains(index + 1) else { return nil }
        return appModel.content.scenes[index + 1]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text(phaseTitle).font(.headline).accessibilityIdentifier("scene-phase-progress")
                switch phase {
                case .story: story
                case .place: placeStep
                case .recall: recall
                case .reward: reward
                }
            }
            .padding(GBSpacing.medium)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .id(phase.rawValue)
        .background(GBColor.Background.app)
        .navigationTitle(scene.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear(perform: restore)
    }

    private var phaseTitle: String {
        switch phase {
        case .story: "Step 1 of 4: Discover the story"
        case .place: "Step 2 of 4: Fort detective"
        case .recall: "Step 3 of 4: Try your memory"
        case .reward: "Step 4 of 4: Your keepsake"
        }
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            LessonSceneArt(plan: plan)
            Text(scene.title).gbTitle()
            Text(scene.childSafeSummary).gbStory()
            Text(plan.teachingText).gbStory().accessibilityIdentifier("lesson-key-fact")
            GBGlossaryTray(terms: GBGlossaryTerm.matching(scene.childSafeSummary + " " + plan.teachingText))
            if scene.number == 1 {
                Text("Look closely. Choose a detail to discover its clue.").gbBody()
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: GBSpacing.small) { discoveryButtons }
                } else {
                    HStack(alignment: .top, spacing: GBSpacing.small) { discoveryButtons }
                }
                if let detailText {
                    Text(detailText).gbStory()
                    LearningNarrationControls(id: scene.id + "-discovery", text: detailText)
                }
            }
            LearningNarrationControls(id: scene.id + "-story", text: scene.childSafeSummary + " " + plan.teachingText)
            Button("Move to place clues") { advance(.place) }
                .buttonStyle(.gbPrimary(.story))
                .accessibilityIdentifier("story-move-to-place-clues-button")
        }
    }

    @ViewBuilder private var discoveryButtons: some View {
        discovery("hill", title: "Hill", symbol: "mountain.2.fill",
            text: "Shivneri is a hill fort near Junnar. Remember it as Shivaji Maharaj's Birth Fort.")
        discovery("gate", title: "Fort gate", symbol: "door.left.hand.open",
            text: "A fort is a protected place. Shivneri is the fort where Shivaji Maharaj's story begins.")
        discovery("book", title: "Storybook", symbol: "book.fill",
            text: "Jijabai guided young Shivaji with courage, care, and responsibility. Shivneri reminds us of these beginnings.")
    }

    private func discovery(_ id: String, title: String, symbol: String, text: String) -> some View {
        Button {
            detailText = text
            mutatePoint { $0.discoveredDetailIDs.insert(id) }
        } label: {
            Label(title, systemImage: symbol).frame(maxWidth: .infinity, minHeight: GBTouch.button)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("story-discovery-" + id)
        .accessibilityValue(point?.discoveredDetailIDs.contains(id) == true ? "Discovered" : "Ready to discover")
    }

    private var placeStep: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Text("These places belong to our story.").gbTitle()
            ForEach(places) { place in
                Text("\(place.name): \(place.primaryEvent)").gbStory()
                OfflineFortChallenge(target: place, candidates: candidates(for: place),
                    solvedPlaceIDs: Binding(get: { point?.solvedPlaceIDs ?? [] }, set: { ids in mutatePoint { $0.solvedPlaceIDs = ids } }),
                    helpedPlaceIDs: Binding(get: { point?.helpedPlaceIDs ?? [] }, set: { ids in mutatePoint { $0.helpedPlaceIDs = ids } })) { support in
                        appModel.lessonStore.recordLearningOutcome(subjectID: place.id, subjectType: .location,
                            activity: .recall, wasSuccessful: true, support: support, mastery: .understood,
                            promptType: .eventToPlaceMatch, detail: "Found a fort from an authored clue on the offline board",
                            sessionID: point?.sessionID)
                    }
            }
            Button("Got it! Try my memory") { advance(.recall) }
                .buttonStyle(.gbPrimary(.place))
                .disabled(!places.allSatisfy { point?.solvedPlaceIDs.contains($0.id) == true })
                .accessibilityIdentifier("place-clues-got-it-button")
        }
    }

    private func candidates(for target: Place) -> [Place] {
        let others = appModel.content.corePlaces.filter { $0.id != target.id }.prefix(2)
        return ([target] + others).sorted { $0.name < $1.name }
    }

    private var recall: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Text(challenge?.prompt ?? scene.recallPrompt.question).gbTitle()
            LearningNarrationControls(id: scene.id + "-question", text: challenge?.prompt ?? scene.recallPrompt.question)
            ForEach(shuffledChoices) { choice in
                Button { guard !correct else { return }; selectedChoiceID = choice.id; feedback = nil } label: {
                    HStack {
                        Text(choice.title).gbHeadline()
                        Spacer()
                        Image(systemName: selectedChoiceID == choice.id ? "checkmark.circle.fill" : "circle")
                    }.frame(minHeight: GBTouch.button)
                }
                .buttonStyle(.bordered)
                .disabled(correct)
                .accessibilityIdentifier("recall-choice-" + choice.id)
                .accessibilityValue(selectedChoiceID == choice.id ? "Selected" : "Not selected")
            }
            if !correct {
                Button("Check my choice", action: check)
                    .buttonStyle(.gbPrimary(.story))
                    .disabled(selectedChoiceID == nil)
                    .accessibilityIdentifier("recall-check-button")
                Button("Help me remember") {
                    usedHelp = true
                    mutatePoint { $0.revealedHintLevel = max(1, $0.revealedHintLevel) }
                    feedback = plan.teachingText
                }.buttonStyle(.bordered).frame(minHeight: GBTouch.button)
            }
            if let feedback {
                Text(feedback).gbStory().accessibilityIdentifier("recall-feedback")
                LearningNarrationControls(id: scene.id + "-feedback", text: feedback)
            }
            if correct {
                Button("Collect my keepsake") { advance(.reward) }
                    .buttonStyle(.gbPrimary(.chronicle))
                    .accessibilityIdentifier("recall-reward-button")
            }
        }
    }

    private var reward: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            if let item = appModel.content.rewards.first(where: { $0.id == scene.rewardID }) {
                GBRewardReveal(title: item.title, subtitle: scene.timelineMarker, iconName: "book.closed.fill",
                    quote: item.meaning, mastery: .understood, onDismiss: nil)
                LearningNarrationControls(id: scene.id + "-reward", text: "Your keepsake: " + item.title + ". " + item.meaning)
                NavigationLink {
                    ChronicleView(rewards: appModel.content.rewards, highlightRewardID: item.id)
                } label: { Label("See in my Album", systemImage: "book.closed.fill") }
                .buttonStyle(.gbPrimary(.chronicle)).accessibilityIdentifier("reward-album-button")
            }
            Button("All done") {
                completed = true
                appModel.lessonStore.clearResumePoint(for: scene.id)
                dismiss()
            }.buttonStyle(.bordered).accessibilityIdentifier("reward-done-button")
            if let nextScene {
                NavigationLink {
                    SceneLessonView(scene: nextScene)
                } label: { Text("Next adventure: \(nextScene.title)") }
                .buttonStyle(.gbPrimary(.story))
                .accessibilityIdentifier("reward-next-button")
                .simultaneousGesture(TapGesture().onEnded {
                    appModel.lessonStore.clearResumePoint(for: scene.id)
                })
            }
        }
    }

    private func check() {
        guard !correct, let selectedChoiceID else { return }
        correct = plan.isCorrect(choiceID: selectedChoiceID)
        let support: LearningSupport = usedHelp || (point?.revealedHintLevel ?? 0) > 0 ? .hinted : .independent
        let wasPreviouslyComplete = appModel.lessonStore.masteryRecord(for: scene.id)?.evidenceLog.contains {
            $0.type == .recallSuccess || $0.type == .reviewSuccess
        } == true
        appModel.lessonStore.recordLearningOutcome(subjectID: scene.id,
            activity: wasPreviouslyComplete ? .review : .recall, wasSuccessful: correct,
            support: support, mastery: wasPreviouslyComplete ? .remembered : .understood,
            promptType: challenge?.promptType ?? .openPrompt, detail: "Authored recognition choice",
            eventID: correct ? completionEventID : UUID(), sessionID: point?.sessionID)
        if correct {
            mutatePoint { $0.recallCompleted = true }
            feedback = challenge?.feedback.success ?? scene.recallPrompt.supportText
            LessonFeedback.fire(.success)
        } else {
            usedHelp = true
            mutatePoint { $0.revealedHintLevel += 1 }
            feedback = "Let's look again. " + plan.teachingText
        }
    }

    private func restore() {
        guard point == nil else { return }
        point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id)
        completionEventID = point?.recallEventID ?? UUID()
        usedHelp = (point?.revealedHintLevel ?? 0) > 0
        shuffledChoices = plan.choices.shuffled()
        // Persist success checkpoint before reward so interruption cannot require a second award.
        let durableSuccess = appModel.lessonStore.masteryRecord(for: scene.id)?.evidenceLog.contains {
            $0.eventID == point?.recallEventID && ($0.type == .recallSuccess || $0.type == .reviewSuccess)
        } == true
        correct = point?.recallCompleted == true || durableSuccess
        if correct && point?.recallCompleted != true { mutatePoint { $0.recallCompleted = true } }
        if phase == .reward && !correct { mutatePoint { $0.phase = .story } }
        appModel.lessonStore.recordLearningOutcome(subjectID: scene.id, activity: .storyExposure,
            wasSuccessful: true, mastery: .witnessed, detail: "Story opened", sessionID: point?.sessionID)
        if let point { appModel.lessonStore.saveResumePoint(point) }
    }

    private func mutatePoint(_ change: (inout LessonResumePoint) -> Void) {
        var next = point ?? LessonResumePoint(sceneID: scene.id)
        change(&next)
        next.updatedAt = Date()
        point = next
        appModel.lessonStore.saveResumePoint(next)
    }

    private func advance(_ next: LessonResumePhase) {
        withAnimation(calm ? nil : GBMotion.standard) { mutatePoint { $0.phase = next; $0.preferredActivity = next == .recall ? .recall : nil } }
    }
}
