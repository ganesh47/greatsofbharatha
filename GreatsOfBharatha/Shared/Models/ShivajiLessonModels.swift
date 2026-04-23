import Foundation

struct LessonChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

struct LessonRecallState: Equatable {
    var typedAnswer = ""
    var selectedChoiceID: String?
    var feedbackText: String?
    var hasAnsweredCorrectly = false
    var revealedHintLevel = 0
    var recognitionRescueUnlocked = false
}

enum SceneLessonStage: Equatable {
    case story
    case place
    case chronicle
    case complete
}

struct SceneLessonFlow: Equatable {
    let totalStoryCards: Int
    let currentStoryCardIndex: Int
    let storyStepComplete: Bool
    let totalMapAnchors: Int
    let revealedMapAnchors: Int
    let hasAnsweredCorrectly: Bool

    var activeStage: SceneLessonStage {
        if hasAnsweredCorrectly {
            return .complete
        }
        if placeStepComplete {
            return .chronicle
        }
        if storyStepComplete {
            return .place
        }
        return .story
    }

    var currentQuestStepID: String {
        switch activeStage {
        case .story:
            return "story"
        case .place:
            return "place"
        case .chronicle, .complete:
            return "chronicle"
        }
    }

    var placeStepComplete: Bool {
        totalMapAnchors == 0 || revealedMapAnchors >= totalMapAnchors
    }

    var progressValue: Double {
        let safeStoryCardCount = max(totalStoryCards, 1)
        let safeMapAnchorCount = max(totalMapAnchors, 1)
        let storyProgress = storyStepComplete ? 1.0 : min(Double(currentStoryCardIndex + 1) / Double(safeStoryCardCount + 1), 0.95)
        let placeProgress = storyStepComplete ? (placeStepComplete ? 1.0 : Double(revealedMapAnchors) / Double(safeMapAnchorCount)) : 0.0
        let chronicleProgress = hasAnsweredCorrectly ? 1.0 : 0.0
        return min((storyProgress + placeProgress + chronicleProgress) / 3.0, 1.0)
    }
}

struct LessonRecallEvaluation: Equatable {
    let wasSuccessful: Bool
    let masteryAwarded: MasteryState
    let feedbackText: String
    let revealedHintLevel: Int
    let recognitionRescueUnlocked: Bool
}

enum LessonRecallEngine {
    static func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func answerMatches(_ candidate: String, challenge: RecallChallenge) -> Bool {
        let normalizedCandidate = normalized(candidate)
        guard !normalizedCandidate.isEmpty else { return false }
        return challenge.correctAnswers.contains { normalized($0) == normalizedCandidate }
    }

    static func revealNextHint(from state: LessonRecallState, challenge: RecallChallenge) -> LessonRecallState {
        var nextState = state
        guard !nextState.hasAnsweredCorrectly else { return nextState }

        if nextState.revealedHintLevel < challenge.hintLadder.count {
            nextState.revealedHintLevel += 1
            if let hint = currentHint(for: nextState, challenge: challenge) {
                nextState.feedbackText = "Try again. \(hint.title): \(hint.body)"
            }
        } else {
            nextState.recognitionRescueUnlocked = true
            nextState.feedbackText = challenge.feedback.recovery
        }

        return nextState
    }

    static func currentHint(for state: LessonRecallState, challenge: RecallChallenge) -> RecallHint? {
        guard state.revealedHintLevel > 0 else { return nil }
        let index = min(state.revealedHintLevel - 1, max(challenge.hintLadder.count - 1, 0))
        guard challenge.hintLadder.indices.contains(index) else { return nil }
        return challenge.hintLadder[index]
    }

    static func submit(
        state: LessonRecallState,
        challenge: RecallChallenge,
        typedAnswer: String,
        selectedChoiceTitle: String?,
        successMastery: MasteryState
    ) -> LessonRecallEvaluation {
        let candidateAnswer: String
        if !normalized(typedAnswer).isEmpty {
            candidateAnswer = typedAnswer
        } else {
            candidateAnswer = selectedChoiceTitle ?? ""
        }

        if answerMatches(candidateAnswer, challenge: challenge) {
            return LessonRecallEvaluation(
                wasSuccessful: true,
                masteryAwarded: successMastery,
                feedbackText: challenge.feedback.success,
                revealedHintLevel: state.revealedHintLevel,
                recognitionRescueUnlocked: state.recognitionRescueUnlocked
            )
        }

        let hintedState = revealNextHint(from: state, challenge: challenge)
        let feedbackText = hintedState.feedbackText ?? challenge.feedback.recovery
        return LessonRecallEvaluation(
            wasSuccessful: false,
            masteryAwarded: .witnessed,
            feedbackText: feedbackText,
            revealedHintLevel: hintedState.revealedHintLevel,
            recognitionRescueUnlocked: hintedState.recognitionRescueUnlocked
        )
    }
}

struct LessonPlanStep: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String

    static let starterSet: [LessonPlanStep] = [
        LessonPlanStep(id: "gate", title: "Protect the gate", detail: "A strong entrance helps a fort stay prepared.", symbol: "shield"),
        LessonPlanStep(id: "watch", title: "Keep a watch post", detail: "Seeing the hills clearly gives early warning.", symbol: "eye.fill"),
        LessonPlanStep(id: "water", title: "Store water", detail: "A fort must be ready for long stretches of planning and defense.", symbol: "drop.fill"),
        LessonPlanStep(id: "grain", title: "Save food", detail: "Supplies help people stay steady and safe.", symbol: "shippingbox.fill")
    ]
}
