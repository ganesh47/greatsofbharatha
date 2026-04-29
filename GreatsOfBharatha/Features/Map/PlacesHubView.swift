import MapKit
import SwiftUI

struct PlacesHubView: View {
    @EnvironmentObject private var appModel: AppModel
    let places: [Place]

    private var readyPlaces: [Place] {
        places.filter { appModel.lessonStore.progress(for: $0) != .locked }
    }

    private var firstReadyPlace: Place? {
        readyPlaces.first
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

    @ViewBuilder
    private var heroCard: some View {
        if let firstReadyPlace {
            NavigationLink {
                PlaceDetailView(place: firstReadyPlace, progress: appModel.lessonStore.progress(for: firstReadyPlace))
            } label: {
                placeHeroContent(
                    ctaTitle: "Open \(firstReadyPlace.memoryHook)",
                    badgeTitle: "\(readyPlaces.count) ready now"
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the first ready fort board.")
        } else {
            placeHeroContent(
                ctaTitle: "Finish a story to unlock forts",
                badgeTitle: "0 ready now"
            )
            .accessibilityHint("No forts are ready yet. Finish the next story scene to unlock one.")
        }
    }

    private func placeHeroContent(ctaTitle: String, badgeTitle: String) -> some View {
        GBHeroCard(
            eyebrow: "Sahyadri Fort Trail",
            title: "Remember the place, not just the plot",
            subtitle: "The forts turn the story into a real landscape.",
            detail: "Pin one fort at a time, compare it with nearby mountains, and keep the geography tied to Shivaji Maharaj's journey.",
            ctaTitle: ctaTitle,
            badgeTitle: badgeTitle,
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
    let place: Place
    let progress: PlaceProgress

    @State private var showsMapExplorer = false

    private var allCorePlaces: [Place] {
        SampleContent.shivajiVerticalSlice.corePlaces
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    // Simplified header: fort icon + name + why it matters
                    simplifiedHeader

                    // Real Apple Maps view replacing the abstract schematic board.
                    if place.coordinate != nil {
                        GBFortMapView(place: place)
                            .frame(height: 250)
                            .padding(.horizontal, context.containerPadding)
                    }

                    // Kid-friendly fact card
                    kidFactCard(padding: context.containerPadding)

                    // Map buttons
                    VStack(spacing: GBSpacing.small) {
                        Button {
                            showsMapExplorer = true
                        } label: {
                            Label("See all forts on the map", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.gbPrimary(.place))

                        if place.canOpenInAppleMaps {
                            VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                                Button {
                                    place.appleMapsHandoff.openInAppleMaps()
                                } label: {
                                    Label("Open in Apple Maps", systemImage: "arrow.up.right.square")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.gbSecondary)
                                .accessibilityLabel("Open \(place.appleMapsDisplayName) in Apple Maps")
                                .accessibilityHint("Opens Apple Maps for directions and place details. Ask a grown-up before planning a visit.")

                                Text("Opens Apple Maps for directions and place details. Ask a grown-up before planning a visit.")
                                    .font(.caption)
                                    .foregroundStyle(GBColor.Content.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, context.containerPadding)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(.vertical, context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle(place.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sheet(isPresented: $showsMapExplorer) {
            PlaceMapExplorerSheet(place: place, nearbyPlaces: allCorePlaces)
        }
    }

    private var simplifiedHeader: some View {
        GBSurface(style: .accented(.place)) {
            HStack(spacing: GBSpacing.medium) {
                Image(systemName: GBIcon.fort)
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    Text(place.name)
                        .font(GBFont.display(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(place.primaryEvent)
                        .font(GBFont.story(size: 15, italic: true))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                }

                Spacer()

                GBBadge(title: progress.rawValue, symbol: progressIcon(progress), emphasis: .place)
            }
        }
        .padding(.horizontal, GBSpacing.medium)
    }

    private func kidFactCard(padding: CGFloat) -> some View {
        GBSurface(style: .plain) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                kidFactRow(icon: "star.fill", label: "Memory hook", value: place.memoryHook)
                Divider().overlay(GBColor.Border.default)
                kidFactRow(icon: "bolt.fill", label: "What happened here", value: place.primaryEvent)
                Divider().overlay(GBColor.Border.default)
                kidFactRow(icon: "location.fill", label: "Where", value: place.regionLabel)
            }
        }
        .padding(.horizontal, padding)
    }

    private func kidFactRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: GBSpacing.small) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(GBColor.Place.primary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                Text(label)
                    .font(GBFont.ui(size: 10, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(GBColor.Content.tertiary)
                Text(value)
                    .font(GBFont.ui(size: 15, weight: .semibold))
                    .foregroundStyle(GBColor.Content.primary)
                    .lineSpacing(2)
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
                    ForEach(nearbyPlaces.filter { $0.coordinate != nil }) { candidate in
                        Annotation(candidate.name, coordinate: candidate.coordinate!) {
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
        let viewport = Place.explorerViewport(for: place, nearbyPlaces: nearbyPlaces)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: viewport.centerLatitude,
                longitude: viewport.centerLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: viewport.latitudeDelta,
                longitudeDelta: viewport.longitudeDelta
            )
        )
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
