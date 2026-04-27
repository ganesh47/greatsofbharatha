import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBButtonStyle.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
// ─────────────────────────────────────────────────────────────

// ── Primary button (gradient) ─────────────────────────────────
struct GBPrimaryButtonStyle: ButtonStyle {
    var emphasis: GBEmphasis = .story

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GBFont.ui(size: 17, weight: .heavy))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: GBTouch.button)
            .background(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .fill(AnyShapeStyle(GBColor.gradient(for: emphasis)))
            )
            .gbShadow(shadowStyle)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(GBMotion.quick, value: configuration.isPressed)
    }

    private var shadowStyle: GBShadowStyle {
        switch emphasis {
        case .story:     return .story
        case .place:     return .place
        case .chronicle: return .gold
        case .neutral:   return .card
        }
    }
}

// ── Secondary button ──────────────────────────────────────────
struct GBSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GBFont.ui(size: 15, weight: .bold))
            .foregroundStyle(GBColor.Content.primary)
            .frame(maxWidth: .infinity, minHeight: GBTouch.control)
            .background(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .fill(GBColor.Background.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                            .stroke(GBColor.Background.panelDeep, lineWidth: 1.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(GBMotion.quick, value: configuration.isPressed)
    }
}

// ── Ghost / text button ───────────────────────────────────────
struct GBGhostButtonStyle: ButtonStyle {
    var color: Color = GBColor.Story.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GBFont.ui(size: 15, weight: .bold))
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.65 : 1.0)
            .animation(GBMotion.quick, value: configuration.isPressed)
    }
}

// ── Convenience extensions ────────────────────────────────────
extension ButtonStyle where Self == GBPrimaryButtonStyle {
    static var gbPrimary: GBPrimaryButtonStyle { .init() }
    static func gbPrimary(emphasis: GBEmphasis) -> GBPrimaryButtonStyle { .init(emphasis: emphasis) }
    /// Backwards-compat positional form: .buttonStyle(.gbPrimary(.story))
    static func gbPrimary(_ emphasis: GBEmphasis) -> GBPrimaryButtonStyle { .init(emphasis: emphasis) }
}

extension ButtonStyle where Self == GBSecondaryButtonStyle {
    static var gbSecondary: GBSecondaryButtonStyle { .init() }
}

extension ButtonStyle where Self == GBGhostButtonStyle {
    static var gbGhost: GBGhostButtonStyle { .init() }
    static func gbGhost(color: Color) -> GBGhostButtonStyle { .init(color: color) }
}

// ─────────────────────────────────────────────────────────────
// GBQuestProgressView — three-pillar score counter widget
// (distinct from GBQuestProgress step navigator)
// ─────────────────────────────────────────────────────────────

struct GBQuestProgressView: View {
    let storyCount:      Int
    let storyTotal:      Int
    let placeCount:      Int
    let placeTotal:      Int
    let chronicleCount:  Int
    let chronicleTotal:  Int

    @Environment(\.gbLayoutContext) private var layout

    private struct Pillar {
        let label: String
        let value: Int
        let total: Int
        let color: Color
    }

    private var pillars: [Pillar] {[
        .init(label: "Story",     value: storyCount,     total: storyTotal,     color: GBColor.Story.primary),
        .init(label: "Place",     value: placeCount,     total: placeTotal,     color: GBColor.Place.primary),
        .init(label: "Chronicle", value: chronicleCount, total: chronicleTotal, color: GBColor.Chronicle.gold),
    ]}

    var body: some View {
        HStack(spacing: GBSpacing.xxSmall) {
            ForEach(pillars, id: \.label) { pillar in
                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    Text(pillar.label)
                        .font(GBFont.ui(size: 10, weight: .heavy))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(GBColor.Content.tertiary)

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(pillar.value)")
                            .font(GBFont.ui(size: 18, weight: .black))
                            .foregroundStyle(pillar.value > 0 ? pillar.color : GBColor.State.locked)
                        Text("/\(pillar.total)")
                            .font(GBFont.ui(size: 11, weight: .semibold))
                            .foregroundStyle(GBColor.Content.tertiary)
                    }

                    ProgressView(value: Double(pillar.value), total: Double(pillar.total))
                        .tint(pillar.color)
                        .animation(GBMotion.progress, value: pillar.value)
                }
                .padding(.horizontal, GBSpacing.xSmall)
                .padding(.vertical, GBSpacing.xxSmall)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                        .fill(GBColor.Background.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                                .stroke(GBColor.Border.default, lineWidth: 1)
                        )
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quest progress: \(storyCount) of \(storyTotal) story scenes, \(placeCount) of \(placeTotal) places, \(chronicleCount) of \(chronicleTotal) chronicle cards")
    }
}
