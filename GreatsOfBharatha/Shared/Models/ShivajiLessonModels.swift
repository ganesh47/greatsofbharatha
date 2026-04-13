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
