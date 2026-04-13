import SwiftUI

@main
struct GreatsOfBharathaApp: SwiftUI.App {
    @StateObject private var appModel = AppModel()

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
    }
}
