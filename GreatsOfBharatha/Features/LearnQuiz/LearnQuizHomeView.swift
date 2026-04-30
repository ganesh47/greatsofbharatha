import SwiftUI

struct LearnQuizHomeView: View {
    private let scenes = LearnQuizPilotData.scenes

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    hero
                    continueCard
                    sceneList
                    reviewCard
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Learn & Quiz")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var hero: some View {
        GBHeroCard(
            eyebrow: "Shivaji pilot",
            title: "Learn, remember, build your Chronicle",
            subtitle: "Three short scenes: Shivneri, Torna + Rajgad, and Pratapgad.",
            detail: "Read a short story card, answer from memory, match the hook, and watch the Chronicle grow.",
            ctaTitle: "Start with Shivneri",
            badgeTitle: "First path",
            emphasis: .story,
            progress: 1.0 / 3.0
        )
    }

    private var continueCard: some View {
        NavigationLink {
            if let first = scenes.first {
                SceneLearnView(scene: first)
            }
        } label: {
            GBSurface(style: .accented(.story)) {
                HStack(spacing: GBSpacing.small) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                        Text("Continue")
                            .font(GBFont.ui(size: 13, weight: .heavy))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.78))
                        Text("Shivneri - Birth Fort")
                            .font(GBFont.display(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var sceneList: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(
                eyebrow: "Pilot scenes",
                title: "Remember the first path",
                subtitle: "One clear memory hook for each place in the opening journey."
            )

            ForEach(scenes) { scene in
                NavigationLink {
                    SceneLearnView(scene: scene)
                } label: {
                    LearnQuizSceneRow(scene: scene)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var reviewCard: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: "Due later", symbol: "rectangle.stack.fill", emphasis: .chronicle)
                    Spacer()
                    Text("1 review seed")
                        .font(GBFont.ui(size: 12, weight: .bold))
                        .foregroundStyle(GBColor.Content.secondary)
                }
                Text("Flashcard review slot")
                    .font(GBFont.display(size: 21, weight: .bold))
                    .foregroundStyle(GBColor.Content.primary)
                Text("A quick card will bring back the memory hook after the story has had time to settle.")
                    .font(GBFont.ui(size: 15, weight: .semibold))
                    .foregroundStyle(GBColor.Content.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Learn Quiz Home") {
    NavigationStack {
        LearnQuizHomeView()
    }
    .environmentObject(AppModel())
}
