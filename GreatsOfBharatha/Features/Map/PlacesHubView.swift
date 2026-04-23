import MapKit
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
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    heroCard

                    GBSurface(style: .elevated) {
                        HStack(spacing: GBSpacing.small) {
                            PlaceSummaryPill(title: "Ready now", value: "\(readyPlaces.count)", emphasis: .place)
                            PlaceSummaryPill(title: "Collected", value: "\(masteredCount)", emphasis: .chronicle)
                            PlaceSummaryPill(title: "Core forts", value: "\(places.filter(\.isCoreReleasePlace).count)", emphasis: .neutral)
                        }
                    }

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Quest",
                                title: "Hold the story on the fort board",
                                subtitle: "The place trail is the middle step between a story moment and its Chronicle reward."
                            )

                            GBQuestProgress(
                                steps: [.story, .place, .chronicle],
                                currentStepID: "place"
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Fort Trail",
                            title: "Walk the ready forts in order",
                            subtitle: "Open any ready fort to pin it on the board and compare it with nearby places."
                        )

                        ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                            let progress = appModel.lessonStore.progress(for: place)
                            Group {
                                if progress == .locked {
                                    PlaceTrailCard(place: place, index: index, progress: progress)
                                } else {
                                    NavigationLink {
                                        PlaceDetailView(place: place, progress: progress)
                                    } label: {
                                        PlaceTrailCard(place: place, index: index, progress: progress)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Places")
    }

    private var heroCard: some View {
        GBHeroCard(
            eyebrow: "Sahyadri Fort Trail",
            title: "Remember the place, not just the plot",
            subtitle: "The forts turn the story into a real landscape.",
            detail: "Pin one fort at a time, compare it with nearby mountains, and keep the geography tied to Shivaji Maharaj's journey.",
            ctaTitle: "Open a ready fort",
            badgeTitle: "\(readyPlaces.count) ready now",
            emphasis: .place,
            progress: places.isEmpty ? nil : Double(readyPlaces.count) / Double(places.count)
        )
    }
}

private struct PlaceSummaryPill: View {
    let title: String
    let value: String
    let emphasis: GBEmphasis

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
            Text(title)
                .font(.caption)
                .foregroundStyle(GBColor.Content.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(GBColor.accent(for: emphasis))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GBSpacing.xSmall)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
    }
}

private struct PlaceTrailCard: View {
    let place: Place
    let index: Int
    let progress: PlaceProgress

    var body: some View {
        GBSurface(style: progress == .locked ? .elevated : .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        HStack(spacing: GBSpacing.xxSmall) {
                            GBBadge(title: "Stop \(index + 1)", symbol: GBIcon.place, emphasis: .place)
                            if place.isCoreReleasePlace {
                                GBBadge(title: "Core fort", symbol: GBIcon.fort, emphasis: .neutral)
                            }
                        }

                        Text(place.name)
                            .gbTitle()
                            .foregroundStyle(GBColor.Content.primary)

                        Text(place.memoryHook)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GBColor.Accent.place)
                    }

                    Spacer()

                    GBBadge(title: progress.rawValue, symbol: progressIcon(progress), emphasis: progressEmphasis(progress))
                }

                HStack(spacing: GBSpacing.small) {
                    Label(place.primaryEvent, systemImage: GBIcon.fort)
                    Label(place.regionLabel, systemImage: GBIcon.region)
                }
                .font(.caption)
                .foregroundStyle(GBColor.Content.secondary)

                HStack {
                    Text(progress == .locked ? "Unlock this fort through the story first." : "Open fort board")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(progress == .locked ? GBColor.Content.secondary : GBColor.Content.primary)
                    Spacer()
                    Image(systemName: progress == .locked ? GBIcon.locked : GBIcon.next)
                        .foregroundStyle(progressColor(progress))
                }
            }
            .opacity(progress == .locked ? 0.84 : 1)
        }
    }
}

struct PlaceDetailView: View {
    @Environment(\.openURL) private var openURL
    let place: Place
    let progress: PlaceProgress

    @State private var selectedCandidateID: String?
    @State private var revealed = false
    @State private var comparisonMode = false
    @State private var showsMapExplorer = false

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
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    headerCard

                    GBSurface(style: .elevated) {
                        VStack(alignment: .leading, spacing: GBSpacing.small) {
                            GBSectionHeader(
                                eyebrow: "Quest",
                                title: "Pin this fort on the Sahyadri board",
                                subtitle: "Use the clue, pick a marker, then reveal the answer before leaving for the Chronicle."
                            )

                            GBQuestProgress(
                                steps: [.story, .place, .chronicle],
                                currentStepID: "place"
                            )
                        }
                    }

                    mapPreviewCard
                    memoryFactsCard
                    externalMapCard
                    fortBoard
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle(place.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sheet(isPresented: $showsMapExplorer) {
            PlaceMapExplorerSheet(place: place, nearbyPlaces: challengeCandidates)
        }
    }

    private var headerCard: some View {
        GBSurface(style: .accented(.place)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack(alignment: .top, spacing: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text(place.memoryHook.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.84))
                        Text(place.name)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(GBColor.Content.inverse)
                        Text(place.whyItMatters)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.92))
                    }
                    Spacer()
                    GBBadge(title: progress.rawValue, symbol: progressIcon(progress), emphasis: .place)
                }

                HStack(spacing: GBSpacing.small) {
                    detailChip(title: "Story moment", value: place.primaryEvent, symbol: GBIcon.fort)
                    detailChip(title: "Region clue", value: place.regionLabel, symbol: "mountain.2.fill")
                }
            }
        }
    }

    private var mapPreviewCard: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Board Preview",
                    title: "See where this fort sits",
                    subtitle: "The current fort glows brighter so its place on the trail is easier to remember."
                )

                Text("Preview only. Use \"Pin the fort\" below to interact.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(GBColor.Content.secondary)

                schematicBoard(interactive: false)
                    .allowsHitTesting(false)
                    .frame(height: 280)

                HStack(spacing: GBSpacing.small) {
                    Label("Bright pin: today's fort", systemImage: "mappin.circle.fill")
                    Label("Light pins: nearby forts", systemImage: "mappin.circle")
                }
                .font(.caption)
                .foregroundStyle(GBColor.Content.secondary)
            }
        }
    }

    private var memoryFactsCard: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Remember",
                    title: "Keep this fort in one glance",
                    subtitle: "Use a short hook, one event, and one region clue."
                )

                VStack(alignment: .leading, spacing: GBSpacing.small) {
                    factRow(title: "Hook", value: place.memoryHook)
                    factRow(title: "Big event", value: place.primaryEvent)
                    factRow(title: "Region", value: place.regionLabel)
                }
            }
        }
    }

    private var externalMapCard: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "MapKit Explorer",
                    title: "See the real fort region",
                    subtitle: "Use the in-app map to connect the Sahyadri board with a real landscape, then optionally open Apple Maps outside the app."
                )

                Button {
                    showsMapExplorer = true
                } label: {
                    Label("Open map explorer", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.gbPrimary(.place))

                Button {
                    guard let appleMapsURL else { return }
                    openURL(appleMapsURL)
                } label: {
                    Label("Open in Apple Maps", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.gbSecondary)

                Text("The explorer keeps the learning context in GreatsOfBharatha. Apple Maps remains an optional external reference.")
                    .font(.caption)
                    .foregroundStyle(GBColor.Content.secondary)
            }
        }
    }

    private var fortBoard: some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSectionHeader(
                    eyebrow: "Place Challenge",
                    title: "Pin the fort",
                    subtitle: "Use the clue, choose a marker on the board, then reveal the answer.",
                    trailing: AnyView(GBBadge(title: place.memoryHook, symbol: GBIcon.place, emphasis: .place))
                )

                GBSurface(style: .elevated, padding: GBSpacing.small) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Label(place.primaryEvent, systemImage: GBIcon.reward)
                            .font(.subheadline.weight(.semibold))
                        Text(feedbackText)
                            .font(.subheadline)
                            .foregroundStyle(GBColor.Content.secondary)
                    }
                }

                schematicBoard(interactive: true)
                    .frame(height: 320)

                if let selectedCandidate {
                    selectedCandidateSummary(selectedCandidate)
                }

                HStack(spacing: GBSpacing.small) {
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
                    .buttonStyle(.gbPrimary(.place))

                    if revealed {
                        Button(comparisonMode ? "Hide compare cards" : "Compare nearby forts") {
                            comparisonMode.toggle()
                            LessonFeedback.fire(.selection)
                        }
                        .buttonStyle(.gbSecondary)
                    }
                }

                if revealed {
                    Text("Reveal: \(place.name) is remembered for \(place.primaryEvent.lowercased()) and sits \(place.regionLabel.lowercased()).")
                        .font(.subheadline)
                        .foregroundStyle(GBColor.Content.secondary)
                }

                if comparisonMode {
                    comparisonCards
                }
            }
        }
    }

    private func selectedCandidateSummary(_ candidate: Place) -> some View {
        let matchesTarget = candidate.id == place.id

        return GBSurface(style: .elevated, padding: GBSpacing.small) {
            HStack(alignment: .top, spacing: GBSpacing.small) {
                Image(systemName: matchesTarget && revealed ? GBIcon.success : "mappin.and.ellipse")
                    .foregroundStyle(matchesTarget && revealed ? GBColor.Accent.success : GBColor.Accent.place)
                    .font(.title3)

                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    Text(candidate.name)
                        .font(.headline)
                    Text(candidate.primaryEvent)
                        .font(.subheadline)
                        .foregroundStyle(GBColor.Content.secondary)
                    Text(candidate.regionLabel)
                        .font(.caption)
                        .foregroundStyle(GBColor.Content.secondary)
                }

                Spacer()
            }
        }
    }

    private var comparisonCards: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Text("Compare the nearby forts")
                .font(.subheadline.weight(.bold))

            ForEach(challengeCandidates.filter { $0.id != place.id }) { candidate in
                GBSurface(style: .elevated, padding: GBSpacing.small) {
                    HStack(alignment: .top, spacing: GBSpacing.small) {
                        Image(systemName: "arrow.left.and.right.circle.fill")
                            .foregroundStyle(GBColor.Accent.place)
                        VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                            Text("\(candidate.name) vs \(place.name)")
                                .font(.subheadline.weight(.semibold))
                            Text("\(candidate.name): \(candidate.primaryEvent)")
                                .font(.caption)
                                .foregroundStyle(GBColor.Content.secondary)
                            Text("\(place.name): \(place.primaryEvent)")
                                .font(.caption)
                                .foregroundStyle(GBColor.Content.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func schematicBoard(interactive: Bool) -> some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [GBColor.Accent.place.opacity(0.15), GBColor.Accent.story.opacity(0.10), GBColor.Accent.success.opacity(0.08)],
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
                .foregroundStyle(GBColor.Content.secondary.opacity(0.35))

                VStack {
                    HStack {
                        Text("N")
                            .font(.caption.weight(.bold))
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                        Spacer()
                        boardLabel("Plateau trail")
                    }
                    Spacer()
                    HStack {
                        boardLabel("Konkan side")
                        Spacer()
                        boardLabel("Pune side")
                    }
                }
                .padding(GBSpacing.small)

                ForEach(challengeCandidates) { candidate in
                    let isCurrent = candidate.id == place.id
                    let isSelected = selectedCandidateID == candidate.id
                    let showAsCorrect = revealed && isCurrent
                    let showAsMistake = revealed && isSelected && !isCurrent
                    let point = pointForCandidate(candidate, in: geometry.size)
                    let marker = pinMarker(
                        candidate: candidate,
                        isCurrent: isCurrent,
                        isSelected: isSelected,
                        showAsCorrect: showAsCorrect,
                        showAsMistake: showAsMistake,
                        interactive: interactive
                    )

                    Group {
                        if interactive {
                            Button {
                                selectedCandidateID = candidate.id
                                LessonFeedback.fire(.selection)
                            } label: {
                                marker
                            }
                            .buttonStyle(.plain)
                        } else {
                            marker
                        }
                    }
                    .position(point)
                }
            }
        }
    }

    private func boardLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private func pinMarker(
        candidate: Place,
        isCurrent: Bool,
        isSelected: Bool,
        showAsCorrect: Bool,
        showAsMistake: Bool,
        interactive: Bool
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: showAsCorrect ? GBIcon.success : isSelected ? "mappin.circle.fill" : isCurrent && !interactive ? "mappin.circle.fill" : "mappin.circle")
                .font(isCurrent ? .title : .title2)
                .foregroundStyle(showAsCorrect ? GBColor.Accent.success : showAsMistake ? GBColor.Accent.story : isCurrent ? GBColor.Accent.place : GBColor.Content.primary.opacity(0.78))
                .shadow(color: isCurrent ? GBColor.Accent.place.opacity(0.24) : .clear, radius: 10)
            Text(revealed || !interactive || isSelected ? candidate.name : "?")
                .font(.caption2.weight(.bold))
                .foregroundStyle(GBColor.Content.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
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

    private func detailChip(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(GBColor.Content.inverse.opacity(0.82))
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(GBColor.Content.inverse)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: GBRadius.control, style: .continuous))
    }

    private func factRow(title: String, value: String) -> some View {
        GBSurface(style: .elevated, padding: GBSpacing.small) {
            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GBColor.Content.secondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(GBColor.Content.primary)
            }
        }
    }
}

private struct PlaceMapExplorerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let place: Place
    let nearbyPlaces: [Place]

    @State private var cameraPosition: MapCameraPosition

    init(place: Place, nearbyPlaces: [Place]) {
        self.place = place
        self.nearbyPlaces = nearbyPlaces
        _cameraPosition = State(initialValue: .region(Self.region(for: place, nearbyPlaces: nearbyPlaces)))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBSurface(style: .accented(.place)) {
                    VStack(alignment: .leading, spacing: GBSpacing.small) {
                        Text("MapKit place explorer")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.84))
                        Text(place.name)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(GBColor.Content.inverse)
                        Text("See how this fort sits inside the wider region, then return to the fort board to pin it from memory.")
                            .foregroundStyle(GBColor.Content.inverse.opacity(0.92))
                    }
                }

                Map(position: $cameraPosition) {
                    ForEach(nearbyPlaces) { candidate in
                        Annotation(candidate.name, coordinate: candidate.coordinate) {
                            VStack(spacing: 4) {
                                Image(systemName: candidate.id == place.id ? "mappin.circle.fill" : "mappin.circle")
                                    .font(candidate.id == place.id ? .title : .title2)
                                    .foregroundStyle(candidate.id == place.id ? GBColor.Accent.place : GBColor.Content.primary)
                                Text(candidate.name)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))

                GBSurface(style: .elevated) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text("Why this helps")
                            .font(.headline)
                        Text(place.primaryEvent)
                            .font(.subheadline.weight(.semibold))
                        Text("Memory hook: \(place.memoryHook). Region clue: \(place.regionLabel).")
                            .font(.subheadline)
                            .foregroundStyle(GBColor.Content.secondary)
                    }
                }
            }
            .padding()
            .background(GBColor.Background.app)
            .navigationTitle("Map explorer")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private static func region(for place: Place, nearbyPlaces: [Place]) -> MKCoordinateRegion {
        let latitudes = nearbyPlaces.map(\.latitude)
        let longitudes = nearbyPlaces.map(\.longitude)
        let minLatitude = latitudes.min() ?? place.latitude
        let maxLatitude = latitudes.max() ?? place.latitude
        let minLongitude = longitudes.min() ?? place.longitude
        let maxLongitude = longitudes.max() ?? place.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.8, 0.4),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.8, 0.4)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

private func progressColor(_ progress: PlaceProgress) -> Color {
    switch progress {
    case .locked:
        GBColor.State.locked
    case .readyToLearn:
        GBColor.Accent.place
    case .reviewed:
        .blue
    case .masteredLightly:
        GBColor.Accent.success
    }
}

private func progressIcon(_ progress: PlaceProgress) -> String {
    switch progress {
    case .locked:
        GBIcon.locked
    case .readyToLearn:
        GBIcon.reward
    case .reviewed:
        "eye.fill"
    case .masteredLightly:
        "star.fill"
    }
}

private func progressEmphasis(_ progress: PlaceProgress) -> GBEmphasis {
    switch progress {
    case .locked:
        .neutral
    case .readyToLearn, .reviewed, .masteredLightly:
        .place
    }
}
