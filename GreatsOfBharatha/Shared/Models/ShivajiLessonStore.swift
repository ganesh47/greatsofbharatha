import Foundation

final class ShivajiLessonStore: ObservableObject {
    @Published private(set) var masteryByScene: [String: MasteryState] = [:]

    func mastery(for sceneID: String) -> MasteryState? {
        masteryByScene[sceneID]
    }

    func markScene(_ sceneID: String, mastery: MasteryState) {
        let current = masteryByScene[sceneID] ?? .witnessed
        masteryByScene[sceneID] = max(current, mastery)
    }

    func isUnlocked(_ entry: ChronicleEntry) -> Bool {
        masteryByScene[entry.id] != nil
    }

    var completedScenes: Int {
        masteryByScene.count
    }

    var totalScenes: Int {
        Scene.all.count
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
}
