import Foundation

struct TVStoryBeat: Identifiable {
    let id: String
    let title: String
    let text: String
}

struct TVDiscovery: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let text: String
}

struct TVPlaceClue: Identifiable {
    /// The canonical location ID; Rajgad has a different authored clue in each chapter.
    let id: String
    let clue: String
    let answer: String
    let hint: String
}

enum TVChapterPuzzle {
    case match([ChronicleMatchPair])
    case order([TVSequenceCard])
}

struct TVChapter: Identifiable {
    let id: String
    let number: Int
    let title: String
    let scene: StoryScene
    let plan: SceneLearningPlan
    let pilot: LearnQuizPilotScene
    let storyBeats: [TVStoryBeat]
    let discoveries: [TVDiscovery]
    let placeClues: [TVPlaceClue]
    let puzzle: TVChapterPuzzle
    let familyPrompt: String
    let timelineEventIDs: [String]
}

/// A TV presentation adapter. Canonical content, quiz evaluation, and learning evidence
/// remain shared with iOS; these brief instructions are authored for remote play.
enum TVLearningContent {
    static let timelineEvents: [TVSequenceCard] = {
        let sceneIDs = ["scene-1-shivneri", "scene-2-torna-rajgad", "scene-3-pratapgad-turning-point",
                        "scene-4-purandar-agra", "scene-4-purandar-agra", "scene-5-rajgad-recovery", "scene-6-raigad-coronation"]
        let teaching = ["The journey begins at Shivneri, the Birth Fort.",
                        "Next came early fort-building: Torna and the planning base at Rajgad.",
                        "After the early forts, Pratapgad became a turning point in 1659.",
                        "Pressure led to a difficult agreement at Purandar in 1665.",
                        "After Purandar came Agra in 1666, and then the return home.",
                        "After returning from Agra, Shivaji Maharaj rebuilt strength at Rajgad.",
                        "After the comeback, the coronation took place at Raigad in 1674."]
        let symbols = ["sunrise.fill", "mountain.2.fill", "binoculars.fill", "shield.fill", "arrow.uturn.backward.circle.fill", "leaf.fill", "crown.fill"]
        return SampleContent.shivajiVerticalSlice.activeHeroArc.timelineEvents.sorted { $0.orderIndex < $1.orderIndex }
            .enumerated().map { index, event in
                TVSequenceCard(id: event.id, title: event.title, teachingText: teaching[index], symbol: symbols[index], sceneID: sceneIDs[index])
            }
    }()

    static var openingTimelineRounds: [[TVSequenceCard]] { [Array(timelineEvents.prefix(3))] }
    static var fullTimelineRounds: [[TVSequenceCard]] {
        // Overlap deliberately links the small puzzles into the full seven-event story.
        [Array(timelineEvents[0...2]), Array(timelineEvents[2...4]), Array(timelineEvents[4...6])]
    }

    static let chapters: [TVChapter] = LearnQuizPilotData.scenes.compactMap { pilot in
        guard let scene = SampleContent.shivajiVerticalSlice.scenes.first(where: { $0.id == pilot.id }) else { return nil }
        let plan = SampleContent.learningPlan(for: scene)
        let extra = authoredDetails(number: pilot.number)
        let beats = [
            TVStoryBeat(id: scene.id + "-story", title: "The story", text: pilot.story),
            TVStoryBeat(id: scene.id + "-memory", title: "Remember this", text: plan.teachingText + " " + extra.teaching),
            TVStoryBeat(id: scene.id + "-meaning", title: "Why it matters", text: pilot.meaning),
        ]
        let discoveries = extra.discoveries.enumerated().map { index, discovery in
            TVDiscovery(id: scene.id + "-discovery-\(index + 1)", title: discovery.0, symbol: discovery.1, text: discovery.2)
        }
        let puzzle: TVChapterPuzzle
        if pilot.number == 4 {
            puzzle = .order(Array(timelineEvents[2...4]))
        } else if pilot.number == 6 {
            puzzle = .order(Array(timelineEvents[4...6]))
        } else {
            puzzle = .match(extra.pairs)
        }
        return TVChapter(id: scene.id, number: pilot.number, title: pilot.title, scene: scene,
                         plan: plan, pilot: pilot, storyBeats: beats, discoveries: discoveries,
                         placeClues: extra.places, puzzle: puzzle, familyPrompt: extra.familyPrompt,
                         timelineEventIDs: timelineEvents.filter { $0.sceneID == scene.id }.map(\.id))
    }

    static func chapter(sceneID: String) -> TVChapter? { chapters.first { $0.id == sceneID } }

    static func hasCheckedLearning(_ chapter: TVChapter, store: ShivajiLessonStore) -> Bool {
        store.masteryRecord(for: chapter.id)?.evidenceLog.contains {
            ($0.type == .recallSuccess || $0.type == .reviewSuccess) && $0.support != .selfReported
        } == true
    }

    static func timelineRounds(store: ShivajiLessonStore) -> [[TVSequenceCard]] {
        if chapters.allSatisfy({ hasCheckedLearning($0, store: store) }) { return fullTimelineRounds }
        if chapters.prefix(3).allSatisfy({ hasCheckedLearning($0, store: store) }) { return openingTimelineRounds }
        return []
    }

    private struct Details {
        let teaching: String
        let discoveries: [(String, String, String)]
        let places: [TVPlaceClue]
        let pairs: [ChronicleMatchPair]
        let familyPrompt: String
    }

    private static func pair(_ id: String, _ left: String, _ right: String, _ clue: String) -> ChronicleMatchPair {
        ChronicleMatchPair(id: id, leftID: id + "-left", leftText: left, rightID: id + "-right",
                           rightText: right, kind: .meaningToScene, teachingClue: clue)
    }

    private static func authoredDetails(number: Int) -> Details {
        switch number {
        case 1:
            return Details(teaching: "Shivneri is the Birth Fort near Junnar. Jijabai's guidance taught courage, care, and responsibility.",
                discoveries: [("Look at the hills", "mountain.2.fill", "Shivneri is a hill fort near Junnar. The hills help us remember a real place where the journey began."),
                              ("Meet Jijabai", "person.2.fill", "Jijabai guided young Shivaji with courage, care, and responsibility."),
                              ("Keep a memory", "sunrise.fill", "Birth Fort is a short memory hook for Shivneri.")],
                places: [TVPlaceClue(id: "place-shivneri", clue: "Find the Birth Fort near Junnar.", answer: "Shivneri", hint: "The journey begins at Shivneri.")],
                pairs: [pair("match-shivneri-birth-fort", "Shivneri", "Birth Fort", "Shivneri is the Birth Fort."),
                        pair("tv-match-jijabai-guidance", "Jijabai", "Guidance and care", "Jijabai's guidance helped Shivaji grow with courage, care, and responsibility.")],
                familyPrompt: "Tell someone: where did the journey begin, and who helped Shivaji grow?")
        case 2:
            return Details(teaching: "Torna is remembered as the First Big Fort. Rajgad is remembered as the Early Capital and planning base. First came Shivneri, then the early forts.",
                discoveries: [("First Big Fort", "flag.fill", "Torna marks an early win in building Swarajya, or self-rule."),
                              ("Planning home", "house.fill", "Rajgad became the early capital, a home base for careful planning."),
                              ("Two different jobs", "arrow.left.arrow.right", "Torna means First Big Fort. Rajgad means Early Capital. A first win and a strong home base both matter.")],
                places: [TVPlaceClue(id: "place-torna", clue: "Find the fort with the hook First Big Fort.", answer: "Torna", hint: "Torna was an early win."),
                         TVPlaceClue(id: "place-rajgad", clue: "Find the Early Capital and planning home base.", answer: "Rajgad", hint: "Rajgad became the early capital; Torna is the First Big Fort.")],
                pairs: LearnQuizPilotData.scenes[1].matchPairs,
                familyPrompt: "Give Torna and Rajgad different jobs in your retelling: first big fort and planning home.")
        case 3:
            return Details(teaching: "Pratapgad is the Turning Point. Hill terrain means the shape of the land; careful planning means being prepared. First came Shivneri, then the early forts, and then Pratapgad in 1659.",
                discoveries: [("Read the land", "mountain.2.fill", "Terrain means the shape of the land. The hills mattered at Pratapgad."),
                              ("Make a plan", "binoculars.fill", "Careful planning means being prepared and making wise choices."),
                              ("A turning point", "arrow.turn.up.right", "Pratapgad changed what happened next, after the early forts.")],
                places: [TVPlaceClue(id: "place-pratapgad", clue: "Find the Turning Point fort, where hills and planning mattered.", answer: "Pratapgad", hint: "Pratapgad is our Turning Point memory hook.")],
                pairs: [pair("match-pratapgad-turning-point", "Pratapgad", "Turning Point", "Pratapgad is the Turning Point fort."),
                        pair("tv-match-terrain-shape", "Hill terrain", "Shape of the land", "Terrain means the shape of the land."),
                        pair("tv-match-preparation-plan", "Careful planning", "Being prepared", "A plan helps us prepare and make wise choices.")],
                familyPrompt: "Explain what terrain means. How could knowing the land help someone prepare?")
        case 4:
            return Details(teaching: "After Pratapgad in 1659 came pressure and a difficult agreement at Purandar in 1665. Later came Agra, a northern city, in 1666 and the return home. Purandar comes before Agra.",
                discoveries: [("A hard choice", "shield.fill", "At Purandar, Shivaji Maharaj made a difficult agreement under pressure."),
                              ("A northern city", "building.columns.fill", "Agra is a city in northern India. After Purandar came Agra and the return home."),
                              ("Patience helps", "arrow.uturn.backward.circle.fill", "Patience and planning helped Shivaji Maharaj keep going through a setback and return home.")],
                places: [TVPlaceClue(id: "place-purandar", clue: "Find the Pressure Fort, where a difficult agreement came first.", answer: "Purandar", hint: "Purandar came before Agra."),
                         TVPlaceClue(id: "place-agra", clue: "Find the northern city from which Shivaji Maharaj returned home.", answer: "Agra", hint: "Agra is the northern city, after Purandar.")],
                pairs: [], familyPrompt: "Retell the order with three words: Pratapgad, Purandar, Agra. What helped through the setback?")
        case 5:
            return Details(teaching: "Rajgad now has a second memory hook: Comeback. Rebuilding strength and reorganizing mean steady recovery after a setback. This happened after the return from Agra.",
                discoveries: [("Rajgad returns", "house.fill", "Rajgad first appeared as Early Capital. In this chapter, it is the Comeback place."),
                              ("Build again", "leaf.fill", "After returning from Agra, Shivaji Maharaj rebuilt strength and grew stronger."),
                              ("Steady organization", "square.grid.2x2.fill", "Reorganizing and planning again helped the recovery. Steady work can matter as much as a dramatic moment.")],
                places: [TVPlaceClue(id: "place-rajgad", clue: "Find the Comeback place, where strength was rebuilt after Agra.", answer: "Rajgad", hint: "Rajgad appears twice: Early Capital before, Comeback now.")],
                pairs: [pair("match-rajgad-comeback", "Rajgad after Agra", "Comeback place", "Rajgad is the Comeback place in this chapter."),
                        pair("tv-match-rebuilding-strength", "Rebuild and reorganize", "Steady recovery", "Rebuilding and reorganizing helped strength grow again.")],
                familyPrompt: "Tell a comeback story: how did planning and steady work help after Agra?")
        default:
            return Details(
                teaching: "First came the return from Agra, then rebuilding at Rajgad, and then the coronation at Raigad in 1674. "
                    + "Coronation means a crowning ceremony. Swarajya means self-rule, with responsibility and care for people.",
                discoveries: [("A crowning ceremony", "crown.fill", "In 1674 at Raigad, Shivaji Maharaj was crowned Chhatrapati. Coronation means a crowning ceremony."),
                              ("What is Swarajya?", "sun.max.fill", "Swarajya means self-rule: people guiding and caring for their own land with dignity."),
                              ("Remember the whole path", "book.fill", "The coronation came after the return from Agra and the comeback at Rajgad.")],
                places: [TVPlaceClue(id: "place-raigad", clue: "Find the Coronation Capital, where the crowning took place in 1674.", answer: "Raigad", hint: "Raigad is the Coronation Capital; Rajgad was the comeback place.")],
                pairs: [], familyPrompt: "Retell return, recovery, and coronation. What does self-rule mean, and how can people care for one another?")
        }
    }
}
