import Foundation

final class ShivajiLessonStore: ObservableObject {
    @Published private(set) var masteryByScene: [String: MasteryState] = [:]

    private let content: AppContent
    private let defaults: UserDefaults
    private let storageKey = "shivajiLessonStore.masteryByScene"

    init(content: AppContent = SampleContent.shivajiVerticalSlice, defaults: UserDefaults = .standard) {
        self.content = content
        self.defaults = defaults
        self.masteryByScene = Self.loadMastery(from: defaults, key: storageKey)
    }

    func mastery(for sceneID: String) -> MasteryState? {
        masteryByScene[sceneID]
    }

    func markScene(_ sceneID: String, mastery: MasteryState) {
        let current = masteryByScene[sceneID] ?? .witnessed
        masteryByScene[sceneID] = higherMastery(current, mastery)
        persist()
    }

    func resetScene(_ sceneID: String) {
        masteryByScene.removeValue(forKey: sceneID)
        persist()
    }

    func isUnlocked(_ reward: ChronicleReward) -> Bool {
        guard let mastery = masteryByScene[reward.unlockedBySceneID] else { return false }
        return masteryRank(mastery) >= masteryRank(.understood)
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
        masteryRank(lhs) >= masteryRank(rhs) ? lhs : rhs
    }

    private func masteryRank(_ mastery: MasteryState) -> Int {
        switch mastery {
        case .witnessed:
            return 0
        case .understood:
            return 1
        case .observedClosely:
            return 2
        }
    }

    private func persist() {
        let encoded = masteryByScene.mapValues(\ .rawValue)
        defaults.set(encoded, forKey: storageKey)
    }

    func applyCaptureSeed(_ profile: CaptureSeedProfile) {
        switch profile {
        case .pristine:
            masteryByScene = [:]
        case .chronicleUnlocked:
            masteryByScene = [
                "scene-1-shivneri": .understood,
                "scene-2-torna-rajgad": .observedClosely
            ]
        }
    }

    private static func loadMastery(from defaults: UserDefaults, key: String) -> [String: MasteryState] {
        guard let stored = defaults.dictionary(forKey: key) as? [String: String] else {
            return [:]
        }

        return stored.reduce(into: [:]) { result, item in
            guard let mastery = MasteryState(rawValue: item.value) else { return }
            result[item.key] = mastery
        }
    }
}
