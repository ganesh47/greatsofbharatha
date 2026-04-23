import SwiftUI

struct TimelineHubView: View {
    @EnvironmentObject private var appModel: AppModel

    private var timelineEvents: [TimelineEvent] {
        appModel.content.activeHeroArc.timelineEvents.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var dueReviews: [ReviewSchedule] {
        appModel.lessonStore.dueReviews()
    }

    private var upcomingReviews: [ReviewSchedule] {
        appModel.lessonStore.upcomingReviews(limit: 3)
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    heroCard

                    GBSurface(style: .elevated) {
                        HStack(spacing: GBSpacing.small) {
                            TimelineSummaryPill(title: "Ready", value: "\(appModel.lessonStore.unlockedTimelineCount)", emphasis: .story)
                            TimelineSummaryPill(title: "Mastered", value: "\(appModel.lessonStore.masteredTimelineCount)", emphasis: .place)
                            TimelineSummaryPill(title: "Due now", value: "\(dueReviews.count)", emphasis: .chronicle)
                        }
                    }

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Quest",
                                title: "Order the journey before exact dates",
                                subtitle: "The timeline turns separate scenes into one remembered arc, then feeds due items back into short review runs."
                            )

                            HStack(spacing: GBSpacing.small) {
                                timelineChip(title: "Story order first", symbol: GBIcon.story, emphasis: .story)
                                timelineChip(title: "Place links", symbol: GBIcon.place, emphasis: .place)
                                timelineChip(title: "Review returns", symbol: GBIcon.timeline, emphasis: .chronicle)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Hero Timeline",
                            title: "Walk the Shivaji arc in order",
                            subtitle: "Each marker teaches what came first, what came next, and which place anchors the moment."
                        )

                        ForEach(timelineEvents) { event in
                            TimelineEventCard(event: event)
                        }
                    }

                    reviewQueueSection
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Timeline")
    }

    private var heroCard: some View {
        GBHeroCard(
            eyebrow: "Hero Timeline",
            title: "Put the journey in living order",
            subtitle: appModel.lessonStore.timelineHeadline,
            detail: "Start with broad sequence, then use quick review returns to keep forts, turning points, and recovery moments connected.",
            ctaTitle: dueReviews.isEmpty ? "Trace the next marker" : "Run due reviews",
            badgeTitle: "\(appModel.lessonStore.unlockedTimelineCount)/\(max(appModel.lessonStore.totalTimelineEvents, 1)) ready",
            emphasis: .story,
            progress: appModel.lessonStore.totalTimelineEvents == 0 ? nil : Double(appModel.lessonStore.unlockedTimelineCount) / Double(appModel.lessonStore.totalTimelineEvents)
        )
    }


    private func timelineChip(title: String, symbol: String, emphasis: GBEmphasis) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(GBColor.accent(for: emphasis))
            .padding(.horizontal, GBSpacing.xSmall)
            .padding(.vertical, GBSpacing.xxxSmall)
            .background(GBColor.Background.surface, in: Capsule())
    }

    @ViewBuilder
    private var reviewQueueSection: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(
                eyebrow: "Review Queue",
                title: dueReviews.isEmpty ? "Upcoming revisit moments" : "Due now for a short revisit",
                subtitle: dueReviews.isEmpty
                    ? "Nothing is overdue. These are the next moments the child will re-enter for calm spaced review."
                    : "These items are ready to come back into the journey through a quick memory run."
            )

            if dueReviews.isEmpty {
                ForEach(upcomingReviews, id: \.subjectID) { schedule in
                    ReviewScheduleCard(schedule: schedule, title: reviewTitle(for: schedule), isDue: false)
                }
            } else {
                ForEach(dueReviews, id: \.subjectID) { schedule in
                    ReviewScheduleCard(schedule: schedule, title: reviewTitle(for: schedule), isDue: true)
                }
            }
        }
    }

    private func reviewTitle(for schedule: ReviewSchedule) -> String {
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

private struct TimelineSummaryPill: View {
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

private struct TimelineEventCard: View {
    @EnvironmentObject private var appModel: AppModel
    let event: TimelineEvent

    private var unlockState: LocationUnlockState {
        appModel.lessonStore.timelineUnlockState(for: event)
    }

    private var linkedPlaces: [Place] {
        appModel.content.places.filter { event.linkedPlaceIDs.contains($0.id) }
    }

    private var linkedScene: StoryScene? {
        appModel.content.scenes.first(where: { $0.timelineMarker == event.id })
    }

    @ViewBuilder
    var body: some View {
        switch unlockState {
        case .hidden:
            cardSurface(style: .elevated)
        case .seenInStory, .learnable:
            cardSurface(style: .plain)
        case .remembered, .placedAccurately, .masteredInReview:
            cardSurface(style: .accented(.story))
        }
    }

    private func cardSurface(style: GBSurface<EmptyView>.Style) -> some View {
        GBSurface(style: style) {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            HStack(alignment: .top, spacing: GBSpacing.small) {
                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    HStack(spacing: GBSpacing.xxSmall) {
                        GBBadge(title: "Step \(event.orderIndex + 1)", symbol: GBIcon.timeline, emphasis: .story)
                        GBBadge(title: stateTitle, symbol: stateSymbol, emphasis: stateEmphasis)
                    }

                    Text(event.title)
                        .gbTitle()
                        .foregroundStyle(titleColor)
                    Text(event.broadEraLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(subtitleColor)
                }

                Spacer()

                if let yearLabel = event.yearLabel {
                    Text(yearLabel)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(trailingColor)
                }
            }

            Text(primaryText)
                .gbBody()
                .foregroundStyle(bodyColor)

            if !linkedPlaces.isEmpty {
                HStack(spacing: GBSpacing.small) {
                    ForEach(linkedPlaces) { place in
                        Label(place.name, systemImage: GBIcon.place)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(chipColor)
                            .padding(.horizontal, GBSpacing.xSmall)
                            .padding(.vertical, GBSpacing.xxxSmall)
                            .background(chipBackground, in: Capsule())
                    }
                }
            }

            if let linkedScene {
                GBSurface(style: nestedSurfaceStyle, padding: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        Text("Re-entry scene")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(nestedSecondaryColor)
                        Text(linkedScene.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(nestedPrimaryColor)
                        Text(event.recallPrompt)
                            .font(.caption)
                            .foregroundStyle(nestedSecondaryColor)
                    }
                }
            }
        }
    }

    private var titleColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.inverse
        default:
            return GBColor.Content.primary
        }
    }

    private var subtitleColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.inverse.opacity(0.92)
        default:
            return GBColor.Accent.story
        }
    }

    private var trailingColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.inverse.opacity(0.9)
        default:
            return GBColor.Content.secondary
        }
    }

    private var bodyColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.inverse.opacity(0.9)
        default:
            return GBColor.Content.secondary
        }
    }

    private var chipColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.inverse
        default:
            return GBColor.Content.secondary
        }
    }

    private var chipBackground: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return .white.opacity(0.14)
        default:
            return GBColor.Background.elevated
        }
    }

    private var nestedSurfaceStyle: GBSurface<EmptyView>.Style {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return .plain
        default:
            return .elevated
        }
    }

    private var nestedPrimaryColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.primary
        default:
            return GBColor.Content.primary
        }
    }

    private var nestedSecondaryColor: Color {
        switch unlockState {
        case .remembered, .placedAccurately, .masteredInReview:
            return GBColor.Content.secondary
        default:
            return GBColor.Content.secondary
        }
    }

    private var stateTitle: String {
        switch unlockState {
        case .hidden:
            return "Locked"
        case .seenInStory, .learnable:
            return "Ready"
        case .remembered:
            return "Remembered"
        case .placedAccurately, .masteredInReview:
            return "Placed"
        }
    }

    private var stateSymbol: String {
        switch unlockState {
        case .hidden:
            return GBIcon.locked
        case .seenInStory, .learnable:
            return GBIcon.next
        case .remembered:
            return GBIcon.story
        case .placedAccurately, .masteredInReview:
            return GBIcon.success
        }
    }

    private var stateEmphasis: GBEmphasis {
        switch unlockState {
        case .hidden:
            return .neutral
        case .seenInStory, .learnable, .remembered:
            return .story
        case .placedAccurately, .masteredInReview:
            return .place
        }
    }

    private var primaryText: String {
        switch unlockState {
        case .hidden:
            return "This moment will open after its scene becomes strong enough to place in order."
        case .seenInStory, .learnable:
            return "The scene is visible. Next step is to remember where this moment belongs in the journey."
        case .remembered:
            return "This event is now part of the remembered sequence. Keep reviewing so it becomes easier to place on sight."
        case .placedAccurately, .masteredInReview:
            return "This moment is holding firmly in order. The timeline is starting to feel like one connected story."
        }
    }
}

private struct ReviewScheduleCard: View {
    let schedule: ReviewSchedule
    let title: String
    let isDue: Bool

    var body: some View {
        GBSurface(style: isDue ? .plain : .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(spacing: GBSpacing.small) {
                    GBBadge(title: badgeTitle, symbol: badgeSymbol, emphasis: badgeEmphasis)
                    Spacer()
                    Text(schedule.stabilityBand.rawValue.capitalized)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(GBColor.Content.secondary)
                }

                Text(title)
                    .gbTitle()
                    .foregroundStyle(GBColor.Content.primary)

                Text(detailText)
                    .gbBody()
                    .foregroundStyle(GBColor.Content.secondary)
            }
        }
    }

    private var badgeTitle: String {
        isDue ? "Due now" : "Next revisit"
    }

    private var badgeSymbol: String {
        isDue ? GBIcon.timeline : GBIcon.next
    }

    private var badgeEmphasis: GBEmphasis {
        isDue ? .chronicle : .neutral
    }

    private var detailText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let when = formatter.localizedString(for: schedule.nextDueAt, relativeTo: Date())
        return "\(subjectLabel) review, interval \(schedule.intervalIndex + 1), \(when)."
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
