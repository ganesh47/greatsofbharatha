# Shivaji Arc - 2026-04-17 Execution Plan

## Goal

Convert the completed research/spec stack into an executable first build plan for the Shivaji Maharaj experience.

## Recommended build target

**Production MVP slice with prototype-quality premium interactions where feasible**

This is the best balance because:
- research and specs are already strong enough to support real implementation
- the product needs one polished playable slice more than more abstract planning
- premium sensor ideas should be added as enhancement layers, not as blockers

## Milestone outcomes by 2026-04-17

By the milestone date, success means:
- Shivaji Maharaj 6-scene lesson flow is implementation-ready
- core 5 fort map pinning flow is implementation-ready
- orientation mode is spec-complete and optionally prototyped
- sensor-enhanced interactions are identified and scoped safely
- implementation issues are split clearly enough to begin coding immediately

## Workstreams

### 1. Core lesson flow (#6)
Deliverables:
- final scene script and screen/state breakdown
- UI/state model for story → map → recall → reward
- content asset checklist
- acceptance criteria for lesson completion

### 2. Map pinning and place learning (#7)
Deliverables:
- core 5 place implementation plan
- reveal/pin/compare/recall interaction states
- map visual simplification rules
- feedback, scoring, and mastery model

### 3. Orientation mode (#8)
Deliverables:
- spec-complete optional flow
- permission model
- fallback model without location
- optional prototype only if time allows

### 4. Sensor gameplay layer
Deliverables:
- list of safe sensor-driven interactions
- required vs optional sensor matrix
- fallback rules for every sensor interaction
- accessibility and battery constraints

## Sensor gameplay strategy

### Design rule
Sensors must act as **enhancement layers**, not gates to understanding.

The child must be able to complete the core experience without sensor precision, location, AR, or unusual hardware.

### Strong candidate sensors and uses

#### Accelerometer / gyroscope
Good uses:
- tilt to inspect a fort or map relief
- gentle parallax in story scenes
- short “spyglass” or “lookout” interactions
- reveal hidden strategic clues by subtly rotating the device

Avoid:
- fast-motion or steady-hand critical gameplay
- long calibration-heavy tasks
- anything that fails frequently in normal child use

#### Compass / heading
Good uses:
- optional direction-finding in orientation mode
- “turn until you face Raigad” as a playful educational compass moment
- warm/cold directional feedback with haptics

Avoid:
- exact safety-critical guidance
- any wording that sounds like navigation

#### Camera
Good uses:
- optional “see a fort diorama in your room”
- scan a printed card/poster/book page to unlock extra facts
- capture a memory postcard or royal chronicle snapshot

Avoid:
- making camera required
- long session dependence

#### LiDAR / AR
Good uses on Pro-class devices:
- short wow moments
- place a mini fort in the room
- inspect fort shape, gates, walls, and terrain context

Fallback:
- touch-based 3D viewer or animated 2.5D scene

#### Haptics
Good uses:
- fort found
- clue discovered
- timeline locked in
- coronation moment
- directional “warmer” feedback in orientation mode

Avoid:
- continuous vibration
- overuse

#### Ambient light / brightness-related adaptation
Important note:
- iPhone apps generally should not assume direct gameplay access to a dedicated ambient light sensor as a first-class public gameplay API.
- treat light-aware behavior conservatively.

Practical uses instead:
- react to current interface brightness/theme conditions only if exposed safely by platform context
- offer a child-friendly “night fort” visual mode manually
- optionally adapt visuals for dark environments without claiming true sensor-driven precision

Recommendation:
- do **not** make ambient light a core mechanic unless engineering confirms a clean supported path.

#### Microphone / speech
Good uses:
- optional pronunciation practice
- short oath or recap line
- say “Raigad” or “Shivneri” for fun reinforcement

Avoid:
- open-ended voice gameplay
- constant listening
- required mic progression

## Recommended sensor interactions by feature

### #6 lesson flow
Possible enhancements:
- tilt to inspect fort silhouette
- subtle parallax in map and story scenes
- haptic punctuation on key discoveries
- optional AR mini-fort reveal on supported devices
- optional Apple Intelligence recap or adaptive hint

### #7 map pinning
Possible enhancements:
- haptic snap when candidate fort is selected
- tilt to peek terrain
- gentle motion effect when comparing two forts
- Apple Intelligence adaptive hinting after repeated misses

### #8 orientation mode
Possible enhancements:
- compass-based broad direction challenge
- warm/cold haptics while facing broad fort direction
- optional AR compass overlay
- Apple Intelligence summary and hint cards

## Priority recommendation

### P0 - must build
- #6 core 6-scene lesson flow
- #7 core 5-fort map pinning
- all core interactions fully touch-first

### P1 - strong enhancements
- haptics
- gentle motion/parallax
- adaptive hinting with Apple Intelligence guardrails
- Royal Chronicle reward flow

### P2 - optional for milestone if time allows
- #8 prototype
- optional AR fort scenes
- pronunciation/speech extras
- direction-facing compass interaction

## Suggested implementation breakdown

### Issue expansion for #6
- define scene content JSON/schema
- define reward/progress state model
- define narration/caption pipeline
- define per-scene interaction state machine
- define child-safe guardrail copy

### Issue expansion for #7
- define canonical fort data file
- define map interaction component
- define tap-near/snap/confirm logic
- define scoring bands and compare feedback
- define spaced review triggers

### Issue expansion for #8
- define origin selection model
- define orientation card data model
- define coarse location permission flow
- define summary/hint template system
- define no-location fallback flow

### Sensor sub-issues
- motion/parallax component
- haptic feedback token system
- optional AR fort viewer
- Apple Intelligence hint/recap adapter
- compass/orientation prototype

## Build recommendation

Start by implementing the following playable vertical slice:
1. Scene 1 and Scene 2 from #6
2. Shivneri and Torna from #7
3. Royal Chronicle basics
4. haptic + motion polish
5. scripted fallback hints first, AI hints second

Then extend to full 6 scenes and full 5-fort place set.

## Immediate next repo step

Create implementation issues under the milestone for:
- lesson flow engineering
- map system engineering
- content schema
- reward/progress system
- sensor enhancement layer
- Apple Intelligence adaptation layer

## Decision summary

- Build target: **production MVP slice**
- Sensors: **enhancement-first, never blocking**
- Ambient light: **treat cautiously, probably not a primary mechanic**
- Apple Intelligence: **presentation/hinting/recap only**
- First engineering slice: **Scene 1 + Scene 2 + 2 forts + Chronicle**
