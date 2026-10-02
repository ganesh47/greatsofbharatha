# Matching UX acceptance: iOS and Apple TV

Date: 2 October 2026. Refs #209, the integrated Apple TV/iOS baseline. Audience: children aged 6–10. This change makes matching easier to understand through two named panels, explicit selection states, short authored teaching feedback and gentle firefly motion.

Linked issue: #126 — child/parent validation of fun, comprehension and trust.

## Interaction contract

- Choosing another card on the same side replaces the selection without recording a mistake or assistance. Choosing the selected card again puts it away.
- A wrong opposite-side choice keeps the source selected and teaches using that source's authored clue. A later success retains the existing assisted-learning classification.
- Correct pairs commit immediately. Decorative animation does not record evidence, advance stages or block input. Restoration does not replay celebrations.
- Canonical tile and pair IDs remain unchanged. iOS saves an optional selected tile in its existing lesson checkpoint; older snapshots decode without it. TV retains its existing selected-tile checkpoint and stable completion IDs.
- Remote focus and selected state are separate. Focus transfer follows visible card order without selecting a correct answer for the child. Back clears an active selection before leaving.
- Matched cards remain readable, with a recap that explicitly joins each source to its partner rather than implying that adjacent rows are pairs.

## Evidence

The integrated source passed the following local checks. Result bundles remain on the implementation host; selected unmodified XCTest screenshots and their test/device/timestamp provenance are checked in below.

| Check | Result | Local evidence |
|---|---|---|
| Final iOS suite | 77/77: 69 unit tests and 8 UI tests | `/tmp/gob-matching-ios-final-07.xcresult` |
| TV regression suite | 35/35: 27 unit tests and 8 remote UI tests, including all six chapters | `/tmp/gob-matching-tv-tests-03.xcresult` |
| Final TV text/layout at 1080p | 3/3 remote cases, including the added three-pair board and completion safe area | `/tmp/gob-matching-tv-readable-1080p.xcresult` |
| Final TV text/layout at 4K | 2/2 remote cases | `/tmp/gob-matching-tv-readable-4k.xcresult` |
| Release device builds | iOS build and unsigned TV archive succeeded | `/tmp/gob-matching-ios-release-recap.log`, `/tmp/gob-matching-tv-final-readable.xcarchive` |
| Release tooling | 77 Python fixtures passed; SwiftLint and diff whitespace checks passed; project generation stable | `/tmp/gob-matching-release-fixtures.log`, `/tmp/gob-matching-swiftlint-final.log` |

The TV full regression run preceded the final font-only adjustment and added three-pair test. All three changed matching scenarios were rerun at 1080p; two also passed at 4K. These are split-run results, not a claimed full 36-test final TV run. Dedicated TV CI reruns the current complete suite.

The tests cover same-side switching, gentle mismatch with retained source, right-first selection/help, Back, relaunch restoration, explicit remote focus, duplicate award protection, real Done navigation, large accessibility text and narration/calm preferences. Review found no material integration issues.

- iOS: [selected source](evidence/2026-10-02-matching/ios-selected.png), [teaching retry](evidence/2026-10-02-matching/ios-retry.png), [joined recap and Done](evidence/2026-10-02-matching/ios-completed.png), [accessibility-size completion](evidence/2026-10-02-matching/ios-accessibility-completed.png), [stacked Places panel](evidence/2026-10-02-matching/ios-accessibility-places.png), [stacked Memory clues panel](evidence/2026-10-02-matching/ios-accessibility-memory.png). The latter two are read-only simulator captures during an unchanged, passing large-text replay.
- TV: [1080p chosen versus focused](evidence/2026-10-02-matching/tv-1080-selected-focus.png), [1080p three-pair completion](evidence/2026-10-02-matching/tv-1080-three-pair-completed.png), [4K chosen versus focused](evidence/2026-10-02-matching/tv-4k-selected-focus.png).
- [Screenshot provenance](evidence/2026-10-02-matching/manifest.json).

A six-second simulator recording at `/tmp/gob-matching-ios-motion-enabled-success.mp4` shows the final iOS firefly celebration with calm transitions disabled and narration off. The TV recording `/tmp/gob-matching-tv-firefly-success-1080p.mov` shows the flight between chosen partners; it predates only the final TV font enlargement. Recordings were visually reviewed but are local artifacts. Static screenshots establish layout, not animation or child enjoyment.

TV matching uses 29-point card facts and at least 23-point instructions/status, following [Apple's accessibility typography guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility). The earlier audit screenshots establish baseline problems, not acceptance of the new design.

## Device and family validation still pending

Automated simulator checks do not establish physical Siri Remote usability, VoiceOver comprehension, comfortable viewing distance or child enjoyment. Use the existing [child/parent research script](2026-04-30-shivaji-learn-quiz-child-parent-validation-script.md), with these matching tasks on iOS and Apple TV:

1. Ask the child to show which panel starts a pair and where its partner belongs, without an adult explaining the panels.
2. Ask the child to change their selected card, then try an incorrect partner. Observe whether they understand that the source stays selected and can find the next choice.
3. Complete with and without help; ask the child to retell one association in their own words. Assistance earns the same keepsake but is reported truthfully in factual progress summaries.
4. Relaunch with a card selected and ask the child to continue. On TV, pass the remote and check that focus movement alone submits nothing.
5. Compare normal motion with calm/Reduce Motion. Record confusion, voluntary continuation, recall and parent trust in 3–5 consenting families. Do not infer learning or enjoyment from test success.

Record device, resolution, remote model, settings and observed results. Narration-off and muted play must remain complete; physical VoiceOver and motion acceptance remain pending until observed.
