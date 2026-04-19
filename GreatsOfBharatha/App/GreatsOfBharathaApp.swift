import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    @StateObject private var appModel = AppModel()
    private let captureRoute = DebugNavigationRoute.current()

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
