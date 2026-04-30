import Foundation

enum ChronicleQuizAttemptKind: Codable, Equatable {
    case correctWithoutHint
    case correctWithHint
    case rescuedRecognition
    case incorrect
}

struct ChronicleQuizState: Codable, Equatable {
    var typedAnswer: String
    var selectedAnswer: String?
    var revealedHintCount: Int
    var recognitionRescueUnlocked: Bool
    var attempts: Int

    init(
        typedAnswer: String = "",
        selectedAnswer: String? = nil,
        revealedHintCount: Int = 0,
        recognitionRescueUnlocked: Bool = false,
        attempts: Int = 0
    ) {
        self.typedAnswer = typedAnswer
        self.selectedAnswer = selectedAnswer
        self.revealedHintCount = revealedHintCount
        self.recognitionRescueUnlocked = recognitionRescueUnlocked
        self.attempts = attempts
    }
}

struct ChronicleQuizResult: Codable, Equatable {
    let kind: ChronicleQuizAttemptKind
    let isCorrect: Bool
    let masteryAwarded: MasteryState
    let feedback: String
    let nextState: ChronicleQuizState

    var shouldUseSoonReview: Bool {
        switch kind {
        case .correctWithoutHint:
            return false
        case .correctWithHint, .rescuedRecognition, .incorrect:
            return true
        }
    }
}

enum ChronicleQuizEngine {
    static func normalizedAnswer(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let scalars = folded.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return String(scalars)
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func answerMatches(_ answer: String, challenge: RecallChallenge) -> Bool {
        let candidate = normalizedAnswer(answer)
        guard !candidate.isEmpty else { return false }

        return challenge.correctAnswers.contains { correctAnswer in
            let normalizedCorrectAnswer = normalizedAnswer(correctAnswer)
            return candidate == normalizedCorrectAnswer
                || candidate.hasPrefix(normalizedCorrectAnswer + " ")
                || normalizedCorrectAnswer.hasPrefix(candidate + " ")
        }
    }

    static func currentHint(for state: ChronicleQuizState, challenge: RecallChallenge) -> RecallHint? {
        guard state.revealedHintCount > 0 else { return nil }
        let index = min(state.revealedHintCount - 1, challenge.hintLadder.count - 1)
        guard challenge.hintLadder.indices.contains(index) else { return nil }
        return challenge.hintLadder[index]
    }

    static func revealNextHint(from state: ChronicleQuizState, challenge: RecallChallenge) -> ChronicleQuizState {
        var nextState = state
        if nextState.revealedHintCount < challenge.hintLadder.count {
            nextState.revealedHintCount += 1
        } else {
            nextState.recognitionRescueUnlocked = true
        }
        return nextState
    }

    static func evaluate(
        state: ChronicleQuizState,
        challenge: RecallChallenge,
        typedAnswer: String? = nil,
        selectedAnswer: String? = nil
    ) -> ChronicleQuizResult {
        var nextState = state
        if let typedAnswer {
            nextState.typedAnswer = typedAnswer
        }
        if let selectedAnswer {
            nextState.selectedAnswer = selectedAnswer
        }
        nextState.attempts += 1

        let candidateAnswer = normalizedAnswer(nextState.typedAnswer).isEmpty
            ? (nextState.selectedAnswer ?? "")
            : nextState.typedAnswer

        if answerMatches(candidateAnswer, challenge: challenge) {
            let kind: ChronicleQuizAttemptKind = nextState.recognitionRescueUnlocked
                ? .rescuedRecognition
                : (nextState.revealedHintCount == 0 ? .correctWithoutHint : .correctWithHint)
            return ChronicleQuizResult(
                kind: kind,
                isCorrect: true,
                masteryAwarded: challenge.masteryContribution,
                feedback: challenge.feedback.success,
                nextState: nextState
            )
        }

        nextState = revealNextHint(from: nextState, challenge: challenge)
        let feedback: String
        if let hint = currentHint(for: nextState, challenge: challenge) {
            feedback = "Try again. \(hint.title): \(hint.body)"
        } else {
            feedback = challenge.feedback.recovery
        }

        return ChronicleQuizResult(
            kind: nextState.recognitionRescueUnlocked ? .rescuedRecognition : .incorrect,
            isCorrect: false,
            masteryAwarded: .witnessed,
            feedback: feedback,
            nextState: nextState
        )
    }
}

enum ChronicleMatchPairKind: String, Codable, CaseIterable, Equatable {
    case placeToHook
    case placeToAction
    case eventToTimeMarker
    case meaningToScene
}

struct ChronicleMatchPair: Identifiable, Codable, Equatable {
    let id: String
    let leftID: String
    let leftText: String
    let rightID: String
    let rightText: String
    let kind: ChronicleMatchPairKind
    let teachingClue: String
}

enum ChronicleMatchTileSide: String, Codable, Equatable {
    case left
    case right
}

struct ChronicleMatchTile: Identifiable, Codable, Equatable {
    let id: String
    let pairID: String
    let side: ChronicleMatchTileSide
    let text: String
}

enum ChronicleMatchSelectionOutcome: Codable, Equatable {
    case selected(ChronicleMatchTile)
    case matched(pairID: String, feedback: String, completedSet: Bool)
    case mismatched(clue: String)
    case ignored
}

struct ChronicleMatchState: Codable, Equatable {
    var selectedTileID: String?
    var completedPairIDs: Set<String>
    var mismatchCount: Int
    var lastOutcome: ChronicleMatchSelectionOutcome?

    init(
        selectedTileID: String? = nil,
        completedPairIDs: Set<String> = [],
        mismatchCount: Int = 0,
        lastOutcome: ChronicleMatchSelectionOutcome? = nil
    ) {
        self.selectedTileID = selectedTileID
        self.completedPairIDs = completedPairIDs
        self.mismatchCount = mismatchCount
        self.lastOutcome = lastOutcome
    }
}

enum ChronicleMatchEngine {
    static func tiles(for pairs: [ChronicleMatchPair], shuffleSeed: Int? = nil) -> [ChronicleMatchTile] {
        let tiles = pairs.flatMap { pair in
            [
                ChronicleMatchTile(id: pair.leftID, pairID: pair.id, side: .left, text: pair.leftText),
                ChronicleMatchTile(id: pair.rightID, pairID: pair.id, side: .right, text: pair.rightText),
            ]
        }

        guard let shuffleSeed else { return tiles }
        return seededShuffle(tiles, seed: shuffleSeed)
    }

    static func select(tileID: String, state: ChronicleMatchState, pairs: [ChronicleMatchPair]) -> ChronicleMatchState {
        let tiles = tiles(for: pairs)
        guard let tile = tiles.first(where: { $0.id == tileID }) else {
            var nextState = state
            nextState.lastOutcome = .ignored
            return nextState
        }
        guard !state.completedPairIDs.contains(tile.pairID) else {
            var nextState = state
            nextState.lastOutcome = .ignored
            return nextState
        }
        guard let selectedTileID = state.selectedTileID else {
            var nextState = state
            nextState.selectedTileID = tile.id
            nextState.lastOutcome = .selected(tile)
            return nextState
        }
        guard selectedTileID != tile.id else {
            var nextState = state
            nextState.selectedTileID = nil
            nextState.lastOutcome = .ignored
            return nextState
        }
        guard let selectedTile = tiles.first(where: { $0.id == selectedTileID }) else {
            var nextState = state
            nextState.selectedTileID = tile.id
            nextState.lastOutcome = .selected(tile)
            return nextState
        }

        var nextState = state
        nextState.selectedTileID = nil

        if selectedTile.pairID == tile.pairID && selectedTile.side != tile.side {
            nextState.completedPairIDs.insert(tile.pairID)
            nextState.lastOutcome = .matched(
                pairID: tile.pairID,
                feedback: "Yes. \(selectedTile.text) belongs with \(tile.text).",
                completedSet: nextState.completedPairIDs.count == pairs.count
            )
            return nextState
        }

        nextState.mismatchCount += 1
        let clue = mismatchClue(first: selectedTile, second: tile, pairs: pairs)
        nextState.lastOutcome = .mismatched(clue: clue)
        return nextState
    }

    private static func mismatchClue(first: ChronicleMatchTile, second: ChronicleMatchTile, pairs: [ChronicleMatchPair]) -> String {
        let preferredPairID = first.side == .left ? first.pairID : second.pairID
        if let pair = pairs.first(where: { $0.id == preferredPairID }) {
            return pair.teachingClue
        }
        return "Look for the memory hook that belongs with this place."
    }

    private static func seededShuffle<T>(_ values: [T], seed: Int) -> [T] {
        guard values.count > 1 else { return values }
        var shuffled = values
        var generator = SeededNumberGenerator(seed: UInt64(abs(seed) + 1))

        for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let swapIndex = Int(generator.next() % UInt64(index + 1))
            shuffled.swapAt(index, swapIndex)
        }
        return shuffled
    }
}

private struct SeededNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = 6364136223846793005 &* state &+ 1442695040888963407
        return state
    }
}

enum LearningReviewResponse: String, Codable, CaseIterable, Equatable {
    case knewIt
    case neededClue
    case teachAgain
}

struct LearningReviewSeed: Identifiable, Codable, Equatable {
    let id: String
    let subjectID: String
    let subjectType: MasterySubjectType
    let promptTypes: [RecallPromptType]
    let cadenceDays: [Int]
}

struct LearningReviewSchedulingResult: Codable, Equatable {
    let schedule: ReviewSchedule
    let nextPromptType: RecallPromptType
    let shouldReviewInCurrentSession: Bool
}

enum SpacedReviewScheduler {
    static func makeInitialSchedule(from seed: LearningReviewSeed, now: Date) -> ReviewSchedule {
        ReviewSchedule(
            subjectID: seed.subjectID,
            subjectType: seed.subjectType,
            nextDueAt: now,
            intervalIndex: 0,
            stabilityBand: .new,
            difficultyAdjustment: 0,
            cadenceDays: seed.cadenceDays.isEmpty ? [0, 1, 3, 7, 14] : seed.cadenceDays
        )
    }

    static func schedule(
        _ schedule: ReviewSchedule,
        after quizResult: ChronicleQuizResult,
        promptHistory: [RecallPromptType],
        now: Date,
        calendar: Calendar = .current
    ) -> LearningReviewSchedulingResult {
        let response: LearningReviewResponse
        switch quizResult.kind {
        case .correctWithoutHint:
            response = .knewIt
        case .correctWithHint:
            response = .neededClue
        case .rescuedRecognition, .incorrect:
            response = .teachAgain
        }

        return schedule(schedule, after: response, promptHistory: promptHistory, now: now, calendar: calendar)
    }

    static func schedule(
        _ schedule: ReviewSchedule,
        after response: LearningReviewResponse,
        promptHistory: [RecallPromptType],
        now: Date,
        calendar: Calendar = .current
    ) -> LearningReviewSchedulingResult {
        var nextSchedule = schedule
        let shouldReviewInCurrentSession: Bool

        switch response {
        case .knewIt:
            nextSchedule.intervalIndex = min(schedule.intervalIndex + 1, max(schedule.cadenceDays.count - 1, 0))
            shouldReviewInCurrentSession = false
        case .neededClue:
            nextSchedule.intervalIndex = max(schedule.intervalIndex, min(1, max(schedule.cadenceDays.count - 1, 0)))
            shouldReviewInCurrentSession = false
        case .teachAgain:
            nextSchedule.intervalIndex = 0
            shouldReviewInCurrentSession = true
        }

        nextSchedule.stabilityBand = stabilityBand(for: nextSchedule.intervalIndex)
        nextSchedule.difficultyAdjustment = difficultyAdjustment(for: response, current: schedule.difficultyAdjustment)
        nextSchedule.nextDueAt = nextDueAt(
            for: response,
            schedule: nextSchedule,
            now: now,
            calendar: calendar
        )

        return LearningReviewSchedulingResult(
            schedule: nextSchedule,
            nextPromptType: nextPromptType(after: promptHistory),
            shouldReviewInCurrentSession: shouldReviewInCurrentSession
        )
    }

    static func dueReviews(from schedules: [ReviewSchedule], now: Date) -> [ReviewSchedule] {
        schedules
            .filter { $0.nextDueAt <= now }
            .sorted { lhs, rhs in
                if lhs.nextDueAt == rhs.nextDueAt {
                    return lhs.subjectID < rhs.subjectID
                }
                return lhs.nextDueAt < rhs.nextDueAt
            }
    }

    static func nextPromptType(after history: [RecallPromptType]) -> RecallPromptType {
        let rotation: [RecallPromptType] = [.openPrompt, .eventToPlaceMatch, .sequenceSlot, .compareFromMemory]
        guard let last = history.last, let index = rotation.firstIndex(of: last) else {
            return rotation[0]
        }
        return rotation[(index + 1) % rotation.count]
    }

    private static func nextDueAt(
        for response: LearningReviewResponse,
        schedule: ReviewSchedule,
        now: Date,
        calendar: Calendar
    ) -> Date {
        switch response {
        case .knewIt:
            let days = schedule.cadenceDays.isEmpty ? 1 : max(schedule.cadenceDays[schedule.intervalIndex], 1)
            return calendar.date(byAdding: .day, value: days, to: now) ?? now.addingTimeInterval(24 * 60 * 60)
        case .neededClue:
            return calendar.date(byAdding: .hour, value: 4, to: now) ?? now.addingTimeInterval(4 * 60 * 60)
        case .teachAgain:
            return now
        }
    }

    private static func stabilityBand(for intervalIndex: Int) -> ReviewStabilityBand {
        switch intervalIndex {
        case 0:
            return .new
        case 1:
            return .warming
        case 2...3:
            return .steady
        default:
            return .durable
        }
    }

    private static func difficultyAdjustment(for response: LearningReviewResponse, current: Int) -> Int {
        switch response {
        case .knewIt:
            return max(current - 1, -2)
        case .neededClue:
            return current
        case .teachAgain:
            return min(current + 1, 3)
        }
    }
}

enum ChronicleProgressEvent: String, Codable, CaseIterable, Equatable, Hashable {
    case lessonSeen
    case recallCorrect
    case matchCompleted
    case timelineCompleted
    case reviewCorrect
}

enum ChronicleRewardDetailLevel: String, Codable, CaseIterable, Comparable, Equatable {
    case hidden
    case silhouette
    case inked
    case sealed
    case rememberedAgain

    var rank: Int {
        switch self {
        case .hidden:
            return 0
        case .silhouette:
            return 1
        case .inked:
            return 2
        case .sealed:
            return 3
        case .rememberedAgain:
            return 4
        }
    }

    static func < (lhs: ChronicleRewardDetailLevel, rhs: ChronicleRewardDetailLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

struct ChronicleRewardProgress: Identifiable, Codable, Equatable {
    let id: String
    let entryID: String
    let sceneID: String
    var detailLevel: ChronicleRewardDetailLevel
    var unlockState: ChronicleUnlockState
    var completedEvents: Set<ChronicleProgressEvent>
    var updatedAt: Date?

    init(
        entryID: String,
        sceneID: String,
        detailLevel: ChronicleRewardDetailLevel = .hidden,
        unlockState: ChronicleUnlockState = .silhouette,
        completedEvents: Set<ChronicleProgressEvent> = [],
        updatedAt: Date? = nil
    ) {
        self.id = entryID
        self.entryID = entryID
        self.sceneID = sceneID
        self.detailLevel = detailLevel
        self.unlockState = unlockState
        self.completedEvents = completedEvents
        self.updatedAt = updatedAt
    }
}

enum ChronicleProgressEngine {
    static func initialProgress(for entry: ChronicleEntry) -> ChronicleRewardProgress {
        ChronicleRewardProgress(entryID: entry.id, sceneID: entry.linkedSceneID)
    }

    static func apply(
        _ event: ChronicleProgressEvent,
        to progress: ChronicleRewardProgress,
        at date: Date
    ) -> ChronicleRewardProgress {
        var nextProgress = progress
        nextProgress.completedEvents.insert(event)
        nextProgress.detailLevel = max(nextProgress.detailLevel, detailLevel(for: event))
        nextProgress.unlockState = unlockState(for: nextProgress.detailLevel)
        nextProgress.updatedAt = date
        return nextProgress
    }

    static func apply(
        _ events: [ChronicleProgressEvent],
        to progress: ChronicleRewardProgress,
        at date: Date
    ) -> ChronicleRewardProgress {
        events.reduce(progress) { partialResult, event in
            apply(event, to: partialResult, at: date)
        }
    }

    static func progress(
        for entry: ChronicleEntry,
        evidence: [ChronicleProgressEvent],
        at date: Date
    ) -> ChronicleRewardProgress {
        apply(evidence, to: initialProgress(for: entry), at: date)
    }

    private static func detailLevel(for event: ChronicleProgressEvent) -> ChronicleRewardDetailLevel {
        switch event {
        case .lessonSeen:
            return .silhouette
        case .recallCorrect:
            return .inked
        case .matchCompleted, .timelineCompleted:
            return .sealed
        case .reviewCorrect:
            return .rememberedAgain
        }
    }

    private static func unlockState(for detailLevel: ChronicleRewardDetailLevel) -> ChronicleUnlockState {
        switch detailLevel {
        case .hidden, .silhouette:
            return .silhouette
        case .inked:
            return .unlocked
        case .sealed, .rememberedAgain:
            return .enriched
        }
    }
}
