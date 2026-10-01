import SwiftUI

struct ChronicleView: View {
    @EnvironmentObject private var appModel: AppModel
    let rewards: [ChronicleReward]
    var highlightRewardID: String?
    @State private var placementIDs: [String: UUID] = [:]

    private var ordered: [ChronicleReward] {
        rewards.sorted { lhs, rhs in
            if lhs.id == rhs.id { return false }
            if lhs.id == highlightRewardID { return true }
            if rhs.id == highlightRewardID { return false }
            let left = appModel.lessonStore.isUnlocked(lhs)
            let right = appModel.lessonStore.isUnlocked(rhs)
            if left != right { return left }
            return rewards.firstIndex(where: { $0.id == lhs.id })! < rewards.firstIndex(where: { $0.id == rhs.id })!
        }
    }
    private func placed(_ reward: ChronicleReward) -> Bool {
        appModel.lessonStore.masteryRecord(for: reward.id)?.evidenceLog.contains(where: { $0.type == .chronicleReflection }) == true
    }
    private func rememberedAgain(_ reward: ChronicleReward) -> Bool {
        guard let entry = appModel.content.activeHeroArc.chronicleEntries.first(where: { $0.id == reward.id }) else { return false }
        return appModel.lessonStore.chronicleProgress(for: entry).detailLevel == .rememberedAgain
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text("My story Album").gbDisplay()
                Text("Keepsakes from the places and stories you explored.").gbStory()
                ForEach(ordered) { reward in
                    let unlocked = appModel.lessonStore.isUnlocked(reward)
                    VStack(alignment: .leading, spacing: GBSpacing.medium) {
                        HStack(alignment: .top) {
                            Image(systemName: unlocked ? (placed(reward) ? "book.closed.fill" : "book.fill") : "lock.fill")
                                .font(.largeTitle).foregroundStyle(GBColor.Chronicle.gold)
                            VStack(alignment: .leading) {
                                Text(reward.title).gbTitle()
                                Text(unlocked ? (rememberedAgain(reward) ? "Remembered again" : "Earned through learning") :
                                    (appModel.lessonStore.isPreviewed(reward) ? "Started — a keepsake to discover" : "A future adventure"))
                                    .font(.caption)
                            }
                        }
                        if unlocked {
                            Text(reward.meaning).gbStory()
                            LearningNarrationControls(id: reward.id + "-album", text: reward.title + ". " + reward.meaning)
                            if placed(reward) {
                                Label("Placed in my Album", systemImage: "checkmark.seal.fill")
                                    .accessibilityIdentifier("album-placed-" + reward.id)
                                Text("Tell someone why this place matters.").gbBody()
                            } else {
                                Button {
                                    guard !placed(reward) else { return }
                                    let eventID = placementIDs[reward.id] ?? UUID()
                                    placementIDs[reward.id] = eventID
                                    appModel.lessonStore.recordLearningOutcome(subjectID: reward.id, subjectType: .chronicle,
                                        activity: .albumPlacement, wasSuccessful: true, mastery: .chronicled,
                                        detail: "Placed an earned keepsake into the Album", eventID: eventID)
                                    LessonFeedback.fire(.celebration)
                                } label: { Label("Place keepsake in my Album", systemImage: "plus.rectangle.on.rectangle") }
                                    .buttonStyle(.gbPrimary(.chronicle))
                                    .accessibilityIdentifier("album-place-" + reward.id)
                            }
                            if let scene = appModel.content.scenes.first(where: { $0.id == reward.unlockedBySceneID }) {
                                NavigationLink { SceneLessonView(scene: scene) } label: { Text("Explore this story again") }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(GBSpacing.medium)
                    .background(unlocked ? GBColor.Chronicle.goldBg : GBColor.Background.surface,
                        in: RoundedRectangle(cornerRadius: GBRadius.hero))
                }
            }.padding(GBSpacing.medium).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(GBColor.Background.app).navigationTitle("Album")
    }
}
