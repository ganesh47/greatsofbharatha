import SwiftUI

@MainActor
final class LearnNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published private(set) var stackIdentity = UUID()

    func returnHome() {
        GBNarrator.shared.stop()
        path = NavigationPath()
        // Legacy destination and Boolean links also belong to this stack.
        // Recreating it dismisses those routes as well as value-based routes.
        stackIdentity = UUID()
    }
}

struct LearnNavigationStack<Content: View>: View {
    @StateObject private var navigation = LearnNavigationCoordinator()
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $navigation.path) { content() }
            .id(navigation.stackIdentity)
            .environmentObject(navigation)
    }
}
