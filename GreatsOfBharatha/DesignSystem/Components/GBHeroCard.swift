import SwiftUI

struct GBHeroCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let detail: String
    let ctaTitle: String
    var badgeTitle: String?
    var emphasis: GBEmphasis = .story
    var progress: Double?
    var action: (() -> Void)?

    @Environment(\.gbLayoutContext) private var layoutContext

    var body: some View {
        GBSurface(style: .accented(emphasis), padding: layoutContext.widthClass == .compact ? GBSpacing.medium : GBSpacing.large) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text(eyebrow)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.86))
                        Text(title)
                            .font(.system(layoutContext.widthClass == .compact ? .title2 : .largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(GBColor.Content.inverse)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.96))
                    }

                    Spacer(minLength: GBSpacing.small)

                    if let badgeTitle {
                        GBBadge(title: badgeTitle, symbol: heroSymbol, emphasis: emphasis, inverted: true)
                    }
                }

                Text(detail)
                    .font(.body)
                    .foregroundStyle(GBColor.Content.inverse.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                if let progress {
                    ProgressView(value: progress)
                        .tint(GBColor.Content.inverse)
                }

                if let action {
                    Button(ctaTitle, action: action)
                        .buttonStyle(.gbSecondary)
                        .padding(.top, GBSpacing.xxxSmall)
                } else {
                    Label(ctaTitle, systemImage: GBIcon.next)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(GBColor.Content.inverse)
                        .padding(.top, GBSpacing.xxxSmall)
                }
            }
            .frame(minHeight: layoutContext.heroMinHeight, alignment: .topLeading)
        }
    }

    private var heroSymbol: String {
        switch emphasis {
        case .story:
            GBIcon.story
        case .place:
            GBIcon.place
        case .chronicle:
            GBIcon.chronicle
        case .neutral:
            GBIcon.next
        }
    }
}

#Preview("Hero Card") {
    GBLayoutContextReader { _ in
        GBHeroCard(
            eyebrow: "Shivaji Maharaj",
            title: "Your journey continues",
            subtitle: "Rajgad becomes the next fort to remember.",
            detail: "Hear the story, find the fort, and earn a Chronicle reward without extra screen noise.",
            ctaTitle: "Continue journey",
            badgeTitle: "Next adventure",
            emphasis: .story,
            progress: 0.45
        )
        .padding()
    }
    .background(GBColor.Background.app)
}
