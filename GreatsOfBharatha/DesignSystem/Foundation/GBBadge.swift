import SwiftUI

struct GBBadge: View {
    let title: String
    var symbol: String?
    var emphasis: GBEmphasis = .neutral
    var inverted: Bool = false

    var body: some View {
        Label {
            Text(title)
        } icon: {
            if let symbol {
                Image(systemName: symbol)
            }
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, GBSpacing.xSmall)
        .padding(.vertical, GBSpacing.xxSmall)
        .background(background, in: Capsule())
        .foregroundStyle(foreground)
        .accessibilityElement(children: .combine)
    }

    private var background: Color {
        if inverted {
            return GBColor.Content.inverse.opacity(0.22)
        }

        switch emphasis {
        case .story:
            return GBColor.Accent.story.opacity(0.16)
        case .place:
            return GBColor.Accent.place.opacity(0.16)
        case .chronicle:
            return GBColor.Accent.chronicle.opacity(0.16)
        case .neutral:
            return GBColor.Background.elevated
        }
    }

    private var foreground: Color {
        if inverted {
            return GBColor.Content.inverse
        }

        switch emphasis {
        case .story:
            return GBColor.Accent.story
        case .place:
            return GBColor.Accent.place
        case .chronicle:
            return GBColor.Accent.chronicle
        case .neutral:
            return GBColor.Content.secondary
        }
    }
}
#Preview("Badge") {
    HStack(spacing: GBSpacing.xxSmall) {
        GBBadge(title: "Story", symbol: GBIcon.story, emphasis: .story)
        GBBadge(title: "Find Place", symbol: GBIcon.place, emphasis: .place)
        GBBadge(title: "Chronicle", symbol: GBIcon.chronicle, emphasis: .chronicle)
    }
    .padding()
    .background(GBColor.Background.app)
}
