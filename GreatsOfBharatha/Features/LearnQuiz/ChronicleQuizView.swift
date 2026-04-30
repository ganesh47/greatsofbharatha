import SwiftUI

struct ChronicleQuizView: View {
    let scene: LearnQuizPilotScene

    @State private var selectedAnswer: String?
    @State private var hintIndex = 0

    private var isCorrect: Bool {
        selectedAnswer == scene.quiz.correctAnswer
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    promptCard
                    answerGrid
                    hintCard
                    feedbackCard
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Quick Quiz")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var promptCard: some View {
        GBSurface(style: .accented(.story)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                GBBadge(title: scene.memoryHook, symbol: "lightbulb.fill", emphasis: .story)
                Text(scene.quiz.question)
                    .font(GBFont.display(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Try from memory first. Hints are here when you want a clue.")
                    .font(GBFont.ui(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var answerGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GBSpacing.xSmall) {
            ForEach(scene.quiz.options, id: \.self) { option in
                Button {
                    selectedAnswer = option
                } label: {
                    HStack {
                        Text(option)
                            .font(GBFont.ui(size: 16, weight: .heavy))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Image(systemName: selectedAnswer == option ? selectedIcon(for: option) : "circle")
                    }
                    .padding(GBSpacing.small)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                    .background(answerBackground(for: option), in: RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                            .stroke(answerBorder(for: option), lineWidth: selectedAnswer == option ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(GBColor.Content.primary)
            }
        }
    }

    private var hintCard: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: "Hint ladder", symbol: "sparkle.magnifyingglass", emphasis: .chronicle)
                    Spacer()
                    Text("\(min(hintIndex + 1, scene.quiz.hintLadder.count))/\(scene.quiz.hintLadder.count)")
                        .font(GBFont.ui(size: 12, weight: .heavy))
                        .foregroundStyle(GBColor.Content.tertiary)
                }

                Text(scene.quiz.hintLadder[hintIndex])
                    .font(GBFont.ui(size: 17, weight: .bold))
                    .foregroundStyle(GBColor.Content.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    hintIndex = min(hintIndex + 1, scene.quiz.hintLadder.count - 1)
                } label: {
                    Label("Show next clue", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.gbSecondary)
                .disabled(hintIndex >= scene.quiz.hintLadder.count - 1)
            }
        }
    }

    @ViewBuilder
    private var feedbackCard: some View {
        if let selectedAnswer {
            GBSurface(style: isCorrect ? .accented(.chronicle) : .elevated) {
                VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                    Label(isCorrect ? "Remembered" : "Try with this clue", systemImage: isCorrect ? "checkmark.seal.fill" : "heart.text.square.fill")
                        .font(GBFont.ui(size: 17, weight: .heavy))
                        .foregroundStyle(isCorrect ? .white : GBColor.Content.primary)
                    Text(isCorrect ? "\(selectedAnswer) is right." : scene.quiz.teachingFeedback)
                        .font(GBFont.story(size: 18))
                        .foregroundStyle(isCorrect ? .white.opacity(0.92) : GBColor.Content.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func selectedIcon(for option: String) -> String {
        option == scene.quiz.correctAnswer ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill"
    }

    private func answerBackground(for option: String) -> Color {
        guard selectedAnswer == option else { return GBColor.Background.surface }
        return option == scene.quiz.correctAnswer ? GBColor.Chronicle.goldBg : GBColor.Story.bg
    }

    private func answerBorder(for option: String) -> Color {
        guard selectedAnswer == option else { return GBColor.Border.default }
        return option == scene.quiz.correctAnswer ? GBColor.Chronicle.gold : GBColor.Story.primary
    }
}

#Preview("Chronicle Quiz") {
    NavigationStack {
        ChronicleQuizView(scene: LearnQuizPilotData.scenes[0])
    }
}
