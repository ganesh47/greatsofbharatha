import SwiftUI

struct ChronicleView: View {
    @EnvironmentObject private var appModel: AppModel
    let rewards: [ChronicleReward]
    var highlightRewardID: String?

    @State private var celebratedRewardIDs: Set<String> = []

    private var unlockedRewards: [ChronicleReward] {
        appModel.lessonStore.unlockedRewards(from: rewards)
    }

    private var highlightedReward: ChronicleReward? {
        guard let highlightRewardID else { return nil }
        return unlockedRewards.first(where: { $0.id == highlightRewardID })
    }

    private var lockedRewards: [ChronicleReward] {
        rewards.filter { !appModel.lessonStore.isUnlocked($0) }
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    heroCard

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Quest",
                                title: "Keep the meaning, not just the completion",
                                subtitle: "The Chronicle is where each learned moment becomes a keepsake."
                            )

                            GBQuestProgress(
                                steps: [.story, .place, .chronicle],
                                currentStepID: "chronicle"
                            )
                        }
                    }

                    if let highlightedReward {
                        HighlightRewardCard(
                            reward: highlightedReward,
                            collected: celebratedRewardIDs.contains(highlightedReward.id)
                        ) {
                            celebratedRewardIDs.insert(highlightedReward.id)
                            LessonFeedback.fire(.celebration)
                        }
                    }

                    GBSurface(style: .elevated) {
                        Text("Meaning-bearing rewards for story progress, not anxiety-heavy grades.")
                            .font(.subheadline)
                            .foregroundStyle(GBColor.Content.secondary)
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Unlocked",
                            title: "Rewards already in your Chronicle",
                            subtitle: unlockedRewards.isEmpty ? "Finish a lesson scene to place its meaning into the Royal Chronicle." : "Each reward should remind the child what was learned."
                        )

                        if unlockedRewards.isEmpty {
                            EmptyChronicleCard(debugMasterySummary: debugMasterySummary)
                        } else {
                            ForEach(unlockedRewards) { reward in
                                RewardCard(
                                    reward: reward,
                                    unlocked: true,
                                    isHighlighted: highlightRewardID == reward.id,
                                    isCollected: celebratedRewardIDs.contains(reward.id)
                                )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Locked",
                            title: "Still to unlock",
                            subtitle: "These rewards stay hidden until their linked lesson scene is complete."
                        )

                        ForEach(lockedRewards) { reward in
                            RewardCard(
                                reward: reward,
                                unlocked: false,
                                isHighlighted: false,
                                isCollected: false
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
        .navigationTitle("Royal Chronicle")
    }

    private var heroCard: some View {
        GBHeroCard(
            eyebrow: "Royal Chronicle",
            title: unlockedRewards.isEmpty ? "Your keepsakes will appear here" : "Your Shivaji keepsakes are growing",
            subtitle: appModel.lessonStore.chronicleHeadline,
            detail: "Chronicle rewards should feel ceremonial and specific, tying story progress back to forts, memory, and meaning.",
            ctaTitle: "\(unlockedRewards.count) unlocked",
            badgeTitle: "\(rewards.count) total",
            emphasis: .chronicle,
            progress: rewards.isEmpty ? nil : Double(unlockedRewards.count) / Double(rewards.count)
        )
    }

    private var debugMasterySummary: String {
        let scene1 = appModel.lessonStore.mastery(for: "scene-1-shivneri")?.rawValue ?? "nil"
        let scene2 = appModel.lessonStore.mastery(for: "scene-2-torna-rajgad")?.rawValue ?? "nil"
        return "Debug mastery: \(scene1) / \(scene2)"
    }
}

private struct HighlightRewardCard: View {
    let reward: ChronicleReward
    let collected: Bool
    let onCollect: () -> Void

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "New Reward",
                    title: reward.title,
                    subtitle: reward.meaning,
                    tone: .inverse,
                    trailing: AnyView(GBBadge(title: collected ? "Collected" : "New", symbol: collected ? GBIcon.success : GBIcon.chronicle, emphasis: .chronicle))
                )

                if collected {
                    Label("Added to your Chronicle", systemImage: GBIcon.success)
                        .font(.subheadline)
                        .foregroundStyle(GBColor.Content.inverse)
                } else {
                    Button {
                        onCollect()
                    } label: {
                        Label("Collect reward", systemImage: GBIcon.reward)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.gbSecondary)
                }
            }
        }
    }
}

private struct EmptyChronicleCard: View {
    let debugMasterySummary: String

    var body: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                Text("Finish a lesson scene to place its meaning into the Royal Chronicle.")
                    .font(.subheadline)
                    .foregroundStyle(GBColor.Content.secondary)
                Text(debugMasterySummary)
                    .font(.caption)
                    .foregroundStyle(GBColor.Content.secondary)
            }
        }
    }
}

private struct RewardCard: View {
    let reward: ChronicleReward
    let unlocked: Bool
    let isHighlighted: Bool
    let isCollected: Bool

    var body: some View {
        GBSurface(style: isHighlighted ? .elevated : .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        Text(reward.title)
                            .gbTitle()
                            .foregroundStyle(GBColor.Content.primary)
                        Text(reward.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(GBColor.Content.secondary)
                    }

                    Spacer()

                    if isHighlighted {
                        GBBadge(title: isCollected ? "Collected" : "New", symbol: isCollected ? GBIcon.success : GBIcon.reward, emphasis: .chronicle)
                    } else {
                        GBBadge(title: reward.category.rawValue, symbol: unlocked ? GBIcon.chronicle : GBIcon.locked, emphasis: unlocked ? .chronicle : .neutral)
                    }
                }

                Text(unlocked ? reward.meaning : "Complete the linked lesson scene to reveal this Chronicle reward.")
                    .gbBody()
                    .foregroundStyle(GBColor.Content.primary)

                Label(reward.mastery.rawValue, systemImage: unlocked ? "medal.fill" : GBIcon.locked)
                    .font(.caption)
                    .foregroundStyle(unlocked ? GBColor.Accent.chronicle : GBColor.Content.secondary)
            }
        }
    }
}
