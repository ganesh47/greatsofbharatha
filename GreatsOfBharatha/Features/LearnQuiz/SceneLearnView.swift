import SwiftUI

struct SceneLearnView: View {
    let scene: LearnQuizPilotScene

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    SceneLearnCard(scene: scene, ctaTitle: "Quiz me")

                    HStack(spacing: GBSpacing.xSmall) {
                        NavigationLink {
                            ChronicleQuizView(scene: scene)
                        } label: {
                            Label("Quiz", systemImage: "questionmark.bubble.fill")
                        }
                        .buttonStyle(.gbPrimary(.story))

                        NavigationLink {
                            ChronicleMatchView(scenes: LearnQuizPilotData.scenes)
                        } label: {
                            Label("Match", systemImage: "square.grid.2x2.fill")
                        }
                        .buttonStyle(.gbSecondary)
                    }

                    NavigationLink {
                        ChronicleBookView(scenes: LearnQuizPilotData.scenes)
                    } label: {
                        GBSurface(style: .elevated) {
                            HStack(spacing: GBSpacing.small) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(GBColor.Chronicle.gold)
                                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                                    Text("Chronicle reward shell")
                                        .font(GBFont.ui(size: 16, weight: .bold))
                                        .foregroundStyle(GBColor.Content.primary)
                                    Text(scene.chronicleEntry.title)
                                        .font(GBFont.ui(size: 14, weight: .semibold))
                                        .foregroundStyle(GBColor.Content.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(GBColor.Content.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle(scene.memoryHook)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview("Scene Learn Cards") {
    NavigationStack {
        SceneLearnView(scene: LearnQuizPilotData.scenes[0])
    }
}
