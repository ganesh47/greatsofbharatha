import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBRecallPrompt.swift — Greats of Bharatha Design System
// Multiple-choice recall component, no-shame feedback model
// ─────────────────────────────────────────────────────────────

struct GBRecallOption: Identifiable {
    let id: String
    let label: String
    let isCorrect: Bool
}

enum GBRecallState: Equatable {
    case idle
    case answered(selectedId: String)
}

struct GBRecallPrompt: View {
    let question: String
    let options:  [GBRecallOption]
    var onCorrect: (() -> Void)?
    var onRetry:   (() -> Void)?

    @State private var recallState: GBRecallState = .idle
    @State private var showHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            // Question card
            VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                Text("Quick Recall")
                    .font(GBFont.ui(size: 10, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.3)
                    .foregroundStyle(GBColor.Chronicle.royalMid)

                Text(question)
                    .font(GBFont.story(size: 19))
                    .foregroundStyle(GBColor.Content.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(GBSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .fill(GBColor.Background.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                            .stroke(GBColor.Border.default, lineWidth: 1)
                    )
            )

            ForEach(options) { option in
                RecallOptionButton(
                    option: option,
                    state: recallState,
                    onTap: { handleAnswer(option) }
                )
            }

            // Warm feedback on wrong answer (no shame)
            if case .answered(let id) = recallState,
               let selected = options.first(where: { $0.id == id }),
               !selected.isCorrect {
                WarmFeedbackCard(correctAnswer: options.first(where: { $0.isCorrect })?.label ?? "")
            }
        }
    }

    private func handleAnswer(_ option: GBRecallOption) {
        guard recallState == .idle else { return }
        withAnimation(GBMotion.quick) {
            recallState = .answered(selectedId: option.id)
        }
        if option.isCorrect {
            GBHaptic.pinCorrect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                onCorrect?()
            }
        }
        // Deliberately NO haptic for wrong answer — no shame signal
    }
}

// ── Option button ─────────────────────────────────────────────
private struct RecallOptionButton: View {
    let option: GBRecallOption
    let state: GBRecallState
    let onTap: () -> Void

    private var isSelected: Bool {
        if case .answered(let id) = state { return id == option.id }
        return false
    }
    private var isCorrect:  Bool { option.isCorrect && isSelected }
    private var isWrong:    Bool { !option.isCorrect && isSelected }
    private var isAnswered: Bool { if case .answered = state { return true }; return false }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GBSpacing.xSmall) {
                ZStack {
                    Circle().fill(iconBackground).frame(width: 28, height: 28)
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(iconForeground)
                }

                Text(option.label)
                    .font(GBFont.ui(size: 16, weight: .bold))
                    .foregroundStyle(labelColor)

                Spacer()
            }
            .padding(.horizontal, GBSpacing.small)
            .padding(.vertical, GBSpacing.xSmall)
            .frame(maxWidth: .infinity, minHeight: GBTouch.button)
            .background(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GBRadius.card, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
        .animation(GBMotion.quick, value: isSelected)
    }

    private var iconName: String {
        isCorrect ? "checkmark" : isWrong ? "xmark" : "circle"
    }
    private var iconBackground: Color {
        isCorrect ? GBColor.Place.primary : isWrong ? GBColor.State.danger : GBColor.Background.panel
    }
    private var iconForeground: Color {
        isCorrect || isWrong ? GBColor.Content.inverse : GBColor.Content.tertiary
    }
    private var labelColor: Color {
        isCorrect ? GBColor.Place.primary : isWrong ? GBColor.State.danger : GBColor.Content.primary
    }
    private var cardBackground: Color {
        isCorrect ? GBColor.Place.bg : isWrong ? Color(red: 0.99, green: 0.91, blue: 0.91) : GBColor.Background.surface
    }
    private var borderColor: Color {
        isCorrect ? GBColor.Place.primary : isWrong ? GBColor.State.danger : GBColor.Background.panel
    }
}

// ── Warm feedback (no shame) ──────────────────────────────────
private struct WarmFeedbackCard: View {
    let correctAnswer: String

    var body: some View {
        HStack(spacing: GBSpacing.xSmall) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(GBColor.Story.primary)
                .font(.system(size: 16))
            Text("\(correctAnswer) is the right answer — try to hold it in your memory.")
                .font(GBFont.ui(size: 14, weight: .semibold))
                .foregroundStyle(GBColor.Story.primary)
                .lineSpacing(2)
        }
        .padding(GBSpacing.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                .fill(GBColor.Story.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: GBRadius.compact, style: .continuous)
                        .stroke(GBColor.Story.light, lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

#Preview("Recall Prompt") {
    GBLayoutContextReader { _ in
        GBRecallPrompt(
            question: "At which fort was Shivaji Maharaj born?",
            options: [
                GBRecallOption(id: "a", label: "Shivneri Fort",  isCorrect: true),
                GBRecallOption(id: "b", label: "Raigad Fort",    isCorrect: false),
                GBRecallOption(id: "c", label: "Torna Fort",     isCorrect: false),
            ]
        )
        .padding()
    }
    .background(GBColor.Background.app)
}
