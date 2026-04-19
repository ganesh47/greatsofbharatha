import SwiftUI

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let nextScene {
                    NavigationLink {
                        SceneLessonView(scene: nextScene)
                    } label: {
                        HeroProgressCard(
                            title: appModel.content.arcTitle,
                            progress: appModel.lessonStore.overallProgress,
                            completedScenes: appModel.lessonStore.completedScenes,
                            totalScenes: appModel.lessonStore.totalScenes,
                            nextSceneTitle: nextScene.title,
                            ctaTitle: appModel.lessonStore.completedScenes == 0 ? "Start Scene 1" : "Continue journey"
                        )
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose a moment from Shivaji Maharaj's journey.")
                        .font(.title3.bold())
                    Text("Short story steps, place clues, and one quick recall help each scene feel easy to finish.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(appModel.content.scenes) { scene in
                    NavigationLink {
                        SceneLessonView(scene: scene)
                    } label: {
                        SceneRowCard(
                            scene: scene,
                            mastery: appModel.lessonStore.mastery(for: scene.id),
                            isNext: scene.id == appModel.lessonStore.nextSceneID
                        )
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
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var nextScene: StoryScene? {
        if let nextSceneID = appModel.lessonStore.nextSceneID {
            return appModel.content.scenes.first(where: { $0.id == nextSceneID })
        }
        return appModel.content.scenes.last
    }
}

private struct HeroProgressCard: View {
    let title: String
    let progress: Double
    let completedScenes: Int
    let totalScenes: Int
    let nextSceneTitle: String
    let ctaTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()
                Text(completedScenes == totalScenes ? "Journey complete" : "Next adventure")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18), in: Capsule())
            }

            Text(completedScenes == 0 ? "Begin Shivaji Maharaj's journey." : "Your journey continues.")
                .font(.title2.bold())
            Text(nextSceneTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.96))
            Text("Explore the story, spot the places, and earn a Chronicle reward.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))

            ProgressView(value: progress)
                .tint(.white)

            HStack {
                Text("\(completedScenes) of \(totalScenes) scenes complete")
                Spacer()
                Label(ctaTitle, systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.bold())
            }
            .font(.subheadline)
            .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.orange.opacity(0.95), .yellow.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct SceneRowCard: View {
    let scene: StoryScene
    let mastery: MasteryState?
    let isNext: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Scene \(scene.number)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        if isNext {
                            Text("Up next")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                                .foregroundStyle(.orange)
                        }
                    }
                    Text(scene.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(scene.childSafeSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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

            HStack(spacing: 12) {
                Label(scene.timelineMarker, systemImage: "clock.arrow.circlepath")
                Spacer()
                Label(isNext ? "Start" : "Review", systemImage: "arrow.right")
                    .font(.subheadline.bold())
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
