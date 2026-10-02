# Due-first review journey

Date: 2026-10-02. Baseline: `dabaca93539ec574ad65fd1d21838e7da5fda048`. Integration/release owner: coordinator task `01a0fd86-4b00-701d-8145-128e43596041`. Related: [learning implementation plan](2026-10-01-multi-agent-fix-and-testflight-plan.md).

## Delivered slice

- `GreatsOfBharatha/Features/LearnQuiz/FlashcardReviewView.swift`: due-card queue, optional practice, checked answer before reveal, honest self-report, authored reteaching, one rescued revisit at the queue end, completion/continue/finish actions, optional read-aloud, scrollable Dynamic Type layout and save retry.
- `GreatsOfBharatha/Shared/Models/ReviewJourneyModels.swift`: Codable checkpoint/archive/evidence, card schedules using the existing SpacedReviewScheduler, authored prompt rotation, per-card independent witnesses, bounded reteach and a durable-before-callback outbox driver.
- `GreatsOfBharathaTests/ReviewJourneyTests.swift`: 34 synthetic XCTest cases with injected dates and UTC calendar.
- This acceptance document.

No edits to Map, SampleContent, ContentModels, AppModel, shared store, app roots/navigation, project or release files. A second commit supplies the optional remote review screen and adapter described in [TV review acceptance](2026-10-02-tv-review-journey-acceptance.md); coordinator owns its routing, project generation and integrated validation. Existing rich six-chapter TV journey remains unchanged by this slice. Existing PR #210 matching work was not duplicated.

## Behavior and evidence

Only learned scene cards enter the queue. Existing per-card schedules are retained; previously unscheduled cards inherit their canonical scene's due date once while keeping their own authored cadence. Due cards sort by due date then card ID. Future cards require explicit optional practice, which cannot lengthen the interval when the card is not due. Initial queue is capped at 32 cards; one taught revisit per card caps the full queue at 64 turns. Pending evidence is capped at 128 events. Any pending event blocks dependent UI actions and a new session, preserving the old validation checkpoint until replay succeeds. The confirmed archive is still published when a callback returns false; Retry uses its original stable event IDs.

`I knew it`, `Needed a clue` and `Teach me again` are self-reports and scheduling inputs. They never create a checked independent witness. Checking a typed answer before reveal records a fresh checked answer, an incorrect attempt or a helped check. A later independent recall requires an earlier checked witness for this SAME card, another session, at least 24 hours, a changed authored check prompt, and no current help. Its optional `priorIndependentWitness` is captured before updating the current witness, so a durable pending event proves the claim after callback/relaunch. `hasValidLaterIndependentWitness` rejects same-session, under-24-hour, unchanged-prompt and shared-family claims. An immediate taught revisit is rescued practice even if the typed answer matches. Same-session repeats and early optional practice cannot imitate spaced recall.

Check prompts reuse existing authored alternate card fronts with the same answer or a canonical chapter challenge whose accepted answers include the card's answer. Duplicate wording is excluded. No new historical facts or generated dialogue are introduced. Cards without an authored alternate support self-report and teaching, not invented assessments. Prompt IDs and the actual checked prompt type remain in the evidence. Exact normalized authored wording/aliases are used; the UI explains that another wording may need help rather than claiming a child's knowledge was measured broadly.

The existing scheduler supplies four-hour clue revisits, immediate teach-again/reset and day intervals capped at the authored final cadence. Teach again opens the actual authored chapter story, card answer and meaning before offering a single rescued turn after the other cards. A repeated teach request can show teaching again but cannot append another turn. Finish for now is available throughout.

Typed input is retained only to resume an interrupted unchecked prompt. It is cleared immediately after checking or self-report and never copied into evidence or exported.

The iOS keyboard includes Done (`review-dismiss-keyboard`), which only clears answer focus. It preserves the typed answer, queue and evidence and does not check or reveal anything. Interactive scroll dismissal also lets the learner put the keyboard away before reaching Finish for now. The coordinator's native UI evidence at `/tmp/gob-enrichment-20261002/evidence/ios-native-hit-fixes/6EBD4F8F-89C9-498F-8BFC-2965A841E634.txt` placed Finish below the visible keyboard; dismissal provides a reachable route without submitting an answer. This scoped source change passes lint/syntax/whitespace checks; integrated UI acceptance must confirm Done hides the keyboard, leaves the answer unchanged, shows no result and allows Finish.

## Coordinator integration contract

`FlashcardReviewView(cards:hooks:now:)` accepts `ReviewJourneyHooks` with MainActor closures:

```swift
load: () -> ReviewJourneyArchive
save: (ReviewJourneyArchive) -> Bool
record: (ReviewJourneyEvidence) -> Bool
```

The coordinator confirmed `activityState(ReviewJourneyArchive.self, for: .review)`, `saveActivityState(archive, for: .review) -> Bool`, and `hasRecordedLearningEvent(UUID)` in integration commit `7233e0a`. Store adapter/navigation injection is coordinator-owned. The adapter must use AppModel's injected normal/capture/test defaults and the shared TV storage budget. Without hooks the view safely offers a return action; production acceptance requires injection at every entry.

Persist the review archive at the snapshot root, separate from LessonResumePoint/TVActivityCheckpoint. Never overwrite the original chapter checkpoint, session, story/place/recall/keepsake progress or preferred chapter activity when reviewing. Retain per-card schedules and witnesses instead of silently combining them into scene-level review history.

`save` must return true only for a durable save. `record` validates the event against the durably saved archive and known authored cards/prompts, and returns true for a durably saved OR already-saved stable event ID. Failure leaves the outbox intact. Save-before-callback, callback-false/relaunch/new-session blocking and replay-after-acknowledgement-failure are covered by tests. An unknown callback must not award learning. Preserve cardID, checkedPromptID, priorIndependentWitness, responseContext, selectedChoiceID, session, support and timestamp provenance. The optional additions decode older archives without migration; older later-recall claims with no prior proof must not earn independent review.

| Kind | Shared learning interpretation |
| --- | --- |
| selfReported | Self-report/scheduling input only; no checked recall |
| freshChecked | Successful independent recall check; no automatic later mastery |
| laterIndependentRecall | Independent review only after same-card witness, changed prompt, >=24h and distinct session |
| helpedChecked | Successful recall with rescued/hinted support |
| incorrectChecked | Unsuccessful recall attempt |
| reteachingExposure | Exposure only; no completion/mastery |

Scene schedule aggregation must not reset or advance each card's archive schedule. Domain `wasSuccessful` is false for self-reports even when the learner selects I knew it.

For TV evidence, `responseContext == .sharedFamilyRecognition` qualifies every interpretation above. A fresh checked choice without a clue has `.independent` support only in the sense that no clue was opened. It never creates an individual's witness or later independent recall. Parent summaries must say the family checked a choice without/with a clue. A self-report has no selected-choice proof and remains separate from checked recognition.

## Validation performed

34/34 review XCTest cases passed on 2026-10-02 in an isolated temporary SwiftPM harness, plus 13/13 synthetic TV adapter cases. The harness compiled unmodified copies of real `ContentModels`, `HeroArcModels`, `LearningEngines` (including SpacedReviewScheduler), `MasteryState`, `TVActivityCheckpoint`, `AppleMapsPlaceHandoff`, and this new model; no scheduler stubs or historical test data were used. Cases cover due ordering/unlearned/future/empty queues, stable card schedules, four-hour revisits, immediate reteach, one requeue, wrong/blank/revealed answers, helped checks, changed prompt provenance, 1/3/7/14-day cadence, early optional practice, clock rollback, same-session repetition, round-trip resume, typed-input clearing, event replay, save/ack failures and queue/outbox bounds. Follow-up cases prove retained prior witnesses, invalid later-claim rejection, backward-compatible optional fields and callback-false/relaunch blocking.

Strict SwiftLint for the five owned Swift files passed with no source violations; the existing configuration emits its deprecated rule-name notice. Swift frontend syntax parsing and git diff whitespace check passed. Checks needed per-command Xcode selection and writable module/cache paths; no global toolchain setting was changed.

Supporting local evidence:

- `/tmp/gob-enrichment-20261002/review-model-tests.log`
- `/tmp/gob-enrichment-20261002/review-lint.log`
- Follow-up logs: `/tmp/gob-enrichment-20261002/review-tv-model-tests.log`, `/tmp/gob-enrichment-20261002/review-tv-lint.log`
- Temporary harness: `/tmp/gob-enrichment-20261002/review-model-validation`
- Dedicated build/module/cache paths: `/tmp/gob-enrichment-20261002/review-model-derived`, `review-module-cache`, `review-model-cache`, `review-model-config`.

Run the harness with per-command `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, `CLANG_MODULE_CACHE_PATH` and `SWIFT_MODULECACHE_PATH` under the review root, `swift test --package-path .../review-model-validation --scratch-path .../review-model-derived --cache-path .../review-model-cache --config-path .../review-model-config --disable-sandbox --jobs 2`. The committed tests also belong to the normal iOS test target after coordinator XcodeGen generation.

## Remaining integrated acceptance

Coordinator alone regenerates the project and takes the heavy build/simulator slot. Pure model/source checks do not establish app compilation, UI acceptance or release readiness. Before merge/release, verify:

1. Inject durable hooks at every production review entry; normal/capture/test storage isolation and compact/recovery load remain correct.
2. Start with synthetic learned cards with different due dates. Confirm due order, no unlearned cards, honest caught-up state and explicit future practice.
3. Check before reveal; reveal then self-report; wrong answer; Teach again -> authored teaching -> other card -> rescued revisit -> completion. Repeated teach requests terminate the bounded queue. Completion, All done and Finish for now are reachable.
4. Terminate/relaunch during typed prompt, after reveal, during teaching and after a saved response. Restore session/turn/help/queue exactly; duplicate callbacks do not re-award evidence or intervals.
5. Confirm the original iOS chapter and TV story/discovery/place/puzzle/keepsake checkpoints are unchanged. Continue my chapter dismisses review to its caller; coordinator owns any additional root continuation route.
6. Validate self-report, fresh checked, helped, exposure and later independent recall remain distinct in Album/Parent summaries. Advance an injected clock to four hours and then another day; same-session or unchanged-prompt work never becomes later recall.
7. Verify small phone/iPad, landscape, largest Dynamic Type, VoiceOver, keyboard dismissal, narration disabled/interrupted, calm/Reduce Motion and offline completion. This view adds no decorative motion.
8. Integrate `TVReviewJourneyView(hooks:now:)` and run the focused TV production-content test plus remote/caption/focus/relaunch acceptance in the linked TV document. Pure adapter checks and syntax parsing do not establish TV app compilation or visual acceptance.

No merge or TestFlight operation was performed by this worker.

Refs #212: [combined enrichment validation](https://github.com/ganesh47/greatsofbharatha/pull/212).
