import Foundation

final class ShivajiLessonStore: ObservableObject {
    @Published private(set) var masteryByScene: [String: MasteryState] = [:]

    private let content: AppContent

    init(content: AppContent = SampleContent.shivajiVerticalSlice) {
        self.content = content
    }

    func mastery(for sceneID: String) -> MasteryState? {
        masteryByScene[sceneID]
    }

    func markScene(_ sceneID: String, mastery: MasteryState) {
        let current = masteryByScene[sceneID] ?? .witnessed
        masteryByScene[sceneID] = higherMastery(current, mastery)
    }

    func resetScene(_ sceneID: String) {
        masteryByScene.removeValue(forKey: sceneID)
    }

    func isUnlocked(_ reward: ChronicleReward) -> Bool {
        masteryByScene[reward.unlockedBySceneID] != nil
    }

    func unlockedRewards(from rewards: [ChronicleReward]) -> [ChronicleReward] {
        rewards.filter(isUnlocked)
    }

    func progress(for place: Place) -> PlaceProgress {
        switch place.id {
        case "place-shivneri":
            return mastery(for: "scene-1-shivneri") == nil ? .readyToLearn : .reviewed
        case "place-torna", "place-rajgad":
            if let mastery = mastery(for: "scene-2-torna-rajgad") {
                return mastery == .observedClosely ? .masteredLightly : .reviewed
            }
            return .readyToLearn
        default:
            return place.progress
        }
    }

    var completedScenes: Int {
        masteryByScene.count
    }

    var totalScenes: Int {
        content.scenes.count
    }

    var overallProgress: Double {
        guard totalScenes > 0 else { return 0 }
        return Double(completedScenes) / Double(totalScenes)
    }

    var chronicleHeadline: String {
        switch completedScenes {
        case 0: return "Begin the Chronicle"
        case totalScenes: return "The first Chronicle page is complete"
        default: return "Your Chronicle is taking shape"
        }
    }

    var nextSceneID: String? {
        content.scenes.first(where: { mastery(for: $0.id) == nil })?.id
    }

    private func higherMastery(_ lhs: MasteryState, _ rhs: MasteryState) -> MasteryState {
        let rank: [MasteryState: Int] = [
            .witnessed: 0,
            .understood: 1,
            .observedClosely: 2
        ]

        return (rank[lhs] ?? 0) >= (rank[rhs] ?? 0) ? lhs : rhs
    }
}
