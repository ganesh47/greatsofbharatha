import Foundation

struct AppContent: Equatable {
    let arcTitle: String
    let scenes: [StoryScene]
    let places: [Place]
    let rewards: [ChronicleReward]

    var corePlaces: [Place] {
        places.filter { $0.isCoreReleasePlace }
    }
}

struct StoryScene: Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    let narrativeObjective: String
    let keyFact: String
    let childSafeSummary: String
    let mapAnchors: [String]
    let timelineMarker: String
    let interactionSteps: [String]
    let recallPrompt: RecallPrompt
    let rewardID: String
}

struct Place: Identifiable, Equatable {
    let id: String
    let name: String
    let memoryHook: String
    let primaryEvent: String
    let whyItMatters: String
    let regionLabel: String
    let latitude: Double
    let longitude: Double
    let progress: PlaceProgress
    let isCoreReleasePlace: Bool
}

struct ChronicleReward: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let meaning: String
    let unlockedBySceneID: String
    let mastery: MasteryState
    let category: RewardCategory
}

struct RecallPrompt: Equatable {
    let question: String
    let answer: String
    let supportText: String
}

enum PlaceProgress: String, CaseIterable, Equatable {
    case locked = "Locked by story"
    case readyToLearn = "Ready to learn"
    case reviewed = "Reviewed"
    case masteredLightly = "Mastered lightly"
}

enum MasteryState: String, CaseIterable, Equatable {
    case witnessed = "Witnessed"
    case understood = "Understood"
    case observedClosely = "Observed Closely"
}

enum RewardCategory: String, CaseIterable, Equatable {
    case storyCard = "Story Card"
    case emblemFragment = "Emblem Fragment"
    case leadershipBadge = "Leadership Badge"
}
