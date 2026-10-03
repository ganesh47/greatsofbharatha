import SwiftUI

struct TVChapterKnowledgePracticeView: View {
    @EnvironmentObject private var narrator: GBNarrator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var presentation: ChapterKnowledgePresentationSession
    @State private var coverage = ChapterKnowledgeTextCoverage()
    @State private var coverageID = ""
    @FocusState private var focus: String?
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
    private var explanationWasPresented: Bool { coverageID == resultID && coverage.isComplete }

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Color.clear.frame(height: 1).id("tv-knowledge-practice-top").accessibilityHidden(true)
                        header
                        saveStatus
                        if presentation.isReadOnly || (point != nil && point?.responseContext != .sharedFamilyRecognition) {
                            unavailable
                        } else {
                            phaseContent
                        }
                    }
                    .padding(.horizontal, 84).padding(.vertical, 44)
                    .frame(maxWidth: 1660, alignment: .leading).frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("tv-knowledge-practice-scroll")
                .onPreferenceChange(TVKnowledgeTextFrameKey.self) { sample in
                    guard scenePhase == .active, !resultID.isEmpty, sample.id == resultID else { return }
                    if coverageID != sample.id { coverageID = sample.id; coverage = ChapterKnowledgeTextCoverage() }
                    coverage.observe(textFrame: sample.frame, viewport: viewport.frame(in: .global))
                }
                .onChange(of: point?.phase) {
                    narrator.stop()
                    proxy.scrollTo("tv-knowledge-practice-top", anchor: .top)
                    restoreFocus()
                }
                .onChange(of: point?.currentTurn?.id) { restoreFocus() }
                .onChange(of: explanationWasPresented) { _, ready in if ready { focus = "next" } }
            }
        }
        .background(TVTheme.background).foregroundStyle(TVTheme.paper)
        .onAppear(perform: load)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { load() } else { _ = presentation.confirmBeforeLeaving(); narrator.stop() }
        }
        .onExitCommand(perform: back)
        .onDisappear { narrator.stop() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("A little family practice").font(.system(size: 40, weight: .bold))
                Text("Shared family recognition · choose, then check").font(.system(size: 25))
                    .accessibilityIdentifier("tv-knowledge-family-context")
                if let point, point.currentTurn != nil {
                    Text("Question \(point.cursor + 1) of \(point.queue.count)").font(.system(size: 25))
                        .accessibilityIdentifier("tv-knowledge-practice-progress")
                }
            }
            Spacer()
            Button("Pause for now", action: pause).buttonStyle(TVCardButtonStyle())
                .disabled(!presentation.isReadOnly && presentation.isBlocked)
                .accessibilityIdentifier("tv-knowledge-practice-pause")
        }.focusSection()
    }

    @ViewBuilder private var saveStatus: some View {
        if presentation.saveIsConfirmed {
            Text("Saved on this TV").font(.system(size: 22)).accessibilityIdentifier("tv-knowledge-save-confirmed")
        } else if presentation.loaded && !presentation.isReadOnly {
            Text("This step is still saving. Try saving again before continuing.").font(.system(size: 25))
            Button("Try saving again") { if presentation.retry() { begin() } }
                .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "retry")
                .accessibilityIdentifier("tv-knowledge-save-retry")
        }
    }

    @ViewBuilder private var phaseContent: some View {
        if let question {
            switch point?.phase {
            case .needsTeaching:
                Text("Learn this first").font(.system(size: 36, weight: .bold))
                    .accessibilityIdentifier("tv-knowledge-practice-needs-teaching")
                Text("Explore the chapter cards for this question, then come back to try it together.").font(.system(size: 30))
                Button("Show the chapter cards") { openTeaching(question) }
                    .buttonStyle(TVCardButtonStyle()).disabled(presentation.isBlocked).focused($focus, equals: "teach")
                    .accessibilityIdentifier("tv-knowledge-practice-teach")
            case .prompt: prompt(question)
            case .result: result(question)
            case .complete: completion
            case .none, .unavailable: unavailable
            }
        } else if point?.phase == .complete { completion } else if presentation.loaded { unavailable }
    }

    private func prompt(_ question: ChapterKnowledgeQuestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(question.prompt).font(.system(size: 33, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("tv-knowledge-question-" + question.id)
            if point?.currentTurn?.answerWasSeen == true {
                Text("We’ve seen this answer before. Here is another chance to practise.").font(.system(size: 23))
                    .accessibilityIdentifier("tv-knowledge-practice-seen-answer")
            }
            ForEach(question.choices) { choice in
                Button {
                    _ = presentation.commit(ChapterKnowledgeJourney.select(choice.id, archive: presentation.archive, definition: definition))
                } label: {
                    HStack {
                        Text(choice.text).font(.system(size: 28)).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Image(systemName: point?.selectedChoiceID == choice.id ? "checkmark.circle.fill" : "circle")
                    }.frame(maxWidth: 1180, alignment: .leading)
                }
                .buttonStyle(TVCardButtonStyle()).disabled(presentation.isBlocked).focused($focus, equals: choice.id)
                .accessibilityIdentifier("tv-knowledge-choice-" + choice.id)
                .accessibilityValue(point?.selectedChoiceID == choice.id ? "Selected" : "Available")
            }
            HStack(spacing: 26) {
                Button("Check our answer") {
                    if !presentation.commit(ChapterKnowledgeJourney.check(presentation.archive, definition: definition, now: now())) {
                        focus = "retry"
                    }
                }.disabled(presentation.isBlocked || point?.selectedChoiceID == nil).focused($focus, equals: "check")
                    .accessibilityIdentifier("tv-knowledge-practice-check")
                Button("Give us a clue") {
                    _ = presentation.commit(ChapterKnowledgeJourney.requestHelp(presentation.archive, definition: definition))
                }.disabled(presentation.isBlocked || (point?.currentTurn?.hintLevel ?? 0) >= min(question.hints.count, 3))
                    .accessibilityIdentifier("tv-knowledge-practice-help")
            }.buttonStyle(TVCardButtonStyle()).focusSection()
            if let level = point?.currentTurn?.hintLevel, level > 0 {
                Text(question.hints.prefix(level).joined(separator: " ")).font(.system(size: 28))
                    .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("tv-knowledge-practice-hint")
            }
            TVNarrationControls(id: question.id, text: question.prompt)
        }.focusSection()
    }

    private func result(_ question: ChapterKnowledgeQuestion) -> some View {
        let answer = question.choices.first { $0.id == question.correctChoiceID }?.text ?? ""
        let explanation = "The answer: " + answer + ". " + question.explanation
        return VStack(alignment: .leading, spacing: 24) {
            Text(resultTitle).font(.system(size: 36, weight: .bold)).accessibilityIdentifier("tv-knowledge-practice-result")
            Text(explanation).font(.system(size: 33)).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("tv-knowledge-explanation-" + question.id)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: TVKnowledgeTextFrameKey.self,
                        value: TVKnowledgeTextFrame(id: resultID, frame: geometry.frame(in: .global)))
                })
            if point?.currentResult?.wasSuccessful == false {
                Text(question.retryFeedback).font(.system(size: 28))
            }
            HStack(spacing: 24) {
                Button(point?.cursor == (point?.queue.count ?? 0) - 1 ? "Finish this practice" : "Next question") {
                    _ = presentation.commit(ChapterKnowledgeJourney.advance(presentation.archive, definition: definition))
                }.disabled(presentation.isBlocked || !explanationWasPresented).focused($focus, equals: "next")
                    .accessibilityIdentifier("tv-knowledge-practice-next")
                if point?.canTryAgain == true {
                    Button("Try again with what we learned") {
                        _ = presentation.commit(ChapterKnowledgeJourney.tryAgain(presentation.archive, definition: definition))
                    }.disabled(presentation.isBlocked || !explanationWasPresented)
                        .accessibilityIdentifier("tv-knowledge-practice-try-again")
                }
                if point?.currentResult?.wasSuccessful == false {
                    Button("Look at chapter cards") { openTeaching(question) }
                        .disabled(presentation.isBlocked || !explanationWasPresented)
                        .accessibilityIdentifier("tv-knowledge-practice-reteach")
                }
            }.buttonStyle(TVCardButtonStyle()).focusSection()
            TVNarrationControls(id: resultID, text: explanation)
        }
    }

    private var resultTitle: String {
        guard let result = point?.currentResult, result.wasSuccessful else { return "Let’s look together" }
        switch result.support {
        case .noClue: return "Our family choice matched"
        case .withClue: return "Our family choice matched with a clue"
        case .answerSeen: return "Our family choice matched after seeing the answer"
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Family practice finished for now").font(.system(size: 36, weight: .bold))
                .accessibilityIdentifier("tv-knowledge-practice-complete")
            Text("We explored this set of questions together. The chapter cards are here whenever we want another look.")
                .font(.system(size: 30))
            Button("Continue our chapter") {
                if presentation.confirmBeforeLeaving() { narrator.stop(); onFinished() }
            }.buttonStyle(TVCardButtonStyle()).disabled(presentation.isBlocked).focused($focus, equals: "finish")
                .accessibilityIdentifier("tv-knowledge-practice-finish")
            Button("Practise this set again") { begin(restartCompleted: true) }
                .buttonStyle(TVCardButtonStyle()).disabled(presentation.isBlocked)
                .accessibilityIdentifier("tv-knowledge-practice-again")
        }.focusSection()
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("This extra practice is unavailable. Your saved chapter is preserved.").font(.system(size: 30))
                .accessibilityIdentifier("tv-knowledge-practice-unavailable")
            Button("Return to the story", action: pause).buttonStyle(TVCardButtonStyle())
                .disabled(!presentation.isReadOnly && presentation.isBlocked)
        }
    }

    private func load() { if presentation.reload() { begin() } }
    private func begin(restartCompleted: Bool = false) {
        _ = presentation.commit(ChapterKnowledgeJourney.begin(presentation.archive, definition: definition,
            sessionID: sessionID, context: .sharedFamilyRecognition, restartCompleted: restartCompleted))
        restoreFocus()
    }
    private func restoreFocus() {
        if presentation.isBlocked { focus = "retry"; return }
        switch point?.phase {
        case .prompt: focus = point?.selectedChoiceID ?? question?.choices.first?.id
        case .needsTeaching: focus = "teach"
        case .complete: focus = "finish"
        case .result, .none, .unavailable: break
        }
    }
    private func openTeaching(_ question: ChapterKnowledgeQuestion) {
        if presentation.confirmBeforeLeaving() { narrator.stop(); onNeedsTeaching(Set(question.requiredBeatIDs)) }
    }
    private func pause() {
        guard presentation.isReadOnly || presentation.confirmBeforeLeaving() else { focus = "retry"; return }
        narrator.stop()
        dismiss()
    }
    private func back() {
        if point?.phase == .prompt, point?.selectedChoiceID != nil {
            _ = presentation.commit(ChapterKnowledgeJourney.select(nil, archive: presentation.archive, definition: definition))
        } else { pause() }
    }
}

struct TVChapterKnowledgeFlowView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var screen: ChapterKnowledgeEntryMode
    @State private var startingAtBeatID: String?
    let chapter: TVChapter
    let sessionID: UUID
    let onFinished: () -> Void

    init(chapter: TVChapter, sessionID: UUID, entry: ChapterKnowledgeEntryMode, onFinished: @escaping () -> Void) {
        self.chapter = chapter
        self.sessionID = sessionID
        self.onFinished = onFinished
        _screen = State(initialValue: entry)
    }
    var body: some View {
        if let definition = ChapterKnowledgeCatalog.definition(sceneID: chapter.id) {
            let hooks = ChapterKnowledgeAdapters.hooks(store: appModel.lessonStore, definitions: ChapterKnowledgeCatalog.definitions)
            switch screen {
            case .teaching:
                TVChapterKnowledgeTeachingView(chapter: chapter, definition: definition, sessionID: sessionID, hooks: hooks,
                    onFinished: { screen = .practice; startingAtBeatID = nil }, startingAtBeatID: startingAtBeatID)
            case .practice:
                TVChapterKnowledgePracticeView(definition: definition, sessionID: sessionID, hooks: hooks,
                    onNeedsTeaching: { ids in
                        startingAtBeatID = definition.beats.first { ids.contains($0.id) }?.id
                        screen = .teaching
                    }, onFinished: onFinished)
            }
        }
    }
}
