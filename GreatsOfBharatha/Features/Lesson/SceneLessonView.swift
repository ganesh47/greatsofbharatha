import SwiftUI

struct SceneLessonView: View {
    @EnvironmentObject private var appModel: AppModel
    let scene: StoryScene

    @State private var cardIndex = 0
    @State private var storyStepComplete = false
    @State private var recallState = LessonRecallState()
    @State private var revealedMapAnchors = 0
    @State private var chosenPlanSteps: Set<String> = []
    @State private var bonusPlanningVisible = false
    @State private var hintVisible = false
    @State private var recapVisible = false

    private var lessonCards: [SceneCardContent] {
        [
            SceneCardContent(id: "summary", eyebrow: "Story spark", title: scene.title, body: scene.childSafeSummary, symbol: GBIcon.story),
            SceneCardContent(id: "fact", eyebrow: "Remember this", title: scene.keyFact, body: scene.narrativeObjective, symbol: "sparkles.rectangle.stack.fill"),
            SceneCardContent(id: "timeline", eyebrow: "Chronicle moment", title: scene.timelineMarker, body: "This is the moment you will remember when you open the Royal Chronicle.", symbol: GBIcon.timeline)
        ]
    }

    private var flow: SceneLessonFlow {
        SceneLessonFlow(
            totalStoryCards: lessonCards.count,
            currentStoryCardIndex: cardIndex,
            storyStepComplete: storyStepComplete,
            totalMapAnchors: scene.mapAnchors.count,
            revealedMapAnchors: revealedMapAnchors,
            hasAnsweredCorrectly: recallState.hasAnsweredCorrectly
        )
    }

    private var currentStepTitle: String {
        switch cardIndex {
        case 0: return "Step 1 of 3, hear the story"
        case 1: return "Step 2 of 3, spot the big idea"
        default: return "Step 3 of 3, mark the moment"
        }
    }

    private var storyButtonTitle: String {
        cardIndex == lessonCards.count - 1 ? "Continue to place clues" : "Continue story"
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    SceneHeaderCard(
                        scene: scene,
                        progressValue: flow.progressValue,
                        mastery: appModel.lessonStore.mastery(for: scene.id)
                    )

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Quest",
                                title: "Hear the story, remember the fort, keep the Chronicle",
                                subtitle: "Only the active step stays on screen, so the scene feels easy to finish."
                            )

                            GBQuestProgress(
                                steps: [.story, .place, .chronicle],
                                currentStepID: flow.currentQuestStepID
                            )
                        }
                    }

                    switch flow.activeStage {
                    case .story:
                        StoryDeckCard(
                            currentStepTitle: currentStepTitle,
                            lessonCards: lessonCards,
                            cardIndex: $cardIndex,
                            nextCardButtonTitle: storyButtonTitle,
                            onFinishStory: completeStoryStep
                        )
                    case .place:
                        MapAnchorCard(scene: scene, revealedMapAnchors: $revealedMapAnchors)
                    case .chronicle:
                        SceneSupportCard(
                            hintVisible: $hintVisible,
                            recapVisible: recapVisible,
                            hasAnsweredCorrectly: recallState.hasAnsweredCorrectly,
                            curatedHint: curatedHint,
                            sceneRecap: sceneRecap
                        )

                        RecallPanel(
                            question: scene.recallPrompt,
                            choices: sceneChoices,
                            selectedChoiceID: $recallState.selectedChoiceID,
                            feedbackText: recallState.feedbackText,
                            completed: recallState.hasAnsweredCorrectly,
                            onSubmit: submitRecall
                        )
                    case .complete:
                        CompletedSceneActions(
                            scene: scene,
                            places: appModel.content.corePlaces,
                            rewards: appModel.content.rewards,
                            recapVisible: recapVisible,
                            sceneRecap: sceneRecap,
                            bonusPlanningVisible: $bonusPlanningVisible,
                            showsPlanningChallenge: scene.number == 2,
                            hasPlanningUpgrade: chosenPlanSteps.count >= 2
                        )

                        if scene.number == 2, bonusPlanningVisible {
                            BonusPlanningCard(chosenPlanSteps: $chosenPlanSteps)
                        }
                    }
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Scene \(scene.number)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: chosenPlanSteps) { _, newValue in
            guard scene.number == 2, recallState.hasAnsweredCorrectly, newValue.count >= 2 else { return }
            appModel.lessonStore.markScene(scene.id, mastery: .observedClosely)
        }
    }

    private func completeStoryStep() {
        storyStepComplete = true
        LessonFeedback.fire(.success)
    }

    private func submitRecall() {
        guard let selectedChoiceID = recallState.selectedChoiceID else { return }

        let correctAnswer = normalized(scene.recallPrompt.answer)
        let selectedTitle = sceneChoices.first(where: { $0.id == selectedChoiceID })?.title ?? ""

        if normalized(selectedTitle) == correctAnswer {
            recallState.hasAnsweredCorrectly = true
            recallState.feedbackText = "You got it. \(scene.recallPrompt.supportText)"
            recapVisible = true
            let mastery: MasteryState = scene.number == 2 && chosenPlanSteps.count >= 2 ? .observedClosely : .understood
            appModel.lessonStore.markScene(scene.id, mastery: mastery)
            LessonFeedback.fire(.success)
        } else {
            recallState.hasAnsweredCorrectly = false
            recapVisible = false
            recallState.feedbackText = "Almost. \(scene.recallPrompt.supportText)"
            appModel.lessonStore.markScene(scene.id, mastery: .witnessed)
            LessonFeedback.fire(.warning)
        }
    }

    private var curatedHint: String {
        if scene.number == 1 {
            return "Think about where the story begins. The answer is the fort tied to Shivaji Maharaj's birth and Jijabai's early guidance."
        }
        return "One fort marks an early breakthrough, but the recall question asks which one became the early capital. Focus on the planning base that comes after Torna."
    }

    private var sceneRecap: String {
        "\(scene.timelineMarker). \(scene.childSafeSummary) Remember: \(scene.keyFact)"
    }

    private var sceneChoices: [LessonChoice] {
        var choices = scene.mapAnchors.map {
            LessonChoice(id: $0.lowercased().replacingOccurrences(of: " ", with: "-"), title: $0, detail: "A place name from this scene.")
        }
        if !choices.contains(where: { normalized($0.title) == normalized(scene.recallPrompt.answer) }) {
            choices.insert(LessonChoice(id: scene.id + "-answer", title: scene.recallPrompt.answer, detail: "The place tied to the key fact in this scene."), at: 0)
        }
        return Array(choices.prefix(3))
    }

    private func normalized(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct SceneCardContent: Identifiable {
    let id: String
    let eyebrow: String
    let title: String
    let body: String
    let symbol: String
}

private struct SceneHeaderCard: View {
    let scene: StoryScene
    let progressValue: Double
    let mastery: MasteryState?

    var body: some View {
        GBSurface(style: .accented(.story)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text(scene.timelineMarker.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                        Text(scene.title)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(GBColor.Content.inverse)
                        Text(scene.narrativeObjective)
                            .font(.body)
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.9))
                    }

                    Spacer(minLength: GBSpacing.small)

                    GBBadge(
                        title: mastery?.rawValue ?? "Ready",
                        symbol: mastery == nil ? GBIcon.story : GBIcon.reward,
                        emphasis: .story
                    )
                }

                ProgressView(value: progressValue)
                    .tint(GBColor.Content.inverse)

                HStack(alignment: .firstTextBaseline, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        Text("Royal Chronicle reward")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                        Text(scene.rewardID.replacingOccurrences(of: "reward-", with: "").replacingOccurrences(of: "-", with: " ").capitalized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GBColor.Content.inverse)
                    }

                    Spacer()

                    Text("Small steps, one clear finish")
                        .font(.caption)
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                }
            }
        }
    }
}

private struct StoryDeckCard: View {
    let currentStepTitle: String
    let lessonCards: [SceneCardContent]
    @Binding var cardIndex: Int
    let nextCardButtonTitle: String
    let onFinishStory: () -> Void

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Story",
                    title: currentStepTitle,
                    subtitle: "Keep one memory hook visible before moving to place clues."
                )

                TabView(selection: $cardIndex) {
                    ForEach(Array(lessonCards.enumerated()), id: \.offset) { index, card in
                        StoryCardView(card: card, cardNumber: index + 1, totalCards: lessonCards.count)
                            .padding(.horizontal, GBSpacing.xxxSmall)
                            .tag(index)
                    }
                }
#if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
#endif
                .frame(height: 340)

                HStack(spacing: GBSpacing.xxSmall) {
                    ForEach(0..<lessonCards.count, id: \.self) { index in
                        Capsule()
                            .fill(index == cardIndex ? GBColor.Accent.story : GBColor.Accent.story.opacity(0.18))
                            .frame(width: index == cardIndex ? 28 : 10, height: 10)
                    }
                }

                HStack(spacing: GBSpacing.small) {
                    if cardIndex > 0 {
                        Button("Back") {
                            cardIndex = max(cardIndex - 1, 0)
                            LessonFeedback.fire(.selection)
                        }
                        .buttonStyle(.gbSecondary)
                    }

                    Button(nextCardButtonTitle) {
                        if cardIndex == lessonCards.count - 1 {
                            onFinishStory()
                        } else {
                            cardIndex = min(cardIndex + 1, lessonCards.count - 1)
                            LessonFeedback.fire(.selection)
                        }
                    }
                    .buttonStyle(.gbPrimary(.story))
                }
            }
        }
    }
}

private struct StoryCardView: View {
    let card: SceneCardContent
    let cardNumber: Int
    let totalCards: Int

    var body: some View {
        GBSurface(style: .elevated, padding: GBSpacing.large) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    Text(card.eyebrow.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Content.secondary)
                    Spacer()
                    Text("\(cardNumber)/\(totalCards)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Accent.story)
                }

                Image(systemName: card.symbol)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(GBColor.Content.inverse)
                    .frame(width: 68, height: 68)
                    .background(GBColor.gradient(for: .story), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))

                Text(card.title)
                    .gbTitle()
                    .foregroundStyle(GBColor.Content.primary)

                Text(card.body)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct MapAnchorCard: View {
    let scene: StoryScene
    @Binding var revealedMapAnchors: Int

    var body: some View {
        GBSurface(style: .accented(.place)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Find Place",
                    title: "Reveal the fort clues",
                    subtitle: "Place names appear one by one so the story stays connected to the map.",
                    tone: .inverse,
                    trailing: AnyView(
                        GBBadge(
                            title: "\(revealedMapAnchors)/\(scene.mapAnchors.count)",
                            symbol: GBIcon.place,
                            emphasis: .place
                        )
                    )
                )

                ForEach(Array(scene.mapAnchors.enumerated()), id: \.offset) { index, anchor in
                    HStack(alignment: .top, spacing: GBSpacing.small) {
                        Image(systemName: index < revealedMapAnchors ? "mappin.circle.fill" : "mappin.circle")
                            .foregroundStyle(GBColor.Content.inverse)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                            Text(index < revealedMapAnchors ? anchor : "Hidden place clue")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GBColor.Content.inverse)
                            Text(index < revealedMapAnchors ? "This place now anchors the scene in your memory." : "Reveal the next clue when you are ready.")
                                .font(.caption)
                                .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                        }

                        Spacer()
                    }
                    .padding(GBSpacing.small)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
                }

                Button(revealedMapAnchors == scene.mapAnchors.count ? "Continue to Chronicle" : "Reveal next place clue") {
                    let nextValue = min(revealedMapAnchors + 1, scene.mapAnchors.count)
                    if nextValue != revealedMapAnchors {
                        revealedMapAnchors = nextValue
                        LessonFeedback.fire(nextValue == scene.mapAnchors.count ? .success : .reveal)
                    }
                }
                .buttonStyle(.gbSecondary)
            }
        }
    }
}

private struct SceneSupportCard: View {
    @Binding var hintVisible: Bool
    let recapVisible: Bool
    let hasAnsweredCorrectly: Bool
    let curatedHint: String
    let sceneRecap: String

    var body: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Help",
                    title: "Use one clue if you need it",
                    subtitle: "Hints stay optional so the main task remains clear."
                )

                Button(hintVisible ? "Hide clue" : "Need a clue?") {
                    hintVisible.toggle()
                    LessonFeedback.fire(.reveal)
                }
                .buttonStyle(.gbSecondary)

                if hintVisible {
                    GuidanceCard(
                        title: "Story clue",
                        message: curatedHint,
                        systemImage: "lightbulb"
                    )
                }

                if recapVisible, hasAnsweredCorrectly {
                    GuidanceCard(
                        title: "You remembered it",
                        message: sceneRecap,
                        systemImage: "text.book.closed"
                    )
                }
            }
        }
    }
}

private struct GuidanceCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        GBSurface(style: .plain, padding: GBSpacing.small) {
            HStack(alignment: .top, spacing: GBSpacing.small) {
                Image(systemName: systemImage)
                    .foregroundStyle(GBColor.Accent.story)
                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(GBColor.Content.secondary)
                }
                Spacer()
            }
        }
    }
}

private struct RecallPanel: View {
    let question: RecallPrompt
    let choices: [LessonChoice]
    @Binding var selectedChoiceID: String?
    let feedbackText: String?
    let completed: Bool
    let onSubmit: () -> Void

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Chronicle Gate",
                    title: "One quick recall before the reward",
                    subtitle: "Choose the place that matches the key fact from this scene."
                )

                Text(question.question)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.primary)

                ForEach(choices) { choice in
                    let isSelected = selectedChoiceID == choice.id
                    Button {
                        selectedChoiceID = choice.id
                        LessonFeedback.fire(.selection)
                    } label: {
                        HStack(alignment: .top, spacing: GBSpacing.small) {
                            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(isSelected ? GBColor.Accent.story : GBColor.Content.secondary)
                            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                                Text(choice.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GBColor.Content.primary)
                                Text(choice.detail)
                                    .font(.caption)
                                    .foregroundStyle(GBColor.Content.secondary)
                            }
                            Spacer()
                        }
                        .padding(GBSpacing.small)
                        .background(
                            isSelected ? GBColor.Accent.story.opacity(0.10) : GBColor.Background.elevated,
                            in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(completed ? "Answer checked" : "Collect my answer") {
                    onSubmit()
                }
                .buttonStyle(.gbPrimary(.chronicle))
                .disabled(selectedChoiceID == nil || completed)

                if let feedbackText {
                    GBSurface(style: .elevated, padding: GBSpacing.small) {
                        Text(feedbackText)
                            .font(.subheadline)
                            .foregroundStyle(completed ? GBColor.Accent.success : GBColor.Content.secondary)
                    }
                }
            }
        }
    }
}

private struct CompletedSceneActions: View {
    let scene: StoryScene
    let places: [Place]
    let rewards: [ChronicleReward]
    let recapVisible: Bool
    let sceneRecap: String
    @Binding var bonusPlanningVisible: Bool
    let showsPlanningChallenge: Bool
    let hasPlanningUpgrade: Bool

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Complete",
                    title: "The scene is ready to keep",
                    subtitle: "Open the Royal Chronicle reward or revisit the fort trail while the memory is fresh.",
                    tone: .inverse,
                    trailing: AnyView(GBBadge(title: "Reward ready", symbol: GBIcon.chronicle, emphasis: .chronicle))
                )

                if recapVisible {
                    Text(sceneRecap)
                        .font(.subheadline)
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.9))
                }

                NavigationLink {
                    ChronicleView(rewards: rewards, highlightRewardID: scene.rewardID)
                } label: {
                    Label("Open your Royal Chronicle reward", systemImage: GBIcon.chronicle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.gbSecondary)

                NavigationLink {
                    PlacesHubView(places: places)
                } label: {
                    Label("Review the fort trail", systemImage: GBIcon.place)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.gbSecondary)

                if showsPlanningChallenge {
                    Button(hasPlanningUpgrade ? "Bonus planning challenge complete" : (bonusPlanningVisible ? "Hide bonus planning challenge" : "Try the bonus planning challenge")) {
                        bonusPlanningVisible.toggle()
                        LessonFeedback.fire(.selection)
                    }
                    .buttonStyle(.gbSecondary)
                    .disabled(hasPlanningUpgrade)
                }
            }
        }
    }
}

private struct BonusPlanningCard: View {
    @Binding var chosenPlanSteps: Set<String>

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Bonus Challenge",
                    title: "Choose smart fort planning steps",
                    subtitle: "Pick any two choices that would help a mountain base stay ready."
                )

                ForEach(LessonPlanStep.starterSet) { step in
                    Button {
                        if chosenPlanSteps.contains(step.id) {
                            chosenPlanSteps.remove(step.id)
                        } else {
                            chosenPlanSteps.insert(step.id)
                        }
                        LessonFeedback.fire(.selection)
                    } label: {
                        HStack(spacing: GBSpacing.small) {
                            Image(systemName: chosenPlanSteps.contains(step.id) ? GBIcon.success : step.symbol)
                                .foregroundStyle(chosenPlanSteps.contains(step.id) ? GBColor.Accent.success : GBColor.Accent.place)
                            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                                Text(step.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(GBColor.Content.primary)
                                Text(step.detail)
                                    .font(.caption)
                                    .foregroundStyle(GBColor.Content.secondary)
                            }
                            Spacer()
                        }
                        .padding(GBSpacing.small)
                        .background(GBColor.Background.elevated, in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
