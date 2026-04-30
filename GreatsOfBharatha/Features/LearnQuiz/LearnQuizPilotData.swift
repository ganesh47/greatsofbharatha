import SwiftUI

enum GBFeatureFlags {
    static var historyLearnQuizResetEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        if let rawValue = environment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"],
           ["1", "true", "yes"].contains(rawValue.lowercased()) {
            return true
        }
        return UserDefaults.standard.bool(forKey: "historyLearnQuizResetEnabled")
    }
}

struct LearnQuizPilotScene: Identifiable {
    let id: String
    let number: Int
    let title: String
    let subtitle: String
    let timeMarker: String
    let place: String
    let actionVerb: String
    let memoryHook: String
    let story: String
    let meaning: String
    let quiz: LearnQuizPrompt
    let matchPairs: [ChronicleMatchPair]
    let chronicleEntry: LearnQuizChronicleEntry
    let art: LearnQuizArt
}

struct LearnQuizPrompt {
    let question: String
    let options: [String]
    let correctAnswer: String
    let hintLadder: [String]
    let teachingFeedback: String
    let challenge: RecallChallenge
}

struct LearnQuizChronicleEntry: Identifiable {
    enum State: String, CaseIterable {
        case silhouette
        case inked
        case sealed
        case rememberedAgain
    }

    let id: String
    let title: String
    let subtitle: String
    let meaning: String
    let state: State
}

struct LearnQuizArt {
    let assetSlot: String
    let symbol: String
    let emphasis: GBEmphasis
}

enum LearnQuizPilotData {
    private static let pilot = SampleContent.shivajiLearnQuizResetPilot

    static var scenes: [LearnQuizPilotScene] {
        pilot.scenes.enumerated().map { index, scene in
            makeScene(from: scene, number: index + 1)
        }
    }

    static var journeyEntry: LearnQuizChronicleEntry {
        LearnQuizChronicleEntry(
            id: pilot.endOfPilotReward.id,
            title: pilot.endOfPilotReward.title,
            subtitle: pilot.endOfPilotReward.subtitle,
            meaning: pilot.endOfPilotReward.meaning,
            state: .rememberedAgain
        )
    }

    private static func makeScene(from scene: ChronicleScene, number: Int) -> LearnQuizPilotScene {
        let quizItem = scene.quizItems.first ?? fallbackQuizItem(for: scene)
        return LearnQuizPilotScene(
            id: scene.id,
            number: number,
            title: scene.title,
            subtitle: scene.memoryHook,
            timeMarker: scene.timeMarker,
            place: scene.placeAnchors.map(\.name).joined(separator: " + "),
            actionVerb: scene.actionVerb,
            memoryHook: scene.memoryHook,
            story: scene.childSafeStory,
            meaning: scene.meaning,
            quiz: makePrompt(from: quizItem),
            matchPairs: scene.matchPairs.map(makeMatchPair),
            chronicleEntry: makeChronicleEntry(from: scene),
            art: art(for: scene)
        )
    }

    private static func makePrompt(from item: QuizItem) -> LearnQuizPrompt {
        let challenge = RecallChallenge(
            id: item.id,
            promptType: .openPrompt,
            prompt: item.prompt,
            correctAnswers: item.acceptedAnswers,
            hintLadder: item.hintLadder,
            feedback: RecallFeedback(success: item.successFeedback, recovery: item.recoveryFeedback),
            masteryContribution: .understood
        )
        return LearnQuizPrompt(
            question: item.prompt,
            options: item.answerChips,
            correctAnswer: item.acceptedAnswers.first ?? item.answerChips.first ?? "",
            hintLadder: item.hintLadder.map(\.body),
            teachingFeedback: item.recoveryFeedback,
            challenge: challenge
        )
    }

    private static func makeMatchPair(from pair: MatchPair) -> ChronicleMatchPair {
        ChronicleMatchPair(
            id: pair.id,
            leftID: "\(pair.id)-left",
            leftText: pair.left,
            rightID: "\(pair.id)-right",
            rightText: pair.right,
            kind: makeMatchKind(from: pair.kind),
            teachingClue: pair.teachingFeedback
        )
    }

    private static func makeMatchKind(from kind: MatchPairKind) -> ChronicleMatchPairKind {
        switch kind {
        case .placeToHook:
            return .placeToHook
        case .placeToAction:
            return .placeToAction
        case .eventToTime:
            return .eventToTimeMarker
        case .actionToMeaning:
            return .meaningToScene
        }
    }

    private static func makeChronicleEntry(from scene: ChronicleScene) -> LearnQuizChronicleEntry {
        let entry = ChronicleEntry(
            id: scene.chronicleReward.id,
            title: scene.chronicleReward.title,
            keepsakeTitle: scene.chronicleReward.subtitle,
            meaningStatement: scene.chronicleReward.meaning,
            linkedSceneID: scene.id,
            linkedPlaceID: scene.placeAnchors.first?.id,
            linkedTimelineEventID: nil,
            unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .mastered)
        )
        let progress = ChronicleProgressEngine.progress(
            for: entry,
            evidence: [.lessonSeen, .recallCorrect],
            at: Date()
        )
        return LearnQuizChronicleEntry(
            id: scene.chronicleReward.id,
            title: scene.chronicleReward.title,
            subtitle: scene.chronicleReward.subtitle,
            meaning: scene.chronicleReward.meaning,
            state: makeEntryState(from: progress.detailLevel)
        )
    }

    private static func makeEntryState(from detailLevel: ChronicleRewardDetailLevel) -> LearnQuizChronicleEntry.State {
        switch detailLevel {
        case .hidden, .silhouette:
            return .silhouette
        case .inked:
            return .inked
        case .sealed:
            return .sealed
        case .rememberedAgain:
            return .rememberedAgain
        }
    }

    private static func art(for scene: ChronicleScene) -> LearnQuizArt {
        if scene.id.contains("shivneri") {
            return LearnQuizArt(assetSlot: "LearnQuizShivneriHero", symbol: "sunrise.fill", emphasis: .story)
        }
        if scene.id.contains("torna") || scene.id.contains("rajgad") {
            return LearnQuizArt(assetSlot: "LearnQuizTornaRajgadHero", symbol: "mountain.2.fill", emphasis: .place)
        }
        return LearnQuizArt(assetSlot: "LearnQuizPratapgadHero", symbol: "seal.fill", emphasis: .chronicle)
    }

    private static func fallbackQuizItem(for scene: ChronicleScene) -> QuizItem {
        QuizItem(
            id: "\(scene.id)-fallback-quiz",
            prompt: "What should we remember about \(scene.title)?",
            acceptedAnswers: [scene.memoryHook],
            answerChips: [scene.memoryHook],
            hintLadder: [RecallHint(level: 1, title: "Memory hook", body: scene.memoryHook)],
            successFeedback: "Yes. \(scene.memoryHook) is the memory hook.",
            recoveryFeedback: "Remember the hook: \(scene.memoryHook)."
        )
    }
}
