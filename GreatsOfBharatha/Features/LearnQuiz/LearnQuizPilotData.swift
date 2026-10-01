import SwiftUI


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
    let reviewCards: [LearnQuizReviewCard]
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

struct LearnQuizReviewCard: Identifiable, Equatable {
    let id: String
    let sceneID: String
    let sceneTitle: String
    let promptType: RecallPromptType
    let front: String
    let back: String
    let meaning: String
    let cadenceDays: [Int]
    let art: LearnQuizArt

    var learningSeed: LearningReviewSeed {
        LearningReviewSeed(
            id: id,
            subjectID: sceneID,
            subjectType: .scene,
            promptTypes: [promptType],
            cadenceDays: cadenceDays
        )
    }
}

struct LearnQuizArt: Equatable {
    let assetSlot: String
    let symbol: String
    let emphasis: GBEmphasis
}

enum LearnQuizPilotData {
    private static let pilot = SampleContent.shivajiLearnQuizResetPilot

    static let canonicalSceneIDs: [String: String] = [
        "reset-scene-1-shivneri": "scene-1-shivneri",
        "reset-scene-2-torna-rajgad": "scene-2-torna-rajgad",
        "reset-scene-3-pratapgad": "scene-3-pratapgad-turning-point",
        "reset-scene-4-purandar-agra": "scene-4-purandar-agra",
        "reset-scene-5-rajgad-recovery": "scene-5-rajgad-recovery",
        "reset-scene-6-raigad-coronation": "scene-6-raigad-coronation",
    ]

    static func canonicalSceneID(for pilotID: String) -> String? { canonicalSceneIDs[pilotID] }


    static var scenes: [LearnQuizPilotScene] {
        pilot.scenes.enumerated().map { index, scene in
            makeScene(from: scene, number: index + 1)
        }
    }

    static var reviewCards: [LearnQuizReviewCard] {
        scenes.flatMap(\.reviewCards)
    }

    static var journeyEntry: LearnQuizChronicleEntry {
        LearnQuizChronicleEntry(
            id: pilot.endOfPilotReward.id,
            title: pilot.endOfPilotReward.title,
            subtitle: pilot.endOfPilotReward.subtitle,
            meaning: pilot.endOfPilotReward.meaning,
            state: .silhouette
        )
    }

    private static func makeScene(from scene: ChronicleScene, number: Int) -> LearnQuizPilotScene {
        let quizItem = scene.quizItems.first ?? fallbackQuizItem(for: scene)
        let art = art(for: scene)
        return LearnQuizPilotScene(
            id: canonicalSceneIDs[scene.id] ?? scene.id,
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
            matchPairs: scene.matchPairs.filter { $0.kind == .placeToHook }.map(makeMatchPair),
            chronicleEntry: makeChronicleEntry(from: scene),
            reviewCards: scene.reviewSeeds.map { makeReviewCard(from: $0, scene: scene, art: art) },
            art: art
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
            correctAnswer: item.answerChips.first(where: { chip in item.acceptedAnswers.contains(where: { LessonRecallEngine.normalized($0) == LessonRecallEngine.normalized(chip) }) }) ?? "",
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

    private static func makeReviewCard(from seed: ReviewSeed, scene: ChronicleScene, art: LearnQuizArt) -> LearnQuizReviewCard {
        LearnQuizReviewCard(
            id: seed.id,
            sceneID: canonicalSceneIDs[scene.id] ?? scene.id,
            sceneTitle: scene.title,
            promptType: seed.promptType,
            front: seed.front,
            back: seed.back,
            meaning: seed.meaning,
            cadenceDays: [seed.rescuedCadenceDays, seed.correctNoHintCadenceDays, 3, 7, 14],
            art: art
        )
    }

    private static func makeChronicleEntry(from scene: ChronicleScene) -> LearnQuizChronicleEntry {
        let canonicalID = canonicalSceneIDs[scene.id] ?? scene.id
        let rewardID = SampleContent.shivajiVerticalSlice.scenes.first(where: { $0.id == canonicalID })?.rewardID ?? scene.chronicleReward.id
        return LearnQuizChronicleEntry(id: rewardID, title: scene.chronicleReward.title,
            subtitle: scene.chronicleReward.subtitle, meaning: scene.chronicleReward.meaning, state: .silhouette)
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
        if let canonicalID = canonicalSceneIDs[scene.id],
           let canonical = SampleContent.shivajiVerticalSlice.scenes.first(where: { $0.id == canonicalID }) {
            let plan = SampleContent.learningPlan(for: canonical)
            return LearnQuizArt(assetSlot: plan.imageAsset ?? "Chapter1ShivneriStory", symbol: plan.artSymbol, emphasis: .story)
        }
        return LearnQuizArt(assetSlot: "Chapter1ShivneriStory", symbol: "book.fill", emphasis: .story)
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
