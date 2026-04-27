import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBColor.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
//
// Palette: "Manuscript and Saffron"
// Surfaces: warm parchment → rich ink
// Story:    saffron family   (lesson / narrative)
// Place:    sahyadri green   (forts / map)
// Chronicle: gold + royal    (reward / mastery)
// ─────────────────────────────────────────────────────────────

enum GBEmphasis: CaseIterable {
    case story
    case place
    case chronicle
    case neutral
}

enum GBColor {

    // ── Surfaces ──────────────────────────────────────────────
    enum Background {
        /// Warm parchment — primary app background
        static let app      = Color(red: 0.961, green: 0.929, blue: 0.847)  // #F5EDD8
        /// Near-white card face
        static let surface  = Color(red: 0.992, green: 0.980, blue: 0.949)  // #FDFAF2
        /// Warm card tint (panels, insets)
        static let elevated = Color(red: 0.941, green: 0.902, blue: 0.784)  // #F0E6C8
        /// Panel / divider surface
        static let panel    = Color(red: 0.918, green: 0.851, blue: 0.690)  // #EAD9B0
        /// Deep panel border / stroke
        static let panelDeep = Color(red: 0.784, green: 0.667, blue: 0.471) // #C8AA78

        // Story gradient endpoints (saffron → amber)
        static let storyStart = Color(red: 0.851, green: 0.310, blue: 0.047)  // #D94F0C
        static let storyEnd   = Color(red: 0.961, green: 0.651, blue: 0.137)  // #F5A623

        // Place gradient endpoints (sahyadri → sky)
        static let placeStart = Color(red: 0.122, green: 0.361, blue: 0.227)  // #1F5C3A
        static let placeEnd   = Color(red: 0.169, green: 0.357, blue: 0.667)  // #2B5BAA

        // Chronicle gradient endpoints (royal → gold)
        static let chronicleStart = Color(red: 0.239, green: 0.141, blue: 0.459) // #3D2475
        static let chronicleEnd   = Color(red: 0.722, green: 0.490, blue: 0.047) // #B87D0C

        // Backwards-compat aliases (v1 names)
        static let heroWarmStart = storyStart
        static let heroWarmEnd   = storyEnd
        static let heroCoolStart = placeStart
        static let heroCoolEnd   = placeEnd
    }

    // ── Text ──────────────────────────────────────────────────
    enum Content {
        static let primary   = Color(red: 0.110, green: 0.078, blue: 0.063)      // #1C1410
        static let secondary = Color(red: 0.110, green: 0.078, blue: 0.063).opacity(0.65)
        static let tertiary  = Color(red: 0.110, green: 0.078, blue: 0.063).opacity(0.40)
        static let inverse   = Color.white
    }

    // ── Story: Saffron family ─────────────────────────────────
    enum Story {
        static let primary = Color(red: 0.851, green: 0.310, blue: 0.047)        // #D94F0C
        static let mid     = Color(red: 0.941, green: 0.416, blue: 0.165)        // #F06A2A
        static let light   = Color(red: 0.992, green: 0.722, blue: 0.490)        // #FDB87D
        static let bg      = Color(red: 0.996, green: 0.941, blue: 0.894)        // #FEF0E4
    }

    // ── Place: Sahyadri family ────────────────────────────────
    enum Place {
        static let primary = Color(red: 0.122, green: 0.361, blue: 0.227)        // #1F5C3A
        static let mid     = Color(red: 0.180, green: 0.490, blue: 0.322)        // #2E7D52
        static let light   = Color(red: 0.353, green: 0.671, blue: 0.471)        // #5AAB78
        static let sky     = Color(red: 0.169, green: 0.357, blue: 0.667)        // #2B5BAA
        static let bg      = Color(red: 0.910, green: 0.957, blue: 0.929)        // #E8F4ED
    }

    // ── Chronicle: Gold + Royal ───────────────────────────────
    enum Chronicle {
        static let gold      = Color(red: 0.722, green: 0.490, blue: 0.047)      // #B87D0C
        static let goldMid   = Color(red: 0.831, green: 0.627, blue: 0.090)      // #D4A017
        static let goldLight = Color(red: 0.961, green: 0.816, blue: 0.376)      // #F5D060
        static let goldBg    = Color(red: 0.992, green: 0.957, blue: 0.847)      // #FDF4D8
        static let royal     = Color(red: 0.239, green: 0.141, blue: 0.459)      // #3D2475
        static let royalMid  = Color(red: 0.361, green: 0.227, blue: 0.624)      // #5C3A9F
        static let royalBg   = Color(red: 0.929, green: 0.910, blue: 0.973)      // #EDE8F8
    }

    // ── States ────────────────────────────────────────────────
    enum State {
        static let locked   = Color(red: 0.627, green: 0.565, blue: 0.502)       // #A09080
        static let lockedBg = Color(red: 0.929, green: 0.898, blue: 0.847)       // #EDE5D8
        static let success  = Place.primary
        static let warning  = Chronicle.goldMid
        static let danger   = Color(red: 0.753, green: 0.224, blue: 0.169)       // #C0392B
    }

    // ── Borders ───────────────────────────────────────────────
    enum Border {
        static let `default` = Content.primary.opacity(0.08)
        static let emphasis  = Content.primary.opacity(0.16)
        static let panel     = Background.panelDeep.opacity(0.35)
    }

    // ── Backwards-compat Accent namespace (v1) ────────────────
    // Existing call sites use GBColor.Accent.story / .place / .chronicle / .success
    enum Accent {
        static let story     = Story.primary
        static let place     = Place.primary
        static let chronicle = Chronicle.gold
        static let success   = Place.primary
    }

    // ── Gradient factory ──────────────────────────────────────
    static func gradient(for emphasis: GBEmphasis) -> LinearGradient {
        switch emphasis {
        case .story:
            return LinearGradient(
                colors: [Background.storyStart, Background.storyEnd],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .place:
            return LinearGradient(
                colors: [Background.placeStart, Background.placeEnd],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .chronicle:
            return LinearGradient(
                colors: [Background.chronicleStart, Background.chronicleEnd],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neutral:
            return LinearGradient(
                colors: [Background.surface, Background.elevated],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    static func accent(for emphasis: GBEmphasis) -> Color {
        switch emphasis {
        case .story:      return Story.primary
        case .place:      return Place.primary
        case .chronicle:  return Chronicle.gold
        case .neutral:    return Content.secondary
        }
    }
}
