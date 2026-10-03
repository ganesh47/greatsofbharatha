import SwiftUI

struct LessonHomeView: View {
    @FocusState private var focusedSceneID: String?
    @EnvironmentObject private var appModel: AppModel

    private var recommended: StoryScene? {
        if let resume = appModel.lessonStore.latestResumePoint, resume.phase != .reward, resume.preferredActivity != .match,
           let scene = appModel.content.scenes.first(where: { $0.id == resume.sceneID }) { return scene }
        return appModel.content.scenes.first(where: { $0.id == appModel.lessonStore.nextSceneID })
            ?? appModel.content.scenes.first
    }

    var body: some View {
        GBLayoutContextReader { context in
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.large) {
                if let scene = recommended {
                    if context.isTelevision {
                        HStack(alignment: .center, spacing: context.sectionSpacing) {
                            LessonSceneArt(plan: SampleContent.learningPlan(for: scene)).frame(maxWidth: .infinity)
                            recommendedActions(scene).frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: GBSpacing.medium) {
                            LessonSceneArt(plan: SampleContent.learningPlan(for: scene))
                            recommendedActions(scene)
                        }
                    }
                }
                Text("\(appModel.lessonStore.completedScenes) of \(appModel.lessonStore.totalScenes) chapters completed")
                    .gbBody().accessibilityIdentifier("home-chapter-progress")
                Text("Your adventures").gbTitle()
                LazyVGrid(columns: [GridItem(.adaptive(minimum: context.isTelevision ? 400 : 260), spacing: context.cardSpacing)], spacing: context.cardSpacing) {
                ForEach(appModel.content.scenes) { scene in
                    if appModel.lessonStore.isSceneUnlocked(scene) {
                        NavigationLink(value: scene.id) { sceneRow(scene, locked: false) }
                            .buttonStyle(.gbSelection)
                            .focused($focusedSceneID, equals: scene.id)
                    } else { sceneRow(scene, locked: true) }
                }
                }
#if os(iOS)
                let learned = LearnQuizPilotData.scenes.filter {
                    appModel.lessonStore.mastery(for: $0.id).map { $0 >= .understood } ?? false
                }
                if !learned.isEmpty {
                    Text("Play with your story clues").gbTitle()
                    NavigationLink { ChronicleMatchView(scenes: learned, usesLegacyPresentation: true) } label: {
                        Label("Match places", systemImage: "square.grid.2x2.fill")
                    }.buttonStyle(.gbSecondary).accessibilityIdentifier("home-match-places")
                    NavigationLink { LearningReviewEntry() } label: {
                        Label("Review story cards", systemImage: "rectangle.on.rectangle")
                    }.buttonStyle(.gbSecondary).accessibilityIdentifier("home-review-cards")
                    NavigationLink { ChronicleBookView(scenes: LearnQuizPilotData.scenes) } label: {
                        Label("Open my Chronicle book", systemImage: "book.closed.fill")
                    }.buttonStyle(.gbSecondary).accessibilityIdentifier("home-chronicle-book")
                }

#endif
            }
            .padding(context.containerPadding)
            .frame(maxWidth: context.maxContentWidth).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("home-story-scroll")
        .background(GBColor.Background.app)
        }
#if os(tvOS)
        .navigationTitle("")
#else
        .navigationTitle("Story Time")
#endif
#if os(tvOS)
        .onAppear { if focusedSceneID == nil { focusedSceneID = "primary" } }
#endif
        .navigationDestination(for: String.self) { sceneID in
            if let scene = appModel.content.scenes.first(where: { $0.id == sceneID }) {
                SceneLessonView(scene: scene).id(sceneID)
            }
        }
    }

    private func recommendedActions(_ scene: StoryScene) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Text(scene.title).gbDisplay()
            Text(scene.childSafeSummary).gbStory()
            NavigationLink(value: scene.id) {
                Label(primaryTitle(scene), systemImage: "play.fill")
                    .frame(maxWidth: .infinity, minHeight: GBTouch.primary)
            }
            .buttonStyle(.gbPrimary(.story))
            .focused($focusedSceneID, equals: "primary")
            .accessibilityIdentifier("home-primary-lesson")
            LearningNarrationControls(id: "home-" + scene.id, text: scene.title + ". " + scene.childSafeSummary)
        }
    }

    private func primaryTitle(_ scene: StoryScene) -> String {
        if appModel.lessonStore.resumePoint(for: scene.id) != nil { return "Continue: \(scene.title)" }
        if let mastery = appModel.lessonStore.mastery(for: scene.id), mastery >= .understood { return "Explore again: \(scene.title)" }
        return "Start: \(scene.title)"
    }

    private func sceneRow(_ scene: StoryScene, locked: Bool) -> some View {
        let mastery = appModel.lessonStore.mastery(for: scene.id)
        let status = locked ? "Ready after the previous chapter" : (mastery.map { $0 >= .understood ? "Completed" : "Started" } ?? "Ready to explore")
        return GBSelectionCard(title: "Chapter \(scene.number): \(scene.title)",
            subtitle: status,
            imageAsset: SampleContent.learningPlan(for: scene).imageAsset,
            state: locked ? .locked : (mastery.map { $0 >= .understood } == true ? .discovered : .ready),
            emphasis: .story)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("home-chapter-" + scene.id)
    }
}
