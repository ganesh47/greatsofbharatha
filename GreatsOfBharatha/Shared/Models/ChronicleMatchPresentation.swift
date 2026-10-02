import Foundation

enum ChronicleMatchPresentationKind: Equatable {
    case placesAndMemoryClues
    case peopleAndPlaces
    case fortsAndMemoryClues
    case storyAndMeaning
}

/// Panel language and display labels do not change canonical answer or evidence identities.
struct ChronicleMatchPresentation: Equatable {
    let kind: ChronicleMatchPresentationKind
    private let tiles: [ChronicleMatchTile]

    init(pairs: [ChronicleMatchPair], kind: ChronicleMatchPresentationKind? = nil) {
        self.kind = kind ?? (pairs.allSatisfy { $0.kind == .placeToHook } ? .placesAndMemoryClues : .storyAndMeaning)
        self.tiles = ChronicleMatchEngine.tiles(for: pairs)
    }

    var leftTitle: String {
        switch kind {
        case .placesAndMemoryClues: "Places"
        case .peopleAndPlaces: "People and places"
        case .fortsAndMemoryClues: "Forts"
        case .storyAndMeaning: "Story cards"
        }
    }

    var rightTitle: String {
        switch kind {
        case .placesAndMemoryClues, .fortsAndMemoryClues: "Memory clues"
        case .peopleAndPlaces: "Story clues"
        case .storyAndMeaning: "What they mean"
        }
    }

    var leftInstruction: String {
        switch kind {
        case .placesAndMemoryClues: "Choose a place."
        case .peopleAndPlaces: "Choose a person or place."
        case .fortsAndMemoryClues: "Choose a fort."
        case .storyAndMeaning: "Choose a story card."
        }
    }

    var rightInstruction: String {
        switch kind {
        case .placesAndMemoryClues, .fortsAndMemoryClues: "Choose a memory clue."
        case .peopleAndPlaces: "Choose a story clue."
        case .storyAndMeaning: "Choose what it means."
        }
    }

    var instruction: String {
        "Choose a card from either panel. Then choose its partner in the other panel."
    }

    func feedback(for state: ChronicleMatchState) -> String {
        switch state.lastOutcome {
        case .selected(let tile):
            selectedFeedback(for: tile)
        case .matched(_, let feedback, _):
            feedback
        case .mismatched(let clue):
            "Let's look again. " + clue
        case .ignored, nil:
            if let source = tiles.first(where: { $0.id == state.selectedTileID && !state.completedPairIDs.contains($0.pairID) }) {
                selectedFeedback(for: source)
            } else {
                instruction
            }
        }
    }

    private func selectedFeedback(for tile: ChronicleMatchTile) -> String {
        "Chosen: \(displayText(for: tile)). Find its partner in the other panel."
    }

    func displayText(for tile: ChronicleMatchTile) -> String {
        guard tile.side == .left else { return tile.text }
        switch tile.pairID {
        case "match-rajgad-early-capital":
            return "Rajgad · early fort building"
        case "match-rajgad-comeback":
            return "Rajgad · after Agra"
        default:
            return tile.text
        }
    }
}
