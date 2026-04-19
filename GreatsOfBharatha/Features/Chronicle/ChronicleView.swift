import SwiftUI

struct ChronicleView: View {
    @EnvironmentObject private var appModel: AppModel
    let rewards: [ChronicleReward]
    var highlightRewardID: String?

    @State private var celebratedRewardIDs: Set<String> = []

    private var unlockedRewards: [ChronicleReward] {
        appModel.lessonStore.unlockedRewards(from: rewards)
    }

    private var highlightedReward: ChronicleReward? {
        guard let highlightRewardID else { return nil }
        return unlockedRewards.first(where: { $0.id == highlightRewardID })
    }

    private var lockedRewards: [ChronicleReward] {
        rewards.filter { !appModel.lessonStore.isUnlocked($0) }
    }

    var body: some View {
        List {
            if let highlightedReward {
                Section("New Chronicle reward") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(highlightedReward.title)
                            .font(.headline)
                        Text(highlightedReward.meaning)
                            .font(.body)
                        if celebratedRewardIDs.contains(highlightedReward.id) {
                            Label("Added to your Chronicle", systemImage: "checkmark.seal.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        } else {
                            Button {
                                celebratedRewardIDs.insert(highlightedReward.id)
                                LessonFeedback.fire(.celebration)
                            } label: {
                                Label("Collect reward", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            Section {
                Text("Meaning-bearing rewards for story progress, not anxiety-heavy grades.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Unlocked rewards") {
                if unlockedRewards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Finish a lesson scene to place its meaning into the Royal Chronicle.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Debug mastery: \(appModel.lessonStore.mastery(for: \"scene-1-shivneri\")?.rawValue ?? \"nil\") / \(appModel.lessonStore.mastery(for: \"scene-2-torna-rajgad\")?.rawValue ?? \"nil\")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(unlockedRewards) { reward in
                        rewardRow(reward, unlocked: true)
                    }
                }
            }

            Section("Still to unlock") {
                ForEach(lockedRewards) { reward in
                    rewardRow(reward, unlocked: false)
                }
            }
        }
        .navigationTitle("Royal Chronicle")
    }

    @ViewBuilder
    private func rewardRow(_ reward: ChronicleReward, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reward.title)
                    .font(.headline)
                if highlightRewardID == reward.id {
                    Text(celebratedRewardIDs.contains(reward.id) ? "COLLECTED" : "NEW")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background((celebratedRewardIDs.contains(reward.id) ? Color.green.opacity(0.18) : Color.orange.opacity(0.18)), in: Capsule())
                        .foregroundStyle(celebratedRewardIDs.contains(reward.id) ? .green : .orange)
                }
                Spacer()
                Text(reward.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(reward.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(unlocked ? reward.meaning : "Complete the linked lesson scene to reveal this Chronicle reward.")
                .font(.body)
            Label(reward.mastery.rawValue, systemImage: unlocked ? "medal.fill" : "lock.fill")
                .font(.caption)
                .foregroundStyle(unlocked ? .orange : .secondary)
        }
        .padding(.vertical, 6)
        .background(highlightRewardID == reward.id ? Color.orange.opacity(0.08) : Color.clear)
    }
}
