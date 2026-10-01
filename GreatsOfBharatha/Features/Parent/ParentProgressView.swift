import SwiftUI

struct ParentProgressView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.large) {
                Text("Learning together").gbDisplay()
                Text("These are activities recorded in the app. A correct choice can include help; it does not by itself establish lasting recall.").gbStory()
                VStack(alignment: .leading, spacing: GBSpacing.small) {
                    Text("\(appModel.lessonStore.completedScenes) of \(appModel.lessonStore.totalScenes) chapters completed").gbHeadline()
                    Text("\(appModel.content.places.filter { appModel.lessonStore.masteryRecord(for: $0.id)?.evidenceLog.contains(where: { $0.type == .recallSuccess }) == true }.count) places matched to a story clue").gbBody()
                    Text("\(appModel.lessonStore.unlockedChronicleCount) keepsakes earned").gbBody()
                }
                VStack(alignment: .leading, spacing: GBSpacing.medium) {
                    Text("Learning support").gbTitle()
                    Toggle("Assist mode", isOn: settings(\ParentLearningSettings.assistModeEnabled))
                        .accessibilityIdentifier("parent-assist-toggle")
                    Text("Adds a region clue to the fort board and a first clue to the optional Chronicle quiz. Children can always ask for help.").font(.caption)
                    Toggle("Narration support", isOn: settings(\ParentLearningSettings.narrationEnabled))
                        .accessibilityIdentifier("parent-narration-toggle")
                    Text("Turns read-aloud controls on or off. Turning it off stops speech already playing.").font(.caption)
                    Toggle("Calm transitions", isOn: settings(\ParentLearningSettings.calmTransitionsEnabled))
                        .accessibilityIdentifier("parent-calm-toggle")
                    Text("Uses quiet transitions and card changes. Device Reduce Motion also takes priority.").font(.caption)
                }
                Text("A conversation to try").gbTitle()
                Text("Which fort did you discover? What helps you remember why it matters?").gbStory()
                Text("Revisit ideas").gbTitle()
                ForEach(appModel.lessonStore.dueReviews(), id: \.subjectID) { schedule in
                    if let scene = appModel.content.scenes.first(where: { $0.id == schedule.subjectID }),
                       appModel.lessonStore.mastery(for: scene.id).map({ $0 >= .understood }) == true {
                        NavigationLink { SceneLessonView(scene: scene) } label: { Text(scene.title) }
                            .buttonStyle(.bordered)
                    }
                }
                Text("Flashcard responses are self-reports used to plan revisits. Independent recall is recorded separately.").font(.caption)
            }.padding(GBSpacing.medium).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }
        .navigationTitle("Parent settings")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
    private func settings(_ keyPath: WritableKeyPath<ParentLearningSettings, Bool>) -> Binding<Bool> {
        Binding(get: { appModel.parentSettings[keyPath: keyPath] }, set: { appModel.parentSettings[keyPath: keyPath] = $0 })
    }
}
