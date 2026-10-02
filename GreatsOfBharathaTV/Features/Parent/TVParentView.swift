import SwiftUI

struct TVParentView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator

    var body: some View {
        TVScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("For grown-ups").font(.system(size: 54, weight: .bold, design: .serif))
                    Text("One shared storybook for your family. Progress is saved on this Apple TV.")
                        .font(.system(size: 30)).fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .top, spacing: 48) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Learning preferences").font(.system(size: 36, weight: .bold))
                            setting("Read-aloud narration", enabled: appModel.parentSettings.narrationEnabled, id: "tv-parent-narration") {
                                appModel.parentSettings.narrationEnabled.toggle()
                                if !appModel.parentSettings.narrationEnabled { narrator.stop() }
                            }
                            setting("Extra clues", enabled: appModel.parentSettings.assistModeEnabled, id: "tv-parent-assist") {
                                appModel.parentSettings.assistModeEnabled.toggle()
                            }
                            setting("Calm transitions", enabled: appModel.parentSettings.calmTransitionsEnabled, id: "tv-parent-calm") {
                                appModel.parentSettings.calmTransitionsEnabled.toggle()
                            }
                            Text("Captions stay visible. Apple TV’s Reduce Motion setting also reduces decorative animation.")
                                .font(.system(size: 26)).fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 22) {
                            Text("What your family practised").font(.system(size: 36, weight: .bold))
                            ForEach(appModel.content.scenes) { scene in
                                let record = appModel.lessonStore.masteryRecord(for: scene.id)
                                let recall = record?.evidenceLog.last {
                                    ($0.type == .recallSuccess || $0.type == .reviewSuccess) && $0.support != .selfReported
                                }
                                HStack(alignment: .top, spacing: 16) {
                                    Image(systemName: recall == nil ? "book" : "checkmark.circle").foregroundStyle(TVTheme.gold)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(scene.title).font(.system(size: 28, weight: .semibold))
                                        Text(ChapterLearningSummary(record: record).activityText).font(.system(size: 24))
                                        Text(ChapterLearningSummary(record: record).nextStep).font(.system(size: 24))
                                    }
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
                            .background(TVTheme.panel, in: RoundedRectangle(cornerRadius: 24))
                    }
                    Text("Try a conversation: Which fort do you remember, and why did it matter?")
                        .font(.system(size: 30, design: .serif))
                    Text("Apple TV records shared family choices. A checked choice, even without a clue, does not establish an individual child's independent recall.")
                        .font(.system(size: 26)).fixedSize(horizontal: false, vertical: true)
                }.padding(12)
            }
        }
    }

    private func setting(_ title: String, enabled: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack { Text(title); Spacer(); Label(enabled ? "On" : "Off", systemImage: enabled ? "checkmark.circle.fill" : "circle") }
        }
        .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier(id)
        .accessibilityValue(enabled ? "On" : "Off")
    }

    private func summary(record: MasteryRecord?, evidence: MasteryEvidence?) -> String {
        guard let record else { return "Not started" }
        guard let evidence else { return record.exposureCount > 0 ? "Story explored; memory activity still to try" : "Activity started" }
        let support = evidence.support == .independent ? "without a clue" : "with support"
        return evidence.type == .reviewSuccess ? "Checked again in a later visit, " + support : "Recognised the story fact, " + support
    }
}
