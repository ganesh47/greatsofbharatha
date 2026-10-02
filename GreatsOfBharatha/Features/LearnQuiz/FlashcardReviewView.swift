import SwiftUI

struct FlashcardReviewView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let cards: [LearnQuizReviewCard]
    // The coordinator injects the durable, capture-isolated store adapter at the navigation boundary.
    var hooks: ReviewJourneyHooks?
    var now: () -> Date = Date.init

    @State private var archive = ReviewJourneyArchive()
    @State private var loaded = false
    @State private var saveFailed = false
    @State private var unsavedArchive: ReviewJourneyArchive?
    @FocusState private var answerFocused: Bool

    init(cards: [LearnQuizReviewCard], hooks: ReviewJourneyHooks? = nil, now: @escaping () -> Date = Date.init) {
        self.cards = cards
        self.hooks = hooks
        self.now = now
    }

    private var point: ReviewJourneyCheckpoint? { archive.checkpoint }
    private var currentCard: LearnQuizReviewCard? {
        guard let id = point?.currentTurn?.cardID else { return nil }
        return cards.first { $0.id == id }
    }
    private var learnedSceneIDs: Set<String> {
        Set(cards.filter { (appModel.lessonStore.mastery(for: $0.sceneID) ?? .witnessed) >= .understood }.map(\.sceneID))
    }
    private var descriptors: [ReviewJourneyCard] { cards.map(descriptor) }
    private var pendingBlocked: Bool { !archive.pendingEvidence.isEmpty }
    private var actionsBlocked: Bool { saveFailed || pendingBlocked }
    private var currentCheckedPrompt: ReviewJourneyCheckPrompt? {
        guard let card = currentCard else { return nil }
        return descriptor(card).checkPrompts.first { $0.id == point?.currentTurn?.checkedPromptID }
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    header
                    if hooks == nil {
                        GBSurface(style: .elevated) {
                            VStack(alignment: .leading, spacing: GBSpacing.small) {
                                Text("Your review path is getting ready.").gbHeadline()
                                Text("You can continue your chapter for now.").gbBody()
                                Button("All done") { dismiss() }.buttonStyle(.gbPrimary(.story))
                            }
                        }
                    } else if point?.phase == .complete {
                        completion
                    } else if let card = currentCard {
                        switch point?.phase {
                        case .prompt: prompt(card)
                        case .revealed: revealed(card)
                        case .result: result(card)
                        case .teaching: teaching(card)
                        case .complete, .none: EmptyView()
                        }
                    }
                    if actionsBlocked {
                        Text("Your last steps are still saving. Try again before continuing.")
                            .gbBody().accessibilityIdentifier("review-save-error")
                        Button("Try saving again") { retrySave() }.buttonStyle(.gbSecondary)
                    }
                    if point?.phase != .complete && hooks != nil {
                        Button("Finish for now") { dismiss() }
                            .buttonStyle(.gbSecondary).accessibilityIdentifier("review-finish-for-now")
                    }
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
#if os(iOS)
            .scrollDismissesKeyboard(.interactively)
#endif
            .background(GBColor.Background.app)
            .accessibilityIdentifier("review-journey-scroll")
        }
        .navigationTitle("Story Card Review")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { answerFocused = false }
                    .accessibilityIdentifier("review-dismiss-keyboard")
            }
        }
#endif
        .onAppear { load() }
    }

    private var header: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: "Review", symbol: "rectangle.on.rectangle.angled", emphasis: .chronicle, inverted: true)
                    Spacer()
                    if let point, point.currentTurn != nil {
                        Text("Card \(point.cursor + 1) of \(point.queue.count)")
                            .font(GBFont.ui(size: 14, weight: .heavy)).foregroundStyle(.white)
                    }
                }
                Text("A little remembering, with help whenever you want it.")
                    .font(GBFont.display(size: 25, weight: .bold)).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Cards that are ready to revisit come first.")
                    .font(GBFont.ui(size: 15, weight: .semibold)).foregroundStyle(.white)
            }
        }
    }

    private func prompt(_ card: LearnQuizReviewCard) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            cardFace(card, showAnswer: false, promptText: currentCheckedPrompt?.text)
            LearningNarrationControls(id: card.id + "-review-prompt", text: currentCheckedPrompt?.text ?? card.front)
            if point?.currentTurn?.isTaughtRevisit == true {
                Text("A small practice after the teaching. Helped practice counts as helped practice.").gbBody()
            }
            if currentCheckedPrompt != nil {
                Text("Try an answer before looking. You can also reveal it and tell us what you needed.").gbBody()
                TextField("Your answer", text: Binding(get: { point?.typedAnswer ?? "" }, set: { text in
                    commit(ReviewJourneyEngine.updateAnswer(text, in: archive))
                }), axis: .vertical)
                    .textFieldStyle(.roundedBorder).font(GBFont.ui(size: 20, weight: .semibold))
                    .focused($answerFocused).disabled(actionsBlocked).accessibilityIdentifier("review-answer")
                Text("The check uses this card’s answer wording; a different way of saying it may need help.")
                    .font(GBFont.ui(size: 14, weight: .regular)).foregroundStyle(GBColor.Content.secondary)
                Button {
                    answerFocused = false
                    commit(ReviewJourneyEngine.check(archive, card: descriptor(card), now: now()))
                } label: { Label("Check my answer", systemImage: "checkmark.circle") }
                    .buttonStyle(.gbPrimary(.chronicle))
                    .disabled(actionsBlocked || ChronicleQuizEngine.normalizedAnswer(point?.typedAnswer ?? "").isEmpty)
                    .accessibilityIdentifier("review-check")
            } else {
                Text("For this card, reveal the answer and tell us what your memory needed.").gbBody()
            }
            Button {
                answerFocused = false
                commit(ReviewJourneyEngine.reveal(archive))
            } label: { Label("Show me the answer", systemImage: "lightbulb.fill") }
                .buttonStyle(.gbSecondary).disabled(actionsBlocked).accessibilityIdentifier("review-reveal")
        }
    }

    private func revealed(_ card: LearnQuizReviewCard) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            cardFace(card, showAnswer: true)
            LearningNarrationControls(id: card.id + "-review-answer", text: card.back + ". " + card.meaning)
            Text("This is your own memory report. It is separate from a checked answer.").gbBody()
            Button { report(.knewIt, card: card) } label: { Label("I knew it", systemImage: "checkmark.circle.fill") }
                .buttonStyle(.gbPrimary(.chronicle)).accessibilityIdentifier("review-knew-it")
            Button { report(.neededClue, card: card) } label: { Label("Needed a clue", systemImage: "lightbulb.fill") }
                .buttonStyle(.gbSecondary).accessibilityIdentifier("review-needed-clue")
            Button { report(.teachAgain, card: card) } label: { Label("Teach me again", systemImage: "heart.text.square.fill") }
                .buttonStyle(.gbSecondary).accessibilityIdentifier("review-teach-again")
        }.disabled(actionsBlocked)
    }

    private func result(_ card: LearnQuizReviewCard) -> some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text(resultTitle).gbTitle().accessibilityIdentifier("review-result-title")
                Text(resultDetail).gbBody()
                if point?.currentEvidence?.kind == .incorrectChecked {
                    Text("Let’s look at the answer together: \(card.back)").gbStory()
                    Text(card.meaning).gbStory()
                }
                if let due = archive.schedulesByCardID[card.id]?.nextDueAt {
                    Text(due <= now() ? "This card is ready for more teaching." : "Next revisit: \(due.formatted(date: .abbreviated, time: .shortened))")
                        .font(GBFont.ui(size: 15, weight: .semibold)).foregroundStyle(GBColor.Content.secondary)
                }
                Button(point?.currentEvidence?.response == .teachAgain ? "Learn it together" : "Continue") {
                    commit(ReviewJourneyEngine.continueAfterResult(archive))
                }.buttonStyle(.gbPrimary(.story)).disabled(actionsBlocked).accessibilityIdentifier("review-continue")
            }
        }
    }

    private func teaching(_ card: LearnQuizReviewCard) -> some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("Learn it together").gbTitle()
                if let scene = LearnQuizPilotData.scenes.first(where: { $0.id == card.sceneID }) {
                    Text(scene.story).gbStory()
                    LearningNarrationControls(id: card.id + "-review-teaching", text: scene.story + ". " + card.back + ". " + card.meaning)
                }
                Text(card.front).gbHeadline()
                Text(card.back).gbTitle()
                Text(card.meaning).gbStory()
                Text(point?.requeuedCardIDs.contains(card.id) == true
                     ? "You have practised this once already. You can finish and return another time."
                     : "After this teaching, we’ll offer this card once more after the other cards.").gbBody()
                Button("Continue after teaching") {
                    commit(ReviewJourneyEngine.finishTeaching(archive, card: descriptor(card), now: now()))
                }.buttonStyle(.gbPrimary(.story)).disabled(actionsBlocked).accessibilityIdentifier("review-teaching-continue")
            }
        }
    }

    private var completion: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text(point?.queue.isEmpty == true ? "You’re caught up for now" : "Review finished for now").gbTitle()
                    .accessibilityIdentifier("review-complete")
                Text(point?.queue.isEmpty == true
                     ? "No learned story cards are due right now. You can return later or practise a card you learned."
                     : "Your memory reports, checked answers, and helped practice stay separate. Returning another day gives memory a fresh try.").gbBody()
                if let evidence = point?.evidence, !evidence.isEmpty {
                    let reports = evidence.filter { $0.kind == .selfReported }.count
                    let checked = evidence.filter { $0.kind == .freshChecked }.count
                    let later = evidence.filter { $0.kind == .laterIndependentRecall }.count
                    Text("Memory reports: \(reports) · Fresh checked answers: \(checked) · Later independent recall: \(later)").gbBody()
                    let helped = evidence.filter { $0.kind == .helpedChecked }.count
                    let teaching = evidence.filter { $0.kind == .reteachingExposure }.count
                    Text("Helped answers: \(helped) · Teaching revisits: \(teaching)").gbBody()
                }
                Button("Continue my chapter") { dismiss() }.buttonStyle(.gbPrimary(.story))
                    .accessibilityIdentifier("review-continue-chapter")
                if !learnedSceneIDs.isEmpty {
                    Button("Practise learned cards") { startPractice() }.buttonStyle(.gbSecondary)
                        .disabled(actionsBlocked).accessibilityIdentifier("review-practice")
                }
                Button("All done") { dismiss() }.buttonStyle(.gbSecondary).accessibilityIdentifier("review-all-done")
            }
        }
    }

    private func cardFace(_ card: LearnQuizReviewCard, showAnswer: Bool, promptText: String? = nil) -> some View {
        GBSurface(style: .accented(showAnswer ? .chronicle : card.art.emphasis)) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                GBBadge(title: showAnswer ? "Answer" : card.sceneTitle, symbol: card.art.symbol, emphasis: .chronicle, inverted: true)
                Text(showAnswer ? card.back : (promptText ?? card.front))
                    .font(GBFont.display(size: 30, weight: .bold)).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                if showAnswer { Text(card.meaning).font(GBFont.story(size: 20)).foregroundStyle(.white) }
            }
        }
    }

    private var resultTitle: String {
        switch point?.currentEvidence?.kind {
        case .selfReported: "Memory report saved"
        case .freshChecked: "Answer checked"
        case .laterIndependentRecall: "Remembered on a later visit"
        case .helpedChecked: "Practice with help"
        case .incorrectChecked: "Let’s learn it together"
        case .reteachingExposure, .none: "Review saved"
        }
    }
    private var resultDetail: String {
        switch point?.currentEvidence?.kind {
        case .selfReported: "You told us what you needed. This does not count as a checked answer."
        case .freshChecked: "Your answer matched before the reveal. It is a fresh check of this card."
        case .laterIndependentRecall: "You recalled this card with another question, without help, at least a day after an earlier checked answer."
        case .helpedChecked: "The answer matched after teaching. We’ll return to it soon for another try."
        case .incorrectChecked: "That answer didn’t match this card’s wording. Help is here; there’s no need to hurry."
        case .reteachingExposure, .none: "You can continue whenever you’re ready."
        }
    }

    private func descriptor(_ card: LearnQuizReviewCard) -> ReviewJourneyCard {
        var prompts: [ReviewJourneyCheckPrompt] = []
        var seenText = Set([ChronicleQuizEngine.normalizedAnswer(card.front)])
        for alternate in LearnQuizPilotData.reviewCards where alternate.sceneID == card.sceneID
            && ChronicleQuizEngine.normalizedAnswer(alternate.back) == ChronicleQuizEngine.normalizedAnswer(card.back) {
            if seenText.insert(ChronicleQuizEngine.normalizedAnswer(alternate.front)).inserted {
                prompts.append(ReviewJourneyCheckPrompt(id: alternate.id, text: alternate.front,
                                                       promptType: alternate.promptType, acceptedAnswers: [alternate.back]))
            }
        }
        if let challenge = LearnQuizPilotData.scenes.first(where: { $0.id == card.sceneID })?.quiz.challenge,
           challenge.correctAnswers.contains(where: {
               ChronicleQuizEngine.normalizedAnswer($0) == ChronicleQuizEngine.normalizedAnswer(card.back)
           }), seenText.insert(ChronicleQuizEngine.normalizedAnswer(challenge.prompt)).inserted {
            prompts.append(ReviewJourneyCheckPrompt(id: challenge.id, text: challenge.prompt,
                                                   promptType: challenge.promptType, acceptedAnswers: challenge.correctAnswers))
        }
        return ReviewJourneyCard(id: card.id, sceneID: card.sceneID, promptType: card.promptType, front: card.front,
                                 back: card.back, meaning: card.meaning, checkPrompts: prompts, cadenceDays: card.cadenceDays)
    }
    private func report(_ response: LearningReviewResponse, card: LearnQuizReviewCard) {
        commit(ReviewJourneyEngine.selfReport(response, archive: archive, card: descriptor(card), now: now()))
    }
    private func load() {
        guard !loaded, let hooks else { return }
        loaded = true
        archive = hooks.load()
        if !archive.pendingEvidence.isEmpty {
            commit(archive)
            if actionsBlocked { return }
        }
        if let point = archive.checkpoint, point.phase != .complete {
            commit(ReviewJourneyEngine.resume(archive, cards: descriptors, learnedSceneIDs: learnedSceneIDs))
        } else {
            commit(ReviewJourneyEngine.start(archive: archive, cards: descriptors, learnedSceneIDs: learnedSceneIDs,
                                            sceneSchedules: appModel.lessonStore.reviewSchedulesBySubject, now: now()))
        }
    }
    private func startPractice() {
        commit(ReviewJourneyEngine.start(archive: archive, cards: descriptors, learnedSceneIDs: learnedSceneIDs,
                                        sceneSchedules: appModel.lessonStore.reviewSchedulesBySubject, selection: .practiceLearned,
                                        sessionID: point?.sessionID ?? UUID(), now: now()))
    }
    private func commit(_ next: ReviewJourneyArchive) {
        guard let hooks else { return }
        // Publish the transition only after it was saved. The old prompt retains its event ID on failure.
        guard let saved = ReviewJourneyPersistence.saveAndReplay(next, hooks: hooks) else {
            unsavedArchive = next
            saveFailed = true
            return
        }
        archive = saved
        saveFailed = false
        unsavedArchive = nil
    }
    private func retrySave() { commit(unsavedArchive ?? archive) }
}
