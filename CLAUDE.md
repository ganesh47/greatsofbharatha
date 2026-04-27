# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

**Project generation (required after adding/removing source files):**
```
xcodegen generate
```

**Build for testing (run on Mac with Xcode, not WSL):**
```
xcodebuild build-for-testing \
  -project GreatsOfBharatha.xcodeproj \
  -scheme GreatsOfBharatha \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -resultBundlePath TestResults/Build \
  SWIFT_VERSION=6.0
```

**Run tests (after build-for-testing):**
```
xcodebuild test-without-building \
  -project GreatsOfBharatha.xcodeproj \
  -scheme GreatsOfBharatha \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -resultBundlePath TestResults/Run
```

**Run a single test:**
```
xcodebuild test-without-building \
  -project GreatsOfBharatha.xcodeproj \
  -scheme GreatsOfBharatha \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -only-testing:GreatsOfBharathaTests/TestClassName/testMethodName
```

**Xcode Cloud hooks** are in `ci_scripts/` — `ci_pre_xcodebuild.sh` runs `xcodegen generate` before every build.

Swift version is **6.0** (strict concurrency). All UIKit types (`UIImpactFeedbackGenerator`, etc.) require `@MainActor` isolation.

## Architecture

### Entry point & state
- `GreatsOfBharathaApp.swift` — creates `AppModel` and injects it as `@EnvironmentObject` at root
- `AppModel` — single source of truth: holds `AppContent`, `ShivajiLessonStore`, `ParentLearningSettings`
- `ShivajiLessonStore` — mastery state machine with `MasteryRecord`, `ReviewSchedule` (spaced repetition), evidence log; drives unlock gating across all 4 tabs

### Navigation
- `ContentView` → `TabView` with 4 tabs: **Learn**, **Places**, **Timeline**, **Chronicle**
- Each tab owns a `NavigationStack`; no path-based routing
- Lesson flow is a 4-phase sequence inside `LessonView`: **Story** (LearningCards 0–2) → **Place** (map anchor clues) → **Recall** (MCQ challenge) → **Reward** (Chronicle keepsake reveal)

### Content model hierarchy
```
HeroArc
  └─ SceneCluster[]
       └─ LearningCard[]     (story beats, image + narrative)
       └─ RecallChallenge    (MCQ, no-shame feedback)
       └─ ChronicleEntry     (collectible keepsake)
```
`MasteryState` is a 6-level enum: `witnessed → understood → observedClosely → remembered → placed → chronicled`

### Design system
All tokens and components live in `GreatsOfBharatha/DesignSystem/`:

| Token file | Key exports |
|---|---|
| `GBColor.swift` | `GBColor.Story/Place/Chronicle/State/Border/Background`, `GBColor.gradient(for:)`, `GBColor.accent(for:)` |
| `GBTypography.swift` | `GBFont.display(size:weight:)` → Cinzel, `GBFont.story(size:italic:)` → Crimson Pro, `GBFont.ui(size:weight:)` → Nunito |
| `GBSpacing.swift` | t-shirt sizing (`xxxSmall`…`xxxLarge`), `cardGap`, `sectionGap`; `GBTouch` for tap-target minimums |
| `GBRadius.swift` | `compact=10`, `card=20`, `hero=28` |
| `GBMotion.swift` | `quick`, `standard`, `spring`, `bounce`, `ceremony`, `progress`; `@MainActor enum GBHaptic` |
| `GBIcon.swift` | SF Symbol name constants; `GBIcon.Fort` enum for fort-specific icons |

`GBEmphasis` (`.story`, `.place`, `.chronicle`, `.neutral`) drives gradient and shadow selection across all components — use `GBColor.gradient(for: emphasis)` and `.gbShadow(.story/.place/.gold)`.

`GBLayoutContext` is an `EnvironmentKey` providing `containerPadding`, `sectionSpacing`, `maxContentWidth` per size class. Read it with `@Environment(\.gbLayoutContext)`.

### Product constraints (non-negotiable)
- **No stars, points, streaks, or timers** — mastery replaces gamification
- **No haptic on wrong answers** — no-shame policy; only `GBHaptic.pinCorrect()` on correct
- **Sensor policy**: camera/microphone only for AR Place mode, never stored
- Touch targets: minimum `GBTouch.button` (56 pt) for primary actions; `GBTouch.primary` (80 pt) for hero CTAs
