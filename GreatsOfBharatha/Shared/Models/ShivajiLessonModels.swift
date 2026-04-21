import Foundation

struct LessonChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

struct LessonRecallState: Equatable {
    var selectedChoiceID: String?
    var feedbackText: String?
    var hasAnsweredCorrectly = false
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
