import SwiftUI

struct LearnQuizHomeView: View {
    @EnvironmentObject private var appModel: AppModel
    private let scenes = LearnQuizPilotData.scenes
    private var learned: [LearnQuizPilotScene] {
        scenes.filter { appModel.lessonStore.mastery(for: $0.id).map { $0 >= .understood } ?? false }
    }
    private var next: LearnQuizPilotScene? {
        scenes.first { appModel.lessonStore.mastery(for: $0.id).map { $0 < .understood } ?? true } ?? scenes.first
    }
    private var reviewCards: [LearnQuizReviewCard] { learned.flatMap(\.reviewCards) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("Learn, remember, build your Chronicle").gbDisplay()
                Text("\(learned.count) of \(scenes.count) opening adventures completed").gbBody()
                if let next {
                    NavigationLink(value: next.id) {
                        Text("Continue: \(next.title)").frame(minHeight: GBTouch.button)
                    }.buttonStyle(.gbPrimary(.story)).accessibilityIdentifier("pilot-home-continue")
                }
                ForEach(scenes) { scene in
                    if let canonical = appModel.content.scenes.first(where: { $0.id == scene.id }),
                       appModel.lessonStore.isSceneUnlocked(canonical) {
                        NavigationLink(value: scene.id) { LearnQuizSceneRow(scene: scene) }
                            .buttonStyle(.plain)
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
        }.background(GBColor.Background.app).navigationTitle("Learn & Play")
        .navigationDestination(for: String.self) { sceneID in
            if let scene = scenes.first(where: { $0.id == sceneID }) {
                SceneLearnView(scene: scene).id(sceneID)
            }
        }
    }
}
