import SwiftUI

struct GBQuestProgress: View {
    struct Step: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
    }

    let steps: [Step]
    let currentStepID: String

    @Environment(\.gbLayoutContext) private var layoutContext

    var body: some View {
        Group {
            if layoutContext.prefersHorizontalQuestProgress {
                compactRow
            } else {
                regularColumn
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var compactRow: some View {
        HStack(alignment: .top, spacing: GBSpacing.xxSmall) {
            ForEach(steps.indices, id: \.self) { index in
                let step = steps[index]

                HStack(spacing: GBSpacing.xxSmall) {
                    questStep(step)
                    if index < steps.index(before: steps.endIndex) {
                        Capsule()
                            .fill(connectorColor(for: step))
                            .frame(height: 4)
                    }
                }
            }
        }
    }

    private var regularColumn: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
            ForEach(steps.indices, id: \.self) { index in
                let step = steps[index]

                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    questStep(step)
                    if index < steps.index(before: steps.endIndex) {
                        Rectangle()
                            .fill(connectorColor(for: step))
                            .frame(width: 2, height: 18)
                            .padding(.leading, GBSpacing.small)
                    }
                }
            }
        }
    }

    private func questStep(_ step: Step) -> some View {
        let isCurrent = step.id == currentStepID

        return HStack(spacing: GBSpacing.xxSmall) {
            Image(systemName: step.symbol)
                .font(.subheadline.weight(.semibold))
            Text(step.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isCurrent ? GBColor.Content.primary : GBColor.Content.secondary)
        .padding(.horizontal, GBSpacing.xSmall)
        .padding(.vertical, GBSpacing.xxSmall)
        .frame(maxWidth: layoutContext.prefersHorizontalQuestProgress ? .infinity : nil, alignment: .leading)
        .background(stepBackground(isCurrent: isCurrent), in: Capsule())
        .overlay(
            Capsule()
                .stroke(isCurrent ? GBColor.accent(for: emphasis(for: step.id)).opacity(0.28) : GBColor.Border.default, lineWidth: 1)
        )
        .accessibilityLabel(accessibilityLabel(for: step, isCurrent: isCurrent))
    }

    private func stepBackground(isCurrent: Bool) -> Color {
        isCurrent ? GBColor.Background.elevated : GBColor.Background.surface.opacity(0.72)
    }

    private func connectorColor(for step: Step) -> Color {
        step.id == currentStepID ? GBColor.accent(for: emphasis(for: step.id)).opacity(0.35) : GBColor.Border.default
    }

    private func emphasis(for stepID: String) -> GBEmphasis {
        switch stepID {
        case "story":
            .story
        case "place":
            .place
        case "chronicle":
            .chronicle
        default:
            .neutral
        }
    }

    private func accessibilityLabel(for step: Step, isCurrent: Bool) -> String {
        isCurrent ? "\(step.title), current step" : step.title
    }
}
extension GBQuestProgress.Step {
    static let story = GBQuestProgress.Step(id: "story", title: "Story", symbol: GBIcon.story)
    static let place = GBQuestProgress.Step(id: "place", title: "Find Place", symbol: GBIcon.place)
    static let chronicle = GBQuestProgress.Step(id: "chronicle", title: "Chronicle", symbol: GBIcon.chronicle)
}

#Preview("Quest Progress") {
    GBLayoutContextReader { _ in
        GBQuestProgress(
            steps: [.story, .place, .chronicle],
            currentStepID: "place"
        )
        .padding()
    }
    .background(GBColor.Background.app)
}
