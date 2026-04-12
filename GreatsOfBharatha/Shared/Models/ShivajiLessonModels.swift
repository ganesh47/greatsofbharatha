import Foundation

struct Scene: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let locationLine: String
    let keyFact: String
    let rewardTitle: String
    let badgeTitle: String
    let timelineLabel: String
    let accentName: String
    let cards: [SceneCard]
    let recallQuestion: RecallQuestion
}

struct SceneCard: Identifiable, Hashable {
    let id: String
    let eyebrow: String
    let title: String
    let body: String
    let symbol: String
}

struct RecallQuestion: Hashable {
    let prompt: String
    let choices: [RecallChoice]
    let correctChoiceID: String
    let successTitle: String
    let successMessage: String
    let gentleHint: String
}

struct RecallChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
}

enum MasteryState: Int, CaseIterable, Comparable {
    case witnessed
    case understood
    case observedClosely

    var title: String {
        switch self {
        case .witnessed: return "Witnessed"
        case .understood: return "Understood"
        case .observedClosely: return "Observed Closely"
        }
    }

    var description: String {
        switch self {
        case .witnessed: return "Saw the moment and can name it."
        case .understood: return "Can explain the key idea."
        case .observedClosely: return "Can recall details with confidence."
        }
    }

    static func < (lhs: MasteryState, rhs: MasteryState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct ChronicleEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let unlockedNarrative: String
    let lockedNarrative: String
}

extension Scene {
    static let all: [Scene] = [sceneOne, sceneTwo]

    static let sceneOne = Scene(
        id: "scene-1",
        title: "Scene 1, Shivneri",
        subtitle: "The child who would grow into a leader",
        locationLine: "Shivneri Fort, near Junnar",
        keyFact: "Shivaji Maharaj was born at Shivneri Fort, and Jijabai shaped how his story is remembered and taught.",
        rewardTitle: "Birth Fort",
        badgeTitle: "Courage Begins at Home",
        timelineLabel: "Born at Shivneri",
        accentName: "Saffron Dawn",
        cards: [
            SceneCard(id: "s1c1", eyebrow: "Fort", title: "A hill fort watches the morning", body: "Stone walls, quiet wind, and watchful paths made Shivneri feel strong and safe.", symbol: "building.2.crop.circle"),
            SceneCard(id: "s1c2", eyebrow: "Guide", title: "Jijabai teaches with purpose", body: "Stories, values, and duty were part of Shivaji's world from childhood.", symbol: "person.crop.circle.badge.heart"),
            SceneCard(id: "s1c3", eyebrow: "Meaning", title: "A beginning tied to place", body: "The story starts with a real fort, a family, and a future still unseen.", symbol: "sparkles")
        ],
        recallQuestion: RecallQuestion(
            prompt: "Which fort is remembered as Shivaji Maharaj's birth place?",
            choices: [
                RecallChoice(id: "torna", title: "Torna", detail: "An early major fort victory."),
                RecallChoice(id: "shivneri", title: "Shivneri", detail: "The opening place in this story."),
                RecallChoice(id: "rajgad", title: "Rajgad", detail: "An early capital and power center.")
            ],
            correctChoiceID: "shivneri",
            successTitle: "Chronicle updated",
            successMessage: "You unlocked the Birth Fort card and moved this moment into your Chronicle.",
            gentleHint: "We first meet Shivaji Maharaj as a child inside the fort near Junnar."
        )
    )

    static let sceneTwo = Scene(
        id: "scene-2",
        title: "Scene 2, Torna and Rajgad",
        subtitle: "The start of Swarajya",
        locationLine: "Torna first, Rajgad as an early capital",
        keyFact: "Torna was an early breakthrough, and Rajgad became an important early capital or power center.",
        rewardTitle: "First Big Fort",
        badgeTitle: "Planning in the Mountains",
        timelineLabel: "Early forts",
        accentName: "Mountain Resolve",
        cards: [
            SceneCard(id: "s2c1", eyebrow: "Action", title: "Torna marks an early breakthrough", body: "A strong fort changed the story from hope into action.", symbol: "flag.pattern.checkered"),
            SceneCard(id: "s2c2", eyebrow: "State-building", title: "Rajgad becomes a planning center", body: "Forts were not only captured. They were used to organize, protect, and prepare.", symbol: "shield.lefthalf.filled"),
            SceneCard(id: "s2c3", eyebrow: "Meaning", title: "Swarajya grows through careful choices", body: "The mountains became a place for planning, courage, and long-term thinking.", symbol: "map")
        ],
        recallQuestion: RecallQuestion(
            prompt: "Which fort became an early capital or power center?",
            choices: [
                RecallChoice(id: "rajgad", title: "Rajgad", detail: "A key early center for planning and power."),
                RecallChoice(id: "shivneri", title: "Shivneri", detail: "The fort linked to birth and early childhood."),
                RecallChoice(id: "pratapgad", title: "Pratapgad", detail: "A later turning point in the story.")
            ],
            correctChoiceID: "rajgad",
            successTitle: "Fort badge earned",
            successMessage: "You unlocked First Big Fort and strengthened your Chronicle entry for the early forts.",
            gentleHint: "Think about the fort that became important for planning, not the one linked to birth."
        )
    )
}

extension ChronicleEntry {
    static let all: [ChronicleEntry] = [
        ChronicleEntry(
            id: Scene.sceneOne.id,
            title: "Birth Fort",
            subtitle: "Shivneri and Jijabai's influence",
            symbol: "sunrise.fill",
            unlockedNarrative: "A remembered beginning at Shivneri Fort, shaped by Jijabai's guidance.",
            lockedNarrative: "Complete Scene 1 to unlock this Chronicle card."
        ),
        ChronicleEntry(
            id: Scene.sceneTwo.id,
            title: "First Big Fort",
            subtitle: "Torna and Rajgad in the rise of Swarajya",
            symbol: "flag.fill",
            unlockedNarrative: "An early breakthrough at Torna, with Rajgad becoming an important center of planning.",
            lockedNarrative: "Complete Scene 2 to unlock this Chronicle card."
        )
    ]
}
