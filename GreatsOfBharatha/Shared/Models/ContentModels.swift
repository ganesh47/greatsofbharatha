import CoreLocation
import Foundation

struct AppContent: Equatable {
    let heroArcs: [HeroArc]
    let selectedHeroID: String

    init(heroArc: HeroArc) {
        self.heroArcs = [heroArc]
        self.selectedHeroID = heroArc.id
    }

    init(heroArcs: [HeroArc], selectedHeroID: String) {
        self.heroArcs = heroArcs
        self.selectedHeroID = selectedHeroID
    }

    init(arcTitle: String, scenes: [StoryScene], places: [Place], rewards: [ChronicleReward]) {
        self = LegacyAppContentAdapter.makeContent(
            arcTitle: arcTitle,
            scenes: scenes,
            places: places,
            rewards: rewards
        )
    }

    var activeHeroArc: HeroArc {
        heroArcs.first(where: { $0.id == selectedHeroID }) ?? heroArcs[0]
    }

    var arcTitle: String {
        activeHeroArc.title
    }

    var scenes: [StoryScene] {
        activeHeroArc.scenes.map { LegacySceneAdapter.makeStoryScene(from: $0) }
    }

    var places: [Place] {
        activeHeroArc.locationNodes.map { LegacyPlaceAdapter.makePlace(from: $0) }
    }

    var rewards: [ChronicleReward] {
        activeHeroArc.chronicleEntries.map { LegacyChronicleAdapter.makeReward(from: $0) }
    }

    var corePlaces: [Place] {
        places.filter { $0.isCoreReleasePlace }
    }
}

struct StoryScene: Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    let narrativeObjective: String
    let keyFact: String
    let childSafeSummary: String
    let mapAnchors: [String]
    let timelineMarker: String
    let interactionSteps: [String]
    let recallPrompt: RecallPrompt
    let rewardID: String
}

struct Place: Identifiable, Equatable {
    let id: String
    let name: String
    let memoryHook: String
    let primaryEvent: String
    let whyItMatters: String
    let regionLabel: String
    let latitude: Double?
    let longitude: Double?
    let progress: PlaceProgress
    let isCoreReleasePlace: Bool

    init(
        id: String,
        name: String,
        memoryHook: String,
        primaryEvent: String,
        whyItMatters: String,
        regionLabel: String,
        latitude: Double?,
        longitude: Double?,
        progress: PlaceProgress,
        isCoreReleasePlace: Bool
    ) {
        self.id = id
        self.name = name
        self.memoryHook = memoryHook
        self.primaryEvent = primaryEvent
        self.whyItMatters = whyItMatters
        self.regionLabel = regionLabel
        self.latitude = latitude
        self.longitude = longitude
        self.progress = progress
        self.isCoreReleasePlace = isCoreReleasePlace
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var appleMapsDisplayName: String { name }

    var appleMapsHandoff: AppleMapsPlaceHandoff {
        AppleMapsPlaceHandoff(displayName: appleMapsDisplayName, coordinate: coordinate)
    }

    var appleMapsURL: URL? { appleMapsHandoff.url }

    var canOpenInAppleMaps: Bool { appleMapsHandoff.isAvailable }

    static func explorerViewport(for focusPlace: Place, nearbyPlaces: [Place]) -> PlaceExplorerViewport {
        let coordinates = (nearbyPlaces + [focusPlace]).compactMap(\.coordinate)
        let fallback = focusPlace.coordinate ?? CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? fallback.latitude
        let maxLatitude = latitudes.max() ?? fallback.latitude
        let minLongitude = longitudes.min() ?? fallback.longitude
        let maxLongitude = longitudes.max() ?? fallback.longitude

        return PlaceExplorerViewport(
            centerLatitude: (minLatitude + maxLatitude) / 2,
            centerLongitude: (minLongitude + maxLongitude) / 2,
            latitudeDelta: max((maxLatitude - minLatitude) * 1.8, 0.4),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.8, 0.4)
        )
    }
}

struct PlaceExplorerViewport: Equatable {
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
}

struct ChronicleReward: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let meaning: String
    let unlockedBySceneID: String
    let mastery: MasteryState
    let category: RewardCategory
}

struct RecallPrompt: Equatable {
    let question: String
    let answer: String
    let supportText: String
}

enum PlaceProgress: String, CaseIterable, Equatable {
    case locked = "Locked by story"
    case readyToLearn = "Ready to learn"
    case reviewed = "Reviewed"
    case masteredLightly = "Mastered lightly"
}

enum RewardCategory: String, CaseIterable, Equatable {
    case storyCard = "Story Card"
    case emblemFragment = "Emblem Fragment"
    case leadershipBadge = "Leadership Badge"
}

enum LegacySceneAdapter {
    static func makeStoryScene(from scene: SceneCluster) -> StoryScene {
        let recallChallenge = scene.primaryRecallChallenge
        return StoryScene(
            id: scene.id,
            number: scene.sceneNumber,
            title: scene.title,
            narrativeObjective: scene.narrativeObjective,
            keyFact: scene.keyFact,
            childSafeSummary: scene.childSafeSummary,
            mapAnchors: scene.mapAnchorIDs,
            timelineMarker: scene.timelineEventID,
            interactionSteps: [
                "Reveal the opening story moment.",
                "Hear why the moment matters.",
                "Use the memory hook to anchor the place or event.",
                "Answer the recall challenge before collecting the Chronicle keepsake."
            ],
            recallPrompt: RecallPrompt(
                question: recallChallenge?.prompt ?? "Recall the key idea from this scene.",
                answer: recallChallenge?.correctAnswers.first ?? "",
                supportText: recallChallenge?.hintLadder.first?.body ?? scene.meaningStatement
            ),
            rewardID: scene.chronicleEntryIDs.first ?? scene.id + "-reward"
        )
    }
}

enum LegacyPlaceAdapter {
    static func makePlace(from node: LocationNode) -> Place {
        Place(
            id: node.id,
            name: node.name,
            memoryHook: node.memoryHook,
            primaryEvent: node.primaryEvent,
            whyItMatters: node.primaryEvent,
            regionLabel: node.regionLabel,
            latitude: node.canonicalCoordinate.latitude,
            longitude: node.canonicalCoordinate.longitude,
            progress: .locked,
            isCoreReleasePlace: node.isCoreReleasePlace
        )
    }
}

enum LegacyChronicleAdapter {
    static func makeReward(from entry: ChronicleEntry) -> ChronicleReward {
        ChronicleReward(
            id: entry.id,
            title: entry.title,
            subtitle: entry.keepsakeTitle,
            meaning: entry.meaningStatement,
            unlockedBySceneID: entry.linkedSceneID,
            mastery: entry.unlockRule.requiredMastery,
            category: .storyCard
        )
    }
}

enum LegacyAppContentAdapter {
    static func makeContent(arcTitle: String, scenes: [StoryScene], places: [Place], rewards: [ChronicleReward]) -> AppContent {
        let sceneClusters = scenes.map { scene in
            SceneCluster(
                id: scene.id,
                sceneNumber: scene.number,
                title: scene.title,
                narrativeObjective: scene.narrativeObjective,
                keyFact: scene.keyFact,
                meaningStatement: scene.recallPrompt.supportText,
                childSafeSummary: scene.childSafeSummary,
                mapAnchorIDs: scene.mapAnchors,
                timelineEventID: scene.timelineMarker,
                cards: [
                    LearningCard(
                        id: scene.id + "-story",
                        type: .story,
                        title: scene.title,
                        text: scene.childSafeSummary,
                        narration: scene.childSafeSummary,
                        imageKey: scene.id,
                        memoryHook: nil,
                        difficultyBand: .standard
                    )
                ],
                recallChallenges: [
                    RecallChallenge(
                        id: scene.id + "-recall",
                        promptType: .openPrompt,
                        prompt: scene.recallPrompt.question,
                        correctAnswers: [scene.recallPrompt.answer],
                        hintLadder: [RecallHint(level: 1, title: "Story clue", body: scene.recallPrompt.supportText)],
                        feedback: RecallFeedback(success: scene.recallPrompt.supportText, recovery: scene.recallPrompt.supportText),
                        masteryContribution: .understood
                    )
                ],
                chronicleEntryIDs: [scene.rewardID]
            )
        }

        let chronicleEntries = rewards.map { reward in
            ChronicleEntry(
                id: reward.id,
                title: reward.title,
                keepsakeTitle: reward.subtitle,
                meaningStatement: reward.meaning,
                linkedSceneID: reward.unlockedBySceneID,
                linkedPlaceID: nil,
                linkedTimelineEventID: nil,
                unlockRule: UnlockRule(requiredMastery: reward.mastery, enhancedMastery: .chronicled)
            )
        }

        let locationNodes = places.map { place in
            let linkedSceneIDs = sceneClusters
                .filter { scene in
                    scene.mapAnchorIDs.contains(where: { $0.localizedCaseInsensitiveContains(place.name) })
                }
                .map { $0.id }

            return LocationNode(
                id: place.id,
                name: place.name,
                canonicalCoordinate: Coordinate(latitude: place.latitude ?? 0, longitude: place.longitude ?? 0),
                memoryHook: place.memoryHook,
                primaryEvent: place.primaryEvent,
                regionLabel: place.regionLabel,
                linkedSceneIDs: linkedSceneIDs,
                linkedTimelineEventIDs: [],
                unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed),
                isCoreReleasePlace: place.isCoreReleasePlace
            )
        }

        let timelineEvents = sceneClusters.enumerated().map { index, scene in
            let linkedPlaceIDs = locationNodes
                .filter { node in
                    !Set(node.linkedSceneIDs).isDisjoint(with: [scene.id])
                }
                .map { $0.id }

            return TimelineEvent(
                id: scene.timelineEventID,
                title: scene.timelineEventID,
                orderIndex: index,
                broadEraLabel: "Hero journey",
                yearLabel: nil,
                linkedPlaceIDs: linkedPlaceIDs,
                recallPrompt: "Place \(scene.title) in the right sequence.",
                unlockRule: UnlockRule(requiredMastery: .remembered, enhancedMastery: .placed)
            )
        }

        let hero = Hero(
            id: selectedHeroID(for: arcTitle),
            name: arcTitle,
            subtitle: arcTitle,
            culturalFramingNotes: "Migrated from legacy content.",
            ageBandCopyVariants: [.standard: arcTitle]
        )

        let heroArc = HeroArc(
            id: hero.id,
            hero: hero,
            title: arcTitle,
            scenes: sceneClusters,
            chronicleEntries: chronicleEntries,
            locationNodes: locationNodes,
            timelineEvents: timelineEvents,
            reviewBlueprints: []
        )

        return AppContent(heroArc: heroArc)
    }

    private static func selectedHeroID(for arcTitle: String) -> String {
        arcTitle.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}
