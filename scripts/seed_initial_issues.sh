#!/usr/bin/env bash
set -euo pipefail
REPO="${1:?usage: seed_initial_issues.sh owner/repo}"
create_issue() {
  local title="$1" body="$2" milestone="$3"
  shift 3
  local labels=("$@")
  if gh issue list --repo "$REPO" --state all --limit 200 --json title --jq '.[].title' | grep -Fxq "$title"; then
    echo "Issue exists: $title"
    return
  fi
  cmd=(gh issue create --repo "$REPO" --title "$title" --body "$body" --milestone "$milestone")
  for label in "${labels[@]}"; do
    cmd+=(--label "$label")
  done
  "${cmd[@]}"
}
create_issue "Research: define product opportunity and thesis" $'Create the first research note clarifying the product opportunity, user value, landscape, and initial thesis.\n\nDeliverable: `docs/research/2026-04-12-product-opportunity-and-thesis.md`' "Research & Discovery" research priority/high status/backlog
create_issue "Spec: repository workflow and planning operating model" $'Document how specs, research, issues, milestones, and project tracking work together in this repo.\n\nDeliverable: `docs/specs/2026-04-12-repo-operating-model.md`' "Foundation" spec documentation priority/high status/backlog
create_issue "Feature: set up initial project workflow conventions" $'Finalize project workflow conventions and ensure issues/docs follow the same system.' "Foundation" feature documentation priority/medium status/backlog
