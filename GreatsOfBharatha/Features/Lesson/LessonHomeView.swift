import SwiftUI

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    private var nextScene: StoryScene? {
        if let nextSceneID = appModel.lessonStore.nextSceneID {
            return appModel.content.scenes.first(where: { $0.id == nextSceneID })
        }
        return appModel.content.scenes.last
    }

    private var previewedRewardsCount: Int {
        appModel.lessonStore.previewedChronicleCount
    }

    private var unlockedRewardsCount: Int {
        appModel.lessonStore.unlockedChronicleCount
    }

    private var enrichedRewardsCount: Int {
        appModel.lessonStore.enrichedChronicleCount
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    if let nextScene {
                        NavigationLink {
                            SceneLessonView(scene: nextScene)
                        } label: {
                            homeHeroCard(nextScene: nextScene)
                        }
                        .buttonStyle(.plain)
                    }

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Your next move",
                                title: appModel.lessonStore.completedScenes == 0 ? "Tap one path and begin" : "Keep the adventure moving",
                                subtitle: "Each scene is short: three story cards, one memory check, then a new Chronicle keepsake."
                            )

                            HStack(spacing: GBSpacing.small) {
                                JourneyStatPill(title: "Scenes", value: "\(appModel.lessonStore.completedScenes)/\(appModel.lessonStore.totalScenes)", emphasis: .story)
                                JourneyStatPill(title: "Previewed", value: "\(previewedRewardsCount)", emphasis: .story)
                                JourneyStatPill(title: "Earned", value: "\(unlockedRewardsCount)", emphasis: .chronicle)
                                JourneyStatPill(title: "Deepened", value: "\(enrichedRewardsCount)", emphasis: .chronicle)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Adventure path",
                            title: "Choose a story moment",
                            subtitle: "One clear card first, one quick recall next, one reward at the end."
                        )

                        ForEach(appModel.content.scenes) { scene in
                            NavigationLink {
                                SceneLessonView(scene: scene)
                            } label: {
                                SceneJourneyCard(
                                    scene: scene,
                                    reward: appModel.content.rewards.first(where: { $0.id == scene.rewardID }),
                                    mastery: appModel.lessonStore.mastery(for: scene.id),
                                    isNext: scene.id == appModel.lessonStore.nextSceneID
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        ChronicleView(rewards: appModel.content.rewards)
                    } label: {
                        ChronicleJourneyCard(
                            headline: appModel.lessonStore.chronicleHeadline,
                            previewedCount: previewedRewardsCount,
                            unlockedCount: unlockedRewardsCount,
                            enrichedCount: enrichedRewardsCount,
                            totalCount: appModel.content.rewards.count
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Greats of Bharatha")
    }

    private func homeHeroCard(nextScene: StoryScene) -> some View {
        GBHeroCard(
            eyebrow: "Shivaji Maharaj",
            title: appModel.lessonStore.completedScenes == 0 ? "Begin the hill-fort adventure" : "Your next fort is ready",
            subtitle: nextScene.timelineMarker,
            detail: appModel.lessonStore.completedScenes == 0
                ? "Start with one vivid scene, let your first keepsake silhouette appear, then earn it with one recall win."
                : "Jump back in with one short scene, a place clue trail, and Chronicle progress that now tracks previewed, earned, and deepened keepsakes.",
            ctaTitle: appModel.lessonStore.completedScenes == 0 ? "Start Scene \(nextScene.number)" : "Continue journey",
            badgeTitle: appModel.lessonStore.completedScenes == appModel.lessonStore.totalScenes ? "Journey complete" : "Next adventure",
            emphasis: .story,
            progress: appModel.lessonStore.overallProgress
        )
    }
}

private struct JourneyStatPill: View {
    let title: String
    let value: String
    let emphasis: GBEmphasis

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
            Text(title)
                .gbCaption()
                .foregroundStyle(GBColor.Content.secondary)
            Text(value)
                .gbHeadline()
                .foregroundStyle(GBColor.accent(for: emphasis))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GBSpacing.xSmall)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
    }
}

private struct SceneJourneyCard: View {
    let scene: StoryScene
    let reward: ChronicleReward?
    let mastery: MasteryState?
    let isNext: Bool

    var body: some View {
        GBSurface(style: isNext ? .elevated : .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        HStack(spacing: GBSpacing.xxSmall) {
                            GBBadge(title: "Scene \(scene.number)", symbol: GBIcon.story, emphasis: .story)
                            if isNext {
                                GBBadge(title: "Up next", symbol: GBIcon.next, emphasis: .story)
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

                    Spacer()

                    if let mastery {
                        GBBadge(title: mastery.rawValue, symbol: masterySymbol(mastery), emphasis: masteryEmphasis(mastery))
                    }
                }

                HStack(spacing: GBSpacing.small) {
                    miniChip(title: scene.timelineMarker, symbol: "sparkles")
                    if let reward {
                        miniChip(title: reward.title, symbol: GBIcon.chronicle)
                    }
                    miniChip(title: "3 cards + recall", symbol: "square.stack.3d.up.fill")
                }

                HStack {
                    Text(isNext ? "Start this scene" : "Open scene")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GBColor.Content.primary)
                    Spacer()
                    Image(systemName: GBIcon.next)
                        .foregroundStyle(GBColor.Accent.story)
                }
            }
        }
    }

    private func miniChip(title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(GBColor.Content.secondary)
            .padding(.horizontal, GBSpacing.xSmall)
            .padding(.vertical, GBSpacing.xxxSmall)
            .background(GBColor.Background.elevated, in: Capsule())
    }

    private func masterySymbol(_ mastery: MasteryState) -> String {
        switch mastery {
        case .witnessed:
            return "eye.fill"
        case .understood:
            return "star.fill"
        case .observedClosely:
            return "sparkles"
        case .remembered:
            return GBIcon.story
        case .placed:
            return GBIcon.place
        case .chronicled:
            return GBIcon.chronicle
        }
    }

    private func masteryEmphasis(_ mastery: MasteryState) -> GBEmphasis {
        switch mastery {
        case .witnessed:
            return .neutral
        case .understood, .remembered:
            return .story
        case .observedClosely, .chronicled:
            return .chronicle
        case .placed:
            return .place
        }
    }
}

private struct ChronicleJourneyCard: View {
    let headline: String
    let previewedCount: Int
    let unlockedCount: Int
    let enrichedCount: Int
    let totalCount: Int

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            HStack(alignment: .center, spacing: GBSpacing.small) {
                Image(systemName: GBIcon.chronicle)
                    .font(.title2)
                    .foregroundStyle(GBColor.Content.inverse)
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))

                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    Text("Royal Chronicle")
                        .gbHeadline()
                        .foregroundStyle(GBColor.Content.inverse)
                    Text(headline)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.9))
                    Text("Previewed \(previewedCount)  •  Earned \(unlockedCount) of \(totalCount)  •  Deepened \(enrichedCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                }

                Spacer()

                Image(systemName: GBIcon.next)
                    .foregroundStyle(GBColor.Content.inverse)
            }
        }
    }
}
