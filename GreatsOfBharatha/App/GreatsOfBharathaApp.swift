import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    private let captureRoute: DebugNavigationRoute?
    @StateObject private var appModel: AppModel

    init() {
        let route = DebugNavigationRoute.current()
        self.captureRoute = route
        _appModel = StateObject(wrappedValue: AppModel(defaults: AppLaunchConfiguration.defaults(captureRoute: route), captureSeedProfile: route?.seedProfile))
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
