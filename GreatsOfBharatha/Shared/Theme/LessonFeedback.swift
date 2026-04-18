import SwiftUI

@MainActor
struct LessonFeedback {
    enum HapticToken {
        case selection
        case reveal
        case success
        case warning
    }

    static func fire(_ token: HapticToken) {
#if os(iOS)
        switch token {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .reveal:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
#else
        _ = token
#endif
    }
}
