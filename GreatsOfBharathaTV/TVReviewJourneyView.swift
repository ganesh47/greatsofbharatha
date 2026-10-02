import SwiftUI

struct TVReviewJourneyCard: Identifiable {
    let review: ReviewJourneyCard
    let sceneTitle: String
    let choices: [AuthoredLessonChoice]
    let teaching: String
    let clue: String
    var id: String { review.id }
}

/// Remote choice state lives in the review checkpoint, never in a chapter/TV lesson checkpoint.
enum TVReviewJourneyAdapter {
    static func start(archive: ReviewJourneyArchive, cards: [TVReviewJourneyCard], learnedSceneIDs: Set<String>,
                      sceneSchedules: [String: ReviewSchedule], selection: ReviewJourneyEngine.Selection = .due,
                      sessionID: UUID = UUID(), now: Date) -> ReviewJourneyArchive {
        guard archive.pendingEvidence.isEmpty else { return archive }
        var next = sharedFamily(ReviewJourneyEngine.start(archive: archive, cards: cards.map(\.review),
            learnedSceneIDs: learnedSceneIDs, sceneSchedules: sceneSchedules, selection: selection, sessionID: sessionID, now: now))
        // Family recognition rotates authored wording without creating an individual's recall witness.
        if var point = next.checkpoint {
            for index in point.queue.indices {
                let cardID = point.queue[index].cardID
                guard let previous = archive.checkpoint?.evidence.last(where: { $0.cardID == cardID && $0.checkedPromptID != nil }),
                      let card = cards.first(where: { $0.id == cardID }),
                      let alternate = card.review.checkPrompts.first(where: { $0.id != previous.checkedPromptID }) else { continue }
                point.queue[index].checkedPromptID = alternate.id
            }
            next.checkpoint = point
        }
        return next
    }

    static func select(_ choiceID: String, in archive: ReviewJourneyArchive, card: TVReviewJourneyCard) -> ReviewJourneyArchive {
        var next = sharedFamily(archive)
        guard next.checkpoint?.phase == .prompt,
              next.checkpoint?.currentTurn?.cardID == card.id,
              card.choices.contains(where: { $0.id == choiceID }) else { return next }
        next.checkpoint?.selectedChoiceID = choiceID
        next.checkpoint?.typedAnswer = ""
        return next
    }

    static func check(_ archive: ReviewJourneyArchive, card: TVReviewJourneyCard, now: Date,
                      calendar: Calendar = .current) -> ReviewJourneyArchive {
        let next = sharedFamily(archive)
        guard next.checkpoint?.phase == .prompt,
              next.checkpoint?.currentTurn?.cardID == card.id,
              let prompt = card.review.checkPrompts.first(where: { $0.id == next.checkpoint?.currentTurn?.checkedPromptID }),
              let choice = card.choices.first(where: { $0.id == next.checkpoint?.selectedChoiceID }),
              validChoices(card.choices, for: prompt) else { return next }
        // Feed the already-authored choice to the shared checker only in memory. No text entry/history is stored.
        let prepared = ReviewJourneyEngine.updateAnswer(choice.title, in: next)
        return ReviewJourneyEngine.check(prepared, card: card.review, now: now, calendar: calendar)
    }

    static func requestHelp(_ archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        var next = sharedFamily(archive)
        guard next.checkpoint?.phase == .prompt else { return next }
        next.checkpoint?.helped = true
        next.checkpoint?.helpWasRequested = true
        return next
    }

    static func sharedFamily(_ archive: ReviewJourneyArchive) -> ReviewJourneyArchive {
        var next = archive
        next.checkpoint?.sharedFamilyResponse = true
        return next
    }

    static func resume(_ archive: ReviewJourneyArchive, cards: [TVReviewJourneyCard], learnedSceneIDs: Set<String>) -> ReviewJourneyArchive {
        var next = sharedFamily(ReviewJourneyEngine.resume(archive, cards: cards.map(\.review), learnedSceneIDs: learnedSceneIDs))
        next.checkpoint?.typedAnswer = ""
        if let current = cards.first(where: { $0.id == next.checkpoint?.currentTurn?.cardID }),
           let selected = next.checkpoint?.selectedChoiceID,
           !current.choices.contains(where: { $0.id == selected }) {
            next.checkpoint?.selectedChoiceID = nil
        }
        return next
    }

    static func validChoices(_ choices: [AuthoredLessonChoice], for prompt: ReviewJourneyCheckPrompt) -> Bool {
        let titles = choices.map { ChronicleQuizEngine.normalizedAnswer($0.title) }
        guard choices.count >= 2, Set(titles).count == choices.count, choices.filter(\.isCorrect).count == 1 else { return false }
        return choices.allSatisfy { choice in
            let matches = prompt.acceptedAnswers.contains {
                ChronicleQuizEngine.normalizedAnswer($0) == ChronicleQuizEngine.normalizedAnswer(choice.title)
            }
            return choice.isCorrect == matches
        }
    }
}

/// Every option, answer, teaching caption and prompt comes from existing TV/pilot authored content.
enum TVReviewJourneyContent {
    static var cards: [TVReviewJourneyCard] {
        LearnQuizPilotData.reviewCards.compactMap { card in
            guard let chapter = TVLearningContent.chapter(sceneID: card.sceneID) else { return nil }
            return makeCard(card, chapter: chapter)
        }
    }
    static var descriptors: [ReviewJourneyCard] { cards.map(\.review) }

    private static func makeCard(_ card: LearnQuizReviewCard, chapter: TVChapter) -> TVReviewJourneyCard {
        let challenge = chapter.pilot.quiz.challenge
        let normalize = ChronicleQuizEngine.normalizedAnswer
        let checksSameAnswer = challenge.correctAnswers.contains { normalize($0) == normalize(card.back) }
            || normalize(card.front) == normalize(challenge.prompt)
        var prompts: [ReviewJourneyCheckPrompt] = []
        var seen: Set<String> = []
        if checksSameAnswer {
            // Rotate to alternate authored wording only when it assesses the same canonical answer.
            for alternate in chapter.pilot.reviewCards where alternate.id != card.id
                && challenge.correctAnswers.contains(where: { normalize($0) == normalize(alternate.back) }) {
                if seen.insert(normalize(alternate.front)).inserted {
                    prompts.append(ReviewJourneyCheckPrompt(id: alternate.id, text: alternate.front,
                        promptType: alternate.promptType, acceptedAnswers: challenge.correctAnswers))
                }
            }
            if seen.insert(normalize(challenge.prompt)).inserted {
                prompts.append(ReviewJourneyCheckPrompt(id: challenge.id, text: challenge.prompt,
                    promptType: challenge.promptType, acceptedAnswers: challenge.correctAnswers))
            }
            prompts = prompts.filter { TVReviewJourneyAdapter.validChoices(chapter.plan.choices, for: $0) }
        }
        let descriptor = ReviewJourneyCard(id: card.id, sceneID: card.sceneID, promptType: card.promptType,
            front: card.front, back: card.back, meaning: card.meaning, checkPrompts: prompts, cadenceDays: card.cadenceDays)
        return TVReviewJourneyCard(review: descriptor, sceneTitle: chapter.title,
            choices: prompts.isEmpty ? [] : chapter.plan.choices,
            teaching: chapter.storyBeats.map(\.text).joined(separator: "\n\n"),
            clue: chapter.pilot.quiz.hintLadder.first ?? chapter.plan.teachingText)
    }
}

struct TVReviewJourneyView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedAction: String?
    private let hooks: ReviewJourneyHooks
    private let cards: [TVReviewJourneyCard]
    private let now: () -> Date

    @State private var archive = ReviewJourneyArchive()
    @State private var loaded = false
    @State private var unsavedArchive: ReviewJourneyArchive?

    init(hooks: ReviewJourneyHooks, now: @escaping () -> Date = Date.init) {
        self.hooks = hooks
        self.cards = TVReviewJourneyContent.cards
        self.now = now
    }

    private var point: ReviewJourneyCheckpoint? { archive.checkpoint }
    private var currentCard: TVReviewJourneyCard? { cards.first { $0.id == point?.currentTurn?.cardID } }
    private var currentPrompt: ReviewJourneyCheckPrompt? {
        currentCard?.review.checkPrompts.first { $0.id == point?.currentTurn?.checkedPromptID }
    }
    private var actionsBlocked: Bool {
        unsavedArchive != nil || !archive.pendingEvidence.isEmpty
    }
    private var learnedSceneIDs: Set<String> {
        Set(TVLearningContent.chapters.filter { TVLearningContent.hasCheckedLearning($0, store: appModel.lessonStore) }.map(\.id))
    }

    var body: some View {
        TVScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Story card review").font(.system(size: 48, weight: .bold, design: .serif))
                            Text("Shared family review · choosing from answers").font(.system(size: 26, weight: .semibold))
                            Text("This checks your family’s choice, rather than one person remembering alone.")
                                .font(.system(size: 25)).fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button("Finish for now") { dismiss() }.buttonStyle(TVCardButtonStyle())
                            .focused($focusedAction, equals: "finish").accessibilityIdentifier("tv-review-finish")
                    }
                    if let point, point.currentTurn != nil {
                        Text("Card \(point.cursor + 1) of \(point.queue.count) · due cards first")
                            .font(.system(size: 25)).foregroundStyle(TVTheme.gold)
                    }
                    if actionsBlocked {
                        Text("Your last steps are still saving. Try again before continuing.").font(.system(size: 28))
                        Button("Try saving again") { commit(unsavedArchive ?? archive) }.buttonStyle(TVCardButtonStyle())
                            .focused($focusedAction, equals: "retry-save").accessibilityIdentifier("tv-review-retry-save")
                    }
                    if point?.phase == .complete {
                        completion
                    } else if let card = currentCard {
                        switch point?.phase {
                        case .prompt: prompt(card)
                        case .revealed: report(card)
                        case .result: result(card)
                        case .teaching: teaching(card)
                        case .complete, .none: EmptyView()
                        }
                    }
                }.padding(12)
            }
            .accessibilityIdentifier("tv-review-scroll")
        }
        .navigationTitle("Family review")
        .onAppear { load() }
        .onExitCommand { dismiss() }
        .onDisappear { narrator.clearCurrent() }
        .defaultFocus($focusedAction, "finish")
    }

    private func prompt(_ card: TVReviewJourneyCard) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(card.sceneTitle).font(.system(size: 27, weight: .semibold)).foregroundStyle(TVTheme.gold)
            Text(currentPrompt?.text ?? card.review.front).font(.system(size: 36, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("tv-review-prompt")
            TVNarrationControls(id: card.id + "-review-prompt", text: currentPrompt?.text ?? card.review.front)
            if point?.currentTurn?.isTaughtRevisit == true {
                Text("A small practice after teaching. This revisit stays helped family practice.").font(.system(size: 26))
            }
            if currentPrompt != nil {
                Text("Move to an answer and click to select. Then choose Check family choice.").font(.system(size: 26))
                ForEach(card.choices) { choice in
                    Button {
                        commit(TVReviewJourneyAdapter.select(choice.id, in: archive, card: card))
                        if !actionsBlocked && point?.selectedChoiceID == choice.id { focusedAction = "check" }
                    } label: {
                        Label(choice.title, systemImage: point?.selectedChoiceID == choice.id ? "checkmark.circle.fill" : "circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "choice-" + choice.id)
                    .disabled(actionsBlocked).accessibilityIdentifier("tv-review-choice-" + choice.id)
                }
                if point?.helpWasRequested == true {
                    Text("A clue is open. This choice will be saved with help.").font(.system(size: 25, weight: .semibold))
                    Text(card.clue).font(.system(size: 29)).fixedSize(horizontal: false, vertical: true)
                    TVNarrationControls(id: card.id + "-review-clue", text: card.clue)
                }
                Button("Check family choice") {
                    commit(TVReviewJourneyAdapter.check(archive, card: card, now: now()))
                }.buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "check")
                    .disabled(actionsBlocked || point?.selectedChoiceID == nil).accessibilityIdentifier("tv-review-check")
                Button("Give us a clue") { commit(TVReviewJourneyAdapter.requestHelp(archive)) }
                    .buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "help")
                    .disabled(actionsBlocked).accessibilityIdentifier("tv-review-help")
            } else {
                Text("For this card, reveal the answer and tell us what your family needed.").font(.system(size: 27))
            }
            Button("Reveal and tell us what we needed") { commit(ReviewJourneyEngine.reveal(archive)) }
                .buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "reveal")
                .disabled(actionsBlocked).accessibilityIdentifier("tv-review-reveal")
        }
        .focusSection()
    }

    private func report(_ card: TVReviewJourneyCard) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(card.review.back).font(.system(size: 36, weight: .semibold))
            Text(card.review.meaning).font(.system(size: 29)).fixedSize(horizontal: false, vertical: true)
            TVNarrationControls(id: card.id + "-review-answer", text: card.review.back + ". " + card.review.meaning)
            Text("This is your family’s own memory report. It is separate from a checked choice.").font(.system(size: 26))
            response("We knew it", response: .knewIt, card: card, id: "knew")
            response("We needed a clue", response: .neededClue, card: card, id: "clue")
            response("Teach us again", response: .teachAgain, card: card, id: "teach")
        }.focusSection()
    }

    private func response(_ title: String, response: LearningReviewResponse, card: TVReviewJourneyCard, id: String) -> some View {
        Button(title) {
            commit(ReviewJourneyEngine.selfReport(response, archive: archive, card: card.review, now: now()))
        }.buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "report-" + id)
            .disabled(actionsBlocked).accessibilityIdentifier("tv-review-report-" + id)
    }

    private func result(_ card: TVReviewJourneyCard) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(resultTitle).font(.system(size: 38, weight: .semibold)).accessibilityIdentifier("tv-review-result")
            Text(resultDetail).font(.system(size: 29)).fixedSize(horizontal: false, vertical: true)
            TVNarrationControls(id: card.id + "-review-result", text: resultTitle + ". " + resultDetail)
            if point?.currentEvidence?.kind == .incorrectChecked {
                Text(card.review.back + ". " + card.review.meaning).font(.system(size: 29))
            }
            Button(point?.currentEvidence?.response == .teachAgain ? "Learn it together" : "Continue") {
                commit(ReviewJourneyEngine.continueAfterResult(archive))
            }.buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "continue")
                .disabled(actionsBlocked).accessibilityIdentifier("tv-review-continue")
        }.focusSection()
    }

    private func teaching(_ card: TVReviewJourneyCard) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Learn it together").font(.system(size: 38, weight: .semibold))
            Text(card.teaching).font(.system(size: 29)).fixedSize(horizontal: false, vertical: true)
            Text(card.review.front + " · " + card.review.back).font(.system(size: 30, weight: .semibold))
            Text(card.review.meaning).font(.system(size: 29))
            TVNarrationControls(id: card.id + "-review-teaching", text: card.teaching + ". " + card.review.back + ". " + card.review.meaning)
            Text(point?.requeuedCardIDs.contains(card.id) == true
                 ? "You’ve practised this once already. You can finish and return another time."
                 : "We’ll offer this card once more after the other cards.").font(.system(size: 26))
            Button("Continue after teaching") {
                commit(ReviewJourneyEngine.finishTeaching(archive, card: card.review, now: now()))
            }.buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "teaching-continue")
                .disabled(actionsBlocked).accessibilityIdentifier("tv-review-teaching-continue")
        }.focusSection()
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(point?.queue.isEmpty == true ? "You’re caught up for now" : "Family review finished for now")
                .font(.system(size: 38, weight: .semibold)).accessibilityIdentifier("tv-review-complete")
            Text("Checked family choices, helped practice, and your own memory reports stay separate.").font(.system(size: 29))
            let events = point?.evidence ?? []
            let checks = events.filter { $0.wasSuccessful && $0.responseContext == .sharedFamilyRecognition }.count
            let reports = events.filter { $0.kind == .selfReported }.count
            Text("Family choices checked: \(checks) · Memory reports: \(reports)").font(.system(size: 27))
            Button("Continue our chapter") { dismiss() }.buttonStyle(TVCardButtonStyle())
                .focused($focusedAction, equals: "chapter").accessibilityIdentifier("tv-review-chapter")
            if !learnedSceneIDs.isEmpty {
                Button("Practise learned cards") { start(.practiceLearned) }.buttonStyle(TVCardButtonStyle())
                    .focused($focusedAction, equals: "practice").disabled(actionsBlocked).accessibilityIdentifier("tv-review-practice")
            }
            Button("All done") { dismiss() }.buttonStyle(TVCardButtonStyle())
                .focused($focusedAction, equals: "done").accessibilityIdentifier("tv-review-done")
        }.focusSection()
    }

    private var resultTitle: String {
        switch point?.currentEvidence?.kind {
        case .freshChecked: "Family choice checked"
        case .helpedChecked: "Family choice checked with help"
        case .selfReported: "Family memory report saved"
        case .incorrectChecked: "Let’s learn it together"
        case .laterIndependentRecall, .reteachingExposure, .none: "Review saved"
        }
    }
    private var resultDetail: String {
        switch point?.currentEvidence?.kind {
        case .freshChecked: "Your family checked a choice without opening a clue. This does not claim one person remembered alone."
        case .helpedChecked: "Your family checked a choice with a clue or after teaching. We’ll return to it soon."
        case .selfReported: "You told us what your family needed. This does not count as a checked answer."
        case .incorrectChecked: "That choice didn’t match. Let’s revisit the story together; there’s no need to hurry."
        case .laterIndependentRecall, .reteachingExposure, .none: "You can continue whenever you’re ready."
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        archive = hooks.load()
        if !archive.pendingEvidence.isEmpty {
            commit(archive)
            if actionsBlocked { return }
        }
        if let point, point.phase != .complete {
            commit(TVReviewJourneyAdapter.resume(archive, cards: cards, learnedSceneIDs: learnedSceneIDs))
        } else {
            start(.due)
        }
    }
    private func start(_ selection: ReviewJourneyEngine.Selection) {
        let sessionID = selection == .practiceLearned ? point?.sessionID ?? UUID() : UUID()
        let next = TVReviewJourneyAdapter.start(archive: archive, cards: cards, learnedSceneIDs: learnedSceneIDs,
            sceneSchedules: appModel.lessonStore.reviewSchedulesBySubject, selection: selection, sessionID: sessionID, now: now())
        commit(next)
    }
    private func commit(_ next: ReviewJourneyArchive) {
        guard let saved = ReviewJourneyPersistence.saveAndReplay(next, hooks: hooks) else {
            unsavedArchive = next
            focusedAction = "retry-save"
            return
        }
        archive = saved
        unsavedArchive = nil
        if !archive.pendingEvidence.isEmpty { focusedAction = "retry-save" } else { restoreFocus() }
    }
    private func restoreFocus() {
        switch point?.phase {
        case .prompt:
            focusedAction = point?.selectedChoiceID == nil ? currentCard?.choices.first.map { "choice-" + $0.id } ?? "reveal" : "check"
        case .revealed: focusedAction = "report-knew"
        case .result: focusedAction = "continue"
        case .teaching: focusedAction = "teaching-continue"
        case .complete: focusedAction = "chapter"
        case .none: focusedAction = "finish"
        }
    }
}
