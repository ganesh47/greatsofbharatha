import Foundation

enum ChapterKnowledgeEntryMode: String {
    case teaching, practice
}

/// Navigation-only test configuration never supplies progress or learning evidence.
struct ChapterKnowledgeDebugEntry {
    let sceneID: String
    let mode: ChapterKnowledgeEntryMode
    let route: String

    static func current(environment: [String: String] = ProcessInfo.processInfo.environment) -> Self? {
#if DEBUG
        let suite = environment["GOB_UI_TEST_SUITE"] ?? ""
        guard suite.hasPrefix("gob.ui.knowledge.") || suite.hasPrefix("gob.tv.ui.knowledge."),
              let sceneID = environment["GOB_UI_TEST_KNOWLEDGE_SCENE_ID"],
              ChapterKnowledgeCatalog.definition(sceneID: sceneID) != nil,
              let rawMode = environment["GOB_UI_TEST_KNOWLEDGE_ENTRY"],
              let mode = ChapterKnowledgeEntryMode(rawValue: rawMode) else { return nil }
        let route = environment["GOB_UI_TEST_KNOWLEDGE_ROUTE"] ?? "story"
        guard ["story", "pilot"].contains(route) else { return nil }
        return Self(sceneID: sceneID, mode: mode, route: route)
#else
        return nil
#endif
    }
}
