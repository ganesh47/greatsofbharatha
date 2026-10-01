import SwiftUI

struct LearnQuizHeroArt: View {
    let art: LearnQuizArt
    let title: String
    var height: CGFloat = 184

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Image(art.assetSlot).resizable().scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero)).accessibilityHidden(true)
            Text(title).gbTitle()
            Text("Story illustration").font(.caption).foregroundStyle(GBColor.Content.secondary)
        }
    }

}

struct LearnQuizMetadataChip: View {
    let label: String
    let value: String
    var emphasis: GBEmphasis = .story

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(GBFont.ui(size: 10, weight: .heavy))
                .textCase(.uppercase)
                .foregroundStyle(GBColor.Content.tertiary)
            Text(value)
                .font(GBFont.ui(size: 13, weight: .bold))
                .foregroundStyle(GBColor.accent(for: emphasis))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, GBSpacing.xSmall)
        .padding(.vertical, GBSpacing.xxSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                .stroke(GBColor.Border.default, lineWidth: 1)
        )
    }
}

struct SceneLearnCard: View {
    let scene: LearnQuizPilotScene
    var ctaTitle: String = "Quiz me"
    var onCTA: (() -> Void)?

    private var glossaryTerms: [GBGlossaryTerm] {
        GBGlossaryTerm.matching([
            scene.title,
            scene.story,
            scene.meaning,
            scene.place,
            scene.memoryHook,
        ].joined(separator: " "))
    }

    var body: some View {
        GBSurface(style: .plain, padding: GBSpacing.small) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                LearnQuizHeroArt(art: scene.art, title: scene.title)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GBSpacing.xxSmall) {
                    LearnQuizMetadataChip(label: "Time", value: scene.timeMarker, emphasis: .story)
                    LearnQuizMetadataChip(label: "Place", value: scene.place, emphasis: .place)
                    LearnQuizMetadataChip(label: "Action", value: scene.actionVerb, emphasis: .chronicle)
                    LearnQuizMetadataChip(label: "Hook", value: scene.memoryHook, emphasis: .story)
                }

                VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                    Text(scene.subtitle)
                        .font(GBFont.ui(size: 13, weight: .heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(GBColor.Content.tertiary)
                    Text(scene.story)
                        .font(GBFont.story(size: 18))
                        .foregroundStyle(GBColor.Content.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(scene.meaning)
                        .font(GBFont.ui(size: 15, weight: .semibold))
                        .foregroundStyle(GBColor.Content.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    GBGlossaryTray(terms: glossaryTerms)
                }

                Button(action: { onCTA?() }) {
                    Label(ctaTitle, systemImage: "questionmark.bubble.fill")
                }
                .buttonStyle(.gbPrimary(scene.art.emphasis))
                .accessibilityIdentifier("pilot-quiz-me")
            }
        }
    }
}

struct LearnQuizSceneRow: View {
    let scene: LearnQuizPilotScene

    var body: some View {
        HStack(spacing: GBSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                    .fill(GBColor.gradient(for: scene.art.emphasis))
                Text("\(scene.number)")
                    .font(GBFont.display(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(scene.title)
                    .font(GBFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(GBColor.Content.primary)
                Text(scene.memoryHook)
                    .font(GBFont.ui(size: 13, weight: .semibold))
                    .foregroundStyle(GBColor.Content.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(GBColor.Content.tertiary)
        }
        .padding(GBSpacing.small)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                .stroke(GBColor.Border.default, lineWidth: 1)
        )
    }
}
