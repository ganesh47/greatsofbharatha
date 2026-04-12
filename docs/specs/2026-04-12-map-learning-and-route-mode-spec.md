# Map learning and route mode spec

- Status: Draft
- Linked issue: #4
- Milestone: Foundation
- Owner: @ganesh47
- Last updated: 2026-04-12

## Problem

Historical learning becomes much stronger when children can connect a figure to real places. For Shivaji Maharaj especially, forts, terrain, region, and routes are central to memory and meaning.

## Goals

- make map interaction a first-class part of learning
- help children identify key historical places
- support top-level route understanding from their current coarse location
- teach direction, distance, regional context, and major towns/cities along the way
- keep the experience child-safe and educational

## Non-goals

- full navigation replacement
- real-time turn-by-turn guidance
- background location tracking
- social location sharing

## Core feature areas

### 1. Place identification
Children can:
- tap forts, cities, regions
- reveal why they matter
- match event to place
- answer “where did this happen?”

### 2. Fort pinning mode
Children can:
- pin locations from memory
- compare against true location
- learn relative north/south/east/west relationships
- unlock contextual facts after placing a pin

### 3. Timeline + map sync
When a child moves through story time:
- relevant places highlight
- routes or event regions can appear
- map state changes with the historical arc

### 4. Route-learning mode
Optional educational mode using current coarse location.

The app may show:
- approximate direction to a historical site
- approximate total distance
- major towns/cities on a broad route
- terrain/region notes
- “you are here” to “historical place” as a learning path

The app should not show:
- live turn-by-turn driving instructions as a core child flow
- exact persistent child location sharing
- unsafe or urgency-oriented travel prompts

## Safety principles

- current-location use is optional
- coarse location is preferred over exact precision when sufficient
- clear parent-facing explanation before enabling location-aware route learning
- no location-based competitive or social mechanics
- no assumption that the child is traveling alone

## UX principles

- educational framing first
- route cards should explain place significance, not just transport
- directions should be broad and age-appropriate
- route mode should degrade gracefully when location permission is unavailable

## Example learning prompts

- Which fort is closest to your area?
- Which direction would you travel to reach Raigad?
- Which major city lies on the broad route?
- Which place belongs to this event?
- Can you pin Pratapgad on the map?

## Technical direction

- use MapKit for maps, annotations, and broad route context
- support lightweight overlays and offline-friendly caching where possible
- use compatibility mode on lower-headroom devices without reducing learning value
- ensure accessibility and low-motion alternatives

## Success criteria

A child should be able to:
- identify important Shivaji Maharaj sites on a map
- place at least some of them from memory
- understand broad direction and distance to a site
- connect place to event and meaning
