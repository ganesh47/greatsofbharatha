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

This repo now includes a generated `GreatsOfBharatha.xcodeproj` alongside `project.yml`.

Current runnable path:

1. Regenerate the project with `xcodegen generate` if `project.yml` changes.
2. Open `GreatsOfBharatha.xcodeproj`.
3. Build the `GreatsOfBharatha` scheme on an iPhone simulator or device.
4. Use `ci_scripts/ci_post_clone.sh` for tag-driven version stamping when a real Xcode Cloud or App Store Connect build pipeline is running.

## Alpha acceptance pass

A basic alpha pass should now work like this:

1. Launch into the Learn tab.
2. Open Scene 1, review cards, reveal map anchors, answer recall, open Chronicle.
3. Open Scene 2, review cards, pick planning steps, answer recall, confirm stronger mastery.
4. Visit Places and confirm Shivneri, Torna, and Rajgad progress updates after lesson completion.
5. Visit Chronicle and confirm rewards move from locked to unlocked.

## Still missing before a more formal alpha

- richer place interaction, especially real pin/snap/reveal/compare behavior
- assets, narration, and haptics polish
- broader tests and preview coverage
- end-to-end release/TestFlight proof, including a real build-producing Apple pipeline
- explicit real-device acceptance closure

## Recently closed alpha gaps

- persistence across launches now exists for lesson mastery state
- Chronicle rewards now require at least `Understood`, not just `Witnessed`
- the repo includes a generated Xcode project and Xcode Cloud post-clone bootstrap script
