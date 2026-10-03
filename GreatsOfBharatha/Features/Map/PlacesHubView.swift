import SwiftUI

struct PlacesHubView: View {
    @EnvironmentObject private var appModel: AppModel
    let places: [Place]
    @State private var selectedAtlasPlace: Place?
    @State private var showsSelectedPlace = false

    private var readyPlaces: [Place] {
        places.filter { appModel.lessonStore.progress(for: $0) != .locked }
    }

    private var firstReadyPlace: Place? {
        readyPlaces.first
    }

    private var clueActivityCount: Int {
        places.filter { place in
            appModel.lessonStore.masteryRecord(for: place.id)?.evidenceLog.contains { $0.type == .recallSuccess } == true
        }.count
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    Text("Find the places in our story").gbHeadline()
                    LearningAtlasView(places: places, selectedPlaceID: selectedAtlasPlace?.id) { place in
                        selectedAtlasPlace = place
                    }
                    if let selectedAtlasPlace {
                        atlasSelectionCard(for: selectedAtlasPlace)
                    }
                    heroCard

                    VStack(alignment: .leading, spacing: context.cardSpacing) {
                        GBSectionHeader(
                            eyebrow: "Place Trail",
                            title: "Choose a place to explore",
                            subtitle: "Pick a ready place and discover its story clue."
                        )

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: context.isTelevision ? 400 : 260), spacing: context.cardSpacing)], spacing: context.cardSpacing) {
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
                                    .buttonStyle(.gbSelection)
                                }
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
#if os(tvOS)
        .navigationTitle("")
#else
        .navigationTitle("Map")
#endif
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .navigationDestination(isPresented: $showsSelectedPlace) {
            if let selectedAtlasPlace, appModel.lessonStore.progress(for: selectedAtlasPlace) != .locked {
                PlaceDetailView(place: selectedAtlasPlace, progress: appModel.lessonStore.progress(for: selectedAtlasPlace))
            }
        }
    }

    private func atlasSelectionCard(for place: Place) -> some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                Text(place.name).gbTitle()
                Text(LearningAtlasContent.relationship(for: place)).gbBody()
                if appModel.lessonStore.progress(for: place) == .locked {
                    Text("Finish this place's story to unlock its activity.")
                        .gbBody()
                        .accessibilityIdentifier("atlas-locked-place")
                } else {
                    Button("Explore \(place.name)") { showsSelectedPlace = true }
                        .buttonStyle(.gbPrimary(.place))
                        .accessibilityIdentifier("atlas-open-selected-place")
                }
            }
        }
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
            title: "Remember the place, not just the story",
            subtitle: "The forts show where the story happened.",
            detail: "Explore each location picture, compare nearby towns, and follow Shivaji Maharaj's journey.",
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
        GBSelectionCard(title: place.name,
            subtitle: progress == .locked ? "Discover this place after its story" : place.memoryHook,
            symbol: place.id == "place-agra" ? "building.2.fill" : GBIcon.fort,
            state: progress == .locked ? .locked : (progress == .reviewed || progress == .masteredLightly ? .discovered : .ready),
            emphasis: .place)
            .accessibilityElement(children: .combine)
    }
}

struct PlaceDetailView: View {
    let place: Place
    let progress: PlaceProgress

    @EnvironmentObject private var appModel: AppModel
    @State private var showsMapExplorer = false
    @State private var showsParentGate = false
    @State private var checkpoint: LearningMapPlaceCheckpoint?

    private var allStoryPlaces: [Place] {
        appModel.content.places
    }

    private var placeGlossaryTerms: [GBGlossaryTerm] {
        let sourceText = [
            place.name,
            place.memoryHook,
            place.primaryEvent,
            place.regionLabel,
            "fort",
        ].joined(separator: " ")
        return GBGlossaryTerm.matching(sourceText)
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    // Simplified header: fort icon + name + why it matters
                    simplifiedHeader

                    if let checkpoint {
                        OfflineFortChallenge(target: place,
                        candidates: LearningAtlasContent.candidates(for: place, places: appModel.content.places),
                        selectedPlaceID: Binding(get: { self.checkpoint?.selectedPlaceID },
                            set: { selected in updateMapCheckpoint { $0.selectedPlaceID = selected } }),
                        solvedPlaceIDs: Binding(get: { self.checkpoint?.wasSolved == true ? [place.id] : [] },
                            set: { solved in updateMapCheckpoint { $0.wasSolved = solved.contains(place.id) } }),
                        helpedPlaceIDs: Binding(get: { self.checkpoint?.usedHelp == true ? [place.id] : [] },
                            set: { helped in updateMapCheckpoint { $0.usedHelp = helped.contains(place.id) } })) { _ in
                            let eventID = LearningMapEvidenceIdentity.eventID(placeID: place.id, sessionID: checkpoint.sessionID)
                            appModel.lessonStore.recordLearningOutcome(subjectID: place.id, subjectType: .location,
                                activity: .recall, wasSuccessful: true, support: .hinted, mastery: .understood,
                                promptType: .eventToPlaceMatch, detail: "Found a fort from an authored clue",
                                eventID: eventID, sessionID: checkpoint.sessionID)
                            _ = appModel.lessonStore.confirmOptionalLearningEvent(eventID, for: .atlas)
                        }.padding(.horizontal, context.containerPadding)
                    } else if !appModel.lessonStore.activityStateIsAvailable(for: .atlas) {
                        Text("This saved map activity could not be opened.").gbBody()
                            .padding(.horizontal, context.containerPadding)
                    }

                    // Kid-friendly fact card
                    kidFactCard(padding: context.containerPadding)

                    GBGlossaryTray(terms: placeGlossaryTerms)
                        .padding(.horizontal, context.containerPadding)

                    // Map buttons
                    VStack(spacing: GBSpacing.small) {
                        Button {
                            showsMapExplorer = true
                        } label: {
                            Label("Explore all story places", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.gbPrimary(.place))

#if os(iOS)
                        if place.canOpenInAppleMaps {
                            VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                                Button {
                                    showsParentGate = true
                                } label: {
                                    Label("Grown-up map option", systemImage: "arrow.up.right.square")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.gbSecondary)
                                .accessibilityLabel("Open \(place.appleMapsDisplayName) in Apple Maps")
                                .accessibilityHint("Grown-up option: opens Apple Maps for directions and place details. Ask a grown-up before planning a visit.")

                                Text("Grown-up option: opens Apple Maps for directions and place details. Ask a grown-up before planning a visit.")
                                    .font(.caption)
                                    .foregroundStyle(GBColor.Content.secondary)
                            }
                        }
#endif
                    }
                    .padding(.horizontal, context.containerPadding)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(.vertical, context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
#if os(iOS)
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
#else
        .navigationTitle("")
#endif
        .onAppear {
            guard checkpoint == nil, var point = appModel.lessonStore.mapPlaceCheckpoint(for: place.id) else { return }
            let candidates = Set(LearningAtlasContent.candidates(for: place, places: allStoryPlaces).map(\.id))
            point.selectedPlaceID = point.selectedPlaceID.flatMap { candidates.contains($0) ? $0 : nil }
            checkpoint = point
        }
#if os(iOS)
        .sheet(isPresented: $showsParentGate) {
            ParentGateView { place.appleMapsHandoff.openInAppleMaps() }
        }
        .navigationDestination(isPresented: $showsMapExplorer) {
            PlaceMapExplorerSheet(place: place, nearbyPlaces: allStoryPlaces)
        }
#endif
    }

    private func updateMapCheckpoint(_ change: (inout LearningMapPlaceCheckpoint) -> Void) {
        guard var point = checkpoint else { return }
        change(&point)
        guard appModel.lessonStore.saveMapPlaceCheckpoint(point, for: place.id) else { return }
        checkpoint = point
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
                        Text(place.primaryEvent)
                        .font(GBFont.story(size: 15, italic: true))
                        .foregroundStyle(.white.opacity(0.88))
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
    @State private var selectedPlace: Place?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GBSpacing.medium) {
                    Text("Compare the places in our story").gbTitle()
                    LearningAtlasView(places: nearbyPlaces, initialPlace: place,
                        selectedPlaceID: selectedPlace?.id) { selectedPlace = $0 }
                    if let selectedPlace {
                        GBSurface(style: .elevated) {
                            VStack(alignment: .leading, spacing: GBSpacing.small) {
                                Text(selectedPlace.name).gbHeadline()
                                Text(selectedPlace.primaryEvent).gbBody()
                                Text(LearningAtlasContent.relationship(for: selectedPlace)).gbBody()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(GBColor.Background.app)
            .navigationTitle("Picture atlas")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
