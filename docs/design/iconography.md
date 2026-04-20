# Iconography policy

## Core rule

Use **SF Symbols first** for product shell, navigation, system actions, and common interaction metaphors.

Why:
- best native rendering in SwiftUI
- accessibility and variable weight support
- strong cross-platform path across iPhone, iPad, and future tvOS
- lower maintenance than importing large third-party packs

## When custom/open-source icons are allowed

Use supplementary open-source icons only when SF Symbols does not express the product meaning well enough, especially for:
- fort/place markers
- Chronicle categories
- historical motifs
- collectible seals or emblems

Recommended supplementary source options:
- **Tabler Icons** (MIT)
- **Phosphor Icons** (MIT)

Pick one family for supplementation. Do not mix several packs casually.

## Usage rules

- navigation and shell icons should remain stable and mostly SF Symbols based
- custom icons should be limited to domain-specific meaning, not basic UI chrome
- imported icons must be normalized for stroke weight, corner feel, and optical size
- only import the approved icons actually used by the app
- document every imported icon in a manifest

## Recommended manifest fields

- local asset name
- semantic meaning
- source library
- source URL
- license
- date imported
- screens/components using it
- notes on edits or normalization

## Visual language guidance

- **Learn / story** icons should feel narrative and guiding
- **Places** icons should feel spatial and discoverable
- **Chronicle** icons should feel ceremonial, collectible, and memory-bearing
- challenge-state icons must read clearly at small sizes
- never rely on icon shape alone to communicate state

## Current recommendation for GreatsOfBharatha

1. keep shell and most UI actions on SF Symbols
2. use custom/open-source icons only for high-value domain surfaces
3. create a repo-local attribution manifest before importing any non-SF symbol assets
4. prefer consistency and meaning over novelty
