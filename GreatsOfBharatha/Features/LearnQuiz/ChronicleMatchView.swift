import SwiftUI

struct ChronicleMatchView: View {
    let scenes: [LearnQuizPilotScene]

    @State private var selectedLeftID: String?
    @State private var matchedIDs: Set<String> = []
    @State private var mismatchPair: LearnQuizMatchPair?

    private var pairs: [LearnQuizMatchPair] {
        scenes.flatMap(\.matchPairs)
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
            subtitle: "\(matchedIDs.count) of \(pairs.count) matched",
            detail: "Tap a card on the left, then find the card on the right that belongs with it.",
            ctaTitle: "Keep matching",
            badgeTitle: "6 pilot pairs",
            emphasis: .place,
            progress: pairs.isEmpty ? nil : Double(matchedIDs.count) / Double(pairs.count)
        )
    }

    private var matchGrid: some View {
        HStack(alignment: .top, spacing: GBSpacing.xSmall) {
            VStack(spacing: GBSpacing.xSmall) {
                ForEach(pairs) { pair in
                    matchTile(
                        id: pair.id,
                        text: pair.left,
                        isSelected: selectedLeftID == pair.id,
                        isMatched: matchedIDs.contains(pair.id),
                        alignment: .leading
                    ) {
                        guard !matchedIDs.contains(pair.id) else { return }
                        selectedLeftID = pair.id
                        mismatchPair = nil
                    }
                }
            }

            VStack(spacing: GBSpacing.xSmall) {
                ForEach(pairs.reversed()) { pair in
                    matchTile(
                        id: pair.id,
                        text: pair.right,
                        isSelected: false,
                        isMatched: matchedIDs.contains(pair.id),
                        alignment: .trailing
                    ) {
                        guard !matchedIDs.contains(pair.id), let selectedLeftID else { return }
                        if selectedLeftID == pair.id {
                            matchedIDs.insert(pair.id)
                            self.selectedLeftID = nil
                            mismatchPair = nil
                        } else {
                            mismatchPair = pair
                        }
                    }
                }
            }
        }
    }

    private func matchTile(
        id: String,
        text: String,
        isSelected: Bool,
        isMatched: Bool,
        alignment: HorizontalAlignment,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                if alignment == .trailing { Spacer(minLength: GBSpacing.xxSmall) }
                Text(text)
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
        .accessibilityLabel("\(text), \(isMatched ? "matched" : "not matched")")
    }

    @ViewBuilder
    private var clueCard: some View {
        if let selectedLeftID, let selected = pairs.first(where: { $0.id == selectedLeftID }) {
            GBSurface(style: .elevated) {
                Label("Now tap the matching card for \(selected.left).", systemImage: "hand.tap.fill")
                    .font(GBFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(GBColor.Content.primary)
            }
        } else if let mismatchPair {
            GBSurface(style: .elevated) {
                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    Label("Try another pair", systemImage: "arrow.counterclockwise.circle.fill")
                        .font(GBFont.ui(size: 16, weight: .heavy))
                        .foregroundStyle(GBColor.Story.primary)
                    Text(mismatchPair.clue)
                        .font(GBFont.ui(size: 15, weight: .semibold))
                        .foregroundStyle(GBColor.Content.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var completionCard: some View {
        if matchedIDs.count == pairs.count {
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
