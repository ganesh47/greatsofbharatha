import Foundation

enum SampleContent {
    static let shivajiVerticalSlice = AppContent(heroArc: shivajiHeroArc)

    static let shivajiHeroArc = HeroArc(
        id: shivajiHero.id,
        hero: shivajiHero,
        title: "Shivaji Arc",
        scenes: [
            sceneCluster1,
            sceneCluster2,
            sceneCluster3,
            sceneCluster4,
            sceneCluster5,
            sceneCluster6,
        ],
        chronicleEntries: [
            birthFortEntry,
            jijabaiGuidanceBadgeEntry,
            dawnAtShivneriEntry,
            firstBigFortEntry,
            planningBadgeEntry,
            mountainSealFragmentEntry,
            turningPointEntry,
            terrainWisdomBadgeEntry,
            lookoutSignalEntry,
            escapeAndReturnEntry,
            northernRouteRibbonEntry,
            patientResolveBadgeEntry,
            comebackEntry,
            rebuildingSealEntry,
            networkRelitBadgeEntry,
            chhatrapatiCrownEntry,
            swarajyaMeaningEntry,
            royalChronicleCompletionEntry,
        ],
        locationNodes: [
            shivneriNode,
            tornaNode,
            rajgadNode,
            pratapgadNode,
            purandarNode,
            agraNode,
            raigadNode,
        ],
        timelineEvents: [
            bornAtShivneriEvent,
            earlyFortsEvent,
            pratapgadTurningPointEvent,
            pressureAtPurandarEvent,
            agraReturnEvent,
            comebackRebuildingEvent,
            raigadCoronationEvent,
        ],
        reviewBlueprints: reviewBlueprints
    )

    static let scene1 = LegacySceneAdapter.makeStoryScene(from: sceneCluster1)
    static let scene2 = LegacySceneAdapter.makeStoryScene(from: sceneCluster2)
    static let scene3 = LegacySceneAdapter.makeStoryScene(from: sceneCluster3)
    static let scene4 = LegacySceneAdapter.makeStoryScene(from: sceneCluster4)
    static let scene5 = LegacySceneAdapter.makeStoryScene(from: sceneCluster5)
    static let scene6 = LegacySceneAdapter.makeStoryScene(from: sceneCluster6)

    static let shivneri = LegacyPlaceAdapter.makePlace(from: shivneriNode)
    static let torna = LegacyPlaceAdapter.makePlace(from: tornaNode)
    static let rajgad = LegacyPlaceAdapter.makePlace(from: rajgadNode)
    static let pratapgad = LegacyPlaceAdapter.makePlace(from: pratapgadNode)
    static let purandar = LegacyPlaceAdapter.makePlace(from: purandarNode)
    static let agra = LegacyPlaceAdapter.makePlace(from: agraNode)
    static let raigad = LegacyPlaceAdapter.makePlace(from: raigadNode)

    static let birthFortCard = LegacyChronicleAdapter.makeReward(from: birthFortEntry)
    static let firstBigFortCard = LegacyChronicleAdapter.makeReward(from: firstBigFortEntry)
    static let mountainSealFragment = LegacyChronicleAdapter.makeReward(from: mountainSealFragmentEntry)
    static let planningBadge = LegacyChronicleAdapter.makeReward(from: planningBadgeEntry)

    private static let shivajiHero = Hero(
        id: "shivaji-maharaj",
        name: "Shivaji Maharaj",
        subtitle: "Retrieval-first Shivaji MVP",
        culturalFramingNotes: "Story-first, child-safe framing centered on place, planning, resilience, and Swarajya.",
        ageBandCopyVariants: [
            .assist: "Shivaji Maharaj's journey through forts, courage, and self-rule.",
            .standard: "Follow Shivaji Maharaj from Shivneri to Raigad through six calm, recall-first story scenes.",
        ]
    )

    private static let sceneCluster1 = SceneCluster(
        id: "scene-1-shivneri",
        sceneNumber: 1,
        title: "Shivneri, where Shivaji Maharaj's story begins",
        narrativeObjective: "Introduce Shivaji Maharaj as a child shaped by place, courage, and Jijabai's guidance.",
        keyFact: "Shivaji Maharaj was born at Shivneri Fort, and Jijabai shaped his early values.",
        meaningStatement: "Shivneri matters because it anchors the beginning of Shivaji Maharaj's journey and the values he carried forward.",
        childSafeSummary: "At Shivneri Fort, young Shivaji began his journey. Jijabai helped him grow brave, caring, and ready to lead.",
        mapAnchorIDs: ["place-shivneri"],
        timelineEventID: bornAtShivneriEvent.id,
        cards: [
            makeCard(sceneID: "scene-1-shivneri", type: .story, title: "Hook", text: "A child named Shivaji begins at a hill fort above Junnar.", memoryHook: "Birth Fort"),
            makeCard(sceneID: "scene-1-shivneri", type: .meaning, title: "Why this matters", text: "Great journeys begin in real places, with real guidance and values."),
            makeCard(sceneID: "scene-1-shivneri", type: .anchor, title: "Anchor", text: "Remember Shivneri as the Birth Fort."),
            makeCard(sceneID: "scene-1-shivneri", type: .recall, title: "Recall", text: "Name the fort where Shivaji Maharaj was born."),
            makeCard(sceneID: "scene-1-shivneri", type: .reward, title: "Reward", text: "Unlock the Birth Fort keepsake in the Chronicle."),
        ],
        recallChallenges: [
            RecallChallenge(
                id: "scene-1-shivneri-recall",
                promptType: .openPrompt,
                prompt: "Which fort is Shivaji Maharaj's birth place?",
                correctAnswers: ["Shivneri Fort", "Shivneri"],
                hintLadder: [
                    RecallHint(level: 1, title: "Anchor hint", body: "Think about the Birth Fort."),
                    RecallHint(level: 2, title: "Place hint", body: "It is near Junnar, north of Pune."),
                    RecallHint(level: 3, title: "Category hint", body: "It is a hill fort where the story begins."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. Shivneri Fort is remembered as Shivaji Maharaj's birth place.",
                    recovery: "Shivneri is the Birth Fort where the journey begins."
                ),
                masteryContribution: .understood
            )
        ],
        chronicleEntryIDs: [birthFortEntry.id, jijabaiGuidanceBadgeEntry.id, dawnAtShivneriEntry.id]
    )

    private static let sceneCluster2 = SceneCluster(
        id: "scene-2-torna-rajgad",
        sceneNumber: 2,
        title: "Torna and Rajgad, the first steps of Swarajya",
        narrativeObjective: "Show how early fort victories turned into careful planning and state-building.",
        keyFact: "Torna was an early breakthrough, and Rajgad became an early capital and planning base.",
        meaningStatement: "The early forts matter because Shivaji Maharaj did not just win space, he built a stronger base for Swarajya.",
        childSafeSummary: "Shivaji Maharaj began building Swarajya by winning key forts and planning from the mountains.",
        mapAnchorIDs: ["place-torna", "place-rajgad"],
        timelineEventID: earlyFortsEvent.id,
        cards: [
            makeCard(sceneID: "scene-2-torna-rajgad", type: .story, title: "Hook", text: "The map stretches from childhood into action at Torna and Rajgad.", memoryHook: "First Big Fort"),
            makeCard(sceneID: "scene-2-torna-rajgad", type: .meaning, title: "Why this matters", text: "Winning and holding forts made planning and protection possible."),
            makeCard(sceneID: "scene-2-torna-rajgad", type: .anchor, title: "Anchor", text: "Torna comes first. Rajgad becomes the early capital."),
            makeCard(sceneID: "scene-2-torna-rajgad", type: .recall, title: "Recall", text: "Which fort became the early capital?"),
            makeCard(sceneID: "scene-2-torna-rajgad", type: .reward, title: "Reward", text: "Collect the First Big Fort keepsake and planning symbols."),
        ],
        recallChallenges: [
            RecallChallenge(
                id: "scene-2-torna-rajgad-recall",
                promptType: .compareFromMemory,
                prompt: "Which fort became an early capital?",
                correctAnswers: ["Rajgad"],
                hintLadder: [
                    RecallHint(level: 1, title: "Anchor hint", body: "Torna is the first big fort, but not the capital."),
                    RecallHint(level: 2, title: "Pair hint", body: "Think of the fort that came next and supported planning."),
                    RecallHint(level: 3, title: "Meaning hint", body: "It became an early capital and power center."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. Rajgad became an early capital and planning base.",
                    recovery: "Rajgad is the early capital, while Torna marks the early breakthrough."
                ),
                masteryContribution: .observedClosely
            )
        ],
        chronicleEntryIDs: [firstBigFortEntry.id, planningBadgeEntry.id, mountainSealFragmentEntry.id]
    )

    private static let sceneCluster3 = SceneCluster(
        id: "scene-3-pratapgad-turning-point",
        sceneNumber: 3,
        title: "Pratapgad, a turning point in the mountains",
        narrativeObjective: "Teach that terrain, planning, and nerve changed the balance at a dangerous moment.",
        keyFact: "The confrontation near Pratapgad in 1659 became a major turning point in Shivaji Maharaj's rise.",
        meaningStatement: "Pratapgad matters because planning and terrain can shift a difficult situation without turning the lesson into gore or spectacle.",
        childSafeSummary: "At Pratapgad, Shivaji Maharaj used planning, local terrain, and courage in a dangerous moment.",
        mapAnchorIDs: ["place-pratapgad"],
        timelineEventID: pratapgadTurningPointEvent.id,
        cards: [
            makeCard(sceneID: "scene-3-pratapgad-turning-point", type: .story, title: "Hook", text: "Mist, hills, and lookout points make the mountain fort feel tense and important.", memoryHook: "Turning Point"),
            makeCard(sceneID: "scene-3-pratapgad-turning-point", type: .meaning, title: "Why this matters", text: "Preparation and terrain can change what happens next."),
            makeCard(sceneID: "scene-3-pratapgad-turning-point", type: .anchor, title: "Anchor", text: "Remember Pratapgad as the turning point fort."),
            makeCard(sceneID: "scene-3-pratapgad-turning-point", type: .recall, title: "Recall", text: "Name the fort where the turning point happened."),
            makeCard(sceneID: "scene-3-pratapgad-turning-point", type: .reward, title: "Reward", text: "Unlock the Turning Point keepsake and terrain badge."),
        ],
        recallChallenges: [
            RecallChallenge(
                id: "scene-3-pratapgad-turning-point-recall",
                promptType: .openPrompt,
                prompt: "At which fort did a major turning point happen?",
                correctAnswers: ["Pratapgad"],
                hintLadder: [
                    RecallHint(level: 1, title: "Anchor hint", body: "Think about the fort remembered as a Turning Point."),
                    RecallHint(level: 2, title: "Terrain hint", body: "It stands in steep hill country near Mahabaleshwar."),
                    RecallHint(level: 3, title: "Meaning hint", body: "This fort teaches planning, lookout points, and terrain."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. Pratapgad marks a major turning point in Shivaji Maharaj's rise.",
                    recovery: "Pratapgad is the turning point fort in the hill country."
                ),
                masteryContribution: .understood
            )
        ],
        chronicleEntryIDs: [turningPointEntry.id, terrainWisdomBadgeEntry.id, lookoutSignalEntry.id]
    )

    private static let sceneCluster4 = SceneCluster(
        id: "scene-4-purandar-agra",
        sceneNumber: 4,
        title: "Purandar to Agra, pressure and escape",
        narrativeObjective: "Teach setback, hard compromise, and clever survival.",
        keyFact: "Purandar brought heavy pressure, and Agra became the northern city where Shivaji Maharaj was held under close watch before returning.",
        meaningStatement: "This scene matters because leaders sometimes face pressure, make hard choices, and still find a way back with patience and planning.",
        childSafeSummary: "Sometimes leaders face hard pressure. Shivaji Maharaj made a difficult agreement, then later found a clever way to return home.",
        mapAnchorIDs: ["place-purandar", "place-agra"],
        timelineEventID: agraReturnEvent.id,
        cards: [
            makeCard(sceneID: "scene-4-purandar-agra", type: .story, title: "Hook", text: "The journey stretches far from Maharashtra to the Mughal court in Agra.", memoryHook: "Escape and Return"),
            makeCard(sceneID: "scene-4-purandar-agra", type: .meaning, title: "Why this matters", text: "Setbacks do not end the story when patience and planning stay alive."),
            makeCard(sceneID: "scene-4-purandar-agra", type: .anchor, title: "Anchor", text: "Purandar brings pressure. Agra is the northern city under watch."),
            makeCard(sceneID: "scene-4-purandar-agra", type: .recall, title: "Recall", text: "Which happened first, Purandar or Agra?"),
            makeCard(sceneID: "scene-4-purandar-agra", type: .reward, title: "Reward", text: "Earn the Escape and Return keepsake and northern-route ribbon."),
        ],
        recallChallenges: [
            RecallChallenge(
                id: "scene-4-purandar-agra-recall",
                promptType: .sequenceSlot,
                prompt: "Which happened first, Purandar or Agra?",
                correctAnswers: ["Purandar"],
                hintLadder: [
                    RecallHint(level: 1, title: "Anchor hint", body: "Pressure comes before the northern court scene."),
                    RecallHint(level: 2, title: "Map hint", body: "Think first of the fort near Pune, then the city in the north."),
                    RecallHint(level: 3, title: "Meaning hint", body: "The agreement at Purandar came before the period under watch in Agra."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. Purandar comes first, then Agra and the return.",
                    recovery: "Purandar is the earlier pressure point. Agra comes after it."
                ),
                masteryContribution: .remembered
            )
        ],
        chronicleEntryIDs: [escapeAndReturnEntry.id, northernRouteRibbonEntry.id, patientResolveBadgeEntry.id]
    )

    private static let sceneCluster5 = SceneCluster(
        id: "scene-5-rajgad-recovery",
        sceneNumber: 5,
        title: "Recovery of strength, rebuilding after Agra",
        narrativeObjective: "Show resilience, rebuilding, and regained confidence after setbacks.",
        keyFact: "After Agra, Shivaji Maharaj rebuilt strength, reorganized, and returned to growth.",
        meaningStatement: "Recovery matters because strength can be rebuilt through steady organization, not only dramatic moments.",
        childSafeSummary: "After a difficult time, Shivaji Maharaj did not give up. He rebuilt, reorganized, and grew stronger again.",
        mapAnchorIDs: ["place-rajgad"],
        timelineEventID: comebackRebuildingEvent.id,
        cards: [
            makeCard(sceneID: "scene-5-rajgad-recovery", type: .story, title: "Hook", text: "The network of forts begins to glow again as the comeback starts.", memoryHook: "Comeback"),
            makeCard(sceneID: "scene-5-rajgad-recovery", type: .meaning, title: "Why this matters", text: "Resilience is part of leadership, especially after a setback."),
            makeCard(sceneID: "scene-5-rajgad-recovery", type: .anchor, title: "Anchor", text: "Remember Rajgad as the comeback anchor."),
            makeCard(sceneID: "scene-5-rajgad-recovery", type: .recall, title: "Recall", text: "What did Shivaji Maharaj do after returning from Agra?"),
            makeCard(sceneID: "scene-5-rajgad-recovery", type: .reward, title: "Reward", text: "Collect the Comeback keepsake and rebuilding symbols."),
        ],
        recallChallenges: [
            RecallChallenge(
                id: "scene-5-rajgad-recovery-recall",
                promptType: .openPrompt,
                prompt: "What did Shivaji Maharaj do after returning from Agra?",
                correctAnswers: ["He rebuilt strength", "He rebuilt and reorganized", "He rebuilt, reorganized, and grew stronger again"],
                hintLadder: [
                    RecallHint(level: 1, title: "Anchor hint", body: "Think about the comeback scene at Rajgad."),
                    RecallHint(level: 2, title: "Action hint", body: "The answer is about rebuilding and reorganizing."),
                    RecallHint(level: 3, title: "Meaning hint", body: "He returned to growth instead of giving up."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. After Agra, Shivaji Maharaj rebuilt strength, reorganized, and grew stronger again.",
                    recovery: "The comeback scene is about rebuilding, reorganizing, and returning to growth."
                ),
                masteryContribution: .understood
            )
        ],
        chronicleEntryIDs: [comebackEntry.id, rebuildingSealEntry.id, networkRelitBadgeEntry.id]
    )

    private static let sceneCluster6 = SceneCluster(
        id: "scene-6-raigad-coronation",
        sceneNumber: 6,
        title: "Raigad, coronation as Chhatrapati",
        narrativeObjective: "Deliver the sovereign climax and explain why Shivaji Maharaj mattered.",
        keyFact: "At Raigad in 1674, Shivaji Maharaj was crowned Chhatrapati, marking a major moment of self-rule and sovereign kingship.",
        meaningStatement: "Raigad matters because the coronation turns the journey into a clear statement of Swarajya and responsibility.",
        childSafeSummary: "At Raigad, Shivaji Maharaj was crowned Chhatrapati. This marked the rise of self-rule, or Swarajya.",
        mapAnchorIDs: ["place-raigad"],
        timelineEventID: raigadCoronationEvent.id,
        cards: [
            makeCard(sceneID: "scene-6-raigad-coronation", type: .story, title: "Hook", text: "Symbols gathered across the arc come together at Raigad.", memoryHook: "Coronation Capital"),
            makeCard(sceneID: "scene-6-raigad-coronation", type: .meaning, title: "Why this matters", text: "The coronation shows self-rule, dignity, and responsibility."),
            makeCard(sceneID: "scene-6-raigad-coronation", type: .anchor, title: "Anchor", text: "Remember Raigad as the Coronation Capital."),
            makeCard(sceneID: "scene-6-raigad-coronation", type: .recall, title: "Recall", text: "At which fort was Shivaji Maharaj crowned Chhatrapati?"),
            makeCard(sceneID: "scene-6-raigad-coronation", type: .reward, title: "Reward", text: "Complete the Chronicle page with the Chhatrapati Crown."),
        ],
        recallChallenges: [
            RecallChallenge(
                id: "scene-6-raigad-coronation-recall",
                promptType: .openPrompt,
                prompt: "At which fort was Shivaji Maharaj crowned Chhatrapati?",
                correctAnswers: ["Raigad"],
                hintLadder: [
                    RecallHint(level: 1, title: "Anchor hint", body: "Think about the Coronation Capital."),
                    RecallHint(level: 2, title: "Scene hint", body: "It is the final fort in the arc, on the Konkan edge of the Sahyadris."),
                    RecallHint(level: 3, title: "Meaning hint", body: "This fort marks the rise of self-rule, or Swarajya."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. Raigad is the fort of the coronation as Chhatrapati.",
                    recovery: "Raigad is remembered as the Coronation Capital where the journey reaches Swarajya."
                ),
                masteryContribution: .remembered
            )
        ],
        chronicleEntryIDs: [chhatrapatiCrownEntry.id, swarajyaMeaningEntry.id, royalChronicleCompletionEntry.id]
    )

    private static let birthFortEntry = makeChronicleEntry(
        id: "reward-birth-fort-card",
        title: "Birth Fort",
        keepsakeTitle: "Journey keepsake card",
        meaning: "The Chronicle keeps the memory of Shivneri Fort, where Shivaji Maharaj's journey begins.",
        sceneID: "scene-1-shivneri",
        placeID: "place-shivneri",
        timelineEventID: bornAtShivneriEvent.id,
        requiredMastery: .witnessed,
        enhancedMastery: .understood
    )

    private static let jijabaiGuidanceBadgeEntry = makeChronicleEntry(
        id: "reward-jijabai-guidance-badge",
        title: "Jijabai's Guidance",
        keepsakeTitle: "Leadership badge",
        meaning: "This badge remembers that courage and duty were taught through Jijabai's guidance.",
        sceneID: "scene-1-shivneri",
        placeID: "place-shivneri",
        timelineEventID: bornAtShivneriEvent.id,
        requiredMastery: .understood,
        enhancedMastery: .observedClosely
    )

    private static let dawnAtShivneriEntry = makeChronicleEntry(
        id: "reward-dawn-at-shivneri",
        title: "Dawn at Shivneri",
        keepsakeTitle: "Emblem fragment",
        meaning: "A dawn fragment for remembering that great journeys can begin quietly, in one strong place.",
        sceneID: "scene-1-shivneri",
        placeID: "place-shivneri",
        timelineEventID: bornAtShivneriEvent.id,
        requiredMastery: .observedClosely,
        enhancedMastery: .remembered
    )

    private static let firstBigFortEntry = makeChronicleEntry(
        id: "reward-first-big-fort-card",
        title: "First Big Fort",
        keepsakeTitle: "Journey keepsake card",
        meaning: "This keepsake remembers Torna as an early breakthrough in building Swarajya.",
        sceneID: "scene-2-torna-rajgad",
        placeID: "place-torna",
        timelineEventID: earlyFortsEvent.id,
        requiredMastery: .witnessed,
        enhancedMastery: .understood
    )

    private static let planningBadgeEntry = makeChronicleEntry(
        id: "reward-planning-badge",
        title: "Planning Badge",
        keepsakeTitle: "Leadership badge",
        meaning: "A keepsake badge for noticing that careful planning helped the early forts become a stronger base.",
        sceneID: "scene-2-torna-rajgad",
        placeID: "place-rajgad",
        timelineEventID: earlyFortsEvent.id,
        requiredMastery: .understood,
        enhancedMastery: .observedClosely
    )

    private static let mountainSealFragmentEntry = makeChronicleEntry(
        id: "reward-mountain-seal-fragment",
        title: "Mountain Seal Fragment",
        keepsakeTitle: "Emblem fragment",
        meaning: "A mountain emblem fragment earned by linking Torna and Rajgad to the growing idea of Swarajya.",
        sceneID: "scene-2-torna-rajgad",
        placeID: "place-rajgad",
        timelineEventID: earlyFortsEvent.id,
        requiredMastery: .observedClosely,
        enhancedMastery: .remembered
    )

    private static let turningPointEntry = makeChronicleEntry(
        id: "reward-turning-point-card",
        title: "Turning Point",
        keepsakeTitle: "Journey keepsake card",
        meaning: "This keepsake remembers Pratapgad as the moment when planning and terrain changed the balance.",
        sceneID: "scene-3-pratapgad-turning-point",
        placeID: "place-pratapgad",
        timelineEventID: pratapgadTurningPointEvent.id,
        requiredMastery: .witnessed,
        enhancedMastery: .understood
    )

    private static let terrainWisdomBadgeEntry = makeChronicleEntry(
        id: "reward-terrain-wisdom-badge",
        title: "Terrain Wisdom",
        keepsakeTitle: "Leadership badge",
        meaning: "A badge for remembering that local terrain can be part of good preparation and judgment.",
        sceneID: "scene-3-pratapgad-turning-point",
        placeID: "place-pratapgad",
        timelineEventID: pratapgadTurningPointEvent.id,
        requiredMastery: .understood,
        enhancedMastery: .observedClosely
    )

    private static let lookoutSignalEntry = makeChronicleEntry(
        id: "reward-lookout-signal",
        title: "Lookout Signal",
        keepsakeTitle: "Emblem fragment",
        meaning: "This Chronicle fragment remembers the calm signals and readiness that mattered before the turning point.",
        sceneID: "scene-3-pratapgad-turning-point",
        placeID: "place-pratapgad",
        timelineEventID: pratapgadTurningPointEvent.id,
        requiredMastery: .observedClosely,
        enhancedMastery: .remembered
    )

    private static let escapeAndReturnEntry = makeChronicleEntry(
        id: "reward-escape-and-return-card",
        title: "Escape and Return",
        keepsakeTitle: "Journey keepsake card",
        meaning: "This keepsake remembers that the journey passed through pressure, close watch, and a careful return.",
        sceneID: "scene-4-purandar-agra",
        placeID: "place-agra",
        timelineEventID: agraReturnEvent.id,
        requiredMastery: .witnessed,
        enhancedMastery: .understood
    )

    private static let northernRouteRibbonEntry = makeChronicleEntry(
        id: "reward-northern-route-ribbon",
        title: "Northern Route Ribbon",
        keepsakeTitle: "Route ribbon",
        meaning: "A ribbon for remembering how far the journey stretched, from Purandar pressure to Agra and back.",
        sceneID: "scene-4-purandar-agra",
        placeID: "place-agra",
        timelineEventID: agraReturnEvent.id,
        requiredMastery: .understood,
        enhancedMastery: .observedClosely
    )

    private static let patientResolveBadgeEntry = makeChronicleEntry(
        id: "reward-patient-resolve-badge",
        title: "Patient Resolve",
        keepsakeTitle: "Leadership badge",
        meaning: "This badge honors patience, resilience, and clever survival during a difficult stretch of the story.",
        sceneID: "scene-4-purandar-agra",
        placeID: "place-purandar",
        timelineEventID: pressureAtPurandarEvent.id,
        requiredMastery: .observedClosely,
        enhancedMastery: .remembered
    )

    private static let comebackEntry = makeChronicleEntry(
        id: "reward-comeback-card",
        title: "Comeback",
        keepsakeTitle: "Journey keepsake card",
        meaning: "This keepsake remembers that Shivaji Maharaj rebuilt strength after returning from Agra.",
        sceneID: "scene-5-rajgad-recovery",
        placeID: "place-rajgad",
        timelineEventID: comebackRebuildingEvent.id,
        requiredMastery: .witnessed,
        enhancedMastery: .understood
    )

    private static let rebuildingSealEntry = makeChronicleEntry(
        id: "reward-rebuilding-seal-fragment",
        title: "Rebuilding Seal",
        keepsakeTitle: "Emblem fragment",
        meaning: "A seal fragment for remembering that recovery comes from reorganizing, reconnecting, and growing stronger again.",
        sceneID: "scene-5-rajgad-recovery",
        placeID: "place-rajgad",
        timelineEventID: comebackRebuildingEvent.id,
        requiredMastery: .understood,
        enhancedMastery: .observedClosely
    )

    private static let networkRelitBadgeEntry = makeChronicleEntry(
        id: "reward-network-relit-badge",
        title: "Network Relit",
        keepsakeTitle: "Leadership badge",
        meaning: "This badge marks the return of confidence and connected strength across the mountain network.",
        sceneID: "scene-5-rajgad-recovery",
        placeID: "place-rajgad",
        timelineEventID: comebackRebuildingEvent.id,
        requiredMastery: .observedClosely,
        enhancedMastery: .remembered
    )

    private static let chhatrapatiCrownEntry = makeChronicleEntry(
        id: "reward-chhatrapati-crown-card",
        title: "Chhatrapati Crown",
        keepsakeTitle: "Journey keepsake card",
        meaning: "This final keepsake remembers the coronation at Raigad and the rise of self-rule.",
        sceneID: "scene-6-raigad-coronation",
        placeID: "place-raigad",
        timelineEventID: raigadCoronationEvent.id,
        requiredMastery: .witnessed,
        enhancedMastery: .understood
    )

    private static let swarajyaMeaningEntry = makeChronicleEntry(
        id: "reward-swarajya-meaning-badge",
        title: "Swarajya Meaning",
        keepsakeTitle: "Leadership badge",
        meaning: "A badge for understanding that Raigad stands for self-rule, dignity, and responsibility.",
        sceneID: "scene-6-raigad-coronation",
        placeID: "place-raigad",
        timelineEventID: raigadCoronationEvent.id,
        requiredMastery: .understood,
        enhancedMastery: .observedClosely
    )

    private static let royalChronicleCompletionEntry = makeChronicleEntry(
        id: "reward-royal-chronicle-completion",
        title: "Royal Chronicle Complete",
        keepsakeTitle: "Chronicle completion emblem",
        meaning: "The first Chronicle page comes together only after the full six-scene journey is remembered with meaning.",
        sceneID: "scene-6-raigad-coronation",
        placeID: "place-raigad",
        timelineEventID: raigadCoronationEvent.id,
        requiredMastery: .remembered,
        enhancedMastery: .chronicled
    )

    private static let shivneriNode = makeLocationNode(
        id: "place-shivneri",
        name: "Shivneri",
        latitude: 19.1990,
        longitude: 73.8595,
        memoryHook: "Birth Fort",
        primaryEvent: "Birth of Shivaji Maharaj",
        regionLabel: "Near Junnar, north of Pune",
        linkedSceneIDs: ["scene-1-shivneri"],
        linkedTimelineEventIDs: [bornAtShivneriEvent.id],
        isCoreReleasePlace: true
    )

    private static let tornaNode = makeLocationNode(
        id: "place-torna",
        name: "Torna",
        latitude: 18.2761,
        longitude: 73.6227,
        memoryHook: "First Big Fort",
        primaryEvent: "Early breakthrough in the start of Swarajya",
        regionLabel: "Sahyadri range, southwest of Pune",
        linkedSceneIDs: ["scene-2-torna-rajgad"],
        linkedTimelineEventIDs: [earlyFortsEvent.id],
        isCoreReleasePlace: true
    )

    private static let rajgadNode = makeLocationNode(
        id: "place-rajgad",
        name: "Rajgad",
        latitude: 18.2460,
        longitude: 73.6822,
        memoryHook: "Early Capital",
        primaryEvent: "Early power center, planning base, and comeback anchor",
        regionLabel: "Sahyadri range near Torna",
        linkedSceneIDs: ["scene-2-torna-rajgad", "scene-5-rajgad-recovery"],
        linkedTimelineEventIDs: [earlyFortsEvent.id, comebackRebuildingEvent.id],
        isCoreReleasePlace: true
    )

    private static let pratapgadNode = makeLocationNode(
        id: "place-pratapgad",
        name: "Pratapgad",
        latitude: 17.9362,
        longitude: 73.5776,
        memoryHook: "Turning Point",
        primaryEvent: "Major turning point in Shivaji Maharaj's rise",
        regionLabel: "Hill country near Mahabaleshwar",
        linkedSceneIDs: ["scene-3-pratapgad-turning-point"],
        linkedTimelineEventIDs: [pratapgadTurningPointEvent.id],
        isCoreReleasePlace: true
    )

    private static let purandarNode = makeLocationNode(
        id: "place-purandar",
        name: "Purandar",
        latitude: 18.2808,
        longitude: 73.9736,
        memoryHook: "Pressure Fort",
        primaryEvent: "Pressure, compromise, and a difficult agreement",
        regionLabel: "Southeast of Pune",
        linkedSceneIDs: ["scene-4-purandar-agra"],
        linkedTimelineEventIDs: [pressureAtPurandarEvent.id],
        isCoreReleasePlace: false
    )

    private static let agraNode = makeLocationNode(
        id: "place-agra",
        name: "Agra",
        latitude: 27.1767,
        longitude: 78.0081,
        memoryHook: "Northern Court",
        primaryEvent: "Close watch, patience, and return",
        regionLabel: "Northern India on the Yamuna",
        linkedSceneIDs: ["scene-4-purandar-agra"],
        linkedTimelineEventIDs: [agraReturnEvent.id],
        isCoreReleasePlace: false
    )

    private static let raigadNode = makeLocationNode(
        id: "place-raigad",
        name: "Raigad",
        latitude: 18.2335,
        longitude: 73.4406,
        memoryHook: "Coronation Capital",
        primaryEvent: "Coronation as Chhatrapati",
        regionLabel: "Konkan edge of the Sahyadris",
        linkedSceneIDs: ["scene-6-raigad-coronation"],
        linkedTimelineEventIDs: [raigadCoronationEvent.id],
        isCoreReleasePlace: true
    )

    private static let bornAtShivneriEvent = TimelineEvent(
        id: "timeline-born-at-shivneri",
        title: "Born at Shivneri",
        orderIndex: 0,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: "commonly commemorated as 1630",
        linkedPlaceIDs: ["place-shivneri"],
        recallPrompt: "Place Born at Shivneri first in the story sequence.",
        unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed)
    )

    private static let earlyFortsEvent = TimelineEvent(
        id: "timeline-early-forts",
        title: "Early forts",
        orderIndex: 1,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: "c. 1646 to 1654",
        linkedPlaceIDs: ["place-torna", "place-rajgad"],
        recallPrompt: "Place the early forts after Shivneri and before Pratapgad.",
        unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed)
    )

    private static let pratapgadTurningPointEvent = TimelineEvent(
        id: "timeline-pratapgad-turning-point",
        title: "Pratapgad changes everything",
        orderIndex: 2,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: "1659",
        linkedPlaceIDs: ["place-pratapgad"],
        recallPrompt: "Place the Pratapgad turning point after the early forts.",
        unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed)
    )

    private static let pressureAtPurandarEvent = TimelineEvent(
        id: "timeline-pressure-at-purandar",
        title: "Pressure at Purandar",
        orderIndex: 3,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: "1665",
        linkedPlaceIDs: ["place-purandar"],
        recallPrompt: "Place Purandar before the northern Agra episode.",
        unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed)
    )

    private static let agraReturnEvent = TimelineEvent(
        id: "timeline-agra-and-return",
        title: "Agra and return",
        orderIndex: 4,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: "1666",
        linkedPlaceIDs: ["place-agra"],
        recallPrompt: "Place Agra and return after Purandar and before the comeback.",
        unlockRule: UnlockRule(requiredMastery: .remembered, enhancedMastery: .placed)
    )

    private static let comebackRebuildingEvent = TimelineEvent(
        id: "timeline-comeback-and-rebuilding",
        title: "Comeback and rebuilding",
        orderIndex: 5,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: nil,
        linkedPlaceIDs: ["place-rajgad"],
        recallPrompt: "Place the comeback after the return from Agra.",
        unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed)
    )

    private static let raigadCoronationEvent = TimelineEvent(
        id: "timeline-raigad-coronation",
        title: "Raigad coronation",
        orderIndex: 6,
        broadEraLabel: "Shivaji Maharaj's journey",
        yearLabel: "1674",
        linkedPlaceIDs: ["place-raigad"],
        recallPrompt: "Place Raigad coronation as the sovereign climax of the arc.",
        unlockRule: UnlockRule(requiredMastery: .remembered, enhancedMastery: .placed)
    )

    private static let reviewBlueprints: [ReviewSchedule] =
        reviewSchedules(for: [
            ("scene-1-shivneri", .scene),
            ("scene-2-torna-rajgad", .scene),
            ("scene-3-pratapgad-turning-point", .scene),
            ("scene-4-purandar-agra", .scene),
            ("scene-5-rajgad-recovery", .scene),
            ("scene-6-raigad-coronation", .scene),
            ("place-shivneri", .location),
            ("place-torna", .location),
            ("place-rajgad", .location),
            ("place-pratapgad", .location),
            ("place-purandar", .location),
            ("place-agra", .location),
            ("place-raigad", .location),
            (bornAtShivneriEvent.id, .timeline),
            (earlyFortsEvent.id, .timeline),
            (pratapgadTurningPointEvent.id, .timeline),
            (pressureAtPurandarEvent.id, .timeline),
            (agraReturnEvent.id, .timeline),
            (comebackRebuildingEvent.id, .timeline),
            (raigadCoronationEvent.id, .timeline),
        ])

    private static func makeCard(sceneID: String, type: LearningCardType, title: String, text: String, memoryHook: String? = nil) -> LearningCard {
        LearningCard(
            id: "\(sceneID)-\(type.rawValue)",
            type: type,
            title: title,
            text: text,
            narration: text,
            imageKey: sceneID,
            memoryHook: memoryHook,
            difficultyBand: .standard
        )
    }

    private static func makeChronicleEntry(
        id: String,
        title: String,
        keepsakeTitle: String,
        meaning: String,
        sceneID: String,
        placeID: String?,
        timelineEventID: String?,
        requiredMastery: MasteryState,
        enhancedMastery: MasteryState?
    ) -> ChronicleEntry {
        ChronicleEntry(
            id: id,
            title: title,
            keepsakeTitle: keepsakeTitle,
            meaningStatement: meaning,
            linkedSceneID: sceneID,
            linkedPlaceID: placeID,
            linkedTimelineEventID: timelineEventID,
            unlockRule: UnlockRule(requiredMastery: requiredMastery, enhancedMastery: enhancedMastery)
        )
    }

    private static func makeLocationNode(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        memoryHook: String,
        primaryEvent: String,
        regionLabel: String,
        linkedSceneIDs: [String],
        linkedTimelineEventIDs: [String],
        isCoreReleasePlace: Bool
    ) -> LocationNode {
        LocationNode(
            id: id,
            name: name,
            canonicalCoordinate: Coordinate(latitude: latitude, longitude: longitude),
            memoryHook: memoryHook,
            primaryEvent: primaryEvent,
            regionLabel: regionLabel,
            linkedSceneIDs: linkedSceneIDs,
            linkedTimelineEventIDs: linkedTimelineEventIDs,
            unlockRule: UnlockRule(requiredMastery: .understood, enhancedMastery: .placed),
            isCoreReleasePlace: isCoreReleasePlace
        )
    }

    private static func reviewSchedules(for subjects: [(String, MasterySubjectType)]) -> [ReviewSchedule] {
        subjects.map { subjectID, subjectType in
            ReviewSchedule(
                subjectID: subjectID,
                subjectType: subjectType,
                nextDueAt: .distantFuture,
                intervalIndex: 0,
                stabilityBand: .new,
                difficultyAdjustment: 0,
                cadenceDays: [0, 1, 3, 7, 14]
            )
        }
    }
}
