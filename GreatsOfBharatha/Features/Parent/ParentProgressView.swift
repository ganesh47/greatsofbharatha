import SwiftUI

struct ParentProgressView: View {
    @EnvironmentObject private var appModel: AppModel

    private var dueReviews: [ReviewSchedule] {
        appModel.lessonStore.dueReviews()
    }

    private var upcomingReviews: [ReviewSchedule] {
        appModel.lessonStore.upcomingReviews(limit: 4)
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    heroCard

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Progress Snapshot",
                                title: "What the child now knows",
                                subtitle: "A calm adult-facing view of retrieval progress, place confidence, Chronicle growth, and revisit readiness."
                            )

                            HStack(spacing: GBSpacing.small) {
                                ParentMetricCard(title: "Scenes", value: "\(appModel.lessonStore.completedScenes)/\(max(appModel.lessonStore.totalScenes, 1))", detail: "story understanding", emphasis: .story)
                                ParentMetricCard(title: "Places", value: "\(appModel.lessonStore.masteredPlaceCount)/\(max(appModel.lessonStore.totalCorePlaces, 1))", detail: "mastered lightly", emphasis: .place)
                            }

                            HStack(spacing: GBSpacing.small) {
                                ParentMetricCard(title: "Chronicle", value: "\(appModel.lessonStore.unlockedChronicleCount)/\(max(appModel.lessonStore.totalChronicleEntries, 1))", detail: "earned keepsakes", emphasis: .chronicle)
                                ParentMetricCard(title: "Due", value: "\(appModel.lessonStore.dueReviewCount)", detail: "short revisits", emphasis: .neutral)
                            }
                        }
                    }

                    progressSections
                    settingsSection
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Parent")
    }

    private var heroCard: some View {
        GBHeroCard(
            eyebrow: "Parent View",
            title: "Progress without child-path clutter",
            subtitle: appModel.lessonStore.parentProgressHeadline,
            detail: appModel.lessonStore.retrievalExplanation,
            ctaTitle: dueReviews.isEmpty ? "Learning is on track" : "\(dueReviews.count) revisit prompt\(dueReviews.count == 1 ? "" : "s") ready",
            badgeTitle: "retrieval-first",
            emphasis: .neutral,
            progress: appModel.lessonStore.overallProgress
        )
    }

    @ViewBuilder
    private var progressSections: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(
                eyebrow: "Learning Value",
                title: "Why this progress matters",
                subtitle: "The child-facing path stays playful. This surface explains the educational meaning in direct adult language."
            )

            ParentNarrativeCard(
                title: "Hero progress",
                badge: "\(appModel.lessonStore.completedScenes) scenes understood",
                emphasis: .story,
                message: appModel.lessonStore.completedScenes == 0
                    ? "The child has not yet reached the first understanding checkpoint."
                    : "The child is recalling story meaning well enough to move through \(appModel.lessonStore.completedScenes) of \(appModel.lessonStore.totalScenes) scenes without needing the path to become adult-heavy."
            )

            ParentNarrativeCard(
                title: "Place confidence",
                badge: "\(appModel.lessonStore.readyOrBetterPlaceCount) places opened",
                emphasis: .place,
                message: appModel.lessonStore.masteredPlaceCount == 0
                    ? "Place learning is unlocked gradually so geography stays forgiving and identity comes before precision."
                    : "\(appModel.lessonStore.masteredPlaceCount) core places are now holding with light mastery, which means the child is connecting story moments to geography."
            )

            ParentNarrativeCard(
                title: "Chronicle meaning",
                badge: "\(appModel.lessonStore.unlockedChronicleCount) keepsakes earned",
                emphasis: .chronicle,
                message: appModel.lessonStore.unlockedChronicleCount == 0
                    ? "Chronicle keepsakes stay silhouetted until the child recalls enough meaning to earn them."
                    : "Chronicle progress signals that meaning is being retrieved, not just exposed, which is why the reward shelf now reflects remembered understanding."
            )
        }

        reviewSection
    }

    @ViewBuilder
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(
                eyebrow: "Revisit Status",
                title: dueReviews.isEmpty ? "Nothing is overdue right now" : "Short revisits are ready",
                subtitle: dueReviews.isEmpty
                    ? "Upcoming retrieval prompts are scheduled to bring knowledge back before it fades."
                    : "These are calm return points, meant to strengthen memory without pressure."
            )

            if dueReviews.isEmpty {
                ForEach(upcomingReviews, id: \.subjectID) { schedule in
                    ParentReviewCard(title: title(for: schedule), schedule: schedule, isDue: false)
                }
            } else {
                ForEach(dueReviews, id: \.subjectID) { schedule in
                    ParentReviewCard(title: title(for: schedule), schedule: schedule, isDue: true)
                }
            }
        }
    }

    private var settingsSection: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Child-safe settings hooks",
                    title: "Support without over-directing",
                    subtitle: "These are hook points for adult choices around help, narration, and calmer transitions."
                )

                Toggle("Assist mode", isOn: settingBinding(\ParentLearningSettings.assistModeEnabled))
                Toggle("Narration support", isOn: settingBinding(\ParentLearningSettings.narrationEnabled))
                Toggle("Calm transitions", isOn: settingBinding(\ParentLearningSettings.calmTransitionsEnabled))
            }
        }
    }

    private func settingBinding(_ keyPath: WritableKeyPath<ParentLearningSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { appModel.parentSettings[keyPath: keyPath] },
            set: { appModel.parentSettings[keyPath: keyPath] = $0 }
        )
    }

    private func title(for schedule: ReviewSchedule) -> String {
        switch schedule.subjectType {
        case .scene:
            return appModel.content.activeHeroArc.scene(withID: schedule.subjectID)?.title ?? schedule.subjectID
        case .location:
            return appModel.content.activeHeroArc.locationNode(withID: schedule.subjectID)?.name ?? schedule.subjectID
        case .timeline:
            return appModel.content.activeHeroArc.timelineEvent(withID: schedule.subjectID)?.title ?? schedule.subjectID
        case .chronicle:
            return appModel.content.activeHeroArc.chronicleEntry(withID: schedule.subjectID)?.title ?? schedule.subjectID
        }
    }
}

private struct ParentMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let emphasis: GBEmphasis

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
            Text(title)
                .gbCaption()
                .foregroundStyle(GBColor.Content.secondary)
            Text(value)
                .gbHeadline()
                .foregroundStyle(GBColor.accent(for: emphasis))
            Text(detail)
                .font(.caption)
                .foregroundStyle(GBColor.Content.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GBSpacing.xSmall)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
    }
}

private struct ParentNarrativeCard: View {
    let title: String
    let badge: String
    let emphasis: GBEmphasis
    let message: String

    var bodyView: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    Text(title)
                        .gbTitle()
                    Spacer()
                    GBBadge(title: badge, symbol: badgeSymbol, emphasis: emphasis)
                }

                Text(message)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)
            }
        }
    }

    var body: some View { bodyView }

    private var badgeSymbol: String {
        switch emphasis {
        case .story:
            return GBIcon.story
        case .place:
            return GBIcon.place
        case .chronicle:
            return GBIcon.chronicle
        case .neutral:
            return GBIcon.timeline
        }
    }
}

private struct ParentReviewCard: View {
    let title: String
    let schedule: ReviewSchedule
    let isDue: Bool

    var body: some View {
        GBSurface(style: isDue ? .plain : .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: isDue ? "Due now" : "Upcoming", symbol: isDue ? GBIcon.timeline : GBIcon.next, emphasis: isDue ? .chronicle : .neutral)
                    Spacer()
                    Text(schedule.stabilityBand.rawValue.capitalized)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Content.secondary)
                }

                Text(title)
                    .gbTitle()
                Text(detailText)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)
            }
        }
    }

    private var detailText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let when = formatter.localizedString(for: schedule.nextDueAt, relativeTo: Date())
        return "\(subjectLabel) revisit, interval \(schedule.intervalIndex + 1), \(when)."
    }

    private var subjectLabel: String {
        switch schedule.subjectType {
        case .scene:
            return "Scene"
        case .location:
            return "Place"
        case .timeline:
            return "Timeline"
        case .chronicle:
            return "Chronicle"
        }
    }
}
