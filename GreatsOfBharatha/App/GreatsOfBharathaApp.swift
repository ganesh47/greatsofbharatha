import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    private let captureRoute = DebugNavigationRoute.current()
    @StateObject private var appModel: AppModel

    init() {
        let captureRoute = DebugNavigationRoute.current()
        self.captureRoute = captureRoute
        _appModel = StateObject(wrappedValue: AppModel(captureSeedProfile: captureRoute?.seedProfile ?? .pristine))
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
