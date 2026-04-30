import SwiftUI

struct ParentLearningSettings: Equatable {
    var assistModeEnabled: Bool = true
    var narrationEnabled: Bool = true
    var calmTransitionsEnabled: Bool = true
}

enum FeatureFlags {
    static var historyLearnQuizResetEnabled: Bool {
        let rawValue = ProcessInfo.processInfo.environment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] ?? ""
        return ["1", "true", "TRUE", "yes", "YES"].contains(rawValue)
    }
}

final class AppModel: ObservableObject {
    @Published var content: AppContent {
        didSet {
            lessonStore = ShivajiLessonStore(content: content)
        }
    }

    @Published var lessonStore: ShivajiLessonStore
    @Published var parentSettings = ParentLearningSettings()

    init(content: AppContent = SampleContent.shivajiVerticalSlice, captureSeedProfile: CaptureSeedProfile = .pristine) {
        self.content = content
        self.lessonStore = ShivajiLessonStore(content: content)
        self.lessonStore.applyCaptureSeed(captureSeedProfile)
    }
}
