# Repository workflow and planning operating model

- Status: Draft
- Linked issue: #3
- Milestone: Foundation
- Owner: @ganesh47
- Last updated: 2026-04-12

## Problem

Product work becomes messy when specs, research, tasks, and roadmap state live in different systems without a clear source of truth.

## Goals

- Keep planning and delivery visible in GitHub
- Track specs and research as first-class artifacts in the repo
- Use issues and milestones to coordinate active work
- Make it easy to start research and convert findings into specs/features

## Non-goals

- Full PM process bureaucracy
- Over-automating every GitHub action on day one

## Scope

This operating model covers repository structure, issue types, labels, milestones, research notes, specs, and basic automation.

## UX / product behavior

- New ideas start as issues
- Research is written in `docs/research/`
- Specs are written in `docs/specs/`
- Delivery work is tracked in feature or bug issues
- Milestones group work by phase

## Technical notes

Current automation:
- issue templates
- stale workflow
- doc linkage check
- basic issue hygiene check

## Risks

- Labels drift without discipline
- Project fields may need manual refinement in the GitHub UI

## Open questions

- Whether to enforce project membership for every issue
- Whether to sync doc frontmatter more strictly

## Delivery plan

1. Seed initial issues
2. Start product opportunity research
3. Refine tracker workflow once real work begins
