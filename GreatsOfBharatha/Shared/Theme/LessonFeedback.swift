import SwiftUI

@MainActor
struct LessonFeedback {
    enum HapticToken {
        case selection
        case reveal
        case success
        case warning
        case celebration
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
        case .celebration:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
#else
        _ = token
#endif
    }
}
