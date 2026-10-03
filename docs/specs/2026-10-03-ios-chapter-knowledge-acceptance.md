# iOS chapter teaching and practice: original slice handoff and current acceptance

Base: `b8af88778fa704a45401a3daa9f8ed8576a6dad8`. Branch: `codex/gob-ios-knowledge-20261003`. Isolated sibling: `/tmp/gob-content-richness-20261003/ios-knowledge`. The integration worktree, original dirty Atlas checkout, and primary checkout were not edited by this slice.

## Owned files

- `GreatsOfBharatha/Features/LearnQuiz/ChapterKnowledgeTeachingView.swift`
- `GreatsOfBharatha/Features/LearnQuiz/ChapterKnowledgePracticeView.swift`
- `GreatsOfBharathaTests/ChapterKnowledgePresentationTests.swift`
- `GreatsOfBharathaUITests/ChapterKnowledgeUITests.swift`
- This acceptance document.

No AppModel, store, shared content/model/catalog, root, TV, or project-file edits. All historical copy is passed in `ChapterKnowledgeDefinition`; the iOS worker consumed the coordinator's three authored chapter files read-only. Synthetic unit-test content is explicitly nonhistorical.

## Entry signatures and integration

```swift
ChapterKnowledgeTeachingView(
    scene: LearnQuizPilotScene,
    definition: ChapterKnowledgeDefinition,
    sessionID: UUID,
    hooks: ChapterKnowledgeHooks,
    onFinished: @escaping () -> Void,
    now: @escaping () -> Date = Date.init,
    startingAtBeatID: String? = nil,
    sourceLookup: @escaping (String) -> ChapterKnowledgeSource? = { _ in nil }
)

ChapterKnowledgePracticeView(
    definition: ChapterKnowledgeDefinition,
    sessionID: UUID,
    hooks: ChapterKnowledgeHooks,
    onNeedsTeaching: @escaping (Set<String>) -> Void,
    onFinished: @escaping () -> Void,
    now: @escaping () -> Date = Date.init
)
```

Both chapter roots must resolve the same canonical scene definition and preserve the parent-owned saved session ID. Inject `ChapterKnowledgeAdapters.hooks(store: appModel.lessonStore, definitions: ChapterKnowledgeCatalog.definitions)`. The views have no store or AppModel mutation. Existing GB button styles expect the ancestor's AppModel environment object; present the views within the existing NavigationStack and app environment.

On ordinary teaching entry, leave `startingAtBeatID` nil to resolve the saved stable beat first. On `onNeedsTeaching(requiredIDs)`, select the first required beat in canonical definition order, pass its ID as `startingAtBeatID`, and push teaching. Pop teaching on its completion to expose the existing practice screen. Practice's `onAppear` reloads, replays, and resumes the existing queue; it does not replace the turn or reset sticky help. Pass `sourceLookup: ChapterKnowledgeSourceCatalog.source(id:)` to resolve the canonical bibliography's title, publisher and edition; the source ID remains the fallback. Each source locator is displayed exactly as authored. The source type/catalog dependency lands in coordinator content commit `650c841fa91353170a4607b0216fb2374d8bbc0b`, which must precede this iOS change during integration.

The coordinator confirmed that saving `teachingBySceneID[sceneID].activeBeatID` without shown/taught receipts is intended. This save occurs before entering a new beat. For beats with no claims, the view saves the shown beat only after the prose was presented; it creates no exposure event. For claim-bearing beats, only `ChapterKnowledgeJourney.presentedBeat` creates exposure.

Pause and native Back preserve saved selections and help. Pause confirms persistence before dismissing. Native navigation remains available for leaving a failed save; the view never claims that a failed proposal was saved. Dependent practice, teaching, advancement, and completion callbacks are blocked until retry succeeds. Unsupported archives stay read-only and offer return without writing them. A saved family-recognition queue is preserved and is not offered as an individual iOS check.

Both parent chapter routes should expose `knowledge-open-teaching-<sceneID>` and `knowledge-open-practice-<sceneID>`; the coordinator has accepted these IDs. The coordinator has also accepted the following DEBUG-only **navigation-only** adapter, gated additionally by `GOB_UI_TEST_SUITE` beginning `gob.ui.knowledge`. Its implementation remains coordinator-owned:

| Environment variable | Values |
| --- | --- |
| `GOB_UI_TEST_KNOWLEDGE_SCENE_ID` | One canonical scene ID |
| `GOB_UI_TEST_KNOWLEDGE_ENTRY` | `teaching` or `practice` |
| `GOB_UI_TEST_KNOWLEDGE_ROUTE` | `story` or `pilot` |

This adapter must use actual integrated views, ordinary hooks and saved session IDs; it must not seed exposure, claims, unlocks, answers, checkpoints or awards. The existing isolated `GOB_UI_TEST_SUITE` and `GOB_UI_TEST_RESET` behavior is reused. Teaching's completion must enter/return to practice, and relaunch through `practice` must restore the saved turn/result. These tests fail if the adapter or approved content is absent; they do not silently skip acceptance.

## Presentation and evidence

Each legacy beat is retained by ID. The authored beat prose and each attached claim statement become separate scrollable cards. Story illustrations remain on prose cards. Sources/detail and authored vocabulary have explicit expand/collapse buttons; no historical facts or glossary definitions are generated by the view. Unreviewed content and invalid definitions are unavailable.

Every card's text must pass through the visible viewport before its Continue button is enabled. Geometry coverage accumulates actual visible vertical intervals, rejects horizontally clipped text, resets when text reflows, and cannot bridge an unseen middle gap. The learner then explicitly continues. A beat is recorded only after all its prose and claim cards have been presented, and the receipt is confirmed through save-and-replay. Partial reading is transient and conservatively restarts at the saved beat's prose on relaunch. It never infers exposure from an old beat receipt. This measures presentation, not attention, comprehension or mastery.

Practice displays the saved four-question queue rather than a first-item adapter. Choosing persists selection without checking or advancing. Check persists the result/outbox before record acknowledgement. Wrong answers show authored retry feedback and the correct choice plus authored explanation. Retry and Next require that explanation to have traversed the viewport. After three wrong checks, retry is absent while teaching and moving on remain available. Clues remain sticky; subsequent seen-answer matches are labeled as such. Explicit practice-again passes `restartCompleted: true`. Completion states only that the bounded practice set is finished, and no view creates independent recall or later-recall evidence.

Semantic fonts, wrapping choices, vertical scrolling, title/header traits, explicit selected/not-selected accessibility values, dedicated fact/question/explanation IDs, and VoiceOver focus changes are provided. Actions stay within the scroll content so compact landscape and the largest Dynamic Type sizes can reach them. At the original source handoff, runtime layout and accessibility were unvalidated. The integration record below reports actual checks; manual spoken VoiceOver remains unperformed.

## Executed source evidence

With the coordinator's grant for pure Swift tests, parsing and scoped lint:

- Eleven actual `ChapterKnowledgePresentationTests` methods compiled with Swift 6 and ran in a standalone macOS XCTest harness: eleven passed, zero failures. The harness strips only the app-module import from the test copy, extracts the existing explicitly synthetic `ChapterKnowledgeTestContent`, and compiles the actual shared models/journey and the presentation helper portion of the actual teaching file. The iOS-only SwiftUI bodies are excluded on macOS.
- Both view files, the unit tests and dedicated UI test file passed Swift source parsing.
- Both actual SwiftUI view bodies passed `swiftc -typecheck` with Swift 6 for `arm64-apple-ios18.0-simulator`, using the installed iPhoneSimulator SDK, the actual existing model/design dependencies and coordinator content/catalog sources. This produces no linked app product and runs no simulator. Xcode's macro plugin required the approved source check outside the nested sandbox; the final check passed without source substitutions or excluded previews.
- Scoped strict SwiftLint passed with no source violations using `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` and `--no-cache`. The repository's pre-existing renamed-rule warning remains. Initial lint toolchain/cache errors were corrected; they are not app validation failures.

Logs and reproducible harness copies: `/tmp/gob-content-richness-20261003/ios-validation/{compile.log,tests.log,lint.log,parse.log,typecheck.log,typecheck-command.json,Fixtures.swift,ChapterKnowledgePresentationTests.swift,main.swift}`. The standalone harness uses MacOSX.platform's `Developer/usr/lib` import/library paths and `Developer/Library/Frameworks` for XCTest, including `libXCTestSwiftSupport`. No xcodebuild, simulator, browser-heavy job, project generation, push, PR, merge or release was performed. All 24 dedicated UI question/choice IDs were also checked against the canonical question coverage ledger; this validates test routing metadata, not a learner journey.

Meaningful pure tests cover failed selection saves retaining the original confirmed UI state, retry retaining the unsaved proposal, blocked advance during failed evidence acknowledgement, relaunch replay using the same checked ID, failed acknowledgement-save retry without duplicate delivery, unsupported archives without writes, active-beat/pause saves without fact credit, another scene's queue preservation, untaught gating, wrong/helped/seen-answer support, original authored page identity, offscreen/horizontal clipping, unseen text gaps, and Dynamic Type reflow.

## Original source-handoff gates

At the worker source handoff, six dedicated UI methods were prepared but unexecuted; the integrated suite now has eight methods, all executed as recorded below. They cover all six chapters and 24 questions through each of the Story and pilot adapters, fresh direct quiz requiring teaching, wrong/clue/retry and checked-result relaunch, three wrong checks retaining teaching and moving-on actions without success, interrupted choice and sticky hint persistence, stable beat and saved selection after pause/relaunch, source disclosures, largest text in landscape, reachable actions, and keyboard-free choices. Screenshots and live AX failure attachments are generated only by actual test execution.

The coordinator must complete independent historical approval, root integration, the navigation-only test adapter (or revise tests to the agreed exact path), project registration, and parent-granted app typechecking/build/UI runs. Run the UI suite on compact phone and iPad, portrait and landscape, with representative screenshot review and manual VoiceOver. Verify existing legacy progress and the original six questions and twenty-nine review cards with the coordinator's integration tests. No simulator layout, VoiceOver, old-progress end-to-end, TestFlight or released-app claim is established by this handoff.

## Integration source-detail correction

At 9205a34, actual large-text landscape AX shows the source control expanded and all textbook metadata present. The enclosing DisclosureGroup identifier replaces each citation descendant's identifier; the expected citation ID is absent. Sources and vocabulary now use independent native buttons with Expanded/Collapsed values and sibling content, preserving separately addressable citations and words. Historical copy, reading coverage, teaching receipts and evidence are unchanged. The focused compact-phone large-text and four-state audit rerun passed in 293.638 and 55.121 seconds. The complete current iPad suite also passes the source-panel and audit cases. Ordinary Story/Pilot entry is verified without navigation or receipt seeds.

## Current runtime acceptance

At tested development head `6a95310dedfe6ca07f735b206e2d4dd5bea14c36`, the dedicated iPad mini A17 Pro / iOS 26.5 run passed all 217 units and all eight knowledge UI methods: 225 total, zero failures and zero skips. Both six-chapter Story/Pilot routes traversed actual teaching and all 24 questions without seeded knowledge receipts (539.181 and 539.471 seconds). Direct untaught entry, sticky clue/wrong/result relaunch, stable beat and unchecked selection, three-wrong-check teaching/Next, ordinary chapter entries, largest text in landscape and native four-state accessibility audits all passed. The UI class took 1,531.235 seconds.

The original compact-phone 5/6 result is retained; its citation-identity failure was corrected from live AX evidence and passed the focused rerun. Representative portrait practice/feedback and direct simulator landscape teaching images were inspected. Landscape XCTest attachments have a capture-transform artifact and are not used to infer app clipping. Native audits cover hit regions, descriptions and traits; they do not establish a manual spoken VoiceOver walkthrough.

[Shared integration acceptance](2026-10-03-chapter-richness-integration-checkpoint.md) records exact timings, TV parity/legacy/4K evidence, local artifact paths and limitations. Full legacy iOS UI coverage and all required checks remain exact-head hosted gates. Public PR, merge and TestFlight publication await the parent's explicit clearance; this is development evidence rather than a released-app claim.
