import SwiftUI

struct ChapterKnowledgePracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var questionIsFocused: Bool
    @AccessibilityFocusState private var explanationIsFocused: Bool
    @StateObject private var presentation: ChapterKnowledgePresentationSession
    @State private var explanationCoverage = ChapterKnowledgeTextCoverage()
    @State private var explanationID = ""

    let definition: ChapterKnowledgeDefinition
    let sessionID: UUID
    let onNeedsTeaching: (Set<String>) -> Void
    let onFinished: () -> Void
    var now: () -> Date

    init(definition: ChapterKnowledgeDefinition, sessionID: UUID, hooks: ChapterKnowledgeHooks,
         onNeedsTeaching: @escaping (Set<String>) -> Void, onFinished: @escaping () -> Void,
         now: @escaping () -> Date = Date.init) {
        self.definition = definition
        self.sessionID = sessionID
        self.onNeedsTeaching = onNeedsTeaching
        self.onFinished = onFinished
        self.now = now
        _presentation = StateObject(wrappedValue: ChapterKnowledgePresentationSession(hooks: hooks))
    }

    private var point: ChapterKnowledgePracticeCheckpoint? { presentation.archive.practiceBySceneID[definition.sceneID] }
    private var question: ChapterKnowledgeQuestion? { definition.questions.first { $0.id == point?.currentTurn?.questionID } }
    private var resultID: String { point?.currentResult?.id.uuidString ?? "" }
    private var explanationWasPresented: Bool { explanationID == resultID && explanationCoverage.isComplete }

    var body: some View {
        GBLayoutContextReader { context in
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: context.sectionSpacing) {
                            Color.clear.frame(height: 1).id("knowledge-practice-top").accessibilityHidden(true)
                            header
                            ChapterKnowledgeSaveStatus(presentation: presentation, retry: retrySave)
                            if presentation.isReadOnly || (point != nil && point?.responseContext != .individualRecognition) {
                                unavailable
                            } else if let question {
                                switch point?.phase {
                                case .needsTeaching: needsTeaching(question)
                                case .prompt: prompt(question)
                                case .result: result(question)
                                case .unavailable: unavailable
                                case .complete: completion
                                case .none: unavailable
                                }
                            } else if point?.phase == .complete {
                                completion
                            } else if presentation.loaded {
                                unavailable
                            }
                            Button("Pause for now") {
                                if presentation.isReadOnly || presentation.confirmBeforeLeaving() { dismiss() }
                            }
                            .buttonStyle(.gbSecondary)
                            .disabled(!presentation.isReadOnly && presentation.isBlocked)
                            .accessibilityIdentifier("knowledge-practice-pause")
                        }
                        .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                        .padding(context.containerPadding)
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("knowledge-practice-scroll")
                    .onPreferenceChange(ChapterKnowledgeTextFrameKey.self) { sample in
                        guard scenePhase == .active, sample.id == resultID, !resultID.isEmpty else { return }
                        if explanationID != sample.id {
                            explanationCoverage = ChapterKnowledgeTextCoverage()
                            explanationID = sample.id
                        }
                        explanationCoverage.observe(textFrame: sample.frame, viewport: viewport.frame(in: .global))
                    }
                    .onChange(of: point?.phase) {
                        proxy.scrollTo("knowledge-practice-top", anchor: .top)
                        if point?.phase == .result { explanationIsFocused = true } else { questionIsFocused = true }
                    }
                    .onChange(of: point?.currentTurn?.id) {
                        proxy.scrollTo("knowledge-practice-top", anchor: .top)
                        questionIsFocused = true
                    }
                }
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Chapter practice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Text("A little practice").gbTitle().accessibilityAddTraits(.isHeader)
            if let point, point.currentTurn != nil {
                Text("Question \(point.cursor + 1) of \(point.queue.count)").gbBody()
                    .accessibilityIdentifier("knowledge-practice-progress")
            }
            Text("Choose an answer, then check. Help is here whenever you need it.").gbBody()
        }
    }

    private func needsTeaching(_ question: ChapterKnowledgeQuestion) -> some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("Learn this first").gbTitle().accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("knowledge-practice-needs-teaching")
                Text("Let’s explore the chapter cards for this question, then come back to try it.").gbStory()
                Button("Show the chapter cards") { openTeaching(question) }
                    .buttonStyle(.gbPrimary(.story)).disabled(presentation.isBlocked)
                    .accessibilityIdentifier("knowledge-practice-teach")
            }
        }
    }

    private func prompt(_ question: ChapterKnowledgeQuestion) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Text(question.prompt).gbStory().fixedSize(horizontal: false, vertical: true)
                .accessibilityFocused($questionIsFocused).accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("knowledge-question-" + question.id)
            if point?.currentTurn?.answerWasSeen == true {
                Text("You’ve seen this answer before. This is another chance to practise.").gbBody()
                    .accessibilityIdentifier("knowledge-practice-seen-answer")
            }
            ForEach(question.choices) { choice in
                choiceButton(choice, question: question)
            }
            Button("Check my answer") {
                _ = presentation.commit(ChapterKnowledgeJourney.check(presentation.archive, definition: definition, now: now()))
            }
            .buttonStyle(.gbPrimary(.story))
            .disabled(presentation.isBlocked || point?.selectedChoiceID == nil)
            .accessibilityIdentifier("knowledge-practice-check")
            hint(question)
        }
    }

    private func choiceButton(_ choice: ChapterKnowledgeChoice, question: ChapterKnowledgeQuestion) -> some View {
        let selected = point?.selectedChoiceID == choice.id
        return Button {
            _ = presentation.commit(ChapterKnowledgeJourney.select(choice.id, archive: presentation.archive, definition: definition))
        } label: {
            HStack(alignment: .top, spacing: GBSpacing.small) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(GBColor.Story.primary).accessibilityHidden(true)
                Text(choice.text).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(GBSpacing.small)
        }
        .buttonStyle(.gbSecondary).disabled(presentation.isBlocked)
        .accessibilityLabel(choice.text)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("knowledge-choice-" + choice.id)
    }

    private func hint(_ question: ChapterKnowledgeQuestion) -> some View {
        let level = point?.currentTurn?.hintLevel ?? 0
        return VStack(alignment: .leading, spacing: GBSpacing.small) {
            if level > 0 {
                Text(question.hints.prefix(level).joined(separator: "\n\n")).gbStory()
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("knowledge-practice-hint")
            }
            Button(level == 0 ? "Give me a clue" : "Another clue") {
                _ = presentation.commit(ChapterKnowledgeJourney.requestHelp(presentation.archive, definition: definition))
            }
            .buttonStyle(.gbSecondary)
            .disabled(presentation.isBlocked || level >= min(question.hints.count, 3))
            .accessibilityIdentifier("knowledge-practice-help")
        }
    }

    private func result(_ question: ChapterKnowledgeQuestion) -> some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text(resultTitle).gbTitle().accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("knowledge-practice-result-title")
                Text(explanationText(question)).gbStory().fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused($explanationIsFocused)
                    .accessibilityIdentifier("knowledge-explanation-" + question.id)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ChapterKnowledgeTextFrameKey.self,
                            value: scenePhase == .active
                                ? ChapterKnowledgeTextFrame(id: resultID, frame: geometry.frame(in: .global))
                                : ChapterKnowledgeTextFrameKey.defaultValue)
                    })
                if point?.currentResult?.wasSuccessful == false {
                    Text(question.retryFeedback).gbStory().fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("knowledge-practice-retry-feedback")
                }
                if !explanationWasPresented {
                    Text("Read the explanation above, then choose your next step.").gbBody()
                }
                if point?.canTryAgain == true {
                    Button("Try again with what you learned") {
                        _ = presentation.commit(ChapterKnowledgeJourney.tryAgain(presentation.archive, definition: definition))
                    }
                    .buttonStyle(.gbSecondary).disabled(presentation.isBlocked || !explanationWasPresented)
                    .accessibilityIdentifier("knowledge-practice-try-again")
                }
                if point?.currentResult?.wasSuccessful == false {
                    Button("Look at the chapter cards") { openTeaching(question) }
                        .buttonStyle(.gbSecondary).disabled(presentation.isBlocked || !explanationWasPresented)
                        .accessibilityIdentifier("knowledge-practice-reteach")
                }
                Button(point?.cursor == (point?.queue.count ?? 0) - 1 ? "Finish this practice" : "Next question") {
                    _ = presentation.commit(ChapterKnowledgeJourney.advance(presentation.archive, definition: definition))
                }
                .buttonStyle(.gbPrimary(.story)).disabled(presentation.isBlocked || !explanationWasPresented)
                .accessibilityIdentifier("knowledge-practice-next")
            }
        }
    }

    private var resultTitle: String {
        guard let result = point?.currentResult, result.wasSuccessful else { return "Let’s look together" }
        switch result.support {
        case .noClue: return "Your choice matched"
        case .withClue: return "Your choice matched with a clue"
        case .answerSeen: return "Your choice matched after seeing the answer"
        }
    }

    private func explanationText(_ question: ChapterKnowledgeQuestion) -> String {
        let answer = question.choices.first { $0.id == question.correctChoiceID }?.text ?? ""
        return "The answer: \(answer)\n\n\(question.explanation)"
    }

    private var completion: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("Practice finished for now").gbTitle().accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("knowledge-practice-complete")
                Text("You explored this set of questions. You can visit the chapter cards or practise again whenever you like.").gbStory()
                Button("Continue my chapter") {
                    if presentation.confirmBeforeLeaving() { onFinished() }
                }
                .buttonStyle(.gbPrimary(.story)).disabled(presentation.isBlocked)
                .accessibilityIdentifier("knowledge-practice-finish")
                Button("Practise this set again") { begin(restartCompleted: true) }
                    .buttonStyle(.gbSecondary).disabled(presentation.isBlocked)
                    .accessibilityIdentifier("knowledge-practice-again")
            }
        }
    }

    private var unavailable: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("Return to the story").gbTitle().accessibilityAddTraits(.isHeader)
                Text("This extra practice is not available right now. Your saved chapter steps are preserved.").gbStory()
                Button("Back to my story") {
                    if presentation.isReadOnly || presentation.confirmBeforeLeaving() { onFinished() }
                }
                .buttonStyle(.gbSecondary).disabled(!presentation.isReadOnly && presentation.isBlocked)
                .accessibilityIdentifier("knowledge-practice-return")
            }
        }.accessibilityIdentifier("knowledge-practice-unavailable")
    }

    private func load() {
        guard presentation.reload() else { return }
        begin()
    }

    private func begin(restartCompleted: Bool = false) {
        _ = presentation.commit(ChapterKnowledgeJourney.begin(presentation.archive, definition: definition,
            sessionID: sessionID, context: .individualRecognition, restartCompleted: restartCompleted))
    }

    private func retrySave() {
        if presentation.retry() { begin() }
    }

    private func openTeaching(_ question: ChapterKnowledgeQuestion) {
        guard presentation.confirmBeforeLeaving() else { return }
        onNeedsTeaching(Set(question.requiredBeatIDs))
    }
}
