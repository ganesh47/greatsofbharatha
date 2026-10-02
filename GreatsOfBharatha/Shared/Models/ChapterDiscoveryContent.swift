import CryptoKit
import Foundation

struct ChapterDiscovery: Identifiable, Equatable {
    let id: String
    let title: String
    let symbol: String
    let text: String

    var legacyID: String? {
        switch id {
        case "scene-1-shivneri-discovery-1": "hill"
        case "scene-1-shivneri-discovery-2": "book"
        case "scene-1-shivneri-discovery-3": "gate"
        default: nil
        }
    }

    var accessibilityID: String { "story-discovery-" + (legacyID ?? id) }

    func wasOpened(in ids: Set<String>) -> Bool {
        ids.contains(id) || legacyID.map { ids.contains($0) } == true
    }
}

struct ChapterPlaceClue: Identifiable, Equatable {
    let id: String
    let clue: String
    let answer: String
    let hint: String
}

/// Existing authored TV chapter content, adapted for either platform without inventing facts.
/// Canonical scene/location/discovery identities are unchanged. Exploration is never assessment.
struct ChapterDiscoveryContent: Identifiable, Equatable {
    let id: String
    let teachingText: String
    let discoveries: [ChapterDiscovery]
    let placeClues: [ChapterPlaceClue]
    let familyPrompt: String

    static func chapter(sceneID: String) -> ChapterDiscoveryContent? {
        chapters.first { $0.id == sceneID }
    }

    func discovery(id: String) -> ChapterDiscovery? { discoveries.first { $0.id == id } }
    func placeClue(placeID: String) -> ChapterPlaceClue? { placeClues.first { $0.id == placeID } }

    func restoredDiscovery(id: String?) -> ChapterDiscovery? {
        guard let id else { return nil }
        return discoveries.first { $0.id == id || $0.legacyID == id }
    }

    func openedDiscoveryIDs(in ids: Set<String>) -> Set<String> {
        Set(discoveries.filter { $0.wasOpened(in: ids) }.map(\.id))
    }

    /// Stable across retries and process termination; independent of randomized Swift hash values.
    func exposureEventID(discoveryID: String, sessionID: UUID) -> UUID? {
        guard discovery(id: discoveryID) != nil else { return nil }
        let bytes = Array(SHA256.hash(data: Data(("chapter-discovery:" + sessionID.uuidString + ":" + discoveryID).utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    private struct Detail {
        let title: String
        let symbol: String
        let text: String
    }

    private static func make(id: String, teachingText: String, discoveries: [Detail],
                             placeClues: [ChapterPlaceClue], familyPrompt: String) -> ChapterDiscoveryContent {
        ChapterDiscoveryContent(id: id, teachingText: teachingText,
            discoveries: discoveries.enumerated().map { index, detail in
                ChapterDiscovery(id: id + "-discovery-\(index + 1)", title: detail.title, symbol: detail.symbol, text: detail.text)
            }, placeClues: placeClues, familyPrompt: familyPrompt)
    }

    static let chapters: [ChapterDiscoveryContent] = [
        make(id: "scene-1-shivneri",
            teachingText: "Shivneri is the Birth Fort near Junnar. Jijabai's guidance taught courage, care, and responsibility.",
            discoveries: [
                Detail(title: "Look at the hills", symbol: "mountain.2.fill",
                    text: "Shivneri is a hill fort near Junnar. The hills help us remember a real place where the journey began."),
                Detail(title: "Meet Jijabai", symbol: "person.2.fill",
                    text: "Jijabai guided young Shivaji with courage, care, and responsibility."),
                Detail(title: "Keep a memory", symbol: "sunrise.fill",
                    text: "Birth Fort is a short memory hook for Shivneri.")
            ],
            placeClues: [
                ChapterPlaceClue(id: "place-shivneri",
                    clue: "Find the Birth Fort near Junnar.", answer: "Shivneri",
                    hint: "The journey begins at Shivneri.")
            ],
            familyPrompt: "Tell someone: where did the journey begin, and who helped Shivaji grow?"),
        make(id: "scene-2-torna-rajgad",
            teachingText: "Torna is remembered as the First Big Fort. Rajgad is remembered as the Early Capital and planning base. First came "
                + "Shivneri, then the early forts.",
            discoveries: [
                Detail(title: "First Big Fort", symbol: "flag.fill",
                    text: "Torna marks an early win in building Swarajya, or self-rule."),
                Detail(title: "Planning home", symbol: "house.fill",
                    text: "Rajgad became the early capital, a home base for careful planning."),
                Detail(title: "Two different jobs", symbol: "arrow.left.arrow.right",
                    text: "Torna means First Big Fort. Rajgad means Early Capital. A first win and a strong home base both matter.")
            ],
            placeClues: [
                ChapterPlaceClue(id: "place-torna",
                    clue: "Find the fort with the hook First Big Fort.", answer: "Torna",
                    hint: "Torna was an early win."),
                ChapterPlaceClue(id: "place-rajgad",
                    clue: "Find the Early Capital and planning home base.", answer: "Rajgad",
                    hint: "Rajgad became the early capital; Torna is the First Big Fort.")
            ],
            familyPrompt: "Give Torna and Rajgad different jobs in your retelling: first big fort and planning home."),
        make(id: "scene-3-pratapgad-turning-point",
            teachingText: "Pratapgad is the Turning Point. Hill terrain means the shape of the land; careful planning means being prepared. First "
                + "came Shivneri, then the early forts, and then Pratapgad in 1659.",
            discoveries: [
                Detail(title: "Read the land", symbol: "mountain.2.fill",
                    text: "Terrain means the shape of the land. The hills mattered at Pratapgad."),
                Detail(title: "Make a plan", symbol: "binoculars.fill",
                    text: "Careful planning means being prepared and making wise choices."),
                Detail(title: "A turning point", symbol: "arrow.turn.up.right",
                    text: "Pratapgad changed what happened next, after the early forts.")
            ],
            placeClues: [
                ChapterPlaceClue(id: "place-pratapgad",
                    clue: "Find the Turning Point fort, where hills and planning mattered.", answer: "Pratapgad",
                    hint: "Pratapgad is our Turning Point memory hook.")
            ],
            familyPrompt: "Explain what terrain means. How could knowing the land help someone prepare?"),
        make(id: "scene-4-purandar-agra",
            teachingText: "After Pratapgad in 1659 came pressure and a difficult agreement at Purandar in 1665. Later came Agra, a northern city, "
                + "in 1666 and the return home. Purandar comes before Agra.",
            discoveries: [
                Detail(title: "A hard choice", symbol: "shield.fill",
                    text: "At Purandar, Shivaji Maharaj made a difficult agreement under pressure."),
                Detail(title: "A northern city", symbol: "building.columns.fill",
                    text: "Agra is a city in northern India. After Purandar came Agra and the return home."),
                Detail(title: "Patience helps", symbol: "arrow.uturn.backward.circle.fill",
                    text: "Patience and planning helped Shivaji Maharaj keep going through a setback and return home.")
            ],
            placeClues: [
                ChapterPlaceClue(id: "place-purandar",
                    clue: "Find the Pressure Fort, where a difficult agreement came first.", answer: "Purandar",
                    hint: "Purandar came before Agra."),
                ChapterPlaceClue(id: "place-agra",
                    clue: "Find the northern city from which Shivaji Maharaj returned home.", answer: "Agra",
                    hint: "Agra is the northern city, after Purandar.")
            ],
            familyPrompt: "Retell the order with three words: Pratapgad, Purandar, Agra. What helped through the setback?"),
        make(id: "scene-5-rajgad-recovery",
            teachingText: "Rajgad now has a second memory hook: Comeback. Rebuilding strength and reorganizing mean steady recovery after a "
                + "setback. This happened after the return from Agra.",
            discoveries: [
                Detail(title: "Rajgad returns", symbol: "house.fill",
                    text: "Rajgad first appeared as Early Capital. In this chapter, it is the Comeback place."),
                Detail(title: "Build again", symbol: "leaf.fill",
                    text: "After returning from Agra, Shivaji Maharaj rebuilt strength and grew stronger."),
                Detail(title: "Steady organization", symbol: "square.grid.2x2.fill",
                    text: "Reorganizing and planning again helped the recovery. Steady work can matter as much as a dramatic moment.")
            ],
            placeClues: [
                ChapterPlaceClue(id: "place-rajgad",
                    clue: "Find the Comeback place, where strength was rebuilt after Agra.", answer: "Rajgad",
                    hint: "Rajgad appears twice: Early Capital before, Comeback now.")
            ],
            familyPrompt: "Tell a comeback story: how did planning and steady work help after Agra?"),
        make(id: "scene-6-raigad-coronation",
            teachingText: "First came the return from Agra, then rebuilding at Rajgad, and then the coronation at Raigad in 1674. Coronation means "
                + "a crowning ceremony. Swarajya means self-rule, with responsibility and care for people.",
            discoveries: [
                Detail(title: "A crowning ceremony", symbol: "crown.fill",
                    text: "In 1674 at Raigad, Shivaji Maharaj was crowned Chhatrapati. Coronation means a crowning ceremony."),
                Detail(title: "What is Swarajya?", symbol: "sun.max.fill",
                    text: "Swarajya means self-rule: people guiding and caring for their own land with dignity."),
                Detail(title: "Remember the whole path", symbol: "book.fill",
                    text: "The coronation came after the return from Agra and the comeback at Rajgad.")
            ],
            placeClues: [
                ChapterPlaceClue(id: "place-raigad",
                    clue: "Find the Coronation Capital, where the crowning took place in 1674.", answer: "Raigad",
                    hint: "Raigad is the Coronation Capital; Rajgad was the comeback place.")
            ],
            familyPrompt: "Retell return, recovery, and coronation. What does self-rule mean, and how can people care for one another?")
    ]
}

/// Durable exploration only. The same event ID makes a retry after interruption harmless.
@MainActor
enum ChapterDiscoveryInteraction {
    @discardableResult
    static func open(_ discovery: ChapterDiscovery, content: ChapterDiscoveryContent,
                     store: ShivajiLessonStore) -> LessonResumePoint? {
        guard ChapterDiscoveryContent.chapter(sceneID: content.id) == content,
              content.discovery(id: discovery.id) == discovery else { return nil }
        var point = store.resumePoint(for: content.id) ?? LessonResumePoint(sceneID: content.id)
        guard let eventID = content.exposureEventID(discoveryID: discovery.id, sessionID: point.sessionID) else { return nil }
        let wasOpened = discovery.wasOpened(in: point.discoveredDetailIDs)
        if point.selectedDiscoveryDetailID != discovery.id {
            point.selectedDiscoveryDetailID = discovery.id
            point.updatedAt = Date()
        }
        // Persist session and selection before evidence, so a termination between the two writes
        // still reconstructs exactly the same event on the next launch.
        store.saveResumePoint(point)
        if !wasOpened {
            store.recordStoryExposure(for: content.id, detail: discovery.text, eventID: eventID, sessionID: point.sessionID)
        }
        if !point.discoveredDetailIDs.contains(discovery.id) {
            point.discoveredDetailIDs.insert(discovery.id)
            point.updatedAt = Date()
            store.saveResumePoint(point)
        }
        return point
    }
}
