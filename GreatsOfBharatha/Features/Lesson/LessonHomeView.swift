import SwiftUI

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroProgressCard(
                    title: appModel.content.arcTitle,
                    progress: appModel.lessonStore.overallProgress,
                    completedScenes: appModel.lessonStore.completedScenes,
                    totalScenes: appModel.lessonStore.totalScenes,
                    nextSceneTitle: nextSceneTitle
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("First playable lesson slice")
                        .font(.title2.bold())
                    Text("Move through story cards, answer a gentle recall prompt, and unlock Chronicle rewards tied to real places.")
                        .foregroundStyle(.secondary)
                }

                ForEach(appModel.content.scenes) { scene in
                    NavigationLink {
                        SceneLessonView(scene: scene)
                    } label: {
                        SceneRowCard(scene: scene, mastery: appModel.lessonStore.mastery(for: scene.id))
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    ChronicleView(rewards: appModel.content.rewards)
                } label: {
                    ChronicleTeaserCard(
                        headline: appModel.lessonStore.chronicleHeadline,
                        unlockedCount: appModel.lessonStore.unlockedRewards(from: appModel.content.rewards).count,
                        totalCount: appModel.content.rewards.count
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Greats of Bharatha")
        .background(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97, opacity: 1.0))
    }

    private var nextSceneTitle: String {
        guard let nextSceneID = appModel.lessonStore.nextSceneID,
              let scene = appModel.content.scenes.first(where: { $0.id == nextSceneID }) else {
            return "Chronicle ready to revisit"
        }
        return "Next up: Scene \(scene.number)"
    }
}

private struct HeroProgressCard: View {
    let title: String
    let progress: Double
    let completedScenes: Int
    let totalScenes: Int
    let nextSceneTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Learn two key moments, then collect their meaning in the Royal Chronicle.")
                .font(.title3.bold())
            ProgressView(value: progress)
                .tint(.orange)
            HStack {
                Text("\(completedScenes) of \(totalScenes) scenes complete")
                Spacer()
                Text(nextSceneTitle)
            }
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
    let scene: StoryScene
    let mastery: MasteryState?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scene \(scene.number)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(scene.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(scene.childSafeSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                if let mastery {
                    Text(mastery.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            Label(scene.timelineMarker, systemImage: "clock.arrow.circlepath")
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
    let totalCount: Int

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
                Text("\(unlockedCount) of \(totalCount) rewards unlocked")
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
