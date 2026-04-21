import SwiftUI

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    private var unlockedRewardsCount: Int {
        appModel.lessonStore.unlockedRewards(from: appModel.content.rewards).count
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    if let nextScene {
                        NavigationLink {
                            SceneLessonView(scene: nextScene)
                        } label: {
                            GBHeroCard(
                                eyebrow: appModel.content.arcTitle,
                                title: appModel.lessonStore.completedScenes == 0 ? "Hear the story first" : "Your story path is still open",
                                subtitle: nextScene.title,
                                detail: "Follow one scene at a time, remember the fort, then add its meaning to your Chronicle.",
                                ctaTitle: appModel.lessonStore.completedScenes == 0 ? "Start Scene 1" : "Continue journey",
                                badgeTitle: appModel.lessonStore.completedScenes == appModel.lessonStore.totalScenes ? "Journey complete" : "Next scene",
                                emphasis: .story,
                                progress: appModel.lessonStore.overallProgress
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Quest",
                                title: "Story to fort to Chronicle",
                                subtitle: "Keep the loop simple: hear one moment, find its fort, then collect the meaning it unlocks."
                            )

                            GBQuestProgress(
                                steps: [.story, .place, .chronicle],
                                currentStepID: unlockedRewardsCount > 0 ? "chronicle" : "story"
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Story Path",
                            title: "Choose a Shivaji Maharaj moment",
                            subtitle: "Only the next unfinished scene opens by default, so kids stay focused on one clear task."
                        )

                        ForEach(appModel.content.scenes) { scene in
                            let isUnlocked = appModel.lessonStore.isSceneUnlocked(scene)
                            let card = SceneRowCard(
                                scene: scene,
                                mastery: appModel.lessonStore.mastery(for: scene.id),
                                isNext: scene.id == appModel.lessonStore.nextSceneID,
                                isLocked: !isUnlocked
                            )

                            Group {
                                if isUnlocked {
                                    NavigationLink {
                                        SceneLessonView(scene: scene)
                                    } label: {
                                        card
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    card
                                }
                            }
                        }
                    }

                    NavigationLink {
                        PlacesHubView(places: appModel.content.corePlaces)
                    } label: {
                        PlacesLoopCard(
                            readyCount: appModel.content.corePlaces.filter { appModel.lessonStore.progress(for: $0) != .locked }.count,
                            totalCount: appModel.content.corePlaces.count
                        )
                    }
                    .buttonStyle(.plain)

                    Group {
                        if unlockedRewardsCount > 0 {
                            NavigationLink {
                                ChronicleView(rewards: appModel.content.rewards)
                            } label: {
                                ChronicleTeaserCard(
                                    headline: appModel.lessonStore.chronicleHeadline,
                                    unlockedCount: unlockedRewardsCount,
                                    totalCount: appModel.content.rewards.count,
                                    isLocked: false
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            ChronicleTeaserCard(
                                headline: "Finish one scene to unlock the first keepsake.",
                                unlockedCount: unlockedRewardsCount,
                                totalCount: appModel.content.rewards.count,
                                isLocked: true
                            )
                        }
                    }
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Greats of Bharatha")
    }

    private var nextScene: StoryScene? {
        if let nextSceneID = appModel.lessonStore.nextSceneID {
            return appModel.content.scenes.first(where: { $0.id == nextSceneID })
        }
        return appModel.content.scenes.last
    }
}

private struct SceneRowCard: View {
    let scene: StoryScene
    let mastery: MasteryState?
    let isNext: Bool
    let isLocked: Bool

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        HStack(spacing: GBSpacing.xxSmall) {
                            GBBadge(title: "Scene \(scene.number)", symbol: GBIcon.story, emphasis: .story)
                            if isNext {
                                GBBadge(title: "Up next", symbol: GBIcon.next, emphasis: .story)
                            }
                            if isLocked {
                                GBBadge(title: "Finish scene \(scene.number - 1) first", symbol: "lock.fill", emphasis: .neutral)
                            }
                        }

                        Text(scene.title)
                            .gbTitle()
                            .foregroundStyle(GBColor.Content.primary)
                            .lineLimit(2)

                        Text(scene.childSafeSummary)
                            .gbBody()
                            .foregroundStyle(GBColor.Content.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: GBSpacing.small)

                    if let mastery {
                        GBBadge(title: mastery.rawValue, symbol: GBIcon.reward, emphasis: .story)
                    }
                }

                HStack(spacing: GBSpacing.small) {
                    Label(scene.timelineMarker, systemImage: GBIcon.timeline)
                    Spacer()
                    Label(isLocked ? "Locked" : (isNext ? "Start" : "Review"), systemImage: isLocked ? "lock.fill" : GBIcon.next)
                        .font(.subheadline.weight(.semibold))
                }
                .font(.subheadline)
                .foregroundStyle(GBColor.Content.secondary)
            }
            .opacity(isLocked ? 0.72 : 1)
        }
    }
}

private struct PlacesLoopCard: View {
    let readyCount: Int
    let totalCount: Int

    var body: some View {
        GBSurface(style: .accented(.place)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text("Find the fort next")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.86))
                        Text("Open the place trail")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse)
                        Text("Keep the story connected to real forts so the journey feels spatial, not just sequential.")
                            .font(.body)
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.9))
                    }

                    Spacer()

                    GBBadge(title: "\(readyCount) of \(totalCount) ready", symbol: GBIcon.place, emphasis: .place)
                }

                Label("See the Sahyadri fort path", systemImage: GBIcon.next)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(GBColor.Content.inverse)
            }
        }
    }
}

private struct ChronicleTeaserCard: View {
    let headline: String
    let unlockedCount: Int
    let totalCount: Int
    let isLocked: Bool

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            HStack(spacing: GBSpacing.small) {
                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    Text("Royal Chronicle")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(GBColor.Content.inverse)
                    Text(headline)
                        .font(.body)
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.9))
                    Text("\(unlockedCount) of \(totalCount) rewards unlocked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                }

                Spacer()

                Image(systemName: isLocked ? "lock.fill" : GBIcon.chronicle)
                    .font(.title2)
                    .foregroundStyle(GBColor.Content.inverse)
            }
        }
        .opacity(isLocked ? 0.82 : 1)
    }
}
