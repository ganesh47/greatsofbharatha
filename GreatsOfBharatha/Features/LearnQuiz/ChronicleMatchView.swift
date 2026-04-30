import SwiftUI

struct ChronicleMatchView: View {
    let scenes: [LearnQuizPilotScene]

    @State private var matchState = ChronicleMatchState()

    private var pairs: [ChronicleMatchPair] {
        scenes.flatMap(\.matchPairs)
    }

    private var leftTiles: [ChronicleMatchTile] {
        ChronicleMatchEngine.tiles(for: pairs).filter { $0.side == .left }
    }

    private var rightTiles: [ChronicleMatchTile] {
        Array(ChronicleMatchEngine.tiles(for: pairs).filter { $0.side == .right }.reversed())
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    header
                    matchGrid
                    clueCard
                    completionCard
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Chronicle Match")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var header: some View {
        GBHeroCard(
            eyebrow: "Match pairs",
            title: "Put each place with its memory hook",
            subtitle: "\(matchState.completedPairIDs.count) of \(pairs.count) matched",
            detail: "Tap a card on the left, then find the card on the right that belongs with it.",
            ctaTitle: "Keep matching",
            badgeTitle: "\(pairs.count) pilot pairs",
            emphasis: .place,
            progress: pairs.isEmpty ? nil : Double(matchState.completedPairIDs.count) / Double(pairs.count)
        )
    }

    private var matchGrid: some View {
        HStack(alignment: .top, spacing: GBSpacing.xSmall) {
            VStack(spacing: GBSpacing.xSmall) {
                ForEach(leftTiles) { tile in
                    matchTile(tile: tile, alignment: .leading)
                }
            }

            VStack(spacing: GBSpacing.xSmall) {
                ForEach(rightTiles) { tile in
                    matchTile(tile: tile, alignment: .trailing)
                }
            }
        }
    }

    private func matchTile(tile: ChronicleMatchTile, alignment: HorizontalAlignment) -> some View {
        let isSelected = matchState.selectedTileID == tile.id
        let isMatched = matchState.completedPairIDs.contains(tile.pairID)

        return Button {
            matchState = ChronicleMatchEngine.select(tileID: tile.id, state: matchState, pairs: pairs)
        } label: {
            HStack {
                if alignment == .trailing { Spacer(minLength: GBSpacing.xxSmall) }
                Text(tile.text)
                    .font(GBFont.ui(size: 15, weight: .heavy))
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if alignment == .leading { Spacer(minLength: GBSpacing.xxSmall) }
            }
            .padding(GBSpacing.xSmall)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(tileBackground(isSelected: isSelected, isMatched: isMatched), in: RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .stroke(tileBorder(isSelected: isSelected, isMatched: isMatched), lineWidth: isSelected || isMatched ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isMatched ? GBColor.Place.primary : GBColor.Content.primary)
        .accessibilityLabel("\(tile.text), \(isMatched ? "matched" : "not matched")")
    }

    @ViewBuilder
    private var clueCard: some View {
        switch matchState.lastOutcome {
        case .selected(let tile):
            GBSurface(style: .elevated) {
                Label("Now tap the matching card for \(tile.text).", systemImage: "hand.tap.fill")
                    .font(GBFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(GBColor.Content.primary)
            }
        case .mismatched(let clue):
            GBSurface(style: .elevated) {
                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    Label("Try another pair", systemImage: "arrow.counterclockwise.circle.fill")
                        .font(GBFont.ui(size: 16, weight: .heavy))
                        .foregroundStyle(GBColor.Story.primary)
                    Text(clue)
                        .font(GBFont.ui(size: 15, weight: .semibold))
                        .foregroundStyle(GBColor.Content.secondary)
                }
            }
        case .matched(_, let feedback, let completedSet):
            GBSurface(style: completedSet ? .accented(.chronicle) : .elevated) {
                Label(feedback, systemImage: "checkmark.circle.fill")
                    .font(GBFont.ui(size: 16, weight: .heavy))
                    .foregroundStyle(completedSet ? .white : GBColor.Content.primary)
            }
        case .ignored, nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private var completionCard: some View {
        if matchState.completedPairIDs.count == pairs.count {
            GBSurface(style: .accented(.chronicle)) {
                Label("All pairs matched. A Chronicle seal is ready.", systemImage: "checkmark.seal.fill")
                    .font(GBFont.ui(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
    }

    private func tileBackground(isSelected: Bool, isMatched: Bool) -> Color {
        if isMatched { return GBColor.Place.bg }
        if isSelected { return GBColor.Chronicle.goldBg }
        return GBColor.Background.surface
    }

    private func tileBorder(isSelected: Bool, isMatched: Bool) -> Color {
        if isMatched { return GBColor.Place.primary }
        if isSelected { return GBColor.Chronicle.gold }
        return GBColor.Border.default
    }
}

#Preview("Chronicle Match") {
    NavigationStack {
        ChronicleMatchView(scenes: LearnQuizPilotData.scenes)
    }
}
