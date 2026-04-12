# Shivaji educational orientation mode

- Status: Draft
- Linked issue: #8
- Milestone: Shivaji Arc - 2026-04-17
- Owner: @ganesh47
- Last updated: 2026-04-12

## Purpose

Define the optional educational orientation mode for Shivaji Maharaj historical places in Greats of Bharatha.

This feature should help children understand where important Shivaji places sit relative to their broad area and region, without becoming a navigation product.

## Product identity

This is a **history orientation layer**, not a travel planner.

The correct product sequence is:

**story understanding → place recognition/pinning → broad orientation**

not:

**story understanding → navigation**

## Product goal

Teach children:
- broad direction to a fort from a chosen origin
- rough distance bands
- major region or city anchors
- terrain/region context
- why the place matters in Shivaji Maharaj’s story

This mode should help answer:
- “Is Shivneri north or south of me?”
- “Is Raigad nearer the coast side or inland?”
- “What big city or region helps me understand where Pratapgad is?”
- “Why does this fort matter?”

It should not answer:
- exact road-by-road directions
- turn-by-turn movement
- precise ETA or meters
- “go there now” prompts

## Scope position

This feature is:
- **P2**
- optional
- non-MVP-blocking
- layered on top of #7 place learning

It depends conceptually on:
- #6 canonical lesson flow
- #7 core 5 place canon

## Audience

Primary age band:
- **8 to 11**

Design assumptions:
- children learn better through direction, comparison, and story-linked place meaning than precision-heavy route detail
- orientation should build mental maps, not outsource thinking

## Canonical place set

For first release, orientation mode must align with the #7 core 5 places only:
- Shivneri
- Torna
- Rajgad
- Pratapgad
- Raigad

Do not expand #8 first release beyond this core 5.

Purandar and Sinhagad remain secondary content unless added in a later phase.

## Product thesis

Best mode framing:

**Story Compass**

The child should feel:
- oriented
- curious
- safe
- informed

The child should not feel:
- instructed to travel
- tracked
- pushed into real-world movement

## Core mode structure

### 1. Orientation entry card
Entry points:
- from a place detail card in #7
- from review surfaces
- from a parent-enabled exploration card

Shows:
- fort name
- memory hook
- one-line promise

Suggested CTA text:
- `Learn where this fort is from your area`
- `Choose a city to compare`
- `See broad direction`

### 2. Parent/location consent sheet
Required before current-area orientation.

Must explain:
- location is optional
- broad area is enough
- this is for learning orientation only
- this is not live navigation

Actions:
- `Use my current area`
- `Choose a city instead`
- `Not now`

### 3. Origin selection screen
Fallback and manual entry path.

Allow:
- major city selection
- regional selection
- previously used origin

V1 should prefer simple curated origins rather than open-ended full search.

### 4. Broad route overview screen
Core screen.

Shows:
- origin area
- destination fort
- broad directional relationship
- approximate distance band
- 2 to 4 major city/town/region anchors at most
- one terrain note

Example output style:
- `Raigad is southwest of Pune.`
- `This journey moves from inland plateau toward the western hill-coast region.`
- `Approximate distance: farther away.`

### 5. Learn-the-route card stack
Card types:
- direction card
- distance card
- waypoint/region card
- terrain card
- why-this-place-matters card

This keeps the feature educational and modular.

### 6. Light recall challenge
Use low-pressure prompts such as:
- Which direction would you travel from Pune to reach Raigad?
- Which fort is farther south?
- Which place is closer to the coast side?
- Which city helps orient Pratapgad?

### 7. Summary and return screen
Shows:
- what was learned
- fort meaning reminder
- return path to #7 place learning or another orientation card

Do not include a child-facing `Start navigation` action.

## Core user flows

### Flow A. Place-first orientation
1. child learns a fort in #7
2. taps orientation entry
3. parent/location consent appears
4. child uses current coarse area or selected city
5. broad orientation appears
6. child completes 1 to 3 learning cards
7. optional recall prompt
8. returns to place learning or review

### Flow B. Manual city comparison
1. child chooses `Choose a city instead`
2. selects a city such as Pune
3. views broad orientation to one of the core forts
4. completes one direction or region prompt
5. returns to the fort card

### Flow C. No-location fallback
1. child declines permission
2. app defaults to manual city selection or example origins
3. full educational value remains available

## What to show

### Direction model
Use only broad directional language:
- north
- south
- east
- west
- north-east
- south-west
- toward the coast
- inland

### Distance model
Use rough educational bands only.

Suggested examples:
- very near
- near
- farther
- full-day journey away

Alternative more neutral bands:
- short trip
- medium trip
- long trip

Do not use exact road distance as the default child-facing output.

### Region and waypoint model
Use only a small number of orienting anchors:
- major city
- region label
- terrain cue

Examples:
- near Junnar
- near Mahabaleshwar
- near Mahad
- in the Sahyadri hills
- toward the Konkan side

## What not to show

Do not include:
- turn-by-turn directions
- exact route instructions
- live rerouting
- ETA promises
- exact child location dot in the main child flow
- road names as a primary teaching surface
- “start trip now” framing
- nearby businesses, transport hubs, or unrelated POIs

## Safety and privacy model

### Permission model
Use progressive permission requests only when needed.

#### Default
- no location permission on first launch
- allow static learning and manual origin selection without permission

#### Current-area mode
- request **When In Use** only
- do not request Always location
- design for coarse/approximate location first

#### Camera/AR
- request only if entering optional AR/camera mode
- never required for core orientation learning

#### Motion
- only if a compass or heading feature is explicitly activated
- avoid requiring motion permission for the main learning value

### Privacy rules
- coarse location preferred
- no background tracking
- no persistent exact route history
- no child-to-child sharing
- no social comparison
- no hidden location collection

### Child-facing safety wording
Use wording like:
- `This shows a broad direction.`
- `Ask an adult before going anywhere.`
- `Maps and location can be approximate.`

Avoid wording like:
- `This will guide you safely there.`
- `Walk this way now.`
- `You are exactly X meters away.`

## Apple Intelligence strategy

Apple Intelligence may be used only as a **curated-content enhancer**, never as a source of history or navigation truth.

### Good uses
- age-banded summaries of a place
- adaptive hints when a child misses a direction question
- short recap phrasing after an orientation session
- supportive encouragement using approved facts

### Not allowed
- live navigation decisions
- unrestricted historical generation
- place/event canon changes
- externalizing exact child location into open-ended LLM flows
- freeform route advice that could be read as safety guidance

### Safe Apple Intelligence examples
- `Today you learned that Raigad is southwest of Pune and became Shivaji Maharaj’s coronation capital.`
- `Want a hint? Think about the western hills.`
- `You remembered the birth fort. Now try the coronation fort.`

### Fallback
If Apple Intelligence is unavailable:
- use scripted summary templates
- use rule-based hinting
- preserve full learning value

## iPhone capability strategy

### Core on all supported iPhones
- static and lightly interactive maps
- manual origin selection
- broad directional output
- light haptics
- accessibility support
- no-location fallback

### Standard enhanced mode
- approximate current-area orientation using When In Use location
- optional heading or compass cues
- haptic warm/cold directional feedback

### Premium optional enhancements
- richer visual polish on Pro-class devices
- optional camera/AR exploratory overlays
- smoother compass/heading feedback
- Apple Intelligence recap/hint surfaces where supported

### Must not be required
- exact GPS precision
- AR
- camera
- Apple Intelligence
- background services
- Pro-only hardware

## Interaction guidelines

- use calm maps with low label density
- use one main educational idea per screen
- keep labels child-readable
- prefer broad arrows and region shapes over roads
- allow single-thumb use where possible
- do not overload the child with too many cities or waypoints at once

## Data model

### Destination fort data
Reuse #7 fort canon:
- id
- name
- memory hook
- primary event
- educational pin coordinate
- region label
- terrain label

### Origin data
For V1:
- origin type: coarse current area or selected city
- city/region label
- coarse coordinate or curated centroid

### Orientation lesson data
- broad cardinal direction
- rough distance band
- broad route line or connection
- major anchors, max 2 to 4
- terrain note
- recall prompts
- safety copy

## Acceptance criteria

The feature is correct when:

1. It covers only the #7 core 5 places:
- Shivneri
- Torna
- Rajgad
- Pratapgad
- Raigad

2. It is clearly framed as:
- educational orientation
- broad route understanding
- not navigation

3. A child can complete it without location permission.

4. If location is used, the app:
- requests it clearly
- explains why
- works with coarse area
- does not require exact persistent tracking

5. The route overview includes only:
- approximate direction
- approximate distance band
- major anchors
- terrain or regional context

6. The feature includes at least:
- one overview screen
- one card explanation layer
- one light recall interaction
- one return path to #7 place learning

7. It never includes:
- turn-by-turn directions
- exact live rerouting
- travel urgency
- social location features

8. A child can finish and answer at least:
- which direction the fort lies from an origin
- roughly how far it is
- one region or waypoint clue
- why the fort matters historically

9. The feature stays optional and does not block #6 or #7 completion.

## Deferred scope

Do not include in V1:
- road-level navigation
- external navigation handoff from child flow
- ETA
- multi-stop journeys
- route comparisons across many origins
- exact trekking or ascent guidance
- live travel mode
- background widgets for travel
- expansion beyond core 5 until the canon is stable

## Short spec line

Issue #8 should ship, if at all in early form, as an optional history orientation layer that teaches broad direction, rough distance, and regional context to the core 5 Shivaji places without becoming a navigation feature.
