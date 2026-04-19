import SwiftUI

struct ContentView: View {
    @State private var selectedTab: DebugTabRoute = .learn

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LessonHomeView()
            }
            .tabItem {
                Label("Learn", systemImage: "book.closed")
            }
            .tag(DebugTabRoute.learn)

            NavigationStack {
                PlacesHubView(places: SampleContent.shivajiVerticalSlice.corePlaces)
            }
            .tabItem {
                Label("Places", systemImage: "map")
            }
            .tag(DebugTabRoute.places)

            NavigationStack {
                ChronicleView(rewards: SampleContent.shivajiVerticalSlice.rewards)
            }
            .tabItem {
                Label("Chronicle", systemImage: "sparkles.rectangle.stack")
            }
            .tag(DebugTabRoute.chronicle)
        }
        .tint(.orange)
    }
}
