# Greats of Bharatha — Design System v1
**Version 1.0 · April 2026**

A complete, Apple-native design system for the Shivaji Maharaj arc and future Bharatha historical arcs.

---

## Quick start

```swift
// 1. Import tokens (all in DesignSystem/Tokens/)
import GBColor, GBTypography, GBSpacing, GBRadius, GBShadow, GBMotion, GBIcon

// 2. Use in views
Text("Shivneri Fort")
    .gbTitle()
    .foregroundStyle(GBColor.Story.primary)

// 3. Apply components
GBSceneCard(sceneNumber: 1, title: "Shivneri", subtitle: "...", status: .current)
GBChronicleCard(title: "Birth Fort", ..., mastery: .witnessed)
GBRecallPrompt(question: "Which fort?", options: [...], onCorrect: { ... })
```

---

## Font bundling (required)

Add these font files to the app target and register in Info.plist:

| Font | File | Use |
|---|---|---|
| Cinzel Regular | `Cinzel-Regular.ttf` | Display body |
| Cinzel SemiBold | `Cinzel-SemiBold.ttf` | Display labels |
| Cinzel Bold | `Cinzel-Bold.ttf` | Hero titles |
| Crimson Pro Regular | `CrimsonPro-Regular.ttf` | Story text |
| Crimson Pro Italic | `CrimsonPro-Italic.ttf` | Narrative quotes |
| Nunito Regular–Black | `Nunito-*.ttf` | All UI labels |

**All fonts: SIL Open Font License** — free to bundle.
Download: [fonts.google.com](https://fonts.google.com)

---

## Color palette

| Token | Hex | Role |
|---|---|---|
| `GBColor.Background.app` | `#F5EDD8` | App background (warm parchment) |
| `GBColor.Background.surface` | `#FDFAF2` | Card face |
| `GBColor.Story.primary` | `#D94F0C` | Saffron — story accent |
| `GBColor.Place.primary` | `#1F5C3A` | Sahyadri green — place accent |
| `GBColor.Chronicle.gold` | `#B87D0C` | Gold — reward accent |
| `GBColor.Chronicle.royal` | `#3D2475` | Royal indigo — ceremony |
| `GBColor.Content.primary` | `#1C1410` | Warm near-black text |
| `GBColor.State.locked` | `#A09080` | Locked/disabled state |

Full palette: see `DesignSystem/Tokens/GBColor.swift`

---

## Component inventory

| Component | File | Status |
|---|---|---|
| `GBHeroCard` | Components/ | ✅ Existing (update needed) |
| `GBSceneCard` | Components/ | 🆕 New |
| `GBQuestProgressView` | Components/ | 🆕 New |
| `GBStoryCard` | Components/ | 🔲 To build |
| `GBRecallPrompt` | Components/ | 🆕 New |
| `GBPlaceCard` | Components/ | 🔲 To build |
| `GBChronicleCard` | Components/ | 🆕 New |
| `GBRewardReveal` | Components/ | 🆕 New |
| `GBMasteryBadge` | Foundation/ | 🆕 New |
| `GBMapPinState` | Components/ | 🔲 To build |
| `GBBottomActionPanel` | Components/ | 🔲 To build |
| `GBTimelineMarker` | Components/ | 🔲 V1.1 |
| `GBBadge` | Foundation/ | ✅ Existing |
| `GBButtonStyle` | Foundation/ | 🆕 Updated |
| `GBSurface` | Foundation/ | ✅ Existing |
| `GBSectionHeader` | Components/ | ✅ Existing |

---

## Motion / haptics

```swift
// Animations
GBMotion.quick      // 0.18s — button press
GBMotion.standard   // 0.28s — screen transitions
GBMotion.spring     // response 0.40 — pin snap, reveal
GBMotion.ceremony   // response 0.55 — Chronicle reward only

// Haptics (GBHaptic)
GBHaptic.pinCorrect()       // fort pin confirmed
GBHaptic.pinClose()         // near but not exact
GBHaptic.timelineLocked()   // timeline step locked in
GBHaptic.chronicleReveal()  // reward ceremony
GBHaptic.coronation()       // arc completion (used once)
// Wrong answer: NO haptic — no shame signal
```

---

## Mastery model

| Level | Token | Meaning |
|---|---|---|
| Witnessed | `.witnessed` | Encountered the story once |
| Understood | `.understood` | Completed place + recall |
| Observed Closely | `.observedClosely` | Reviewed and retained |

No stars. No points. No timers in the core flow.

---

## Web design system

For web prototypes and design references:
- `gb-tokens.css` — full CSS token set
- `gb-design-system.html` — visual design brief (all 10 sections)
- `Greats of Bharatha Prototype.html` — interactive 5-screen prototype

---

## Implementation checklist

### P0 — Foundations (ship with arc 1)
- [ ] Bundle Cinzel, Crimson Pro, Nunito in app target
- [ ] Migrate `GBColor.swift` to v2 token set
- [ ] Add `GBShadow.swift`, update `GBMotion.swift` with haptics
- [ ] Add `GBRadius.swift` / `GBSpacing.swift` updates
- [ ] Build `GBSceneCard`, `GBQuestProgressView`
- [ ] Build `GBRecallPrompt` (no-shame feedback)
- [ ] Build `GBChronicleCard` + `GBRewardReveal`
- [ ] Build `GBMasteryBadge` + `GBButtonStyle` (v2)
- [ ] Migrate `LessonHomeView`, `SceneLessonView`, `ChronicleView`
- [ ] Migrate `PlacesHubView` + pin challenge map component
- [ ] Add icon attribution manifest

### P1 — Enhancement (V1.1)
- [ ] Dark mode polish pass
- [ ] iPad layout variants (GBAdaptiveStack)
- [ ] Parallax / tilt layer on story illustrations
- [ ] Timeline moments view
- [ ] SwiftUI Previews for all components (iPhone + iPad)
- [ ] CI artifact refresh

### Later
- [ ] Arc 2 character + token extension pattern
- [ ] AR fort viewer asset pipeline
- [ ] Speech / pronunciation UI
- [ ] Orientation mode full implementation

---

## Open questions

1. Should font files live in `GreatsOfBharatha/Resources/Fonts/` or an embedded framework?
2. Should `GBMapPinState` use SwiftUI Canvas or a UIKit-backed map view?
3. When does the place board need real iOS Maps data vs the simplified schematic board?
4. What is the minimum motion system for reward ceremony on A15 devices and below?
5. Should `GBQuestProgress` show 3 steps or allow a 4-step variant when board pinning needs emphasis?
