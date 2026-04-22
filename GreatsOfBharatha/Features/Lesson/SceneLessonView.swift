import SwiftUI

struct SceneLessonView: View {
    @EnvironmentObject private var appModel: AppModel
    let scene: StoryScene

    @State private var cardIndex = 0
    @State private var recallState = LessonRecallState()
    @State private var revealedMapAnchors = 0
    @State private var chosenPlanSteps: Set<String> = []
    @State private var hintVisible = false

    private var reward: ChronicleReward? {
        appModel.content.rewards.first(where: { $0.id == scene.rewardID })
    }

    private var lessonCards: [SceneCardContent] {
        [
            SceneCardContent(
                id: "hook",
                eyebrow: "Hook card",
                title: scene.timelineMarker,
                body: scene.childSafeSummary,
                symbol: GBIcon.story,
                accent: scene.mapAnchors.first ?? scene.timelineMarker
            ),
            SceneCardContent(
                id: "meaning",
                eyebrow: "Meaning card",
                title: scene.keyFact,
                body: scene.narrativeObjective,
                symbol: GBIcon.reward,
                accent: "Why it matters"
            ),
            SceneCardContent(
                id: "anchor",
                eyebrow: "Anchor card",
                title: scene.recallPrompt.answer,
                body: scene.recallPrompt.supportText,
                symbol: GBIcon.place,
                accent: "Keep this hook"
            )
        ]
    }

    private var progressValue: Double {
        let storyProgress = Double(cardIndex + 1) / Double(max(lessonCards.count, 1))
        let placeProgress = min(Double(revealedMapAnchors) / Double(max(scene.mapAnchors.count, 1)), 1)
        let planningProgress = scene.number == 2 ? min(Double(chosenPlanSteps.count) / 2, 1) : 1
        let recallProgress = recallState.selectedChoiceID == nil ? 0.2 : (recallState.hasAnsweredCorrectly ? 1 : 0.55)
        let total = storyProgress + placeProgress + planningProgress + recallProgress
        return min(total / 4, 1)
    }

    private var currentCard: SceneCardContent {
        lessonCards[cardIndex]
    }

    private var nextCardButtonTitle: String {
        cardIndex == lessonCards.count - 1 ? "Go to place clues" : "Next card"
    }

    private var sceneChoices: [LessonChoice] {
        var choices = scene.mapAnchors.map {
            LessonChoice(id: $0.lowercased().replacingOccurrences(of: " ", with: "-"), title: $0, detail: "A place clue from this scene")
        }
        if !choices.contains(where: { normalized($0.title) == normalized(scene.recallPrompt.answer) }) {
            choices.insert(LessonChoice(id: scene.id + "-answer", title: scene.recallPrompt.answer, detail: "The memory hook you want to keep"), at: 0)
        }
        return Array(choices.prefix(3))
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    SceneAdventureHero(
                        scene: scene,
                        reward: reward,
                        progressValue: progressValue,
                        mastery: appModel.lessonStore.mastery(for: scene.id)
                    )

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Adventure path",
                                title: currentCard.eyebrow,
                                subtitle: "Move through one clear card at a time, then answer from memory."
                            )

                            GBQuestProgress(
                                steps: [
                                    .story,
                                    GBQuestProgress.Step(id: "meaning", title: "Meaning", symbol: GBIcon.reward),
                                    .place,
                                    .chronicle
                                ],
                                currentStepID: currentQuestStepID
                            )
                        }
                    }

                    ActiveStoryCard(
                        card: currentCard,
                        cardNumber: cardIndex + 1,
                        totalCards: lessonCards.count
                    )

                    HStack(spacing: GBSpacing.small) {
                        if cardIndex > 0 {
                            Button("Back") {
                                cardIndex = max(cardIndex - 1, 0)
                                LessonFeedback.fire(.selection)
                            }
                            .buttonStyle(.gbSecondary)
                        }

                        Button(nextCardButtonTitle) {
                            cardIndex = min(cardIndex + 1, lessonCards.count - 1)
                            LessonFeedback.fire(.selection)
                        }
                        .buttonStyle(.gbPrimary(.story))
                    }

                    PlaceClueTrailCard(scene: scene, revealedMapAnchors: $revealedMapAnchors)

                    if scene.number == 2 {
                        FortPlanningCard(chosenPlanSteps: $chosenPlanSteps)
                    }

                    GBSurface(style: .plain) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            Button(hintVisible ? "Hide clue" : "Need a clue?") {
                                hintVisible.toggle()
                                LessonFeedback.fire(.reveal)
                            }
                            .buttonStyle(.gbSecondary)

                            if hintVisible {
                                GuidanceCard(
                                    title: "Helpful clue",
                                    message: curatedHint,
                                    systemImage: "lightbulb.fill"
                                )
                            }
                        }
                    }

                    RecallPanel(
                        question: scene.recallPrompt,
                        choices: sceneChoices,
                        selectedChoiceID: $recallState.selectedChoiceID,
                        feedbackText: recallState.feedbackText,
                        completed: recallState.hasAnsweredCorrectly,
                        onSubmit: submitRecall
                    )

                    if recallState.hasAnsweredCorrectly, let reward {
                        RewardTransitionCard(reward: reward, scene: scene)

                        NavigationLink {
                            ChronicleView(rewards: appModel.content.rewards, highlightRewardID: reward.id)
                        } label: {
                            Label("Open my Chronicle page", systemImage: GBIcon.chronicle)
                        }
                        .buttonStyle(.gbPrimary(.chronicle))
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
    }

    private var currentQuestStepID: String {
        if recallState.hasAnsweredCorrectly {
            return "chronicle"
        }
        if cardIndex == 1 {
            return "meaning"
        }
        if cardIndex == 2 || revealedMapAnchors > 0 {
            return "place"
        }
        return "story"
    }

    private func submitRecall() {
        guard let selectedChoiceID = recallState.selectedChoiceID else { return }

        let correctAnswer = normalized(scene.recallPrompt.answer)
        let selectedTitle = sceneChoices.first(where: { $0.id == selectedChoiceID })?.title ?? ""

        if normalized(selectedTitle) == correctAnswer {
            recallState.hasAnsweredCorrectly = true
            recallState.feedbackText = "Yes. \(scene.recallPrompt.supportText)"
            let mastery: MasteryState = scene.number == 2 && chosenPlanSteps.count >= 2 ? .observedClosely : .understood
            appModel.lessonStore.markScene(scene.id, mastery: mastery)
            LessonFeedback.fire(.success)
        } else {
            recallState.hasAnsweredCorrectly = false
            recallState.feedbackText = "Almost. \(scene.recallPrompt.supportText)"
            appModel.lessonStore.markScene(scene.id, mastery: .witnessed)
            LessonFeedback.fire(.warning)
        }
    }

    private var curatedHint: String {
        if scene.number == 1 {
            return "The first scene begins at the fort where Shivaji Maharaj was born with Jijabai nearby."
        }
        return "Torna is the breakthrough fort. The answer you want is the fort that became the early capital after that."
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
    let accent: String
}

private struct SceneAdventureHero: View {
    let scene: StoryScene
    let reward: ChronicleReward?
    let progressValue: Double
    let mastery: MasteryState?

    var body: some View {
        GBSurface(style: .accented(.story)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text("SCENE \(scene.number)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.84))
                        Text(scene.title)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(GBColor.Content.inverse)
                        Text(scene.childSafeSummary)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.92))
                    }

                    Spacer()

                    GBBadge(
                        title: mastery?.rawValue ?? "Ready",
                        symbol: mastery == nil ? GBIcon.story : "star.fill",
                        emphasis: mastery == nil ? .neutral : .chronicle
                    )
                }

                ProgressView(value: progressValue)
                    .tint(GBColor.Content.inverse)

                HStack(spacing: GBSpacing.small) {
                    heroChip(title: scene.timelineMarker, symbol: GBIcon.timeline)
                    if let reward {
                        heroChip(title: reward.title, symbol: GBIcon.chronicle)
                    }
                }
            }
        }
    }

    private func heroChip(title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(GBColor.Content.inverse)
            .padding(.horizontal, GBSpacing.xSmall)
            .padding(.vertical, GBSpacing.xxxSmall)
            .background(.white.opacity(0.12), in: Capsule())
    }
}

private struct ActiveStoryCard: View {
    let card: SceneCardContent
    let cardNumber: Int
    let totalCards: Int

    var body: some View {
        GBSurface(style: .plain, padding: GBSpacing.large) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: "\(cardNumber) of \(totalCards)", symbol: "square.stack.3d.up.fill", emphasis: .story)
                    Spacer()
                    Text(card.eyebrow)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Accent.story)
                }

                Image(systemName: card.symbol)
                    .font(.system(size: 34))
                    .foregroundStyle(GBColor.Content.inverse)
                    .frame(width: 68, height: 68)
                    .background(GBColor.gradient(for: .story), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))

                Text(card.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(GBColor.Content.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(card.body)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(card.accent, systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GBColor.Accent.story)
            }
        }
        .accessibilityLabel("\(card.eyebrow). \(currentSummary)")
    }

    private var currentSummary: String {
        "\(card.title). \(card.body)"
    }
}

private struct PlaceClueTrailCard: View {
    let scene: StoryScene
    @Binding var revealedMapAnchors: Int

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Place clue trail",
                    title: "Follow the fort path",
                    subtitle: "Reveal one clue at a time so the story keeps its shape on the map."
                )

                ForEach(Array(scene.mapAnchors.enumerated()), id: \.offset) { index, anchor in
                    HStack(spacing: GBSpacing.small) {
                        Image(systemName: index < revealedMapAnchors ? "mappin.circle.fill" : "mappin.circle")
                            .foregroundStyle(index < revealedMapAnchors ? GBColor.Accent.place : GBColor.Content.secondary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                            Text(index < revealedMapAnchors ? anchor : "Hidden place clue")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GBColor.Content.primary)
                            Text(index < revealedMapAnchors ? "Keep this place in your mind for the recall card." : "Reveal the next clue when you are ready.")
                                .font(.caption)
                                .foregroundStyle(GBColor.Content.secondary)
                        }

                        Spacer()
                    }
                    .padding(GBSpacing.small)
                    .background(GBColor.Background.elevated, in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
                }

                Button(revealedMapAnchors == scene.mapAnchors.count ? "All clues found" : "Reveal next clue") {
                    let nextValue = min(revealedMapAnchors + 1, scene.mapAnchors.count)
                    if nextValue != revealedMapAnchors {
                        revealedMapAnchors = nextValue
                        LessonFeedback.fire(nextValue == scene.mapAnchors.count ? .success : .reveal)
                    }
                }
                .buttonStyle(.gbPrimary(.place))
            }
        }
    }
}

private struct FortPlanningCard: View {
    @Binding var chosenPlanSteps: Set<String>

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Planning practice",
                    title: "Pick two strong fort moves",
                    subtitle: "Choose the ideas that would help a mountain fort stay ready."
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
                            Image(systemName: chosenPlanSteps.contains(step.id) ? "checkmark.circle.fill" : step.symbol)
                                .foregroundStyle(chosenPlanSteps.contains(step.id) ? GBColor.Accent.success : GBColor.Accent.story)
                                .font(.title3)
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

private struct GuidanceCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: GBSpacing.small) {
            Image(systemName: systemImage)
                .foregroundStyle(GBColor.Accent.story)
            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(GBColor.Content.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(GBColor.Content.secondary)
            }
            Spacer()
        }
        .padding(GBSpacing.small)
        .background(GBColor.Accent.story.opacity(0.10), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
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
                    eyebrow: "Recall card",
                    title: "Say it from memory",
                    subtitle: "Pick the answer that matches the story hook you just learned."
                )

                Text(question.question)
                    .font(.body.weight(.medium))
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
                        .background(GBColor.Background.elevated, in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button(completed ? "Answer locked in" : "Check my answer") {
                    onSubmit()
                }
                .buttonStyle(.gbPrimary(.story))
                .disabled(selectedChoiceID == nil || completed)

                if let feedbackText {
                    Text(feedbackText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(completed ? GBColor.Accent.success : GBColor.Content.primary)
                        .padding(GBSpacing.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((completed ? GBColor.Accent.success : GBColor.Accent.story).opacity(0.12), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
                }
            }
        }
    }
}

private struct RewardTransitionCard: View {
    let reward: ChronicleReward
    let scene: StoryScene

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: "Reward earned", symbol: GBIcon.success, emphasis: .chronicle)
                    Spacer()
                    Text("Royal Chronicle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.84))
                }

                Text(reward.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(GBColor.Content.inverse)
                Text(reward.meaning)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(GBColor.Content.inverse.opacity(0.92))

                Label("You remembered \(scene.timelineMarker.lowercased())", systemImage: GBIcon.chronicle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GBColor.Content.inverse)
            }
        }
    }
}
