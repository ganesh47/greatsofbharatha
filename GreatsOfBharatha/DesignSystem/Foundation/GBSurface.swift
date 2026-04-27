import SwiftUI

struct GBSurface<Content: View>: View {
    enum Style {
        case plain
        case elevated
        case accented(GBEmphasis)
    }

    private let style: Style
    private let padding: CGFloat
    private let content: Content

    init(
        style: Style = .plain,
        padding: CGFloat = GBSpacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundStyle)
                    .overlay {
                        if case .accented = style {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(Color.black.opacity(0.42))
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .accented:
            GBRadius.hero
        case .plain, .elevated:
            GBRadius.card
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .plain:
            AnyShapeStyle(GBColor.Background.surface)
        case .elevated:
            AnyShapeStyle(GBColor.Background.elevated)
        case .accented(let emphasis):
            AnyShapeStyle(GBColor.gradient(for: emphasis))
        }
    }

    private var borderColor: Color {
        switch style {
        case .accented:
            .white.opacity(0.12)
        case .plain, .elevated:
            GBColor.Border.default
        }
    }
}
#Preview("Surface") {
    GBSurface(style: .elevated) {
        VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
            Text("Surface").gbTitle()
            Text("Shared container treatment for cards and grouped sections.").gbBody()
        }
    }
    .padding()
    .background(GBColor.Background.app)
}
