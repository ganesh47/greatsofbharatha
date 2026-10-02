import XCTest
@testable import GreatsOfBharathaTV

final class TVSequenceEngineTests: XCTestCase {
    private var cards: [TVSequenceCard] {
        [
            TVSequenceCard(id: "birth", title: "Birth", teachingText: "The story begins at Shivneri.", symbol: "sun.max", sceneID: "scene-1-shivneri"),
            TVSequenceCard(id: "forts", title: "Early forts", teachingText: "Torna and Rajgad came next.", symbol: "flag", sceneID: "scene-2-torna-rajgad"),
            TVSequenceCard(id: "turn", title: "Turning point", teachingText: "Pratapgad came after the early forts.",
                           symbol: "arrow.turn.up.right", sceneID: "scene-3-pratapgad-turning-point")
        ]
    }

    func testSelectingDoesNotPlaceOrCompleteAnything() {
        let initial = TVSequenceState(cardCount: cards.count)
        let selected = TVSequenceEngine.select(cardID: "forts", state: initial, cards: cards)
        XCTAssertEqual(selected.selectedCardID, "forts")
        XCTAssertEqual(selected.slots, [nil, nil, nil])
        XCTAssertFalse(TVSequenceEngine.isComplete(state: selected, cards: cards))
    }

    func testIncorrectSlotKeepsCardAvailableAndTeachesWithoutCountingProgress() {
        let selected = TVSequenceEngine.select(cardID: "forts", state: TVSequenceState(cardCount: 3), cards: cards)
        let incorrect = TVSequenceEngine.place(slotIndex: 0, state: selected, cards: cards)
        XCTAssertEqual(incorrect.slots, [nil, nil, nil])
        XCTAssertEqual(incorrect.selectedCardID, "forts")
        XCTAssertTrue(incorrect.helped)
        XCTAssertFalse(incorrect.feedback?.isEmpty ?? true)
        XCTAssertFalse(TVSequenceEngine.isComplete(state: incorrect, cards: cards))
        let corrected = TVSequenceEngine.place(slotIndex: 1, state: incorrect, cards: cards)
        XCTAssertEqual(corrected.slots, [nil, "forts", nil])
    }

    func testCorrectPlacementsStayLockedAndCompletionRequiresEverySlot() {
        var state = TVSequenceState(cardCount: cards.count)
        for index in cards.indices {
            state = TVSequenceEngine.select(cardID: cards[index].id, state: state, cards: cards)
            state = TVSequenceEngine.place(slotIndex: index, state: state, cards: cards)
            XCTAssertEqual(state.slots[index], cards[index].id)
            XCTAssertEqual(TVSequenceEngine.isComplete(state: state, cards: cards), index == cards.count - 1)
        }
        let completed = state.slots
        state = TVSequenceEngine.select(cardID: "birth", state: state, cards: cards)
        state = TVSequenceEngine.place(slotIndex: 2, state: state, cards: cards)
        XCTAssertEqual(state.slots, completed)
    }

    func testUnknownCardsAndOutOfBoundsSlotsCannotChangeProgress() {
        let initial = TVSequenceState(cardCount: cards.count)
        let unknown = TVSequenceEngine.select(cardID: "missing", state: initial, cards: cards)
        XCTAssertEqual(unknown.slots, initial.slots)
        XCTAssertNil(unknown.selectedCardID)
        let selected = TVSequenceEngine.select(cardID: "birth", state: initial, cards: cards)
        for index in [-1, cards.count, 999] {
            let result = TVSequenceEngine.place(slotIndex: index, state: selected, cards: cards)
            XCTAssertEqual(result.slots, initial.slots)
            XCTAssertFalse(TVSequenceEngine.isComplete(state: result, cards: cards))
        }
    }

    func testHintsAndRescueRetainCorrectPlacementsAndMarkAssistance() {
        var state = TVSequenceEngine.select(cardID: "forts", state: TVSequenceState(cardCount: 3), cards: cards)
        state = TVSequenceEngine.place(slotIndex: 1, state: state, cards: cards)
        state = TVSequenceEngine.revealHint(state: state, cards: cards)
        XCTAssertTrue(state.helped)
        XCTAssertGreaterThan(state.hintLevel, 0)
        XCTAssertEqual(state.slots[1], "forts")
        for _ in cards.indices {
            state = TVSequenceEngine.rescueNext(state: state, cards: cards)
            XCTAssertEqual(state.slots[1], "forts")
        }
        XCTAssertTrue(TVSequenceEngine.isComplete(state: state, cards: cards))
        XCTAssertEqual(state.slots, cards.map { Optional($0.id) })
        XCTAssertTrue(state.helped)
    }

    func testMalformedDuplicateOrReorderedSlotsDoNotPassCompletion() {
        var state = TVSequenceState(cardCount: cards.count)
        state.slots = ["birth", "birth", "turn"]
        XCTAssertFalse(TVSequenceEngine.isComplete(state: state, cards: cards))
        state.slots = ["forts", "birth", "turn"]
        XCTAssertFalse(TVSequenceEngine.isComplete(state: state, cards: cards))
        state.slots = ["birth", "forts"]
        XCTAssertFalse(TVSequenceEngine.isComplete(state: state, cards: cards))
    }

    func testMultipleCluesRemainHintsUntilAnExplicitRescuePlacesACard() {
        var state = TVSequenceState(cardCount: cards.count)
        for _ in 0..<4 { state = TVSequenceEngine.revealHint(state: state, cards: cards) }
        XCTAssertTrue(state.helped)
        XCTAssertFalse(state.rescued)
        XCTAssertEqual(state.slots, [nil, nil, nil])
        state = TVSequenceEngine.rescueNext(state: state, cards: cards)
        XCTAssertTrue(state.rescued)
        XCTAssertEqual(state.slots, ["birth", nil, nil])
    }
}
