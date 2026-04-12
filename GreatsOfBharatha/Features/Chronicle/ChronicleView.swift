import SwiftUI

struct ChronicleView: View {
    let rewards: [ChronicleReward]

    var body: some View {
        List {
            Section {
                Text("Meaning-bearing rewards for story progress, not anxiety-heavy grades.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Unlocked rewards") {
                ForEach(rewards) { reward in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(reward.title)
                                .font(.headline)
                            Spacer()
                            Text(reward.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(reward.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(reward.meaning)
                            .font(.body)
                        Label(reward.mastery.rawValue, systemImage: "medal")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Royal Chronicle")
    }
}
