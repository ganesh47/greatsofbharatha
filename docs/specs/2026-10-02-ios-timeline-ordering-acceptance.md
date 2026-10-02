# iOS Timeline ordering activity

Date: 2026-10-02 · Base: `dabaca93539ec574ad65fd1d21838e7da5fda048` · Owner: `codex/ios-timeline-ordering`

## Result and scope

Replace the read-only Timeline hub with a touch ordering activity. A child reads a short recap, taps a story card, and taps First, Then, or After that. Correct cards stay placed. A wrong slot retains the selection and prior correct work, gives an authored clue, and marks help. Optional clues never place cards. Selected card, partial placements, teaching state, retries, hints, help, current round, session and placement receipts survive checkpoint serialization.

The seven event IDs, titles and date labels come from `SampleContent.shivajiVerticalSlice.activeHeroArc.timelineEvents`. Brief teaching strings and the three overlapping round boundaries reuse `TVLearningContent.timelineEvents` / `fullTimelineRounds`: events 1–3, 3–5 and 5–7. Each recap also reads the linked canonical scene's child-safe summary and meaning, retaining Chhatrapati, Swarajya, geography and responsibility context already authored in the journey. No historical facts, dialogue, collective enemy framing or recovery year are added. The birth label remains “commonly commemorated as 1630”, early forts remain “c. 1646 to 1654”, and recovery has no exact year. These broad sequencing cards do not add interpretations of tradition.

The rich six-chapter TV journey and existing matching work are untouched. This change does not write to chapter or TV resume checkpoints, settings, maps, authored content, app roots, generated project or release configuration.

## Owned files

- `GreatsOfBharatha/Features/Timeline/TimelineHubView.swift`
- `GreatsOfBharatha/Shared/Models/TimelineActivityModels.swift` (new, Foundation only; shared target visibility)
- `GreatsOfBharathaTests/TimelineActivityTests.swift` (new)
- `docs/specs/2026-10-02-ios-timeline-ordering-acceptance.md` (new)

## Coordinator integration contract

The coordinator accepted this API in `/tmp/gob-enrichment-20261002/COORDINATION.md`:

```swift
TimelineHubView(
    checkpoint: store.activityState(TimelineActivityCheckpoint.self, for: .timeline),
    onCheckpointChange: { store.saveActivityState($0, for: .timeline) },
    onPlacementChecked: { store.recordIOSTimelinePlacement($0) }
)
```

The generic checkpoint store API was provided by the coordinator in integration commit `7233e0a`; the placement adapter name in the example is illustrative. `onCheckpointChange` and `onPlacementChecked` both return Bool. The view names and types are final. The default initializer remains compatible with the existing isolated capture route, but production entry must supply both hooks for durable progress and learning evidence.

`TimelineActivityCheckpoint` is Codable. The coordinator stores its encoded data under `.timeline` in snapshot-root `activityStateData`, outside chapter resume state; `activityState(_:for:)` returns nil for absent older-snapshot data. The worker does not edit storage. The view restores against known canonical rounds, removes unknown IDs, wrong/reordered slots, missing or mismatched checks, self-reported checks, duplicate receipt IDs and stale-session receipts. It does not advance past earlier unchecked rounds. Opening completion is retained when all six chapters later become eligible.

`TimelinePlacementCheck` carries `eventID: UUID`, `sessionID: UUID`, `roundID: String`, `eventSubjectID: String`, `slotIndex: Int` and `support: LearningSupport`. Each receipt belongs to one correct, explicit slot submission and one canonical timeline subject. Save the checkpoint before recording evidence and deliver no receipts if that durable save returns false. `TimelineActivityEngine.synchronize` enforces this ordering. The callback returns true for accepted **or already-recorded** receipts; false leaves a pending receipt for retry after restoration using the same ID. Acknowledge and save after recording. Failed intent/acknowledgement saves show `timeline-save-status` and `timeline-save-retry`; failed evidence acknowledgements stay pending. Recorded completion and the next-round CTA require acknowledged receipts and a successful save. If acknowledgement saving fails, the previous durable checkpoint retains pending receipts with identical IDs for crash retry. Distinct subjects and overlapping rounds use distinct receipt IDs; the same receipt is never awarded twice.

The store adapter must read the **durably saved** checkpoint and verify `check.isValid(round:sessionID:)` against the canonical matching round, plus the saved round's matching `checksByCardID` and slot. Record only:

```swift
recordLearningOutcome(
    subjectID: check.eventSubjectID,
    subjectType: .timeline,
    activity: .timelinePlacement,
    wasSuccessful: true,
    support: check.support,
    promptType: .sequenceSlot,
    eventID: check.eventID,
    sessionID: check.sessionID
)
```

The coordinator supplies the actual adapter, root entry, persistence migration and project generation. Correct placements made before later help retain their original support; round help/retry state remains sticky. There is no rescue auto-placement in this slice. Selection, recap, hints, wrong answers and opening the screen emit no successful learning evidence. Completed recap emits no new award. Completion copy says checked story order or checked with help; it does not claim mastery, independent recall or later retention.

Eligibility matches TV: first three canonical chapters need checked recall/review evidence to open the first round; all six need checked learning to open all three. `TimelineActivityCatalog.hasCheckedLearning(evidence:)` accepts recallSuccess/reviewSuccess, excludes selfReported support, and rejects exposure, failed attempts and reflection. Legacy checked evidence with no support field remains compatible. Self-report cannot open an assessed round or manufacture a placement receipt.

## Validation completed for this slice

- 26/26 `TimelineActivityTests` pass in an isolated macOS Swift 6 package. The package copies the actual canonical content, existing store, models and Timeline test source, plus the unchanged `GBEmphasis` enum extracted from its token file. Test storage uses a random synthetic UserDefaults suite with cleanup. No app's real storage is loaded or seeded.
- Coverage includes seven-event/dates parity, overlap boundaries, checked-learning eligibility, exposure/self-report exclusion, no checks from teaching/selection/hints, gentle retry, preserved correct slots/selection/help, correct-card locking, invalid inputs, partial relaunch, pending receipt identity, duplicate subject IDs, malformed checkpoints, sequential round progression, opening-to-full transition and version recovery. Five additional fault-injection checks verify no evidence on failed intent save, save-before-check ordering, acknowledgement-save failure/crash retry, pending evidence status and completion only after acknowledgement.
- A real existing-store crash/retry test records a helped timeline placement, reconstructs the store, retries the same receipt and confirms one evidence entry, `.timelinePlacementSuccess` / `.timelinePlacement` / `.hinted`, `.understood` state and no `.reviewSuccess`.
- New UI and domain typecheck with Swift 6 against iOS Simulator SDK 27 and the coordinator's pinned baseline app module. This is compile evidence, not rendered/simulator interaction evidence.
- Swift parser, scoped SwiftLint with `--no-cache` and `git diff --check` pass. Only the existing renamed lint-rule configuration warning remains.
- Isolated logs: `/tmp/gob-enrichment-20261002/timeline-domain-tests.log` and `/tmp/gob-enrichment-20261002/timeline-ui-typecheck.log`; dedicated package/build/cache paths all start with `timeline-domain-` or `timeline-ui-`.

No Xcode project generation, simulator session, merge or release was performed by this owner. Source and model checks do not establish a released build's behavior.

## Required integrated acceptance gates

The coordinator must generate the project and run these tests in the real iOS test target. Add a reachable Learn/Album entry and use the hooks for the production and Timeline capture routes before considering the slice complete.

| Gate | Synthetic setup and observable result |
|---|---|
| Reachability and eligibility | Pristine storage shows `timeline-locked`; exposure/self-report cannot open it. Three checked chapter answers open the first recap. All six checked chapters make all three rounds available. |
| Tap check | `timeline-start` begins; tap `timeline-card-<canonical ID>` then `timeline-slot-0/1/2`. Selecting alone changes no evidence. Correct slot stays locked and persists exactly one receipt. |
| Gentle retry/help | Choose a wrong slot after one correct card. Correct slot and selected card remain. `timeline-feedback` teaches the authored clue. `timeline-hint` fills no slot; subsequent correct placement retains `.hinted`. No wrong-answer haptic. |
| Partial relaunch | Save one correct card, reveal a clue and select another card. Terminate/relaunch using the same dedicated suite without reset. Slots, selected card, support and session/event IDs match. |
| Crash window | Terminate after receipt save/record but before acknowledgement. On relaunch, adapter acknowledges the already-recorded same UUID. Evidence and success counters do not increase twice. |
| Save failure | Inject false from checkpoint callback. `timeline-save-status` and `timeline-save-retry` appear; no evidence callback runs. Retry with successful storage delivers the same IDs. Inject failed evidence or acknowledgement save; completion remains unavailable until successful retry. |
| Full story | Complete opening, middle and return rounds. Pratapgad and Agra anchor the overlaps; Purandar stays before Agra; recovery stays after return and before Raigad. `timeline-success` reports checked order, retaining helped status. Looking back emits no award. |
| Durable migration | Decode older snapshots with no iOS Timeline field; chapter and TV checkpoints remain unchanged. Preserve optional Timeline checkpoint through AppModel/store recreation and reset under coordinator policy. |
| Accessibility/layout | Verify iPhone/iPad, landscape and large Dynamic Type. Card and slot targets are at least 80 pt, primary actions at least 56 pt. VoiceOver labels distinguish available/selected/checked cards and name ordered slots. No horizontal drag or color-only correctness cue is required. |
| Offline and regressions | With networking disabled, recap and checks remain usable. Verify the default six-chapter iOS/TV paths, PR210 matching and TV focus/Back/resume independently. |

Human VoiceOver listening, real offline disconnection and child/parent usability checks remain human validation. No child recordings, exports or recruitment are part of this work.

Refs #212: [combined enrichment validation](https://github.com/ganesh47/greatsofbharatha/pull/212).
