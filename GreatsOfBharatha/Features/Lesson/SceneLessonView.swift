import SwiftUI

// ─────────────────────────────────────────────────────────────
// SceneLessonView.swift — kid-friendly 4-phase lesson flow.
// Phase 1: GBFlashCardDeck (story cards, swipeable)
// Phase 2: Place reveal with real Apple Maps (GBFortMapView)
// Phase 3: MCQ recall (no text input, no shame on wrong answer)
// Phase 4: GBRewardReveal (chronicle keepsake ceremony)
// ─────────────────────────────────────────────────────────────

struct SceneLessonView: View {
    @EnvironmentObject private var appModel: AppModel
    let scene: StoryScene

    private enum LessonPhase: CaseIterable, Equatable {
        case storyCards, placeReveal, recall, reward
    }

    @State private var currentPhase: LessonPhase = .storyCards
    @State private var recallState = LessonRecallState()
    @State private var storyExposureRecorded = false
    @State private var cachedMCQChoices: [LessonChoice] = []
    @StateObject private var narrator = GBNarrator()

    // MARK: - Derived data

    private var reward: ChronicleReward? {
        appModel.content.rewards.first(where: { $0.id == scene.rewardID })
    }

    private var recallChallenge: RecallChallenge {
        appModel.content.activeHeroArc.scene(withID: scene.id)?.primaryRecallChallenge
            ?? RecallChallenge(
                id: scene.id + "-recall",
                promptType: .openPrompt,
                prompt: scene.recallPrompt.question,
                correctAnswers: [scene.recallPrompt.answer],
                hintLadder: [RecallHint(level: 1, title: "Clue", body: scene.recallPrompt.supportText)],
                feedback: RecallFeedback(
                    success: "Yes! \(scene.recallPrompt.supportText)",
                    recovery: "Almost. \(scene.recallPrompt.supportText)"
                ),
                masteryContribution: .understood
            )
    }

    private var primaryPlace: Place? {
        scene.mapAnchors.compactMap { id in
            appModel.content.places.first(where: { $0.id == id })
        }.first
    }

    // MCQ choices: generated once on appear, shuffled for variety
    private func makeMCQChoices() -> [LessonChoice] {
        var titles = recallChallenge.correctAnswers
        for anchor in scene.mapAnchors
        where !titles.contains(where: {
            LessonRecallEngine.normalized($0) == LessonRecallEngine.normalized(anchor)
        }) {
            titles.append(anchor)
        }
        return Array(titles.prefix(4).enumerated()).map { index, title in
            LessonChoice(
                id: "\(scene.id)-choice-\(index)",
                title: title,
                detail: LessonRecallEngine.answerMatches(title, challenge: recallChallenge)
                    ? "The answer to keep"
                    : "A place from this scene"
            )
        }.shuffled()
    }

    // Story cards → GBFlashCardData
    private var flashCards: [GBFlashCardData] {
        [
            GBFlashCardData(
                id: scene.id + "-hook",
                iconName: GBIcon.story,
                title: scene.timelineMarker,
                storyBeat: scene.childSafeSummary,
                emphasis: .story
            ),
            GBFlashCardData(
                id: scene.id + "-meaning",
                iconName: GBIcon.reward,
                title: scene.keyFact,
                storyBeat: scene.narrativeObjective,
                emphasis: .story
            ),
            GBFlashCardData(
                id: scene.id + "-anchor",
                iconName: GBIcon.place,
                title: scene.recallPrompt.answer,
                storyBeat: scene.recallPrompt.supportText,
                emphasis: .story
            )
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            GBColor.Background.app.ignoresSafeArea()

            VStack(spacing: 0) {
                // Phase dots
                phaseDotRow
                    .padding(.top, GBSpacing.small)
                    .padding(.bottom, GBSpacing.xSmall)

                // Phase content
                Group {
                    switch currentPhase {
                    case .storyCards:
                        storyCardView
                    case .placeReveal:
                        placeRevealView
                    case .recall:
                        recallView
                    case .reward:
                        rewardView
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(GBMotion.standard, value: currentPhase)
            }
        }
        .navigationTitle(scene.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear(perform: recordStoryExposureIfNeeded)
        .onDisappear { narrator.stop() }
    }

    // MARK: - Phase indicator

    private var phaseDotRow: some View {
        HStack(spacing: 10) {
            ForEach(Array(LessonPhase.allCases.enumerated()), id: \.offset) { _, phase in
                dotView(phase)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(phaseAccessibilityLabel)
    }

    private func dotView(_ phase: LessonPhase) -> some View {
        let phaseIndex = LessonPhase.allCases.firstIndex(of: phase) ?? 0
        let currentIndex = LessonPhase.allCases.firstIndex(of: currentPhase) ?? 0
        let isDone    = phaseIndex < currentIndex
        let isCurrent = phase == currentPhase

        return Circle()
            .fill(isDone ? GBColor.Place.primary : isCurrent ? GBColor.Story.primary : GBColor.Content.tertiary)
            .frame(width: isCurrent ? 10 : 8, height: isCurrent ? 10 : 8)
            .animation(GBMotion.quick, value: currentPhase)
    }

    private var phaseAccessibilityLabel: String {
        switch currentPhase {
        case .storyCards:  return "Step 1 of 4: Story cards"
        case .placeReveal: return "Step 2 of 4: Where it happened"
        case .recall:      return "Step 3 of 4: Quick quiz"
        case .reward:      return "Step 4 of 4: Your treasure"
        }
    }

    // MARK: - Phase 1: One big story card

    private var storyCardView: some View {
        let narration = storyNarration

        return ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Image("Chapter1ShivneriStory")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        Label("Listen first", systemImage: "sparkles")
                            .font(GBFont.ui(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, GBSpacing.small)
                            .padding(.vertical, GBSpacing.xxSmall)
                            .background(.black.opacity(0.28), in: Capsule())
                            .padding(GBSpacing.small)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: GBSpacing.small) {
                    Text("Chapter \(scene.number)")
                        .font(GBFont.ui(size: 13, weight: .heavy))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(GBColor.Story.primary)

                    Text(scene.title)
                        .font(GBFont.display(size: 28, weight: .bold))
                        .foregroundStyle(GBColor.Content.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(scene.childSafeSummary)
                        .font(GBFont.story(size: 20))
                        .foregroundStyle(GBColor.Content.secondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                narrationControls(text: narration, id: "\(scene.id)-story")

                Button {
                    narrator.stop()
                    GBHaptic.stepAdvance()
                    advanceTo(.placeReveal)
                } label: {
                    Label("Show me the fort", systemImage: "map.fill")
                        .frame(maxWidth: .infinity, minHeight: GBTouch.button)
                }
                .buttonStyle(.gbPrimary(.story))
                .accessibilityLabel("Show me the fort")
                .accessibilityHint("Moves to the map for this chapter.")
            }
            .padding(GBSpacing.medium)
            .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                    .stroke(GBColor.Story.light, lineWidth: 2)
            )
            .padding(.horizontal, GBSpacing.medium)
            .padding(.top, GBSpacing.small)
        }
        .accessibilityElement(children: .contain)
    }

    private var storyNarration: String {
        "Chapter \(scene.number). \(scene.title). \(scene.childSafeSummary) Next, tap Show me the fort."
    }

    private func narrationControls(text: String, id: String) -> some View {
        HStack(spacing: GBSpacing.xSmall) {
            narrationButton(title: "Listen", icon: "speaker.wave.2.fill") {
                narrator.speak(id: id, text: text)
            }
            narrationButton(title: "Repeat", icon: "arrow.clockwise") {
                narrator.repeatLast()
            }
            narrationButton(title: "Stop", icon: "stop.fill") {
                narrator.stop()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func narrationButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(GBFont.ui(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(GBColor.Story.primary)
        .accessibilityHint(title == "Stop" ? "Stops read aloud." : "Reads this story card aloud.")
    }

    // MARK: - Phase 2: Place reveal

    private var placeRevealView: some View {
        VStack(spacing: GBSpacing.medium) {
            Text("Where it happened!")
                .font(GBFont.display(size: 24, weight: .bold))
                .foregroundStyle(GBColor.Content.primary)
                .padding(.horizontal, GBSpacing.medium)

            if let place = primaryPlace {
                GBFortMapView(place: place)
                    .frame(height: 260)
                    .padding(.horizontal, GBSpacing.medium)

                HStack(spacing: GBSpacing.small) {
                    Image(systemName: GBIcon.place)
                        .font(.system(size: 28))
                        .foregroundStyle(GBColor.Place.primary)
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        Text(place.name)
                            .font(GBFont.display(size: 20, weight: .bold))
                            .foregroundStyle(GBColor.Content.primary)
                        Text(place.primaryEvent)
                            .font(GBFont.story(size: 15, italic: true))
                            .foregroundStyle(GBColor.Content.secondary)
                    }
                }
                .padding(.horizontal, GBSpacing.medium)

                narrationControls(
                    text: "This is \(place.name). \(place.primaryEvent). When you are ready, tap Got it.",
                    id: "\(scene.id)-place"
                )
                .padding(.horizontal, GBSpacing.medium)
            } else {
                // No place data — skip straight to recall
                Text("Tap continue to test your memory.")
                    .font(GBFont.story(size: 17))
                    .foregroundStyle(GBColor.Content.secondary)
                    .padding()
            }

            Spacer()

            Button("Got it!") {
                GBHaptic.stepAdvance()
                advanceTo(.recall)
            }
            .buttonStyle(.gbPrimary(.place))
            .padding(.horizontal, GBSpacing.medium)
            .padding(.bottom, GBSpacing.medium)
        }
    }

    // MARK: - Phase 3: MCQ recall

    private var recallView: some View {
        SimpleRecallView(
            challenge: recallChallenge,
            choices: cachedMCQChoices,
            recallState: recallState,
            onChoiceSelected: { choiceID in
                selectRecallChoice(choiceID: choiceID)
            },
            onCheckChoice: {
                checkSelectedRecallChoice()
            },
            onAdvance: {
                withAnimation(GBMotion.ceremony) { currentPhase = .reward }
            }
        )
    }

    // MARK: - Phase 4: Reward

    private var rewardView: some View {
        ScrollView {
            VStack(spacing: GBSpacing.medium) {
                if let reward {
                    GBRewardReveal(
                        title: reward.title,
                        subtitle: scene.timelineMarker,
                        iconName: GBIcon.chronicle,
                        quote: reward.meaning,
                        mastery: .understood,
                        onDismiss: nil
                    )

                    NavigationLink {
                        ChronicleView(rewards: appModel.content.rewards, highlightRewardID: reward.id)
                    } label: {
                        Label("See in my Album", systemImage: GBIcon.chronicle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.gbPrimary(.chronicle))
                    .padding(.horizontal, GBSpacing.medium)
                } else {
                    Text("Adventure complete!")
                        .font(GBFont.display(size: 22, weight: .bold))
                        .padding()
                }
            }
        }
    }

    // MARK: - Recall logic

    private func selectRecallChoice(choiceID: String) {
        guard !recallState.hasAnsweredCorrectly else { return }
        recallState.selectedChoiceID = choiceID
        recallState.feedbackText = nil
    }

    private func checkSelectedRecallChoice() {
        guard let choiceID = recallState.selectedChoiceID,
              let choice = cachedMCQChoices.first(where: { $0.id == choiceID }) else { return }

        let evaluation = LessonRecallEngine.submit(
            state: recallState,
            challenge: recallChallenge,
            typedAnswer: "",
            selectedChoiceTitle: choice.title,
            successMastery: recallChallenge.masteryContribution
        )

        recallState.feedbackText = evaluation.feedbackText
        recallState.revealedHintLevel = evaluation.revealedHintLevel
        recallState.recognitionRescueUnlocked = evaluation.recognitionRescueUnlocked
        recallState.hasAnsweredCorrectly = evaluation.wasSuccessful

        appModel.lessonStore.recordRecallOutcome(
            subjectID: scene.id,
            promptType: recallChallenge.promptType,
            wasSuccessful: evaluation.wasSuccessful,
            mastery: evaluation.masteryAwarded,
            detail: evaluation.wasSuccessful ? "Recall succeeded (MCQ)" : "Recall attempt (MCQ)"
        )

        if evaluation.wasSuccessful {
            LessonFeedback.fire(.success)
        }
    }

    private func advanceTo(_ phase: LessonPhase) {
        withAnimation(GBMotion.standard) { currentPhase = phase }
    }

    private func recordStoryExposureIfNeeded() {
        guard !storyExposureRecorded else { return }
        storyExposureRecorded = true
        cachedMCQChoices = makeMCQChoices()
        appModel.lessonStore.recordStoryExposure(for: scene.id, detail: "Scene \(scene.number) opened")
    }
}

// ── MCQ recall view ───────────────────────────────────────────
private struct SimpleRecallView: View {
    let challenge: RecallChallenge
    let choices: [LessonChoice]
    let recallState: LessonRecallState
    var onChoiceSelected: ((String) -> Void)?
    var onCheckChoice: (() -> Void)?
    var onAdvance: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            // Question
            GBSurface(style: .elevated) {
                Text(challenge.prompt)
                    .font(GBFont.story(size: 21))
                    .foregroundStyle(GBColor.Content.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, GBSpacing.medium)
            .padding(.top, GBSpacing.small)

            Text("Pick one choice before you collect your Chronicle reward.")
                .font(GBFont.ui(size: 15, weight: .semibold))
                .foregroundStyle(GBColor.Content.secondary)
                .padding(.horizontal, GBSpacing.medium)
                .accessibilityIdentifier("recall-choice-helper")

            // Choice buttons
            VStack(spacing: GBSpacing.small) {
                ForEach(choices) { choice in
                    choiceButton(choice)
                }
            }
            .padding(.horizontal, GBSpacing.medium)

            // Warm feedback (wrong answer — no shame)
            if let feedback = recallState.feedbackText,
               !feedback.isEmpty,
               !recallState.hasAnsweredCorrectly {
                HStack(alignment: .top, spacing: GBSpacing.xSmall) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(GBColor.Story.primary)
                    Text(feedback)
                        .font(GBFont.ui(size: 14, weight: .semibold))
                        .foregroundStyle(GBColor.Story.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(GBSpacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                        .fill(GBColor.Story.bg)
                )
                .padding(.horizontal, GBSpacing.medium)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            // Explicit choice CTA makes this unmistakably multiple choice.
            if recallState.hasAnsweredCorrectly {
                Button("Open my treasure!") {
                    GBHaptic.chronicleReveal()
                    onAdvance?()
                }
                .buttonStyle(.gbPrimary(.chronicle))
                .padding(.horizontal, GBSpacing.medium)
                .padding(.bottom, GBSpacing.medium)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button("Check my choice") {
                    GBHaptic.stepAdvance()
                    onCheckChoice?()
                }
                .buttonStyle(.gbPrimary(.story))
                .disabled(recallState.selectedChoiceID == nil)
                .padding(.horizontal, GBSpacing.medium)
                .padding(.bottom, GBSpacing.medium)
                .accessibilityIdentifier("recall-check-choice-button")
            }
        }
        .animation(GBMotion.quick, value: recallState.hasAnsweredCorrectly)
    }

    private func choiceButton(_ choice: LessonChoice) -> some View {
        let isSelected = recallState.selectedChoiceID == choice.id
        let isCorrect  = LessonRecallEngine.answerMatches(choice.title, challenge: challenge)
        let hasChecked = recallState.feedbackText != nil || recallState.hasAnsweredCorrectly
        let showRight  = isCorrect && recallState.hasAnsweredCorrectly
        let showWrong  = hasChecked && isSelected && !isCorrect

        return Button {
            guard !recallState.hasAnsweredCorrectly else { return }
            LessonFeedback.fire(.selection)
            onChoiceSelected?(choice.id)
        } label: {
            HStack(spacing: GBSpacing.small) {
                ZStack {
                    Circle()
                        .fill(iconBackground(isSelected: isSelected, showRight: showRight, showWrong: showWrong))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconName(isSelected: isSelected, showRight: showRight, showWrong: showWrong))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(showRight || showWrong || isSelected ? .white : GBColor.Content.tertiary)
                }

                Text(choice.title)
                    .font(GBFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(labelColor(showRight: showRight, showWrong: showWrong))

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: GBTouch.button)
            .padding(.horizontal, GBSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .fill(cardBackground(isSelected: isSelected, showRight: showRight, showWrong: showWrong))
                    .overlay(
                        RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                            .stroke(borderColor(isSelected: isSelected, showRight: showRight, showWrong: showWrong), lineWidth: isSelected ? 3 : 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(recallState.hasAnsweredCorrectly)
        .accessibilityIdentifier("recall-choice-\(choice.id)")
        .accessibilityLabel("Choice: \(choice.title)")
        .accessibilityValue(accessibilityValue(isSelected: isSelected, showRight: showRight, showWrong: showWrong))
        .accessibilityHint(recallState.hasAnsweredCorrectly ? "Choice checked" : "Tap to select this choice, then use Check my choice")
        .animation(GBMotion.quick, value: isSelected)
    }

    // ── Styling helpers ───────────────────────────────────────

    private func iconName(isSelected: Bool, showRight: Bool, showWrong: Bool) -> String {
        if showRight { return "checkmark" }
        if showWrong { return "xmark" }
        return isSelected ? "checkmark.circle.fill" : "circle"
    }

    private func iconBackground(isSelected: Bool, showRight: Bool, showWrong: Bool) -> Color {
        if showRight { return GBColor.Place.primary }
        if showWrong { return GBColor.State.danger }
        if isSelected { return GBColor.Story.primary }
        return GBColor.Background.panel
    }

    private func labelColor(showRight: Bool, showWrong: Bool) -> Color {
        if showRight { return GBColor.Place.primary }
        if showWrong { return GBColor.State.danger }
        return GBColor.Content.primary
    }

    private func cardBackground(isSelected: Bool, showRight: Bool, showWrong: Bool) -> Color {
        if showRight { return GBColor.Place.bg }
        if showWrong { return Color(red: 0.99, green: 0.91, blue: 0.91) }
        if isSelected { return GBColor.Story.bg }
        return GBColor.Background.surface
    }

    private func borderColor(isSelected: Bool, showRight: Bool, showWrong: Bool) -> Color {
        if showRight { return GBColor.Place.primary }
        if showWrong { return GBColor.State.danger }
        if isSelected { return GBColor.Story.primary }
        return GBColor.Background.panel
    }

    private func accessibilityValue(isSelected: Bool, showRight: Bool, showWrong: Bool) -> String {
        if showRight { return "selected, correct choice checked" }
        if showWrong { return "selected, try another choice" }
        return isSelected ? "selected" : "not selected"
    }
}
