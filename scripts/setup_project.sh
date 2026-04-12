#!/usr/bin/env bash
set -euo pipefail
OWNER="${1:?usage: setup_project.sh owner repo}"
REPO="${2:?usage: setup_project.sh owner repo}"
PROJECT_TITLE="Greats of Bharatha Tracker"
OWNER_ID=$(gh api graphql -f query='query($login:String!){ user(login:$login){ id }}' -F login="$OWNER" --jq '.data.user.id')
EXISTING=$(gh project list --owner "$OWNER" --format json | jq -r '.projects[] | select(.title=="'"$PROJECT_TITLE"'") | .number' | head -n1)
if [ -z "$EXISTING" ]; then
  PROJECT_NUM=$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json | jq -r '.number')
else
  PROJECT_NUM="$EXISTING"
fi
echo "$PROJECT_NUM"
