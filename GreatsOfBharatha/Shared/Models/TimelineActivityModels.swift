import Foundation

struct TimelineActivityCard: Identifiable, Equatable {
    let id: String
    let sceneID: String
    let title: String
    let teachingText: String
    let yearLabel: String?
    let symbol: String
}

struct TimelineActivityRound: Identifiable, Equatable {
    let id: String
    let cards: [TimelineActivityCard]
}

/// iOS adapts the existing seven-event TV sequence. Dates and titles come from
/// canonical content; teaching text is reused from TVLearningContent, not new history.
enum TimelineActivityCatalog {
    private struct Teaching {
        let eventID: String
        let sceneID: String
        let text: String
        let symbol: String
    }

    private static let teaching: [Teaching] = [
        Teaching(eventID: "timeline-born-at-shivneri", sceneID: "scene-1-shivneri",
                 text: "The journey begins at Shivneri, the Birth Fort.", symbol: "sunrise.fill"),
        Teaching(eventID: "timeline-early-forts", sceneID: "scene-2-torna-rajgad",
                 text: "Next came early fort-building: Torna and the planning base at Rajgad.", symbol: "mountain.2.fill"),
        Teaching(eventID: "timeline-pratapgad-turning-point", sceneID: "scene-3-pratapgad-turning-point",
                 text: "After the early forts, Pratapgad became a turning point in 1659.", symbol: "binoculars.fill"),
        Teaching(eventID: "timeline-pressure-at-purandar", sceneID: "scene-4-purandar-agra",
                 text: "Pressure led to a difficult agreement at Purandar in 1665.", symbol: "shield.fill"),
        Teaching(eventID: "timeline-agra-and-return", sceneID: "scene-4-purandar-agra",
                 text: "After Purandar came Agra in 1666, and then the return home.", symbol: "arrow.uturn.backward.circle.fill"),
        Teaching(eventID: "timeline-comeback-and-rebuilding", sceneID: "scene-5-rajgad-recovery",
                 text: "After returning from Agra, Shivaji Maharaj rebuilt strength at Rajgad.", symbol: "leaf.fill"),
        Teaching(eventID: "timeline-raigad-coronation", sceneID: "scene-6-raigad-coronation",
                 text: "After the comeback, the coronation took place at Raigad in 1674.", symbol: "crown.fill")
    ]

    static func cards(events: [TimelineEvent]) -> [TimelineActivityCard] {
        teaching.compactMap { item in
            guard let event = events.first(where: { $0.id == item.eventID }) else { return nil }
            return TimelineActivityCard(id: event.id, sceneID: item.sceneID, title: event.title,
                                        teachingText: item.text, yearLabel: event.yearLabel, symbol: item.symbol)
        }
    }

    static func allRounds(events: [TimelineEvent]) -> [TimelineActivityRound] {
        let cards = cards(events: events)
        guard cards.count == teaching.count else { return [] }
        return [
            TimelineActivityRound(id: "ios-timeline-opening", cards: Array(cards[0...2])),
            TimelineActivityRound(id: "ios-timeline-middle", cards: Array(cards[2...4])),
            TimelineActivityRound(id: "ios-timeline-return", cards: Array(cards[4...6]))
        ]
    }

    static func availableRounds(events: [TimelineEvent], checkedSceneIDs: Set<String>) -> [TimelineActivityRound] {
        let rounds = allRounds(events: events)
        guard Set(teaching.prefix(3).map(\.sceneID)).isSubset(of: checkedSceneIDs) else { return [] }
        return Set(teaching.map(\.sceneID)).isSubset(of: checkedSceneIDs) ? rounds : Array(rounds.prefix(1))
    }

    /// Exposure, reflection, self-report and a failed attempt cannot open a checked round.
    static func hasCheckedLearning(evidence: [MasteryEvidence]) -> Bool {
        evidence.contains {
            ($0.type == .recallSuccess || $0.type == .reviewSuccess) && $0.support != .selfReported
        }
    }
}

/// A receipt for one explicit, correct tap-card/tap-slot placement. The store adapter
/// must use eventID for idempotence and retain support; this is never later-recall evidence.
struct TimelinePlacementCheck: Codable, Equatable, Identifiable {
    let eventID: UUID
    let sessionID: UUID
    let roundID: String
    let eventSubjectID: String
    let slotIndex: Int
    let support: LearningSupport

    var id: UUID { eventID }

    func isValid(round: TimelineActivityRound, sessionID: UUID) -> Bool {
        self.sessionID == sessionID && roundID == round.id && support != .selfReported
            && round.cards.indices.contains(slotIndex) && round.cards[slotIndex].id == eventSubjectID
    }
}

struct TimelineRoundProgress: Codable, Equatable {
    var teachingSeen = false
    var slots: [String?] = Array(repeating: nil, count: 3)
    var selectedCardID: String?
    var hintLevel = 0
    var retryCount = 0
    var support: LearningSupport = .independent
    var feedback: String?
    var checksByCardID: [String: TimelinePlacementCheck] = [:]
    var acknowledgedEventIDs: Set<UUID> = []
}

/// Kept separately from a chapter resume point so optional ordering never replaces
/// an in-progress lesson or the rich television journey.
struct TimelineActivityCheckpoint: Codable, Equatable {
    var schemaVersion = 1
    var sessionID = UUID()
    var currentRoundID = "ios-timeline-opening"
    var rounds: [String: TimelineRoundProgress] = [:]
}

enum TimelineActivityEngine {
    static func restored(_ checkpoint: TimelineActivityCheckpoint?, allRounds: [TimelineActivityRound],
                         availableRounds: [TimelineActivityRound]) -> TimelineActivityCheckpoint {
        var next = checkpoint?.schemaVersion == 1 ? checkpoint ?? TimelineActivityCheckpoint() : TimelineActivityCheckpoint()
        next.rounds = next.rounds.filter { key, _ in allRounds.contains(where: { $0.id == key }) }
        var usedEventIDs: Set<UUID> = []
        for round in allRounds {
            var progress = next.rounds[round.id] ?? TimelineRoundProgress()
            progress.checksByCardID = progress.checksByCardID.filter { key, check in
                key == check.eventSubjectID && check.isValid(round: round, sessionID: next.sessionID)
            }
            // The store deduplicates globally, so each actual subject placement needs its own receipt.
            for card in round.cards {
                if let check = progress.checksByCardID[card.id], !usedEventIDs.insert(check.eventID).inserted {
                    progress.checksByCardID.removeValue(forKey: card.id)
                }
            }
            let stored = progress.slots
            progress.slots = round.cards.enumerated().map { index, card in
                stored.indices.contains(index) && stored[index] == card.id
                    && progress.checksByCardID[card.id]?.slotIndex == index ? card.id : nil
            }
            progress.checksByCardID = progress.checksByCardID.filter { progress.slots.contains($0.key) }
            progress.acknowledgedEventIDs.formIntersection(Set(progress.checksByCardID.values.map(\.eventID)))
            progress.hintLevel = max(0, progress.hintLevel)
            progress.retryCount = max(0, progress.retryCount)
            if progress.support == .selfReported { progress.support = .hinted }
            if (progress.hintLevel > 0 || progress.retryCount > 0) && progress.support != .rescued { progress.support = .hinted }
            if let selected = progress.selectedCardID,
               !round.cards.contains(where: { $0.id == selected }) || progress.slots.contains(selected) {
                progress.selectedCardID = nil
            }
            next.rounds[round.id] = progress
        }
        if !availableRounds.contains(where: { $0.id == next.currentRoundID }), let first = availableRounds.first {
            next.currentRoundID = first.id
        }
        if let currentIndex = availableRounds.firstIndex(where: { $0.id == next.currentRoundID }),
           let unfinished = availableRounds.prefix(currentIndex).first(where: { !isComplete(round: $0, checkpoint: next) }) {
            next.currentRoundID = unfinished.id
        }
        return next
    }

    static func begin(round: TimelineActivityRound, checkpoint: inout TimelineActivityCheckpoint) {
        var progress = checkpoint.rounds[round.id] ?? TimelineRoundProgress()
        progress.teachingSeen = true
        progress.feedback = nil
        checkpoint.rounds[round.id] = progress
    }

    static func select(cardID: String, round: TimelineActivityRound, checkpoint: inout TimelineActivityCheckpoint) {
        var progress = checkpoint.rounds[round.id] ?? TimelineRoundProgress()
        guard progress.teachingSeen, round.cards.contains(where: { $0.id == cardID }), !progress.slots.contains(cardID) else { return }
        progress.selectedCardID = progress.selectedCardID == cardID ? nil : cardID
        progress.feedback = progress.selectedCardID == nil ? "Choose any remaining story card." : "Now tap its place in the story."
        checkpoint.rounds[round.id] = progress
    }

    @discardableResult
    static func place(slotIndex: Int, round: TimelineActivityRound, checkpoint: inout TimelineActivityCheckpoint,
                      eventID: UUID = UUID()) -> TimelinePlacementCheck? {
        var progress = checkpoint.rounds[round.id] ?? TimelineRoundProgress()
        guard progress.teachingSeen, round.cards.indices.contains(slotIndex), progress.slots.count == round.cards.count,
              progress.slots[slotIndex] == nil, let selected = progress.selectedCardID,
              round.cards.contains(where: { $0.id == selected }), !progress.slots.contains(selected) else { return nil }
        let correctCard = round.cards[slotIndex]
        guard selected == correctCard.id else {
            progress.retryCount = min(progress.retryCount, 999) + 1
            progress.hintLevel = max(progress.hintLevel, 1)
            progress.support = .hinted
            progress.feedback = "Let's look back together. " + correctCard.teachingText + " Your placed cards stay here."
            checkpoint.rounds[round.id] = progress
            return nil
        }
        let check = TimelinePlacementCheck(eventID: eventID, sessionID: checkpoint.sessionID, roundID: round.id,
                                           eventSubjectID: selected, slotIndex: slotIndex, support: progress.support)
        guard check.isValid(round: round, sessionID: checkpoint.sessionID),
              !checkpoint.rounds.values.contains(where: { $0.checksByCardID.values.contains(where: { $0.eventID == eventID }) }) else { return nil }
        progress.slots[slotIndex] = selected
        progress.selectedCardID = nil
        progress.checksByCardID[selected] = check
        progress.feedback = "That belongs here. " + correctCard.teachingText
        checkpoint.rounds[round.id] = progress
        return check
    }

    static func hint(round: TimelineActivityRound, checkpoint: inout TimelineActivityCheckpoint) {
        var progress = checkpoint.rounds[round.id] ?? TimelineRoundProgress()
        guard progress.teachingSeen, let index = progress.slots.firstIndex(where: { $0 == nil }),
              round.cards.indices.contains(index) else { return }
        progress.support = .hinted
        progress.hintLevel = min(progress.hintLevel, 2) + 1
        progress.feedback = "For \(slotTitle(index)), choose \(round.cards[index].title). " + round.cards[index].teachingText
        checkpoint.rounds[round.id] = progress
    }

    static func isComplete(round: TimelineActivityRound, checkpoint: TimelineActivityCheckpoint) -> Bool {
        guard !round.cards.isEmpty, let progress = checkpoint.rounds[round.id], progress.slots.count == round.cards.count else { return false }
        guard Set(progress.checksByCardID.values.map(\.eventID)).count == round.cards.count else { return false }
        return round.cards.enumerated().allSatisfy { index, card in
            guard let check = progress.checksByCardID[card.id] else { return false }
            return progress.slots[index] == card.id && check.eventSubjectID == card.id && check.slotIndex == index
                && check.isValid(round: round, sessionID: checkpoint.sessionID)
        }
    }

    static func pendingChecks(rounds: [TimelineActivityRound], checkpoint: TimelineActivityCheckpoint) -> [TimelinePlacementCheck] {
        rounds.flatMap { round in
            let progress = checkpoint.rounds[round.id] ?? TimelineRoundProgress()
            return round.cards.compactMap { card -> TimelinePlacementCheck? in
                guard let check = progress.checksByCardID[card.id], check.eventSubjectID == card.id,
                      check.isValid(round: round, sessionID: checkpoint.sessionID),
                      progress.slots.indices.contains(check.slotIndex), progress.slots[check.slotIndex] == card.id,
                      !progress.acknowledgedEventIDs.contains(check.eventID) else { return nil }
                return check
            }
        }
    }

    static func acknowledge(_ check: TimelinePlacementCheck, checkpoint: inout TimelineActivityCheckpoint) {
        guard var progress = checkpoint.rounds[check.roundID], progress.checksByCardID[check.eventSubjectID] == check else { return }
        progress.acknowledgedEventIDs.insert(check.eventID)
        checkpoint.rounds[check.roundID] = progress
    }

    static func advance(rounds: [TimelineActivityRound], checkpoint: inout TimelineActivityCheckpoint) {
        guard let index = rounds.firstIndex(where: { $0.id == checkpoint.currentRoundID }),
              isComplete(round: rounds[index], checkpoint: checkpoint), rounds.indices.contains(index + 1) else { return }
        checkpoint.currentRoundID = rounds[index + 1].id
    }

    static func slotTitle(_ index: Int) -> String {
        let titles = ["First", "Then", "After that"]
        return titles.indices.contains(index) ? titles[index] : "Place \(index + 1)"
    }
}
