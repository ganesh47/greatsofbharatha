import Foundation

// Lightweight planning hooks for a later Apple Intelligence/App Intents pass.
// This file deliberately avoids unavailable Foundation Models symbols so the
// current iOS 18 target and local toolchains keep compiling.

enum GBChildSafeAIPlan {
    static let policy = GBChildSafeAIPolicy(
        answerMode: .curatedFactsOnly,
        privacyMode: .onDevicePreferred,
        allowedVoiceCommands: GBPlannedVoiceCommand.allCases
    )

    static func plannedHintRequest(for challenge: RecallChallenge) -> GBPlannedHintRequest {
        GBPlannedHintRequest(
            prompt: challenge.prompt,
            allowedFacts: challenge.correctAnswers + challenge.hintLadder.map(\.body),
            guardrail: "Give one simple hint for a child. Do not introduce new facts or open chat."
        )
    }
}

struct GBChildSafeAIPolicy: Equatable, Sendable {
    enum AnswerMode: String, Sendable {
        case curatedFactsOnly
    }

    enum PrivacyMode: String, Sendable {
        case onDevicePreferred
    }

    let answerMode: AnswerMode
    let privacyMode: PrivacyMode
    let allowedVoiceCommands: [GBPlannedVoiceCommand]
}

struct GBPlannedHintRequest: Equatable, Sendable {
    let prompt: String
    let allowedFacts: [String]
    let guardrail: String
}

enum GBPlannedVoiceCommand: String, CaseIterable, Sendable {
    case next
    case `repeat`
    case help
    case stop

    var childFacingPhrase: String {
        switch self {
        case .next:
            return "next"
        case .repeat:
            return "repeat"
        case .help:
            return "help"
        case .stop:
            return "stop"
        }
    }
}
