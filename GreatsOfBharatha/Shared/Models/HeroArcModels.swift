import Foundation

struct HeroArc: Identifiable, Equatable {
    let id: String
    let hero: Hero
    let title: String
    let scenes: [SceneCluster]
    let chronicleEntries: [ChronicleEntry]
    let locationNodes: [LocationNode]
    let timelineEvents: [TimelineEvent]
    let reviewBlueprints: [ReviewSchedule]

    var orderedSceneIDs: [String] {
        scenes.map { $0.id }
    }

    func scene(withID sceneID: String) -> SceneCluster? {
        scenes.first(where: { $0.id == sceneID })
    }

    func chronicleEntry(withID entryID: String) -> ChronicleEntry? {
        chronicleEntries.first(where: { $0.id == entryID })
    }

    func locationNode(withID locationID: String) -> LocationNode? {
        locationNodes.first(where: { $0.id == locationID })
    }

    func timelineEvent(withID eventID: String) -> TimelineEvent? {
        timelineEvents.first(where: { $0.id == eventID })
    }
}

struct Hero: Equatable {
    let id: String
    let name: String
    let subtitle: String
    let culturalFramingNotes: String
    let ageBandCopyVariants: [AgeBand: String]
}

enum AgeBand: String, Codable, CaseIterable, Equatable {
    case assist
    case standard
}

struct SceneCluster: Identifiable, Equatable {
    let id: String
    let sceneNumber: Int
    let title: String
    let narrativeObjective: String
    let keyFact: String
    let meaningStatement: String
    let childSafeSummary: String
    let mapAnchorIDs: [String]
    let timelineEventID: String
    let cards: [LearningCard]
    let recallChallenges: [RecallChallenge]
    let chronicleEntryIDs: [String]

    var primaryRecallChallenge: RecallChallenge? {
        recallChallenges.first
    }
}

enum LearningCardType: String, Codable, CaseIterable, Equatable {
    case story
    case meaning
    case anchor
    case recall
    case compare
    case reward
    case review
}

struct LearningCard: Identifiable, Equatable {
    let id: String
    let type: LearningCardType
    let title: String
    let text: String
    let narration: String
    let imageKey: String
    let memoryHook: String?
    let difficultyBand: DifficultyBand
}

enum DifficultyBand: String, Codable, CaseIterable, Equatable {
    case assist
    case standard
    case stretch
}

enum RecallPromptType: String, Codable, CaseIterable, Equatable {
    case openPrompt
    case mapPlacement
    case sequenceSlot
    case eventToPlaceMatch
    case compareFromMemory
}

struct RecallChallenge: Identifiable, Equatable {
    let id: String
    let promptType: RecallPromptType
    let prompt: String
    let correctAnswers: [String]
    let hintLadder: [RecallHint]
    let feedback: RecallFeedback
    let masteryContribution: MasteryState
}

struct RecallHint: Codable, Equatable {
    let level: Int
    let title: String
    let body: String
}

struct RecallFeedback: Codable, Equatable {
    let success: String
    let recovery: String
}

enum MasterySubjectType: String, Codable, CaseIterable, Equatable {
    case scene
    case chronicle
    case location
    case timeline
}

enum MasteryEvidenceType: String, Codable, CaseIterable, Equatable {
    case storyExposure
    case recallAttempt
    case recallSuccess
    case mapPlacementSuccess
    case timelinePlacementSuccess
    case reviewSuccess
    case chronicleReflection
}

struct MasteryEvidence: Codable, Equatable {
    let type: MasteryEvidenceType
    let recordedAt: Date
    let detail: String
}

struct MasteryRecord: Codable, Equatable {
    let subjectID: String
    let subjectType: MasterySubjectType
    var state: MasteryState
    var exposureCount: Int
    var successfulReviewCount: Int
    var lastReviewedAt: Date?
    var evidenceLog: [MasteryEvidence]
}

struct ChronicleEntry: Identifiable, Equatable {
    let id: String
    let title: String
    let keepsakeTitle: String
    let meaningStatement: String
    let linkedSceneID: String
    let linkedPlaceID: String?
    let linkedTimelineEventID: String?
    let unlockRule: UnlockRule
}

struct UnlockRule: Codable, Equatable {
    let requiredMastery: MasteryState
    let enhancedMastery: MasteryState?
}

enum ChronicleUnlockState: String, Codable, CaseIterable, Equatable {
    case silhouette
    case unlocked
    case enriched
}

struct LocationNode: Identifiable, Equatable {
    let id: String
    let name: String
    let canonicalCoordinate: Coordinate
    let memoryHook: String
    let primaryEvent: String
    let regionLabel: String
    let linkedSceneIDs: [String]
    let linkedTimelineEventIDs: [String]
    let unlockRule: UnlockRule
    let isCoreReleasePlace: Bool
}

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

enum LocationUnlockState: String, Codable, CaseIterable, Equatable {
    case hidden
    case seenInStory
    case learnable
    case remembered
    case placedAccurately
    case masteredInReview
}

struct TimelineEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let orderIndex: Int
    let broadEraLabel: String
    let yearLabel: String?
    let linkedPlaceIDs: [String]
    let recallPrompt: String
    let unlockRule: UnlockRule
}

struct ReviewSchedule: Codable, Equatable {
    let subjectID: String
    let subjectType: MasterySubjectType
    var nextDueAt: Date
    var intervalIndex: Int
    var stabilityBand: ReviewStabilityBand
    var difficultyAdjustment: Int
    let cadenceDays: [Int]
}

enum ReviewStabilityBand: String, Codable, CaseIterable, Equatable {
    case new
    case warming
    case steady
    case durable
}
