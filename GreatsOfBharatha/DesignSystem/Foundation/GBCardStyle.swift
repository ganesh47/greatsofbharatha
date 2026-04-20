import SwiftUI

struct GBCardStyle: ViewModifier {
    let emphasis: GBEmphasis

    func body(content: Content) -> some View {
        GBSurface(style: emphasis == .neutral ? .plain : .accented(emphasis)) {
            content
        }
    }
}

extension View {
    func gbCardStyle(_ emphasis: GBEmphasis = .neutral) -> some View {
        modifier(GBCardStyle(emphasis: emphasis))
    }
}

