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

    private let rewardColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let highlightedReward {
                    highlightedRewardCard(highlightedReward)
                }

                collectionSummaryCard

                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader(title: "Collected keepsakes", subtitle: unlockedRewards.isEmpty ? "Finish a lesson scene to place its first keepsake into the Royal Chronicle." : "Each reward becomes a memory keepsake from the Shivaji journey.")

                    if unlockedRewards.isEmpty {
                        emptyCollectionCard
                    } else {
                        LazyVGrid(columns: rewardColumns, spacing: 12) {
                            ForEach(unlockedRewards) { reward in
                                rewardCard(reward, unlocked: true)
                            }
                        }
                    }
                }

                if !lockedRewards.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader(title: "Still waiting in the Chronicle", subtitle: "More keepsakes appear as more scenes are completed.")

                        LazyVGrid(columns: rewardColumns, spacing: 12) {
                            ForEach(lockedRewards) { reward in
                                rewardCard(reward, unlocked: false)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Royal Chronicle")
        .background(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97, opacity: 1.0))
    }

    private var collectionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Chronicle shelf")
                        .font(.title3.bold())
                    Text("Collected story rewards stay here like keepsakes from the journey.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
                summaryPill(title: "Collected", value: "\(unlockedRewards.count)", tint: .orange)
                summaryPill(title: "Waiting", value: "\(lockedRewards.count)", tint: .secondary)
                summaryPill(title: "New today", value: "\(newlyCollectedCount)", tint: .green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.20), Color.yellow.opacity(0.10), Color.blue.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private var emptyCollectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Finish Scene 1 to unlock your first Chronicle keepsake.", systemImage: "sparkles")
                .font(.headline)
            Text("Story rewards appear here as cards, fragments, and badges you can revisit any time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var newlyCollectedCount: Int {
        unlockedRewards.filter { celebratedRewardIDs.contains($0.id) }.count
    }

    private func highlightedRewardCard(_ reward: ChronicleReward) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEW CHRONICLE KEEPSAKE")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text(reward.title)
                        .font(.title2.bold())
                    Text(reward.meaning)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: celebratedRewardIDs.contains(reward.id) ? "checkmark.seal.fill" : "sparkles.rectangle.stack.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(celebratedRewardIDs.contains(reward.id) ? .green : .orange)
            }

            HStack(spacing: 10) {
                rewardBadge(text: reward.category.rawValue, tint: accentColor(for: reward))
                rewardBadge(text: reward.mastery.rawValue, tint: .purple)
            }

            if celebratedRewardIDs.contains(reward.id) {
                Label("Placed in your Chronicle", systemImage: "books.vertical.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else {
                Button {
                    celebratedRewardIDs.insert(reward.id)
                    LessonFeedback.fire(.celebration)
                } label: {
                    Label("Place keepsake in Chronicle", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.22), Color.yellow.opacity(0.14), Color.white.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.orange.opacity(0.30), lineWidth: 1)
        )
    }

    private func rewardCard(_ reward: ChronicleReward, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: unlocked ? symbol(for: reward.category) : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(unlocked ? accentColor(for: reward) : .secondary)

                Spacer()

                if highlightRewardID == reward.id && unlocked {
                    Text(celebratedRewardIDs.contains(reward.id) ? "NEWLY STORED" : "NEW")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background((celebratedRewardIDs.contains(reward.id) ? Color.green.opacity(0.18) : Color.orange.opacity(0.18)), in: Capsule())
                        .foregroundStyle(celebratedRewardIDs.contains(reward.id) ? .green : .orange)
                }
            }

            Text(reward.title)
                .font(.headline)
                .foregroundStyle(unlocked ? .primary : .secondary)

            Text(reward.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(unlocked ? reward.meaning : "Complete its linked story scene to reveal this keepsake.")
                .font(.subheadline)
                .foregroundStyle(unlocked ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack {
                rewardBadge(text: reward.mastery.rawValue, tint: unlocked ? accentColor(for: reward) : .secondary)
                Spacer()
                Text(reward.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(cardBackground(for: reward, unlocked: unlocked), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke((highlightRewardID == reward.id && unlocked) ? Color.orange.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.92)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func summaryPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func rewardBadge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
    }

    private func symbol(for category: RewardCategory) -> String {
        switch category {
        case .storyCard: return "text.book.closed.fill"
        case .emblemFragment: return "seal.fill"
        case .leadershipBadge: return "star.circle.fill"
        }
    }

    private func accentColor(for reward: ChronicleReward) -> Color {
        switch reward.category {
        case .storyCard: return .orange
        case .emblemFragment: return .blue
        case .leadershipBadge: return .purple
        }
    }

    private func cardBackground(for reward: ChronicleReward, unlocked: Bool) -> LinearGradient {
        if unlocked {
            switch reward.category {
            case .storyCard:
                return LinearGradient(colors: [Color.orange.opacity(0.20), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .emblemFragment:
                return LinearGradient(colors: [Color.blue.opacity(0.18), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .leadershipBadge:
                return LinearGradient(colors: [Color.purple.opacity(0.18), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        return LinearGradient(colors: [Color.gray.opacity(0.15), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
