#!/usr/bin/env bash
set -euo pipefail
REPO="${1:?usage: bootstrap_labels.sh owner/repo}"
create_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force
}
create_label spec 5319e7 "Specification work"
create_label research 0e8a16 "Research and discovery"
create_label feature 1d76db "Feature delivery"
create_label bug d73a4a "Bug report or fix"
create_label documentation 0075ca "Documentation work"
create_label priority/critical b60205 "Highest priority"
create_label priority/high d93f0b "High priority"
create_label priority/medium fbca04 "Medium priority"
create_label priority/low c2e0c6 "Low priority"
create_label status/backlog cfd3d7 "Queued work"
create_label status/active 0052cc "In progress"
create_label status/blocked bfd4f2 "Blocked"
create_label status/stale e4e669 "Inactive / stale"
