import SwiftUI

struct GBButtonStyle: ButtonStyle {
    enum Kind {
        case primary(GBEmphasis)
        case secondary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, GBSpacing.small)
            .padding(.vertical, GBSpacing.small)
            .background(background(configuration: configuration), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous)
                    .stroke(borderColor, lineWidth: showsBorder ? 1 : 0)
            )
            .foregroundStyle(foregroundColor)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(GBMotion.quick, value: configuration.isPressed)
    }

    @ViewBuilder
    private func background(configuration: Configuration) -> some ShapeStyle {
        switch kind {
        case .primary(let emphasis):
            GBColor.gradient(for: emphasis)
        case .secondary:
            GBColor.Background.elevated.opacity(configuration.isPressed ? 0.88 : 1)
        }
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            GBColor.Content.inverse
        case .secondary:
            GBColor.Content.primary
        }
    }

    private var borderColor: Color {
        GBColor.Border.emphasis
    }

    private var showsBorder: Bool {
        switch kind {
        case .primary:
            false
        case .secondary:
            true
        }
    }
}

extension ButtonStyle where Self == GBButtonStyle {
    static func gbPrimary(_ emphasis: GBEmphasis = .story) -> GBButtonStyle {
        GBButtonStyle(kind: .primary(emphasis))
    }

    static var gbSecondary: GBButtonStyle {
        GBButtonStyle(kind: .secondary)
    }
}
