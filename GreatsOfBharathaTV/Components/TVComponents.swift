import SwiftUI
import UIKit

enum TVTheme {
    static let ink = Color(red: 0.09, green: 0.12, blue: 0.14)
    static let paper = Color(red: 0.99, green: 0.95, blue: 0.85)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.35)
    static let panel = Color(red: 0.14, green: 0.20, blue: 0.21)
    static let background = LinearGradient(colors: [ink, Color(red: 0.06, green: 0.16, blue: 0.14)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct TVCardButtonStyle: ButtonStyle {
    var emphasis: GBEmphasis = .story
    func makeBody(configuration: Configuration) -> some View {
        TVCardButtonBody(configuration: configuration)
    }
}

private struct TVCardButtonBody: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.isFocused) private var focused
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .font(.system(size: 29, weight: .semibold, design: .rounded))
            .padding(.horizontal, 26).padding(.vertical, 18)
            .frame(minHeight: 76)
            .foregroundStyle(focused ? TVTheme.ink : TVTheme.paper)
            .background(focused ? TVTheme.paper : TVTheme.panel, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(focused ? TVTheme.gold : .white.opacity(0.16), lineWidth: focused ? 5 : 1))
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.42)
            .scaleEffect(focused && !reduceMotion && !appModel.parentSettings.calmTransitionsEnabled ? 1.025 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: focused)
    }
}

struct TVScreen<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            TVTheme.background.ignoresSafeArea()
            content.padding(.horizontal, 72).padding(.vertical, 44)
        }
        .foregroundStyle(TVTheme.paper)
    }
}

struct TVFireflyGuide: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false
    let message: String

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle().fill(TVTheme.gold.opacity(glowing ? 0.22 : 0.08)).frame(width: 94, height: 94)
                Ellipse().fill(.white.opacity(0.75)).frame(width: 38, height: 22).rotationEffect(.degrees(-30)).offset(x: -23, y: -5)
                Ellipse().fill(.white.opacity(0.75)).frame(width: 38, height: 22).rotationEffect(.degrees(30)).offset(x: 23, y: -5)
                Capsule().fill(TVTheme.gold).frame(width: 40, height: 64)
                HStack(spacing: 9) {
                    Circle().fill(TVTheme.ink).frame(width: 5, height: 7)
                    Circle().fill(TVTheme.ink).frame(width: 5, height: 7)
                }.offset(y: -14)
                Capsule().fill(TVTheme.ink).frame(width: 12, height: 3).offset(y: -1)
            }.accessibilityHidden(true)
            Text(message).font(.system(size: 29, design: .rounded)).fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .task(id: reduceMotion || appModel.parentSettings.calmTransitionsEnabled) {
            glowing = false
            if !reduceMotion && !appModel.parentSettings.calmTransitionsEnabled {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { glowing = true }
            }
        }
    }
}

struct TVNarrationControls: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    let id: String
    let text: String

    var body: some View {
        if appModel.parentSettings.narrationEnabled {
            HStack(spacing: 20) {
                Button { narrator.speak(id: id, text: text) } label: {
                    Label("Listen again", systemImage: "speaker.wave.2.fill")
                }.accessibilityIdentifier("tv-listen-" + id)
                if narrator.activeCardID != nil {
                    Button { narrator.togglePlayback() } label: {
                        Label(narrator.isPaused ? "Keep listening" : "Pause", systemImage: narrator.isPaused ? "play.fill" : "pause.fill")
                    }.accessibilityIdentifier("tv-narration-pause")
                }
            }.buttonStyle(TVCardButtonStyle())
            .onAppear { narrator.setCurrent(id: id, text: text) }
            .onChange(of: id) { _, _ in narrator.setCurrent(id: id, text: text) }
            .onChange(of: text) { _, _ in narrator.setCurrent(id: id, text: text) }
            .onChange(of: appModel.parentSettings.narrationEnabled) { _, enabled in if !enabled { narrator.stop() } }
            if let status = narrator.statusMessage { Text(status).font(.system(size: 23)).accessibilityIdentifier("tv-narration-status") }
        }
    }
}

struct TVChapterArt: View {
    let scene: StoryScene
    var body: some View {
        let plan = SampleContent.learningPlan(for: scene)
        Group {
            if let asset = plan.imageAsset {
                Image(asset).resizable().scaledToFill()
            } else {
                ZStack { GBColor.gradient(for: .story); Image(systemName: plan.artSymbol).font(.system(size: 96)) }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
