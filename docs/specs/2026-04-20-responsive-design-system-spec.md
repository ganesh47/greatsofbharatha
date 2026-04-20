# Responsive design system spec

- Status: Draft
- Linked issue: #38
- Milestone: Shivaji Arc
- Owner: @ganesh47
- Last updated: 2026-04-20

## Problem

GreatsOfBharatha now has enough product shape that UI inconsistency is becoming a product risk, not just a polish issue.

The current app already shows a promising loop, story, place memory, recall, and Chronicle reward, but it still behaves like a set of screens rather than one coherent system. The recent review pass surfaced the same root problems repeatedly:
- the learning quest is not legible enough moment to moment
- too many systems compete on single screens
- place learning is promising but not yet the unmistakable star
- Chronicle is structurally clear but emotionally underpowered
- copy, iconography, and visual language are still too prototype-like in places
- current layouts are iPhone-first and should be upgraded into a durable SwiftUI-native responsive system that scales to iPhone, iPad, and future Apple TV exploration

Without a design system, each screen will continue solving the same hierarchy, spacing, state, responsiveness, and asset problems independently.

## Goals

- create a durable SwiftUI-native design system for GreatsOfBharatha
- make the core quest legible across the product: story -> place -> Chronicle
- establish responsive layout rules that work across iPhone portrait, iPhone landscape, iPad split view, iPad full-screen, and future tvOS adaptation
- define shared tokens for color, type, spacing, shape, iconography, motion, and interaction states
- make place learning the most distinctive visual and interaction surface in the app
- turn Chronicle into a ceremonial, meaningful reward system instead of a flat list
- prefer Apple-native implementation patterns first, with low-fragility, accessible components
- define a workflow for free/open-source icons and future AI-assisted asset production

## Non-goals

- finalizing the complete visual identity for every future historical arc
- shipping custom 3D or heavy real-time animation systems in this phase
- replacing SF Symbols everywhere with custom icon packs just for novelty
- designing a tvOS UI now, beyond keeping the system structurally open to it
- adding large new content arcs before the existing loop is visually and interactionally coherent

## Product design principles

### 1. One quest, not many modules
Every screen should reinforce one child-legible quest structure.

Preferred child-facing framing:
- hear the story
- find the fort
- earn the Chronicle

Where the board interaction is foregrounded, this can extend to:
- hear the story
- remember the place
- pin it on the board
- keep it in your Chronicle

### 2. One dominant action per screen
Children should not need to parse five systems at once.
The active step should dominate visually and semantically.
Future steps can be hinted at, but not compete.

### 3. Place learning is the signature mechanic
The fort board, place comparisons, and spatial memory cues should become the most memorable product surface.
If users mainly remember generic cards and progress rows, the product is underusing its differentiator.

### 4. Rewards must prove learning
Chronicle is not a sticker album. It is evidence of what the child now knows.
Every reward should feel ceremonial, specific, and tied back to person, place, and significance.

### 5. Calm, native, and premium without feeling static
The UI should stay readable and low-anxiety, but it must stop feeling like stacked white cards with weak peaks.
Use native SwiftUI strengths, typography, spacing, materials, and motion with more intention.

### 6. Child-first language, parent-trust outcomes
Instructional copy should be direct and concrete for children.
System structure should remain explainable to adults, especially around learning outcomes and reward meaning.

## Responsive platform matrix

### iPhone compact width
Primary target for V1.

Rules:
- single-column scroll surfaces
- one hero action at top
- step content revealed progressively
- bottom tab bar remains primary shell
- cards can be full-width, but must avoid long text blocks and nested sections competing at once

### iPhone regular height landscape
Needs graceful degradation rather than dense reuse of portrait layouts.

Rules:
- avoid tall hero cards that push the active task below the fold
- prefer two-panel compositions only when content clearly benefits, such as place board + clue summary
- keep tap targets large enough for handheld landscape use

### iPad split view
Critical for responsiveness.

Rules:
- components must survive 1/3, 1/2, and 2/3 split widths
- avoid hard-coded full-width assumptions
- cards should adapt between compact and regular presentation tokens
- side-by-side layouts only when each pane retains clear focus

### iPad full-screen
Opportunity surface, not just scaled phone UI.

Rules:
- allow two-column story/place and collection/detail layouts
- increase environmental feeling through whitespace, background treatment, and stronger visual anchors
- place board can gain surrounding context, comparison panel, and richer reveal states

### tvOS future readiness
Not in current implementation scope, but design-system decisions should not block it.

Rules:
- avoid interactions that only make sense as tiny touch targets
- keep components focus-friendly in principle
- distinguish content container styles from navigation shell styles
- structure scenes so the active learning step can be a clear focus region on larger screens

## Design-system architecture

Create a dedicated design layer inside the app.

Recommended structure:

```text
GreatsOfBharatha/
  DesignSystem/
    Tokens/
      GBColor.swift
      GBTypography.swift
      GBSpacing.swift
      GBRadius.swift
      GBShadow.swift
      GBMotion.swift
      GBIcon.swift
    Foundation/
      GBLayoutContext.swift
      GBAdaptiveStack.swift
      GBCardStyle.swift
      GBSurface.swift
      GBButtonStyle.swift
      GBBadge.swift
    Components/
      GBHeroCard.swift
      GBQuestProgress.swift
      GBStoryCard.swift
      GBClueCard.swift
      GBRecallCard.swift
      GBRewardReveal.swift
      GBChronicleCard.swift
      GBPlaceBoard.swift
      GBPlaceTrailCard.swift
      GBSectionHeader.swift
    Patterns/
      LessonScreenPattern.swift
      PlaceScreenPattern.swift
      ChronicleScreenPattern.swift
```

Guidance:
- tokens should be static, centralized, and semantic
- feature screens should compose design-system components rather than own their own visual language
- components should derive sizing and composition from environment-driven layout context, not one-off geometry hacks

## Token system

### Color tokens
Use semantic names, not implementation names.

Core semantic groups:
- `bg.app`
- `bg.surface`
- `bg.elevated`
- `bg.heroWarm`
- `bg.heroCool`
- `content.primary`
- `content.secondary`
- `content.tertiary`
- `accent.story`
- `accent.place`
- `accent.chronicle`
- `accent.success`
- `accent.warning`
- `border.default`
- `border.emphasis`
- `state.locked`

Behavior:
- support light and dark appearance explicitly
- preserve calm contrast ratios suitable for children
- keep story, place, and Chronicle color families distinct enough to reinforce product structure
- Chronicle should not share exactly the same emphasis language as story progression or place challenge

### Typography tokens
Prefer Apple-native text styles and semantic wrappers.

Recommended styles:
- display for arc/hero titles
- title for scene/place/reward headings
- headline for active-task labels
- body for instructional sentences
- caption for secondary metadata only

Rules:
- use Dynamic Type-friendly wrappers
- limit multi-line body copy in primary action zones
- prefer short sentence blocks over paragraphs
- on iPad, increase line length carefully, not by simply scaling fonts up

### Spacing and layout tokens
Define a small, consistent scale.

Suggested spacing ladder:
- 4, 8, 12, 16, 20, 24, 32, 40

Rules:
- section spacing should communicate task separation
- internal card spacing should make hierarchy obvious without bloating height
- larger screens should increase outer margin and group spacing before increasing text density

### Shape tokens
Rounded rectangles are already the product language, but standardize them.

Suggested radii:
- compact controls: 12 to 16
- standard cards: 20 to 24
- hero surfaces: 28 to 32
- badges/chips: capsule or 16+

### Shadow and depth tokens
Use depth sparingly.

Rules:
- default cards rely on contrast and border, not heavy shadows
- ceremonial Chronicle or reward reveal states can use stronger elevation
- place board can use depth selectively to signal interaction and current focus

### Motion tokens
Motion should support memory and ceremony, not decoration.

Allowed use cases:
- reward reveal
- board pin confirmation
- state transition between lesson steps
- subtle hero emphasis on first load

Avoid:
- perpetual motion
- large parallax systems
- complex chained animation that makes CI capture fragile

## Iconography strategy

### Baseline rule
Use **SF Symbols first** for product shell, navigation, system actions, and common UI metaphors.
This is the best default for SwiftUI-native quality, accessibility, rendering behavior, and future platform coverage.

### Open-source icon rule
Use free/open-source custom icons only where SF Symbols is not expressive enough, especially for:
- historical or domain motifs
- Chronicle categories
- fort/place board markers
- collectible rarity or mastery seals

Recommended sources:
- **Tabler Icons** (MIT)
- **Phosphor Icons** (MIT)

Selection guidance:
- pick one supplementary icon family, not several mixed packs
- normalize stroke weight, corner feel, and optical size
- import only approved icons into repo, not entire packages
- keep a repo-local attribution manifest

Recommended repo location:

```text
GreatsOfBharatha/Assets.xcassets/
GreatsOfBharatha/Resources/Iconography/
  README.md
  attribution.md
  source-manifest.json
```

Source manifest fields:
- symbol name
- source library
- license
- original URL
- local asset name
- usage surfaces
- date imported

### Product icon rules
- navigation icons should remain stable across screens
- story, place, and Chronicle each need a distinct semantic icon family
- place markers must be recognizable at small sizes and from a distance on larger layouts
- reward icons must feel collectible, not generic productivity badges

## Core components and responsive behavior

### App shell
Includes navigation, tabs, top-level background behavior, and sectional rhythm.

Requirements:
- single shared shell language across Learn, Places, Chronicle
- adaptive top padding and width constraints by size class
- avoid screen-specific ad hoc background colors and card treatments

### Hero card
Used on Learn and possibly future arc hubs.

Requirements:
- one dominant CTA
- concise progress framing
- responsive title and subtitle hierarchy
- supports compact and regular variants
- no more than one secondary badge at top-right

### Quest progress component
Unifies the active learning loop.

Requirements:
- explicit steps with child-legible labels
- highlights current step only
- can render horizontally on iPhone, optionally vertically or sidebar-style on iPad

Recommended labels:
- Story
- Find Place
- Chronicle

If board pinning is a dedicated step in some screens, use a four-step variant without inventing a second visual language.

### Story card
Requirements:
- active card owns the screen
- short readable copy blocks
- image/illustration slot ready for future assets
- clear next action
- no secondary module should visually compete while story is active

### Clue / place memory card
Requirements:
- concrete clue phrasing
- space for one memory hook, one event, one region clue
- supports hidden, revealed, success, and compare variants

### Recall card
Requirements:
- retrieval-first behavior
- avoid echo questions immediately after re-showing answer
- make correctness feedback reinforce mastery, not only correctness
- ready for reuse in delayed review mode later

### Place board
This is the flagship component.

Requirements:
- adaptive board aspect ratio
- supports compact presentation on iPhone and richer contextual framing on iPad
- current fort stands out clearly
- nearby alternatives remain legible
- pins, trails, and region hints use stable visual grammar
- challenge state, reveal state, and compare state should feel distinct

### Chronicle reward reveal
Requirements:
- separate reveal moment from catalog state
- supports celebratory animation and a strong summary sentence
- communicates what was learned, not just what was unlocked

### Chronicle collection card
Requirements:
- category, title, memory value, and learning significance
- locked state should tease meaning without becoming noisy inventory
- unlocked states should feel like keepsakes

## Screen-pattern guidance

### Learn home
Target outcome:
- immediately communicates the next quest step
- feels like entering an adventure, not browsing a syllabus

Pattern:
- hero next-action card
- concise journey framing
- scene cards with low reading load
- Chronicle teaser only after primary journey content

### Scene lesson
Target outcome:
- one obvious active task
- transitions feel like progress within one quest

Pattern:
- top quest progress
- active story or task card
- only the current step visible in full emphasis
- future steps hinted, not fully expanded

### Places hub
Target outcome:
- feels like the next chapter of the same journey, not a side product

Pattern:
- journey framing at top
- status labels rewritten to action-led language
- trail list with strong next-up cues
- on iPad, allow trail + selected summary split view

### Place detail / board challenge
Target outcome:
- feels like discovery and reasoning

Pattern:
- clue / context panel
- board as dominant visual
- reveal / compare states
- optional Apple Maps handoff stays secondary to the learning board

### Chronicle
Target outcome:
- feels ceremonial and identity-building

Pattern:
- recent unlock highlight
- clear grouping of unlocked vs next-to-earn
- each item restates memory value
- future catalog does not overwhelm recent reward meaning

## Copy system guidance

Preferred child-facing verbs:
- listen
- find
- remember
- pin
- collect
- compare
- unlock

Avoid or reduce in core child-facing flows:
- linked lesson scene
- reveal this Chronicle reward
- complete the following
- meaning-bearing rewards
- debug/prototype/capture framing

Parent-trust copy should be concise and placed in supportive surfaces, not in the middle of active child tasks.

## Accessibility and quality bar

- Dynamic Type support for all primary components
- VoiceOver labels for quest progress, pins, reward states, and challenge feedback
- color contrast validated for all semantic token pairs
- no state should rely on color alone
- all interactive targets should be at least Apple-recommended touch sizes
- responsive layouts should be testable in previews for compact, regular, and split-screen environments

## Asset and AI-assisted workflow

Ganesh may use tools like nano-banana, ChatGPT, or other generators to help produce assets, sprites, concepts, or icon variations. This is useful, but only if the workflow stays controlled.

### Asset categories
- illustrations and story spot art
- fort/place board motifs
- Chronicle card art
- icon candidates and ornament systems
- character or environment sprites for future motion work

### Workflow
1. Write an asset brief in repo before generation.
2. Generate multiple candidates externally.
3. Review for child-safety, cultural respect, clarity, and product fit.
4. Normalize style, naming, and sizing.
5. Export approved assets into repo with attribution/provenance notes.
6. Add preview screenshots or usage references.
7. Only then wire them into SwiftUI components.

Recommended repo structure:

```text
docs/design/
  asset-briefs/
  prompts/
  review-notes/
GreatsOfBharatha/Resources/Art/
  Chronicle/
  Places/
  Story/
```

### Asset brief template fields
- purpose
- target screen/component
- child age band
- educational meaning
- visual references
- size/aspect needs
- animation intent, if any
- licensing / provenance
- approved by

### AI asset guardrails
- never ship unreviewed generated outputs directly
- avoid style drift across generated batches
- keep a human-approved final edit pass
- maintain cultural and historical respect, especially for real figures and places
- prefer vector-first or layered source files when possible

## Implementation plan

### Phase 1: foundations
- create `DesignSystem/` module structure inside the app target
- introduce semantic tokens for color, typography, spacing, radius, elevation, and icon usage
- create adaptive layout context helpers and base surfaces
- remove visible debug or prototype framing from user-facing UI where still present

### Phase 2: screen primitives
- build quest progress component
- build hero card, section header, badge, and card styles
- build story card, clue card, recall card, and Chronicle card primitives
- build first pass of responsive place board component

### Phase 3: feature migration
- migrate `LessonHomeView` to design-system hero and section patterns
- migrate `SceneLessonView` to explicit quest-step structure
- migrate `PlacesHubView` and place detail screens to responsive place system
- migrate `ChronicleView` to reveal + collection pattern split

### Phase 4: asset pipeline and iconography
- add icon source manifest and attribution docs
- import only approved open-source supplementary icons if SF Symbols is insufficient
- create asset-brief and review workflow docs for future generated art

### Phase 5: proof and follow-through
- add SwiftUI previews for iPhone and iPad variants of core components
- refresh UX artifact capture from CI
- review against the product-critical findings that triggered this spec
- split implementation into focused issues/PRs if required

## Suggested GitHub issue breakdown

Primary umbrella issue:
- responsive SwiftUI-native design system for GreatsOfBharatha

Follow-up execution issues:
1. design-system foundations and semantic tokens
2. quest progress and lesson-screen pattern
3. responsive place board and places flow
4. Chronicle reveal and collection redesign
5. iconography and asset-source policy
6. AI-assisted asset workflow and review docs

## Acceptance criteria

A design-system phase is successful when:
- the app no longer feels like independent feature screens with separate visual logic
- the quest structure is obvious at a glance
- iPhone and iPad layouts both feel intentional, not merely stretched
- place learning is visually and interactively the strongest lane
- Chronicle rewards feel ceremonial and specific
- icon usage is consistent, licensed, and documented
- asset generation and import workflow is durable enough for future contributors

## Open questions

- should the product standardize on a 3-step quest model everywhere, or allow a 4-step model when board pinning needs explicit prominence?
- should Places remain a tab in V1, or become more tightly integrated into guided lesson progression?
- which surfaces truly need custom icons versus SF Symbols?
- when should story art become required rather than optional?
- what is the minimum motion system that materially improves reward ceremony without increasing fragility?

## Immediate next moves

1. Open the umbrella GitHub issue for the design-system workstream.
2. Link this spec to that issue.
3. Add a small set of design-system foundation files in SwiftUI.
4. Create `docs/design/` support docs for icon attribution and asset workflow.
5. Start migration with Learn home, place board, and Chronicle, in that order.
