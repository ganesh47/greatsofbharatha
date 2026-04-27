import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBShadow.swift — Greats of Bharatha Design System
// Version: 1.0 · April 2026
// ─────────────────────────────────────────────────────────────

struct GBShadowModifier: ViewModifier {
    let style: GBShadowStyle
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.shadow(
            color: shadowColor,
            radius: style.radius(for: scheme),
            x: 0,
            y: style.yOffset(for: scheme)
        )
    }

    private var shadowColor: Color {
        switch style {
        case .card:     return Color.black.opacity(scheme == .dark ? 0.22 : 0.09)
        case .elevated: return Color.black.opacity(scheme == .dark ? 0.30 : 0.14)
        case .hero:     return Color.black.opacity(scheme == .dark ? 0.40 : 0.20)
        case .story:    return GBColor.Story.primary.opacity(scheme == .dark ? 0.35 : 0.28)
        case .place:    return GBColor.Place.primary.opacity(scheme == .dark ? 0.32 : 0.25)
        case .gold:     return GBColor.Chronicle.gold.opacity(scheme == .dark ? 0.35 : 0.28)
        }
    }
}

enum GBShadowStyle {
    case card       // Default card surface
    case elevated   // Raised panel / modal
    case hero       // Hero card
    case story      // Saffron-tinted glow
    case place      // Green-tinted glow
    case gold       // Gold-tinted glow (Chronicle)

    func radius(for scheme: ColorScheme) -> CGFloat {
        switch self {
        case .card:     return scheme == .dark ? 16 : 10
        case .elevated: return scheme == .dark ? 22 : 16
        case .hero:     return scheme == .dark ? 32 : 22
        case .story, .place, .gold: return scheme == .dark ? 28 : 18
        }
    }

    func yOffset(for scheme: ColorScheme) -> CGFloat {
        switch self {
        case .card:     return scheme == .dark ? 6 : 3
        case .elevated: return scheme == .dark ? 8 : 5
        case .hero:     return scheme == .dark ? 12 : 7
        case .story, .place, .gold: return scheme == .dark ? 10 : 6
        }
    }
}

extension View {
    func gbShadow(_ style: GBShadowStyle = .card) -> some View {
        self.modifier(GBShadowModifier(style: style))
    }
}
