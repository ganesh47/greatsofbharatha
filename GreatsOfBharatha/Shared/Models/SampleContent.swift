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
        narrativeObjective: "Meet young Shivaji Maharaj at Shivneri and see how Jijabai helped shape his courage and care.",
        keyFact: "Shivaji Maharaj was born at Shivneri Fort, and Jijabai shaped his early values.",
        childSafeSummary: "Inside Shivneri Fort, young Shivaji begins his journey. Jijabai helps him grow brave, thoughtful, and ready to protect people.",
        mapAnchors: ["Shivneri Fort", "Junnar", "Hill-fort country north of Pune"],
        timelineMarker: "Born at Shivneri",
        interactionSteps: [
            "Open the story hook.",
            "Notice why Shivneri matters.",
            "Keep the birth-fort anchor in mind.",
            "Answer the recall card to earn the Chronicle keepsake."
        ],
        recallPrompt: RecallPrompt(
            question: "Which fort is Shivaji Maharaj's birth place?",
            answer: "Shivneri Fort",
            supportText: "Shivneri is the Birth Fort where the journey begins."
        ),
        rewardID: "reward-birth-fort-card"
    )

    static let scene2 = StoryScene(
        id: "scene-2-torna-rajgad",
        number: 2,
        title: "Torna and Rajgad, the first steps of Swarajya",
        narrativeObjective: "See how an early fort win at Torna grew into careful planning and a strong base at Rajgad.",
        keyFact: "Torna was an early breakthrough, and Rajgad became an early capital and planning base.",
        childSafeSummary: "The journey climbs from Torna to Rajgad. One fort shows the breakthrough, and the next becomes the place for planning.",
        mapAnchors: ["Torna", "Rajgad", "Mountain routes of western Maharashtra"],
        timelineMarker: "Early forts",
        interactionSteps: [
            "Follow the story from Torna to Rajgad.",
            "Notice which fort comes first and which fort becomes the planning base.",
            "Choose smart fort moves.",
            "Answer the recall card before collecting the reward."
        ],
        recallPrompt: RecallPrompt(
            question: "Which fort became an early capital?",
            answer: "Rajgad",
            supportText: "Rajgad is the early capital. Torna is the breakthrough fort that comes first."
        ),
        rewardID: "reward-first-big-fort-card"
    )

    static let shivneri = Place(
        id: "place-shivneri",
        name: "Shivneri",
        memoryHook: "Birth Fort",
        primaryEvent: "Birth of Shivaji Maharaj",
        whyItMatters: "This is where the journey begins.",
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
        whyItMatters: "It helps the journey grow stronger.",
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
        primaryEvent: "Major turning point in Shivaji Maharaj's rise",
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
        meaning: "You remembered Shivneri Fort as the place where Shivaji Maharaj's journey begins.",
        unlockedBySceneID: "scene-1-shivneri",
        mastery: .understood,
        category: .storyCard
    )

    static let firstBigFortCard = ChronicleReward(
        id: "reward-first-big-fort-card",
        title: "First Big Fort",
        subtitle: "Journey keepsake card",
        meaning: "You remembered how the early fort journey climbs from Torna's breakthrough to Rajgad's planning base.",
        unlockedBySceneID: "scene-2-torna-rajgad",
        mastery: .understood,
        category: .storyCard
    )

    static let mountainSealFragment = ChronicleReward(
        id: "reward-mountain-seal-fragment",
        title: "Mountain Seal Fragment",
        subtitle: "Mountain emblem fragment",
        meaning: "A mountain emblem fragment for learning the first forts and how they sit in the Sahyadris.",
        unlockedBySceneID: "scene-2-torna-rajgad",
        mastery: .understood,
        category: .emblemFragment
    )

    static let planningBadge = ChronicleReward(
        id: "reward-planning-badge",
        title: "Planning Badge",
        subtitle: "Planner's badge",
        meaning: "A keepsake badge for noticing that careful planning helps the Shivaji journey grow strong.",
        unlockedBySceneID: "scene-2-torna-rajgad",
        mastery: .observedClosely,
        category: .leadershipBadge
    )
}
