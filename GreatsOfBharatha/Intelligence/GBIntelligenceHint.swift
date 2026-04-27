import Foundation

// ─────────────────────────────────────────────────────────────
// GBIntelligenceHint.swift — Greats of Bharatha
// On-device hint generation using the Foundation Models framework
// (introduced in iOS 26 / Xcode 26 as part of Apple Intelligence).
//
// Falls back gracefully to the static hint ladder on:
//   - iOS < 26 devices
//   - Devices without Apple Intelligence (older hardware)
//   - Any runtime error from the model
//
// No data leaves the device — LanguageModelSession is fully local.
// ─────────────────────────────────────────────────────────────

@MainActor
enum GBIntelligenceHint {

    /// Returns a child-friendly hint string.
    /// Prefers an AI-generated hint on iOS 26+ with Apple Intelligence;
    /// always falls back to `staticFallback` on failure or older OS.
    static func hint(
        fortName: String,
        question: String,
        staticFallback: String
    ) async -> String {
        guard #available(iOS 26.0, *) else { return staticFallback }
        return await aiGeneratedHint(fortName: fortName, question: question)
            ?? staticFallback
    }

    // ── iOS 26+ path ──────────────────────────────────────────

    @available(iOS 26.0, *)
    private static func aiGeneratedHint(fortName: String, question: String) async -> String? {
        // Import guard: canImport check prevents compile errors on SDKs < iOS 26
        #if canImport(FoundationModels)
        do {
            let session = LanguageModelSession()
            let prompt = """
            A 5-year-old is learning about \(fortName) in Indian history.
            Give ONE playful sentence that helps them answer: "\(question)"
            Rules: use very simple words, do NOT give the answer away, end with "!".
            Maximum 20 words.
            """
            let response = try await session.respond(to: prompt)
            let trimmed = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}

#if canImport(FoundationModels)
import FoundationModels
#endif
