import SwiftUI

struct ChronicleQuizView: View {
    @EnvironmentObject private var appModel: AppModel
    let scene: LearnQuizPilotScene
    var sessionID = UUID()
    @State private var activeSessionID: UUID?
    @State private var quizState = ChronicleQuizState()
    @State private var result: ChronicleQuizResult?
    @State private var completionID = UUID()
    @State private var taught = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text(scene.quiz.question).gbTitle()
                LearningNarrationControls(id: scene.id + "-pilot-question", text: scene.quiz.question)
                Text("Try from memory. Help is here whenever you want it.").gbBody()
                ForEach(scene.quiz.options, id: \.self) { option in
                    Button { answer(option) } label: {
                        Text(option).gbHeadline().frame(maxWidth: .infinity, minHeight: GBTouch.button)
                    }
                    .buttonStyle(.bordered)
                    .disabled(result?.isCorrect == true)
                    .accessibilityIdentifier("pilot-choice-" + option.lowercased().replacingOccurrences(of: " ", with: "-"))
                }
                if let hint = ChronicleQuizEngine.currentHint(for: quizState, challenge: scene.quiz.challenge) {
                    Text(hint.body).gbStory()
                    LearningNarrationControls(id: scene.id + "-pilot-hint", text: hint.body)
                }
                if result?.isCorrect != true {
                    Button("Help me remember") {
                        quizState = ChronicleQuizEngine.revealNextHint(from: quizState, challenge: scene.quiz.challenge)
                        saveCheckpoint()
                    }.buttonStyle(.bordered).frame(minHeight: GBTouch.button)
                }
                if let result {
                    Text(result.feedback).gbStory().accessibilityIdentifier("pilot-quiz-feedback")
                    LearningNarrationControls(id: scene.id + "-pilot-feedback", text: result.feedback)
                    if result.isCorrect {
                        NavigationLink { ChronicleMatchView(scenes: [scene], sessionID: activeSessionID ?? sessionID) } label: {
                            Text("Play a matching game")
                        }.buttonStyle(.gbPrimary(.place))
                        NavigationLink { ChronicleBookView(scenes: LearnQuizPilotData.scenes) } label: {
                            Text("See my Chronicle")
                        }.buttonStyle(.gbPrimary(.chronicle))
                    }
                }
            }.padding(GBSpacing.medium).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }
        .navigationTitle("Try your memory")
        .onAppear {
            guard !taught else { return }
            taught = true
            let point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id, sessionID: activeSessionID ?? sessionID)
            activeSessionID = point.sessionID
            completionID = point.recallEventID
            quizState.revealedHintCount = point.revealedHintLevel
            quizState.recognitionRescueUnlocked = point.recognitionRescueUnlocked
            if point.recallCompleted {
                result = ChronicleQuizResult(kind: point.recognitionRescueUnlocked ? .rescuedRecognition : (point.revealedHintLevel > 0 ? .correctWithHint : .correctWithoutHint),
                    isCorrect: true, masteryAwarded: .understood, feedback: scene.quiz.challenge.feedback.success, nextState: quizState)
            } else if quizState.revealedHintCount == 0 && appModel.parentSettings.assistModeEnabled {
                quizState = ChronicleQuizEngine.revealNextHint(from: quizState, challenge: scene.quiz.challenge)
            }
            saveCheckpoint()
        }
    }

    private func answer(_ option: String) {
        guard result?.isCorrect != true else { return }
        let next = ChronicleQuizEngine.evaluate(state: quizState, challenge: scene.quiz.challenge, selectedAnswer: option)
        quizState = next.nextState
        result = next
        let support: LearningSupport
        switch next.kind {
        case .correctWithoutHint: support = .independent
        case .correctWithHint, .incorrect: support = quizState.revealedHintCount > 0 ? .hinted : .independent
        case .rescuedRecognition: support = .rescued
        }
        let prior = appModel.lessonStore.masteryRecord(for: scene.id)?.evidenceLog.contains {
            $0.type == .recallSuccess || $0.type == .reviewSuccess
        } == true
        appModel.lessonStore.recordLearningOutcome(subjectID: scene.id, activity: prior ? .review : .recall,
            wasSuccessful: next.isCorrect, support: support, mastery: prior ? .remembered : .understood,
            promptType: scene.quiz.challenge.promptType, detail: "Chronicle quiz", eventID: next.isCorrect ? completionID : UUID(),
            sessionID: activeSessionID ?? sessionID)
        saveCheckpoint()
        if next.isCorrect { LessonFeedback.fire(.success) }
    }

    private func saveCheckpoint() {
        var point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id, sessionID: activeSessionID ?? sessionID)
        point.phase = result?.isCorrect == true ? .reward : .recall
        point.revealedHintLevel = quizState.revealedHintCount
        point.recognitionRescueUnlocked = quizState.recognitionRescueUnlocked
        point.recallCompleted = result?.isCorrect == true
        point.recallEventID = completionID
        point.updatedAt = Date()
        appModel.lessonStore.saveResumePoint(point)
    }
}
