import SwiftUI

struct GBSectionHeader: View {
    enum Tone {
        case `default`
        case inverse
    }

    let eyebrow: String?
    let title: String
    let subtitle: String?
    let tone: Tone
    var trailing: AnyView?

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        tone: Tone = .default,
        trailing: AnyView? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.tone = tone
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top, spacing: GBSpacing.small) {
            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .gbCaption()
                        .foregroundStyle(secondaryColor)
                }

                Text(title)
                    .gbTitle()
                    .foregroundStyle(primaryColor)

                if let subtitle {
                    Text(subtitle)
                        .gbBody()
                        .foregroundStyle(secondaryColor)
                }
            }

            Spacer(minLength: GBSpacing.small)

            trailing
        }
    }

    private var primaryColor: Color {
        switch tone {
        case .default:
            GBColor.Content.primary
        case .inverse:
            GBColor.Content.inverse
        }
    }

    private var secondaryColor: Color {
        switch tone {
        case .default:
            GBColor.Content.secondary
        case .inverse:
            GBColor.Content.inverse.opacity(0.84)
        }
    }
}

#Preview("Section Header") {
    GBSectionHeader(
        eyebrow: "Journey",
        title: "Fort trail",
        subtitle: "See how each place fits the story before you open the board.",
        trailing: AnyView(GBBadge(title: "3 ready", symbol: GBIcon.place, emphasis: .place))
    )
    .padding()
}
