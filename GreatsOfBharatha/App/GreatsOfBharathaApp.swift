import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    private let captureRoute: DebugNavigationRoute?
    @StateObject private var appModel: AppModel

    init() {
        let route = DebugNavigationRoute.current()
        self.captureRoute = route
        _appModel = StateObject(wrappedValue: AppModel(captureSeedProfile: route?.seedProfile ?? .pristine))
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
