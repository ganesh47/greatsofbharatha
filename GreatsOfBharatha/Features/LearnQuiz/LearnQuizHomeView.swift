import SwiftUI

struct LearnQuizHomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var navigation: LearnNavigationCoordinator
    private let scenes = LearnQuizPilotData.scenes
    private var learned: [LearnQuizPilotScene] {
        scenes.filter { appModel.lessonStore.mastery(for: $0.id).map { $0 >= .understood } ?? false }
    }
    private var next: LearnQuizPilotScene? {
        let unlocked = scenes.filter { scene in
            guard let canonical = appModel.content.scenes.first(where: { $0.id == scene.id }),
                  appModel.lessonStore.isSceneUnlocked(canonical) else { return false }
            return true
        }
        let unfinishedMatch = LearnQuizMatchingResume.nextScene(in: unlocked,
            resumePoints: unlocked.compactMap { appModel.lessonStore.resumePoint(for: $0.id) })
        if let unfinishedMatch { return unfinishedMatch }
        return scenes.first { appModel.lessonStore.mastery(for: $0.id).map { $0 < .understood } ?? true } ?? scenes.first
    }
    private var reviewCards: [LearnQuizReviewCard] { learned.flatMap(\.reviewCards) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("Learn, remember, build your Chronicle").gbDisplay()
                Text("\(learned.count) of \(scenes.count) opening adventures completed").gbBody()
                if let next {
                    Button { navigation.path.append(next.id) } label: {
                        Text("Continue: \(next.title)").frame(minHeight: GBTouch.button)
                    }.buttonStyle(.gbPrimary(.story)).accessibilityIdentifier("pilot-home-continue")
                }
                ForEach(scenes) { scene in
                    if let canonical = appModel.content.scenes.first(where: { $0.id == scene.id }),
                       appModel.lessonStore.isSceneUnlocked(canonical) {
                        NavigationLink(value: scene.id) { LearnQuizSceneRow(scene: scene) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("pilot-home-scene-" + scene.id)
                    } else { Text("\(scene.title) — ready after the previous adventure").gbBody() }
                }
                if !learned.isEmpty {
                    NavigationLink { ChronicleMatchView(scenes: learned) } label: {
                        Label("Match the places you learned", systemImage: "square.grid.2x2.fill")
                    }.buttonStyle(.gbPrimary(.place))
                    NavigationLink { FlashcardReviewView(cards: reviewCards) } label: {
                        Label("Review my story cards", systemImage: "rectangle.on.rectangle")
                    }.buttonStyle(.gbSecondary)
                }
                NavigationLink { ChronicleBookView(scenes: scenes) } label: {
                    Label("Open my Chronicle", systemImage: "book.closed.fill")
                }.buttonStyle(.gbPrimary(.chronicle))
            }.padding(GBSpacing.medium).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.accessibilityIdentifier("pilot-home-scroll").background(GBColor.Background.app).navigationTitle("Learn & Play")
        .navigationDestination(for: String.self) { sceneID in
            if let scene = scenes.first(where: { $0.id == sceneID }) {
                SceneLearnView(scene: scene).id(sceneID)
            }
        }
    }
}

/// Combined boards save one checkpoint per scene. The selected card's owner
/// takes priority over the order in which those checkpoints were written.
enum LearnQuizMatchingResume {
    private struct Candidate {
        let scene: LearnQuizPilotScene
        let point: LessonResumePoint
        let hasSelection: Bool
    }

    static func nextScene(in scenes: [LearnQuizPilotScene], resumePoints: [LessonResumePoint]) -> LearnQuizPilotScene? {
        let candidates = scenes.compactMap { scene -> Candidate? in
            guard let point = resumePoints.first(where: { $0.sceneID == scene.id }), point.preferredActivity == .match,
                  scene.matchPairs.contains(where: { !point.completedMatchPairIDs.contains($0.id) }) else { return nil }
            let hasSelection = scene.matchPairs.contains { pair in
                !point.completedMatchPairIDs.contains(pair.id) &&
                    (point.selectedMatchTileID == pair.leftID || point.selectedMatchTileID == pair.rightID)
            }
            return Candidate(scene: scene, point: point, hasSelection: hasSelection)
        }
        return candidates.max { first, second in
            if first.hasSelection != second.hasSelection { return !first.hasSelection && second.hasSelection }
            return first.point.updatedAt < second.point.updatedAt
        }?.scene
    }
}
