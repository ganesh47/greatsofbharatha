import SwiftUI

struct SceneLearnView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var sessionID = UUID()
    @State private var showsQuiz = false
    @State private var showsMatch = false
    @State private var recordedExposure = false
    let scene: LearnQuizPilotScene

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    SceneLearnCard(scene: scene, ctaTitle: "Quiz me", onCTA: { saveQuizCheckpoint(); showsQuiz = true })
                    LearningNarrationControls(id: scene.id + "-pilot-story", text: scene.story + " " + scene.memoryHook)

                    if let content = ChapterDiscoveryContent.chapter(sceneID: scene.id) {
                        ChapterStoryDiscoveryView(content: content)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: GBSpacing.xSmall)], spacing: GBSpacing.xSmall) {
                        NavigationLink {
                            ChronicleQuizView(scene: scene, sessionID: sessionID)
                        } label: {
                            Label("Quiz", systemImage: "questionmark.bubble.fill")
                        }
                        .buttonStyle(.gbPrimary(.story))
                        .simultaneousGesture(TapGesture().onEnded { saveQuizCheckpoint() })

                        NavigationLink {
                            ChronicleMatchView(scenes: [scene], sessionID: sessionID)
                        } label: {
                            Label("Match", systemImage: "square.grid.2x2.fill")
                        }
                        .buttonStyle(.gbSecondary)

                        NavigationLink {
                            LearningReviewEntry()
                        } label: {
                            Label("Cards", systemImage: "rectangle.on.rectangle.angled")
                        }
                        .buttonStyle(.gbSecondary)
                    }

                    NavigationLink {
                        ChronicleBookView(scenes: LearnQuizPilotData.scenes)
                    } label: {
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
        .navigationDestination(isPresented: $showsQuiz) { ChronicleQuizView(scene: scene, sessionID: sessionID) }
        .navigationDestination(isPresented: $showsMatch) { ChronicleMatchView(scenes: [scene], sessionID: sessionID) }
        .onAppear {
            guard !recordedExposure else { return }
            recordedExposure = true
            let point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id, sessionID: sessionID)
            sessionID = point.sessionID
            appModel.lessonStore.saveResumePoint(point)
            if point.preferredActivity == .match { showsMatch = true }
            else if point.phase == .recall || point.phase == .reward { showsQuiz = true }
            appModel.lessonStore.recordLearningOutcome(subjectID: scene.id, activity: .storyExposure,
                wasSuccessful: true, mastery: .witnessed, detail: "Read authored pilot story", sessionID: sessionID)
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
