import SwiftUI

struct PlacesHubView: View {
    @EnvironmentObject private var appModel: AppModel
    let places: [Place]

    var body: some View {
        List {
            Section {
                Text("Learn, pin, reveal, compare, and revisit the core forts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Core places") {
                ForEach(places) { place in
                    NavigationLink {
                        PlaceDetailView(place: place, progress: appModel.lessonStore.progress(for: place))
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(place.name)
                                    .font(.headline)
                                Text(place.memoryHook)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(place.primaryEvent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(appModel.lessonStore.progress(for: place).rawValue)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(progressColor(appModel.lessonStore.progress(for: place)).opacity(0.15), in: Capsule())
                                .foregroundStyle(progressColor(appModel.lessonStore.progress(for: place)))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Places Hub")
    }

    private func progressColor(_ progress: PlaceProgress) -> Color {
        switch progress {
        case .locked: return .gray
        case .readyToLearn: return .orange
        case .reviewed: return .blue
        case .masteredLightly: return .green
        }
    }
}

struct PlaceDetailView: View {
    let place: Place
    let progress: PlaceProgress

    @State private var selectedCandidateID: String?
    @State private var revealed = false
    @State private var comparisonMode = false

    private var challengeCandidates: [Place] {
        let core = SampleContent.shivajiVerticalSlice.corePlaces
        if core.contains(where: { $0.id == place.id }) {
            return core
        }
        return [place]
    }

    private var selectedCandidate: Place? {
        challengeCandidates.first(where: { $0.id == selectedCandidateID })
    }

    private var feedbackText: String {
        guard let selectedCandidate else {
            return comparisonMode ? "Compare the real fort with the nearby choices, then try again." : "Tap the fort marker that feels right, then reveal the answer."
        }
        if selectedCandidate.id == place.id {
            return revealed ? "Well spotted. You pinned the right fort." : "Good instinct. Reveal to confirm your choice."
        }
        return revealed ? "Close, but this clue belongs to \(place.name). Compare the reveal and try again." : "That pin is not quite right. Reveal to compare and learn the difference."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.largeTitle.bold())
                    Text(place.memoryHook)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                infoRow(title: "Primary event", value: place.primaryEvent)
                infoRow(title: "Why it matters", value: place.whyItMatters)
                infoRow(title: "Region", value: place.regionLabel)
                infoRow(title: "Educational pin", value: String(format: "%.4f, %.4f", place.latitude, place.longitude))
                infoRow(title: "Current progress", value: progress.rawValue)

                fortBoard

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pin challenge loop")
                        .font(.headline)
                    Text(feedbackText)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button(revealed ? "Reset challenge" : "Reveal answer") {
                            if revealed {
                                selectedCandidateID = nil
                                revealed = false
                                comparisonMode = false
                                LessonFeedback.fire(.selection)
                            } else {
                                revealed = true
                                comparisonMode = true
                                LessonFeedback.fire(selectedCandidate?.id == place.id ? .success : .reveal)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        if revealed {
                            Button(comparisonMode ? "Hide compare view" : "Compare nearby forts") {
                                comparisonMode.toggle()
                                LessonFeedback.fire(.selection)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding()
        }
        .navigationTitle(place.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var fortBoard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tap-near fort board")
                .font(.headline)
            Text("Choose the fort that matches this clue. The board snaps your attention to one core place at a time.")
                .foregroundStyle(.secondary)

            ForEach(challengeCandidates) { candidate in
                let isSelected = selectedCandidateID == candidate.id
                let isCorrect = revealed && candidate.id == place.id
                let showMistake = revealed && isSelected && candidate.id != place.id

                Button {
                    selectedCandidateID = candidate.id
                    LessonFeedback.fire(.selection)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : isSelected ? "mappin.circle.fill" : "mappin.circle")
                            .foregroundStyle(isCorrect ? .green : isSelected ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.name)
                                .foregroundStyle(.primary)
                            Text(candidate.primaryEvent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isCorrect {
                            Text("Correct")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        } else if showMistake {
                            Text("Compare")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background((isCorrect ? Color.green.opacity(0.12) : showMistake ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if revealed {
                Text("Reveal: \(place.name) belongs to \(place.regionLabel) and is remembered here for \(place.primaryEvent.lowercased()).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if comparisonMode {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Compare the nearby forts")
                        .font(.subheadline.bold())
                    ForEach(challengeCandidates.filter { $0.id != place.id }) { candidate in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "arrow.left.and.right.circle")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(candidate.name) vs \(place.name)")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(candidate.name): \(candidate.primaryEvent)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(place.name): \(place.primaryEvent)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
