import SwiftUI
#if DEBUG
import UIKit
#endif

enum LearnRoute: Hashable {
    case scene(String)
    case quiz(sceneID: String, sessionID: UUID)
    case matching(sceneIDs: [String], sessionID: UUID)
    case review
    case chronicle
}

@MainActor
final class LearnNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath() {
        didSet { trace("path.didSet", priorCount: oldValue.count) }
    }
#if DEBUG
    private let diagnosticID = UUID()
    private let navigationID = UUID()
#endif

    init() {
        trace("coordinator.init")
    }

    func returnHome() {
        trace("returnHome.begin")
        GBNarrator.shared.stop()
        path = NavigationPath()
        trace("returnHome.pathCleared")
    }

    func openScene(_ sceneID: String) {
        trace("continue.beforeAppend", sceneID: sceneID)
        path.append(LearnRoute.scene(sceneID))
        trace("continue.afterAppend", sceneID: sceneID)
    }

    func openQuiz(sceneID: String, sessionID: UUID) {
        path.append(LearnRoute.quiz(sceneID: sceneID, sessionID: sessionID))
    }

    func openMatching(sceneIDs: [String], sessionID: UUID = UUID()) {
        path.append(LearnRoute.matching(sceneIDs: sceneIDs, sessionID: sessionID))
    }

    func trace(_ event: String, sceneID: String? = nil, priorCount: Int? = nil) {
#if DEBUG
        SyntheticNavigationTrace.record(event, navigationID: navigationID, coordinatorID: diagnosticID,
            sceneID: sceneID, count: path.count, priorCount: priorCount)
#endif
    }
}

struct LearnNavigationStack<Content: View>: View {
    @StateObject private var navigation = LearnNavigationCoordinator()
    private let content: () -> Content
    private let registerPilotRoutes: Bool

    init(registerPilotRoutes: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.registerPilotRoutes = registerPilotRoutes
    }

    var body: some View {
        NavigationStack(path: $navigation.path) {
            if registerPilotRoutes {
                content()
                    .navigationDestination(for: LearnRoute.self) { route in
                        destination(route)
                    }
            } else {
                content()
            }
        }
        .environmentObject(navigation)
        .onAppear { navigation.trace("session.appear") }
        .onDisappear { navigation.trace("session.disappear") }
        .onChange(of: navigation.path.count) { _, _ in navigation.trace("session.pathCountChanged") }
#if DEBUG
        .overlay(alignment: .topLeading) {
            if SyntheticNavigationTrace.enabled {
                NavigationTraceProbe().frame(width: 1, height: 1).allowsHitTesting(false)
            }
        }
#endif
    }

    @ViewBuilder
    private func destination(_ route: LearnRoute) -> some View {
        switch route {
        case .scene(let sceneID):
            sceneDestination(sceneID)
        case .quiz(let sceneID, let sessionID):
            if let scene = LearnQuizPilotData.scenes.first(where: { $0.id == sceneID }) {
                ChronicleQuizView(scene: scene, sessionID: sessionID)
            }
        case .matching(let sceneIDs, let sessionID):
            ChronicleMatchView(scenes: sceneIDs.compactMap { sceneID in
                LearnQuizPilotData.scenes.first(where: { $0.id == sceneID })
            }, sessionID: sessionID)
        case .review:
            LearningReviewEntry()
        case .chronicle:
            ChronicleBookView(scenes: LearnQuizPilotData.scenes)
        }
    }

    @ViewBuilder
    private func sceneDestination(_ sceneID: String) -> some View {
        let _ = navigation.trace("destination.resolve", sceneID: sceneID)
        if let scene = LearnQuizPilotData.scenes.first(where: { $0.id == sceneID }) {
            SceneLearnView(scene: scene).id(sceneID)
                .onAppear { navigation.trace("destination.appear", sceneID: sceneID) }
                .onDisappear { navigation.trace("destination.disappear", sceneID: sceneID) }
        }
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
