import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBIcon.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
//
// Icon policy:
//   SF Symbols first — navigation, shell, system actions.
//   Supplementary open-source icons only for domain-specific
//   surfaces (fort markers, chronicle emblems, historical motifs).
//
// Supplementary source: Phosphor Icons (MIT)
//   phosphoricons.com — import only approved icons, not whole pack.
//   See: GreatsOfBharatha/Resources/Iconography/attribution.md
// ─────────────────────────────────────────────────────────────

enum GBIcon {
    // ── Navigation (SF Symbols) ───────────────────────────────
    static let learn      = "book.fill"
    static let places     = "map.fill"
    static let chronicle  = "scroll.fill"
    static let back       = "chevron.left"
    static let next       = "chevron.right"
    static let home       = "house.fill"

    // ── Story / Lesson (SF Symbols) ───────────────────────────
    static let story      = "text.book.closed.fill"
    static let scene      = "play.fill"
    static let narration  = "speaker.wave.2.fill"
    static let narrationOff = "speaker.slash.fill"
    static let hint       = "lightbulb.fill"

    // ── Places / Forts (SF Symbols) ───────────────────────────
    static let place      = "mappin.circle.fill"
    static let fort       = "building.columns.fill"
    static let mapPin     = "mappin.fill"
    static let pinCorrect = "checkmark.circle.fill"
    static let pinClose   = "circle.dashed"
    static let compass    = "location.north.circle.fill"

    // ── Chronicle / Rewards (SF Symbols) ─────────────────────
    static let chronicleIcon = "crown.fill"
    static let reward     = "star.fill"
    static let lock       = "lock.fill"
    static let unlock     = "lock.open.fill"
    static let mastery    = "seal.fill"

    // ── Timeline (SF Symbols) ─────────────────────────────────
    static let timeline   = "timeline.selection"
    static let marker     = "circle.fill"
    static let markerDone = "checkmark.circle.fill"

    // ── System (SF Symbols) ───────────────────────────────────
    static let close      = "xmark.circle.fill"
    static let audio      = "speaker.wave.2.fill"
    static let audioOff   = "speaker.slash.fill"
    static let replay     = "arrow.counterclockwise.circle.fill"

    // ── Backwards-compat aliases (v1 names) ───────────────────
    static let locked     = lock           // v1: "lock.fill"
    static let success    = "checkmark.seal.fill"
    static let region     = "location.north.line.fill"

    // ── Fort-specific emblems ─────────────────────────────────
    enum Fort {
        static let shivneri   = "building.columns"
        static let torna      = "mountain.2.fill"
        static let rajgad     = "flag.fill"
        static let pratapgad  = "bolt.fill"
        static let raigad     = "crown.fill"
        static let purandar   = "shield.fill"
        static let generic    = "mappin.and.ellipse"
    }
}

// ── Icon size presets ─────────────────────────────────────────
extension Image {
    func gbNavIcon() -> some View {
        self.font(.system(size: 22, weight: .bold))
    }
    func gbTabIcon() -> some View {
        self.font(.system(size: 22, weight: .regular))
    }
    func gbCardIcon() -> some View {
        self.font(.system(size: 20, weight: .semibold))
    }
    func gbStatusIcon() -> some View {
        self.font(.system(size: 14, weight: .bold))
    }
}
