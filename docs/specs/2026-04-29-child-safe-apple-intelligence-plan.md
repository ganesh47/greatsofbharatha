# Child-Safe Apple Intelligence Plan

Greats of Bharatha should use Apple Intelligence only as a helper around curated lesson content, not as an open-ended chatbot.

## Linked issue

Refs #118 — TestFlight child-friendly Chapter 1 UX, voice navigation, and Apple Intelligence planning feedback.

## Release-safe hooks

- `GBChildSafeAIPlan` stores the current policy in compile-safe Swift with no dependency on unavailable SDK symbols.
- `GBIntelligenceHint` may use Foundation Models only behind `#if canImport(FoundationModels)` and an OS availability check.
- Voice command planning is limited to constrained commands: `next`, `repeat`, `help`, and `stop`.

## Guardrails

- Use curated facts from the lesson model as the only allowed fact source.
- Prefer on-device processing. Do not send child voice or lesson answers to a network service for the core flow.
- Generate at most one short hint at a time. Do not create free-form historical chat.
- Keep microphone-based commands feature-gated until App Intents/Speech recognition UX, permissions, and parental expectations are reviewed.

## Asset provenance

- The shipped Chapter 1 story illustration and app icon are prompt-generated originals that were resized into the asset catalog variants.
- No script-generated story or icon art remains in this branch.

## Later integration path

1. Add App Intents for `next`, `repeat`, `help`, and `stop` once the supported deployment/toolchain target is confirmed.
2. Route intents into the existing lesson phase and `GBNarrator` actions.
3. Use Foundation Models only to rewrite approved hint ladder text into simpler wording, with fallback to static hints.
4. Add UI tests for the no-mic core flow so narration remains usable without speech recognition permission.
