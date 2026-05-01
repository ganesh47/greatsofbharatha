import SwiftUI

struct FlashcardReviewView: View {
    let cards: [LearnQuizReviewCard]

    @State private var currentIndex = 0
    @State private var isShowingBack = false
    @State private var reviewResult: LearningReviewSchedulingResult?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentCard: LearnQuizReviewCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    header

                    if let card = currentCard {
                        flipCard(card)
                        responseButtons(for: card)
                        resultCard
                    } else {
                        emptyState
                    }
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Flash Cards")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var header: some View {
        GBSurface(style: .accented(.chronicle)) {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                HStack {
                    GBBadge(title: "Review", symbol: "rectangle.on.rectangle.angled", emphasis: .chronicle, inverted: true)
                    Spacer()
                    if !cards.isEmpty {
                        Text("\(currentIndex + 1)/\(cards.count)")
                            .font(GBFont.ui(size: 13, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }

                Text("Flip the card, then choose what your memory needed.")
                    .font(GBFont.display(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func flipCard(_ card: LearnQuizReviewCard) -> some View {
        Button {
            flip()
        } label: {
            ZStack {
                reviewFace(
                    badge: card.sceneTitle,
                    title: card.front,
                    body: promptCopy(for: card),
                    symbol: card.art.symbol,
                    emphasis: card.art.emphasis,
                    isBack: false
                )
                .opacity(isShowingBack ? 0 : 1)
                .rotation3DEffect(.degrees(isShowingBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                reviewFace(
                    badge: "Answer",
                    title: card.back,
                    body: card.meaning,
                    symbol: "checkmark.seal.fill",
                    emphasis: .chronicle,
                    isBack: true
                )
                .opacity(isShowingBack ? 1 : 0)
                .rotation3DEffect(.degrees(isShowingBack ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .animation(reduceMotion ? nil : GBMotion.standard, value: isShowingBack)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isShowingBack ? "Showing answer: \(card.back). \(card.meaning)" : "Showing prompt: \(card.front). Tap to flip.")
    }

    private func reviewFace(
        badge: String,
        title: String,
        body: String,
        symbol: String,
        emphasis: GBEmphasis,
        isBack: Bool
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                .fill(GBColor.gradient(for: emphasis))
                .overlay(
                    RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                        .fill(Color.black.opacity(isBack ? 0.32 : 0.40))
                )

            Image(systemName: symbol)
                .font(.system(size: 76, weight: .bold))
                .foregroundStyle(.white.opacity(0.22))
                .padding(GBSpacing.medium)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                GBBadge(title: badge, symbol: isBack ? "sparkles" : "questionmark.circle.fill", emphasis: emphasis, inverted: true)

                Spacer(minLength: GBSpacing.medium)

                Text(title)
                    .font(GBFont.display(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(body)
                    .font(GBFont.story(size: 20))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: GBSpacing.medium)

                Label(isBack ? "Tap to see the clue side" : "Tap to flip", systemImage: "arrow.triangle.2.circlepath")
                    .font(GBFont.ui(size: 14, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(GBSpacing.medium)
        }
        .frame(minHeight: 360)
        .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
        .gbShadow(.card)
    }

    private func responseButtons(for card: LearnQuizReviewCard) -> some View {
        VStack(spacing: GBSpacing.xSmall) {
            Button {
                record(.knewIt, for: card)
            } label: {
                Label("I knew it", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.gbPrimary(.chronicle))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: GBSpacing.xSmall)], spacing: GBSpacing.xSmall) {
                Button {
                    record(.neededClue, for: card)
                } label: {
                    Label("Needed a clue", systemImage: "lightbulb.fill")
                }
                .buttonStyle(.gbSecondary)

                Button {
                    record(.teachAgain, for: card)
                } label: {
                    Label("Teach me again", systemImage: "heart.text.square.fill")
                }
                .buttonStyle(.gbSecondary)
            }
        }
    }

    @ViewBuilder
    private var resultCard: some View {
        if let reviewResult {
            GBSurface(style: .elevated) {
                VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                    Label(resultTitle(for: reviewResult), systemImage: "calendar.badge.clock")
                        .font(GBFont.ui(size: 16, weight: .heavy))
                        .foregroundStyle(GBColor.Content.primary)
                    Text(resultDetail(for: reviewResult))
                        .font(GBFont.ui(size: 14, weight: .semibold))
                        .foregroundStyle(GBColor.Content.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if cards.indices.contains(currentIndex + 1) {
                        Button {
                            nextCard()
                        } label: {
                            Label("Next flash card", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(.gbPrimary(.story))
                        .padding(.top, GBSpacing.xxSmall)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GBSurface(style: .elevated) {
            Text("No review cards are ready for this path yet.")
                .font(GBFont.ui(size: 16, weight: .bold))
                .foregroundStyle(GBColor.Content.secondary)
        }
    }

    private func promptCopy(for card: LearnQuizReviewCard) -> String {
        switch card.promptType {
        case .openPrompt:
            return "What place or idea does this memory hook point to?"
        case .eventToPlaceMatch:
            return "Which places belong with this pair?"
        case .mapPlacement:
            return "Where would this memory sit on the map?"
        case .sequenceSlot:
            return "Where does this fit in the journey?"
        case .compareFromMemory:
            return "Which fort or idea matches this clue?"
        }
    }

    private func record(_ response: LearningReviewResponse, for card: LearnQuizReviewCard) {
        let now = Date()
        let schedule = SpacedReviewScheduler.makeInitialSchedule(from: card.learningSeed, now: now)
        reviewResult = SpacedReviewScheduler.schedule(
            schedule,
            after: response,
            promptHistory: [card.promptType],
            now: now
        )
        isShowingBack = true
        GBHaptic.chronicleReveal()
    }

    private func flip() {
        isShowingBack.toggle()
        GBHaptic.stepAdvance()
    }

    private func nextCard() {
        currentIndex += 1
        isShowingBack = false
        reviewResult = nil
        GBHaptic.stepAdvance()
    }

    private func resultTitle(for result: LearningReviewSchedulingResult) -> String {
        result.shouldReviewInCurrentSession ? "We will teach it again now" : "Review saved"
    }

    private func resultDetail(for result: LearningReviewSchedulingResult) -> String {
        if result.shouldReviewInCurrentSession {
            return "This card stays warm because it needed more teaching."
        }

        switch result.schedule.stabilityBand {
        case .new:
            return "This card comes back soon."
        case .warming:
            return "This card comes back after a short wait."
        case .steady:
            return "This memory is getting steady."
        case .durable:
            return "This memory is becoming durable."
        }
    }
}

#Preview("Flashcard Review") {
    NavigationStack {
        FlashcardReviewView(cards: LearnQuizPilotData.reviewCards)
    }
}
