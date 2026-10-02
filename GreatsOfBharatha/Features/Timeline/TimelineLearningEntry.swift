import SwiftUI

struct TimelineLearningEntry: View {
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        TimelineHubView(checkpoint: appModel.lessonStore.activityState(TimelineActivityCheckpoint.self, for: .timeline),
            onCheckpointChange: { LearningActivityAdapters.saveTimeline($0, store: appModel.lessonStore) },
            onPlacementChecked: { LearningActivityAdapters.recordTimeline($0, store: appModel.lessonStore, content: appModel.content) })
    }
}
