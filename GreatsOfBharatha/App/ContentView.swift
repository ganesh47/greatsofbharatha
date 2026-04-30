import SwiftUI

struct ContentView: View {
    @State private var selectedTab: DebugTabRoute = .learn
    @State private var showsParentView = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // ── Tab 1: Story ──────────────────────────────────
            NavigationStack {
                if FeatureFlags.historyLearnQuizResetEnabled {
                    LearnQuizResetPlaceholderView()
                } else {
                    LessonHomeView()
                }
            }
            .tabItem { Label("Story", systemImage: "book.fill") }
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

struct LearnQuizResetPlaceholderView: View {
    private let pilot = SampleContent.shivajiLearnQuizResetPilot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.large) {
                VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                    Text("Shivaji Chronicle Pilot")
                        .gbTitle()
                        .foregroundStyle(GBColor.Content.primary)

                    Text("Learn, quiz, match, and build the Chronicle.")
                        .gbBody()
                        .foregroundStyle(GBColor.Content.secondary)
                }

                ForEach(pilot.scenes) { scene in
                    VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                        Text(scene.memoryHook)
                            .gbCaption()
                            .foregroundStyle(GBColor.Story.primary)

                        Text(scene.title)
                            .gbHeadline()
                            .foregroundStyle(GBColor.Content.primary)

                        Text(scene.childSafeStory)
                            .gbStory()
                            .foregroundStyle(GBColor.Content.secondary)

                        Text(scene.quizItems.first?.prompt ?? "")
                            .gbBody()
                            .foregroundStyle(GBColor.Content.primary)
                            .padding(.top, GBSpacing.xSmall)
                    }
                    .padding(GBSpacing.medium)
                    .background(GBColor.Background.surface)
                    .clipShape(RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                            .stroke(GBColor.Border.default)
                    )
                }
            }
            .padding(GBSpacing.large)
        }
        .background(GBColor.Background.app)
        .navigationTitle("Chronicle Pilot")
    }
}
