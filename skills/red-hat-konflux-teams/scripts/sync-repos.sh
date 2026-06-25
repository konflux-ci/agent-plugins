#!/usr/bin/env bash
# Fetch repos from all tracked GitHub orgs and regenerate reference docs.
#
# Usage: ./scripts/sync-repos.sh
#
# Requires: gh CLI (authenticated), python3, PyYAML

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORGS=(konflux-ci hermetoproject conforma)

{
  for org in "${ORGS[@]}"; do
    gh repo list "$org" --limit 500 --json name,isArchived \
      --jq ".[] | select(.isArchived == false) | \"${org}/\" + .name"
  done
} | python3 "$SCRIPT_DIR/generate-references.py"
