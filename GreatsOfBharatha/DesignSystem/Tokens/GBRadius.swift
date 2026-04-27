import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBRadius.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
// ─────────────────────────────────────────────────────────────

enum GBRadius {
    /// Tight controls, small chips, inline badges: 10pt
    static let compact:  CGFloat = 10
    /// Standard controls, secondary cards: 16pt
    static let control:  CGFloat = 16
    /// Primary card surface (GBSurface default): 20pt
    static let card:     CGFloat = 20
    /// Hero cards, large surfaces: 28pt
    static let hero:     CGFloat = 28
    /// Capsule pill (badges, step pills): 9999pt
    static let pill:     CGFloat = 9999

    /// Backwards-compat alias (v1 used `badge` for chip radii)
    static let badge: CGFloat = compact

    static func forCard(isHero: Bool) -> CGFloat {
        isHero ? hero : card
    }
}
