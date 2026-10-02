import SwiftUI

@MainActor
final class LearnNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    private let resetStack: () -> Void

    init(resetStack: @escaping () -> Void) {
        self.resetStack = resetStack
    }

    func returnHome() {
        GBNarrator.shared.stop()
        path = NavigationPath()
        // Legacy destination and Boolean links also belong to this stack.
        // Recreating it dismisses those routes as well as value-based routes.
        resetStack()
    }
}

struct LearnNavigationStack<Content: View>: View {
    @State private var stackIdentity = UUID()
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        LearnNavigationSession(content: content, resetStack: { stackIdentity = UUID() })
            .id(stackIdentity)
    }
}

/// A reset replaces the native stack and its path owner together. Retaining the
/// old path owner across native-stack recreation leaves two stack lifetimes
/// temporarily attached to one binding on older supported SwiftUI runtimes.
private struct LearnNavigationSession<Content: View>: View {
    @StateObject private var navigation: LearnNavigationCoordinator
    private let content: () -> Content

    init(content: @escaping () -> Content, resetStack: @escaping () -> Void) {
        self.content = content
        _navigation = StateObject(wrappedValue: LearnNavigationCoordinator(resetStack: resetStack))
    }

    var body: some View {
        NavigationStack(path: $navigation.path) { content() }
            .environmentObject(navigation)
    }
}
