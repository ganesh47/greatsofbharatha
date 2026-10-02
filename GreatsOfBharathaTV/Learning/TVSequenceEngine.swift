import Foundation

struct TVSequenceCard: Identifiable, Equatable {
    let id: String
    let title: String
    let teachingText: String
    let symbol: String
    let sceneID: String
}

struct TVSequenceState: Equatable {
    var slots: [String?]
    var selectedCardID: String?
    var hintLevel = 0
    var helped = false
    var rescued = false
    var feedback: String?

    init(cardCount: Int) {
        slots = Array(repeating: nil, count: max(cardCount, 0))
    }

    init(slots: [String?], selectedCardID: String? = nil, hintLevel: Int = 0,
         helped: Bool = false, rescued: Bool = false, feedback: String? = nil) {
        self.slots = slots
        self.selectedCardID = selectedCardID
        self.hintLevel = hintLevel
        self.helped = helped
        self.rescued = rescued
        self.feedback = feedback
    }
}

/// Selecting is reversible; only an explicit placement checks the order.
/// Correct placements stay in place so a mistake never erases a child's work.
enum TVSequenceEngine {
    static func select(cardID: String, state: TVSequenceState, cards: [TVSequenceCard]) -> TVSequenceState {
        guard cards.contains(where: { $0.id == cardID }), !state.slots.contains(cardID) else { return state }
        var next = state
        next.selectedCardID = state.selectedCardID == cardID ? nil : cardID
        next.feedback = next.selectedCardID == nil ? "Selection put away. Choose any remaining card." : "Now choose its place in the story."
        return next
    }

    static func place(slotIndex: Int, state: TVSequenceState, cards: [TVSequenceCard]) -> TVSequenceState {
        guard state.slots.indices.contains(slotIndex), cards.indices.contains(slotIndex),
              state.slots[slotIndex] == nil, let selected = state.selectedCardID,
              cards.contains(where: { $0.id == selected }) else { return state }
        var next = state
        if cards[slotIndex].id == selected {
            next.slots[slotIndex] = selected
            next.selectedCardID = nil
            next.feedback = "That belongs here. " + cards[slotIndex].teachingText
        } else {
            next.helped = true
            next.hintLevel = max(next.hintLevel, 1)
            next.feedback = "Let's remember this part. " + cards[slotIndex].teachingText
        }
        return next
    }

    static func revealHint(state: TVSequenceState, cards: [TVSequenceCard]) -> TVSequenceState {
        var next = state
        next.helped = true
        next.hintLevel += 1
        if let index = next.slots.firstIndex(where: { $0 == nil }), cards.indices.contains(index) {
            next.feedback = "For \(slotTitle(index: index)), choose \(cards[index].title). " + cards[index].teachingText
        }
        return next
    }

    /// Called only by an explicit help action, never by focus or a timer.
    static func rescueNext(state: TVSequenceState, cards: [TVSequenceCard]) -> TVSequenceState {
        var next = state
        guard let index = next.slots.firstIndex(where: { $0 == nil }), cards.indices.contains(index) else { return state }
        next.helped = true
        next.hintLevel = max(next.hintLevel, 2)
        next.rescued = true
        next.slots[index] = cards[index].id
        next.selectedCardID = nil
        next.feedback = "We placed \(cards[index].title) together. " + cards[index].teachingText
        return next
    }

    static func isComplete(state: TVSequenceState, cards: [TVSequenceCard]) -> Bool {
        !cards.isEmpty && state.slots.count == cards.count
            && zip(state.slots, cards).allSatisfy { $0.0 == $0.1.id }
    }

    static func slotTitle(index: Int) -> String {
        ["First", "Then", "After that"].indices.contains(index) ? ["First", "Then", "After that"][index] : "Place \(index + 1)"
    }
}
