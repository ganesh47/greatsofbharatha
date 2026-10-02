import SwiftUI

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    private var recommended: StoryScene? {
        if let resume = appModel.lessonStore.latestResumePoint, resume.phase != .reward, resume.preferredActivity != .match,
           let scene = appModel.content.scenes.first(where: { $0.id == resume.sceneID }) { return scene }
        return appModel.content.scenes.first(where: { $0.id == appModel.lessonStore.nextSceneID })
            ?? appModel.content.scenes.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.large) {
                if let scene = recommended {
                    VStack(alignment: .leading, spacing: GBSpacing.medium) {
                        LessonSceneArt(plan: SampleContent.learningPlan(for: scene))
                        Text(scene.title).gbDisplay()
                        Text(scene.childSafeSummary).gbStory()
                        NavigationLink(value: scene.id) {
                            Label(primaryTitle(scene), systemImage: "play.fill")
                                .frame(maxWidth: .infinity, minHeight: GBTouch.primary)
                        }
                        .buttonStyle(.gbPrimary(.story))
                        .accessibilityIdentifier("home-primary-lesson")
                        LearningNarrationControls(id: "home-" + scene.id, text: scene.title + ". " + scene.childSafeSummary)
                    }
                }
                Text("\(appModel.lessonStore.completedScenes) of \(appModel.lessonStore.totalScenes) chapters completed")
                    .gbBody().accessibilityIdentifier("home-chapter-progress")
                Text("Your adventures").gbTitle()
                ForEach(appModel.content.scenes) { scene in
                    if appModel.lessonStore.isSceneUnlocked(scene) {
                        NavigationLink(value: scene.id) { sceneRow(scene, locked: false) }
                            .buttonStyle(.plain)
                    } else { sceneRow(scene, locked: true) }
                }
                let learned = LearnQuizPilotData.scenes.filter {
                    appModel.lessonStore.mastery(for: $0.id).map { $0 >= .understood } ?? false
                }
                if !learned.isEmpty {
                    Text("Play with your story clues").gbTitle()
                    NavigationLink { ChronicleMatchView(scenes: learned) } label: {
                        Label("Match places", systemImage: "square.grid.2x2.fill")
                    }.buttonStyle(.gbSecondary).accessibilityIdentifier("home-match-places")
                    NavigationLink { FlashcardReviewView(cards: learned.flatMap(\.reviewCards), hooks: LearningActivityAdapters.reviewHooks(store: appModel.lessonStore)) } label: {
                        Label("Review story cards", systemImage: "rectangle.on.rectangle")
                    }.buttonStyle(.gbSecondary).accessibilityIdentifier("home-review-cards")
                    NavigationLink { ChronicleBookView(scenes: LearnQuizPilotData.scenes) } label: {
                        Label("Open my Chronicle book", systemImage: "book.closed.fill")
                    }.buttonStyle(.gbSecondary).accessibilityIdentifier("home-chronicle-book")
                }
            }
            .padding(GBSpacing.medium)
            .frame(maxWidth: 700).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("home-story-scroll")
        .background(GBColor.Background.app)
        .navigationTitle("Story Time")
        .navigationDestination(for: String.self) { sceneID in
            if let scene = appModel.content.scenes.first(where: { $0.id == sceneID }) {
                SceneLessonView(scene: scene).id(sceneID)
            }
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
        return HStack {
            Image(systemName: locked ? "lock.fill" : (mastery.map { $0 >= .understood } == true ? "checkmark.circle.fill" : "book.fill"))
            VStack(alignment: .leading) {
                Text("Chapter \(scene.number): \(scene.title)").gbHeadline()
                Text(status).font(.caption)
            }
            Spacer()
        }
        .foregroundStyle(locked ? GBColor.Content.secondary : GBColor.Content.primary)
        .padding(GBSpacing.medium)
        .frame(minHeight: GBTouch.button)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.card))
        .accessibilityElement(children: .combine)
    }
}
