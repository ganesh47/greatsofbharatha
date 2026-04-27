import SwiftUI

// ─────────────────────────────────────────────────────────────
// LessonHomeView.swift — kid-friendly scene list.
// Simplified to: hero welcome + star progress + big scene cards.
// Removed: stat pills, metadata chips, ChronicleJourneyCard.
// ─────────────────────────────────────────────────────────────

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    welcomeHero
                    progressStarRow
                    sceneGrid(context: context)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Greats of Bharatha")
    }

    // MARK: - Welcome hero

    private var welcomeHero: some View {
        GBSurface(style: .accented(.story)) {
            HStack(spacing: GBSpacing.medium) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.85))

                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    Text("Shivaji Maharaj")
                        .font(GBFont.ui(size: 11, weight: .heavy))
                        .textCase(.uppercase)
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.78))

                    Text(appModel.lessonStore.completedScenes == 0
                         ? "Begin the adventure!"
                         : "Welcome back!")
                        .font(GBFont.display(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Pick a story card and start exploring the forts.")
                        .font(GBFont.story(size: 14))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(3)
                }
            }
        }
    }

    // MARK: - Progress star row

    private var progressStarRow: some View {
        let completed = appModel.lessonStore.completedScenes
        let total     = appModel.lessonStore.totalScenes

        return VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
            HStack {
                Text("Your adventure")
                    .font(GBFont.ui(size: 11, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.3)
                    .foregroundStyle(GBColor.Content.tertiary)
                Spacer()
                Text("\(completed) of \(total) scenes")
                    .font(GBFont.ui(size: 13, weight: .bold))
                    .foregroundStyle(GBColor.Content.secondary)
            }

            // Stars row
            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { idx in
                    Image(systemName: idx < completed ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundStyle(idx < completed ? GBColor.Chronicle.gold : GBColor.Content.tertiary)
                        .animation(GBMotion.bounce.delay(Double(idx) * 0.06), value: completed)
                }
            }
        }
        .padding(GBSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                .fill(GBColor.Background.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                        .stroke(GBColor.Border.default, lineWidth: 1)
                )
        )
    }

    // MARK: - Scene grid

    private func sceneGrid(context: GBLayoutContext) -> some View {
        VStack(alignment: .leading, spacing: context.cardSpacing) {
            Text("Choose a scene")
                .font(GBFont.ui(size: 11, weight: .heavy))
                .textCase(.uppercase)
                .tracking(1.3)
                .foregroundStyle(GBColor.Content.tertiary)

            ForEach(appModel.content.scenes) { scene in
                let mastery    = appModel.lessonStore.mastery(for: scene.id)
                let isNext     = scene.id == appModel.lessonStore.nextSceneID
                let isLocked   = mastery == nil && !isNext

                Group {
                    if isLocked {
                        kidSceneCard(scene: scene, mastery: mastery, isNext: false, isLocked: true)
                    } else {
                        NavigationLink {
                            SceneLessonView(scene: scene)
                        } label: {
                            kidSceneCard(scene: scene, mastery: mastery, isNext: isNext, isLocked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func kidSceneCard(
        scene: StoryScene,
        mastery: MasteryState?,
        isNext: Bool,
        isLocked: Bool
    ) -> some View {
        HStack(spacing: GBSpacing.medium) {
            // Scene number badge
            ZStack {
                RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                    .fill(isLocked
                          ? AnyShapeStyle(GBColor.State.lockedBg)
                          : AnyShapeStyle(GBColor.gradient(for: .story)))
                Text("\(scene.number)")
                    .font(GBFont.display(size: 17, weight: .bold))
                    .foregroundStyle(isLocked ? GBColor.State.locked : .white)
            }
            .frame(width: 52, height: 52)

            // Title
            Text(scene.title)
                .font(GBFont.ui(size: 16, weight: .bold))
                .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Content.primary)
                .lineLimit(2)

            Spacer()

            // Status icon
            if isLocked {
                Image(systemName: GBIcon.locked)
                    .foregroundStyle(GBColor.State.locked)
                    .font(.system(size: 18))
            } else if mastery != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(GBColor.Place.primary)
                    .font(.system(size: 22))
            } else if isNext {
                Image(systemName: "play.fill")
                    .foregroundStyle(GBColor.Story.primary)
                    .font(.system(size: 20))
            }
        }
        .padding(GBSpacing.small)
        .frame(minHeight: GBTouch.button)
        .background(
            RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                .fill(isNext ? GBColor.Background.elevated : GBColor.Background.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                        .stroke(
                            isNext ? GBColor.Story.light : GBColor.Border.default,
                            lineWidth: isNext ? 2 : 1
                        )
                )
        )
        .gbShadow(isNext ? .story : .card)
        .accessibilityLabel(accessibilityLabel(scene: scene, mastery: mastery, isNext: isNext, isLocked: isLocked))
    }

    private func accessibilityLabel(
        scene: StoryScene,
        mastery: MasteryState?,
        isNext: Bool,
        isLocked: Bool
    ) -> String {
        if isLocked { return "Scene \(scene.number): \(scene.title). Locked." }
        if mastery != nil { return "Scene \(scene.number): \(scene.title). Completed." }
        if isNext { return "Scene \(scene.number): \(scene.title). Start now!" }
        return "Scene \(scene.number): \(scene.title)"
    }
}
