import SwiftUI

struct PlacesHubView: View {
    @EnvironmentObject private var appModel: AppModel
    let places: [Place]

    private var readyPlaces: [Place] {
        places.filter { appModel.lessonStore.progress(for: $0) != .locked }
    }

    private var masteredCount: Int {
        places.filter { appModel.lessonStore.progress(for: $0) == .masteredLightly }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                VStack(alignment: .leading, spacing: 14) {
                    Text("Fort trail")
                        .font(.title3.bold())
                    Text("See how the forts relate to each other, then step into one place at a time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                        NavigationLink {
                            PlaceDetailView(place: place, progress: appModel.lessonStore.progress(for: place))
                        } label: {
                            placeTrailCard(place, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Places")
        .background(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97, opacity: 1.0))
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Journey across the forts")
                        .font(.title2.bold())
                    Text("Match each fort to its moment so the map starts feeling like a real story world.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "map.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 10) {
                summaryPill(title: "Ready now", value: "\(readyPlaces.count)", tint: .orange)
                summaryPill(title: "Collected", value: "\(masteredCount)", tint: .green)
                summaryPill(title: "Core forts", value: "\(places.filter(\.isCoreReleasePlace).count)", tint: .blue)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Start with a ready fort, spot its place on the Sahyadri board, then compare it with its nearby neighbors.", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                Text("Each fort card keeps one memory hook, one big event, and one region clue visible at a glance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.20), Color.blue.opacity(0.12), Color.green.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
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

    private func placeTrailCard(_ place: Place, index: Int) -> some View {
        let progress = appModel.lessonStore.progress(for: place)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Stop \(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(place.name)
                        .font(.headline)
                    Text(place.memoryHook)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                }

                Spacer()

                Text(progress.rawValue)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(progressColor(progress).opacity(0.15), in: Capsule())
                    .foregroundStyle(progressColor(progress))
            }

            HStack(spacing: 12) {
                Label(place.primaryEvent, systemImage: "flag.fill")
                Label(place.regionLabel, systemImage: "location.north.line.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Text(progress == .locked ? "Unlock this fort through the story first." : "Open fort board")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(progress == .locked ? .secondary : .primary)
                Spacer()
                Image(systemName: progress == .locked ? "lock.fill" : "arrow.right.circle.fill")
                    .foregroundStyle(progress == .locked ? .secondary : .orange)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(progressColor(progress).opacity(0.20), lineWidth: 1)
        )
        .opacity(progress == .locked ? 0.82 : 1)
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
            return comparisonMode ? "Study the reveal and compare the nearby forts before you try another pin." : "Tap a fort marker on the board, then reveal the answer when you are ready."
        }
        if selectedCandidate.id == place.id {
            return revealed ? "Well spotted. \(place.name) is the right fort for this clue." : "Good instinct. Reveal the answer to lock in the location."
        }
        return revealed ? "Close. This clue belongs to \(place.name). Use compare mode to see what makes it different." : "That pin is close, but not right yet. Reveal the answer and compare the forts."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                mapPreviewCard
                memoryFactsCard
                fortBoard
            }
            .padding()
        }
        .navigationTitle(place.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .background(Color(.sRGB, red: 0.96, green: 0.96, blue: 0.97, opacity: 1.0))
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(place.memoryHook.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text(place.name)
                        .font(.largeTitle.bold())
                    Text(place.whyItMatters)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(progress.rawValue, systemImage: progressIcon)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(progressColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(progressColor)
            }

            HStack(spacing: 12) {
                detailChip(title: "Story moment", value: place.primaryEvent, symbol: "flag.fill")
                detailChip(title: "Region clue", value: place.regionLabel, symbol: "mountain.2.fill")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var mapPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sahyadri fort board")
                .font(.headline)
            Text("The current fort glows brighter so its place on the trail is easier to remember.")
                .foregroundStyle(.secondary)

            schematicBoard(interactive: false)
                .frame(height: 280)

            HStack(spacing: 12) {
                Label("Orange pin: today’s fort", systemImage: "mappin.circle.fill")
                Label("Light pins: nearby forts", systemImage: "mappin.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var memoryFactsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Remember this fort")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                factRow(title: "Hook", value: place.memoryHook)
                factRow(title: "Big event", value: place.primaryEvent)
                factRow(title: "Region", value: place.regionLabel)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var fortBoard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pin the fort")
                        .font(.headline)
                    Text("Use the clue, choose a marker on the board, then reveal the answer.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(place.memoryHook)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.14), in: Capsule())
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(place.primaryEvent, systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                Text(feedbackText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            schematicBoard(interactive: true)
                .frame(height: 320)

            if let selectedCandidate {
                selectedCandidateSummary(selectedCandidate)
            }

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
                    Button(comparisonMode ? "Hide compare cards" : "Compare nearby forts") {
                        comparisonMode.toggle()
                        LessonFeedback.fire(.selection)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if revealed {
                Text("Reveal: \(place.name) is remembered for \(place.primaryEvent.lowercased()) and sits \(place.regionLabel.lowercased()).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if comparisonMode {
                comparisonCards
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func selectedCandidateSummary(_ candidate: Place) -> some View {
        let matchesTarget = candidate.id == place.id

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: matchesTarget && revealed ? "checkmark.seal.fill" : "mappin.and.ellipse")
                .foregroundStyle(matchesTarget && revealed ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.name)
                    .font(.headline)
                Text(candidate.primaryEvent)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(candidate.regionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var comparisonCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compare the nearby forts")
                .font(.subheadline.bold())

            ForEach(challengeCandidates.filter { $0.id != place.id }) { candidate in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.left.and.right.circle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 5) {
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

    private func schematicBoard(interactive: Bool) -> some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.13), Color.orange.opacity(0.10), Color.green.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Path { path in
                    let sorted = challengeCandidates.sorted { $0.latitude > $1.latitude }
                    guard let first = sorted.first else { return }
                    path.move(to: pointForCandidate(first, in: geometry.size))
                    for candidate in sorted.dropFirst() {
                        path.addLine(to: pointForCandidate(candidate, in: geometry.size))
                    }
                }
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10]))
                .foregroundStyle(Color.white.opacity(0.65))

                VStack {
                    HStack {
                        Text("N")
                            .font(.caption.bold())
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                        Spacer()
                        Text("Plateau trail")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    Spacer()
                    HStack {
                        Text("Konkan side")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                        Spacer()
                        Text("Pune side")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(16)

                ForEach(challengeCandidates) { candidate in
                    let isCurrent = candidate.id == place.id
                    let isSelected = selectedCandidateID == candidate.id
                    let showAsCorrect = revealed && isCurrent
                    let showAsMistake = revealed && isSelected && !isCurrent
                    let point = pointForCandidate(candidate, in: geometry.size)

                    Button {
                        guard interactive else { return }
                        selectedCandidateID = candidate.id
                        LessonFeedback.fire(.selection)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: showAsCorrect ? "checkmark.circle.fill" : isSelected ? "mappin.circle.fill" : isCurrent && !interactive ? "mappin.circle.fill" : "mappin.circle")
                                .font(isCurrent ? .title : .title2)
                                .foregroundStyle(showAsCorrect ? .green : showAsMistake ? .orange : isCurrent ? .orange : .primary.opacity(0.78))
                                .shadow(color: isCurrent ? .orange.opacity(0.25) : .clear, radius: 10)
                            Text(revealed || !interactive || isSelected ? candidate.name : "?")
                                .font(.caption2.bold())
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                    .position(point)
                }
            }
        }
    }

    private func pointForCandidate(_ candidate: Place, in size: CGSize) -> CGPoint {
        let minLat = challengeCandidates.map(\.latitude).min() ?? candidate.latitude
        let maxLat = challengeCandidates.map(\.latitude).max() ?? candidate.latitude
        let minLon = challengeCandidates.map(\.longitude).min() ?? candidate.longitude
        let maxLon = challengeCandidates.map(\.longitude).max() ?? candidate.longitude

        let lonSpan = max(maxLon - minLon, 0.001)
        let latSpan = max(maxLat - minLat, 0.001)

        let x = ((candidate.longitude - minLon) / lonSpan) * (size.width - 70) + 35
        let normalizedY = 1 - ((candidate.latitude - minLat) / latSpan)
        let y = normalizedY * (size.height - 90) + 45
        return CGPoint(x: x, y: y)
    }

    private var progressColor: Color {
        switch progress {
        case .locked: return .gray
        case .readyToLearn: return .orange
        case .reviewed: return .blue
        case .masteredLightly: return .green
        }
    }

    private var progressIcon: String {
        switch progress {
        case .locked: return "lock.fill"
        case .readyToLearn: return "sparkles"
        case .reviewed: return "eye.fill"
        case .masteredLightly: return "star.fill"
        }
    }

    private func detailChip(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func factRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
