import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    private let captureRoute: DebugNavigationRoute?
    @StateObject private var appModel: AppModel

    init() {
        let route = DebugNavigationRoute.current()
        self.captureRoute = route
        let model = AppModel(defaults: AppLaunchConfiguration.defaults(captureRoute: route), captureSeedProfile: route?.seedProfile)
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if route == nil, environment["GOB_UI_TEST_RESET"] == "1",
           environment["GOB_UI_TEST_SUITE"]?.hasPrefix("gob.ui.enrichment.") == true,
           let count = Int(environment["GOB_UI_TEST_SEED_THROUGH_CHAPTER"] ?? ""), (1...6).contains(count) {
            for scene in model.content.scenes.prefix(count) {
                model.lessonStore.recordStoryExposure(for: scene.id, detail: "Isolated enrichment UI fixture")
                model.lessonStore.recordLearningOutcome(subjectID: scene.id, activity: .recall, wasSuccessful: true,
                    detail: "Isolated enrichment UI fixture", sessionID: UUID())
            }
        }
#endif
        _appModel = StateObject(wrappedValue: model)
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            Group {
                if let captureRoute {
                    CaptureRootView(route: captureRoute)
                } else {
                    ContentView()
                }
            }
            .environmentObject(appModel)
        }
    }
}
