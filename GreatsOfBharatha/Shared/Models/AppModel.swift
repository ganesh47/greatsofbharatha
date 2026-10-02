import Combine
import SwiftUI

struct ParentLearningSettings: Codable, Equatable {
    var assistModeEnabled: Bool = true
    var narrationEnabled: Bool = true
    var calmTransitionsEnabled: Bool = true
}

enum FeatureFlags {
    static var historyLearnQuizResetEnabled: Bool {
#if DEBUG
        if let rawValue = ProcessInfo.processInfo.environment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"] {
            return ["1", "true", "yes"].contains(rawValue.lowercased())
        }
#endif
        return Bundle.main.object(forInfoDictionaryKey: "GOBHistoryLearnQuizEnabled") as? Bool ?? false
    }
}

final class AppModel: ObservableObject {
    @Published var content: AppContent {
        didSet {
            lessonStore = ShivajiLessonStore(content: content, defaults: defaults)
        }
    }

    @Published var lessonStore: ShivajiLessonStore {
        didSet { observeLessonStore() }
    }
    @Published var parentSettings: ParentLearningSettings {
        didSet {
            if let data = try? JSONEncoder().encode(parentSettings) {
                defaults.set(data, forKey: Self.settingsKey)
                lessonStore.refreshPersistenceDiagnostics()
            }
        }
    }

    private let defaults: UserDefaults
    private var lessonStoreObservation: AnyCancellable?
    private static let settingsKey = "greatsOfBharatha.parentLearningSettings"

    init(
        content: AppContent = SampleContent.shivajiVerticalSlice,
        defaults: UserDefaults = .standard,
        captureSeedProfile: CaptureSeedProfile? = nil
    ) {
#if DEBUG
        let storageDefaults = captureSeedProfile == nil ? defaults : AppLaunchConfiguration.captureDefaults()
#else
        let storageDefaults = defaults
#endif
        self.defaults = storageDefaults
        self.content = content
        self.parentSettings = storageDefaults.data(forKey: Self.settingsKey)
            .flatMap { try? JSONDecoder().decode(ParentLearningSettings.self, from: $0) }
            ?? ParentLearningSettings()
        self.lessonStore = ShivajiLessonStore(content: content, defaults: storageDefaults)
#if DEBUG
        // A supplied capture seed always uses dedicated storage, even when a caller forgot to inject it.
        if let captureSeedProfile {
            self.lessonStore.applyCaptureSeed(captureSeedProfile)
        }
#endif
        observeLessonStore()
    }

    private func observeLessonStore() {
        lessonStoreObservation = lessonStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

/// Debug automation may choose a named suite; a normal or Release launch always uses real saved data.
enum AppLaunchConfiguration {
    static func defaults(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        captureRoute: DebugNavigationRoute? = nil
    ) -> UserDefaults {
#if DEBUG
        if captureRoute != nil { return captureDefaults() }
        if let suite = environment["GOB_UI_TEST_SUITE"], !suite.isEmpty,
           let defaults = UserDefaults(suiteName: suite) {
            if environment["GOB_UI_TEST_RESET"] == "1" { defaults.removePersistentDomain(forName: suite) }
            return defaults
        }
#endif
        return .standard
    }

    static func captureDefaults() -> UserDefaults {
        UserDefaults(suiteName: "com.ganesh47.greatsofbharatha.debug-capture")!
    }
}
