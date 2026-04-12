import SwiftUI

struct LessonHomeView: View {
    @EnvironmentObject private var store: ShivajiLessonStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeroProgressCard(progress: store.overallProgress, completedScenes: store.completedScenes, totalScenes: store.totalScenes)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shivaji Arc Vertical Slice")
                            .font(.title2.bold())
                        Text("Two story scenes, one quick recall loop, and a Royal Chronicle reward page.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(Scene.all) { scene in
                        NavigationLink {
                            SceneLessonView(scene: scene)
                        } label: {
                            SceneRowCard(scene: scene, mastery: store.mastery(for: scene.id))
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        RoyalChronicleView()
                    } label: {
                        ChronicleTeaserCard(headline: store.chronicleHeadline, unlockedCount: store.completedScenes)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Greats of Bharatha")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct SceneLessonView: View {
    @EnvironmentObject private var store: ShivajiLessonStore
    let scene: Scene

    @State private var cardIndex = 0
    @State private var selectedChoiceID: String?
    @State private var feedbackText: String?
    @State private var completed = false

    private var progressValue: Double {
        Double(cardIndex + 1) / Double(scene.cards.count + 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SceneHeaderCard(scene: scene, progressValue: progressValue, mastery: store.mastery(for: scene.id))

                TabView(selection: $cardIndex) {
                    ForEach(Array(scene.cards.enumerated()), id: \.offset) { index, card in
                        StoryCardView(card: card, accentName: scene.accentName)
                            .padding(.horizontal, 4)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 280)

                HStack(spacing: 12) {
                    Button("Previous") {
                        cardIndex = max(cardIndex - 1, 0)
                    }
                    .buttonStyle(.bordered)
                    .disabled(cardIndex == 0)

                    Button(cardIndex == scene.cards.count - 1 ? "Continue to recall" : "Next card") {
                        cardIndex = min(cardIndex + 1, scene.cards.count - 1)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                RecallPanel(
                    question: scene.recallQuestion,
                    selectedChoiceID: $selectedChoiceID,
                    feedbackText: feedbackText,
                    completed: completed,
                    onSubmit: submitRecall
                )

                if completed {
                    NavigationLink {
                        RoyalChronicleView(highlightSceneID: scene.id)
                    } label: {
                        Label("Open Royal Chronicle", systemImage: "book.closed.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle(scene.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private func submitRecall() {
        guard let selectedChoiceID else { return }

        if selectedChoiceID == scene.recallQuestion.correctChoiceID {
            completed = true
            feedbackText = scene.recallQuestion.successMessage
            let mastery: MasteryState = cardIndex == scene.cards.count - 1 ? .observedClosely : .understood
            store.markScene(scene.id, mastery: mastery)
        } else {
            completed = false
            feedbackText = scene.recallQuestion.gentleHint
            store.markScene(scene.id, mastery: .witnessed)
        }
    }
}

private struct HeroProgressCard: View {
    let progress: Double
    let completedScenes: Int
    let totalScenes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("First Chronicle Journey")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Learn two key moments, then collect their meaning in the Royal Chronicle.")
                .font(.title3.bold())
            ProgressView(value: progress)
                .tint(.orange)
            Text("\(completedScenes) of \(totalScenes) scenes complete")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.orange.opacity(0.9), .yellow.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .foregroundStyle(.white)
    }
}

private struct SceneRowCard: View {
    let scene: Scene
    let mastery: MasteryState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(scene.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let mastery {
                    Text(mastery.title)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            Label(scene.locationLine, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(scene.keyFact)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ChronicleTeaserCard: View {
    let headline: String
    let unlockedCount: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "book.pages.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Royal Chronicle")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(unlockedCount) reward cards unlocked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SceneHeaderCard: View {
    let scene: Scene
    let progressValue: Double
    let mastery: MasteryState?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(scene.timelineLabel.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(scene.subtitle)
                .font(.title2.bold())
            Text(scene.keyFact)
                .foregroundStyle(.secondary)
            ProgressView(value: progressValue)
                .tint(.orange)
            HStack {
                Label(scene.rewardTitle, systemImage: "medal.fill")
                Spacer()
                Text(mastery?.title ?? "Not yet in Chronicle")
            }
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct StoryCardView: View {
    let card: SceneCard
    let accentName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(card.eyebrow.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Image(systemName: card.symbol)
                .font(.system(size: 42))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.orange.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text(card.title)
                .font(.title3.bold())
            Text(card.body)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(accentName)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.white, Color.orange.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct RecallPanel: View {
    let question: RecallQuestion
    @Binding var selectedChoiceID: String?
    let feedbackText: String?
    let completed: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick recall")
                .font(.headline)
            Text(question.prompt)
                .font(.body)

            ForEach(question.choices) { choice in
                Button {
                    selectedChoiceID = choice.id
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedChoiceID == choice.id ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selectedChoiceID == choice.id ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(choice.title)
                                .foregroundStyle(.primary)
                            Text(choice.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button(completed ? question.successTitle : "Check answer") {
                onSubmit()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedChoiceID == nil)

            if let feedbackText {
                Text(feedbackText)
                    .font(.subheadline)
                    .foregroundStyle(completed ? .green : .secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(completed ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
