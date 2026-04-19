import SwiftUI

struct CaptureRootView: View {
    @EnvironmentObject private var appModel: AppModel
    let route: DebugNavigationRoute

    var body: some View {
        ZStack(alignment: .topLeading) {
            captureScreen

            Text("CAPTURE ROUTE: \(route.rawValue)")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.75), in: Capsule())
                .foregroundStyle(.white)
                .padding()
        }
        .tint(.orange)
    }

    @ViewBuilder
    private var captureScreen: some View {
        switch route {
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
        case .learnHome:
            NavigationStack { LessonHomeView() }
        }
    }
}
