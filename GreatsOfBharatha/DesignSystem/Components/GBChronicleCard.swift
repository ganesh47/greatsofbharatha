import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBChronicleCard.swift — Greats of Bharatha Design System
// Used in ChronicleView (collection grid) and RewardReveal
// ─────────────────────────────────────────────────────────────

enum GBMasteryLevel: String, CaseIterable {
    case witnessed       = "Witnessed"
    case understood      = "Understood"
    case observedClosely = "Observed Closely"

    var color: Color {
        switch self {
        case .witnessed:       return GBColor.Story.primary
        case .understood:      return GBColor.Place.primary
        case .observedClosely: return GBColor.Chronicle.gold
        }
    }
    var background: Color {
        switch self {
        case .witnessed:       return GBColor.Story.bg
        case .understood:      return GBColor.Place.bg
        case .observedClosely: return GBColor.Chronicle.goldBg
        }
    }
}

// ── GBMasteryBadge ────────────────────────────────────────────
struct GBMasteryBadge: View {
    let level: GBMasteryLevel

    var body: some View {
        Text(level.rawValue)
            .font(GBFont.ui(size: 10, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.3)
            .foregroundStyle(level.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(level.background)
                    .overlay(Capsule().stroke(level.color.opacity(0.3), lineWidth: 1))
            )
    }
}

// ── GBChronicleCard — collection state ───────────────────────
struct GBChronicleCard: View {
    let title:    String
    let subtitle: String
    let iconName: String        // SF Symbol name
    let description: String
    let mastery:  GBMasteryLevel?
    var isLocked: Bool = false
    var emphasis: GBEmphasis = .chronicle

    var body: some View {
        VStack(spacing: 0) {
            // Header band (gradient or locked muted)
            ZStack(alignment: .bottomLeading) {
                if isLocked {
                    GBColor.State.lockedBg
                } else {
                    LinearGradient(
                        colors: [GBColor.Background.chronicleStart, GBColor.accent(for: emphasis)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                HStack(alignment: .center, spacing: GBSpacing.xSmall) {
                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Content.inverse)
                        .saturation(isLocked ? 0 : 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(GBFont.display(size: 16, weight: .bold))
                            .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Content.inverse)
                        Text(subtitle)
                            .font(GBFont.display(size: 12, weight: .regular))
                            .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Chronicle.goldLight)
                    }

                    Spacer()

                    if let mastery, !isLocked {
                        GBMasteryBadge(level: mastery)
                    }
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(GBColor.State.locked)
                    }
                }
                .padding(GBSpacing.small)
            }
            .frame(height: 80)

            // Body
            HStack {
                Text(description)
                    .font(GBFont.story(size: 14, italic: true))
                    .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Content.secondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(GBSpacing.small)
            .background(isLocked ? GBColor.State.lockedBg : GBColor.Background.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                .stroke(isLocked ? GBColor.Background.panelDeep.opacity(0.25) : GBColor.accent(for: emphasis).opacity(0.25), lineWidth: 1.5)
        )
        .gbShadow(isLocked ? .card : .gold)
    }
}

// ── GBRewardReveal — ceremonial full reveal ───────────────────
struct GBRewardReveal: View {
    let title:       String
    let subtitle:    String
    let iconName:    String
    let quote:       String
    let mastery:     GBMasteryLevel
    var onDismiss:   (() -> Void)?

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: GBSpacing.medium) {
            VStack(spacing: 0) {
                // Full gradient header
                VStack(spacing: GBSpacing.xxSmall) {
                    Image(systemName: iconName)
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(GBColor.Content.inverse)
                    Text(title)
                        .font(GBFont.display(size: 22, weight: .bold))
                        .foregroundStyle(GBColor.Content.inverse)
                        .tracking(0.5)
                    Text(subtitle)
                        .font(GBFont.display(size: 13, weight: .regular))
                        .foregroundStyle(GBColor.Chronicle.goldLight)
                    GBMasteryBadge(level: mastery)
                        .padding(.top, GBSpacing.xxSmall)
                }
                .padding(.vertical, GBSpacing.large)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [GBColor.Background.chronicleStart, GBColor.Background.chronicleEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // Quote
                VStack(spacing: GBSpacing.xxSmall) {
                    Text(quote)
                        .font(GBFont.story(size: 15, italic: true))
                        .foregroundStyle(GBColor.Content.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, GBSpacing.xxSmall)
                }
                .padding(GBSpacing.medium)
                .frame(maxWidth: .infinity)
                .background(GBColor.Background.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
            .gbShadow(.gold)
            .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.82))
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(GBMotion.ceremony.delay(0.2)) {
                    appeared = true
                }
                GBHaptic.chronicleReveal()
            }

            if let onDismiss {
                Button("Continue", action: onDismiss)
                    .buttonStyle(GBPrimaryButtonStyle(emphasis: .story))
            }
        }
        .padding(GBSpacing.medium)
    }
}

#Preview("Chronicle Cards") {
    ScrollView {
        VStack(spacing: GBSpacing.cardGap) {
            GBChronicleCard(
                title: "Birth Fort", subtitle: "Shivneri",
                iconName: "building.columns.fill",
                description: "Shivneri Fort, northern Sahyadri. Where Shivaji Maharaj's journey began.",
                mastery: .witnessed,
                isLocked: false
            )
            GBChronicleCard(
                title: "Chhatrapati Crown", subtitle: "Raigad · 1674",
                iconName: "crown.fill",
                description: "Complete Scene 6 to unlock this Chronicle card.",
                mastery: nil,
                isLocked: true
            )
        }
        .padding()
    }
    .background(GBColor.Background.app)
}
