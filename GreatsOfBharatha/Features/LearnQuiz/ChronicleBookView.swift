import SwiftUI

struct ChronicleBookView: View {
    let scenes: [LearnQuizPilotScene]

    private var entries: [LearnQuizChronicleEntry] {
        scenes.map(\.chronicleEntry) + [LearnQuizPilotData.journeyEntry]
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    cover
                    entriesSection
                    journeyStrip
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Chronicle Book")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var cover: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                Text("Shivaji Chronicle")
                    .font(GBFont.display(size: 31, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("A growing book of remembered places, actions, and meanings.")
                    .font(GBFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(
                eyebrow: "Reward states",
                title: "Cards deepen with memory proof",
                subtitle: "A card starts faint, then gains ink, a seal, and a remembered-again mark."
            )

            ForEach(entries) { entry in
                ChronicleBookEntryCard(entry: entry)
            }
        }
    }

    private var journeyStrip: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBBadge(title: "Journey so far", symbol: "map.fill", emphasis: .place)
                HStack(alignment: .top, spacing: GBSpacing.xxSmall) {
                    ForEach(scenes) { scene in
                        VStack(spacing: GBSpacing.xxSmall) {
                            ZStack {
                                Circle()
                                    .fill(GBColor.gradient(for: scene.art.emphasis))
                                Text("\(scene.number)")
                                    .font(GBFont.ui(size: 14, weight: .black))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 40, height: 40)
                            Text(scene.memoryHook)
                                .font(GBFont.ui(size: 11, weight: .heavy))
                                .foregroundStyle(GBColor.Content.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

private struct ChronicleBookEntryCard: View {
    let entry: LearnQuizChronicleEntry

    @ViewBuilder
    var body: some View {
        if entry.state == .rememberedAgain {
            GBSurface(style: .accented(.chronicle)) {
                content
            }
        } else {
            GBSurface(style: .plain) {
                content
            }
            .opacity(entry.state == .silhouette ? 0.72 : 1.0)
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: GBSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                    .fill(iconBackground)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(iconForeground)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                Text(stateTitle)
                    .font(GBFont.ui(size: 11, weight: .heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(labelColor)
                Text(entry.title)
                    .font(GBFont.display(size: 20, weight: .bold))
                    .foregroundStyle(primaryTextColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(entry.subtitle)
                    .font(GBFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(secondaryTextColor)
                Text(entry.meaning)
                    .font(GBFont.ui(size: 14, weight: .semibold))
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var icon: String {
        switch entry.state {
        case .silhouette: return "eye.slash.fill"
        case .inked: return "paintbrush.pointed.fill"
        case .sealed: return "seal.fill"
        case .rememberedAgain: return "checkmark.seal.fill"
        }
    }

    private var stateTitle: String {
        switch entry.state {
        case .silhouette: return "Silhouette"
        case .inked: return "Inked"
        case .sealed: return "Sealed"
        case .rememberedAgain: return "Remembered again"
        }
    }

    private var iconBackground: Color {
        entry.state == .silhouette ? GBColor.State.lockedBg : GBColor.Chronicle.goldBg
    }

    private var iconForeground: Color {
        entry.state == .silhouette ? GBColor.State.locked : GBColor.Chronicle.gold
    }

    private var labelColor: Color {
        entry.state == .rememberedAgain ? .white.opacity(0.75) : GBColor.Content.tertiary
    }

    private var primaryTextColor: Color {
        entry.state == .rememberedAgain ? .white : GBColor.Content.primary
    }

    private var secondaryTextColor: Color {
        entry.state == .rememberedAgain ? .white.opacity(0.88) : GBColor.Content.secondary
    }
}

#Preview("Chronicle Book") {
    NavigationStack {
        ChronicleBookView(scenes: LearnQuizPilotData.scenes)
    }
}
