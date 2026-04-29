import AVFoundation
import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBFlashCard.swift — Greats of Bharatha Design System
// Full-screen swipeable story cards for young learners.
// Read-aloud narration built-in via GBNarrator.
// ─────────────────────────────────────────────────────────────

struct GBFlashCardData: Identifiable, Sendable {
    let id: String
    let iconName: String
    let title: String
    let storyBeat: String
    var emphasis: GBEmphasis = .story
    var narrationText: String? = nil
}

// ── Read-aloud controller ─────────────────────────────────────
@MainActor
final class GBNarrator: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var activeCardID: String? = nil
    private var lastRequest: (id: String, text: String)?

    func toggle(cardID: String, text: String) {
        if activeCardID == cardID, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            activeCardID = nil
            return
        }
        speak(id: cardID, text: text)
    }

    func speak(id: String, text: String) {
        lastRequest = (id: id, text: text)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        // Slightly slower rate so young children can follow
        utterance.rate = AVSpeechUtteranceMinimumSpeechRate
            + (AVSpeechUtteranceDefaultSpeechRate - AVSpeechUtteranceMinimumSpeechRate) * 0.30
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        activeCardID = id
    }

    func repeatLast() {
        guard let lastRequest else { return }
        speak(id: lastRequest.id, text: lastRequest.text)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        activeCardID = nil
    }
}

// ── Single flashcard ──────────────────────────────────────────
struct GBFlashCard: View {
    let card: GBFlashCardData
    @EnvironmentObject private var narrator: GBNarrator

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                .fill(GBColor.gradient(for: card.emphasis))
                .overlay(
                    RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous)
                        .fill(Color.black.opacity(0.42))
                )

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: card.iconName)
                    .font(.system(size: 88, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.bottom, GBSpacing.large)
                    .accessibilityHidden(true)

                Text(card.title)
                    .font(GBFont.display(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, GBSpacing.large)

                Text(card.storyBeat)
                    .font(GBFont.story(size: 20, italic: true))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, GBSpacing.large)
                    .padding(.top, GBSpacing.small)

                Spacer()
                Spacer()
            }

            // Read-aloud button — top-right
            let isActive = narrator.activeCardID == card.id
            Button {
                narrator.toggle(
                    cardID: card.id,
                    text: card.narrationText ?? "\(card.title). \(card.storyBeat)"
                )
            } label: {
                Image(systemName: isActive ? "speaker.wave.3.fill" : "speaker.wave.1")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: GBTouch.button, height: GBTouch.button)
                    .background(.white.opacity(0.16), in: Circle())
            }
            .padding(GBSpacing.small)
            .accessibilityLabel(isActive ? "Stop reading aloud" : "Read aloud")
        }
        .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
        .gbShadow(.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.title). \(card.storyBeat)")
    }
}

// ── Deck: swipeable carousel ──────────────────────────────────
struct GBFlashCardDeck: View {
    let cards: [GBFlashCardData]
    var emphasis: GBEmphasis = .story
    var onComplete: (() -> Void)?

    @StateObject private var narrator = GBNarrator()
    @State private var currentIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: GBSpacing.medium) {
            // Card carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    GBFlashCard(card: card)
                        .padding(.horizontal, GBSpacing.medium)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
            .onChange(of: currentIndex) { _, _ in
                GBHaptic.stepAdvance()
                narrator.stop()
            }

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<cards.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx == currentIndex
                              ? GBColor.accent(for: emphasis)
                              : GBColor.Content.tertiary)
                        .frame(width: idx == currentIndex ? 24 : 7, height: 7)
                        .animation(GBMotion.quick, value: currentIndex)
                }
            }

            // CTA
            if currentIndex == cards.count - 1 {
                Button("Continue") {
                    narrator.stop()
                    GBHaptic.stepAdvance()
                    onComplete?()
                }
                .buttonStyle(.gbPrimary(emphasis: emphasis))
                .padding(.horizontal, GBSpacing.medium)
            } else if reduceMotion {
                Button {
                    withAnimation(GBMotion.standard) { currentIndex += 1 }
                    GBHaptic.stepAdvance()
                } label: {
                    Label("Next card", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.gbPrimary(emphasis: emphasis))
                .padding(.horizontal, GBSpacing.medium)
            } else {
                Label("Swipe to turn the card", systemImage: "hand.draw")
                    .font(GBFont.ui(size: 13, weight: .bold))
                    .foregroundStyle(GBColor.Content.secondary)
            }
        }
        .padding(.bottom, GBSpacing.medium)
        .environmentObject(narrator)
    }
}

#Preview("Flash Card Deck") {
    ZStack {
        GBColor.Background.app.ignoresSafeArea()
        GBFlashCardDeck(
            cards: [
                GBFlashCardData(
                    id: "c1", iconName: "building.columns.fill",
                    title: "Shivneri Fort",
                    storyBeat: "High in the Sahyadri hills, a brave prince was born.",
                    emphasis: .story
                ),
                GBFlashCardData(
                    id: "c2", iconName: "mountain.2.fill",
                    title: "The Fort Trail",
                    storyBeat: "Young Shivaji climbed these paths and dreamed of freedom.",
                    emphasis: .story
                ),
                GBFlashCardData(
                    id: "c3", iconName: "crown.fill",
                    title: "Swarajya Begins",
                    storyBeat: "With courage, Shivaji started building his own kingdom.",
                    emphasis: .story
                )
            ],
            emphasis: .story
        ) {}
    }
}
