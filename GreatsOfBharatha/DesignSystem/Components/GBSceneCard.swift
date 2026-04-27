import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBSceneCard.swift — Greats of Bharatha Design System
// Scene list card for LessonHomeView
// ─────────────────────────────────────────────────────────────

enum GBSceneStatus {
    case locked
    case current
    case completed
}

struct GBSceneCard: View {
    let sceneNumber: Int
    let title:       String
    let subtitle:    String
    let status:      GBSceneStatus
    var emphasis:    GBEmphasis = .story
    var action:      (() -> Void)?

    @Environment(\.gbLayoutContext) private var layout

    var body: some View {
        Button(action: { if status != .locked { action?() } }) {
            HStack(spacing: GBSpacing.small) {
                // Scene number badge
                ZStack {
                    RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                        .fill(badgeBackground)
                    Text("\(sceneNumber)")
                        .font(GBFont.display(size: 15, weight: .bold))
                        .foregroundStyle(badgeForeground)
                }
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                        .stroke(badgeBorder, lineWidth: 1)
                )

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scene \(sceneNumber)")
                        .font(GBFont.ui(size: 10, weight: .heavy))
                        .textCase(.uppercase)
                        .tracking(1.3)
                        .foregroundStyle(eyebrowColor)

                    Text(title)
                        .font(GBFont.ui(size: 15, weight: .bold))
                        .foregroundStyle(status == .locked ? GBColor.State.locked : GBColor.Content.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(GBFont.story(size: 13, italic: true))
                        .foregroundStyle(GBColor.Content.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: GBSpacing.xxSmall)

                statusIcon
            }
            .padding(.horizontal, GBSpacing.small)
            .padding(.vertical, GBSpacing.xSmall)
            .background(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1.5)
            )
            .opacity(status == .locked ? 0.70 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(status == .locked)
        .animation(GBMotion.quick, value: status)
    }

    private var badgeBackground: AnyShapeStyle {
        if status == .locked { return AnyShapeStyle(GBColor.State.lockedBg) }
        return AnyShapeStyle(GBColor.gradient(for: emphasis))
    }

    private var badgeForeground: Color {
        status == .locked ? GBColor.State.locked : GBColor.Content.inverse
    }

    private var badgeBorder: Color {
        status == .locked ? GBColor.State.lockedBg : .clear
    }

    private var eyebrowColor: Color {
        status == .locked ? GBColor.State.locked : GBColor.accent(for: emphasis)
    }

    private var cardBackground: Color {
        status == .locked ? GBColor.State.lockedBg : GBColor.Background.surface
    }

    private var cardBorder: Color {
        status == .locked ? GBColor.Background.panelDeep.opacity(0.35) : GBColor.Background.panel.opacity(0.6)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .locked:    Image(systemName: "lock.fill").foregroundStyle(GBColor.State.locked)
        case .current:   Image(systemName: "play.fill").foregroundStyle(GBColor.accent(for: emphasis))
        case .completed: Image(systemName: "checkmark.circle.fill").foregroundStyle(GBColor.Place.primary)
        }
    }
}

#Preview("Scene Cards") {
    ScrollView {
        VStack(spacing: GBSpacing.cardGap) {
            GBSceneCard(sceneNumber: 1, title: "Shivneri", subtitle: "The child who would become a leader", status: .current, emphasis: .story)
            GBSceneCard(sceneNumber: 2, title: "Torna & Rajgad", subtitle: "The start of Swarajya", status: .locked)
            GBSceneCard(sceneNumber: 6, title: "Raigad", subtitle: "Coronation as Chhatrapati — 1674", status: .completed, emphasis: .chronicle)
        }
        .padding()
    }
    .background(GBColor.Background.app)
}
