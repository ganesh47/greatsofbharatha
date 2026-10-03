import SwiftUI

enum LearnRoute: Hashable {
    case scene(String)
    case quiz(sceneID: String, sessionID: UUID)
    case matching(sceneIDs: [String], sessionID: UUID)
    case review
    case chronicle
}

@MainActor
final class LearnNavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func returnHome() {
        GBNarrator.shared.stop()
        path = NavigationPath()
    }

    func openScene(_ sceneID: String) {
        path.append(LearnRoute.scene(sceneID))
    }

    func openQuiz(sceneID: String, sessionID: UUID) {
        path.append(LearnRoute.quiz(sceneID: sceneID, sessionID: sessionID))
    }

    func openMatching(sceneIDs: [String], sessionID: UUID = UUID()) {
        path.append(LearnRoute.matching(sceneIDs: sceneIDs, sessionID: sessionID))
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
        if let scene = LearnQuizPilotData.scenes.first(where: { $0.id == sceneID }) {
            SceneLearnView(scene: scene).id(sceneID)
        }
    }
}
