import Foundation

/// Source classification stays with the fact when it moves between teaching and practice.
enum ChapterKnowledgeClaimKind: String, Codable, Sendable {
    case historical, siteFeature, vocabulary, derivedReasoning, tradition, reflection

    var allowsFactualAssessment: Bool {
        self != .tradition && self != .reflection
    }
}

enum ChapterKnowledgeReviewStatus: String, Codable, Sendable {
    case pendingIndependentReview, approved, held
}

struct ChapterKnowledgeCitation: Codable, Equatable, Sendable {
    let sourceID: String
    let locator: String
}

struct ChapterKnowledgeClaim: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let kind: ChapterKnowledgeClaimKind
    let statement: String
    let citations: [ChapterKnowledgeCitation]
    let taughtBeatIDs: [String]
    let reviewStatus: ChapterKnowledgeReviewStatus

    var allowsFactualAssessment: Bool {
        reviewStatus == .approved && kind.allowsFactualAssessment
    }
}

/// The three original IDs remain in the catalog even when additional short beats are added.
struct ChapterKnowledgeBeat: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let text: String
    let claimIDs: [String]
}

enum ChapterKnowledgeQuestionKind: String, Codable, Sendable {
    case identity, geography, sequence, meaning, application, material
    case numericCount, numericDate, numericYearLabelGap
}

struct ChapterKnowledgeChoice: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let text: String
}

struct ChapterKnowledgeQuestion: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let kind: ChapterKnowledgeQuestionKind
    let prompt: String
    let choices: [ChapterKnowledgeChoice]
    let correctChoiceID: String
    let claimIDs: [String]
    let requiredBeatIDs: [String]
    let explanation: String
    let hints: [String]
    let retryFeedback: String
}

struct ChapterKnowledgeDefinition: Codable, Equatable, Sendable {
    let sceneID: String
    let claims: [ChapterKnowledgeClaim]
    let beats: [ChapterKnowledgeBeat]
    let questions: [ChapterKnowledgeQuestion]

    /// A catalog check is separate from historical review and learner evidence.
    var validationIssues: [String] {
        var issues: [String] = []
        checkUniqueIDs(claims.map(\.id), label: "claim", issues: &issues)
        checkUniqueIDs(beats.map(\.id), label: "beat", issues: &issues)
        checkUniqueIDs(questions.map(\.id), label: "question", issues: &issues)
        let claimIDs = Set(claims.map(\.id))
        let beatIDs = Set(beats.map(\.id))
        for role in LegacyChapterStoryRole.allCases where !beatIDs.contains(role.beatID(sceneID: sceneID)) {
            issues.append("Missing legacy beat: \(role.beatID(sceneID: sceneID))")
        }
        for claim in claims {
            if claim.statement.isEmpty || claim.citations.isEmpty || claim.taughtBeatIDs.isEmpty {
                issues.append("Incomplete claim: \(claim.id)")
            }
            if claim.citations.contains(where: { $0.sourceID.isEmpty || $0.locator.isEmpty }) {
                issues.append("Incomplete citation: \(claim.id)")
            }
            for beatID in claim.taughtBeatIDs where !beats.contains(where: { $0.id == beatID && $0.claimIDs.contains(claim.id) }) {
                issues.append("Claim not taught by declared beat: \(claim.id), \(beatID)")
            }
        }
        for beat in beats {
            if beat.title.isEmpty || beat.text.isEmpty { issues.append("Empty teaching beat: \(beat.id)") }
            if !Set(beat.claimIDs).isSubset(of: claimIDs) { issues.append("Unknown beat claim: \(beat.id)") }
        }
        for question in questions {
            checkUniqueIDs(question.choices.map(\.id), label: question.id + " choice", issues: &issues)
            if question.choices.count < 2 || !question.choices.contains(where: { $0.id == question.correctChoiceID }) {
                issues.append("Invalid correct choice: \(question.id)")
            }
            if question.prompt.isEmpty || question.explanation.isEmpty || question.retryFeedback.isEmpty ||
                question.hints.isEmpty || question.hints.contains(where: \.isEmpty) ||
                question.choices.contains(where: { $0.text.isEmpty }) {
                issues.append("Incomplete question copy: \(question.id)")
            }
            if question.claimIDs.isEmpty || !Set(question.claimIDs).isSubset(of: claimIDs) {
                issues.append("Unknown or missing question claim: \(question.id)")
            }
            let taughtIDs = Set(claims.filter { question.claimIDs.contains($0.id) }.flatMap(\.taughtBeatIDs))
            if taughtIDs.isEmpty || Set(question.requiredBeatIDs) != taughtIDs || !taughtIDs.isSubset(of: beatIDs) {
                issues.append("Question teaching coverage mismatch: \(question.id)")
            }
        }
        return issues
    }

    /// Legacy completion never implies that newly added facts have been shown.
    /// Callers supply only durably saved beat and claim IDs after presentation.
    /// An old receipt for an enriched legacy beat does not prove the new claims were taught.
    func questionsEligible(afterShownBeatIDs shownBeatIDs: Set<String>,
                           taughtClaimIDs: Set<String>) -> [ChapterKnowledgeQuestion] {
        guard validationIssues.isEmpty else { return [] }
        let claimsByID = Dictionary(uniqueKeysWithValues: claims.map { ($0.id, $0) })
        return questions.filter { question in
            Set(question.requiredBeatIDs).isSubset(of: shownBeatIDs) &&
                Set(question.claimIDs).isSubset(of: taughtClaimIDs) &&
                question.claimIDs.allSatisfy { claimsByID[$0]?.allowsFactualAssessment == true }
        }
    }

    private func checkUniqueIDs(_ ids: [String], label: String, issues: inout [String]) {
        if ids.contains(where: \.isEmpty) || Set(ids).count != ids.count {
            issues.append("Empty or duplicate \(label) IDs")
        }
    }
}

/// This order is a frozen migration map, independent of any future expanded catalog order.
enum LegacyChapterStoryRole: String, CaseIterable, Codable, Sendable {
    case story, memory, meaning

    func beatID(sceneID: String) -> String { sceneID + "-" + rawValue }
}

enum ChapterStoryBeatResolutionReason: String, Equatable, Sendable {
    case stableID, legacyIndex, clampedLegacyIndex, retiredStableID, unavailable
}

struct ChapterStoryBeatResolution: Equatable, Sendable {
    let beatID: String?
    let reason: ChapterStoryBeatResolutionReason
}

enum ChapterStoryBeatMigration {
    static func resolve(sceneID: String, persistedBeatID: String?, legacyIndex: Int,
                        availableBeatIDs: [String]) -> ChapterStoryBeatResolution {
        let available = Set(availableBeatIDs)
        if let persistedBeatID {
            if available.contains(persistedBeatID) {
                return ChapterStoryBeatResolution(beatID: persistedBeatID, reason: .stableID)
            }
            // A retired stable ID resumes at a documented teaching fallback; its saved receipt
            // is retained by the store. It is never reinterpreted as an expanded numeric index.
            let openingID = LegacyChapterStoryRole.story.beatID(sceneID: sceneID)
            return ChapterStoryBeatResolution(beatID: available.contains(openingID) ? openingID : nil,
                                              reason: available.contains(openingID) ? .retiredStableID : .unavailable)
        }
        let legacyRoles: [LegacyChapterStoryRole] = [.story, .memory, .meaning]
        let boundedIndex = min(max(legacyIndex, 0), legacyRoles.count - 1)
        let beatID = legacyRoles[boundedIndex].beatID(sceneID: sceneID)
        guard available.contains(beatID) else {
            return ChapterStoryBeatResolution(beatID: nil, reason: .unavailable)
        }
        return ChapterStoryBeatResolution(beatID: beatID,
                                          reason: boundedIndex == legacyIndex ? .legacyIndex : .clampedLegacyIndex)
    }
}
