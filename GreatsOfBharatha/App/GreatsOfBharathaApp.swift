import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    @StateObject private var appModel = AppModel()
    private let debugRoute = DebugNavigationRoute.current()

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView(debugRoute: debugRoute)
                .environmentObject(appModel)
        }
    }
}
