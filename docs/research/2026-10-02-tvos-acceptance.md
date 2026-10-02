# Apple TV learning beta acceptance

Date: 2 October 2026. Audience: children aged 6–10, with one shared local family journey and a shared Siri Remote. All six Shivaji Maharaj chapters are included. This document distinguishes automated evidence from device and family observations.

Refs #208: [iOS beta baseline integrated before the tvOS release](https://github.com/ganesh47/greatsofbharatha/pull/208).

## Delivery gates

- Build the `GreatsOfBharathaTV` scheme for tvOS Simulator in Debug and for a generic Apple TV device in Release. Verify the TV icon and static Top Shelf assets compile. Preserve the iOS scheme and run its existing learning/state and journey regression tests.
- Run `GreatsOfBharathaTVTests` for canonical authored content, remote sequence rules, truthful reward/mastery outcomes, compact storage, migration, checkpoints and duplicate-event protection.
- Run `GreatsOfBharathaTVUITests` using `XCUIRemote` directional and Select presses. Collect `.xcresult` attachments for home, retry, puzzles, keepsake, album and parent settings. A screenshot-only route is not proof that a child can navigate there.
- Check both 1920×1080 and 3840×2160 layouts. Essential text, focus enlargement and navigation controls must remain visible inside the TV safe area.
- Verify narration-off, muted sound and Reduce Motion journeys remain complete and understandable. Text and control states must communicate the same essential information as audio and animation.
- Keep total app-owned defaults, including recovery data, at or below the 256 KiB budget after repeated play. Caches must not hold essential progress. The TV store must retain earned keepsakes, review timing, assistance classification and resume state through relaunch.
- CI must find an available Apple TV runtime/device, compile the TV scheme, confirm `Assets.car` and both static Top Shelf declarations are packaged, and run both TV test targets. A missing runtime fails the gate.

## Evidence status

The local environment has Xcode 27.0, tvOS 27.0 SDKs and tvOS 26.5/27.0 1080p and 4K simulator runtimes. Apple commands use a per-process `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` because global developer selection points to CommandLineTools. No physical Apple TV was detected during setup.

An unperformed check remains pending. Local `.xcresult` paths below contain test logs and screenshots; the CI workflow uploads its result bundle independently.

| Check | Status | Evidence |
| --- | --- | --- |
| tvOS unit tests | Passed: 27/27 after main integration | tvOS 27.0, 1080p simulator; `/tmp/gob-tvos-pr-integrated.xcresult`, `/tmp/gob-tvos-pr-integrated.log`; 7 content, 7 sequence, 13 persistence tests. The earlier final-17 run also passed 27/27 |
| tvOS remote UI tests | Passed: 6/6 after main integration | Same integrated result bundle: pristine six-chapter journey, retry/help, matching/ordering, keepsakes, final fort-board link, useful Home continuation, partial timeline and selected-card recovery, album relaunch, Back, locked timeline, persisted preferences and Play/Pause. All-six journey 304.365 seconds; UI suite 431.172 seconds. Combined unit/UI result: 33 passed, zero failed. Earlier final-17 screenshots retain their original provenance and remain representative of the unchanged TV UI |
| 1080p and 4K visual inspection | 1080p reviewed; 4K Home and chapter-four regression reviewed | 26 curated final-17 1080p screenshots, five 3840×2160 chapter-four regression attachments and the separate `home-4k.png` in `docs/research/evidence/2026-10-02-tvos/`. Native focused puzzle text has dark ink on a light fill; story, keepsake and timeline controls remain visible. The entire six-chapter journey was performed at 1080p; a full 4K six-chapter journey remains unperformed |
| Release device archive | Passed, unsigned | `build/tvos/GreatsOfBharathaTV.xcarchive`; `/tmp/gob-tvos-release-final-source.log`. Device signing/provisioning and installation remain unverified |
| iOS regression tests | Passed: 58/58 after main integration | `/tmp/gob-tvos-ios-integrated.xcresult`, `/tmp/gob-tvos-ios-integrated.log`: 53 unit and 5 UI tests. Earlier isolated baseline/current runs passed 51 unit tests but failed their four UI tests (large/landscape home activation, parent gate and retry/reward); integration of the newer iOS beta baseline resolved those failures. The earlier result remains historical evidence, not the current gate |
| Lint and whitespace | Passed | Full-project SwiftLint exits 0 (`/tmp/gob-tvos-lint-final-source.log`); scoped TV test lint exits 0 with only the repository's renamed-rule configuration notice (`/tmp/gob-tvos-validation-lint-final.log`). `actionlint .github/workflows/tvos.yml` and `git diff --check` pass |
| Real Siri Remote / Apple TV | Pending | Physical device not available during setup |
| Physical narration and VoiceOver | Pending | Requires actual Apple TV |
| Family learning/fun study | Pending | Requires 3–5 consenting families |

UI tests launch with a unique `gob.tv.ui.` defaults suite and reset only the first launch. Navigation uses directional `XCUIRemote` presses, strict `hasFocus` assertions and Select. The all-six journey starts with no progress. A separate fast chapter-four regression uses a narrowly guarded Debug-only first-three-chapter bootstrap; it is absent from Release and does not seed the complete acceptance journey.

The six UI cases completed in 428.4 seconds; the complete chapter-to-timeline-to-album journey took 302.3 seconds. The [screenshot manifest](evidence/2026-10-02-tvos/screenshot-manifest.json) records each curated 1080p capture's test, device, timestamp and result bundle. Representative evidence: [selected-card resume focus](evidence/2026-10-02-tvos/selected-order-restored-focus-1080p.png), [final keepsake](evidence/2026-10-02-tvos/final-chapter-keepsake-placed-1080p.png), [seven-event timeline](evidence/2026-10-02-tvos/seven-event-timeline-1080p.png), and [earned album](evidence/2026-10-02-tvos/earned-album-1080p.png).

The targeted 4K chapter-four remote case passed 1/1 in 53.355 seconds on tvOS 27.0 (`GoB-TV-4K-Review`, device `EA851759-6362-4F9F-B9A1-623BCEED0F5D`): `/tmp/gob-tvos-4k-ordering-final.xcresult` and `/tmp/gob-tvos-4k-ordering-final.log`. It covers an incorrect ordering attempt, help, all three placements, partial-puzzle and selected-card relaunch, initial native focus, and the keepsake screen. The five exported captures have manifest provenance and verified 3840×2160 dimensions. [Restored slot focus](evidence/2026-10-02-tvos/selected-order-restored-focus-4k.png) and [keepsake ready](evidence/2026-10-02-tvos/keepsake-ready-4k.png) show clear text and visible controls within the safe area. The separately retained `selected-order-before-focus-check-4k.png` is a diagnostic capture before focus settles; the restored-focus capture is the accepted focus evidence.

These are XCTest app screenshots. Foreground DeviceHub window verification was unavailable while the Mac was locked; the remote tests and app captures still ran successfully. One runtime warning reports synchronous audio-session activation on the main thread. No narration test failed, but physical audio responsiveness remains a device acceptance check. Xcode's auxiliary diagnostic collector also reported that its subprocess could not find `simctl` under the global CommandLineTools selection; the per-process tvOS build, tests and result export succeeded.

The persistence tests include 3,000 family story replays, legacy/schema migration, corrupt main data, stable completed-event IDs after the recent 256-event replay window rotates, all checkpoint stages, a separate timeline checkpoint, explicit rescue markers surviving hint compaction, and rejection of invalid compressed recovery length declarations. Completed checkpoint IDs preserve durable deduplication; the recent event ring alone is a finite replay window.

A full saved journey with six completed chapter checkpoints and 31 active completion IDs on the final chapter exposed an outdated recovery snapshot when uncompressed data exceeded 16 KiB. Tagged, bounded LZFSE recovery now retains the latest timeline and exact review schedules after corrupting the main snapshot. The final automated fixture's recovery is 8,908 bytes and main snapshot is 43,330 bytes, within the 256 KiB aggregate gate. Imported/self-reported recognition preserves earned keepsakes while genuine checked recall remains necessary to unlock the timeline.

## Physical Apple TV checklist

Use the Release build on an Apple TV and a real Siri Remote. Record hardware, tvOS version, resolution and remote model. The beta is not physically accepted until this checklist has observed results.

1. From roughly eight feet away, find the focused control, start a chapter and read the essential prompt. Verify 1080p and 4K safe areas and focus enlargement.
2. Navigate all controls with directional buttons, then with normal clickpad swipes. Focus must follow direction, remain visible and never itself submit an answer. Pick up and pass the remote without accidentally completing an activity.
3. Make an incorrect recall choice. Verify encouraging, useful feedback and a reachable retry/help control. Complete with help and verify the parent summary does not claim independent lasting recall.
4. Complete a matching puzzle and an ordering puzzle. Verify no required dragging, text entry, phone, microphone or game controller. Check edge tiles, filled slots, repeated Select presses and focus after a tile disappears or becomes disabled.
5. Earn one keepsake, place it in the album, leave and relaunch the app. Resume the correct stage and verify the reward is not duplicated. Complete the sixth chapter and inspect the final shared-journey state.
6. Check Back from each screen. Back must pause an active activity or return through the visible navigation hierarchy. Verify Continue restores progress. Check Play/Pause starts and pauses narration, and that voice, sound effects and background music remain comfortable.
7. Turn narration off while speech plays, then relaunch. Speech must stop and the preference must remain off. Verify the local English voice fallback, volume handling and interruptions on actual hardware.
8. Enable VoiceOver. Navigate story, choices, puzzle, reward, album and parent controls. Names, selected/locked states and feedback must be understandable; narration must not obscure VoiceOver instructions.
9. Enable Reduce Motion, then disable calm transitions inside the app. System Reduce Motion must still prevent vigorous celebration/transition motion. Check increased text and contrast settings without clipping or color-only meanings.
10. Disable networking and complete core play. Clear disposable caches, relaunch and verify essential content and saved learning still work. Test low-storage behavior without promising recovery after deleting the application.

## Family learning and fun study

Recruit 3–5 families with children aged 6–10; a guardian gives consent and stays present. Record age, historical familiarity, language comfort and display/remote used. Screen recording is optional and requires separate consent. Stop when a child is tired, anxious or asks to stop. Do not describe the activity as a test or call an answer a failure.

Use a 20–25 minute session: short warm-up, the first three chapters, one matching puzzle, one sequence puzzle, the album and a five-minute recall break. Ask a family member to hand over the remote once and use one family prompt. Avoid coaching answers; offer navigation help after the child is stuck for 20 seconds. Observe whether help, retry, reward and the next action are understood.

Record fun and willingness to continue (1–5), confusion (1–5), parent learning value (1–5), parent trust (1–5), which controls require adult intervention and whether the family prompt sparks a discussion. Ask the guardian for a brief factual-trust comment: which story fact, historical framing or progress label they trust or would want checked. A high learning-value score does not replace this trust observation. Record short factual observations rather than collecting child names or audio by default.

At a natural stopping point, offer “one more story, a different activity, or stop” without praise or a reward for continuing. Record the child's voluntary choice and whether it required adult prompting. Choosing to stop is an observation, not a failed session.

After the break, ask where the story begins, what “Birth Fort” means, which fort was the early capital, which fort was the turning point, the order of the first three moments and one reason forts mattered. Score each privately: 2 for unprompted recall, 1 after a clue, 0 when not recalled. Have the guardian repeat four short questions the next day without teaching first; do not send external messages automatically.

Initial signals to continue: average fun at least 4/5, confusion at most 2/5, five-minute recall at least 8/12, parent value and trust each at least 4/5, and no age-appropriateness or cultural-respect concerns. Review voluntary continuation separately from the rating. These are research observations, not app mastery claims. Iterate if rewards are enjoyable while places/order are not remembered, or children need an adult to find routine controls.

The following anonymous record slots are blank; no family sessions have been performed.

| Family | Age / device / remote | Fun / confusion | Recall after break / next day | Parent value / trust | Voluntary continuation | Factual-trust comment / navigation help |
| --- | --- | --- | --- | --- | --- | --- |
| F01 | Pending | Pending | Pending | Pending | Pending | Pending |
| F02 | Pending | Pending | Pending | Pending | Pending | Pending |
| F03 | Pending | Pending | Pending | Pending | Pending | Pending |
| F04 | Pending | Pending | Pending | Pending | Pending | Pending |
| F05 | Pending | Pending | Pending | Pending | Pending | Pending |

## Limits and release scope

Simulator tests verify behavior and focus routes; they do not certify physical remote feel, TV readability, audio routing, device memory/performance or durable restoration after application deletion. Local progress is a single family journey; there is no account, cross-device sync or guaranteed cloud backup.

The initial acceptance delivery prepared source, an unsigned archive and local test evidence. The user subsequently authorized commit, pull request, merge and tvOS TestFlight deployment. Release verification now requires the exact merged source SHA, all existing main CI gates plus the dedicated tvOS gate, a TV-only Xcode Cloud workflow, the `tvos-v` release tag, and an App Store Connect prerelease build whose platform is explicitly `TV_OS`. A matching iOS version/build number cannot establish TV delivery. TestFlight delivery remains pending until the release report verifies the signed Cloud run, exact TV build and existing internal group membership; no testers are invited by this acceptance work.

Primary references: [Apple remote behavior](https://developer.apple.com/design/human-interface-guidelines/remotes), [focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/), [tvOS defaults limits](https://developer.apple.com/documentation/foundation/userdefaults/sizelimitexceedednotification), [release-device testing](https://developer.apple.com/documentation/xcode/testing-a-release-build), [app asset catalogs](https://developer.apple.com/documentation/xcode/configuring-your-app-icon), and [accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
