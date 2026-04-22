import Foundation

enum SampleContent {
    private enum IDs {
        static let heroArc = "hero-shivaji"

        static let scene1 = "scene-1-shivneri"
        static let scene2 = "scene-2-torna-rajgad"
        static let scene3 = "scene-3-rajgad-planning"
        static let scene4 = "scene-4-pratapgad"
        static let scene5 = "scene-5-comeback"
        static let scene6 = "scene-6-raigad"

        static let placeShivneri = "place-shivneri"
        static let placeTorna = "place-torna"
        static let placeRajgad = "place-rajgad"
        static let placePratapgad = "place-pratapgad"
        static let placeRaigad = "place-raigad"
        static let placePurandar = "place-purandar"
        static let placeSinhagad = "place-sinhagad"

        static let eventBirth = "event-birth-fort"
        static let eventFirstFort = "event-first-fort"
        static let eventEarlyCapital = "event-early-capital"
        static let eventTurningPoint = "event-turning-point"
        static let eventComeback = "event-comeback"
        static let eventCoronation = "event-coronation"

        static let chronicleBirth = "chronicle-birth-fort"
        static let chronicleFirstFort = "chronicle-first-fort"
        static let chronicleStrategy = "chronicle-mountain-strategy"
        static let chronicleTurningPoint = "chronicle-turning-point"
        static let chronicleComeback = "chronicle-comeback"
        static let chronicleCoronation = "chronicle-coronation"
    }

    static let shivajiHeroArc = HeroArc(
        id: IDs.heroArc,
        hero: Hero(
            id: "shivaji-maharaj",
            name: "Shivaji Maharaj",
            subtitle: "Build Swarajya through remembered places, events, and meaning",
            culturalFramingNotes: "Use respectful, child-safe framing grounded in curated canon.",
            ageBandCopyVariants: [
                .assist: "Hear the story, remember the fort, and collect one keepsake at a time.",
                .standard: "Remember the place, the turning point, and why it mattered."
            ]
        ),
        title: "Shivaji Arc",
        scenes: [scene1, scene2, scene3, scene4, scene5, scene6],
        chronicleEntries: [birthFortEntry, firstFortEntry, mountainStrategyEntry, turningPointEntry, comebackEntry, coronationEntry],
        locationNodes: [shivneri, torna, rajgad, pratapgad, raigad, purandar, sinhagad],
        timelineEvents: [timelineBirth, timelineTorna, timelineRajgad, timelinePratapgad, timelineComeback, timelineCoronation],
        reviewBlueprints: ReviewSchedule.defaultBlueprints(for: [
            IDs.scene1,
            IDs.scene2,
            IDs.scene3,
            IDs.scene4,
            IDs.scene5,
            IDs.scene6
        ])
    )

    static let shivajiVerticalSlice = AppContent(heroArc: shivajiHeroArc)

    static let scene1 = makeScene(
        id: IDs.scene1,
        number: 1,
        title: "Shivneri, where Shivaji Maharaj's story begins",
        objective: "Meet Shivaji Maharaj as a child and tie the journey to one memorable birthplace.",
        keyFact: "Shivaji Maharaj was born at Shivneri Fort, and Jijabai shaped his early values.",
        meaning: "The journey begins with place, family guidance, and a clear memory hook: Birth Fort.",
        summary: "At Shivneri Fort, young Shivaji began his journey. Jijabai helped him grow brave, caring, and ready to lead.",
        mapAnchors: ["Shivneri Fort", "Junnar", "Hill-fort country north of Pune"],
        timelineEventID: IDs.eventBirth,
        memoryHook: "Birth Fort",
        answer: "Shivneri Fort",
        chronicleEntryID: IDs.chronicleBirth
    )

    static let scene2 = makeScene(
        id: IDs.scene2,
        number: 2,
        title: "Torna and Rajgad, the first steps of Swarajya",
        objective: "Show how early fort victories turned into careful planning and state-building.",
        keyFact: "Torna was an early breakthrough, and Rajgad became an early capital and planning base.",
        meaning: "A remembered breakthrough helps the child connect courage with strategic place-making.",
        summary: "Torna shows the first big mountain breakthrough, and Rajgad turns the journey into careful planning.",
        mapAnchors: ["Torna", "Rajgad", "Mountain routes of western Maharashtra"],
        timelineEventID: IDs.eventFirstFort,
        memoryHook: "Early Capital",
        answer: "Rajgad",
        chronicleEntryID: IDs.chronicleFirstFort
    )

    static let scene3 = makeScene(
        id: IDs.scene3,
        number: 3,
        title: "Rajgad, the planning capital",
        objective: "Link planning, state-building, and place memory through Rajgad.",
        keyFact: "Rajgad became an early capital and planning base for growing Swarajya.",
        meaning: "Children should remember that leadership also means careful planning from the right place.",
        summary: "Rajgad becomes the fort for planning, storing strength, and thinking ahead.",
        mapAnchors: ["Rajgad", "Near Torna", "Mountain planning base"],
        timelineEventID: IDs.eventEarlyCapital,
        memoryHook: "Early Capital",
        answer: "Rajgad",
        chronicleEntryID: IDs.chronicleStrategy
    )

    static let scene4 = makeScene(
        id: IDs.scene4,
        number: 4,
        title: "Pratapgad, the turning point",
        objective: "Teach a decisive turning point through terrain, strategy, and confidence.",
        keyFact: "Pratapgad became a major turning point that showed how terrain and preparation matter.",
        meaning: "The child should remember Pratapgad as the turning-point fort, not just a dramatic battle name.",
        summary: "At Pratapgad, strategy and terrain change the story. A turning point becomes unforgettable.",
        mapAnchors: ["Pratapgad", "Near Mahabaleshwar", "Hill country"],
        timelineEventID: IDs.eventTurningPoint,
        memoryHook: "Turning Point",
        answer: "Pratapgad",
        chronicleEntryID: IDs.chronicleTurningPoint
    )

    static let scene5 = makeScene(
        id: IDs.scene5,
        number: 5,
        title: "Purandar to Sinhagad, pressure and comeback",
        objective: "Hold two related places in memory while teaching pressure, loss, and return.",
        keyFact: "Purandar marks pressure and compromise, while Sinhagad helps children remember comeback and courage.",
        meaning: "History includes setbacks, and remembered places help children see how the story recovers.",
        summary: "The journey faces pressure, then regains confidence. The child learns that courage includes comeback.",
        mapAnchors: ["Purandar", "Sinhagad", "Forts around Pune"],
        timelineEventID: IDs.eventComeback,
        memoryHook: "Pressure to Comeback",
        answer: "Sinhagad",
        chronicleEntryID: IDs.chronicleComeback
    )

    static let scene6 = makeScene(
        id: IDs.scene6,
        number: 6,
        title: "Raigad, the coronation capital",
        objective: "Close the arc with a place, title, and sequence moment that feels ceremonial.",
        keyFact: "Raigad is remembered as the coronation capital where Shivaji Maharaj became Chhatrapati.",
        meaning: "The final scene should tie sovereignty, sequence, and Chronicle completion into one earned moment.",
        summary: "Raigad brings the story to its sovereign climax. The child remembers the coronation capital with pride.",
        mapAnchors: ["Raigad", "Konkan edge of the Sahyadris", "Coronation capital"],
        timelineEventID: IDs.eventCoronation,
        memoryHook: "Coronation Capital",
        answer: "Raigad",
        chronicleEntryID: IDs.chronicleCoronation
    )

    static let shivneri = makeLocation(
        id: IDs.placeShivneri,
        name: "Shivneri",
        hook: "Birth Fort",
        event: "Birth of Shivaji Maharaj",
        region: "Near Junnar, north of Pune",
        latitude: 19.1990,
        longitude: 73.8595,
        linkedSceneIDs: [IDs.scene1],
        linkedTimelineEventIDs: [IDs.eventBirth],
        isCore: true
    )

    static let torna = makeLocation(
        id: IDs.placeTorna,
        name: "Torna",
        hook: "First Big Fort",
        event: "Early breakthrough in the start of Swarajya",
        region: "Sahyadri range, southwest of Pune",
        latitude: 18.2761,
        longitude: 73.6227,
        linkedSceneIDs: [IDs.scene2],
        linkedTimelineEventIDs: [IDs.eventFirstFort],
        isCore: true
    )

    static let rajgad = makeLocation(
        id: IDs.placeRajgad,
        name: "Rajgad",
        hook: "Early Capital",
        event: "Early power center and planning base",
        region: "Sahyadri range, near Torna",
        latitude: 18.2460,
        longitude: 73.6822,
        linkedSceneIDs: [IDs.scene2, IDs.scene3],
        linkedTimelineEventIDs: [IDs.eventFirstFort, IDs.eventEarlyCapital],
        isCore: true
    )

    static let pratapgad = makeLocation(
        id: IDs.placePratapgad,
        name: "Pratapgad",
        hook: "Turning Point",
        event: "Major turning point in Shivaji Maharaj's rise",
        region: "Hill country near Mahabaleshwar",
        latitude: 17.9362,
        longitude: 73.5776,
        linkedSceneIDs: [IDs.scene4],
        linkedTimelineEventIDs: [IDs.eventTurningPoint],
        isCore: true
    )

    static let raigad = makeLocation(
        id: IDs.placeRaigad,
        name: "Raigad",
        hook: "Coronation Capital",
        event: "Coronation as Chhatrapati",
        region: "Konkan edge of the Sahyadris",
        latitude: 18.2335,
        longitude: 73.4406,
        linkedSceneIDs: [IDs.scene6],
        linkedTimelineEventIDs: [IDs.eventCoronation],
        isCore: true
    )

    static let purandar = makeLocation(
        id: IDs.placePurandar,
        name: "Purandar",
        hook: "Pressure Fort",
        event: "Context for later pressure and compromise",
        region: "Southeast of Pune",
        latitude: 18.2808,
        longitude: 73.9736,
        linkedSceneIDs: [IDs.scene5],
        linkedTimelineEventIDs: [IDs.eventComeback],
        isCore: false
    )

    static let sinhagad = makeLocation(
        id: IDs.placeSinhagad,
        name: "Sinhagad",
        hook: "Comeback Fort",
        event: "Remembered comeback and courage",
        region: "Southwest of Pune",
        latitude: 18.3662,
        longitude: 73.7559,
        linkedSceneIDs: [IDs.scene5],
        linkedTimelineEventIDs: [IDs.eventComeback],
        isCore: false
    )

    static let birthFortEntry = makeChronicle(
        id: IDs.chronicleBirth,
        title: "Birth Fort",
        keepsakeTitle: "Journey keepsake",
        meaning: "The Chronicle keeps Shivneri as the place where Shivaji Maharaj's journey begins.",
        sceneID: IDs.scene1,
        placeID: IDs.placeShivneri,
        timelineEventID: IDs.eventBirth
    )

    static let firstFortEntry = makeChronicle(
        id: IDs.chronicleFirstFort,
        title: "First Big Fort",
        keepsakeTitle: "Mountain keepsake",
        meaning: "This keepsake remembers the first fort step and why Rajgad mattered next.",
        sceneID: IDs.scene2,
        placeID: IDs.placeRajgad,
        timelineEventID: IDs.eventFirstFort
    )

    static let mountainStrategyEntry = makeChronicle(
        id: IDs.chronicleStrategy,
        title: "Mountain Strategy",
        keepsakeTitle: "Planning seal",
        meaning: "Rajgad becomes a keepsake about planning well, not just winning quickly.",
        sceneID: IDs.scene3,
        placeID: IDs.placeRajgad,
        timelineEventID: IDs.eventEarlyCapital
    )

    static let turningPointEntry = makeChronicle(
        id: IDs.chronicleTurningPoint,
        title: "Turning Point Seal",
        keepsakeTitle: "Turning-point keepsake",
        meaning: "Pratapgad earns a Chronicle seal only after the child remembers why the turning point mattered.",
        sceneID: IDs.scene4,
        placeID: IDs.placePratapgad,
        timelineEventID: IDs.eventTurningPoint
    )

    static let comebackEntry = makeChronicle(
        id: IDs.chronicleComeback,
        title: "Comeback Crest",
        keepsakeTitle: "Resilience keepsake",
        meaning: "This keepsake marks the journey through pressure and comeback, not a simple straight climb.",
        sceneID: IDs.scene5,
        placeID: IDs.placeSinhagad,
        timelineEventID: IDs.eventComeback
    )

    static let coronationEntry = makeChronicle(
        id: IDs.chronicleCoronation,
        title: "Coronation Seal",
        keepsakeTitle: "Hero page reward",
        meaning: "Raigad becomes the ceremonial final keepsake when the child remembers the coronation capital.",
        sceneID: IDs.scene6,
        placeID: IDs.placeRaigad,
        timelineEventID: IDs.eventCoronation
    )

    static let timelineBirth = makeTimelineEvent(
        id: IDs.eventBirth,
        title: "Birth at Shivneri",
        order: 0,
        era: "Beginning",
        linkedPlaces: [IDs.placeShivneri]
    )

    static let timelineTorna = makeTimelineEvent(
        id: IDs.eventFirstFort,
        title: "Early fort breakthrough at Torna and Rajgad",
        order: 1,
        era: "Early rise",
        linkedPlaces: [IDs.placeTorna, IDs.placeRajgad]
    )

    static let timelineRajgad = makeTimelineEvent(
        id: IDs.eventEarlyCapital,
        title: "Rajgad becomes the planning capital",
        order: 2,
        era: "State-building",
        linkedPlaces: [IDs.placeRajgad]
    )

    static let timelinePratapgad = makeTimelineEvent(
        id: IDs.eventTurningPoint,
        title: "Pratapgad turns the story",
        order: 3,
        era: "Turning point",
        linkedPlaces: [IDs.placePratapgad]
    )

    static let timelineComeback = makeTimelineEvent(
        id: IDs.eventComeback,
        title: "Pressure, recovery, and comeback",
        order: 4,
        era: "Comeback",
        linkedPlaces: [IDs.placePurandar, IDs.placeSinhagad]
    )

    static let timelineCoronation = makeTimelineEvent(
        id: IDs.eventCoronation,
        title: "Coronation at Raigad",
        order: 5,
        era: "Coronation",
        linkedPlaces: [IDs.placeRaigad]
    )

    private static func makeScene(
        id: String,
        number: Int,
        title: String,
        objective: String,
        keyFact: String,
        meaning: String,
        summary: String,
        mapAnchors: [String],
        timelineEventID: String,
        memoryHook: String,
        answer: String,
        chronicleEntryID: String
    ) -> SceneCluster {
        let challenge = RecallChallenge(
            id: id + "-recall",
            promptType: number == 6 ? .sequenceSlot : .openPrompt,
            prompt: number == 6 ? "Which fort is remembered as the coronation capital at the end of the arc?" : "Which place matches this memory hook: \(memoryHook)?",
            correctAnswers: [answer],
            hintLadder: [
                RecallHint(level: 1, title: "Anchor hint", body: "Remember this hook: \(memoryHook)."),
                RecallHint(level: 2, title: "Story hint", body: meaning),
                RecallHint(level: 3, title: "Recognition rescue", body: "Look for the fort tied to \(answer).")
            ],
            feedback: RecallFeedback(
                success: "You got it. \(meaning)",
                recovery: "Good try. \(meaning)"
            ),
            masteryContribution: .understood
        )

        return SceneCluster(
            id: id,
            sceneNumber: number,
            title: title,
            narrativeObjective: objective,
            keyFact: keyFact,
            meaningStatement: meaning,
            childSafeSummary: summary,
            mapAnchorIDs: mapAnchors,
            timelineEventID: timelineEventID,
            cards: [
                LearningCard(id: id + "-story", type: .story, title: title, text: summary, narration: summary, imageKey: id, memoryHook: nil, difficultyBand: .standard),
                LearningCard(id: id + "-meaning", type: .meaning, title: "Why it matters", text: meaning, narration: meaning, imageKey: id + "-meaning", memoryHook: nil, difficultyBand: .standard),
                LearningCard(id: id + "-anchor", type: .anchor, title: memoryHook, text: keyFact, narration: keyFact, imageKey: id + "-anchor", memoryHook: memoryHook, difficultyBand: .standard),
                LearningCard(id: id + "-reward", type: .reward, title: "Chronicle reward", text: "Earn the keepsake by remembering the scene.", narration: "Earn the keepsake by remembering the scene.", imageKey: id + "-reward", memoryHook: memoryHook, difficultyBand: .standard)
            ],
            recallChallenges: [challenge],
            chronicleEntryIDs: [chronicleEntryID]
        )
    }

    private static func makeLocation(
        id: String,
        name: String,
        hook: String,
        event: String,
        region: String,
        latitude: Double,
        longitude: Double,
        linkedSceneIDs: [String],
        linkedTimelineEventIDs: [String],
        isCore: Bool
    ) -> LocationNode {
        LocationNode(
            id: id,
            name: name,
            canonicalCoordinate: Coordinate(latitude: latitude, longitude: longitude),
            memoryHook: hook,
            primaryEvent: event,
            regionLabel: region,
            linkedSceneIDs: linkedSceneIDs,
            linkedTimelineEventIDs: linkedTimelineEventIDs,
            unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed),
            isCoreReleasePlace: isCore
        )
    }

    private static func makeChronicle(
        id: String,
        title: String,
        keepsakeTitle: String,
        meaning: String,
        sceneID: String,
        placeID: String?,
        timelineEventID: String?
    ) -> ChronicleEntry {
        ChronicleEntry(
            id: id,
            title: title,
            keepsakeTitle: keepsakeTitle,
            meaningStatement: meaning,
            linkedSceneID: sceneID,
            linkedPlaceID: placeID,
            linkedTimelineEventID: timelineEventID,
            unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .remembered)
        )
    }

    private static func makeTimelineEvent(
        id: String,
        title: String,
        order: Int,
        era: String,
        linkedPlaces: [String]
    ) -> TimelineEvent {
        TimelineEvent(
            id: id,
            title: title,
            orderIndex: order,
            broadEraLabel: era,
            yearLabel: nil,
            linkedPlaceIDs: linkedPlaces,
            recallPrompt: "Place \(title) in the correct sequence slot.",
            unlockRule: UnlockRule(requiredMastery: .remembered, enhancedMastery: .placed)
        )
    }
}

private extension ReviewSchedule {
    static func defaultBlueprints(for subjectIDs: [String]) -> [ReviewSchedule] {
        subjectIDs.map { subjectID in
            ReviewSchedule(
                subjectID: subjectID,
                subjectType: .scene,
                nextDueAt: .distantFuture,
                intervalIndex: 0,
                stabilityBand: .new,
                difficultyAdjustment: 0,
                cadenceDays: [0, 1, 3, 7, 14]
            )
        }
    }
}
