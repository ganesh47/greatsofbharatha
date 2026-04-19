import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel
    let debugRoute: DebugNavigationRoute?

    @State private var selectedTab: DebugTabRoute

    init(debugRoute: DebugNavigationRoute? = nil) {
        self.debugRoute = debugRoute
        _selectedTab = State(initialValue: debugRoute?.tab ?? .learn)
    }

    @ViewBuilder
    private var captureScreen: some View {
        switch debugRoute?.destination {
        case .scene1:
            if let scene = appModel.content.scenes.first(where: { $0.id == "scene-1-shivneri" }) {
                NavigationStack { SceneLessonView(scene: scene) }
            }
        case .scene2:
            if let scene = appModel.content.scenes.first(where: { $0.id == "scene-2-torna-rajgad" }) {
                NavigationStack { SceneLessonView(scene: scene) }
            }
        case .placesHub:
            NavigationStack { PlacesHubView(places: appModel.content.corePlaces) }
        case .placeShivneri:
            if let place = appModel.content.corePlaces.first(where: { $0.id == "place-shivneri" }) {
                NavigationStack { PlaceDetailView(place: place, progress: appModel.lessonStore.progress(for: place)) }
            }
        case .chronicleUnlocked:
            NavigationStack {
                ChronicleView(
                    rewards: appModel.content.rewards,
                    highlightRewardID: "reward-first-big-fort-card"
                )
            }
        case .learnHome, .none:
            NavigationStack { LessonHomeView() }
        }
    }

    var body: some View {
        Group {
            if debugRoute != nil {
                captureScreen
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        LessonHomeView()
                    }
                    .tabItem {
                        Label("Learn", systemImage: "book.closed")
                    }
                    .tag(DebugTabRoute.learn)

                    NavigationStack {
                        PlacesHubView(places: appModel.content.corePlaces)
                    }
                    .tabItem {
                        Label("Places", systemImage: "map")
                    }
                    .tag(DebugTabRoute.places)

                    NavigationStack {
                        ChronicleView(rewards: appModel.content.rewards)
                    }
                    .tabItem {
                        Label("Chronicle", systemImage: "sparkles.rectangle.stack")
                    }
                    .tag(DebugTabRoute.chronicle)
                }
            }
        }
        .tint(.orange)
        .onAppear {
            if debugRoute?.destination == .chronicleUnlocked {
                appModel.lessonStore.seedForDebugCapture()
            }
        }
    }
}
