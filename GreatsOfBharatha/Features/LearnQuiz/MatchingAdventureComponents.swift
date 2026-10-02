import SwiftUI

/// The established adventure guide, kept small so the learning board leads.
struct MatchingFirefly: View {
    var celebrating: Bool

    var body: some View {
        ZStack {
            Circle().fill(GBColor.Chronicle.gold.opacity(0.14)).frame(width: 58, height: 58)
            Ellipse().fill(.white.opacity(0.8)).frame(width: 21, height: 31)
                .rotationEffect(.degrees(-30)).offset(x: -14, y: -3)
            Ellipse().fill(.white.opacity(0.8)).frame(width: 21, height: 31)
                .rotationEffect(.degrees(30)).offset(x: 14, y: -3)
            Capsule().fill(GBColor.Chronicle.goldLight).frame(width: 25, height: 40)
            HStack(spacing: 6) {
                Capsule().frame(width: 3, height: 5)
                Capsule().frame(width: 3, height: 5)
            }.foregroundStyle(Color(red: 0.15, green: 0.11, blue: 0.08)).offset(y: -6)
            Capsule().fill(Color(red: 0.15, green: 0.11, blue: 0.08))
                .frame(width: 8, height: 2).offset(y: 3)
            if celebrating {
                Image(systemName: "sparkles").font(.caption.weight(.bold))
                    .foregroundStyle(GBColor.Chronicle.gold).offset(x: 25, y: -23)
            }
        }
        .frame(width: 58, height: 58)
        .scaleEffect(celebrating ? 1.08 : 1)
        .accessibilityHidden(true)
    }
}

struct MatchingGuideFeedback: View {
    let message: String
    let celebrating: Bool
    let reduceMovement: Bool

    var body: some View {
        HStack(alignment: .top, spacing: GBSpacing.xSmall) {
            MatchingFirefly(celebrating: celebrating)
                .animation(reduceMovement ? nil : .easeOut(duration: 0.4), value: celebrating)
            Text(message)
                .font(GBFont.ui(size: 15, weight: .semibold))
                .foregroundStyle(GBColor.Content.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(GBSpacing.xSmall)
        .frame(minHeight: 112, alignment: .top)
        .background(GBColor.Background.elevated, in: RoundedRectangle(cornerRadius: GBRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("matching-feedback")
    }
}

struct MatchingReplayControls: View {
    @EnvironmentObject private var appModel: AppModel
    @ObservedObject private var narrator = GBNarrator.shared
    let text: String

    var body: some View {
        Group {
        if appModel.parentSettings.narrationEnabled {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: GBSpacing.small) { controls }
                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) { controls }
            }
            if let status = narrator.statusMessage {
                Text(status).gbBody()
            }
        } else {
            Text("Read-aloud is off in parent settings.")
                .font(GBFont.ui(size: 11)).foregroundStyle(GBColor.Content.secondary)
        }
        }
        .onDisappear { narrator.stop() }
        .onChange(of: appModel.parentSettings.narrationEnabled) { _, enabled in
            if !enabled { narrator.stop() }
        }
        .onChange(of: text) { _, _ in narrator.stop() }
    }

    @ViewBuilder private var controls: some View {
        Button { narrator.speak(id: "matching-instructions", text: text) } label: {
            Label("Listen", systemImage: "speaker.wave.2.fill")
                .frame(minHeight: GBTouch.button)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("listen-matching-instructions")
        Button { narrator.stop() } label: {
            Label("Stop", systemImage: "stop.fill").frame(minHeight: GBTouch.button)
        }
        .buttonStyle(.bordered)
        .disabled(narrator.activeCardID != "matching-instructions")
        .accessibilityIdentifier("stop-matching-instructions")
    }
}
