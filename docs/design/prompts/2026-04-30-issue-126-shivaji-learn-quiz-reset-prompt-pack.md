# Prompt pack for issue #126 Shivaji learn-and-quiz reset

- Linked issue: #126
- Track: D2 pilot asset prompt pack
- Depends on: `docs/design/2026-04-30-shivaji-learn-quiz-reset-visual-style-guide.md`
- Status: Draft for generation, not final art approval
- Last updated: 2026-04-30

## Use

These prompts prepare candidate art for the Shivaji Maharaj learn-and-quiz Chronicle pilot. They should be used to generate candidates only. Human review is required before any image becomes a product asset.

Recommended sequence:

1. Generate one conservative candidate per learn card.
2. Generate one stronger collectible-card candidate per reward.
3. Generate match/timeline tiles as a coordinated small-size set.
4. Run the review checklist before choosing candidates for cleanup.

## Shared Style Block

Append this block to each prompt unless the generator has a separate style field:

Warm storybook illustration for a premium children's history-learning app, collectible Chronicle card energy, bold readable silhouettes, lightly textured painted shapes, calm ceremonial mood, clear mobile-first composition, historically respectful, child-safe, not photorealistic, not fantasy RPG, not generic sticker art.

## Shared Historical and Cultural Constraints

- Shivaji Maharaj is presented respectfully as a Hindu king and builder of Swarajya.
- Focus on forts, geography, planning, courage, responsibility, and self-rule.
- Use broad stable memory hooks: Birth Fort, First Big Fort, Early Capital, Turning Point.
- Avoid disputed micro-details and do not invent specific battle or costume claims.
- No modern political symbols, slogans, maps, vehicles, weapons, or party colors as messaging.
- No communal enemy caricatures, revenge framing, or totalized religious conflict.
- Sacred or cultural motifs must be dignified, simple, and purposeful.

## Shared Negative Prompt

No gore, blood, injury, bodies, direct combat tableau, assassination scene, villain caricature, modern politics, modern flags, modern weapons, European medieval castle, fantasy armor, pirate map, treasure chest, loot crate, casino reward burst, neon, dark horror mood, disrespectful religious symbols, garbled script, baked-in text, cluttered tiny details.

## Shared Human Review Checklist

Use this for every generated candidate:

- Does the asset strengthen the intended memory hook?
- Is the place/terrain cue clear at mobile size?
- Is the historical and Hindu cultural framing respectful?
- Is the scene child-safe and free from graphic or fear-first imagery?
- Does it avoid modern political, fantasy, and generic game-reward tropes?
- Does it match the shared storybook + Chronicle card system?
- Can UI labels, chips, and state marks sit near it without visual conflict?
- Is provenance recorded: tool, date, prompt version, reviewer, edits?

## Asset Naming Contract

Proposed future asset slots:

- `learn_shivneri_birth_fort`
- `learn_torna_rajgad_early_forts`
- `learn_pratapgad_turning_point`
- `chronicle_birth_fort_card`
- `chronicle_first_fort_early_capital_card`
- `chronicle_turning_point_seal`
- `chronicle_journey_so_far_page`
- `tile_shivneri`
- `tile_birth_fort`
- `tile_torna`
- `tile_rajgad`
- `tile_first_big_fort`
- `tile_early_capital`
- `tile_pratapgad`
- `tile_turning_point`
- `tile_beginning`
- `tile_early_swarajya`

## Learn Card Prompt: Shivneri - Birth Fort

### Scene Title

Shivneri - Birth Fort

### Memory Outcome

The child remembers: Shivaji Maharaj's story begins at Shivneri.

### Prompt

Create a vertical learn-card hero illustration for a children's history-learning app about Shivaji Maharaj. Show Shivneri Fort as a calm hill-fort silhouette at dawn, with protective stone forms, soft early light, and a sense of beginning. The image should feel warm, respectful, and memorable for the hook "Birth Fort." Include subtle cues of Jijabai's guidance only if shown respectfully and simply, such as a distant parent-child silhouette or warm interior light, but keep the fort and place as the main focus. Leave quiet space for SwiftUI time/place/action chips and short story copy.

### Composition

- Fort silhouette and hill profile should dominate.
- Dawn sky can frame the fort without heavy effects.
- Keep foreground simple and non-cluttered.
- No baked-in text.

### Scene Palette

Dawn gold, warm stone, muted saffron, light earth, soft sky blue.

### Forbidden Elements

No baby portrait as the central image, no divine destiny rays, no palace fantasy, no ornate crown-first imagery, no battle weapons, no modern city or flag.

### Review Focus

Can a child say "this is the beginning at Shivneri" after seeing it?

## Learn Card Prompt: Torna + Rajgad - First Big Fort / Early Capital

### Scene Title

Torna + Rajgad - Early Forts and Planning Base

### Memory Outcome

The child remembers: Torna and Rajgad matter in the early Swarajya-building story; Rajgad is the early capital memory.

### Prompt

Create a vertical learn-card hero illustration for a children's history-learning app about Shivaji Maharaj. Show two Sahyadri hill-fort silhouettes connected by a quiet visual rhythm: one higher ridge for Torna as "First Big Fort," and one steadier planning-base fort for Rajgad as "Early Capital." The mood should be adventurous but calm, focused on planning, building, and mountain geography. Use warm storybook + collectible card styling with clear ridgelines, fort walls, and a child-readable relationship between the two places. Leave clean space for UI chips and story text.

### Composition

- Use two distinct fort/ridge silhouettes without making the scene busy.
- Use a subtle path, light beam, or map-like contour to connect the places.
- Make the "planning base" idea visible through organized shapes, not text.

### Scene Palette

Muted green mountains, fort stone, terracotta, controlled gold highlights, clear sky accents.

### Forbidden Elements

No battle charge, no smoke, no troops, no weapon-first scene, no victory pose, no fantasy conquest banner, no exact route map claim.

### Review Focus

Can a child distinguish "first fort energy" from "early capital/planning base" without needing dense explanation?

## Learn Card Prompt: Pratapgad - Turning Point

### Scene Title

Pratapgad - Turning Point

### Memory Outcome

The child remembers: Pratapgad is the turning point where terrain and planning mattered.

### Prompt

Create a vertical learn-card hero illustration for a children's history-learning app about Shivaji Maharaj. Show Pratapgad as a dramatic but child-safe hill-fort silhouette surrounded by misty Sahyadri terrain, angled paths, and a visual sense of strategy. The mood should communicate "Turning Point" through terrain, planning, and courage, not combat. Use a restrained blue-gray and stone palette with one warm saffron/gold accent that draws attention to the fort or strategic path. Keep the composition dignified, calm, and readable on mobile.

### Composition

- Fort and terrain should create a clear turning-point shape or diagonal.
- Mist may add drama but must not obscure readability.
- No human confrontation scene.
- Leave room for UI elements.

### Scene Palette

Blue-gray mist, stone charcoal, muted forest green, restrained saffron/gold highlight.

### Forbidden Elements

No Afzal Khan confrontation depiction, no stabbing, no blood, no bodies, no villain caricature, no revenge pose, no horror lighting, no weapon-centered composition.

### Review Focus

Does the image teach "terrain and planning mattered" instead of glamorizing violence?

## Chronicle Reward Prompt: Birth Fort Chronicle Card

### Reward State

First correct recall inks the card; later match/timeline success can add a seal or border detail.

### Prompt

Create a square Chronicle reward card illustration called "Birth Fort" for a children's history-learning app about Shivaji Maharaj. Use a Shivneri-inspired fort emblem at dawn, with a clear silhouette, warm stone, and a quiet protective mood. It should feel like a meaningful keepsake earned because the child remembered where the story begins. Make it simple, ceremonial, and readable at small card size.

### Variants

- Silhouette preview: faint fort outline, low detail.
- Inked card: clear fort, dawn light, warm border.
- Deepened card: small reviewed seal or border mark, no loud effects.

### Forbidden Elements

No random trophy, no crown-only symbol, no loot glow, no baby portrait, no fantasy castle.

## Chronicle Reward Prompt: First Fort / Early Capital Card

### Reward State

Recall inks the card; matching both Torna and Rajgad roles adds a double-fort border detail.

### Prompt

Create a square Chronicle reward card illustration for "First Fort / Early Capital" in a children's history-learning app about Shivaji Maharaj. Show a coordinated emblem with two Sahyadri fort silhouettes: Torna as upward first-fort momentum and Rajgad as a steady planning-base form. The reward should feel earned through memory, not like generic game loot. Use warm storybook emblem styling, strong silhouettes, muted mountain green, terracotta stone, and restrained gold.

### Variants

- Silhouette preview: two simple ridge/fort forms.
- Inked card: both forts clear and balanced.
- Deepened card: border detail or small planning mark after match success.

### Forbidden Elements

No troops, no battle smoke, no conquest flag, no exact campaign map, no generic trophy.

## Chronicle Reward Prompt: Turning Point Seal

### Reward State

Correct Pratapgad recall earns the seal; match/timeline success adds a strategic path mark.

### Prompt

Create a square Chronicle reward seal called "Turning Point" for a children's history-learning app about Shivaji Maharaj. Use a Pratapgad-inspired hill-fort silhouette, misty mountain geometry, and a subtle turning path or angled ridge motif. The seal should suggest strategy, terrain, courage, and a major change in the story. Keep it dignified, child-safe, and readable at small size, with restrained blue-gray stone and one warm accent.

### Variants

- Silhouette preview: faint fort and ridge.
- Inked seal: clear terrain and turning path.
- Deepened seal: small remembered-again mark or border notch.

### Forbidden Elements

No combat, no blood, no weapon-first imagery, no villain face, no revenge symbol, no skull or flame motif.

## Chronicle Reward Prompt: Shivaji Journey So Far Page

### Reward State

End-of-pilot page after the child completes the three-scene timeline.

### Prompt

Create a vertical Chronicle page illustration for a children's history-learning app showing the journey so far: Shivneri at the beginning, Torna/Rajgad as early forts and planning base, and Pratapgad as a turning point. Use three simple connected emblems or scene windows rather than a detailed route map. The page should feel like a child's remembered history book is becoming richer. Keep the style warm storybook, premium, respectful, and readable on mobile.

### Forbidden Elements

No exact route claim, no dense dates, no battle montage, no fantasy treasure map, no cluttered scroll.

## Match Tile Prompt Set

### Prompt

Create a coordinated set of small square match tiles for a children's history-learning app about Shivaji Maharaj. Each tile must be icon-like, silhouette-first, high contrast, and readable at 80-120 px. Use the same warm storybook + Chronicle card style across the set. Generate tiles for: Shivneri, Birth Fort, Torna, First Big Fort, Rajgad, Early Capital, Pratapgad, Turning Point. Place tiles should use fort/terrain motifs; hook tiles should use simple emblem motifs. No baked-in text unless explicitly requested for a reviewed UI variant.

### Required Pair Meanings

- Shivneri <-> Birth Fort
- Torna <-> First Big Fort
- Rajgad <-> Early Capital
- Pratapgad <-> Turning Point

### Forbidden Elements

No tiny detailed scenes, no text-dependent recognition, no generic stickers, no random medals, no weapons as primary icons.

### Review Focus

At 80 px, can a reviewer still identify which tile is a fort/place tile and which tile is a role/hook tile?

## Timeline Tile Prompt Set

### Prompt

Create three coordinated timeline tiles for the Shivaji Maharaj learn-and-quiz pilot in a children's history-learning app. Tile 1: Shivneri / beginning. Tile 2: Torna + Rajgad / early forts and planning base. Tile 3: Pratapgad / turning point. Use simple scene emblems, clear ordering mood, and strong silhouettes. The set should support a drag-or-tap ordering game without relying on dates. Keep the style warm storybook + Chronicle card, child-safe, historically respectful, and readable at compact mobile size.

### Forbidden Elements

No date-heavy design, no exact route map, no combat scene, no cluttered border, no baked-in paragraphs.

### Review Focus

Can a child order the tiles by visual memory: beginning -> early forts -> turning point?

## Placeholder Background/Icon Prompt

### Prompt

Create a quiet reusable background texture for the Shivaji learn-and-quiz reset screens. Use subtle Sahyadri contour shapes, soft stone texture, and very light warm paper or sky tone. It must stay behind SwiftUI cards, chips, answer buttons, and tile grids without reducing readability. The image should feel crafted and historical, not parchment cliche or fantasy map.

### Forbidden Elements

No pirate-map parchment, no labels, no routes, no forts as focal points, no high-contrast texture, no decorative clutter.

## Candidate Review Record Template

For each candidate, record:

- Asset slot:
- Generator/tool:
- Prompt section:
- Date generated:
- Reviewer:
- Accepted / revise / reject:
- Memory-hook readability:
- Historical/cultural notes:
- Child-safety notes:
- Mobile readability notes:
- Required edits before import:
