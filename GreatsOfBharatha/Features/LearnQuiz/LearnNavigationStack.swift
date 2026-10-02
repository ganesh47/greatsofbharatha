import SwiftUI
#if DEBUG
import UIKit
#endif

@MainActor
final class LearnNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath() {
        didSet { trace("path.didSet", priorCount: oldValue.count) }
    }
    private let resetStack: () -> Void
#if DEBUG
    private let diagnosticID = UUID()
    private let navigationID: UUID
#endif

    init(navigationID: UUID, resetStack: @escaping () -> Void) {
        self.resetStack = resetStack
#if DEBUG
        self.navigationID = navigationID
#endif
        trace("coordinator.init")
    }

    func returnHome() {
        trace("returnHome.begin")
        GBNarrator.shared.stop()
        path = NavigationPath()
        trace("returnHome.pathCleared")
        // Legacy destination and Boolean links also belong to this stack.
        // Recreating it dismisses those routes as well as value-based routes.
        resetStack()
        trace("returnHome.resetReturned")
    }

    func openScene(_ sceneID: String) {
        trace("continue.beforeAppend", sceneID: sceneID)
        path.append(sceneID)
        trace("continue.afterAppend", sceneID: sceneID)
    }

    func trace(_ event: String, sceneID: String? = nil, priorCount: Int? = nil) {
#if DEBUG
        SyntheticNavigationTrace.record(event, navigationID: navigationID, coordinatorID: diagnosticID,
            sceneID: sceneID, count: path.count, priorCount: priorCount)
#endif
    }
}

struct LearnNavigationStack<Content: View>: View {
    @State private var stackIdentity = UUID()
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        LearnNavigationSession(content: content, navigationID: stackIdentity, resetStack: {
            let next = UUID()
#if DEBUG
            SyntheticNavigationTrace.record("reset.request", navigationID: stackIdentity, nextNavigationID: next)
#endif
            stackIdentity = next
        })
        .id(stackIdentity)
#if DEBUG
        .overlay(alignment: .topLeading) {
            if SyntheticNavigationTrace.enabled {
                NavigationTraceProbe().frame(width: 1, height: 1).allowsHitTesting(false)
            }
        }
#endif
    }
}

/// A reset replaces the native stack and its path owner together, preventing
/// departing and entering stacks from sharing the same path binding.
private struct LearnNavigationSession<Content: View>: View {
    @StateObject private var navigation: LearnNavigationCoordinator
    private let content: () -> Content

    init(content: @escaping () -> Content, navigationID: UUID, resetStack: @escaping () -> Void) {
        self.content = content
        _navigation = StateObject(wrappedValue: LearnNavigationCoordinator(navigationID: navigationID, resetStack: resetStack))
    }

    var body: some View {
        NavigationStack(path: $navigation.path) { content() }
            .environmentObject(navigation)
            .onAppear { navigation.trace("session.appear") }
            .onDisappear { navigation.trace("session.disappear") }
    }
}

#if DEBUG
/// Only canonical routing metadata from isolated synthetic tests; no user data or persistent writes.
@MainActor
private enum SyntheticNavigationTrace {
    static let enabled = ProcessInfo.processInfo.environment["GOB_NAV_TRACE"] == "1"
        && ProcessInfo.processInfo.environment["GOB_UI_TEST_SUITE"]?.hasPrefix("gob.ui.") == true
    private static let launchID = UUID()
    private static let origin = ProcessInfo.processInfo.systemUptime
    private static var sequence = 0
    private static var lines: [String] = []
    static var payload: String { lines.joined(separator: "\n") }

    static func record(_ event: String, navigationID: UUID? = nil, coordinatorID: UUID? = nil,
                       sceneID: String? = nil, count: Int? = nil, priorCount: Int? = nil, nextNavigationID: UUID? = nil) {
        guard enabled else { return }
        sequence += 1
        var row: [String: Any] = ["v": 1, "seq": sequence,
            "ms": Int((ProcessInfo.processInfo.systemUptime - origin) * 1000),
            "launchID": launchID.uuidString, "pid": ProcessInfo.processInfo.processIdentifier, "event": event]
        row["navID"] = navigationID?.uuidString
        row["coordID"] = coordinatorID?.uuidString
        row["sceneID"] = sceneID
        row["count"] = count
        row["priorCount"] = priorCount
        row["nextNavID"] = nextNavigationID?.uuidString
        if let data = try? JSONSerialization.data(withJSONObject: row, options: [.sortedKeys]),
           let line = String(data: data, encoding: .utf8) {
            lines.append(line)
            if lines.count > 128 { lines.removeFirst(lines.count - 128) }
        }
    }
}

private struct NavigationTraceProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> NavigationTraceProbeView {
        let view = NavigationTraceProbeView()
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "gob-nav-trace"
        view.accessibilityLabel = "Synthetic navigation trace"
        view.backgroundColor = .clear
        return view
    }
    func updateUIView(_ uiView: NavigationTraceProbeView, context: Context) {}
}

private final class NavigationTraceProbeView: UIView {
    override var accessibilityValue: String? {
        get { SyntheticNavigationTrace.payload }
        set {}
    }
}
#endif
