import SwiftUI

struct TimelineLearningEntry: View {
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        if appModel.lessonStore.activityStateIsAvailable(for: .timeline) {
            TimelineHubView(checkpoint: appModel.lessonStore.activityState(TimelineActivityCheckpoint.self, for: .timeline),
            onCheckpointChange: { LearningActivityAdapters.saveTimeline($0, store: appModel.lessonStore) },
            onPlacementChecked: { LearningActivityAdapters.recordTimeline($0, store: appModel.lessonStore, content: appModel.content) })
        } else {
            Text("Your saved timeline uses a format this app cannot open. Its saved data and chapter progress are preserved.")
                .gbStory().padding().accessibilityIdentifier("timeline-unavailable")
        }
    }
}
