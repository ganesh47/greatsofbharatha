import Foundation

/// The television journey has explicit Select-driven activities instead of swipe/drag state.
enum TVActivityStage: String, Codable, CaseIterable, Equatable {
    case story, discover, place, recall, puzzle, keepsake
}

struct TVActivityCheckpoint: Codable, Equatable {
    var stage: TVActivityStage = .story
    var storyBeatIndex: Int = 0
    /// Optional in old saves. The index remains a legacy three-beat rollback anchor.
    var storyBeatID: String?
    var discoveredDetailIDs: Set<String> = []
    var solvedPlaceIDs: Set<String> = []
    var helpedActivityIDs: Set<String> = []
    var matchedPairIDs: Set<String> = []
    var completedActivityIDs: Set<String> = []
    var hintLevels: [String: Int] = [:]
    var sequenceSlots: [String?] = []
    var completionEventIDs: [String: UUID] = [:]
    var selectedTileID: String?
    var timelineCheckpoint: TVTimelineCheckpoint?
    /// Optional in earlier saves. A family practice interruption resumes before the puzzle.
    var knowledgePracticePending: Bool?

    /// Keep IDs stable between Select, persistence, and a process relaunch.
    mutating func eventID(for activityID: String) -> UUID {
        if let existing = completionEventIDs[activityID] { return existing }
        let id = UUID()
        completionEventIDs[activityID] = id
        return id
    }
}

/// An optional timeline revisit lives alongside, rather than replacing, a chapter's puzzle.
struct TVTimelineCheckpoint: Codable, Equatable {
    var mode: String = "opening"
    var roundIndex: Int = 0
    var slots: [String?] = []
    var selectedCardID: String?
    var hintLevel: Int = 0
    var helpedRoundIndices: Set<Int> = []
    var completedRoundIndices: Set<Int> = []
    var sessionID: UUID = UUID()
}
