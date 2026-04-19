import SwiftUI

struct SceneLessonView: View {
    @EnvironmentObject private var appModel: AppModel
    let scene: StoryScene

    @State private var cardIndex = 0
    @State private var recallState = LessonRecallState()
    @State private var revealedMapAnchors = 0
    @State private var chosenPlanSteps: Set<String> = []
    @State private var hintVisible = false
    @State private var recapVisible = false

    private var progressValue: Double {
        let bonusStep = scene.number == 2 ? 1.0 : 0.0
        let completedCards = Double(cardIndex + 1)
        let answered = recallState.hasAnsweredCorrectly ? 1.0 : 0.0
        let denominator = Double(scene.interactionSteps.count) + 1.0 + bonusStep
        let planProgress = scene.number == 2 ? min(Double(chosenPlanSteps.count) / 2.0, 1.0) : 0.0
        return min((completedCards + Double(revealedMapAnchors > 0 ? 1 : 0) + planProgress + answered) / denominator, 1.0)
    }

    private var lessonCards: [SceneCardContent] {
        [
            SceneCardContent(id: "summary", eyebrow: "Story spark", title: scene.title, body: scene.childSafeSummary, symbol: "book.closed.fill"),
            SceneCardContent(id: "fact", eyebrow: "Remember this", title: scene.keyFact, body: scene.narrativeObjective, symbol: "sparkles.rectangle.stack.fill"),
            SceneCardContent(id: "timeline", eyebrow: "Chronicle moment", title: scene.timelineMarker, body: "This is the moment you will remember when you open the Royal Chronicle.", symbol: "clock.arrow.circlepath")
        ]
    }

    private var currentStepTitle: String {
        switch cardIndex {
        case 0: return "Step 1 of 3, hear the story"
        case 1: return "Step 2 of 3, spot the big idea"
        default: return "Step 3 of 3, mark the moment"
        }
    }

    private var nextCardButtonTitle: String {
        cardIndex == lessonCards.count - 1 ? "Move to place clues" : "Continue story"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SceneHeaderCard(scene: scene, progressValue: progressValue, mastery: appModel.lessonStore.mastery(for: scene.id))

                VStack(alignment: .leading, spacing: 12) {
                    Text(currentStepTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)

                    TabView(selection: $cardIndex) {
                        ForEach(Array(lessonCards.enumerated()), id: \.offset) { index, card in
                            StoryCardView(card: card, accentText: scene.timelineMarker, cardNumber: index + 1, totalCards: lessonCards.count)
                                .padding(.horizontal, 4)
                                .tag(index)
                        }
                    }
#if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
#endif
                    .frame(height: 340)

                    HStack(spacing: 8) {
                        ForEach(0..<lessonCards.count, id: \.self) { index in
                            Capsule()
                                .fill(index == cardIndex ? Color.orange : Color.orange.opacity(0.18))
                                .frame(width: index == cardIndex ? 28 : 10, height: 10)
                        }
                    }

                    HStack(spacing: 12) {
                        if cardIndex > 0 {
                            Button("Back") {
                                cardIndex = max(cardIndex - 1, 0)
                                LessonFeedback.fire(.selection)
                            }
                            .buttonStyle(.bordered)
                        }

                        Spacer()

                        Button(nextCardButtonTitle) {
                            cardIndex = min(cardIndex + 1, lessonCards.count - 1)
                            LessonFeedback.fire(.selection)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                MapAnchorCard(scene: scene, revealedMapAnchors: $revealedMapAnchors)

                if scene.number == 2 {
                    FortPlanningCard(chosenPlanSteps: $chosenPlanSteps)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button(hintVisible ? "Hide clue" : "Need a clue?") {
                        hintVisible.toggle()
                        LessonFeedback.fire(.reveal)
                    }
                    .buttonStyle(.bordered)

                    if hintVisible {
                        GuidanceCard(
                            title: "Story clue",
                            message: curatedHint,
                            systemImage: "lightbulb"
                        )
                    }

                    if recapVisible, recallState.hasAnsweredCorrectly {
                        GuidanceCard(
                            title: "You remembered it",
                            message: sceneRecap,
                            systemImage: "text.book.closed"
                        )
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

                if recallState.hasAnsweredCorrectly {
                    NavigationLink {
                        ChronicleView(rewards: appModel.content.rewards, highlightRewardID: scene.rewardID)
                    } label: {
                        Label("Open your Royal Chronicle reward", systemImage: "book.closed.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Scene \(scene.number)")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .background(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97, opacity: 1.0))
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(scene.timelineMarker.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(mastery?.rawValue ?? "Ready to learn")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                    .foregroundStyle(.orange)
            }
            Text(scene.title)
                .font(.title2.bold())
            Text(scene.narrativeObjective)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: progressValue)
                .tint(.orange)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Royal Chronicle reward")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(scene.rewardID.replacingOccurrences(of: "reward-", with: "").replacingOccurrences(of: "-", with: " ").capitalized)
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                Text("Small steps, one clear finish")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct StoryCardView: View {
    let card: SceneCardContent
    let accentText: String
    let cardNumber: Int
    let totalCards: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(card.eyebrow.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(cardNumber)/\(totalCards)")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            Image(systemName: card.symbol)
                .font(.system(size: 42))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.orange.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text(card.title)
                .font(.title3.bold())
            Text(card.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Label(accentText, systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.white, Color.orange.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct MapAnchorCard: View {
    let scene: StoryScene
    @Binding var revealedMapAnchors: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Place clues")
                    .font(.headline)
                Spacer()
                Text("\(revealedMapAnchors)/\(scene.mapAnchors.count) found")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text("Reveal the places from this moment one by one.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(scene.mapAnchors.enumerated()), id: \.offset) { index, anchor in
                HStack(spacing: 12) {
                    Image(systemName: index < revealedMapAnchors ? "mappin.circle.fill" : "mappin.circle")
                        .foregroundStyle(index < revealedMapAnchors ? .orange : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(index < revealedMapAnchors ? anchor : "Hidden place clue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(index < revealedMapAnchors ? "This place is now part of your scene map." : "Tap reveal when you are ready for the next clue.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button(revealedMapAnchors == scene.mapAnchors.count ? "All place clues found" : "Reveal next place clue") {
                let nextValue = min(revealedMapAnchors + 1, scene.mapAnchors.count)
                if nextValue != revealedMapAnchors {
                    revealedMapAnchors = nextValue
                    LessonFeedback.fire(nextValue == scene.mapAnchors.count ? .success : .reveal)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct FortPlanningCard: View {
    @Binding var chosenPlanSteps: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planning practice")
                .font(.headline)
            Text("Pick two smart fort choices to prepare a mountain base.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(LessonPlanStep.starterSet) { step in
                Button {
                    if chosenPlanSteps.contains(step.id) {
                        chosenPlanSteps.remove(step.id)
                    } else {
                        chosenPlanSteps.insert(step.id)
                    }
                    LessonFeedback.fire(.selection)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: chosenPlanSteps.contains(step.id) ? "checkmark.circle.fill" : step.symbol)
                            .foregroundStyle(chosenPlanSteps.contains(step.id) ? .green : .orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .foregroundStyle(.primary)
                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct GuidanceCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick recall")
                .font(.headline)
            Text("One last check before you collect your Chronicle reward.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(question.question)
                .font(.body)

            ForEach(choices) { choice in
                let isSelected = selectedChoiceID == choice.id
                Button {
                    selectedChoiceID = choice.id
                    LessonFeedback.fire(.selection)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(isSelected ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(choice.title)
                                .foregroundStyle(.primary)
                            Text(choice.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button(completed ? "Answer checked" : "Collect my answer") {
                onSubmit()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedChoiceID == nil || completed)

            if let feedbackText {
                Text(feedbackText)
                    .font(.subheadline)
                    .foregroundStyle(completed ? .green : .secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(completed ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
