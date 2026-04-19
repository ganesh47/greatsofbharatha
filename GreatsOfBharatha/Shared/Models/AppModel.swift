import SwiftUI

final class AppModel: ObservableObject {
    @Published var content: AppContent {
        didSet {
            lessonStore = ShivajiLessonStore(content: content)
        }
    }

    @Published var lessonStore: ShivajiLessonStore

    init(content: AppContent = SampleContent.shivajiVerticalSlice, captureSeedProfile: CaptureSeedProfile = .pristine) {
        self.content = content
        self.lessonStore = ShivajiLessonStore(content: content)
        self.lessonStore.applyCaptureSeed(captureSeedProfile)
    }
}
