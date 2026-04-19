import Foundation

enum DebugTabRoute: String {
    case learn
    case places
    case chronicle
}

enum DebugDestinationRoute: String {
    case scene1 = "scene-1"
    case scene2 = "scene-2"
    case placeShivneri = "place-shivneri"
    case chronicleUnlocked = "chronicle-unlocked"
}

struct DebugNavigationRoute {
    let tab: DebugTabRoute
    let destination: DebugDestinationRoute?

    static func current(from environment: [String: String] = ProcessInfo.processInfo.environment) -> DebugNavigationRoute? {
        guard let tabRaw = environment["GOB_CAPTURE_TAB"], let tab = DebugTabRoute(rawValue: tabRaw) else {
            return nil
        }
        let destination = environment["GOB_CAPTURE_DESTINATION"].flatMap(DebugDestinationRoute.init(rawValue:))
        return DebugNavigationRoute(tab: tab, destination: destination)
    }
}
