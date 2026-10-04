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

struct HistoricalFigureArc: Identifiable, Equatable {
    let id: String
    let figureName: String
    let title: String
    let resetAnchorIssue: String
    let scenes: [ChronicleScene]
    let timelineBuilder: TimelineBuilderSeed
    let endOfPilotReward: ChronicleReward
}

struct ChronicleScene: Identifiable, Equatable {
    let id: String
    let title: String
    let timeMarker: String
    let placeAnchors: [PlaceAnchor]
    let actionVerb: String
    let memoryHook: String
    let childSafeStory: String
    let meaning: String
    let quizItems: [QuizItem]
    let matchPairs: [MatchPair]
    let chronicleReward: ChronicleReward
    let reviewSeeds: [ReviewSeed]
}

struct PlaceAnchor: Identifiable, Equatable {
    let id: String
    let name: String
    let regionLabel: String
    let memoryHook: String
}

struct QuizItem: Identifiable, Equatable {
    let id: String
    let prompt: String
    let acceptedAnswers: [String]
    let answerChips: [String]
    let hintLadder: [RecallHint]
    let successFeedback: String
    let recoveryFeedback: String
}

enum MatchPairKind: String, Codable, CaseIterable, Equatable {
    case placeToHook
    case placeToAction
    case eventToTime
    case actionToMeaning
}

struct MatchPair: Identifiable, Equatable {
    let id: String
    let left: String
    let right: String
    let kind: MatchPairKind
    let teachingFeedback: String
}

struct TimelineBuilderSeed: Identifiable, Equatable {
    let id: String
    let prompt: String
    let orderedSceneIDs: [String]
    let completionRewardText: String
}

struct ReviewSeed: Identifiable, Equatable {
    let id: String
    let promptType: RecallPromptType
    let front: String
    let back: String
    let meaning: String
    let correctNoHintCadenceDays: Int
    let correctWithHintCadenceDays: Int
    let rescuedCadenceDays: Int
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
    case recognitionChoice
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
    case matchSuccess
    case selfReportedReview
}

enum LearningParticipation: String, Codable {
    case typedResponse, individualRecognition, sharedFamilyRecognition
}

struct MasteryEvidence: Codable, Equatable {
    let type: MasteryEvidenceType
    let recordedAt: Date
    let detail: String
    var eventID: UUID? = nil
    var activity: LearningActivityKind? = nil
    var support: LearningSupport? = nil
    var sessionID: UUID? = nil
    var promptType: RecallPromptType? = nil
    var reviewResponse: LearningReviewResponse? = nil
    var cardID: String? = nil
    var checkedPromptID: String? = nil
    var reviewKind: ReviewJourneyEvidenceKind? = nil
    var participation: LearningParticipation? = nil
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


/// Authored facts and observed actions are separate from the amount of help offered.
enum LearningActivityKind: String, Codable, Equatable {
    case storyExposure, recall, match, mapPlacement, timelinePlacement, review, albumPlacement
}

enum LearningSupport: String, Codable, Equatable {
    case independent, hinted, rescued, selfReported
}

enum LessonResumePhase: String, Codable, Equatable {
    case story, place, recall, reward
}

struct LessonResumePoint: Codable, Equatable {
    let sceneID: String
    var phase: LessonResumePhase = .story
    var sessionID: UUID = UUID()
    var storyCardIndex: Int = 0
    var storyBeatID: String?
    var revealedHintLevel: Int = 0
    var recognitionRescueUnlocked: Bool = false
    var recallCompleted: Bool = false
    var completedMatchPairIDs: Set<String> = []
    var selectedMatchTileID: String?
    var matchMismatchCount: Int = 0
    var recallEventID: UUID = UUID()
    var matchEventID: UUID = UUID()
    var preferredActivity: LearningActivityKind? = nil
    var discoveredDetailIDs: Set<String> = []
    var selectedDiscoveryDetailID: String?
    var selectedAtlasDiscoveryID: String?
    var selectedPlaceChoiceIDs: [String: String] = [:]
    var solvedPlaceIDs: Set<String> = []
    var helpedPlaceIDs: Set<String> = []
    var tvCheckpoint: TVActivityCheckpoint? = nil
    var updatedAt: Date = Date()

    private enum CodingKeys: String, CodingKey {
        case sceneID, phase, sessionID, storyCardIndex, storyBeatID, revealedHintLevel, recognitionRescueUnlocked
        case recallCompleted, completedMatchPairIDs, selectedMatchTileID, matchMismatchCount, recallEventID, matchEventID, preferredActivity
        case selectedAtlasDiscoveryID, selectedPlaceChoiceIDs
        case discoveredDetailIDs, selectedDiscoveryDetailID, solvedPlaceIDs, helpedPlaceIDs, tvCheckpoint, updatedAt
    }

    // Optional checkpoint fields keep existing callers and older saved lessons compatible.
    // swiftlint:disable:next function_parameter_count
    init(sceneID: String, phase: LessonResumePhase = .story, sessionID: UUID = UUID(), storyCardIndex: Int = 0,
         revealedHintLevel: Int = 0, recognitionRescueUnlocked: Bool = false, recallCompleted: Bool = false,
         completedMatchPairIDs: Set<String> = [], selectedMatchTileID: String? = nil,
         matchMismatchCount: Int = 0, recallEventID: UUID = UUID(),
         matchEventID: UUID = UUID(), preferredActivity: LearningActivityKind? = nil,
         discoveredDetailIDs: Set<String> = [], selectedDiscoveryDetailID: String? = nil,
         selectedAtlasDiscoveryID: String? = nil, selectedPlaceChoiceIDs: [String: String] = [:],
         solvedPlaceIDs: Set<String> = [], helpedPlaceIDs: Set<String> = [],
         tvCheckpoint: TVActivityCheckpoint? = nil, storyBeatID: String? = nil, updatedAt: Date = Date()) {
        self.sceneID = sceneID
        self.phase = phase
        self.sessionID = sessionID
        self.storyCardIndex = max(storyCardIndex, 0)
        self.storyBeatID = storyBeatID
        self.revealedHintLevel = max(revealedHintLevel, 0)
        self.recognitionRescueUnlocked = recognitionRescueUnlocked
        self.recallCompleted = recallCompleted
        self.completedMatchPairIDs = completedMatchPairIDs
        self.selectedMatchTileID = selectedMatchTileID
        self.matchMismatchCount = max(matchMismatchCount, 0)
        self.recallEventID = recallEventID
        self.matchEventID = matchEventID
        self.preferredActivity = preferredActivity
        self.discoveredDetailIDs = discoveredDetailIDs
        self.selectedDiscoveryDetailID = selectedDiscoveryDetailID
        self.selectedAtlasDiscoveryID = selectedAtlasDiscoveryID
        self.selectedPlaceChoiceIDs = selectedPlaceChoiceIDs
        self.solvedPlaceIDs = solvedPlaceIDs
        self.helpedPlaceIDs = helpedPlaceIDs
        self.tvCheckpoint = tvCheckpoint
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sceneID = try values.decode(String.self, forKey: .sceneID)
        phase = try values.decodeIfPresent(LessonResumePhase.self, forKey: .phase) ?? .story
        sessionID = try values.decodeIfPresent(UUID.self, forKey: .sessionID) ?? UUID()
        storyCardIndex = max(try values.decodeIfPresent(Int.self, forKey: .storyCardIndex) ?? 0, 0)
        storyBeatID = try values.decodeIfPresent(String.self, forKey: .storyBeatID)
        revealedHintLevel = max(try values.decodeIfPresent(Int.self, forKey: .revealedHintLevel) ?? 0, 0)
        recognitionRescueUnlocked = try values.decodeIfPresent(Bool.self, forKey: .recognitionRescueUnlocked) ?? false
        recallCompleted = try values.decodeIfPresent(Bool.self, forKey: .recallCompleted) ?? false
        completedMatchPairIDs = try values.decodeIfPresent(Set<String>.self, forKey: .completedMatchPairIDs) ?? []
        selectedMatchTileID = try values.decodeIfPresent(String.self, forKey: .selectedMatchTileID)
        matchMismatchCount = max(try values.decodeIfPresent(Int.self, forKey: .matchMismatchCount) ?? 0, 0)
        recallEventID = try values.decodeIfPresent(UUID.self, forKey: .recallEventID) ?? UUID()
        matchEventID = try values.decodeIfPresent(UUID.self, forKey: .matchEventID) ?? UUID()
        preferredActivity = try values.decodeIfPresent(LearningActivityKind.self, forKey: .preferredActivity)
        discoveredDetailIDs = try values.decodeIfPresent(Set<String>.self, forKey: .discoveredDetailIDs) ?? []
        selectedDiscoveryDetailID = try values.decodeIfPresent(String.self, forKey: .selectedDiscoveryDetailID)
        selectedAtlasDiscoveryID = try values.decodeIfPresent(String.self, forKey: .selectedAtlasDiscoveryID)
        selectedPlaceChoiceIDs = try values.decodeIfPresent([String: String].self, forKey: .selectedPlaceChoiceIDs) ?? [:]
        solvedPlaceIDs = try values.decodeIfPresent(Set<String>.self, forKey: .solvedPlaceIDs) ?? []
        helpedPlaceIDs = try values.decodeIfPresent(Set<String>.self, forKey: .helpedPlaceIDs) ?? []
        tvCheckpoint = try values.decodeIfPresent(TVActivityCheckpoint.self, forKey: .tvCheckpoint)
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
    }
}
