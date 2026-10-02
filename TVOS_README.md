# Greats of Bharatha on Apple TV

Native SwiftUI adventure for ages 6–10, in English, with one local family journey.
The six Shivaji chapters combine narrated story beats, three optional discoveries,
fort clues, recognition, matching or ordering, and keepsake placement. A fictional
firefly supplies authored help outside the historical story.

## Run and test

Open `GreatsOfBharatha.xcodeproj`, choose **GreatsOfBharathaTV**, and select an Apple TV
simulator or a provisioned Apple TV. The deployment target is tvOS 18.

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
xcodebuild test -project GreatsOfBharatha.xcodeproj \
  -scheme GreatsOfBharathaTV \
  -destination 'platform=tvOS Simulator,name=GoB-TV-Acceptance' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Use an available Apple TV simulator name on another machine. The dedicated
`.github/workflows/tvos.yml` discovers a supported destination automatically.
Regenerate the project after adding or removing Swift sources. Only the integrator
should regenerate while agents are working.

## Remote and learning

Direction buttons move focus; Select activates. Match by choosing a card and its
partner. Order events by choosing a moment and a numbered slot. Back cancels a
selection or closes a discovery before leaving; Play/Pause controls the visible
text's narration. No typing, dragging, microphone, or controller is required.

Help and explicit assisted placement are available throughout. Incorrect choices
teach without penalties. Assistance is saved truthfully; exploration and album
placement do not establish independent recall. Family discussion is optional and
unassessed. Narration, extra clues, and calm transitions are persistent parent
settings. Captions remain visible; VoiceOver takes priority over app narration.

## Shared code and saved state

The TV target explicitly includes shared content/store/engines, compatible design
tokens, the existing six-chapter adapter, and bundled artwork. TV screens and
navigation have their own source root. The iOS entry point and feature views are
excluded; shared Maps/haptics APIs are platform guarded.

TV checkpoints preserve each lesson's activity, clues, matching/ordering state,
session, and completion IDs. Separate timeline checkpoints prevent a timeline
review from overwriting an unfinished lesson. Completed learning remains replayable
in a new session; Home chooses unfinished work, a due review, or the next chapter.

TV defaults use a single compact snapshot without legacy mirrors. The 256 KiB
budget includes app-owned settings and bounded semantic recovery. Recent history
and dedup IDs are bounded; mastery evidence, earned rewards, counters, review
schedules, and active completion IDs remain. Dedup covers retained events and
checkpoint completion IDs, rather than an unlimited UUID history. Progress remains
local to this platform and is not promised after deletion/reinstallation.

## Assets and acceptance

TV resources must appear in the target's **sources** entries with resource build
phases, so XcodeGen includes both catalogs. The TV-specific brand collection has
layered small/store icons and static standard/wide Top Shelf images. The script
`tools/prepare_tvos_brand_assets.py` packages the existing fort/book emblem and
requires Pillow.

See `docs/research/2026-10-02-tvos-acceptance.md` for automated results and the
physical-device and family-research checklist. Simulator screenshots live in
`docs/research/evidence/2026-10-02-tvos/`.

The Release archive is a local unsigned candidate. Device provisioning/signing,
real Siri Remote ergonomics, actual audio/pronunciation, VoiceOver listening,
couch-distance readability, and the 3–5-family study require physical validation.
No TestFlight publication has been performed.

## Local beta package

The implementation lives on `codex/tvos-learning-adventure` in the isolated TV
worktree. It includes the reviewed working-tree baseline; the original checkout
was not modified by this execution. Open this worktree's project when testing.

`build/tvos/` contains the complete source ZIP, unsigned Release `.xcarchive` and
archive ZIP, preserved XCTest result bundles, logs, test summaries, and
`beta-candidate.json` with hashes and baseline provenance. The source ZIP includes
the generated Xcode project, resources, tests, CI, and research evidence.

The final 1080p run passed 27 TV unit tests and six remote UI tests. The targeted
4K ordering/relaunch run also passed. The iOS unit suite passed 51 tests; all four
existing iOS UI cases also fail on the preserved baseline, so iOS UI regression
acceptance remains unresolved. Detailed scope and pending physical/family work
are recorded in the acceptance document above.
