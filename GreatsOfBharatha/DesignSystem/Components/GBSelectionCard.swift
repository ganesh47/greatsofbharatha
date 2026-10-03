import SwiftUI

/// Persistent learning state. Remote focus is rendered separately by the button style.
enum GBSelectionState: Equatable {
    case ready, selected, discovered, found, locked

    var label: String {
        switch self {
        case .ready: "Explore"
        case .selected: "Chosen"
        case .discovered: "Discovered"
        case .found: "Found it!"
        case .locked: "Coming next"
        }
    }

    var symbol: String {
        switch self {
        case .ready: "hand.tap.fill"
        case .selected: "checkmark.circle.fill"
        case .discovered: "eye.fill"
        case .found: "checkmark.seal.fill"
        case .locked: "lock.fill"
        }
    }
}

/// Content only: wrap in a Button or NavigationLink and apply .gbSelection.
struct GBSelectionCard: View {
    let title: String
    var subtitle: String?
    var symbol: String?
    var imageAsset: String?
    var state: GBSelectionState = .ready
    var emphasis: GBEmphasis = .story

    private var accent: Color { GBColor.accent(for: emphasis) }
    private var marked: Bool { state == .selected || state == .discovered || state == .found }
    private var artworkHeight: CGFloat {
#if os(tvOS)
        170
#else
        112
#endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            if let imageAsset {
                GeometryReader { geometry in
                    Image(imageAsset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: artworkHeight)
                        .clipped()
                }
                .frame(height: artworkHeight)
                .clipShape(RoundedRectangle(cornerRadius: GBRadius.compact))
                .accessibilityHidden(true)
            } else if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: artworkHeight * 0.38, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: artworkHeight)
                    .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: GBRadius.compact))
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(GBFont.ui(size: 17, weight: .heavy))
                .foregroundStyle(GBColor.Content.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(GBFont.ui(size: 14))
                    .foregroundStyle(GBColor.Content.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Label(state.label, systemImage: state.symbol)
                .font(GBFont.ui(size: 12, weight: .bold))
                .foregroundStyle(state == .locked ? GBColor.Content.secondary : accent)
                .padding(.horizontal, GBSpacing.xSmall)
                .padding(.vertical, GBSpacing.xxSmall)
                .background(accent.opacity(marked ? 0.16 : 0.07), in: Capsule())
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GBSpacing.small)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: GBRadius.card)
                .stroke(marked ? accent : GBColor.Border.default, lineWidth: marked ? 3 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(state.label)
        .accessibilityAddTraits(state == .selected ? [.isSelected] : [])
    }
}

struct GBSelectionButtonStyle: ButtonStyle {
    var emphasis: GBEmphasis = .story
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var appModel: AppModel

    private var calm: Bool { reduceMotion || appModel.parentSettings.calmTransitionsEnabled }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minHeight: GBTouch.button)
            .contentShape(RoundedRectangle(cornerRadius: GBRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: GBRadius.card + 5)
                    .stroke(GBColor.Content.primary, lineWidth: isFocused ? 4 : 0)
                    .padding(-6)
                    .accessibilityHidden(true)
            }
            .scaleEffect(calm ? 1 : (configuration.isPressed ? 0.98 : (isFocused ? 1.025 : 1)))
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(calm ? nil : GBMotion.quick, value: configuration.isPressed)
            .animation(calm ? nil : GBMotion.spring, value: isFocused)
    }
}

extension ButtonStyle where Self == GBSelectionButtonStyle {
    static var gbSelection: GBSelectionButtonStyle { .init() }
    static func gbSelection(emphasis: GBEmphasis) -> GBSelectionButtonStyle { .init(emphasis: emphasis) }
    static func gbSelection(_ emphasis: GBEmphasis) -> GBSelectionButtonStyle { .init(emphasis: emphasis) }
}
