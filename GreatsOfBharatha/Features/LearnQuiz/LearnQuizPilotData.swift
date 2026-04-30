import SwiftUI

enum GBFeatureFlags {
    static var historyLearnQuizResetEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment
        if let rawValue = environment["GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED"],
           ["1", "true", "yes"].contains(rawValue.lowercased()) {
            return true
        }
        return UserDefaults.standard.bool(forKey: "historyLearnQuizResetEnabled")
    }
}

struct LearnQuizPilotScene: Identifiable {
    let id: String
    let number: Int
    let title: String
    let subtitle: String
    let timeMarker: String
    let place: String
    let actionVerb: String
    let memoryHook: String
    let story: String
    let meaning: String
    let quiz: LearnQuizPrompt
    let matchPairs: [LearnQuizMatchPair]
    let chronicleEntry: LearnQuizChronicleEntry
    let art: LearnQuizArt
}

struct LearnQuizPrompt {
    let question: String
    let options: [String]
    let correctAnswer: String
    let hintLadder: [String]
    let teachingFeedback: String
}

struct LearnQuizMatchPair: Identifiable {
    let id: String
    let left: String
    let right: String
    let clue: String
}

struct LearnQuizChronicleEntry: Identifiable {
    enum State: String, CaseIterable {
        case silhouette
        case inked
        case sealed
        case rememberedAgain
    }

    let id: String
    let title: String
    let subtitle: String
    let meaning: String
    let state: State
}

struct LearnQuizArt {
    let assetSlot: String
    let symbol: String
    let emphasis: GBEmphasis
}

enum LearnQuizPilotData {
    static let scenes: [LearnQuizPilotScene] = [
        LearnQuizPilotScene(
            id: "learn-quiz-shivneri",
            number: 1,
            title: "Shivneri",
            subtitle: "Birth Fort",
            timeMarker: "Beginning",
            place: "Shivneri Fort",
            actionVerb: "Begins",
            memoryHook: "Birth Fort",
            story: "Shivaji Maharaj's story begins at Shivneri Fort. Jijabai helped him grow with courage, care, and a love for protecting people.",
            meaning: "Shivneri is the first place to remember because it anchors the whole journey.",
            quiz: LearnQuizPrompt(
                question: "Where does Shivaji Maharaj's story begin?",
                options: ["Shivneri", "Raigad", "Agra"],
                correctAnswer: "Shivneri",
                hintLadder: ["Memory hook: Birth Fort", "Place clue: a hill fort near Junnar", "Choose the fort where the journey begins."],
                teachingFeedback: "Shivneri is the birth fort. It is where this journey begins."
            ),
            matchPairs: [
                LearnQuizMatchPair(id: "shivneri-birth", left: "Shivneri", right: "Birth Fort", clue: "The beginning of the story."),
                LearnQuizMatchPair(id: "jijabai-values", left: "Jijabai", right: "Early values", clue: "Guidance helped shape young Shivaji.")
            ],
            chronicleEntry: LearnQuizChronicleEntry(
                id: "chronicle-birth-fort",
                title: "Birth Fort Chronicle Card",
                subtitle: "Shivneri",
                meaning: "The journey starts at Shivneri Fort.",
                state: .inked
            ),
            art: LearnQuizArt(assetSlot: "LearnQuizShivneriHero", symbol: "sunrise.fill", emphasis: .story)
        ),
        LearnQuizPilotScene(
            id: "learn-quiz-torna-rajgad",
            number: 2,
            title: "Torna + Rajgad",
            subtitle: "Early Forts",
            timeMarker: "Early Swarajya",
            place: "Torna and Rajgad",
            actionVerb: "Builds",
            memoryHook: "First Big Fort / Early Capital",
            story: "Torna became an early fort victory. Rajgad grew into a planning base where ideas for Swarajya could take shape.",
            meaning: "These forts help children remember that Swarajya was built with planning, places, and steady effort.",
            quiz: LearnQuizPrompt(
                question: "Which fort became an early capital and planning base?",
                options: ["Rajgad", "Pratapgad", "Shivneri"],
                correctAnswer: "Rajgad",
                hintLadder: ["Memory hook: Early Capital", "Place clue: paired with Torna in the early story", "Choose Rajgad."],
                teachingFeedback: "Rajgad is remembered as an early capital and planning base."
            ),
            matchPairs: [
                LearnQuizMatchPair(id: "torna-first-big", left: "Torna", right: "First Big Fort", clue: "A strong early step."),
                LearnQuizMatchPair(id: "rajgad-capital", left: "Rajgad", right: "Early Capital", clue: "A place for planning.")
            ],
            chronicleEntry: LearnQuizChronicleEntry(
                id: "chronicle-early-forts",
                title: "First Fort / Early Capital Card",
                subtitle: "Torna + Rajgad",
                meaning: "Early forts show planning and momentum.",
                state: .sealed
            ),
            art: LearnQuizArt(assetSlot: "LearnQuizTornaRajgadHero", symbol: "mountain.2.fill", emphasis: .place)
        ),
        LearnQuizPilotScene(
            id: "learn-quiz-pratapgad",
            number: 3,
            title: "Pratapgad",
            subtitle: "Turning Point",
            timeMarker: "Major rise",
            place: "Pratapgad",
            actionVerb: "Plans",
            memoryHook: "Turning Point",
            story: "At Pratapgad, terrain and careful planning mattered. The moment is remembered as a turning point in Shivaji Maharaj's rise.",
            meaning: "Pratapgad helps children connect place, strategy, and courage without needing a harsh battle story.",
            quiz: LearnQuizPrompt(
                question: "Which fort is remembered as the turning point?",
                options: ["Pratapgad", "Shivneri", "Torna"],
                correctAnswer: "Pratapgad",
                hintLadder: ["Memory hook: Turning Point", "Place clue: hill terrain and planning", "Choose Pratapgad."],
                teachingFeedback: "Pratapgad is the turning point to remember."
            ),
            matchPairs: [
                LearnQuizMatchPair(id: "pratapgad-turning", left: "Pratapgad", right: "Turning Point", clue: "The rise becomes clearer here."),
                LearnQuizMatchPair(id: "terrain-planning", left: "Hill terrain", right: "Careful planning", clue: "Place and action worked together.")
            ],
            chronicleEntry: LearnQuizChronicleEntry(
                id: "chronicle-turning-point",
                title: "Turning Point Seal",
                subtitle: "Pratapgad",
                meaning: "Strategy, terrain, and courage are linked here.",
                state: .silhouette
            ),
            art: LearnQuizArt(assetSlot: "LearnQuizPratapgadHero", symbol: "seal.fill", emphasis: .chronicle)
        )
    ]

    static let journeyEntry = LearnQuizChronicleEntry(
        id: "chronicle-journey-so-far",
        title: "Shivaji Journey So Far",
        subtitle: "Shivneri -> Torna/Rajgad -> Pratapgad",
        meaning: "The first three scenes form a remembered path through time, place, and action.",
        state: .rememberedAgain
    )
}
