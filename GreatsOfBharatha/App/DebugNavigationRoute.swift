import Foundation

enum DebugTabRoute: String {
    case learn
    case places
    case timeline
    case chronicle
    case parent
}

enum CaptureSeedProfile {
    case pristine
    case chronicleUnlocked
}

enum DebugNavigationRoute: String {
    case learnQuizReset = "learn-quiz-reset"
    case learnHome = "learn-home"
    case scene1 = "scene-1"
    case scene2 = "scene-2"
    case placesHub = "places-hub"
    case placeShivneri = "place-shivneri"
    case timelineHome = "timeline-home"
    case chronicleUnlocked = "chronicle-unlocked"
    case parentHome = "parent-home"

    static func current(from environment: [String: String] = ProcessInfo.processInfo.environment) -> DebugNavigationRoute? {
        if let raw = environment["GOB_CAPTURE_ROUTE"], let route = DebugNavigationRoute(rawValue: raw) {
            return route
        }

        let tab = environment["GOB_CAPTURE_TAB"] ?? ""
        let destination = environment["GOB_CAPTURE_DESTINATION"] ?? ""

        switch (tab, destination) {
        case ("learn", "learn-quiz-reset"):
            return .learnQuizReset
        case ("learn", ""), ("learn", "learn-home"):
            return .learnHome
        case ("learn", "scene-1"):
            return .scene1
        case ("learn", "scene-2"):
            return .scene2
        case ("places", ""), ("places", "places-hub"):
            return .placesHub
        case ("places", "place-shivneri"):
            return .placeShivneri
        case ("timeline", ""), ("timeline", "timeline-home"):
            return .timelineHome
        case ("chronicle", "chronicle-unlocked"):
            return .chronicleUnlocked
        case ("parent", ""), ("parent", "parent-home"):
            return .parentHome
        default:
            return nil
        }
    }

    var seedProfile: CaptureSeedProfile {
        switch self {
        case .chronicleUnlocked:
            return .chronicleUnlocked
        default:
            return .pristine
        }
    }
}
