# Main UX iteration spec

- Status: Draft
- Linked issue: #30
- Milestone: Shivaji Arc
- Owner: @ganesh47
- Last updated: 2026-04-19

> Reset note (2026-04-30): #126 supersedes this as the main gameplay direction. Treat this document as pre-reset UX exploration unless a later #126 implementation spec explicitly reuses a pattern.

## Problem

The latest successful `iOS UI Review (main)` CI artifact run on `main` shows that the product direction is coherent, but the current UX still reads as a careful prototype rather than a compelling child-learning experience.

The current build has a clear information architecture and a thoughtful educational model, but the most important user-facing flows underperform in emotional pull, clarity of progression, map distinctiveness, and reward delight.

The most important gaps observed in the main artifacts are:
- the home screen feels like a curriculum dashboard rather than an adventure entry point
- the lesson flow is organized but too text-heavy and not vivid enough
- the place-learning experience does not yet feel like meaningful geographic discovery
- the Chronicle reward moment is structurally clear but emotionally weak
- prototype and debug framing are still visible in capture states and product copy

## Goals

- make the first-run and return-user flow feel like a journey, not a static syllabus
- make the lesson experience more vivid, easier to parse, and more motivating for children
- make place-learning feel like a differentiating product strength rather than a supporting card stack
- make Chronicle rewards feel collectible and meaningful
- reduce prototype language, debug leakage, and internal framing in user-visible surfaces
- preserve the current product strengths: calm aesthetic, educational clarity, and low-anxiety progress framing

## Non-goals

- full visual redesign of the entire app brand system
- expansion beyond the current Shivaji vertical slice
- adding large new content arcs before the core loop feels strong
- building full route-learning mode in this iteration
- adding dense animation systems that increase fragility before the core UX is sound

## Users / stakeholders

### Primary user
- children learning Shivaji Maharaj through story, place, and memory anchors

### Secondary user
- parents or evaluators who need to feel that the experience is educationally grounded, safe, and purposeful

### Internal stakeholders
- product/design execution owners
- iOS implementation owners
- content and curriculum owners
- CI artifact reviewers using main-branch UX capture

## Scope

This iteration covers the highest-leverage UX improvements visible in the current main CI artifact flow:
- Learn home
- scene lesson flow, starting with Scene 1 and shared lesson components
- Places Hub
- place detail and fort challenge interaction
- Chronicle unlock and collection flow
- copy cleanup across the slice
- CI UX capture improvements where needed to better represent the intended user experience

Out of scope for this iteration unless required by implementation:
- new historical scenes beyond the current slice
- deep map engine work beyond what is needed to materially improve place learning
- account systems, persistence expansion, or cross-device syncing

## UX / product behavior

### 1. Home should feel like a clear journey start

Current issue:
- the home screen is orderly but static
- the page lacks one obvious primary action
- copy such as `First playable lesson slice` reads like internal prototype language

Required behavior:
- the top of home should present one clear next action such as `Start Scene 1` or `Continue journey`
- the hero should communicate arc, progress, and next step with stronger emotional pull
- scene cards should scan faster, with less body copy and stronger action cues
- internal or prototype-oriented copy should be removed from child-facing UI

Acceptance direction:
- a first-time user can identify what to do next in under a few seconds
- the first screen feels like the beginning of an adventure, not a content index

### 2. Lesson flow should be more vivid and less text-burdened

Current issue:
- lesson structure is good, but the experience feels flat and worksheet-like
- card content truncates in artifact capture
- controls compete for attention too early

Required behavior:
- the active story card should feel like the focus of the screen
- progression through the scene should be visually obvious and emotionally paced
- copy per step should be reduced or redistributed so the user is not asked to read long blocks before doing anything
- disabled or low-value controls should be minimized at the top of the flow
- status language should feel motivating rather than administrative

Acceptance direction:
- the scene is understandable as a sequence of small, satisfying steps
- the card area no longer looks cramped or obviously truncated
- the first-time lesson path feels guided and alive

### 3. Place learning should feel like a real product strength

Current issue:
- the current map preview is too abstract to feel like a meaningful map
- spatial learning is implied more than delivered
- the challenge loop risks feeling like text recognition instead of geographic memory

Required behavior:
- the place view should communicate clearer spatial relationships among forts
- the map or place board should feel tangible enough to support memory and comparison
- challenge interactions should emphasize locating, comparing, or placing, not just selecting from text rows
- the current place should stand out, while nearby alternatives should still be legible and distinct

Acceptance direction:
- reviewers can clearly say the user is learning places, not merely reading place facts
- the place screen becomes one of the strongest and most differentiated screens in the slice

### 4. Chronicle should feel collectible and rewarding

Current issue:
- the reward flow is understandable but emotionally soft
- the unlock moment feels like a list update, not a meaningful collection event
- explanatory rationale copy is too prominent in the user experience

Required behavior:
- a newly unlocked reward should be visually and emotionally distinct from the catalog view
- the collect moment should feel ceremonial enough to reward progress
- unlocked items should feel like keepsakes or trophies rather than flat list rows
- philosophy or meta copy about grading anxiety should be de-emphasized in the core child flow

Acceptance direction:
- the unlock moment feels worth reaching
- the Chronicle reads as a collection space, not just a storage list

### 5. Copy and framing should separate product voice from internal rationale

Current issue:
- several surfaces still expose internal framing, debug states, or implementation-era language

Required behavior:
- remove user-visible prototype/debug language from normal product states and CI capture outputs where feasible
- prefer direct child-facing and parent-safe phrasing over internal product descriptions
- keep educational seriousness, but reduce self-conscious explanation inside the main flow

Acceptance direction:
- the captured UX reads as intentional product, not an internal demo build

## Technical notes

Likely implementation areas:
- `GreatsOfBharatha/Features/Lesson/LessonHomeView.swift`
- `GreatsOfBharatha/Features/Lesson/SceneLessonView.swift`
- `GreatsOfBharatha/Features/Map/PlacesHubView.swift`
- `GreatsOfBharatha/Features/Chronicle/ChronicleView.swift`
- supporting content and copy in `Shared/Models/SampleContent.swift`
- capture-specific presentation in `App/CaptureRootView.swift` and related capture flow only if needed for artifact realism

Implementation guidance:
- prefer stronger layout, hierarchy, and interaction changes before introducing complex animation systems
- use CI artifact capture on `main` as the product review surface for before/after evaluation
- preserve accessibility and readable contrast while increasing visual emphasis and delight
- avoid shipping purely cosmetic churn that does not strengthen comprehension, motivation, or place learning

## Risks

- over-optimizing for visual polish without materially improving the learning loop
- making the experience louder without making it clearer
- adding too much motion or decoration before the interaction model is strong
- improving home and Chronicle while leaving place learning underpowered, which would preserve the core product gap
- mixing parent-facing educational reassurance into child-facing primary flows

## Open questions

- should home lead with a single hard CTA, or should scene cards themselves become the hero-level action surface?
- should the lesson card flow remain a paged card carousel, or move to a stronger step-by-step narrative layout?
- should place learning be improved through richer schematic geography first, or through more game-like placement interaction first?
- should Chronicle collection happen inline on the Chronicle screen, or in a distinct reward moment before entering the collection view?
- what minimum artifact set best proves that the iteration succeeded on `main`?

## Delivery plan

### Phase 1, spec and alignment
- record this spec
- open a linked GitHub issue
- split implementation into a coordinator-led execution plan with specialized ownership

### Phase 2, planning and task breakdown
- product/design planning for home, lesson, places, and Chronicle improvements
- engineering task decomposition with acceptance criteria per screen
- CI artifact validation plan for before/after comparison

### Phase 3, execution order
1. home entry and copy cleanup
2. lesson flow hierarchy and interaction improvements
3. place-learning redesign
4. Chronicle reward and collection improvement
5. final pass on consistency, copy, and capture artifacts

### Phase 4, proof of improvement
- produce fresh CI review artifacts from the updated flow
- run another critical review against main artifacts
- convert remaining gaps into follow-up issues rather than leaving them implicit

## Initial task-level plan

### Task group A, home and top-level guidance
- define the primary CTA model
- simplify hero and scene-card copy
- improve action hierarchy on Learn home

### Task group B, lesson flow
- reduce top-of-screen clutter
- improve story-card readability and pacing
- refine map reveal and recall sequencing
- adjust reward-state language for motivation

### Task group C, place learning
- redesign the place preview and challenge interaction
- strengthen spatial legibility and comparative learning
- improve visual differentiation among forts

### Task group D, Chronicle
- redesign new-reward emphasis
- improve collection feel and item differentiation
- reduce rationale-heavy explanatory copy in the main flow

### Task group E, review and CI proof
- refresh artifact capture if required
- validate contrast, truncation, and first-run clarity
- record follow-up bugs or polish issues from the updated artifacts
