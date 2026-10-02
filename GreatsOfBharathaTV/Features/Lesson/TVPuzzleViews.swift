import SwiftUI

struct TVSequencePuzzle: View {
    let cards: [TVSequenceCard]
    @Binding var state: TVSequenceState
    let onChange: () -> Void
    @FocusState private var focus: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Story cards").font(.system(size: 26, weight: .bold))
                    ForEach(Array(cards.reversed())) { card in
                        Button {
                            guard !state.slots.contains(card.id) else { return }
                            state = TVSequenceEngine.select(cardID: card.id, state: state, cards: cards)
                            onChange()
                        } label: {
                            Text(card.title + " · " + cardStatus(card))
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(focus == "card-" + card.id ? TVTheme.ink : TVTheme.paper)
                                .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .focused($focus, equals: "card-" + card.id)
                        .accessibilityLabel(card.title)
                        .accessibilityIdentifier("tv-sequence-card-" + card.id)
                        .accessibilityValue(cardStatus(card))
                    }
                }.frame(maxWidth: .infinity).focusSection()
                VStack(alignment: .leading, spacing: 18) {
                    Text("Places in the story").font(.system(size: 26, weight: .bold))
                    ForEach(cards.indices, id: \.self) { index in
                        Button {
                            guard state.slots[index] == nil else { return }
                            guard state.selectedCardID != nil else {
                                state.feedback = "Choose a story card on the left, then choose its place on the right."
                                return
                            }
                            state = TVSequenceEngine.place(slotIndex: index, state: state, cards: cards)
                            onChange()
                        } label: {
                            Text(TVSequenceEngine.slotTitle(index: index) + "\n" + slotDescription(index))
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundStyle(focus == "slot-\(index)" ? TVTheme.ink : TVTheme.paper)
                                .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .focused($focus, equals: "slot-\(index)")
                        .accessibilityLabel(TVSequenceEngine.slotTitle(index: index))
                        .accessibilityValue(state.slots[index].flatMap { id in cards.first(where: { $0.id == id })?.title } ?? "Empty. Choose a story card, then select here.")
                        .accessibilityIdentifier("tv-sequence-slot-\(index)")
                    }
                }.frame(maxWidth: .infinity).focusSection()
            }
            if let feedback = state.feedback {
                Text(feedback).font(.system(size: 26)).foregroundStyle(GBColor.Content.primary)
                    .accessibilityIdentifier("tv-sequence-feedback")
            }
            if !TVSequenceEngine.isComplete(state: state, cards: cards) {
                HStack(spacing: 24) {
                    Button("Help me remember") {
                        state = TVSequenceEngine.revealHint(state: state, cards: cards)
                        onChange()
                    }.buttonStyle(TVCardButtonStyle())
                        .accessibilityIdentifier("tv-sequence-help")
                    if state.hintLevel >= 1 {
                        Button("Place one with help") {
                            state = TVSequenceEngine.rescueNext(state: state, cards: cards)
                            onChange()
                        }.buttonStyle(TVCardButtonStyle())
                            .accessibilityIdentifier("tv-sequence-rescue")
                    }
                }
            }
        }
        .task {
            await Task.yield()
            guard !TVSequenceEngine.isComplete(state: state, cards: cards) else { return }
            if let index = preferredSlotIndex { focus = "slot-\(index)" }
            else if let id = preferredCardID { focus = "card-" + id }
        }
    }

    private var preferredCardID: String? {
        guard state.selectedCardID == nil else { return nil }
        return cards.reversed().first(where: { !state.slots.contains($0.id) })?.id
    }

    private var preferredSlotIndex: Int? {
        guard state.selectedCardID != nil else { return nil }
        return state.slots.firstIndex(where: { $0 == nil })
    }

    private func cardStatus(_ card: TVSequenceCard) -> String {
        state.slots.contains(card.id) ? "Placed" : (state.selectedCardID == card.id ? "Selected" : "Available")
    }

    private func slotDescription(_ index: Int) -> String {
        state.slots[index].flatMap { id in cards.first(where: { $0.id == id })?.title } ?? "Choose a card, then select here"
    }
}

struct TVMatchPuzzle: View {
    let pairs: [ChronicleMatchPair]
    @Binding var state: ChronicleMatchState
    let helped: Bool
    let hintLevel: Int
    let onChange: () -> Void
    let onHelp: () -> Void
    let onRescue: () -> Void
    @FocusState private var focus: String?

    private var tiles: [ChronicleMatchTile] { ChronicleMatchEngine.tiles(for: pairs) }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 32) {
                tileColumn(tiles.filter { $0.side == .left })
                tileColumn(Array(tiles.filter { $0.side == .right }.reversed()))
            }
            Text(feedback).font(.system(size: 26)).foregroundStyle(GBColor.Content.primary)
                .accessibilityIdentifier("tv-puzzle-feedback")
            if state.completedPairIDs.count < pairs.count {
                HStack(spacing: 24) {
                    Button("Show a clue", action: onHelp).buttonStyle(TVCardButtonStyle())
                        .accessibilityIdentifier("tv-puzzle-help")
                    if hintLevel > 0 {
                        Button("Place a pair with help", action: onRescue).buttonStyle(TVCardButtonStyle())
                            .accessibilityIdentifier("tv-puzzle-rescue")
                    }
                }
            }
        }
        .onAppear {
            if let selected = state.selectedTileID, let tile = tiles.first(where: { $0.id == selected }) {
                focus = tiles.first(where: { $0.side != tile.side && !state.completedPairIDs.contains($0.pairID) })?.id
            } else { focus = tiles.first(where: { $0.side == .left && !state.completedPairIDs.contains($0.pairID) })?.id }
        }
    }

    private var feedback: String {
        switch state.lastOutcome {
        case .selected(let tile): "Find the partner for \(tile.text)."
        case .matched(_, let feedback, _): feedback
        case .mismatched(let clue): "Let's look again. " + clue
        case .ignored, nil: "Choose one card on the left, then its partner on the right."
        }
    }

    private func tileColumn(_ column: [ChronicleMatchTile]) -> some View {
        VStack(spacing: 20) {
            ForEach(column) { tile in
                let isMatched = state.completedPairIDs.contains(tile.pairID)
                Button {
                    state = ChronicleMatchEngine.select(tileID: tile.id, state: state, pairs: pairs)
                    onChange()
                    if state.selectedTileID != nil {
                        focus = tiles.first(where: { $0.side != tile.side && !state.completedPairIDs.contains($0.pairID) })?.id
                    } else { focus = tiles.first(where: { $0.side == .left && !state.completedPairIDs.contains($0.pairID) })?.id }
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: isMatched ? "checkmark.circle.fill" : (state.selectedTileID == tile.id ? "hand.point.up.left.fill" : "square.dashed"))
                        Text(tile.text).font(.system(size: 28, weight: .semibold))
                        Spacer(minLength: 0)
                    }.frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                }
                .buttonStyle(TVCardButtonStyle())
                .disabled(isMatched)
                .focused($focus, equals: tile.id)
                .accessibilityIdentifier("tv-puzzle-" + tile.side.rawValue + "-" + tile.pairID)
                .accessibilityValue(isMatched ? "Matched" : (state.selectedTileID == tile.id ? "Selected" : "Available"))
            }
        }.frame(maxWidth: .infinity)
    }
}
