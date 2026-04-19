import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    let debugRoute: DebugNavigationRoute?

    @State private var selectedTab: DebugTabRoute

    init(debugRoute: DebugNavigationRoute? = nil) {
        self.debugRoute = debugRoute
        _selectedTab = State(initialValue: debugRoute?.tab ?? .learn)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                if debugRoute?.destination == .scene1, let scene = appModel.content.scenes.first(where: { $0.id == "scene-1-shivneri" }) {
                    SceneLessonView(scene: scene)
                } else if debugRoute?.destination == .scene2, let scene = appModel.content.scenes.first(where: { $0.id == "scene-2-torna-rajgad" }) {
                    SceneLessonView(scene: scene)
                } else {
                    LessonHomeView()
                }
            }
            .tabItem {
                Label("Learn", systemImage: "book.closed")
            }
            .tag(DebugTabRoute.learn)

            NavigationStack {
                if debugRoute?.destination == .placeShivneri, let place = appModel.content.corePlaces.first(where: { $0.id == "place-shivneri" }) {
                    PlaceDetailView(place: place, progress: appModel.lessonStore.progress(for: place))
                } else {
                    PlacesHubView(places: appModel.content.corePlaces)
                }
            }
            .tabItem {
                Label("Places", systemImage: "map")
            }
            .tag(DebugTabRoute.places)

            NavigationStack {
                ChronicleView(
                    rewards: appModel.content.rewards,
                    highlightRewardID: debugRoute?.destination == .chronicleUnlocked ? "reward-first-big-fort-card" : nil
                )
            }
            .tabItem {
                Label("Chronicle", systemImage: "sparkles.rectangle.stack")
            }
            .tag(DebugTabRoute.chronicle)
        }
        .tint(.orange)
        .onAppear {
            if debugRoute?.destination == .chronicleUnlocked {
                appModel.lessonStore.seedForDebugCapture()
            }
        }
    }
}
