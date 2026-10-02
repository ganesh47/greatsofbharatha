import SwiftUI

@MainActor
final class LearnNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    private let resetStack: () -> Void
#if DEBUG
    private let diagnosticID = UUID()
    @Published private var openCount = 0
    @Published private var homeAppearanceCount = 0
    @Published private var observedPathCount = -1
    private var requestedSceneID = "none"
#endif

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

    func openScene(_ sceneID: String) {
#if DEBUG
        if diagnosticsEnabled {
            requestedSceneID = sceneID
            openCount += 1
            print("GOB_NAV before-append " + syntheticDiagnosticValue)
        }
#endif
        path.append(sceneID)
#if DEBUG
        if diagnosticsEnabled { print("GOB_NAV after-append " + syntheticDiagnosticValue) }
#endif
    }

    func recordHomeAppearance() {
#if DEBUG
        if diagnosticsEnabled { homeAppearanceCount += 1 }
#endif
    }

    func recordObservedPath() {
#if DEBUG
        if diagnosticsEnabled {
            observedPathCount = path.count
            print("GOB_NAV path-observed " + syntheticDiagnosticValue)
        }
#endif
    }

    var syntheticDiagnosticValue: String {
#if DEBUG
        guard diagnosticsEnabled else { return "" }
        return "coordinator=\(diagnosticID.uuidString) open=\(openCount) home=\(homeAppearanceCount) path=\(path.count) observed=\(observedPathCount) scene=\(requestedSceneID)"
#else
        return ""
#endif
    }

#if DEBUG
    private var diagnosticsEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["GOB_NAV_TRACE"] == "1" && environment["GOB_UI_TEST_SUITE"]?.hasPrefix("gob.ui.") == true
    }
#endif
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

/// A reset replaces the native stack and its path owner together, preventing
/// departing and entering stacks from sharing the same path binding.
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
            .onChange(of: navigation.path) { _, _ in navigation.recordObservedPath() }
    }
}
