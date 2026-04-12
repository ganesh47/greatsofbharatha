import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView {
            NavigationStack {
                StoryHomeView(scenes: appModel.content.scenes)
            }
            .tabItem {
                Label("Story", systemImage: "book.closed")
            }

            NavigationStack {
                PlacesHubView(places: appModel.content.corePlaces)
            }
            .tabItem {
                Label("Places", systemImage: "map")
            }

            NavigationStack {
                ChronicleView(rewards: appModel.content.rewards)
            }
            .tabItem {
                Label("Chronicle", systemImage: "sparkles.rectangle.stack")
            }
        }
        .tint(.orange)
    }
}
