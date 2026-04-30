import SwiftUI

struct CaptureRootView: View {
    @EnvironmentObject private var appModel: AppModel
    let route: DebugNavigationRoute

    var body: some View {
        captureScreen
            .tint(.orange)
    }

    @ViewBuilder
    private var captureScreen: some View {
        switch route {
        case .learnQuizReset:
            NavigationStack { LearnQuizHomeView() }
        case .scene1:
            if let scene = appModel.content.scenes.first(where: { $0.id == "scene-1-shivneri" }) {
                NavigationStack { SceneLessonView(scene: scene) }
            } else {
                Text("Missing capture scene: scene-1-shivneri")
            }
        case .scene2:
            if let scene = appModel.content.scenes.first(where: { $0.id == "scene-2-torna-rajgad" }) {
                NavigationStack { SceneLessonView(scene: scene) }
            } else {
                Text("Missing capture scene: scene-2-torna-rajgad")
            }
        case .placesHub:
            NavigationStack { PlacesHubView(places: appModel.content.corePlaces) }
        case .placeShivneri:
            if let place = appModel.content.corePlaces.first(where: { $0.id == "place-shivneri" }) {
                NavigationStack { PlaceDetailView(place: place, progress: appModel.lessonStore.progress(for: place)) }
            } else {
                Text("Missing capture place: place-shivneri")
            }
        case .chronicleUnlocked:
            NavigationStack {
                ChronicleView(
                    rewards: appModel.content.rewards,
                    highlightRewardID: "reward-first-big-fort-card"
                )
            }
        case .timelineHome:
            NavigationStack { TimelineHubView() }
        case .parentHome:
            NavigationStack { ParentProgressView() }
        case .learnHome:
            NavigationStack { LessonHomeView() }
        case .learnQuizHome:
            NavigationStack { LearnQuizHomeView() }
        }
    }
}
