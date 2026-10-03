import SwiftUI

@main
struct GreatsOfBharathaTVApp: App {
    @StateObject private var appModel: AppModel
    @StateObject private var narrator = GBNarrator()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let model = AppModel(defaults: AppLaunchConfiguration.defaults())
#if DEBUG
        // An isolated XCTest fixture shortens diagnosis of the chapter-four focus regression.
        // The acceptance journey starts pristine; this fixture is absent from Release builds.
        let environment = ProcessInfo.processInfo.environment
        if environment["GOB_UI_TEST_SEED_THROUGH_CHAPTER"] == "3",
           environment["GOB_UI_TEST_RESET"] == "1",
           environment["GOB_UI_TEST_SUITE"]?.hasPrefix("gob.tv.ui.") == true {
            for chapter in TVLearningContent.chapters.prefix(3) {
                let session = UUID()
                model.lessonStore.recordLearningOutcome(subjectID: chapter.id, activity: .storyExposure,
                    wasSuccessful: false, detail: "Isolated remote-test fixture", sessionID: session)
                model.lessonStore.recordLearningOutcome(subjectID: chapter.id, activity: .recall,
                    wasSuccessful: true, support: .independent, detail: "Isolated remote-test fixture", sessionID: session)
            }
        }
#endif
        _appModel = StateObject(wrappedValue: model)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let entry = ChapterKnowledgeDebugEntry.current() {
                    NavigationStack {
                        TVLessonView(sceneID: entry.sceneID, initialKnowledgeEntry: entry.mode)
                    }
                } else { TVHomeView() }
            }
                .environmentObject(appModel)
                .environmentObject(narrator)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in if phase != .active { narrator.stop() } }
                .onChange(of: appModel.parentSettings.narrationEnabled) { _, enabled in if !enabled { narrator.stop() } }
        }
    }
}

enum TVRoute: Hashable {
    case lesson(String)
    case replay(String)
    case album
    case map
    case timeline
    case parent
    case review
}
