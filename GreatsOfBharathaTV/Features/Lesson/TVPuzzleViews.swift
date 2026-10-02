import SwiftUI
import UIKit

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
    let presentation: ChronicleMatchPresentation
    @Binding var state: ChronicleMatchState
    let helped: Bool
    let hintLevel: Int
    let onChange: () -> Void
    let onHelp: () -> Void
    let onRescue: () -> Void
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: String?
    @State private var celebrationPairID: String?
    @State private var celebrationProgress: CGFloat = 0
    @State private var celebrationVisible = false

    private var tiles: [ChronicleMatchTile] { ChronicleMatchEngine.tiles(for: pairs) }
    private var canAnimate: Bool { !reduceMotion && !appModel.parentSettings.calmTransitionsEnabled }
    private var complete: Bool { state.completedPairIDs.count == pairs.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                TVFireflyCharacter(glowing: false).scaleEffect(0.30).frame(width: 30, height: 30)
                Text("Choose a card, then its partner. Let's make a story link.")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
            }
            .padding(8).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("tv-match-guide")

            HStack(alignment: .top, spacing: 16) {
                tilePanel(side: .left)
                RoundedRectangle(cornerRadius: 2).fill(TVTheme.gold.opacity(0.30))
                    .frame(width: 2).padding(.vertical, 18)
                    .accessibilityHidden(true)
                tilePanel(side: .right)
            }
            .overlayPreferenceValue(TVMatchCardBoundsKey.self, connectionOverlay)

            Text(feedback).font(.system(size: 24)).foregroundStyle(GBColor.Content.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 30, alignment: .topLeading)
                .accessibilityIdentifier("tv-puzzle-feedback")
            if complete {
                Text("Our story links: " + completedLinks.joined(separator: "   •   "))
                    .font(.system(size: 23, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(TVTheme.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Our story links. " + completedLinks.joined(separator: ". "))
                    .accessibilityIdentifier("tv-match-recap")
            } else {
                HStack(spacing: 24) {
                    Button("Show a clue") { onHelp(); announceFeedback() }.buttonStyle(TVCardButtonStyle())
                        .accessibilityIdentifier("tv-puzzle-help")
                    if hintLevel > 0 {
                        Button("Place a pair with help") { onRescue(); announceFeedback() }.buttonStyle(TVCardButtonStyle())
                            .accessibilityIdentifier("tv-puzzle-rescue")
                    }
                }
            }
        }
        .task {
            await Task.yield()
            if UIAccessibility.isVoiceOverRunning { narrator.stop() }
            guard !complete else { return }
            restoreFocus()
        }
        .onChange(of: state.lastOutcome) { _, outcome in
            if case .ignored = outcome, state.selectedTileID == nil, !complete { focus = firstAvailable(on: .left)?.id }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            if UIAccessibility.isVoiceOverRunning { narrator.stop() }
        }
        .onChange(of: state.completedPairIDs) { old, new in
            guard canAnimate, let pairID = new.subtracting(old).sorted().first else { return }
            celebrationPairID = pairID
        }
        .onChange(of: canAnimate) { _, enabled in
            if !enabled {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    celebrationPairID = nil
                    celebrationVisible = false
                    celebrationProgress = 1
                }
            }
        }
        .task(id: celebrationPairID) {
            guard celebrationPairID != nil, canAnimate else { return }
            celebrationProgress = 0
            celebrationVisible = true
            await Task.yield()
            withAnimation(.easeInOut(duration: 0.4)) { celebrationProgress = 1 }
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.15)) { celebrationVisible = false }
        }
    }

    private var feedback: String {
        presentation.feedback(for: state)
    }

    private var completedLinks: [String] {
        pairs.filter { state.completedPairIDs.contains($0.id) }.map { pair in
            let left = tiles.first(where: { $0.pairID == pair.id && $0.side == .left })
            return (left.map(presentation.displayText(for:)) ?? pair.leftText) + " — " + pair.rightText
        }
    }

    private func visibleTiles(on side: ChronicleMatchTileSide) -> [ChronicleMatchTile] {
        let column = tiles.filter { $0.side == side }
        return side == .right ? Array(column.reversed()) : column
    }

    private func firstAvailable(on side: ChronicleMatchTileSide) -> ChronicleMatchTile? {
        visibleTiles(on: side).first { !state.completedPairIDs.contains($0.pairID) }
    }

    private func restoreFocus() {
        let selected = tiles.first(where: { $0.id == state.selectedTileID })
        focus = firstAvailable(on: selected?.side == .left ? .right : .left)?.id
    }

    private func select(_ tile: ChronicleMatchTile) {
        state = ChronicleMatchEngine.select(tileID: tile.id, state: state, pairs: pairs)
        onChange()
        switch state.lastOutcome {
        case .selected(let source): focus = firstAvailable(on: source.side == .left ? .right : .left)?.id
        case .matched:
            if !complete { focus = firstAvailable(on: .left)?.id }
        case .mismatched, .ignored, nil: break // A rejected partner keeps the person's actual focus and their chosen source.
        }
        if case .ignored = state.lastOutcome { return }
        announceFeedback()
    }

    private func announceFeedback() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        narrator.stop()
        UIAccessibility.post(notification: .announcement, argument: feedback)
    }

    private func tilePanel(side: ChronicleMatchTileSide) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(side == .left ? presentation.leftTitle : presentation.rightTitle)
                    .font(.system(size: 24, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("tv-match-" + side.rawValue + "-title")
                Text(side == .left ? presentation.leftInstruction : presentation.rightInstruction)
                    .font(.system(size: 23)).foregroundStyle(TVTheme.paper.opacity(0.85))
            }
            ForEach(visibleTiles(on: side)) { tile in
                let isMatched = state.completedPairIDs.contains(tile.pairID)
                let isChosen = state.selectedTileID == tile.id
                Button { select(tile) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isMatched ? "checkmark.circle.fill" : (isChosen ? "hand.point.up.left.fill" : "square.dashed"))
                            .font(.system(size: 23)).accessibilityHidden(true)
                        Text(presentation.displayText(for: tile)).font(.system(size: 29, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Text(isMatched ? "Linked" : (isChosen ? "Chosen" : ""))
                            .font(.system(size: 23, weight: .bold))
                            .frame(width: 90)
                            .accessibilityHidden(true)
                    }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                }
                .buttonStyle(TVMatchCardButtonStyle(chosen: isChosen, matched: isMatched))
                .disabled(isMatched)
                .focused($focus, equals: tile.id)
                .anchorPreference(key: TVMatchCardBoundsKey.self, value: .bounds) { [tile.id: $0] }
                .accessibilityLabel(presentation.displayText(for: tile))
                .accessibilityIdentifier("tv-puzzle-" + tile.side.rawValue + "-" + tile.pairID)
                .accessibilityValue(isMatched ? "Matched" : (state.selectedTileID == tile.id ? "Selected" : "Available"))
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(side == .left ? .white.opacity(0.045) : TVTheme.gold.opacity(0.055), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15), lineWidth: 1))
        .focusSection()
    }

    private func connectionOverlay(_ bounds: [String: Anchor<CGRect>]) -> some View {
        GeometryReader { geometry in
            if let pair = pairs.first(where: { $0.id == celebrationPairID }),
               let left = bounds[pair.leftID], let right = bounds[pair.rightID], celebrationVisible {
                let leftFrame = geometry[left]
                let rightFrame = geometry[right]
                let start = CGPoint(x: leftFrame.maxX + 4, y: leftFrame.midY)
                let end = CGPoint(x: rightFrame.minX - 4, y: rightFrame.midY)
                let middleX = (start.x + end.x) / 2
                let progress = celebrationProgress
                let easedY = progress * progress * (3 - 2 * progress)
                let point = CGPoint(x: start.x + (end.x - start.x) * progress,
                                    y: start.y + (end.y - start.y) * easedY)
                Path { path in
                    path.move(to: start)
                    path.addCurve(to: end, control1: CGPoint(x: middleX, y: start.y), control2: CGPoint(x: middleX, y: end.y))
                }
                .trim(from: 0, to: progress).stroke(TVTheme.gold.opacity(0.65), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                TVFireflyCharacter(glowing: true).scaleEffect(0.30).frame(width: 30, height: 30).position(point)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct TVMatchCardBoundsKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}
