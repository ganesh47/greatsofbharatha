import SwiftUI

/// The chapter entry and its reteaching use one canonical catalog, saved session and durable adapter.
struct ChapterKnowledgeFlowView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var screen: ChapterKnowledgeEntryMode
    @State private var startingAtBeatID: String?
    let sceneID: String
    let sessionID: UUID

    init(sceneID: String, sessionID: UUID, entry: ChapterKnowledgeEntryMode) {
        self.sceneID = sceneID
        self.sessionID = sessionID
        _screen = State(initialValue: entry)
    }

    private var hooks: ChapterKnowledgeHooks {
        ChapterKnowledgeAdapters.hooks(store: appModel.lessonStore, definitions: ChapterKnowledgeCatalog.definitions)
    }

    var body: some View {
        if let scene = LearnQuizPilotData.scenes.first(where: { $0.id == sceneID }),
           let definition = ChapterKnowledgeCatalog.definition(sceneID: sceneID) {
            switch screen {
            case .teaching:
                ChapterKnowledgeTeachingView(scene: scene, definition: definition, sessionID: sessionID,
                    hooks: hooks, onFinished: { screen = .practice; startingAtBeatID = nil },
                    startingAtBeatID: startingAtBeatID,
                    sourceLookup: ChapterKnowledgeSourceCatalog.source(id:))
            case .practice:
                ChapterKnowledgePracticeView(definition: definition, sessionID: sessionID, hooks: hooks,
                    onNeedsTeaching: { requiredIDs in
                        startingAtBeatID = definition.beats.first { requiredIDs.contains($0.id) }?.id
                        screen = .teaching
                    }, onFinished: { dismiss() })
            }
        } else {
            Text("This chapter is unavailable. Return to your story.")
        }
    }
}

struct ChapterKnowledgeChapterLinks: View {
    let sceneID: String
    let sessionID: UUID
    var initialEntry: ChapterKnowledgeEntryMode?
    @State private var openedInitialEntry = false
    @State private var showingInitialEntry = false

    var body: some View {
        if ChapterKnowledgeCatalog.definition(sceneID: sceneID) != nil {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                Text("More to discover").gbHeadline()
                Text("Explore the chapter’s facts and words, then try four little questions.").gbBody()
                NavigationLink {
                    ChapterKnowledgeFlowView(sceneID: sceneID, sessionID: sessionID, entry: .teaching)
                } label: { Label("Explore chapter facts", systemImage: "book.pages") }
                .buttonStyle(.gbPrimary(.story))
                .accessibilityIdentifier("knowledge-open-teaching-" + sceneID)
                NavigationLink {
                    ChapterKnowledgeFlowView(sceneID: sceneID, sessionID: sessionID, entry: .practice)
                } label: { Label("Practise chapter facts", systemImage: "questionmark.bubble") }
                .buttonStyle(.gbSecondary)
                .accessibilityIdentifier("knowledge-open-practice-" + sceneID)
            }
            .navigationDestination(isPresented: $showingInitialEntry) {
                ChapterKnowledgeFlowView(sceneID: sceneID, sessionID: sessionID, entry: initialEntry ?? .teaching)
            }
            .onAppear {
                guard initialEntry != nil, !openedInitialEntry else { return }
                openedInitialEntry = true
                showingInitialEntry = true
            }
        }
    }
}

/// This wrapper selects a real route family without unlocking chapters or seeding receipts.
struct ChapterKnowledgeDebugRoot: View {
    @EnvironmentObject private var appModel: AppModel
    let entry: ChapterKnowledgeDebugEntry

    var body: some View {
        if entry.route == "pilot", let scene = LearnQuizPilotData.scenes.first(where: { $0.id == entry.sceneID }) {
            LearnNavigationStack {
                SceneLearnView(scene: scene, initialKnowledgeEntry: entry.mode)
            }.accessibilityIdentifier("knowledge-root-pilot")
        } else if let scene = appModel.content.scenes.first(where: { $0.id == entry.sceneID }) {
            NavigationStack {
                SceneLessonView(scene: scene, initialKnowledgeEntry: entry.mode)
            }.accessibilityIdentifier("knowledge-root-story")
        }
    }
}
