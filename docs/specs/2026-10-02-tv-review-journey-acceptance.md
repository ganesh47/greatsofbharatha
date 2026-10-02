# Apple TV family card review

Date: 2026-10-02. Follow-up to [due-first review](2026-10-02-review-journey-acceptance.md), first commit `08cdb2fc269345f1b2ac1d7f0ba3533e21c7fe59`. Coordinator task `01a0fd86-4b00-701d-8145-128e43596041` owns navigation, shared store adapters, project generation, integrated builds, PR publication/merge and release.

## Delivered source

`GreatsOfBharathaTV/TVReviewJourneyView.swift` adds a remote-selectable review screen, a pure adapter and descriptors derived from existing content. `GreatsOfBharathaTVTests/TVReviewJourneyTests.swift` adds 13 synthetic adapter tests and one tvOS-only production-content test. Shared review models and the iOS view receive the prior-witness and pending-outbox fixes requested during integration.

No roots, chapter screens, maps, shared store, content models, historical content, project or release files change. All six existing TV chapters retain their story, discovery, place, puzzle, keepsake and checkpoint flows.

## Entry API and durable hooks

```swift
TVReviewJourneyView(hooks: ReviewJourneyHooks, now: @escaping () -> Date = Date.init)
```

Inject the existing `AppModel` and `GBNarrator` environments. `ReviewJourneyHooks(load:save:record:)` uses the same durable root `.review` activity archive as iOS, independently of the chapter checkpoint. `TVReviewJourneyContent.descriptors: [ReviewJourneyCard]` supplies known TV cards/check prompts. `TVReviewJourneyContent.cards: [TVReviewJourneyCard]` additionally supplies the existing authored choices for callback validation. The caller determines the route; Continue our chapter, All done and Finish for now dismiss to it. Remote Back first clears and durably saves a selected unchecked choice without evidence; otherwise it stops narration and dismisses. Selection persists across process relaunch when Back was not pressed.

Checkpoint additions are optional `selectedChoiceID`, `helpWasRequested` and `sharedFamilyResponse`. Evidence additions are optional `priorIndependentWitness`, `responseContext` and `selectedChoiceID`. Existing archives decode absent fields. The submitted choice ID stays in the event so the durable callback can verify the authored selected answer after checkpoint selection clears. Choice titles are fed to the checker only in memory; TV never persists a typed answer.

The adapter must validate an event against the DURABLY SAVED archive and canonical card/prompt/choice IDs. A false recording callback or failed acknowledgment leaves the outbox pending. Both views publish the last confirmed archive, show Try saving again and block dependent actions until the outbox is empty. `ReviewJourneyEngine.start` returns the old archive unchanged whenever any pending event exists; it cannot discard the old session's validation checkpoint. Retry and relaunch preserve stable event IDs. The outbox driver requires acknowledgment of an already-recorded ID as success.

## Remote journey and honest evidence

Only cards from checked learned TV chapters enter the due-first queue. Future cards require explicit Practise learned cards. Due ordering and scheduler behavior use the existing shared engine: at most 32 initial cards, 64 turns and 128 pending events. No event is evicted to continue.

The prompt and all answer choices have visible captions and optional read-aloud. Clicking an answer selects it without awarding evidence. Check family choice is a separate remote action. Give us a clue opens the authored hint and marks help before the answer is checked; that state stays sticky across selection and relaunch. Focus identifiers cover choices, Check, help, reports, teaching, retry and completion. No text entry or phone is required.

Every TV event is `responseContext == .sharedFamilyRecognition`. Without a clue a correct selected choice is `freshChecked` with `.independent` support and a family caption. With a clue or after teaching it is `helpedChecked` with `.hinted`/`.rescued` support. Neither creates/overwrites `independentWitnessesByCardID`, and neither can become `laterIndependentRecall`. An incorrect choice is unsuccessful and cannot extend its interval or create a witness. Parent summaries must describe a family choice checked without/with a clue, never one person's independent recall.

Reveal and tell us what we needed leads to We knew it / We needed a clue / Teach us again. These are explicitly labelled memory reports, separate from checked choices, and have no selected-choice proof. Teach us again displays the complete existing chapter story beats, the card answer and meaning, with optional read-aloud. Continuing after teaching records exposure and appends one rescued revisit after the other cards. Asking again can show teaching again but cannot append another turn. Completion and exit remain reachable.

## Authored content and prompt rotation

All 29 canonical pilot review card IDs and authored answers are retained. Existing TV chapter challenge choices/correct-answer flags supply checked recognition. A card gets choices only when its authored answer matches that chapter's challenge accepted answers, or its original question is exactly the authored challenge question. Other cards support honest self-report and teaching. No custom choices, historical facts, dialogue or unsupported assessment prompts are invented.

Alternative prompts reuse existing same-answer review fronts and the canonical chapter challenge. Choices must have unique normalized labels, exactly one correct choice and flags consistent with the prompt's accepted answers. A new acknowledged family session rotates away from its last checked prompt when another authored prompt exists. A taught revisit also rotates when supported. This variation never establishes a later independent witness.

## Local validation and remaining integrated checks

47 synthetic XCTest cases passed: 34 review-domain cases and 13 TV adapter cases. The isolated SwiftPM harness uses the real shared Foundation models and scheduler. Its TV target copies the exact adapter/card prefix of `TVReviewJourneyView.swift`; it excludes the production content factory and SwiftUI screen. Cases cover select-before-check, no-selection rejection, family context, old-individual-witness isolation, sticky clue/four-hour schedule, wrong-choice behavior, self-report separation, bounded rescued reteaching, selection/help resume, invalid selection/choice rejection, prompt rotation and callback-false/relaunch/new-session blocking. Logs: `/tmp/gob-enrichment-20261002/review-tv-model-tests.log` and `review-tv-lint.log`.

The five owned Swift files pass strict SwiftLint; both UI sources pass frontend syntax parsing. These checks do not establish an app build, simulator UI behavior or release readiness. The additional `testProductionTVReviewOnlyUsesExistingAuthoredChoicesAndCanonicalSubjects` is guarded by `os(tvOS)` and requires the coordinator's TV target run; it verifies canonical card IDs, existing choices/teaching/prompt provenance and eligible checks across all six scenes.

Before merge/release the coordinator must:

1. Generate the project and build/test the integrated iOS and TV targets in the reserved heavy slot. Inject hooks at every TV/iOS card entry and validate the event's context and choice ID before acknowledgment.
2. Run the production-content test and inspect prompt/answer correctness in all six chapters; preserve Hindu kingship, Swarajya, geography, governance and history/tradition distinctions in the reused text.
3. Verify 1080p and 4K layouts, focus visibility, remote selection then Check, Back/dismiss, scroll reachability, caption wrapping, read-aloud pause/interruption/off settings and VoiceOver. Inspect long teaching captions without requiring a phone.
4. Test selection, clue, revealed report, result, teaching and completed-session relaunch. Reject one recording callback, attempt continuation/practice, relaunch, then retry; stable IDs and the old checkpoint must remain until acknowledgment.
5. Confirm review writes preserve the original six-chapter story/discovery/place/puzzle/keepsake checkpoints. Parent/Album summaries must separate family recognition, self-report, helped practice, exposure and individual later independent recall.
6. Complete offline/no-save retry and duplicate-event acceptance with the real store. Verify normal/capture/test defaults isolation and aggregate TV storage budget.

No worker merge, project generation, full app build, simulator slot or TestFlight operation was performed.

Refs #212: [combined enrichment validation](https://github.com/ganesh47/greatsofbharatha/pull/212).
## Focused remote UI follow-up

`GreatsOfBharathaTVUITests/TVReviewJourneyUITests.swift` adds four coordinator-run acceptance tests. It uses the established native directional focus helper and `XCUIRemote.shared.press(.select/.menu)` only; it contains no element taps, pointer coordinates or debug route bypass. Each test has a unique `gob.tv.ui.review.*` defaults suite and the existing debug-only seed through chapter three. Reset is removed after the initial launch, so relaunch reads the same durable archive. The route is the coordinator-owned `tv-home-review` / `TVRoute.review` entry. Explicit optional practice handles the seed's future due dates.

1. Focus on the home entry does not navigate. Focus on an answer does not select/check; selection enables Check without changing prompt/progress/result; only remote Check produces a family-choice result.
2. Selection restores after termination with native focus on Check. First Back clears it without result or queue advancement; relaunch retains the cleared selection. Next Back returns home with the original chapter continuation unchanged.
3. Opening an authored clue displays captions/read-aloud and creates no checked result. Relaunch retains help; a subsequent Check says the family checked with help. Finish returns home.
4. Reveal/report/Teach again shows authored teaching captions/read-aloud, appends one tail revisit and keeps it rescued. Repeat teaching on that tail cannot append another turn; completion, Continue our chapter, All done and Finish remain reachable. Screenshots accompany selected, restored, clue, teaching, revisit and completion states.

The follow-up also adds Selected/Available accessibility values to TV review choices and the Back behavior above. Strict SwiftLint and frontend syntax parsing passed for the view and new UI-test source. These four UI tests have NOT been run by the worker; coordinator owns the reserved TV simulator/device and integrated test execution. The earlier 47 synthetic passes remain the domain/adapter evidence, not proof that these remote scenarios passed.
