import SwiftUI

struct TVAlbumView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedReward: ChronicleReward?

    var body: some View {
        TVScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("My storybook Album").font(.system(size: 54, weight: .bold, design: .serif))
                    TVFireflyGuide(message: "Your keepsakes belong to the stories you discovered. Choose one, then place it on its chapter page.")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 28) {
                        ForEach(appModel.content.rewards) { reward in
                            let earned = appModel.lessonStore.isUnlocked(reward)
                            let placed = isPlaced(reward)
                            Button { selectedReward = reward } label: {
                                VStack(alignment: .leading, spacing: 16) {
                                    if let scene = appModel.content.scenes.first(where: { $0.id == reward.unlockedBySceneID }) {
                                        TVChapterArt(scene: scene).frame(height: 190).clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    Label(reward.title, systemImage: earned ? "seal.fill" : "lock.fill")
                                    Text(placed ? "Placed on my chapter page" : (earned ? "Ready to place" : "Discover its chapter to earn it"))
                                        .font(.system(size: 24)).fixedSize(horizontal: false, vertical: true)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(TVCardButtonStyle()).disabled(!earned)
                            .accessibilityIdentifier("tv-album-" + reward.id)
                        }
                    }
                    if appModel.lessonStore.unlockedRewards(from: appModel.content.rewards).isEmpty {
                        Text("Your first keepsake is waiting in the Shivneri chapter.").font(.system(size: 30))
                        NavigationLink(value: TVRoute.lesson(appModel.content.scenes[0].id)) { Text("Discover Shivneri") }
                            .buttonStyle(TVCardButtonStyle())
                    }
                }.padding(12)
            }
        }
        .sheet(item: $selectedReward) { reward in TVAlbumPageView(reward: reward) }
    }

    private func isPlaced(_ reward: ChronicleReward) -> Bool {
        appModel.lessonStore.masteryRecord(for: reward.id)?.evidenceLog.contains { $0.type == .chronicleReflection } == true
    }
}

private struct TVAlbumPageView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedAction: String?
    let reward: ChronicleReward
    @State private var eventID = UUID()

    private var placed: Bool {
        appModel.lessonStore.masteryRecord(for: reward.id)?.evidenceLog.contains { $0.type == .chronicleReflection } == true
    }

    var body: some View {
        TVScreen {
            HStack(spacing: 56) {
                if let scene = appModel.content.scenes.first(where: { $0.id == reward.unlockedBySceneID }) {
                    ZStack(alignment: .bottomTrailing) {
                        TVChapterArt(scene: scene)
                        if placed {
                            Label(reward.title, systemImage: "seal.fill")
                                .font(.system(size: 29, weight: .bold, design: .serif)).padding(30)
                                .foregroundStyle(TVTheme.ink).background(TVTheme.gold, in: RoundedRectangle(cornerRadius: 24))
                                .padding(28).accessibilityIdentifier("tv-album-placed")
                        }
                    }.frame(width: 830, height: 600).clipShape(RoundedRectangle(cornerRadius: 30))
                }
                VStack(alignment: .leading, spacing: 28) {
                    Text(reward.title).font(.system(size: 48, weight: .bold, design: .serif))
                    Text(reward.meaning).font(.system(size: 30)).fixedSize(horizontal: false, vertical: true)
                    TVFireflyGuide(message: placed ? "Your keepsake is at home in the storybook. Tell someone what it helps you remember." : "Click to place your keepsake on this chapter page.")
                    TVNarrationControls(id: reward.id, text: reward.title + ". " + reward.meaning)
                    if !placed {
                        Button("Place on this page") { place() }
                            .buttonStyle(TVCardButtonStyle()).focused($focusedAction, equals: "place")
                            .accessibilityIdentifier("tv-album-place")
                    }
                    Button("Back to my Album") { dismiss() }.buttonStyle(TVCardButtonStyle())
                        .focused($focusedAction, equals: "done").accessibilityIdentifier("tv-album-done")
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .defaultFocus($focusedAction, placed ? "done" : "place")
        .onPlayPauseCommand { if appModel.parentSettings.narrationEnabled { narrator.togglePlayback() } }
        .onExitCommand { dismiss() }
        .onDisappear { narrator.stop() }
    }

    private func place() {
        guard !placed, appModel.lessonStore.isUnlocked(reward) else { return }
        withAnimation(reduceMotion || appModel.parentSettings.calmTransitionsEnabled ? nil : .easeOut(duration: 0.35)) {
            _ = appModel.lessonStore.recordLearningOutcome(subjectID: reward.id, subjectType: .chronicle,
                activity: .albumPlacement, wasSuccessful: true, support: .selfReported,
                detail: "Placed an earned keepsake on its TV album page", eventID: eventID)
        }
        focusedAction = "done"
    }
}
