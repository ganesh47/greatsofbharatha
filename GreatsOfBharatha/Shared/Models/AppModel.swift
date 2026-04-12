import SwiftUI

final class AppModel: ObservableObject {
    @Published var content: AppContent

    init(content: AppContent = SampleContent.shivajiVerticalSlice) {
        self.content = content
    }
}
