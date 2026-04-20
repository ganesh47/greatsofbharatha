import SwiftUI

enum GBTypography {
    static func display(_ text: Text) -> some View {
        text
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    static func title(_ text: Text) -> some View {
        text
            .font(.system(.title3, design: .rounded, weight: .bold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    static func headline(_ text: Text) -> some View {
        text
            .font(.headline.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    static func body(_ text: Text) -> some View {
        text
            .font(.body)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    static func caption(_ text: Text) -> some View {
        text
            .font(.caption.weight(.semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}

extension Text {
    func gbDisplay() -> some View { GBTypography.display(self) }
    func gbTitle() -> some View { GBTypography.title(self) }
    func gbHeadline() -> some View { GBTypography.headline(self) }
    func gbBody() -> some View { GBTypography.body(self) }
    func gbCaption() -> some View { GBTypography.caption(self) }
}

