#!/usr/bin/env bash
set -euo pipefail
REPO="${1:?usage: bootstrap_milestones.sh owner/repo}"
for title in "Foundation" "Research & Discovery" "MVP"; do
  if ! gh api "repos/$REPO/milestones" --paginate --jq '.[].title' | grep -Fxq "$title"; then
    gh api "repos/$REPO/milestones" --method POST -f title="$title" >/dev/null
    echo "Created milestone: $title"
  else
    echo "Milestone exists: $title"
  fi
done
