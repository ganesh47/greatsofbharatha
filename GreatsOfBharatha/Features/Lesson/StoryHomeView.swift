import SwiftUI

struct StoryHomeView: View {
    let scenes: [StoryScene]

    var body: some View {
        List {
            Section {
                Text("A calm, story-first vertical slice for the Shivaji Arc.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Scenes 1 to 2") {
                ForEach(scenes) { scene in
                    NavigationLink {
                        SceneDetailView(scene: scene)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Scene \(scene.number)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(scene.title)
                                .font(.headline)
                            Text(scene.childSafeSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Shivaji Arc")
    }
}

struct SceneDetailView: View {
    let scene: StoryScene

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scene \(scene.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(scene.title)
                        .font(.largeTitle.bold())
                    Text(scene.childSafeSummary)
                        .font(.body)
                }

                detailCard(title: "Narrative objective", body: scene.narrativeObjective)
                detailCard(title: "Key fact", body: scene.keyFact)
                detailCard(title: "Timeline marker", body: scene.timelineMarker)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Map anchors")
                        .font(.headline)
                    ForEach(scene.mapAnchors, id: \.self) { anchor in
                        Label(anchor, systemImage: "mappin.and.ellipse")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Flow steps")
                        .font(.headline)
                    ForEach(Array(scene.interactionSteps.enumerated()), id: \.offset) { step in
                        Label(step.element, systemImage: "checkmark.circle")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recall prompt")
                        .font(.headline)
                    Text(scene.recallPrompt.question)
                        .font(.body.weight(.semibold))
                    Text("Expected answer: \(scene.recallPrompt.answer)")
                    Text(scene.recallPrompt.supportText)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Scene \(scene.number)")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func detailCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
