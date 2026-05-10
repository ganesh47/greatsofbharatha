import Foundation

// #126 reset pilot content intentionally keeps the static fixture in one namespace.
// swiftlint:disable type_body_length
enum SampleContent {
    static let shivajiVerticalSlice = AppContent(heroArc: shivajiHeroArc)

    static let shivajiLearnQuizResetPilot = HistoricalFigureArc(
        id: "shivaji-learn-quiz-reset-pilot",
        figureName: "Shivaji Maharaj",
        title: "Shivaji Learn-and-Quiz Chronicle Pilot",
        resetAnchorIssue: "#126",
        scenes: [
            ChronicleScene(
                id: "reset-scene-1-shivneri",
                title: "Shivneri - Birth Fort",
                timeMarker: "Beginning of the journey",
                placeAnchors: [
                    PlaceAnchor(id: "place-shivneri", name: "Shivneri", regionLabel: "Junnar region", memoryHook: "Birth Fort"),
                ],
                actionVerb: "begins",
                memoryHook: "Birth Fort",
                childSafeStory: "Shivaji Maharaj's story begins at Shivneri Fort. Jijabai's guidance helped him grow with courage, care, and responsibility.",
                meaning: "Shivneri matters because it anchors the beginning of the journey and the values Shivaji Maharaj carried forward.",
                quizItems: [
                    QuizItem(
                        id: "quiz-shivneri-birth-fort",
                        prompt: "Where does Shivaji Maharaj's story begin?",
                        acceptedAnswers: ["Shivneri", "Shivneri Fort"],
                        answerChips: ["Shivneri", "Rajgad", "Pratapgad"],
                        hintLadder: [
                            RecallHint(level: 1, title: "Memory hook", body: "Think of the Birth Fort."),
                            RecallHint(level: 2, title: "Place clue", body: "It is the fort near Junnar where the story begins."),
                            RecallHint(level: 3, title: "Recognition rescue", body: "Choose Shivneri."),
                        ],
                        successFeedback: "Yes. Shivneri is the Birth Fort where Shivaji Maharaj's story begins.",
                        recoveryFeedback: "Remember the hook: Birth Fort means Shivneri."
                    ),
                ],
                matchPairs: [
                    MatchPair(id: "match-shivneri-birth-fort", left: "Shivneri", right: "Birth Fort", kind: .placeToHook, teachingFeedback: "Shivneri is the Birth Fort."),
                    MatchPair(id: "match-shivneri-begins", left: "Shivneri", right: "Story begins", kind: .placeToAction, teachingFeedback: "The journey begins at Shivneri."),
                ],
                chronicleReward: ChronicleReward(
                    id: "reset-reward-birth-fort-card",
                    title: "Birth Fort Chronicle Card",
                    subtitle: "First inked keepsake",
                    meaning: "A Chronicle card for remembering Shivneri as the place where the journey begins.",
                    unlockedBySceneID: "reset-scene-1-shivneri",
                    mastery: .understood,
                    category: .storyCard
                ),
                reviewSeeds: [
                    ReviewSeed(
                        id: "review-shivneri-birth-fort",
                        promptType: .openPrompt,
                        front: "Birth Fort",
                        back: "Shivneri",
                        meaning: "Shivneri is where Shivaji Maharaj's story begins.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-shivneri-place-to-hook",
                        promptType: .openPrompt,
                        front: "Shivneri",
                        back: "Birth Fort",
                        meaning: "Shivneri is remembered as the Birth Fort where the journey begins.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-shivneri-jijabai",
                        promptType: .openPrompt,
                        front: "Who taught Shivaji Maharaj courage and duty?",
                        back: "Jijabai — at Shivneri",
                        meaning: "Jijabai's guidance at Shivneri shaped the values Shivaji Maharaj carried forward.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-shivneri-event-to-place",
                        promptType: .eventToPlaceMatch,
                        front: "Where the journey begins / Jijabai's guidance",
                        back: "Shivneri",
                        meaning: "Shivneri is the place where the story and the values begin.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-shivneri-meaning",
                        promptType: .openPrompt,
                        front: "What does Shivneri teach?",
                        back: "Great journeys begin in real places with real guidance.",
                        meaning: "Shivneri anchors the idea that values and place are connected from the very start.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                ]
            ),
            ChronicleScene(
                id: "reset-scene-2-torna-rajgad",
                title: "Torna and Rajgad - Early Forts",
                timeMarker: "Early self-rule steps",
                placeAnchors: [
                    PlaceAnchor(id: "place-torna", name: "Torna", regionLabel: "Sahyadri range southwest of Pune", memoryHook: "First Big Fort"),
                    PlaceAnchor(id: "place-rajgad", name: "Rajgad", regionLabel: "Sahyadri range near Torna", memoryHook: "Early Capital"),
                ],
                actionVerb: "builds",
                memoryHook: "First Big Fort / Early Capital",
                childSafeStory: "Shivaji Maharaj began building self-rule with important forts. Torna was an early win, and Rajgad became a place to plan next steps.",
                meaning: "These forts matter because the story is not only about winning a fort; it is about building a stronger base.",
                quizItems: [
                    QuizItem(
                        id: "quiz-rajgad-early-capital",
                        prompt: "Which fort became an early capital?",
                        acceptedAnswers: ["Rajgad"],
                        answerChips: ["Torna", "Rajgad", "Shivneri"],
                        hintLadder: [
                            RecallHint(level: 1, title: "Memory hook", body: "Think of Early Capital."),
                            RecallHint(level: 2, title: "Pair clue", body: "Torna is the First Big Fort; the other fort became the planning base."),
                            RecallHint(level: 3, title: "Recognition rescue", body: "Choose Rajgad."),
                        ],
                        successFeedback: "Yes. Rajgad became an early capital and planning base.",
                        recoveryFeedback: "Remember the pair: Torna is First Big Fort, Rajgad is Early Capital."
                    ),
                ],
                matchPairs: [
                    MatchPair(id: "match-torna-first-big-fort", left: "Torna", right: "First Big Fort", kind: .placeToHook, teachingFeedback: "Torna marks an early breakthrough."),
                    MatchPair(id: "match-rajgad-early-capital", left: "Rajgad", right: "Early Capital", kind: .placeToHook, teachingFeedback: "Rajgad became an early capital."),
                    MatchPair(id: "match-rajgad-planning-base", left: "Rajgad", right: "Planning base", kind: .placeToAction, teachingFeedback: "Rajgad helps children remember careful planning and building a strong home base."),
                ],
                chronicleReward: ChronicleReward(
                    id: "reset-reward-first-fort-early-capital-card",
                    title: "First Fort / Early Capital Card",
                    subtitle: "Fort-building keepsake",
                    meaning: "A Chronicle card for remembering Torna as First Big Fort and Rajgad as Early Capital.",
                    unlockedBySceneID: "reset-scene-2-torna-rajgad",
                    mastery: .understood,
                    category: .storyCard
                ),
                reviewSeeds: [
                    ReviewSeed(
                        id: "review-torna-rajgad-pair",
                        promptType: .eventToPlaceMatch,
                        front: "First Big Fort / Early Capital",
                        back: "Torna / Rajgad",
                        meaning: "Torna and Rajgad teach early fort-building and planning.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-torna-hook",
                        promptType: .openPrompt,
                        front: "Torna",
                        back: "First Big Fort",
                        meaning: "Torna is remembered as the First Big Fort, an early win in building self-rule.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-rajgad-hook",
                        promptType: .openPrompt,
                        front: "Rajgad",
                        back: "Early Capital",
                        meaning: "Rajgad became the early capital and planning base.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-rajgad-planning-base",
                        promptType: .compareFromMemory,
                        front: "Which fort became the planning base?",
                        back: "Rajgad",
                        meaning: "Rajgad is where Shivaji Maharaj planned from the mountains.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-torna-rajgad-meaning",
                        promptType: .openPrompt,
                        front: "What does building Torna and Rajgad teach?",
                        back: "Not just winning space — building a stronger base.",
                        meaning: "The early forts teach that careful planning matters as much as the first win.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                ]
            ),
            ChronicleScene(
                id: "reset-scene-3-pratapgad",
                title: "Pratapgad - Turning Point",
                timeMarker: "Major rise and turning point",
                placeAnchors: [
                    PlaceAnchor(id: "place-pratapgad", name: "Pratapgad", regionLabel: "Hill country near Mahabaleshwar", memoryHook: "Turning Point"),
                ],
                actionVerb: "plans",
                memoryHook: "Turning Point",
                childSafeStory: "At Pratapgad, careful planning, courage, and hill terrain mattered in a dangerous moment. The story stays focused on preparation and judgment.",
                meaning: "Pratapgad matters because terrain and planning changed the balance at a key moment.",
                quizItems: [
                    QuizItem(
                        id: "quiz-pratapgad-turning-point",
                        prompt: "Which fort is remembered as the turning point?",
                        acceptedAnswers: ["Pratapgad"],
                        answerChips: ["Pratapgad", "Shivneri", "Rajgad"],
                        hintLadder: [
                            RecallHint(level: 1, title: "Memory hook", body: "Think of Turning Point."),
                            RecallHint(level: 2, title: "Place clue", body: "It stands in hill country near Mahabaleshwar."),
                            RecallHint(level: 3, title: "Recognition rescue", body: "Choose Pratapgad."),
                        ],
                        successFeedback: "Yes. Pratapgad is remembered as the turning point.",
                        recoveryFeedback: "Remember the hook: Turning Point means Pratapgad."
                    ),
                ],
                matchPairs: [
                    MatchPair(id: "match-pratapgad-turning-point", left: "Pratapgad", right: "Turning Point", kind: .placeToHook, teachingFeedback: "Pratapgad is the turning point fort."),
                    MatchPair(id: "match-planning-terrain", left: "Planning and terrain", right: "Changed the balance", kind: .actionToMeaning, teachingFeedback: "The meaning is preparation, courage, and wise use of terrain."),
                ],
                chronicleReward: ChronicleReward(
                    id: "reset-reward-turning-point-seal",
                    title: "Turning Point Seal",
                    subtitle: "Deepened Chronicle mark",
                    meaning: "A Chronicle seal for remembering Pratapgad as the turning point where planning and terrain mattered.",
                    unlockedBySceneID: "reset-scene-3-pratapgad",
                    mastery: .understood,
                    category: .emblemFragment
                ),
                reviewSeeds: [
                    ReviewSeed(
                        id: "review-pratapgad-turning-point",
                        promptType: .compareFromMemory,
                        front: "Turning Point",
                        back: "Pratapgad",
                        meaning: "Pratapgad teaches planning, terrain, and courage.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-pratapgad-place-to-hook",
                        promptType: .openPrompt,
                        front: "Pratapgad",
                        back: "Turning Point",
                        meaning: "Pratapgad is remembered as the fort where the balance shifted.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-pratapgad-what-changed",
                        promptType: .openPrompt,
                        front: "What changed at Pratapgad?",
                        back: "Planning and terrain changed the balance.",
                        meaning: "Knowing the land is a form of preparation — Pratapgad shows this clearly.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-pratapgad-sequence",
                        promptType: .sequenceSlot,
                        front: "Where does Pratapgad come in the journey?",
                        back: "After Torna and Rajgad.",
                        meaning: "Pratapgad comes third — after the birth fort and the early building forts.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-pratapgad-meaning",
                        promptType: .openPrompt,
                        front: "What does Pratapgad teach?",
                        back: "Knowing the land is a form of preparation.",
                        meaning: "Terrain and careful planning matter as much as courage in a difficult moment.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                ]
            ),
            ChronicleScene(
                id: "reset-scene-4-purandar-agra",
                title: "Purandar and Agra - Pressure and Return",
                timeMarker: "Pressure, setback, and patient return",
                placeAnchors: [
                    PlaceAnchor(id: "place-purandar", name: "Purandar", regionLabel: "Southeast of Pune", memoryHook: "Pressure Fort"),
                    PlaceAnchor(id: "place-agra", name: "Agra", regionLabel: "Northern India on the Yamuna", memoryHook: "Northern Court"),
                ],
                actionVerb: "endures",
                memoryHook: "Pressure Fort / Northern Court",
                childSafeStory: "Sometimes leaders face hard pressure. Shivaji Maharaj made a difficult agreement at Purandar, then found a clever way to return home from Agra.",
                meaning: "This scene matters because leaders sometimes face pressure, make hard choices, and still find a way back with patience and planning.",
                quizItems: [
                    QuizItem(
                        id: "quiz-purandar-agra-sequence",
                        prompt: "Which happened first — Purandar or Agra?",
                        acceptedAnswers: ["Purandar"],
                        answerChips: ["Purandar", "Agra", "Rajgad"],
                        hintLadder: [
                            RecallHint(level: 1, title: "Memory hook", body: "Pressure comes before the northern city."),
                            RecallHint(level: 2, title: "Place clue", body: "Purandar is near Pune; Agra is in the north."),
                            RecallHint(level: 3, title: "Recognition rescue", body: "Choose Purandar."),
                        ],
                        successFeedback: "Yes. The difficult agreement at Purandar came before the period at Agra.",
                        recoveryFeedback: "Remember: Purandar brings pressure first, then Agra and the return."
                    ),
                ],
                matchPairs: [
                    MatchPair(id: "match-purandar-pressure", left: "Purandar", right: "Pressure Fort", kind: .placeToHook, teachingFeedback: "Purandar is the Pressure Fort — where a hard agreement was made."),
                    MatchPair(id: "match-agra-northern-court", left: "Agra", right: "Northern Court", kind: .placeToHook, teachingFeedback: "Agra is the Northern Court where Shivaji Maharaj was held under close watch."),
                    MatchPair(id: "match-patience-return", left: "Patience and planning", right: "Made the return possible", kind: .actionToMeaning, teachingFeedback: "Setbacks don't end the story when patience stays alive."),
                ],
                chronicleReward: ChronicleReward(
                    id: "reset-reward-pressure-and-return-card",
                    title: "Pressure and Return Card",
                    subtitle: "Patient resolve keepsake",
                    meaning: "A Chronicle card for remembering that setbacks are part of the journey and patience opens the way home.",
                    unlockedBySceneID: "reset-scene-4-purandar-agra",
                    mastery: .understood,
                    category: .storyCard
                ),
                reviewSeeds: [
                    ReviewSeed(
                        id: "review-purandar-hook",
                        promptType: .openPrompt,
                        front: "Pressure Fort",
                        back: "Purandar",
                        meaning: "Purandar is where a hard agreement was made under pressure.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-agra-hook",
                        promptType: .openPrompt,
                        front: "Northern Court",
                        back: "Agra",
                        meaning: "Agra is the northern city where Shivaji Maharaj was held under close watch before returning home.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-purandar-agra-sequence",
                        promptType: .sequenceSlot,
                        front: "Which came first — Purandar or Agra?",
                        back: "Purandar, then Agra.",
                        meaning: "The hard agreement at Purandar came before the period of watch in Agra.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-purandar-agra-pair",
                        promptType: .eventToPlaceMatch,
                        front: "Hard agreement / Under watch in the north",
                        back: "Purandar / Agra",
                        meaning: "Purandar and Agra form the setback-and-return arc in the journey.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-agra-meaning",
                        promptType: .openPrompt,
                        front: "What does the Agra episode teach?",
                        back: "Setbacks don't end the story when patience stays alive.",
                        meaning: "Even under pressure and watch, patience and planning kept the journey going.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                ]
            ),
            ChronicleScene(
                id: "reset-scene-5-rajgad-recovery",
                title: "Recovery - Rebuilding After Agra",
                timeMarker: "Comeback and rebuilding",
                placeAnchors: [
                    PlaceAnchor(id: "place-rajgad", name: "Rajgad", regionLabel: "Sahyadri range near Torna", memoryHook: "Comeback"),
                ],
                actionVerb: "rebuilds",
                memoryHook: "Comeback",
                childSafeStory: "After a difficult time in Agra, Shivaji Maharaj did not give up. He returned to Rajgad, rebuilt his strength, reorganized, and grew stronger again.",
                meaning: "Recovery matters because strength can be rebuilt through steady organization, not only dramatic moments.",
                quizItems: [
                    QuizItem(
                        id: "quiz-rajgad-comeback",
                        prompt: "What did Shivaji Maharaj do after returning from Agra?",
                        acceptedAnswers: ["He rebuilt strength", "He rebuilt and reorganized", "Rebuilt and grew stronger"],
                        answerChips: ["Rebuilt and grew stronger", "Gave up the fight", "Left Maharashtra"],
                        hintLadder: [
                            RecallHint(level: 1, title: "Memory hook", body: "Think of the Comeback scene at Rajgad."),
                            RecallHint(level: 2, title: "Action clue", body: "He did not give up — he rebuilt and reorganized."),
                            RecallHint(level: 3, title: "Recognition rescue", body: "Choose Rebuilt and grew stronger."),
                        ],
                        successFeedback: "Yes. After Agra, Shivaji Maharaj rebuilt strength, reorganized, and grew stronger again.",
                        recoveryFeedback: "The comeback scene is about rebuilding and returning to growth."
                    ),
                ],
                matchPairs: [
                    MatchPair(id: "match-rajgad-comeback", left: "Rajgad", right: "Comeback", kind: .placeToHook, teachingFeedback: "Rajgad is the comeback anchor — where strength was rebuilt."),
                    MatchPair(id: "match-rebuilding-resilience", left: "Rebuilding and reorganizing", right: "Resilience in leadership", kind: .actionToMeaning, teachingFeedback: "Recovery shows that resilience is part of leadership."),
                ],
                chronicleReward: ChronicleReward(
                    id: "reset-reward-comeback-card",
                    title: "Comeback Chronicle Card",
                    subtitle: "Resilience keepsake",
                    meaning: "A Chronicle card for remembering that Shivaji Maharaj rebuilt strength and grew stronger after a difficult time.",
                    unlockedBySceneID: "reset-scene-5-rajgad-recovery",
                    mastery: .understood,
                    category: .storyCard
                ),
                reviewSeeds: [
                    ReviewSeed(
                        id: "review-rajgad-comeback-hook",
                        promptType: .openPrompt,
                        front: "Comeback",
                        back: "Rajgad — the recovery anchor.",
                        meaning: "Rajgad is where Shivaji Maharaj rebuilt after the difficult time in Agra.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-rajgad-what-happened",
                        promptType: .openPrompt,
                        front: "What did Shivaji Maharaj do after returning from Agra?",
                        back: "Rebuilt strength, reorganized, and grew stronger.",
                        meaning: "The comeback shows that the journey continued even after a setback.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-rajgad-comeback-compare",
                        promptType: .compareFromMemory,
                        front: "Which fort is the comeback anchor?",
                        back: "Rajgad",
                        meaning: "Rajgad appears twice in the journey: first as Early Capital, then as the Comeback anchor.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-rajgad-comeback-meaning",
                        promptType: .openPrompt,
                        front: "What does the comeback teach?",
                        back: "Resilience is part of leadership, especially after a setback.",
                        meaning: "Steady rebuilding and reorganizing are how leaders recover and return to growth.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                ]
            ),
            ChronicleScene(
                id: "reset-scene-6-raigad-coronation",
                title: "Raigad - Coronation as Chhatrapati",
                timeMarker: "Crowning moment of the journey",
                placeAnchors: [
                    PlaceAnchor(id: "place-raigad", name: "Raigad", regionLabel: "Konkan edge of the Sahyadris", memoryHook: "Coronation Capital"),
                ],
                actionVerb: "crowns",
                memoryHook: "Coronation Capital",
                childSafeStory: "At Raigad in 1674, Shivaji Maharaj was crowned Chhatrapati. This marked Swarajya — self-rule for the people.",
                meaning: "Raigad matters because the coronation showed self-rule and responsibility.",
                quizItems: [
                    QuizItem(
                        id: "quiz-raigad-coronation",
                        prompt: "At which fort was Shivaji Maharaj crowned Chhatrapati?",
                        acceptedAnswers: ["Raigad"],
                        answerChips: ["Raigad", "Rajgad", "Pratapgad"],
                        hintLadder: [
                            RecallHint(level: 1, title: "Memory hook", body: "Think of the Coronation Capital."),
                            RecallHint(level: 2, title: "Place clue", body: "It stands on the Konkan edge of the Sahyadris."),
                            RecallHint(level: 3, title: "Recognition rescue", body: "Choose Raigad."),
                        ],
                        successFeedback: "Yes. Raigad is the Coronation Capital where the journey reaches self-rule.",
                        recoveryFeedback: "Remember: Raigad is the Coronation Capital — the final fort in the arc."
                    ),
                ],
                matchPairs: [
                    MatchPair(id: "match-raigad-coronation-capital", left: "Raigad", right: "Coronation Capital", kind: .placeToHook, teachingFeedback: "Raigad is where Shivaji Maharaj was crowned Chhatrapati."),
                    MatchPair(id: "match-swarajya-raigad", left: "Swarajya", right: "Raigad, 1674", kind: .eventToTime, teachingFeedback: "Swarajya means self-rule. Raigad helps us remember that moment in 1674."),
                    MatchPair(id: "match-raigad-meaning", left: "Self-rule and responsibility", right: "Meaning of the coronation", kind: .actionToMeaning, teachingFeedback: "The coronation shows self-rule, dignity, and responsibility."),
                ],
                chronicleReward: ChronicleReward(
                    id: "reset-reward-chhatrapati-crown-card",
                    title: "Chhatrapati Crown Card",
                    subtitle: "Sovereign journey keepsake",
                    meaning: "The final Chronicle card remembers the coronation at Raigad and the rise of self-rule.",
                    unlockedBySceneID: "reset-scene-6-raigad-coronation",
                    mastery: .remembered,
                    category: .leadershipBadge
                ),
                reviewSeeds: [
                    ReviewSeed(
                        id: "review-raigad-hook-to-place",
                        promptType: .openPrompt,
                        front: "Coronation Capital",
                        back: "Raigad",
                        meaning: "Raigad is remembered as the Coronation Capital where self-rule was celebrated.",
                        correctNoHintCadenceDays: 1,
                        correctWithHintCadenceDays: 0,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-raigad-place-to-hook",
                        promptType: .openPrompt,
                        front: "Raigad",
                        back: "Coronation Capital",
                        meaning: "Raigad is the final fort in the arc — the Coronation Capital.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-raigad-what-happened",
                        promptType: .openPrompt,
                        front: "What happened at Raigad in 1674?",
                        back: "Shivaji Maharaj was crowned Chhatrapati.",
                        meaning: "The coronation at Raigad is the crowning moment of the whole journey.",
                        correctNoHintCadenceDays: 2,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-swarajya-meaning",
                        promptType: .openPrompt,
                        front: "What does Swarajya mean?",
                        back: "Self-rule — people governing themselves with dignity.",
                        meaning: "Swarajya means self-rule. It is the big idea Shivaji Maharaj worked toward through the whole journey.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                    ReviewSeed(
                        id: "review-raigad-sequence",
                        promptType: .sequenceSlot,
                        front: "Where does Raigad come in the journey?",
                        back: "Last — the crowning moment after the comeback.",
                        meaning: "Raigad is the sixth and final place, where the journey reaches its fullest meaning.",
                        correctNoHintCadenceDays: 3,
                        correctWithHintCadenceDays: 1,
                        rescuedCadenceDays: 0
                    ),
                ]
            ),
        ],
        timelineBuilder: TimelineBuilderSeed(
            id: "timeline-shivaji-reset-pilot",
            prompt: "Put all six Shivaji scenes in order.",
            orderedSceneIDs: [
                "reset-scene-1-shivneri",
                "reset-scene-2-torna-rajgad",
                "reset-scene-3-pratapgad",
                "reset-scene-4-purandar-agra",
                "reset-scene-5-rajgad-recovery",
                "reset-scene-6-raigad-coronation",
            ],
            completionRewardText: "The Chronicle gains a complete Journey So Far timeline strip."
        ),
        endOfPilotReward: ChronicleReward(
            id: "reset-reward-shivaji-journey-so-far",
            title: "Shivaji Journey So Far",
            subtitle: "Full arc completion page",
            meaning: "A page for remembering the order: Shivneri, Torna/Rajgad, Pratapgad, Purandar/Agra, Recovery, Raigad.",
            unlockedBySceneID: "reset-scene-6-raigad-coronation",
            mastery: .remembered,
            category: .leadershipBadge
        )
    )

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
        culturalFramingNotes: "Story-first, child-safe framing centered on place, planning, resilience, and Swarajya (self-rule).",
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
        title: "Torna and Rajgad, first steps toward self-rule",
        narrativeObjective: "Show how early fort victories turned into careful planning and a stronger home base.",
        keyFact: "Torna was an early breakthrough, and Rajgad became an early capital and planning base.",
        meaningStatement: "The early forts matter because Shivaji Maharaj did not just win places; he built a stronger base for self-rule.",
        childSafeSummary: "Shivaji Maharaj began building self-rule by winning key forts and planning from the mountains.",
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
        narrativeObjective: "Show the crowning moment and explain why Shivaji Maharaj mattered.",
        keyFact: "At Raigad in 1674, Shivaji Maharaj was crowned Chhatrapati, marking a major moment of self-rule.",
        meaningStatement: "Raigad matters because the coronation shows self-rule and responsibility.",
        childSafeSummary: "At Raigad, Shivaji Maharaj was crowned Chhatrapati. This marked Swarajya, or self-rule.",
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
                    RecallHint(level: 3, title: "Meaning hint", body: "This fort marks Swarajya, or self-rule."),
                ],
                feedback: RecallFeedback(
                    success: "Yes. Raigad is the fort of the coronation as Chhatrapati.",
                    recovery: "Raigad is remembered as the Coronation Capital where the journey reaches self-rule."
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
        meaning: "This keepsake remembers Torna as an early win in building self-rule.",
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
        meaning: "A mountain emblem fragment earned by linking Torna and Rajgad to the growing idea of self-rule.",
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
        title: "Self-Rule Meaning",
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
        primaryEvent: "Early win in the start of self-rule",
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
        recallPrompt: "Place the Raigad coronation as the crowning moment of the journey.",
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
// swiftlint:enable type_body_length
