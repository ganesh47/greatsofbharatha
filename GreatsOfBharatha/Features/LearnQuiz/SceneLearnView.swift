import SwiftUI

struct SceneLearnView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var navigation: LearnNavigationCoordinator
    @State private var sessionID = UUID()
    @State private var recordedExposure = false
    let scene: LearnQuizPilotScene
    var initialKnowledgeEntry: ChapterKnowledgeEntryMode?

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    SceneLearnCard(scene: scene, ctaTitle: "Quiz me", onCTA: {
                        saveQuizCheckpoint()
                        navigation.openQuiz(sceneID: scene.id, sessionID: sessionID)
                    })
                    LearningNarrationControls(id: scene.id + "-pilot-story", text: scene.story + " " + scene.memoryHook)

                    ChapterKnowledgeChapterLinks(sceneID: scene.id, sessionID: sessionID, initialEntry: initialKnowledgeEntry)

                    if let content = ChapterDiscoveryContent.chapter(sceneID: scene.id) {
                        ChapterStoryDiscoveryView(content: content)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: GBSpacing.xSmall)], spacing: GBSpacing.xSmall) {
                        NavigationLink(value: LearnRoute.quiz(sceneID: scene.id, sessionID: sessionID)) {
                            Label("Quiz", systemImage: "questionmark.bubble.fill")
                        }
                        .buttonStyle(.gbPrimary(.story))
                        .simultaneousGesture(TapGesture().onEnded { saveQuizCheckpoint() })

                        NavigationLink(value: LearnRoute.matching(sceneIDs: [scene.id], sessionID: sessionID)) {
                            Label("Match", systemImage: "square.grid.2x2.fill")
                        }
                        .buttonStyle(.gbSecondary)

                        NavigationLink(value: LearnRoute.review) {
                            Label("Cards", systemImage: "rectangle.on.rectangle.angled")
                        }
                        .buttonStyle(.gbSecondary)
                        .accessibilityIdentifier("pilot-scene-review")
                    }

                    NavigationLink(value: LearnRoute.chronicle) {
                        GBSurface(style: .elevated) {
                            HStack(spacing: GBSpacing.small) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(GBColor.Chronicle.gold)
                                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                                    Text("Your Chronicle reward")
                                        .font(GBFont.ui(size: 16, weight: .bold))
                                        .foregroundStyle(GBColor.Content.primary)
                                    Text(scene.chronicleEntry.title)
                                        .font(GBFont.ui(size: 14, weight: .semibold))
                                        .foregroundStyle(GBColor.Content.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(GBColor.Content.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .accessibilityIdentifier("pilot-scene-scroll")
        .onAppear {
            guard !recordedExposure else { return }
            recordedExposure = true
            let point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id, sessionID: sessionID)
            sessionID = point.sessionID
            appModel.lessonStore.saveResumePoint(point)
            appModel.lessonStore.recordLearningOutcome(subjectID: scene.id, activity: .storyExposure,
                wasSuccessful: true, mastery: .witnessed, detail: "Read authored pilot story", sessionID: sessionID)
            if point.preferredActivity == .match {
                navigation.openMatching(sceneIDs: [scene.id], sessionID: sessionID)
            } else if point.phase == .recall || point.phase == .reward {
                navigation.openQuiz(sceneID: scene.id, sessionID: sessionID)
            }
        }
        .navigationTitle(scene.memoryHook)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    private func saveQuizCheckpoint() {
        var point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id, sessionID: sessionID)
        point.phase = point.recallCompleted ? .reward : .recall
        point.preferredActivity = .recall
        point.updatedAt = Date()
        appModel.lessonStore.saveResumePoint(point)
    }
}

#Preview("Scene Learn Cards") {
    LearnNavigationStack {
        SceneLearnView(scene: LearnQuizPilotData.scenes[0])
    }
    .environmentObject(AppModel(defaults: UserDefaults(suiteName: "gob.preview.scene-learn")!))
}
