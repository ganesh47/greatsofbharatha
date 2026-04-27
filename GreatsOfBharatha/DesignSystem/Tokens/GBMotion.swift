import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBMotion.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
//
// Motion philosophy:
//   Spring-based for interactions, ease-out for transitions.
//   Ceremony animation is reserved for Chronicle reveals only.
//   Reduced Motion: all content remains accessible, only
//   decorative motion (parallax, scale-in) is suppressed.
// ─────────────────────────────────────────────────────────────

enum GBMotion {
    /// Button press, tap feedback — 0.18s ease-out
    static let quick      = Animation.easeOut(duration: 0.18)

    /// Screen transitions, step changes — 0.28s ease-in-out
    static let standard   = Animation.easeInOut(duration: 0.28)

    /// Pin snap, card reveal, map zoom — spring
    static let spring     = Animation.spring(response: 0.40, dampingFraction: 0.82)

    /// Bouncy feedback (correct answer) — spring, bouncier
    static let bounce     = Animation.spring(response: 0.36, dampingFraction: 0.58)

    /// Chronicle reward reveal — slow spring, used once per scene
    static let ceremony   = Animation.spring(response: 0.55, dampingFraction: 0.72)

    /// Progress bar fill — ease-in-out, 0.4s
    static let progress   = Animation.easeInOut(duration: 0.40)

    /// Backwards-compat alias (v1 name)
    static let emphasized = spring
}

// ── Reduced Motion support ────────────────────────────────────
extension Animation {
    /// Use @Environment(\.accessibilityReduceMotion) in Views instead.
    static func gbMotion(_ animation: Animation) -> Animation { animation }
}

// ── Haptic token system ───────────────────────────────────────
#if canImport(UIKit)
import UIKit

enum GBHaptic {
    /// Fort pin confirmed — strong satisfaction
    static func pinCorrect() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Fort pin near but not exact — soft cue
    static func pinClose() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// Timeline marker locked in — rigid click
    static func timelineLocked() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }

    /// Chronicle card reveal — success notification (ceremony)
    static func chronicleReveal() {
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Coronation / arc completion — heavy × 2 (used once per arc)
    static func coronation() {
        Task { @MainActor in
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
            try? await Task.sleep(nanoseconds: 180_000_000)
            gen.impactOccurred()
        }
    }

    /// Scene step advance — selection click
    static func stepAdvance() {
        Task { @MainActor in
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // Wrong answer: intentionally NO haptic — no shame signal.
}
#endif
