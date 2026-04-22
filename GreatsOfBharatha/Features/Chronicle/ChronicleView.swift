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
                    chronicleHero

                    if let highlightedReward {
                        NewRewardSpotlight(
                            reward: highlightedReward,
                            collected: celebratedRewardIDs.contains(highlightedReward.id),
                            onCollect: {
                                celebratedRewardIDs.insert(highlightedReward.id)
                                LessonFeedback.fire(.celebration)
                            }
                        )
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Collected keepsakes",
                            title: unlockedRewards.isEmpty ? "Your Chronicle is waiting" : "Your Chronicle shelf",
                            subtitle: unlockedRewards.isEmpty
                                ? "Finish a scene and remember its hook to place your first keepsake here."
                                : "Each keepsake marks a part of Shivaji Maharaj's journey you remembered."
                        )

                        if unlockedRewards.isEmpty {
                            GBSurface(style: .elevated) {
                                Text("Play a short scene, answer the recall card, and your first Chronicle page will open here.")
                                    .gbBody()
                                    .foregroundStyle(GBColor.Content.secondary)
                            }
                        } else {
                            ForEach(unlockedRewards) { reward in
                                RewardShelfCard(
                                    reward: reward,
                                    unlocked: true,
                                    isHighlighted: reward.id == highlightRewardID,
                                    collected: celebratedRewardIDs.contains(reward.id)
                                )
                            }
                        }
                    }

                    if !lockedRewards.isEmpty {
                        VStack(alignment: .leading, spacing: context.cardSpacing) {
                            GBSectionHeader(
                                eyebrow: "Still ahead",
                                title: "More keepsakes to earn",
                                subtitle: "New Chronicle cards will appear as you finish more story scenes."
                            )

                            ForEach(lockedRewards) { reward in
                                RewardShelfCard(
                                    reward: reward,
                                    unlocked: false,
                                    isHighlighted: false,
                                    collected: false
                                )
                            }
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

    private var chronicleHero: some View {
        GBHeroCard(
            eyebrow: "Royal Chronicle",
            title: unlockedRewards.isEmpty ? "Collect your first keepsake" : "Your remembered story shelf",
            subtitle: unlockedRewards.isEmpty ? "Short scenes unlock lasting rewards." : "\(unlockedRewards.count) keepsakes already glow here.",
            detail: unlockedRewards.isEmpty
                ? "Remember one story hook from the lesson path and a Chronicle page opens for you."
                : "Each new card marks a piece of story, place, or meaning you held onto from memory.",
            ctaTitle: unlockedRewards.isEmpty ? "Begin a scene" : "Keep collecting",
            badgeTitle: "\(unlockedRewards.count) unlocked",
            emphasis: .chronicle,
            progress: rewards.isEmpty ? nil : Double(unlockedRewards.count) / Double(rewards.count)
        )
    }
}

private struct NewRewardSpotlight: View {
    let reward: ChronicleReward
    let collected: Bool
    let onCollect: () -> Void

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: collected ? "Collected" : "New reward", symbol: collected ? GBIcon.success : GBIcon.reward, emphasis: .chronicle)
                    Spacer()
                    Text(reward.category.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
                }

                Text(reward.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(GBColor.Content.inverse)
                Text(reward.subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(GBColor.Content.inverse.opacity(0.96))
                Text(reward.meaning)
                    .font(.body)
                    .foregroundStyle(GBColor.Content.inverse.opacity(0.9))

                if collected {
                    Label("Added to your Chronicle shelf", systemImage: GBIcon.success)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GBColor.Content.inverse)
                } else {
                    Button {
                        onCollect()
                    } label: {
                        Label("Collect keepsake", systemImage: GBIcon.reward)
                    }
                    .buttonStyle(.gbSecondary)
                }
            }
        }
    }
}

private struct RewardShelfCard: View {
    let reward: ChronicleReward
    let unlocked: Bool
    let isHighlighted: Bool
    let collected: Bool

    var body: some View {
        GBSurface(style: unlocked ? .plain : .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        HStack(spacing: GBSpacing.xxSmall) {
                            GBBadge(
                                title: unlocked ? reward.mastery.rawValue : "Locked",
                                symbol: unlocked ? GBIcon.success : GBIcon.locked,
                                emphasis: unlocked ? .chronicle : .neutral
                            )

                            if isHighlighted {
                                GBBadge(title: collected ? "Collected" : "New", symbol: collected ? GBIcon.success : GBIcon.reward, emphasis: .story)
                            }
                        }

                        Text(reward.title)
                            .gbTitle()
                            .foregroundStyle(GBColor.Content.primary)
                        Text(reward.subtitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GBColor.Content.secondary)
                    }

                    Spacer()

                    Image(systemName: unlocked ? GBIcon.chronicle : GBIcon.locked)
                        .font(.title2)
                        .foregroundStyle(unlocked ? GBColor.Accent.chronicle : GBColor.State.locked)
                }

                Text(unlocked ? reward.meaning : "Finish the linked story scene and answer its recall card to reveal this keepsake.")
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)

                Text(reward.category.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GBColor.accent(for: unlocked ? .chronicle : .neutral))
            }
        }
    }
}
