import SwiftUI

// Semantic system fonts scale through the full Dynamic Type range.
// Serif story/headings and rounded controls retain the three voices without
// referring to font files that are not bundled with this application.

enum GBFont {
    static func display(size: CGFloat = 28, weight: Font.Weight = .bold) -> Font {
        Font.system(size >= 30 ? .largeTitle : (size >= 22 ? .title2 : (size >= 17 ? .headline : .subheadline)), design: .serif).weight(weight)
    }
    static func story(size: CGFloat = 17, italic: Bool = false) -> Font {
        italic ? Font.system(.body, design: .serif).italic() : Font.system(.body, design: .serif)
    }
    static func ui(size: CGFloat = 15, weight: Font.Weight = .semibold) -> Font {
        Font.system(size >= 17 ? .headline : (size >= 14 ? .body : (size >= 11 ? .caption : .caption2)), design: .rounded).weight(weight)
    }
}

enum GBTypography {

    // ── Display — Cinzel, majestic ───────────────────────────
    /// Arc / hero screen title (e.g. "Your Journey Begins")
    @discardableResult
    static func display(_ text: Text) -> some View {
        text
            .font(GBFont.display(size: 32, weight: .bold))
            .tracking(-0.4)
            .lineSpacing(2)
    }

    /// Scene / section heading (e.g. "Shivneri Fort")
    @discardableResult
    static func title(_ text: Text) -> some View {
        text
            .font(GBFont.display(size: 22, weight: .semibold))
    }

    // ── Story — Crimson Pro, literary ────────────────────────
    /// Primary narrative body copy
    @discardableResult
    static func storyBody(_ text: Text) -> some View {
        text
            .font(GBFont.story(size: 18))
            .lineSpacing(5)
    }

    /// Italic narrative / quote variant
    @discardableResult
    static func storyQuote(_ text: Text) -> some View {
        text
            .font(GBFont.story(size: 17, italic: true))
            .lineSpacing(4)
    }

    // ── UI — Nunito, friendly ─────────────────────────────────
    /// Primary CTA / button label
    @discardableResult
    static func headline(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 17, weight: .heavy))
    }

    /// Card title, fort name, scene label
    @discardableResult
    static func body(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 15, weight: .semibold))
    }

    /// Eyebrow / metadata label (uppercase + tracked)
    @discardableResult
    static func caption(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 11, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.5)
    }

    /// Mastery / badge micro label
    @discardableResult
    static func micro(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 10, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.3)
    }
}

// ── View extensions ──────────────────────────────────────────
extension Text {
    func gbDisplay() -> some View  { GBTypography.display(self) }
    func gbTitle() -> some View    { GBTypography.title(self) }
    func gbStory() -> some View    { GBTypography.storyBody(self) }
    func gbQuote() -> some View    { GBTypography.storyQuote(self) }
    func gbHeadline() -> some View { GBTypography.headline(self) }
    func gbBody() -> some View     { GBTypography.body(self) }
    func gbCaption() -> some View  { GBTypography.caption(self) }
    func gbMicro() -> some View    { GBTypography.micro(self) }
}
