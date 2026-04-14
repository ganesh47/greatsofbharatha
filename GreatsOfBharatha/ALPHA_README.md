# GreatsOfBharatha Alpha Slice

This app folder now packages a smallest believable SwiftUI alpha around the existing Shivaji vertical slice.

## Included in this first slice

- Learn tab with Scene 1 and Scene 2
- Scene 1 coverage: Shivneri / birth-fort setup
- Scene 2 coverage: Torna + Rajgad / early Swarajya setup
- Places tab with core place progress states
- Royal Chronicle tab with locked and unlocked reward states
- Shared `AppModel` + `ShivajiLessonStore` glue for lesson, place, and Chronicle progress

## Current source layout

- `App/`
  - `GreatsOfBharathaApp.swift`
  - `ContentView.swift`
- `Features/Lesson/`
  - `LessonHomeView.swift`
  - `SceneLessonView.swift`
  - `StoryHomeView.swift` (older detail-browse view, still usable as a reference/debug screen)
- `Features/Map/`
  - `PlacesHubView.swift`
- `Features/Chronicle/`
  - `ChronicleView.swift`
- `Shared/Models/`
  - app content, lesson state, rewards, sample data

## Xcode target wiring

This repo still does not include an `.xcodeproj`, so the quickest path to a runnable alpha is:

1. Create a new iOS SwiftUI app target named `GreatsOfBharatha` in Xcode.
2. Drag the `GreatsOfBharatha/` folder into the target.
3. Ensure all Swift files under `App/`, `Features/`, and `Shared/Models/` are included in the app target.
4. Build on iPhone 15 / iOS 17+ first.

## Alpha acceptance pass

A basic alpha pass should now work like this:

1. Launch into the Learn tab.
2. Open Scene 1, review cards, reveal map anchors, answer recall, open Chronicle.
3. Open Scene 2, review cards, pick planning steps, answer recall, confirm stronger mastery.
4. Visit Places and confirm Shivneri, Torna, and Rajgad progress updates after lesson completion.
5. Visit Chronicle and confirm rewards move from locked to unlocked.

## Still missing before a more formal alpha

- actual map rendering and pin/snap interaction
- persistence across launches
- assets, narration, and haptics polish
- an Xcode project committed to the repo
- tests and preview coverage
