import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBSpacing.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
// ─────────────────────────────────────────────────────────────

enum GBSpacing {
    static let xxxSmall: CGFloat = 4
    static let xxSmall:  CGFloat = 8
    static let xSmall:   CGFloat = 12
    static let small:    CGFloat = 16
    static let medium:   CGFloat = 20
    static let large:    CGFloat = 24
    static let xLarge:   CGFloat = 32
    static let xxLarge:  CGFloat = 40
    static let xxxLarge: CGFloat = 56

    /// Card internal padding
    static let cardPad:    CGFloat = 20
    static let cardPadLg:  CGFloat = 24
    /// Gap between cards in a scroll list
    static let cardGap:    CGFloat = 12
    /// Section spacing
    static let sectionGap: CGFloat = 28
}

// ── GBTouch — minimum tap target sizes (child-safe, ages 8–11) ──

enum GBTouch {
    /// Primary child-facing interactions (map pins, large cards): 80pt
    static let primary:  CGFloat = 80
    /// Primary CTA button height: 56pt
    static let button:   CGFloat = 56
    /// Secondary controls, back buttons: 44pt
    static let control:  CGFloat = 44
    /// Tab bar tap area: 48pt
    static let tab:      CGFloat = 48
    /// Map pin tap zone (generous): 48pt
    static let mapPin:   CGFloat = 48
}
