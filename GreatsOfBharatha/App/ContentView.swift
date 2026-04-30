import SwiftUI

struct ContentView: View {
    @State private var selectedTab: DebugTabRoute = .learn
    @State private var showsParentView = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // ── Tab 1: Story ──────────────────────────────────
            NavigationStack {
                if GBFeatureFlags.historyLearnQuizResetEnabled {
                    LearnQuizHomeView()
                } else {
                    LessonHomeView()
                }
            }
            .tabItem { Label(GBFeatureFlags.historyLearnQuizResetEnabled ? "Learn" : "Story", systemImage: "book.fill") }
            .tag(DebugTabRoute.learn)

            // ── Tab 2: Map ────────────────────────────────────
            NavigationStack {
                PlacesHubView(places: SampleContent.shivajiVerticalSlice.corePlaces)
            }
            .tabItem { Label("Map", systemImage: "map.fill") }
            .tag(DebugTabRoute.places)

            // ── Tab 3: Album (Chronicle + Parent gear) ────────
            NavigationStack {
                ChronicleView(rewards: SampleContent.shivajiVerticalSlice.rewards)
                    .toolbar {
                        // Discreet parent-access button — no label visible to children
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showsParentView = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16))
                                    .foregroundStyle(GBColor.Content.tertiary)
                            }
                            .accessibilityLabel("Parent settings")
                        }
                    }
            }
            .tabItem { Label("Album", systemImage: "sparkles.rectangle.stack") }
            .tag(DebugTabRoute.chronicle)
        }
        .tint(GBColor.Story.primary)
        .sheet(isPresented: $showsParentView) {
            NavigationStack { ParentProgressView() }
        }
    }
}
