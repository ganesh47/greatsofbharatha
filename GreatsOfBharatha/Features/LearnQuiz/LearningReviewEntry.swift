import SwiftUI

/// All entry points resolve the same learned-card catalog so a suspended queue is never filtered by a chapter link.
struct LearningReviewEntry: View {
    @EnvironmentObject private var appModel: AppModel
    var body: some View {
        if appModel.lessonStore.activityStateIsAvailable(for: .review) {
            FlashcardReviewView(cards: LearnQuizPilotData.reviewCards,
                hooks: LearningActivityAdapters.reviewHooks(store: appModel.lessonStore))
        } else {
            Text("Your saved card review uses a format this app cannot open. Its saved data and chapter progress are preserved.")
                .gbStory().padding().accessibilityIdentifier("review-unavailable")
        }
    }
}
