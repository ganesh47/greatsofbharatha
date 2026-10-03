import SwiftUI

struct GBLayoutContext: Equatable {
    enum WidthClass: Equatable {
        case compact
        case regular
        case television
    }

    let widthClass: WidthClass
    let containerPadding: CGFloat
    let sectionSpacing: CGFloat
    let cardSpacing: CGFloat
    let maxContentWidth: CGFloat?

    var isTelevision: Bool { widthClass == .television }

    var prefersHorizontalQuestProgress: Bool {
        widthClass == .compact
    }

    var heroMinHeight: CGFloat {
        isTelevision ? 360 : (widthClass == .compact ? 220 : 260)
    }

    static let compact = GBLayoutContext(
        widthClass: .compact,
        containerPadding: GBSpacing.small,
        sectionSpacing: GBSpacing.medium,
        cardSpacing: GBSpacing.small,
        maxContentWidth: nil
    )

    static let television = GBLayoutContext(
        widthClass: .television,
        containerPadding: 64,
        sectionSpacing: 40,
        cardSpacing: 28,
        maxContentWidth: 1680
    )

    static let regular = GBLayoutContext(
        widthClass: .regular,
        containerPadding: GBSpacing.large,
        sectionSpacing: GBSpacing.large,
        cardSpacing: GBSpacing.medium,
        maxContentWidth: 920
    )
}
private struct GBLayoutContextKey: EnvironmentKey {
    static let defaultValue: GBLayoutContext = .compact
}

extension EnvironmentValues {
    var gbLayoutContext: GBLayoutContext {
        get { self[GBLayoutContextKey.self] }
        set { self[GBLayoutContextKey.self] = newValue }
    }
}

struct GBLayoutContextReader<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let content: (GBLayoutContext) -> Content

    init(@ViewBuilder content: @escaping (GBLayoutContext) -> Content) {
        self.content = content
    }

    var body: some View {
#if os(tvOS)
        let context = GBLayoutContext.television
#else
        let context = horizontalSizeClass == .regular ? GBLayoutContext.regular : GBLayoutContext.compact

#endif
        content(context)
            .environment(\.gbLayoutContext, context)
    }
}
