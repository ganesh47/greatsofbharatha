import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBTypography.swift — Greats of Bharatha Design System
// Version: 2.0 · April 2026
//
// Three-voice system:
//   Display (Cinzel)      — majestic arc/scene titles
//   Story   (Crimson Pro) — narrative body text
//   UI      (Nunito)      — labels, buttons, metadata
//
// Custom fonts must be bundled in the app target:
//   Cinzel-Regular.ttf, Cinzel-SemiBold.ttf, Cinzel-Bold.ttf
//   CrimsonPro-Regular.ttf, CrimsonPro-Italic.ttf, CrimsonPro-SemiBold.ttf
//   Nunito-Regular.ttf … Nunito-Black.ttf (full weight range)
//
// All fonts: SIL Open Font License — distributable
// Source: fonts.google.com
//
// Fallback: .system(.rounded) until fonts are bundled.
// ─────────────────────────────────────────────────────────────

enum GBFont {
    static func display(size: CGFloat = 28, weight: Font.Weight = .bold) -> Font {
        Font.custom("Cinzel", size: size).weight(weight)
    }
    static func story(size: CGFloat = 17, italic: Bool = false) -> Font {
        italic
            ? Font.custom("CrimsonPro-Italic", size: size)
            : Font.custom("CrimsonPro-Regular", size: size)
    }
    static func ui(size: CGFloat = 15, weight: Font.Weight = .semibold) -> Font {
        Font.custom("Nunito", size: size).weight(weight)
    }
}

enum GBTypography {

    // ── Display — Cinzel, majestic ───────────────────────────
    /// Arc / hero screen title (e.g. "Your Journey Begins")
    @discardableResult
    static func display(_ text: Text) -> some View {
        text
            .font(GBFont.display(size: 32, weight: .bold))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .tracking(-0.4)
            .lineSpacing(2)
    }

    /// Scene / section heading (e.g. "Shivneri Fort")
    @discardableResult
    static func title(_ text: Text) -> some View {
        text
            .font(GBFont.display(size: 22, weight: .semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    // ── Story — Crimson Pro, literary ────────────────────────
    /// Primary narrative body copy
    @discardableResult
    static func storyBody(_ text: Text) -> some View {
        text
            .font(GBFont.story(size: 18))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .lineSpacing(5)
    }

    /// Italic narrative / quote variant
    @discardableResult
    static func storyQuote(_ text: Text) -> some View {
        text
            .font(GBFont.story(size: 17, italic: true))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .lineSpacing(4)
    }

    // ── UI — Nunito, friendly ─────────────────────────────────
    /// Primary CTA / button label
    @discardableResult
    static func headline(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 17, weight: .heavy))
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Card title, fort name, scene label
    @discardableResult
    static func body(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 15, weight: .semibold))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// Eyebrow / metadata label (uppercase + tracked)
    @discardableResult
    static func caption(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 11, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.5)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Mastery / badge micro label
    @discardableResult
    static func micro(_ text: Text) -> some View {
        text
            .font(GBFont.ui(size: 10, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1.3)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
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
