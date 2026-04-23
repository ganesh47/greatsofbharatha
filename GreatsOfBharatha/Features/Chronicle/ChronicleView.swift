import SwiftUI

struct ChronicleView: View {
    @EnvironmentObject private var appModel: AppModel
    let rewards: [ChronicleReward]
    var highlightRewardID: String?

    @State private var celebratedRewardIDs: Set<String> = []

    private var previewedRewards: [ChronicleReward] {
        rewards.filter { appModel.lessonStore.isPreviewed($0) && !appModel.lessonStore.isUnlocked($0) }
    }

    private var earnedRewards: [ChronicleReward] {
        rewards.filter { reward in
            guard appModel.lessonStore.isUnlocked(reward) else { return false }
            return !isEnriched(reward)
        }
    }

    private var deepenedRewards: [ChronicleReward] {
        rewards.filter(isEnriched)
    }

    private var hiddenRewards: [ChronicleReward] {
        rewards.filter { !appModel.lessonStore.isPreviewed($0) && !appModel.lessonStore.isUnlocked($0) }
    }

    private var highlightedReward: ChronicleReward? {
        guard let highlightRewardID else { return nil }
        return rewards.first(where: { $0.id == highlightRewardID && appModel.lessonStore.isUnlocked($0) })
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    chronicleHero

                    if let highlightedReward {
                        NewRewardSpotlight(
                            reward: highlightedReward,
                            state: shelfState(for: highlightedReward),
                            linkedSceneTitle: linkedSceneTitle(for: highlightedReward),
                            collected: celebratedRewardIDs.contains(highlightedReward.id),
                            onCollect: {
                                celebratedRewardIDs.insert(highlightedReward.id)
                                LessonFeedback.fire(.celebration)
                            }
                        )
                    }

                    if !previewedRewards.isEmpty {
                        shelfSection(
                            eyebrow: "Taking shape",
                            title: "Previewed silhouettes",
                            subtitle: "You have seen these moments in the story. Answer the recall card to reveal their meaning.",
                            rewards: previewedRewards,
                            state: .previewed
                        )
                    }

                    if !earnedRewards.isEmpty {
                        shelfSection(
                            eyebrow: "Kept from memory",
                            title: "Earned keepsakes",
                            subtitle: "These Chronicle cards opened because you remembered the scene, not just because you saw it.",
                            rewards: earnedRewards,
                            state: .earned
                        )
                    }

                    if !deepenedRewards.isEmpty {
                        shelfSection(
                            eyebrow: "Held more deeply",
                            title: "Deepened keepsakes",
                            subtitle: "These entries now carry richer meaning because your mastery went beyond the first unlock.",
                            rewards: deepenedRewards,
                            state: .deepened
                        )
                    }

                    if !hiddenRewards.isEmpty {
                        shelfSection(
                            eyebrow: "Still sealed",
                            title: "More keepsakes ahead",
                            subtitle: "These entries will appear after their story moments surface in the lesson journey.",
                            rewards: hiddenRewards,
                            state: .hidden
                        )
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
            title: appModel.lessonStore.unlockedChronicleCount == 0 ? "Your keepsakes are taking shape" : "A shelf of remembered meaning",
            subtitle: "Previewed: \(appModel.lessonStore.previewedChronicleCount)  •  Earned: \(appModel.lessonStore.unlockedChronicleCount)  •  Deepened: \(appModel.lessonStore.enrichedChronicleCount)",
            detail: appModel.lessonStore.unlockedChronicleCount == 0
                ? "Story exposure lets a keepsake silhouette appear. Real Chronicle unlocks begin when you answer from memory."
                : "The Chronicle now tracks what you have merely seen, what you have truly earned, and what you understand more deeply.",
            ctaTitle: appModel.lessonStore.unlockedChronicleCount == 0 ? "Earn a keepsake" : "Keep deepening",
            badgeTitle: "\(appModel.lessonStore.unlockedChronicleCount)/\(max(appModel.lessonStore.totalChronicleEntries, 1)) earned",
            emphasis: .chronicle,
            progress: appModel.lessonStore.totalChronicleEntries == 0 ? nil : Double(appModel.lessonStore.unlockedChronicleCount) / Double(appModel.lessonStore.totalChronicleEntries)
        )
    }

    @ViewBuilder
    private func shelfSection(
        eyebrow: String,
        title: String,
        subtitle: String,
        rewards: [ChronicleReward],
        state: ChronicleShelfState
    ) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(eyebrow: eyebrow, title: title, subtitle: subtitle)

            ForEach(rewards) { reward in
                ChronicleShelfCard(
                    reward: reward,
                    state: state,
                    linkedSceneTitle: linkedSceneTitle(for: reward),
                    isHighlighted: reward.id == highlightRewardID,
                    collected: celebratedRewardIDs.contains(reward.id)
                )
            }
        }
    }

    private func linkedSceneTitle(for reward: ChronicleReward) -> String {
        appModel.content.scenes.first(where: { $0.id == reward.unlockedBySceneID })?.title ?? "A story moment"
    }

    private func isEnriched(_ reward: ChronicleReward) -> Bool {
        guard let entry = appModel.content.activeHeroArc.chronicleEntry(withID: reward.id) else {
            return false
        }
        return appModel.lessonStore.chronicleUnlockState(for: entry) == .enriched
    }

    private func shelfState(for reward: ChronicleReward) -> ChronicleShelfState {
        if isEnriched(reward) {
            return .deepened
        }
        if appModel.lessonStore.isUnlocked(reward) {
            return .earned
        }
        if appModel.lessonStore.isPreviewed(reward) {
            return .previewed
        }
        return .hidden
    }
}

private enum ChronicleShelfState {
    case hidden
    case previewed
    case earned
    case deepened
}

private struct NewRewardSpotlight: View {
    let reward: ChronicleReward
    let state: ChronicleShelfState
    let linkedSceneTitle: String
    let collected: Bool
    let onCollect: () -> Void

    var body: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: spotlightTitle, symbol: collected ? GBIcon.success : GBIcon.reward, emphasis: .chronicle)
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
                Text(reasonText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(GBColor.Content.inverse.opacity(0.88))

                if collected {
                    Label("Added to your Chronicle shelf", systemImage: GBIcon.success)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GBColor.Content.inverse)
                } else {
                    Button(action: onCollect) {
                        Label(state == .deepened ? "Collect deepened keepsake" : "Collect keepsake", systemImage: GBIcon.reward)
                    }
                    .buttonStyle(.gbSecondary)
                }
            }
        }
    }

    private var spotlightTitle: String {
        switch state {
        case .deepened:
            return "Deepened keepsake"
        case .earned:
            return "New keepsake"
        case .previewed:
            return "Previewed keepsake"
        case .hidden:
            return "Chronicle keepsake"
        }
    }

    private var reasonText: String {
        switch state {
        case .deepened:
            return "You remembered \(linkedSceneTitle) strongly enough to deepen this keepsake's meaning."
        case .earned:
            return "You earned this by recalling \(linkedSceneTitle), not just by opening the scene."
        case .previewed:
            return "You have seen the story moment for \(linkedSceneTitle), but this keepsake still needs a recall win."
        case .hidden:
            return linkedSceneTitle
        }
    }
}

private struct ChronicleShelfCard: View {
    let reward: ChronicleReward
    let state: ChronicleShelfState
    let linkedSceneTitle: String
    let isHighlighted: Bool
    let collected: Bool

    var body: some View {
        GBSurface(style: surfaceStyle) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        HStack(spacing: GBSpacing.xxSmall) {
                            GBBadge(title: badgeTitle, symbol: badgeSymbol, emphasis: badgeEmphasis)
                            if isHighlighted {
                                GBBadge(title: collected ? "Collected" : "New", symbol: collected ? GBIcon.success : GBIcon.reward, emphasis: .story)
                            }
                        }

                        Text(reward.title)
                            .gbTitle()
                            .foregroundStyle(titleColor)
                        Text(reward.subtitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GBColor.Content.secondary)
                    }

                    Spacer()

                    Image(systemName: badgeSymbol)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                }

                Text(primaryText)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)

                Text("From: \(linkedSceneTitle)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GBColor.accent(for: badgeEmphasis))
            }
            .opacity(state == .hidden ? 0.82 : 1)
        }
    }

    private var surfaceStyle: GBSurfaceStyle {
        switch state {
        case .hidden, .previewed:
            return .elevated
        case .earned:
            return .plain
        case .deepened:
            return .accented(.chronicle)
        }
    }

    private var badgeTitle: String {
        switch state {
        case .hidden:
            return "Sealed"
        case .previewed:
            return "Previewed"
        case .earned:
            return "Earned"
        case .deepened:
            return "Deepened"
        }
    }

    private var badgeSymbol: String {
        switch state {
        case .hidden:
            return GBIcon.locked
        case .previewed:
            return "eye.fill"
        case .earned:
            return GBIcon.chronicle
        case .deepened:
            return GBIcon.success
        }
    }

    private var badgeEmphasis: GBEmphasis {
        switch state {
        case .hidden:
            return .neutral
        case .previewed:
            return .story
        case .earned, .deepened:
            return .chronicle
        }
    }

    private var titleColor: Color {
        state == .deepened ? GBColor.Content.inverse : GBColor.Content.primary
    }

    private var iconColor: Color {
        switch state {
        case .deepened:
            return GBColor.Content.inverse
        case .earned:
            return GBColor.Accent.chronicle
        case .previewed:
            return GBColor.Accent.story
        case .hidden:
            return GBColor.State.locked
        }
    }

    private var primaryText: String {
        switch state {
        case .hidden:
            return "This keepsake has not appeared in the story yet. Reach its scene to let the silhouette appear."
        case .previewed:
            return "You have seen this story moment, but the Chronicle only opens the keepsake after a successful recall."
        case .earned:
            return reward.meaning
        case .deepened:
            return reward.meaning + " This keepsake now carries a deeper Chronicle glow because your mastery went beyond the first unlock."
        }
    }
}
