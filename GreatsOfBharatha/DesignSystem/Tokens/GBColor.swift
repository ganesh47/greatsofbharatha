import SwiftUI
import UIKit

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

    private struct RGBA {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        init(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.opacity = opacity
        }
    }

    private static func adaptive(light: RGBA, dark: RGBA) -> Color {
        Color(UIColor { traits in
            let values = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: values.red,
                green: values.green,
                blue: values.blue,
                alpha: values.opacity
            )
        })
    }

    // ── Surfaces ──────────────────────────────────────────────
    enum Background {
        /// Warm parchment — primary app background
        static let app = GBColor.adaptive(
            light: .init(0.961, 0.929, 0.847, 1), // #F5EDD8
            dark: .init(0.071, 0.051, 0.043, 1)   // #120D0B
        )
        /// Card face
        static let surface = GBColor.adaptive(
            light: .init(0.992, 0.980, 0.949, 1), // #FDFAF2
            dark: .init(0.129, 0.094, 0.078, 1)   // #211814
        )
        /// Warm card tint (panels, insets)
        static let elevated = GBColor.adaptive(
            light: .init(0.941, 0.902, 0.784, 1), // #F0E6C8
            dark: .init(0.180, 0.129, 0.098, 1)   // #2E2119
        )
        /// Panel / divider surface
        static let panel = GBColor.adaptive(
            light: .init(0.918, 0.851, 0.690, 1), // #EAD9B0
            dark: .init(0.259, 0.196, 0.145, 1)   // #423225
        )
        /// Deep panel border / stroke
        static let panelDeep = GBColor.adaptive(
            light: .init(0.784, 0.667, 0.471, 1), // #C8AA78
            dark: .init(0.522, 0.416, 0.286, 1)   // #856A49
        )

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
        static let primary = GBColor.adaptive(
            light: .init(0.110, 0.078, 0.063, 1.00), // #1C1410
            dark: .init(0.980, 0.941, 0.851, 1.00)  // warm parchment text
        )
        static let secondary = GBColor.adaptive(
            light: .init(0.110, 0.078, 0.063, 0.72),
            dark: .init(0.980, 0.941, 0.851, 0.78)
        )
        static let tertiary = GBColor.adaptive(
            light: .init(0.110, 0.078, 0.063, 0.68),
            dark: .init(0.980, 0.941, 0.851, 0.74)
        )
        static let inverse = Color.white
    }

    // ── Story: Saffron family ─────────────────────────────────
    enum Story {
        static let primary = GBColor.adaptive(
            light: .init(0.851, 0.310, 0.047, 1), // #D94F0C
            dark: .init(0.992, 0.722, 0.490, 1)   // #FDB87D
        )
        static let mid = GBColor.adaptive(
            light: .init(0.941, 0.416, 0.165, 1), // #F06A2A
            dark: .init(0.992, 0.820, 0.640, 1)
        )
        static let light = Color(red: 0.992, green: 0.722, blue: 0.490)          // #FDB87D
        static let bg = GBColor.adaptive(
            light: .init(0.996, 0.941, 0.894, 1), // #FEF0E4
            dark: .init(0.243, 0.094, 0.047, 1)   // deep saffron wash
        )
    }

    // ── Place: Sahyadri family ────────────────────────────────
    enum Place {
        static let primary = GBColor.adaptive(
            light: .init(0.122, 0.361, 0.227, 1), // #1F5C3A
            dark: .init(0.353, 0.671, 0.471, 1)   // #5AAB78
        )
        static let mid = GBColor.adaptive(
            light: .init(0.180, 0.490, 0.322, 1), // #2E7D52
            dark: .init(0.565, 0.820, 0.635, 1)
        )
        static let light = Color(red: 0.353, green: 0.671, blue: 0.471)          // #5AAB78
        static let sky     = Color(red: 0.169, green: 0.357, blue: 0.667)        // #2B5BAA
        static let bg = GBColor.adaptive(
            light: .init(0.910, 0.957, 0.929, 1), // #E8F4ED
            dark: .init(0.063, 0.188, 0.118, 1)   // deep green wash
        )
    }

    // ── Chronicle: Gold + Royal ───────────────────────────────
    enum Chronicle {
        static let gold = GBColor.adaptive(
            light: .init(0.722, 0.490, 0.047, 1), // #B87D0C
            dark: .init(0.961, 0.816, 0.376, 1)   // #F5D060
        )
        static let goldMid = GBColor.adaptive(
            light: .init(0.831, 0.627, 0.090, 1), // #D4A017
            dark: .init(0.980, 0.875, 0.518, 1)
        )
        static let goldLight = Color(red: 0.961, green: 0.816, blue: 0.376)      // #F5D060
        static let goldBg = GBColor.adaptive(
            light: .init(0.992, 0.957, 0.847, 1), // #FDF4D8
            dark: .init(0.235, 0.161, 0.047, 1)   // deep gold wash
        )
        static let royal = GBColor.adaptive(
            light: .init(0.239, 0.141, 0.459, 1), // #3D2475
            dark: .init(0.714, 0.616, 0.941, 1)
        )
        static let royalMid = GBColor.adaptive(
            light: .init(0.361, 0.227, 0.624, 1), // #5C3A9F
            dark: .init(0.800, 0.725, 0.973, 1)
        )
        static let royalBg = GBColor.adaptive(
            light: .init(0.929, 0.910, 0.973, 1), // #EDE8F8
            dark: .init(0.129, 0.078, 0.247, 1)   // deep royal wash
        )
    }

    // ── States ────────────────────────────────────────────────
    enum State {
        static let locked = GBColor.adaptive(
            light: .init(0.420, 0.365, 0.310, 1),
            dark: .init(0.735, 0.671, 0.600, 1)
        )
        static let lockedBg = GBColor.adaptive(
            light: .init(0.929, 0.898, 0.847, 1), // #EDE5D8
            dark: .init(0.169, 0.145, 0.122, 1)
        )
        static let success = Place.primary
        static let warning = Chronicle.goldMid
        static let danger = GBColor.adaptive(
            light: .init(0.753, 0.224, 0.169, 1), // #C0392B
            dark: .init(0.980, 0.420, 0.360, 1)
        )
    }

    // ── Form controls ─────────────────────────────────────────
    enum Input {
        static let background = Background.surface
        static let text = Content.primary
        static let placeholder = Content.tertiary
        static let border = Border.panel
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
        case .story: return Story.primary
        case .place: return Place.primary
        case .chronicle: return Chronicle.gold
        case .neutral: return Content.secondary
        }
    }
}
