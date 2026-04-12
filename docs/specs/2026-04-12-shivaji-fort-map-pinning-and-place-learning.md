# Shivaji fort map pinning and place learning

- Status: Draft
- Linked issue: #7
- Milestone: Shivaji Arc - 2026-04-17
- Owner: @ganesh47
- Last updated: 2026-04-12

## Purpose

Define the first-release map pinning and place-learning system for Shivaji Maharaj in Greats of Bharatha.

This feature should teach children to recognize, place, compare, and remember the core forts and locations in the Shivaji Maharaj arc.

It is a **place-learning feature**, not:
- a navigation app
- a freeform map sandbox
- a route-replay system

## Product thesis

The canonical loop is:

**Reveal → Recall → Compare → Connect → Retry**

In practical terms:
- learn the place
- guess the place from memory
- compare guess to truth
- connect place to event
- revisit later for retention

This feature supports the wider product loop:

**story → place → time → meaning → recall → revisit**

## Audience

Primary age band:
- **8 to 11**

The experience should be:
- forgiving
- spatially clear
- low on fine-motor demands
- memory-building rather than score-chasing

## Canonical first-release scope

### Mandatory core 5 place set

These 5 places are the only mandatory exact-pin places in first release:
- **Shivneri** = Birth Fort
- **Torna** = First Big Fort
- **Rajgad** = Early Capital
- **Pratapgad** = Turning Point
- **Raigad** = Coronation Capital

### Secondary-only contextual places

These should not be mandatory first-release pin targets:
- **Purandar**
- **Sinhagad**

Use them only as:
- contextual story support
- optional review content
- expansion content after core 5 mastery

## What this feature should be

A focused system with 4 main states:

1. **Places Hub**
2. **Place Learn**
3. **Pin Challenge**
4. **Mixed Recall / Review**

Do not add route-learning, dense timeline mechanics, or large free-exploration map complexity into #7.

## Best interaction model

Use:

**tap-near → snap → confirm**

Do not use tiny precision dragging as the primary interaction.

### Recommended placement flow
1. child taps broadly on the map
2. nearest eligible place within tolerance becomes candidate
3. candidate pin magnetically snaps
4. gentle haptic confirms candidate
5. bottom card offers:
   - confirm
   - retry
   - hear clue

This preserves the feeling of placement while removing motor frustration.

## Core screens and states

### 1. Places Hub

Purpose:
- show all 5 core forts
- communicate progress and readiness

Each fort card should show:
- fort icon
- memory hook
- progress state

Suggested states:
- Locked by story
- Ready to learn
- Reviewed
- Mastered lightly

### 2. Place Learn screen

Purpose:
- introduce one fort at a time with region context
- establish one stable memory link per fort

Display:
- simplified Maharashtra / Sahyadri map
- fort card with name
- one primary event
- one why-it-matters sentence
- one memory hook

### 3. Pin Challenge screen

Purpose:
- ask the child to place the fort from memory

Behavior:
- map stripped down for recall
- broad tap areas
- generous snapping radius
- non-punitive directional feedback

### 4. Mixed Recall / Review

Purpose:
- spaced retrieval across multiple forts

Prompt types:
- pin the fort
- match event to place
- choose the fort from a clue
- relative direction comparison

## Place-learning loop per fort

For each fort, use this sequence:

### 1. Orient
Show region context first.
Ask:
- “Where do you think Shivneri is?”
- “Can you find the coronation fort?”

### 2. Pin from memory
Child taps or places a pin.
Use generous tolerance.

### 3. Reveal
Show true fort marker.
Animate child guess to true location comparison.

### 4. Compare
Show:
- guessed point
- correct point
- short line between them
- one directional clue

### 5. Meaning unlock
After reveal, display:
- fort name
- memory hook
- primary event
- why it mattered

### 6. Immediate recall
Ask one fast follow-up question.

### 7. Later recall
Bring the place back later in-session and in future reviews.

## Difficulty ramp

### Stage 1. Learn mode
- one place at a time
- broad highlighted region
- event clue visible
- unlimited retries
- large success radius

### Stage 2. Guided recall
- no highlight
- compass-style hinting
- event clue fades after first attempt
- medium success radius

### Stage 3. Mixed recall
- all 5 places in one pool
- fewer clues
- compare feedback after first try
- relative location prompts appear

### Stage 4. Mastery
- pin from memory with minimal hints
- no harsh time pressure
- mix place-to-event, event-to-place, and relative position prompts

## Directional feedback model

Best child-readable system:
- north / south / east / west language
- directional arrow
- warmth band:
  - far
  - getting closer
  - very close

Examples:
- “A little west”
- “Too far south”
- “Very close”
- “Good try, this fort is farther west in the Sahyadris”

Avoid:
- exact coordinates
- dense geographic prose
- hard fail-state language

## Scoring and confidence model

Use a 3-band placement model:
- **Perfect**
- **Great find**
- **Good try**

This is better than right/wrong only.

The product should celebrate improvement and comparison learning, not just first-try accuracy.

## Canonical place-to-event links

Each core place should have one primary stable memory link.

### Shivneri
- memory hook: `Birth Fort`
- primary event: birth of Shivaji Maharaj
- why it matters: story begins here

### Torna
- memory hook: `First Big Fort`
- primary event: early breakthrough, start of Swarajya
- why it matters: first major fort success

### Rajgad
- memory hook: `Early Capital`
- primary event: early power center and planning base
- why it matters: growth and consolidation

### Pratapgad
- memory hook: `Turning Point`
- primary event: major turning point in Shivaji Maharaj’s rise
- why it matters: strategy and terrain mattered

### Raigad
- memory hook: `Coronation Capital`
- primary event: coronation as Chhatrapati
- why it matters: sovereign climax of the arc

## Secondary content handling

### Purandar
Use as:
- story support for pressure and difficult compromise
- optional mixed-review card
- advanced places unlock after core 5

Do not make mandatory in first-release exact pinning.

### Sinhagad
Use as:
- review or expansion content
- comeback / later-era context card
- optional place after core 5 completion

Do not make mandatory in first-release exact pinning.

## Map design rules

- use a heavily simplified regional map
- keep only child-useful labels
- support single-thumb play where possible
- avoid dense contour detail
- avoid tiny targets
- keep UI chrome away from active touch zones
- use progressive zoom instead of requiring precision pinch work
- if sites are close, use expanded candidate selection rather than demanding repeated tiny taps

## Suggested canonical educational pins

These should be treated as canonical educational centers for V1:
- Shivneri: `19.1990, 73.8595`
- Torna: `18.2761, 73.6227`
- Rajgad: `18.2460, 73.6822`
- Pratapgad: `17.9362, 73.5776`
- Raigad: `18.2335, 73.4406`

Secondary-only:
- Purandar: `18.2808, 73.9736`
- Sinhagad: `18.3657, 73.7553`

These are educational pins, not detailed fortress polygons or gate-level maps.

## Apple Intelligence strategy

Apple Intelligence should be used only as a **curated-content enhancer**, never as a source of historical truth.

### Good uses
- adaptive hints after repeated misses
- personalized difficulty tuning
- recap phrasing after a session
- supportive encouragement tied to approved content

### Not allowed
- inventing place facts
- rewriting historical canon
- generating new contested claims
- changing answer sets or canonical place-event links

### Safe Apple Intelligence examples
- “You keep mixing up Rajgad and Raigad. Want a quick clue?”
- “Today you learned the birth fort and the coronation fort.”
- “Let’s try the turning-point fort again with a hint.”

## Sensor and device strategy

### Core on all supported iPhones
- 2D map interaction
- tap-to-snap candidate placement
- layered visual feedback
- light haptics
- voice support
- accessibility support
- offline-capable place-learning

### Enhanced where available
- subtle motion/parallax
- terrain peek effect
- optional camera or AR reveal mode
- richer transitions and polish on Pro-class devices

### Must not be required
- AR for basic play
- continuous motion control
- exact gyro control
- location permission
- camera permission

## Accessibility

- large touch targets
- generous snap radius
- no color-only encoding
- VoiceOver labels for place cards and confirm actions
- reduced motion mode disables parallax and bounce
- captions or read-aloud support for clue text where needed
- non-timed default flow

## Acceptance criteria

The feature is correct when:

1. It includes exactly the 5 mandatory core places:
- Shivneri
- Torna
- Rajgad
- Pratapgad
- Raigad

2. Each core place supports:
- learn view
- pin challenge
- reveal and compare feedback
- primary event link
- memory hook

3. Wrong guesses receive:
- encouraging feedback
- directional guidance
- visible comparison to truth
- no harsh fail language

4. Mixed recall includes at least:
- one pin-from-memory task
- one event-to-place match
- one clue-to-fort prompt

5. A child can leave the first session knowing:
- Shivneri = birth place
- Torna = first big fort
- Rajgad = early capital
- Pratapgad = turning point
- Raigad = coronation capital

6. Purandar and Sinhagad appear only as:
- contextual support
- optional review / expansion content
- non-blocking content

7. The feature teaches:
- place identity
- rough relative position
- fort-event meaning
and does not require:
- route mastery
- navigation logic
- exact geospatial precision

## Short spec line

Issue #7 should ship a focused 5-fort place-learning system where children learn, pin, reveal, compare, and recall Shivneri, Torna, Rajgad, Pratapgad, and Raigad, while Purandar and Sinhagad remain secondary contextual content.
