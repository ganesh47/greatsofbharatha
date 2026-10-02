# Six chapter iOS discovery and story transfer

- Pinned source: `dabaca93539ec574ad65fd1d21838e7da5fda048`.
- Worker branch: `codex/ios-chapter-discoveries`.
- Shared schema dependency: coordinator commit `7d2959f834174c49447c387465e4e07b5e33ee51`.
- Scope: authored story discovery, chapter-specific place teaching, and optional family reflection.
- Project generation, active navigation integration, integrated testing, PR merge, and release belong to the coordinator.

## Content and learning boundaries

The [shared catalog](../../GreatsOfBharatha/Shared/Models/ChapterDiscoveryContent.swift) reuses the exact teaching, discoveries, place clues, answers, hints, and family prompts from the six chapters in [TVLearningContent](../../GreatsOfBharathaTV/Learning/TVLearningContent.swift). A dedicated parity test compares every field. There are 18 discoveries and eight chapter/place clues, under the existing six canonical scene IDs. Rajgad keeps its distinct Early Capital and Comeback clues; Purandar precedes Agra; Raigad remains the coronation capital. The existing story, historical chronology, Chhatrapati, Swarajya, geography, planning, and responsibility framing remain in place. No historical facts, dialogue, or tradition claims were added.

Story and extra chapter teaching precede checked activities. Discovery controls remain optional, with no all-details gate. Each first opened detail records `.storyExposure` only. Reading, replay, and family reflection cannot award recall, successful reviews, a keepsake, or a more advanced mastery state. Checked recognition, helped recognition, self-report, and later independent recall remain the store's distinct activity types.

“Talk together (optional)” opens the exact authored family prompt. A separate “Think about your own day” prompt is explicitly described as personal reflection with no answer to check. No response, completion, evidence, or personal information is saved for reflection.

## Integration API

The coordinator inserts this hook in `SceneLearnView`, before Quiz/Match/Cards actions:

```swift
if let content = ChapterDiscoveryContent.chapter(sceneID: scene.id) {
    ChapterStoryDiscoveryView(content: content)
}
```

The wrapper provides teaching, glossary, read-aloud controls, discovery state, and optional family reflection using the existing `AppModel` environment object. Its presentation component also supports explicit state injection:

```swift
ChapterDiscoverySection(
    content: ChapterDiscoveryContent,
    discoveredDetailIDs: Set<String>,
    selectedDetailID: String?,
    onSelect: (ChapterDiscovery) -> Void
)
```

`ChapterDiscoveryInteraction.open(_:content:store:) -> LessonResumePoint?` validates authored content, uses the existing session, saves the selected detail before exposure, and saves the opened ID afterwards. The exposure event UUID is a deterministic SHA-256-derived identity scoped to session and canonical detail. Retrying between either write is idempotent. Relaunch restores the exact selected detail and finishes a prepared but interrupted exposure using the original identity.

Legacy `hill`, `gate`, and `book` exposure IDs remain in the saved set and are recognized as opened chapter-one details. Opening them adds their canonical identity without inventing new checked evidence. Existing chapter-one UI button IDs remain compatible. Other checkpoint fields, including matching and TV checkpoints, are preserved. `SceneLessonView` reads the latest stored checkpoint before phase changes, so a child discovery write is retained.

`OfflineFortChallenge` accepts an optional `authoredClue: ChapterPlaceClue?`; existing callers retain their fallback behavior. The story lesson supplies the exact chapter clue and hint, including Rajgad's comeback role. Each challenge has a `fort-challenge-<placeID>` accessibility container for unambiguous testing when two boards contain the same candidate.

## Validation evidence

These are source and native test results, not released-build or simulator rendering evidence.

| Gate | Worker result | Evidence |
| --- | --- | --- |
| Canonical catalog, exploration-only progress, replay, interrupted writes, legacy IDs, selection restoration, preserved activity state | Passed: 10/10 native XCTest cases | `/tmp/gob-enrichment-20261002/discovery-validation/native-tests.log` |
| Exact six-chapter TV authored content parity | Passed: 1/1 native XCTest case | `/tmp/gob-enrichment-20261002/discovery-validation/native-tv-tests.log` |
| Swift 6 production core/module compile | Passed | `native-build.log` in the same validation directory |
| Complete iOS production source frontend check | Passed: all 56 production Swift files with the coordinator schema overlay | `ios-typecheck.log` in the same validation directory (exit 0, no diagnostics) |
| Dedicated iOS UI test source frontend check | Passed | `ios-ui-test-typecheck.log` in the same validation directory |
| Scoped SwiftLint and whitespace | Passed; only the existing renamed-rule configuration notice | `lint.log`; `git diff --check` |
| Integrated iOS/tvOS builds, simulator UI execution, visual and VoiceOver inspection | Pending coordinator | Project generation and a coordinated simulator slot are required |

The native harness compiles the real production content, engines, models, and store, and executes the checked-in XCTest classes. It uses unique synthetic defaults suites and removes each suite afterwards. To honor ownership, the coordinator's exact `HeroArcModels.swift` from commit `7d2959f` is supplied as an external compiler overlay, without editing that worker file. Its SHA-256 is `afce85de17fa9f2fcbd2161a549b098e846d33a804bcea38ecb0bdd815dc73aa`. The native TV parity harness also compiles the real TV content adapter, sequence engine, and pilot adapter; its color-independent `GBEmphasis` declaration is copied verbatim from the existing token file. This checks content, not TV rendering or remote behavior.

Source checks use per-command `DEVELOPER_DIR`, isolated module caches, and no simulator. The SwiftUI compiler macro runner could not create a nested sandbox; the source frontend check used an auto-reviewed per-command escalation. No project generation, `xcodebuild`, simulator use, process termination, global developer setting, credential change, merge, or release was performed by the worker.

## Integrated acceptance to run

Run the new `ChapterDiscoveryTests` and `ChapterDiscoveryParityTests` under their actual iOS/tvOS targets after coordinator project generation. Run `ChapterDiscoveryUITests` on the coordinator's reserved iOS simulator. Its two cases cover:

1. All six chapters with teaching before recall, all three discoveries, optional family prompts, distinct place boards, checked recognition, and the final keepsake. Chapter two restores the selected detail after cold relaunch; chapter three uses recall help. The journey uses normal transitions.
2. Large accessibility text in landscape with narration disabled and calm transitions enabled. A revealed detail survives cold relaunch; unopened discoveries remain optional and place learning can continue.

Retain screenshots from the test result bundle and inspect each chapter's revealed text, optional reflection, and place clues in portrait and landscape. Confirm long text remains readable and all controls are reachable. Check narration off, Stop, returning from another phase, and device Reduce Motion. Test VoiceOver reading order, button labels, opened state, focus on newly opened detail text, optional reflection, and continuation. The worker prepared native accessibility labels and focus handling; actual VoiceOver usability remains unverified.

With networking unavailable, verify that bundled teaching, all discoveries, place clues, and reflection remain usable; read-aloud may depend on the installed system voice, while readable text and continuation remain available. This source has no network request or remote content dependency. Preserve the existing rich six chapter TV journey and matching acceptance while integrating this iOS hook.

### Landscape test reachability correction

The coordinator's `ios-final-targeted.xcresult` run passed 149 unit cases and both matching cases, but the large-text discovery case failed before its initial hill discovery tap. In the fresh recording `BE26201E-4F41-43F6-9BDB-F98908BE3ED0.mp4`, the hill button passes through the visible landscape viewport around 66 seconds; the helper continues scrolling and finishes back at the story top. During every discovery iteration the activity log reads the window and two target frames, then swipes; it never reaches the subsequent native hittability read. This supports the added window-center predicate rejecting the rotated target. The exported binary UI snapshots contain only an application stub with empty children, so they do not establish the actual button frame or label overflow.

The discovery helper now accepts XCTest's native `exists` and `isHittable` result, retains bounded scrolling and the native element tap, and attaches a screenshot, live accessibility hierarchy, device orientation, and window/scroll/target frames if it still cannot reach a target. No app layout or authored content changed. Worker Swift 6 source checking, scoped lint, and whitespace checking pass; coordinator simulator rerun is required before claiming the landscape case passes. Evidence: `/tmp/gob-enrichment-20261002/ios-final-targeted.log`, `/tmp/gob-enrichment-20261002/evidence/ios-final-targeted/manifest.json`, and extracted fresh frames in `/tmp/gob-enrichment-20261002/evidence/discovery-layout-worker`.

A separate CI run at integration head `450aec1` failed before rotation: the narration switch was tapped at 19.03 seconds and its value was read immediately at 19.51 seconds, still enabled. That log does not establish whether the switch missed the interaction or updated later. The preference helper now waits up to five seconds for the requested value after one native switch tap. It fails with retained live accessibility, geometry, current/expected values, and screenshot evidence if the preference remains unchanged or cannot be reached. It neither writes preferences directly nor repeats a toggle blindly. This is a test postcondition correction; runtime success still requires the coordinator rerun. Evidence: `/tmp/gob-enrichment-20261002/integration-450-ios-ci.log`; pure checks: `/tmp/gob-enrichment-20261002/discovery-layout-validation`.

The native-hit rerun reached the hill tap but failed to find its detail after relaunch. The landscape case now positively reveals and asserts the selected detail before termination, in addition to checking that narration controls are absent. This separates first-tap activation from later restoration; a logged tap alone is not proof that a detail opened. The fresh rerun's missing-detail failure requires its live hierarchy before assigning the cause to Home navigation, selection, or persistence. Evidence: `/tmp/gob-enrichment-20261002/ios-native-hit-fixes.log`.

The fresh rerun's live hierarchy `D325BB52-5730-467F-BEC4-76C5819541C6.txt` confirms entry into Shivneri after relaunch, with all three discoveries still ready to discover. The first hill tap's actual synthesized event `09CCF2DE-41B5-4AC7-B1D7-D239AFBF5AAC` sends both touch-down and touch-up at `(249, 8)` in an `844 × 390` window. Recording frames at 43.9 and 44.335 seconds show the hill already above the navigation bar. Native hittability therefore accepted a covered target; the absent restored detail cannot yet be attributed to persistence.

The helper now captures the target frame once per iteration and requires its center inside the scroll/window intersection, excluding current navigation, tab, and keyboard frames with an eight-point inset. It uses frame-directed native drags, with a slow drag and a hold before release, bounded to 64 drags. A known target more than one usable viewport away permits a drag of up to 70% of that viewport, without passing the target center; near or unknown targets retain the 76-point cap (or 40% of a smaller viewport). This avoids spending dozens of small drags crossing long teaching content while preserving the narrow-control approach. The native button tap and positive initial-detail check remain. Failure attachments include all obstruction frames, usable viewport, live accessibility, target state, and screenshot. Worker source/lint/geometry checks pass; a coordinator runtime rerun remains necessary. No app layout or navigation change is justified by this evidence.

### iPad clipped-control and text postcondition correction

The completed iPad mini A17 Pro / iOS 27 run reached Raigad after the preceding five chapters, then failed its second selected-detail assertion. Synthesized event `6B62E83F-D97E-4718-B61C-B43EF5897BE0` records a native tap at `(372, 1122)` in a `744 × 1133` window. The recording's frame at 211.4767 seconds shows the second discovery button clipped below the window, with the home indicator crossing its center; the first detail remains open. The center-only viewport predicate admitted this clipped button because there was no bottom TabBar. Evidence: `/tmp/gob-enrichment-20261002/ipad-enrichment.log`, `/tmp/gob-enrichment-20261002/evidence/ipad-enrichment/manifest.json`, and `/tmp/gob-enrichment-20261002/evidence/ipad-worker-frames/frame-211.5.png`.

Fitting content buttons now require their complete vertical bounds inside the unobstructed viewport as well as native hittability. Long static text and controls taller than that viewport retain center handling. Each iteration still measures the target once, uses the existing bounded native drags, and taps the native button. All 18 selected-detail checks and six optional family-prompt checks reveal their text before positively asserting its presence. Missing text retains a screenshot, live accessibility hierarchy, and target/viewport frames. Relaunch, helped recall, skipped discovery, narration, and reward assertions remain in place; no app content, layout, navigation, or evidence recording changed.

The lightweight geometry harness extracts the actual helper and checks the recorded iPad window and tap point against fitting test button rectangles centered there, without claiming those synthetic rectangles are captured AX frames. It rejects the clipped button, accepts it after the existing 76-point drag, and retains center handling for long static text. All 26 geometry checks, the Swift 6 UI source frontend check, scoped strict lint, and whitespace checks passed; logs are recorded under `/tmp/gob-enrichment-20261002/discovery-layout-validation/ipad-clipped-*`. Lint emitted only the existing renamed-rule configuration notice. Coordinator iPad execution is still required for this test-only correction.

### Fitting-button alignment in landscape

The coordinator's strengthened iPad cases passed: the six-chapter discovery journey in 250.97 seconds and timeline in 43.50 seconds. The subsequent iPhone landscape case selected its initial detail successfully, then exhausted 64 alternating drags on Home after relaunch. The finalized `ios-visible-final.xcresult` live attachment `AFCCA78C-06D5-404D-9C21-5C9B5DC98D1E.txt` captures a native-hittable Home Continue button at `(92, 84.33333587646484, 660, 187.33331298828125)` in an `844 × 390` window. Its usable viewport is `(8, 86, 828, 232)`. The button fits vertically when aligned, but its final top edge is above that viewport. A fixed 76-point adjustment moves it past the opposite bottom edge; reversing that adjustment returns to the same clipped position. The captured center is about 24 points from the viewport center.

For a fitting content button within one viewport, `dragDistance(to:isButton:)` now caps the existing near drag by the absolute target-center-to-viewport-center gap. Far targets keep the 70%-of-viewport approach, and unknown targets, static text, and controls taller than the viewport keep their prior bounded approach. Full vertical visibility, native hittability, native drag/tap input, all text postconditions, and failure diagnostics remain required. The pure harness extracts the actual revised helper and uses the exact finalized Home AX rectangle to show that both former oscillation endpoints can reach full visibility with the capped step. It also preserves the recorded iPad clipped-control checks. All 38 geometry checks, the Swift 6 UI source frontend check, scoped strict lint, and whitespace checks passed. This is a test helper correction; no app source changed. Worker evidence lives under `/tmp/gob-enrichment-20261002/discovery-layout-validation/near-alignment-*`; coordinator landscape execution remains required.

## Owned file list

- `GreatsOfBharatha/Features/Lesson/SceneLessonView.swift`
- `GreatsOfBharatha/Features/Lesson/LearningExperienceComponents.swift`
- `GreatsOfBharatha/Shared/Models/ChapterDiscoveryContent.swift` (new)
- `GreatsOfBharathaTests/ChapterDiscoveryTests.swift` (new)
- `GreatsOfBharathaTVTests/ChapterDiscoveryParityTests.swift` (new)
- `GreatsOfBharathaUITests/ChapterDiscoveryUITests.swift` (new)
- `docs/specs/2026-10-02-ios-chapter-discovery-acceptance.md` (new)

No existing shared schema/store, authored sample content, map, root/navigation, project, matching, TV production, CI, or release file was changed by this slice. The original dirty checkout remains untouched.

Refs #212: [combined enrichment validation](https://github.com/ganesh47/greatsofbharatha/pull/212).
