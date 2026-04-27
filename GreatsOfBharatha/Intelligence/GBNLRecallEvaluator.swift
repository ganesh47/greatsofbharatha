import Foundation
import NaturalLanguage

// ─────────────────────────────────────────────────────────────
// GBNLRecallEvaluator.swift — Greats of Bharatha
// Semantic recall matching via NaturalLanguage (on-device, iOS 13+).
// Accepts answers that are close in meaning to the correct answer,
// e.g. "Shivneri", "birth fort", "where he was born" for
// "Where was Shivaji Maharaj born?" → answer: "Shivneri Fort".
// No cloud calls — NLEmbedding is fully local.
// ─────────────────────────────────────────────────────────────

enum GBNLRecallEvaluator {

    // Threshold: distance ≤ this value = semantically close enough.
    // NLEmbedding distances are cosine; 0.4 is permissive enough for
    // synonyms and partial matches while rejecting random guesses.
    private static let similarityThreshold: Double = 0.40

    /// Returns `true` if `answer` is semantically close enough to any
    /// of the `correctAnswers`. Falls back to the existing exact-match
    /// logic when the embedding is unavailable.
    static func matches(
        answer: String,
        correctAnswers: [String]
    ) -> Bool {
        let normalizedAnswer = normalize(answer)
        guard !normalizedAnswer.isEmpty else { return false }

        // Fast path: exact or prefix match (no embedding needed)
        for correct in correctAnswers {
            let normalizedCorrect = normalize(correct)
            if normalizedAnswer == normalizedCorrect { return true }
            if normalizedCorrect.hasPrefix(normalizedAnswer) || normalizedAnswer.hasPrefix(normalizedCorrect) {
                return true
            }
        }

        // Semantic path: token-level embedding similarity
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            return false
        }

        let answerTokens = tokens(normalizedAnswer)
        for correct in correctAnswers {
            let correctTokens = tokens(normalize(correct))
            if hasSemanticOverlap(answerTokens, correctTokens, embedding: embedding) {
                return true
            }
        }
        return false
    }

    // ── Helpers ───────────────────────────────────────────────

    private static func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: " fort", with: "")
            .replacingOccurrences(of: " maharaj", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func tokens(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var result: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            result.append(String(text[range]))
            return true
        }
        return result.filter { $0.count > 2 }  // drop short stop-words
    }

    private static func hasSemanticOverlap(
        _ aTokens: [String],
        _ bTokens: [String],
        embedding: NLEmbedding
    ) -> Bool {
        for aToken in aTokens {
            for bToken in bTokens {
                let distance = embedding.distance(between: aToken, and: bToken)
                if distance <= similarityThreshold { return true }
            }
        }
        return false
    }
}
