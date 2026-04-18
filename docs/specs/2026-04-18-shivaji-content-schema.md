# Shivaji content schema

- Status: Draft
- Linked issue: #11
- Milestone: Shivaji Arc - 2026-04-17
- Owner: @ganesh47
- Last updated: 2026-04-18

## Problem

The playable Shivaji alpha already uses concrete Swift models for scenes, places, recall prompts, and Chronicle rewards, but the repo does not yet have a dedicated implementation-facing schema doc that explains the canonical fields and how they fit together.

Without that layer, future content expansion risks drifting between code-only assumptions and planning docs.

## Goals

- define the canonical content objects required by the current Shivaji slice
- document the fields engineering must provide for scenes, places, rewards, and recall prompts
- make the schema understandable even before content is externalized from Swift sample data
- align docs with the currently shipped app models

## Non-goals

- define a final JSON file format or parser implementation
- lock the repo into one persistence or serialization strategy
- redesign the current alpha data model from scratch

## Users / stakeholders

- product and design contributors adding new Shivaji content
- engineers expanding the SwiftUI slice beyond Scene 1 and Scene 2
- future contributors externalizing content from `SampleContent.swift`

## Scope

This schema covers the content needed for the current lesson, map, and Chronicle experience:

- arc container
- story scenes
- places
- Chronicle rewards
- recall prompts
- related enums used for progression and presentation

## Canonical objects

### `AppContent`

Top-level container for one hero arc.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `arcTitle` | `String` | yes | Display name for the arc, for example `Shivaji Arc` |
| `scenes` | `[StoryScene]` | yes | Ordered scene list for the playable lesson flow |
| `places` | `[Place]` | yes | Full place set available to story and map flows |
| `rewards` | `[ChronicleReward]` | yes | Reward inventory for Chronicle unlocking |

Derived helper:
- `corePlaces` filters `places` to the first-release place-learning set where `isCoreReleasePlace == true`

### `StoryScene`

Represents one story-map-timeline lesson unit.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `String` | yes | Stable scene identifier, for example `scene-1-shivneri` |
| `number` | `Int` | yes | Human-facing scene order |
| `title` | `String` | yes | Scene heading shown in lesson UI |
| `narrativeObjective` | `String` | yes | Internal-facing statement of what the scene teaches |
| `keyFact` | `String` | yes | Core truth the child should remember |
| `childSafeSummary` | `String` | yes | Age-appropriate scene summary |
| `mapAnchors` | `[String]` | yes | Places or regions surfaced during map reveal |
| `timelineMarker` | `String` | yes | Short timeline label |
| `interactionSteps` | `[String]` | yes | Ordered interaction beats for the scene |
| `recallPrompt` | `RecallPrompt` | yes | Retrieval-practice prompt tied to the scene |
| `rewardID` | `String` | yes | Identifier of the reward highlighted after completion |

Authoring rules:
- `id` must be unique within the arc
- `number` should reflect intended chronological order
- `rewardID` must resolve to an existing `ChronicleReward.id`
- `mapAnchors` should stay child-legible and place-based, not overloaded with dense tactical detail

### `RecallPrompt`

Small retrieval-practice unit used at the end of a scene.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `question` | `String` | yes | Child-facing prompt |
| `answer` | `String` | yes | Canonical correct answer |
| `supportText` | `String` | yes | Helpful explanation shown after submission |

Authoring rules:
- prompts should reinforce one stable historical truth
- support text should help learning, not merely mark right or wrong
- answer phrasing should stay close to the visible choice text used in UI

### `Place`

Represents one historical place surfaced in map and place-learning flows.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `String` | yes | Stable identifier, for example `place-raigad` |
| `name` | `String` | yes | Human-facing place name |
| `memoryHook` | `String` | yes | Short mnemonic phrase like `Birth Fort` |
| `primaryEvent` | `String` | yes | Main story event linked to the place |
| `whyItMatters` | `String` | yes | Child-friendly meaning statement |
| `regionLabel` | `String` | yes | Broad geographic framing |
| `latitude` | `Double` | yes | Educational coordinate for map placement |
| `longitude` | `Double` | yes | Educational coordinate for map placement |
| `progress` | `PlaceProgress` | yes | Default or sample progress state |
| `isCoreReleasePlace` | `Bool` | yes | Whether the place is in the first-release core set |

Authoring rules:
- `memoryHook` should be short enough to function as a reusable recall label
- `regionLabel` should prefer broad orientation over precision-heavy navigation language
- coordinates are for educational placement, not turn-by-turn travel

### `ChronicleReward`

Represents one collectible meaning-bearing reward in the Royal Chronicle.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | `String` | yes | Stable reward identifier |
| `title` | `String` | yes | Reward title shown in Chronicle |
| `subtitle` | `String` | yes | Reward type or flavor label |
| `meaning` | `String` | yes | What the reward teaches or symbolizes |
| `unlockedBySceneID` | `String` | yes | Scene gate for unlocking |
| `mastery` | `MasteryState` | yes | Minimum mastery associated with the reward |
| `category` | `RewardCategory` | yes | Presentation grouping |

Authoring rules:
- `unlockedBySceneID` must resolve to an existing `StoryScene.id`
- rewards should communicate meaning, not generic gamified currency
- titles and subtitles should be readable by children and useful in recap UI

## Supporting enums

### `PlaceProgress`

Current values:
- `locked`
- `readyToLearn`
- `reviewed`
- `masteredLightly`

Meaning:
- these represent child-facing place familiarity states in the map flow

### `RewardCategory`

Current values:
- `storyCard`
- `emblemFragment`
- `leadershipBadge`

Meaning:
- these group Chronicle rewards for display and tone, not monetization or rarity systems

## Relationship constraints

- every `StoryScene.rewardID` must match one `ChronicleReward.id`
- every `ChronicleReward.unlockedBySceneID` must match one `StoryScene.id`
- `AppContent.scenes`, `AppContent.places`, and `AppContent.rewards` should each use unique IDs internally
- first-release place-learning should use the subset where `Place.isCoreReleasePlace == true`

## Current source of truth

The live implementation currently expresses this schema in:
- `GreatsOfBharatha/Shared/Models/ContentModels.swift`
- `GreatsOfBharatha/Shared/Models/SampleContent.swift`

This doc should stay aligned with those files until content is externalized.

## Delivery notes

- treat this as the canonical schema reference for the current alpha slice
- if content later moves to JSON, plist, or another source, keep the field set semantically aligned with this document
- add new objects here before widening the content system in code
