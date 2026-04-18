# Shivaji asset checklist

- Status: Draft
- Linked issue: #11
- Milestone: Shivaji Arc - 2026-04-17
- Owner: @ganesh47
- Last updated: 2026-04-18

## Problem

The current alpha slice proves lesson, place, and Chronicle flows in code, but the repo has not yet documented the content assets needed to take that slice from placeholder implementation to repeatable production authoring.

This checklist defines the minimum asset inventory needed to keep scene expansion, captions, narration, and place-learning content consistent.

## Goals

- define the asset families required by the Shivaji arc
- make caption and narration requirements explicit
- separate must-have first-slice assets from later polish
- give contributors a concrete checklist when adding new scenes or places

## Non-goals

- prescribe final recording tools or audio middleware
- require premium-only media before the touch-first slice is usable
- replace per-feature implementation specs

## Asset groups

### 1. Scene content copy

For each `StoryScene`, provide:
- scene title
- narrative objective
- key fact
- child-safe summary
- timeline marker text
- ordered interaction-step copy
- recall prompt question
- recall prompt answer
- recall prompt support text

Status for current alpha:
- present in `SampleContent.swift`
- should be treated as baseline content, even where later polish improves wording

### 2. Map and place content

For each `Place`, provide:
- place name
- memory hook
- primary event
- why-it-matters copy
- broad region label
- educational coordinates
- core-release inclusion flag

Optional later assets:
- hero image or illustration reference
- terrain silhouette or fort thumbnail
- comparison-callout copy for nearby forts

### 3. Chronicle reward content

For each `ChronicleReward`, provide:
- title
- subtitle
- meaning text
- linked scene ID
- category
- mastery threshold

Optional later assets:
- reward icon or badge art
- unlock animation treatment
- collection celebration copy variant

### 4. Narration package

For each scene, define:
- narration script matching the child-safe story beat
- optional shorter fallback script for low-attention or retry contexts
- pronunciation notes for proper nouns where needed
- scene-to-scene tone guidance so the arc sounds consistent

Delivery expectations:
- narration must reinforce approved historical framing
- narration should remain interruptible and non-blocking
- every narration line should have a matching caption or transcript source

Current status:
- script intent exists in scene copy and interaction steps
- finished narration assets are not yet present in repo

### 5. Caption and transcript package

For each narrated or read-aloud moment, provide:
- caption text
- transcript text if it differs from on-screen caption pacing
- speaker context if needed for accessibility or future audio systems
- punctuation and line-break review for child readability

Rules:
- captions should reflect approved canonical wording
- captions must be available for all narrated instructional beats
- caption text should avoid dense, adult-oriented phrasing

Current status:
- captions are referenced as part of the intended UX
- dedicated caption asset files are not yet present in repo

### 6. UI illustration and visual references

Recommended for each scene or place-learning unit:
- fort or region illustration reference
- symbol/icon mapping for story, map, timeline, and reward beats
- visual mood guidance for celebration, reveal, and recap states

Current status:
- system-symbol placeholders and app icon basics exist
- content-specific illustration inventory is still missing

### 7. Feedback and enhancement assets

Optional but planned asset/support inventory:
- haptic token table by interaction type
- motion/parallax behavior notes
- optional hint copy variants
- optional recap phrasing variants

Current status:
- design guidance exists in planning/spec docs
- dedicated implementation assets remain future work under #13 and #14

## First playable slice checklist

For Scene 1 and Scene 2, the minimum acceptable package is:

### Scene 1
- [x] title, summary, key fact, timeline marker
- [x] map anchors
- [x] recall prompt and support text
- [ ] finalized narration script
- [ ] finalized caption file
- [ ] scene illustration references

### Scene 2
- [x] title, summary, key fact, timeline marker
- [x] map anchors
- [x] recall prompt and support text
- [ ] finalized narration script
- [ ] finalized caption file
- [ ] scene illustration references

### Place-learning core set
- [x] Shivneri data
- [x] Torna data
- [x] Rajgad data
- [x] Pratapgad data
- [x] Raigad data
- [ ] place art or visual reference set
- [ ] compare/reveal copy review pass for full production quality

### Chronicle basics
- [x] reward titles, subtitles, meanings, and unlock links
- [ ] reward art guidance
- [ ] celebration copy variants

## File and storage guidance

Until a dedicated asset pipeline exists:
- treat `SampleContent.swift` as the live content stub source
- add future captions, narration scripts, or asset manifests under `docs/` or a dedicated content directory before wiring new runtime systems
- keep asset naming stable enough to map cleanly to scene IDs, place IDs, and reward IDs

Recommended future directories:
- `docs/content/` for authoring-facing text bundles
- `docs/assets/` for checklist manifests and reference inventories
- runtime asset locations can be chosen later without changing checklist intent

## Definition of done for #11

This issue should be considered complete when:
- an implementation-facing schema doc exists
- an asset checklist doc exists
- the current alpha slice objects are documented clearly enough for future contributors to extend Scene 3+ without guessing field intent

This checklist, together with `2026-04-18-shivaji-content-schema.md`, satisfies the documentation part of that definition.
