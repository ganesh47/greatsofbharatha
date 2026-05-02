import SwiftUI

// ─────────────────────────────────────────────────────────────
// LessonHomeView.swift — kid-first chapter entry.
// One dominant Chapter 1 story stage, then quieter progress and
// lower-priority future scenes for grown-up browsing.
// ─────────────────────────────────────────────────────────────

struct LessonHomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var narrator = GBNarrator()

    private var firstScene: StoryScene? { appModel.content.scenes.first }
    private var nextSceneID: String? { appModel.lessonStore.nextSceneID }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    if let firstScene {
                        chapterOneStage(scene: firstScene)
                    }
                    progressStarRow
                    tuckedSceneList(context: context)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Story Time")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .onDisappear { narrator.stop() }
    }

    // MARK: - Chapter 1 stage

    private func chapterOneStage(scene: StoryScene) -> some View {
        let isCompleted = (appModel.lessonStore.mastery(for: scene.id) ?? .witnessed) >= .understood
        let narration = "Chapter 1. Shivneri Fort. At Shivneri Fort, young Shivaji began his journey. Jijabai helped him grow brave, caring, and ready to lead. Tap Start Chapter 1."

        return VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Image("Chapter1ShivneriStory")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 238)
                .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("Chapter 1")
                        .font(GBFont.ui(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, GBSpacing.small)
                        .padding(.vertical, GBSpacing.xxSmall)
                        .background(.black.opacity(0.24), in: Capsule())
                        .padding(GBSpacing.small)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                Text("Chapter 1")
                    .font(GBFont.ui(size: 13, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.78))

                Text("Shivneri, where the story begins")
                    .font(GBFont.display(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Meet young Shivaji and Jijabai at a warm hill fort. We will listen, look, and answer one easy question.")
                    .font(GBFont.story(size: 18))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            narrationRow(text: narration)

            NavigationLink {
                SceneLessonView(scene: scene)
            } label: {
                Label(isCompleted ? "Play Chapter 1 Again" : "Start Chapter 1", systemImage: "play.fill")
                    .frame(maxWidth: .infinity, minHeight: GBTouch.button)
            }
            .buttonStyle(.gbPrimary(.chronicle))
            .accessibilityLabel(isCompleted ? "Play Chapter 1 again" : "Start Chapter 1")
            .accessibilityHint("Opens one story card with read aloud and one next button.")
        }
        .padding(GBSpacing.medium)
        .background(GBColor.gradient(for: .story), in: RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
        .gbShadow(.story)
        .accessibilityElement(children: .contain)
    }

    private func narrationRow(text: String) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
            HStack(spacing: GBSpacing.xSmall) {
                narrationButton(title: "Listen", icon: "speaker.wave.2.fill") {
                    narrator.speak(id: "home-chapter-1", text: text)
                }
                narrationButton(title: "Repeat", icon: "arrow.clockwise") {
                    narrator.repeatLast()
                }
                narrationButton(title: "Stop", icon: "stop.fill") {
                    narrator.stop()
                }
            }
            .accessibilityElement(children: .contain)

            if let statusMessage = narrator.statusMessage {
                Text(statusMessage)
                    .font(GBFont.ui(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(statusMessage)
            }
        }
    }

    private func narrationButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(GBFont.ui(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(.white.opacity(0.22))
        .foregroundStyle(.white)
        .accessibilityHint(title == "Stop" ? "Stops read aloud." : "Reads the Chapter 1 card aloud.")
    }

    // MARK: - Progress star row

    private var progressStarRow: some View {
        let completed = appModel.lessonStore.completedScenes
        let total = appModel.lessonStore.totalScenes

        return VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
            HStack {
                Text("My story stars")
                    .font(GBFont.ui(size: 12, weight: .heavy))
                    .foregroundStyle(GBColor.Content.secondary)
                Spacer()
                Text("\(completed) of \(total)")
                    .font(GBFont.ui(size: 14, weight: .bold))
                    .foregroundStyle(GBColor.Content.secondary)
            }

            HStack(spacing: 7) {
                ForEach(0..<total, id: \.self) { idx in
                    Image(systemName: idx < completed ? "star.fill" : "star")
                        .font(.system(size: 22))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("My story stars, \(completed) of \(total) scenes complete")
    }

    // MARK: - Tucked lower-priority scenes

    private func tuckedSceneList(context: GBLayoutContext) -> some View {
        VStack(alignment: .leading, spacing: context.cardSpacing) {
            Text("More chapters")
                .font(GBFont.ui(size: 12, weight: .heavy))
                .foregroundStyle(GBColor.Content.tertiary)

            ForEach(appModel.content.scenes.dropFirst()) { scene in
                let mastery = appModel.lessonStore.mastery(for: scene.id)
                let isNext = scene.id == nextSceneID
                let isLocked = mastery == nil && !isNext

                Group {
                    if isLocked {
                        tuckedSceneCard(scene: scene, mastery: mastery, isNext: false, isLocked: true)
                    } else {
                        NavigationLink {
                            SceneLessonView(scene: scene)
                        } label: {
                            tuckedSceneCard(scene: scene, mastery: mastery, isNext: isNext, isLocked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, GBSpacing.xSmall)
    }

    private func tuckedSceneCard(
        scene: StoryScene,
        mastery: MasteryState?,
        isNext: Bool,
        isLocked: Bool
    ) -> some View {
        HStack(spacing: GBSpacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                    .fill(isLocked ? GBColor.State.lockedBg : GBColor.Story.bg)
                Text("\(scene.number)")
                    .font(GBFont.display(size: 16, weight: .bold))
                    .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Story.primary)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(scene.title)
                    .font(GBFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(isLocked ? GBColor.State.locked : GBColor.Content.primary)
                    .lineLimit(2)
                Text(isLocked ? "Unlock after the next chapter" : isNext ? "Next when you are ready" : "Ready to revisit")
                    .font(GBFont.ui(size: 13, weight: .semibold))
                    .foregroundStyle(GBColor.Content.secondary)
            }

            Spacer()

            Image(systemName: statusIcon(mastery: mastery, isNext: isNext, isLocked: isLocked))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isLocked ? GBColor.State.locked : isNext ? GBColor.Story.primary : GBColor.Place.primary)
        }
        .padding(GBSpacing.small)
        .frame(minHeight: GBTouch.button)
        .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                .stroke(isNext ? GBColor.Story.light : GBColor.Border.default, lineWidth: isNext ? 2 : 1)
        )
        .accessibilityLabel(accessibilityLabel(scene: scene, mastery: mastery, isNext: isNext, isLocked: isLocked))
    }

    private func statusIcon(mastery: MasteryState?, isNext: Bool, isLocked: Bool) -> String {
        if isLocked { return GBIcon.locked }
        if mastery != nil { return "checkmark.circle.fill" }
        if isNext { return "play.fill" }
        return "book.fill"
    }

    private func accessibilityLabel(
        scene: StoryScene,
        mastery: MasteryState?,
        isNext: Bool,
        isLocked: Bool
    ) -> String {
        if isLocked { return "Chapter \(scene.number): \(scene.title). Locked until earlier chapters are done." }
        if mastery != nil { return "Chapter \(scene.number): \(scene.title). Completed." }
        if isNext { return "Chapter \(scene.number): \(scene.title). Next chapter." }
        return "Chapter \(scene.number): \(scene.title)."
    }
}
