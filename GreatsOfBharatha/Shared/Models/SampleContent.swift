import Foundation

enum SampleContent {
    static let shivajiVerticalSlice = AppContent(
        arcTitle: "Shivaji Arc",
        scenes: [scene1, scene2],
        places: [shivneri, torna, rajgad, pratapgad, raigad, purandar],
        rewards: [birthFortCard, firstBigFortCard, mountainSealFragment, planningBadge]
    )

    static let scene1 = StoryScene(
        id: "scene-1-shivneri",
        number: 1,
        title: "Shivneri, where Shivaji Maharaj's story begins",
        narrativeObjective: "Meet Shivaji Maharaj as a child, guided by place, courage, and Jijabai.",
        keyFact: "Shivaji Maharaj was born at Shivneri Fort, and Jijabai shaped his early values.",
        childSafeSummary: "At Shivneri Fort, young Shivaji began his journey. Jijabai helped him grow brave, caring, and ready to lead.",
        mapAnchors: ["Shivneri Fort", "Junnar", "Hill-fort country north of Pune"],
        timelineMarker: "Born at Shivneri",
        interactionSteps: [
            "Reveal the opening story moment.",
            "Hear the short story beat.",
            "Mark the first Chronicle moment: Born at Shivneri.",
            "Answer the recall question to unlock the Chronicle card."
        ],
        recallPrompt: RecallPrompt(
            question: "Which fort is Shivaji Maharaj’s birth place?",
            answer: "Shivneri Fort",
            supportText: "The story begins at Shivneri, the Birth Fort."
        ),
        rewardID: "reward-birth-fort-card"
    )

    static let scene2 = StoryScene(
        id: "scene-2-torna-rajgad",
        number: 2,
        title: "Torna and Rajgad, the first steps of Swarajya",
        narrativeObjective: "Show how early fort victories turned into careful planning and state-building.",
        keyFact: "Torna was an early breakthrough, and Rajgad became an early capital and planning base.",
        childSafeSummary: "Shivaji Maharaj began building Swarajya by winning key forts and planning from the mountains.",
        mapAnchors: ["Torna", "Rajgad", "Mountain routes of western Maharashtra"],
        timelineMarker: "Early forts",
        interactionSteps: [
            "Follow the story from Shivneri to Torna and Rajgad.",
            "Notice why Torna mattered first and Rajgad mattered next.",
            "Pick smart fort-planning choices.",
            "Answer a short recall prompt before collecting the reward."
        ],
        recallPrompt: RecallPrompt(
            question: "Which fort became an early capital?",
            answer: "Rajgad",
            supportText: "Torna is the First Big Fort, and Rajgad is the Early Capital."
        ),
        rewardID: "reward-first-big-fort-card"
    )

    static let shivneri = Place(
        id: "place-shivneri",
        name: "Shivneri",
        memoryHook: "Birth Fort",
        primaryEvent: "Birth of Shivaji Maharaj",
        whyItMatters: "This is where the story begins.",
        regionLabel: "Near Junnar, north of Pune",
        latitude: 19.1990,
        longitude: 73.8595,
        progress: .readyToLearn,
        isCoreReleasePlace: true
    )

    static let torna = Place(
        id: "place-torna",
        name: "Torna",
        memoryHook: "First Big Fort",
        primaryEvent: "Early breakthrough in the start of Swarajya",
        whyItMatters: "It marks one of the first major fort successes.",
        regionLabel: "Sahyadri range, southwest of Pune",
        latitude: 18.2761,
        longitude: 73.6227,
        progress: .readyToLearn,
        isCoreReleasePlace: true
    )

    static let rajgad = Place(
        id: "place-rajgad",
        name: "Rajgad",
        memoryHook: "Early Capital",
        primaryEvent: "Early power center and planning base",
        whyItMatters: "It supported growth and consolidation.",
        regionLabel: "Sahyadri range, near Torna",
        latitude: 18.2460,
        longitude: 73.6822,
        progress: .readyToLearn,
        isCoreReleasePlace: true
    )

    static let pratapgad = Place(
        id: "place-pratapgad",
        name: "Pratapgad",
        memoryHook: "Turning Point",
        primaryEvent: "Major turning point in Shivaji Maharaj’s rise",
        whyItMatters: "It teaches strategy and terrain.",
        regionLabel: "Hill country near Mahabaleshwar",
        latitude: 17.9362,
        longitude: 73.5776,
        progress: .locked,
        isCoreReleasePlace: true
    )

    static let raigad = Place(
        id: "place-raigad",
        name: "Raigad",
        memoryHook: "Coronation Capital",
        primaryEvent: "Coronation as Chhatrapati",
        whyItMatters: "It is the sovereign climax of the arc.",
        regionLabel: "Konkan edge of the Sahyadris",
        latitude: 18.2335,
        longitude: 73.4406,
        progress: .locked,
        isCoreReleasePlace: true
    )

    static let purandar = Place(
        id: "place-purandar",
        name: "Purandar",
        memoryHook: "Pressure Fort",
        primaryEvent: "Context for later pressure and compromise",
        whyItMatters: "Useful story support, but not required for first-release pinning.",
        regionLabel: "Southeast of Pune",
        latitude: 18.2808,
        longitude: 73.9736,
        progress: .locked,
        isCoreReleasePlace: false
    )

    static let birthFortCard = ChronicleReward(
        id: "reward-birth-fort-card",
        title: "Birth Fort",
        subtitle: "Journey keepsake card",
        meaning: "The Chronicle keeps the memory of Shivneri Fort, where Shivaji Maharaj’s journey begins.",
        unlockedBySceneID: "scene-1-shivneri",
        mastery: .witnessed,
        category: .storyCard
    )

    static let firstBigFortCard = ChronicleReward(
        id: "reward-first-big-fort-card",
        title: "First Big Fort",
        subtitle: "Journey keepsake card",
        meaning: "This keepsake remembers Torna as an early breakthrough in building Swarajya.",
        unlockedBySceneID: "scene-2-torna-rajgad",
        mastery: .witnessed,
        category: .storyCard
    )

    static let mountainSealFragment = ChronicleReward(
        id: "reward-mountain-seal-fragment",
        title: "Mountain Seal Fragment",
        subtitle: "Mountain emblem fragment",
        meaning: "A mountain emblem fragment earned by learning the first forts and how they sit in the Sahyadris.",
        unlockedBySceneID: "scene-2-torna-rajgad",
        mastery: .understood,
        category: .emblemFragment
    )

    static let planningBadge = ChronicleReward(
        id: "reward-planning-badge",
        title: "Planning Badge",
        subtitle: "Planner’s badge",
        meaning: "A keepsake badge for noticing that careful planning helps the Shivaji journey grow strong.",
        unlockedBySceneID: "scene-2-torna-rajgad",
        mastery: .observedClosely,
        category: .leadershipBadge
    )
}
