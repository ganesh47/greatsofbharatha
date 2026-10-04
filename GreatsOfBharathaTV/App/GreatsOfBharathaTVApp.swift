import SwiftUI

@main
struct GreatsOfBharathaTVApp: App {
    @StateObject private var appModel: AppModel
    @StateObject private var narrator = GBNarrator()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let defaults = AppLaunchConfiguration.defaults()
        #if DEBUG
        TVKnowledgeCompatibilityFixture.prepare(defaults: defaults)
        #endif
        let model = AppModel(defaults: defaults)
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
                if let sceneID = TVKnowledgeCompatibilityFixture.sceneID {
                    NavigationStack { TVLessonView(sceneID: sceneID) }
                } else if let entry = ChapterKnowledgeDebugEntry.current() {
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

/// Synthetic old-progress fixtures never run for ordinary or Release launches.
private enum TVKnowledgeCompatibilityFixture {
    static var sceneID: String? {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        guard environment["GOB_UI_TEST_SUITE"]?.hasPrefix("gob.tv.ui.knowledge.") == true,
              ["story", "recall", "replay"].contains(environment["GOB_UI_TEST_KNOWLEDGE_COMPATIBILITY"] ?? "") else { return nil }
        return "scene-1-shivneri"
        #else
        return nil
        #endif
    }

    #if DEBUG
    @MainActor
    static func prepare(defaults: UserDefaults) {
        let environment = ProcessInfo.processInfo.environment
        guard let sceneID, environment["GOB_UI_TEST_RESET"] == "1" else { return }
        let mode = environment["GOB_UI_TEST_KNOWLEDGE_COMPATIBILITY"]
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        var point = LessonResumePoint(sceneID: sceneID)
        var checkpoint = TVActivityCheckpoint()
        if mode == "recall" {
            checkpoint.stage = .recall
            checkpoint.completedActivityIDs = ["recall"]
            checkpoint.knowledgePracticePending = true
        } else if mode == "replay" {
            checkpoint.stage = .keepsake
            checkpoint.completedActivityIDs = ["album"]
        }
        point.tvCheckpoint = checkpoint
        guard store.saveResumePointConfirmed(point) else { return }
        if mode == "replay" {
            var archive = ChapterKnowledgeArchive()
            archive.teachingBySceneID[sceneID] = ChapterKnowledgeTeachingCheckpoint(sceneID: sceneID, activeBeatID: sceneID + "-meaning")
            _ = store.saveActivityState(archive, for: .knowledge)
            return
        }
        guard let data = defaults.data(forKey: "shivajiLessonStore.snapshot.v1"),
              var snapshot = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        let payload = environment["GOB_UI_TEST_KNOWLEDGE_OPAQUE"] == "corrupt"
            ? Data("not-json".utf8) : Data("{\"schemaVersion\":99,\"futureField\":\"preserve\"}".utf8)
        snapshot["activityStateData"] = [LessonActivityStateKey.knowledge.rawValue: payload.base64EncodedString()]
        if let updated = try? JSONSerialization.data(withJSONObject: snapshot) {
            defaults.set(updated, forKey: "shivajiLessonStore.snapshot.v1")
        }
    }
    #endif
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
