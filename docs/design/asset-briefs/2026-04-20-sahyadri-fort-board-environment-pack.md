# Sahyadri fort board environment pack

- Linked issue: #40
- Status: Ready for generation
- Last updated: 2026-04-20

## Goal
Create a distinctive environment layer for the Sahyadri fort board so place-learning screens feel memorable, regional, and premium without reducing gameplay clarity.

## Product surfaces
- `PlacesHubView`
- `PlaceDetailView`
- future board-based place challenges

## Child outcome
The child should feel that forts belong to a real mountain world, not a generic board.

## Audience
- Primary: children 6 to 10
- Secondary: parents who should feel the app is thoughtful, calm, and culturally grounded

## Asset set
1. **Main board background**
   - stylized Sahyadri ridge-and-plateau environment
   - landscape-first composition
   - safe to crop for iPhone and iPad
2. **Optional texture layer**
   - subtle paper / painted-relief grain
   - should be usable as a low-opacity overlay
3. **Optional ornament pack**
   - compass treatment
   - ridge separators
   - fort-marker halo treatment
   - subtle direction accents for regional reading

## Visual direction
- stylized painted-relief map board
- layered ridgelines and plateau edges
- restrained contour cues
- warm, earthy, calm palette with legible contrast for overlays
- soft sense of altitude and geography
- readable, not noisy

## What it should feel like
- adventurous
- calm
- elevated
- rooted in western Maharashtra hill-fort terrain
- premium but child-legible

## What to avoid
- fantasy treasure-map clichés
- parchment overload
- busy ornamental borders
- dark muddy terrain that kills pin contrast
- militaristic UI language or aggressive battle framing
- photoreal aerial maps

## Layout and export requirements
- master artwork should favor a wide board aspect ratio
- preserve a quiet central play region for pins and route overlays
- keep high-detail clusters near edges, not the interaction center
- export targets:
  - 1x concept board preview
  - high-res production PNG
  - layered/vector source if available

## Color guidance
- terrain browns, stone neutrals, dusty olive, muted sunrise gold, restrained sky tint
- avoid saturated greens/blues that overpower pins and labels
- ensure orange, blue, and green UI accents still read on top

## Interaction constraints
- pins, labels, and route overlays must remain clearer than the background
- current board interaction should not require a code rewrite to use the art
- art should work behind both challenge and reveal states

## Cultural and historical guardrails
- keep the terrain grounded in Deccan hill-fort context
- avoid generic medieval-European map language
- use fort motifs carefully and sparingly
- signal real geography, not fantasy worldbuilding

## Prompt 1, conservative
Create a stylized map-board environment for a children’s history-learning app about Shivaji Maharaj and Sahyadri forts. Show layered western Maharashtra mountain ridges, plateau edges, and hill-fort terrain in a calm painted-relief style. Keep the center of the board visually quiet for interactive pins and route overlays. Use warm earthy browns, stone neutrals, muted olive, and restrained sunrise gold. Make it feel adventurous, premium, and geographically grounded, not fantasy. Avoid parchment clichés, pirate-map language, photoreal satellite looks, and cluttered ornament.

## Prompt 2, more playful
Design a child-friendly Sahyadri fort board background for an educational adventure app. The board should feel like a memorable mountain world with layered ridges, soft contour cues, calm altitude, and subtle fort-region storytelling. Use a stylized storybook-relief map look with clean silhouettes and soft texture. Keep the middle area clear for gameplay. Make it warm, inviting, and regionally specific, with no noisy border art and no fantasy treasure-map tropes.

## Prompt 3, system-fit refinement
Refine this board background so it fits a modern SwiftUI design system for a premium children’s learning app. The artwork should support overlays, pins, labels, and path traces without fighting them. Prioritize a quiet central field, stronger edge framing, subtle ridge hierarchy, and a palette that keeps orange, blue, and green UI accents readable. Preserve western Maharashtra Sahyadri geography cues and a calm ceremonial tone.

## Review checklist
- Does it still feel readable behind pins and labels?
- Does it look rooted in Sahyadri geography?
- Is the center too busy?
- Is it memorable without becoming noisy?
- Does it feel like Greats of Bharatha, not generic ed-tech?

## File drop expectations
When attaching generated candidates to issue #40, include:
- generator/tool used
- prompt version used
- any negative prompt or style constraints
- edits applied after generation
- which candidate is recommended and why
