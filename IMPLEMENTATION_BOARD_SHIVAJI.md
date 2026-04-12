# Implementation Board - Shivaji Arc

## Objective

Turn the Shivaji Maharaj research/spec stack into a build-ready implementation board for the April 17 milestone.

## Build target

**Production MVP slice with premium enhancement layers**

## Vertical slice definition

### Slice 1 (fastest proof)
- Scene 1 and Scene 2 from #6
- Shivneri and Torna from #7
- Royal Chronicle base flow
- haptic + motion polish
- scripted hints first, AI hints optional behind fallback

### Slice 2
- Scene 3 and Scene 4
- Rajgad and Pratapgad
- compare/recall strengthening
- adaptive hint logic

### Slice 3
- Scene 5 and Scene 6
- Raigad completion flow
- coronation climax
- end-of-arc mastery round

## Priority lanes

### Lane A - Foundations
- #11 define content schema and asset checklist
- project structure for content-driven implementation
- interaction/state contracts

### Lane B - Core gameplay
- #9 implement lesson flow core
- #10 implement fort map system
- #12 Royal Chronicle reward and progress system

### Lane C - Enhancements
- #13 sensor enhancement layer
- #14 Apple Intelligence hint and recap layer
- #8 orientation mode prototype/spec follow-through

## Dependency graph

### #11 Content schema and asset checklist
Dependencies:
- none
Blocks:
- #9
- #10
- #12
- #14

### #9 Lesson flow core
Dependencies:
- #11
Uses:
- #6 spec
Blocks:
- polish completion
- scene-by-scene implementation

### #10 Core fort map system
Dependencies:
- #11
Uses:
- #7 spec
Blocks:
- place-learning implementation
- review loop integration

### #12 Royal Chronicle reward/progress system
Dependencies:
- #11
Integrates with:
- #9
- #10

### #13 Sensor enhancement layer
Dependencies:
- #9 core scene structure
- #10 core map interaction
Can proceed partly in parallel as prototype work.

### #14 Apple Intelligence hint and recap layer
Dependencies:
- #11 content schema
- #9 and #10 interaction surfaces
Requires strong non-AI fallback.

### #8 Orientation mode
Dependencies:
- #7 core place canon
Recommended after core slice stability.

## Recommended execution order

### Phase 1 - unblock implementation
1. #11 content schema and asset checklist
2. #9 lesson flow core
3. #10 fort map system

### Phase 2 - make it feel like a product
4. #12 Royal Chronicle
5. #13 sensor enhancement layer

### Phase 3 - intelligence and extended experience
6. #14 Apple Intelligence hint/recap layer
7. #8 orientation mode prototype or limited implementation

## Immediate next actions by issue

### #11 Define Shivaji content schema and asset checklist
Next actions:
- define scene JSON/content model
- define fort/place data model
- define reward/progress data model
- define narration/caption asset checklist
- define guardrail copy fields

Definition of done:
- one implementation-facing schema doc
- one asset checklist doc
- enough structure for engineering to render Scene 1 and Scene 2 without guessing

### #9 Implement Shivaji lesson flow core
Next actions:
- define scene renderer states
- define hook/story/action/recall/reward state machine
- implement Scene 1 and Scene 2 shell
- wire progress state
- wire captions/narration placeholders

Definition of done:
- playable Scene 1 and Scene 2 flow with stub or real content
- progress visible
- no dead-end states

### #10 Implement Shivaji core fort map system
Next actions:
- define simplified map viewport for western Maharashtra
- implement tap-near/snap/confirm
- implement reveal/compare feedback
- implement core 2-fort starter set: Shivneri and Torna
- define scoring bands: Perfect / Great find / Good try

Definition of done:
- child can learn and pin Shivneri + Torna
- comparison feedback works
- core loop supports replay

### #12 Royal Chronicle reward and progress system
Next actions:
- define Chronicle card model
- define reward unlock states
- define mastery states: Witnessed / Understood / Observed Closely
- wire Chronicle UI after Scene 1 and Scene 2 completion

Definition of done:
- the vertical slice has collectible meaning-bearing rewards
- progress feels persistent and coherent

### #13 Sensor enhancement layer
Next actions:
- define haptic tokens
- define motion/parallax rules
- prototype one tilt interaction in Scene 1 or Scene 2
- define fallback paths when sensors unavailable or reduced motion enabled
- explicitly validate ambient light feasibility before committing any gameplay dependence

Definition of done:
- at least one scene and one map interaction gain sensor enhancement without becoming required

### #14 Apple Intelligence hint and recap layer
Next actions:
- define approved AI use cases
- define curated prompt templates or transformation templates
- define fallback scripted hints
- define recap generation surface
- ensure no freeform history generation

Definition of done:
- hint and recap system works with and without AI availability
- all history remains locked to approved content

## Board view

### Now
- #11 content schema and asset checklist
- #9 lesson flow core
- #10 core fort map system

### Next
- #12 Royal Chronicle
- #13 sensor enhancement layer

### Later
- #14 Apple Intelligence layer
- #8 orientation mode

## Sensor policy

### Allowed as enhancement
- haptics
- accelerometer / gyroscope
- heading / compass
- optional camera
- optional AR
- optional speech

### Caution
- ambient light or light-sensor dependent mechanics should not be assumed viable until engineering confirms supported access and stable behavior.

### Hard rule
- no sensor should block story comprehension, place learning, or progression.

## Apple Intelligence policy

Allowed:
- recap
- hinting
- difficulty adaptation
- phrasing transforms

Not allowed:
- canon generation
- open-ended historical invention
- changing place-event truth
- relying on AI for basic progression

## Milestone completion rubric

The milestone is operationally successful when:
- #11 is complete enough to drive implementation
- #9 and #10 support a believable playable slice
- #12 makes the slice feel rewarding
- #13 adds at least one meaningful premium interaction with fallback
- #14 is at least designed with safe guardrails and fallback behavior
- the repo clearly expresses sequence, ownership, and readiness to code
