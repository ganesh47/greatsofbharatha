import SwiftUI

struct LearnQuizHeroArt: View {
    let art: LearnQuizArt
    let title: String
    var height: CGFloat = 184

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                .fill(GBColor.gradient(for: art.emphasis))
                .overlay {
                    Image(systemName: art.symbol)
                        .font(.system(size: 76, weight: .bold))
                        .foregroundStyle(.white.opacity(0.30))
                        .offset(x: 92, y: -26)
                }

            VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                Image(systemName: art.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(GBFont.display(size: 27, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(GBSpacing.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) illustration placeholder, asset slot \(art.assetSlot)")
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
                }

                Button(action: { onCTA?() }) {
                    Label(ctaTitle, systemImage: "questionmark.bubble.fill")
                }
                .buttonStyle(.gbPrimary(scene.art.emphasis))
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
                    .lineLimit(1)
                Text(scene.memoryHook)
                    .font(GBFont.ui(size: 13, weight: .semibold))
                    .foregroundStyle(GBColor.Content.secondary)
                    .lineLimit(1)
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
