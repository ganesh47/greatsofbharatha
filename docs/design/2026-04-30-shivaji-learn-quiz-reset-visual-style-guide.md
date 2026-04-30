# Shivaji learn-and-quiz reset visual style guide

- Linked issue: #126
- Track: D1 visual style guide
- Status: Draft for art generation and human review
- Last updated: 2026-04-30

## Purpose

This guide defines the visual direction for the Shivaji Maharaj learn-and-quiz Chronicle pilot. It supports the reset loop:

`Learn card -> quick quiz -> match/timeline reinforcement -> Chronicle reward -> spaced review`

The art should help children remember time, place, action, and meaning. It should not compete with the learning task or drift into generic game decoration.

## Audience

- Primary: children ages 6 to 10
- Secondary: parents evaluating whether the app feels historically respectful and educationally worthwhile
- Product tone: warm, clear, proud, calm, and memorable

## Core Style

Use a **warm storybook + collectible Chronicle card** style:

- bold readable silhouettes for forts, mountains, and card emblems
- lightly textured painted shapes, not heavy realism
- clean mobile-first compositions with one strong focal idea
- collectible card framing that feels earned and educational
- restrained ceremonial detail: seals, borders, ink marks, ridgelines, fort profiles
- tactile mini-game tiles that read instantly at small size

Avoid art that looks like a generic fantasy RPG, a battle game, a sticker pack, or a museum textbook plate.

## Visual Hierarchy

Every asset must read in this order:

1. memory hook or place identity
2. scene mood
3. historical/cultural detail
4. decorative polish

If decorative detail weakens the memory hook, remove the detail.

## Scene Color Worlds

### Shivneri - Birth Fort

- Mood: dawn, beginning, protection, Jijabai's guidance, values forming
- Palette: warm dawn gold, stone beige, muted saffron, soft sky blue, light earth
- Main shapes: Shivneri-inspired fort silhouette, hill profile, early light, protective enclosure
- Avoid: baby imagery as the main focus, divine destiny effects, palace fantasy styling

### Torna + Rajgad - First Big Fort / Early Capital

- Mood: ascent, planning, early Swarajya-building, strong mountain base
- Palette: muted greens, fort stone, terracotta, clear sky accents, controlled warm gold
- Main shapes: high ridgelines, fort walls, two-place relationship, planning/base cues
- Avoid: conquest spectacle, battle smoke, weapon-first compositions, exaggerated victory poses

### Pratapgad - Turning Point

- Mood: strategy, terrain, courage, a decisive turning point handled with restraint
- Palette: blue-gray mist, stone charcoal, muted forest green, restrained saffron/gold highlight
- Main shapes: dramatic hill terrain, angled paths, watchful fort silhouette, turning-point seal
- Avoid: graphic violence, direct combat scene, revenge framing, villain caricature

## Figure Depiction Rules

Human figures are optional and should be used sparingly for the first pilot. Place and memory-hook art is preferred because it reduces risk and improves recognition.

When depicting Shivaji Maharaj or Jijabai:

- keep posture dignified, calm, and child-safe
- use respectful Maratha-era clothing cues without overclaiming exact costume details
- prefer medium or distant storybook treatment over portrait claims
- show Jijabai as a guiding parental influence without turning the scene into mythology
- avoid caricature, exaggerated facial features, comic mockery, or overly cinematic aggression

## Historical and Cultural Guardrails

Use stable, broad facts from the approved Shivaji V1 framing:

- Shivneri is the beginning / Birth Fort
- Torna and Rajgad represent early fort-building and planning base memory
- Pratapgad is a turning point where terrain and planning mattered
- Swarajya means self-rule / independent rule in child-safe language
- forts, geography, preparation, courage, and responsibility are core themes

Do not imply disputed micro-details as visual fact. Do not insert modern political symbols or present-day slogans. Do not use communal enemy imagery, totalized religious conflict, or revenge-centered visuals.

## Forbidden Elements

Across all generated assets, reject:

- photorealistic violence, gore, bodies, blood, or injury
- direct assassination/combat tableau for Pratapgad
- villain caricatures or dehumanized enemy figures
- modern weapons, vehicles, flags, buildings, microphones, cameras, or party-political symbols
- fantasy castles, European medieval armor, pirate-map language, treasure chests, loot crates
- random crowns, generic swords, skulls, flames, neon effects, or casino-style reward bursts
- disrespectful Hindu symbols, decorative sacred marks used without purpose, or garbled script
- text baked into art unless explicitly requested as a reviewed UI label
- unreadable clutter at mobile card or tile size

## Asset Surface Guidance

### Learn Cards

- Aspect: vertical card hero area, crop-safe for iPhone portrait
- Composition: one clear scene environment, quiet lower area for chips/copy if overlaid
- Focal point: fort/place first, then mood
- Detail level: enough texture to feel crafted, simple enough for fast comprehension

### Chronicle Reward Cards

- Aspect: square master, crop-safe for vertical cards
- Composition: emblem or seal with one primary motif
- States: silhouette, inked, sealed/deepened, remembered-again mark
- Reward feeling: keepsake earned through memory, not generic loot

### Match Tiles

- Aspect: square or rounded-rectangle tile art
- Composition: icon-like, silhouette-first, strong contrast
- Pair types: place <-> hook, place <-> action, event <-> time marker
- Must be recognizable without paragraph text

### Timeline Tiles

- Aspect: compact horizontal or square tile
- Composition: small scene emblem plus ordering cue
- Avoid relying on dates for the pilot; use beginning / early forts / turning point memory

## Accessibility and Readability

- Assets must remain understandable at 120 px wide.
- Avoid low-contrast text or line art.
- Keep UI text outside generated images whenever possible.
- Do not rely on color alone to distinguish scene identity; use silhouette and motif differences.
- Leave enough negative space for SwiftUI chips, labels, and state marks.

## Human Review Checklist

Before any generated asset ships:

- Memory: Can a child connect the art to the intended hook within 3 seconds?
- Place: Is the fort or terrain cue specific enough for Shivneri, Torna/Rajgad, or Pratapgad?
- Respect: Is Shivaji Maharaj, Jijabai, and Hindu/cultural context handled with dignity?
- Safety: Is there no gore, direct violence, fear imagery, or shame-based reward language?
- History: Does the art avoid disputed specifics and modern political messaging?
- Product fit: Does it match the warm storybook + Chronicle card system?
- Readability: Does it work at learn-card, reward-card, match-tile, and timeline-tile sizes?
- Provenance: Is the generator, prompt version, review owner, and edit history recorded?

## Approval Rule

Generated art is not product-ready by default. A human reviewer must approve historical/cultural fit, child safety, and mobile readability before import into app assets.
