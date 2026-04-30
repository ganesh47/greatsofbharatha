# Shivaji learn-and-quiz reset implementation spec

- Status: Draft
- Linked issue: #126
- Planning comment: https://github.com/ganesh47/greatsofbharatha/issues/126#issuecomment-4351294484
- Owner: @ganesh47
- Last updated: 2026-04-30

## Reset decision

Issue #126 is the gameplay reset anchor for the Shivaji MVP. The product direction is now:

> A fun learn-and-quiz app where kids build a memorable Chronicle of Shivaji Maharaj through time, place, and action.

Older gameplay specs and UX explorations remain useful reference material, but they are pre-reset exploration unless this spec or a later #126 follow-up explicitly reuses a mechanic. Do not polish the old gameplay path as the main MVP center.

## Related specs

- `2026-04-12-shivaji-maharaj-story-map-timeline-lesson-flow.md` - six-scene pre-reset content exploration.
- `2026-04-18-shivaji-content-schema.md` - current alpha schema for existing `HeroArc`/`SceneCluster` data.
- `2026-04-19-main-ux-iteration-spec.md` - pre-reset UX iteration notes.
- `2026-04-20-responsive-design-system-spec.md` - reusable design guidance that can still inform reset UI.

## Product promise

For each historical figure, children should remember:

- Time: what came before and after.
- Place: forts, regions, terrain, capitals, and routes.
- Action: what the figure did, decided, endured, built, or protected.
- Meaning: why it matters in child-safe language.
- Memory proof: recall, match, order, and explain before the Chronicle deepens.

## MVP loop

Each pilot scene should follow the same small loop:

1. Learn card with one illustrated episode.
2. Memory hook with one sticky phrase.
3. Quick retrieval quiz.
4. Mini-game reinforcement through match, order, tap place, or flashcard.
5. Chronicle unlock or deepen event.
6. Spaced review seed based on correctness and hint use.

## Feature flag and routing

Use `historyLearnQuizResetEnabled` as the reset gate. In the current PR, the safe implementation surface is:

- environment flag: `GOB_HISTORY_LEARN_QUIZ_RESET_ENABLED=1`
- default behavior: off, existing app route unchanged
- capture placeholder route: `GOB_CAPTURE_ROUTE=learn-quiz-reset`

The placeholder exists only to prove route isolation and content availability. Full reset UI work belongs in later #126 PRs.

## Pilot content contract

The first shippable pilot is exactly three scenes:

1. Shivneri - Birth Fort
2. Torna and Rajgad - Early Forts
3. Pratapgad - Turning Point

The Swift fixture source of truth for this pilot is `SampleContent.shivajiLearnQuizResetPilot`.

### Scene 1: Shivneri - Birth Fort

- Time: beginning of the journey
- Place: Shivneri Fort, Junnar region
- Action: childhood begins under Jijabai's guidance
- Meaning: Shivneri anchors the beginning and the values carried forward
- Memory hook: Birth Fort
- Quiz: Where does Shivaji Maharaj's story begin?
- Hints:
  - Think of the Birth Fort.
  - It is the fort near Junnar where the story begins.
  - Choose Shivneri.
- Match pairs:
  - Shivneri <-> Birth Fort
  - Shivneri <-> Story begins
- Chronicle reward: Birth Fort Chronicle Card
- Review prompt: Birth Fort -> Shivneri

### Scene 2: Torna and Rajgad - Early Forts

- Time: early Swarajya-building
- Place: Torna and Rajgad
- Action: wins an early fort and builds a planning base
- Meaning: the early forts show building and planning, not only winning
- Memory hooks: First Big Fort, Early Capital
- Quiz: Which fort became an early capital?
- Hints:
  - Think of Early Capital.
  - Torna is the First Big Fort; the other fort became the planning base.
  - Choose Rajgad.
- Match pairs:
  - Torna <-> First Big Fort
  - Rajgad <-> Early Capital
  - Rajgad <-> Planning base
- Chronicle reward: First Fort / Early Capital Card
- Review prompt: First Big Fort / Early Capital -> Torna / Rajgad

### Scene 3: Pratapgad - Turning Point

- Time: major rise and turning point
- Place: Pratapgad, hill terrain near Mahabaleshwar
- Action: plans with courage and terrain awareness
- Meaning: preparation and terrain changed the balance at a key moment
- Memory hook: Turning Point
- Quiz: Which fort is remembered as the turning point?
- Hints:
  - Think of Turning Point.
  - It stands in hill country near Mahabaleshwar.
  - Choose Pratapgad.
- Match pairs:
  - Pratapgad <-> Turning Point
  - Planning and terrain <-> Changed the balance
- Chronicle reward: Turning Point Seal
- Review prompt: Turning Point -> Pratapgad

## Timeline builder seed

Pilot order:

1. Shivneri
2. Torna/Rajgad
3. Pratapgad

Completion reward: the Chronicle gains a Journey So Far timeline strip.

## Data contracts

Use the reset-specific models for new learn-and-quiz work:

- `HistoricalFigureArc`
- `ChronicleScene`
- `PlaceAnchor`
- `QuizItem`
- `MatchPair`
- `TimelineBuilderSeed`
- `ReviewSeed`

Keep `HeroArc`, `SceneCluster`, and the existing six-scene sample available for old/pre-reset UI until replacement is proven. Later PRs may add pure engines for quiz evaluation, match completion, review scheduling, and Chronicle deepening against these reset contracts.

## Child UX principles

- Retrieval first: ask the child to pull from memory before relying on recognition.
- Kind recovery: wrong answers rebuild the hook without shame.
- Low anxiety: no lives, harsh fail states, public scoring, or punishment loops.
- Interleaving: rotate place, time, action, and meaning prompts.
- Chronicle as evidence: rewards should show remembered history, not generic loot.

## Non-goals for PR1

- Do not delete old gameplay or the six-scene Shivaji arc.
- Do not build the full reset UI.
- Do not implement quiz, match, scheduler, or Chronicle reward engines yet.
- Do not add new generated art.
- Do not make `historyLearnQuizResetEnabled` default-on.

## Follow-up PRs

1. Pure learning engines: quiz, match, review scheduler, Chronicle progress.
2. Isolated UI: reset home, learn card, quiz, match, Chronicle book shell.
3. Shivneri vertical slice: learn card -> quiz -> match -> reward -> review seed.
4. Full three-scene pilot: timeline builder, flashcards, and review evidence.
