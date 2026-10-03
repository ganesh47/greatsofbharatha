import SwiftUI

struct ChronicleView: View {
    @EnvironmentObject private var appModel: AppModel
    let rewards: [ChronicleReward]
    var highlightRewardID: String?
    @State private var placementIDs: [String: UUID] = [:]
    @FocusState private var focusedAction: String?

    private var layout: GBLayoutContext {
#if os(tvOS)
        .television
#else
        .compact
#endif
    }

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
                                    focusedAction = "replay-" + reward.id
                                } label: { Label("Place keepsake in my Album", systemImage: "plus.rectangle.on.rectangle") }
                                    .buttonStyle(.gbPrimary(.chronicle))
                                    .accessibilityIdentifier("album-place-" + reward.id)
                                    .focused($focusedAction, equals: "place-" + reward.id)
                            }
                            if let scene = appModel.content.scenes.first(where: { $0.id == reward.unlockedBySceneID }) {
                                NavigationLink { SceneLessonView(scene: scene) } label: { Text("Explore this story again") }
                                    .buttonStyle(.bordered)
                                    .focused($focusedAction, equals: "replay-" + reward.id)
                            }
                        }
                    }
                    .padding(GBSpacing.medium)
                    .background(unlocked ? GBColor.Chronicle.goldBg : GBColor.Background.surface,
                        in: RoundedRectangle(cornerRadius: GBRadius.hero))
                }
            }.padding(layout.containerPadding).frame(maxWidth: albumWidth).frame(maxWidth: .infinity)
        }.background(GBColor.Background.app)
#if os(tvOS)
            .navigationTitle("")
#else
            .navigationTitle("Album")
#endif
            .onAppear {
#if os(tvOS)
                if let reward = ordered.first(where: { appModel.lessonStore.isUnlocked($0) }) {
                    focusedAction = (placed(reward) ? "replay-" : "place-") + reward.id
                }
#endif
            }
    }

    private var albumWidth: CGFloat {
#if os(tvOS)
        layout.maxContentWidth ?? 1400
#else
        700
#endif
    }
}
