# AI-assisted asset workflow

This workflow is for future art, sprites, motifs, Chronicle cards, and other visual assets created with tools like nano-banana, ChatGPT, or other generators.

## Principle

AI can accelerate exploration. It should not bypass product judgment, historical respect, or style consistency.

## Approved workflow

### 1. Write a brief first
Before any generation, create an asset brief in `asset-briefs/`.

Required fields:
- asset name
- purpose
- target screen/component
- target age band
- educational meaning
- required mood
- style references
- aspect ratio / sizing needs
- animation intent, if any
- historical/cultural constraints
- provenance notes

### 2. Generate candidate sets
Create multiple candidates externally.

Recommended working pattern:
- one conservative set
- one more playful set
- one system-fitting refinement set

Store prompt drafts or generation notes in `prompts/` when they are worth preserving.

### 3. Review before import
Review candidates for:
- child clarity
- historical respect
- style fit with the app
- readability at target size
- whether the asset improves learning or only decorates

Record the decision in `review-notes/`.

### 4. Normalize approved outputs
Before import:
- crop and align consistently
- normalize stroke/weight and palette where needed
- export in the preferred final format
- avoid shipping raw generated outputs without cleanup

### 5. Import with provenance
Each approved asset should carry:
- source tool
- date created
- prompt or brief reference
- editing notes
- final owner approval

## Format guidance

Prefer, in order:
1. vector or layered source when possible
2. transparent PNG for illustration assets
3. sprite sheets only when there is a clear runtime need

## Product guardrails

- do not use AI art just to fill space
- do not let generated styles drift across scenes
- do not introduce culturally sloppy motifs around real historical figures or forts
- do not make reward art more important than learning clarity

## Best future uses in GreatsOfBharatha

- story spot illustrations
- Chronicle card art systems
- fort-board ornament sets
- emblem fragments and seals
- celebratory reward treatments

## Avoid first

- shipping a large generated asset pack without a style system
- mixing many generator aesthetics in one release
- using AI assets before the responsive design system and component language are stable
