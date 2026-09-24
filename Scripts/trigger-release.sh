#!/bin/bash
# Starts the CircleCI release pipeline for the version currently on origin/master.
# Same as CircleCI UI: Trigger Pipeline -> branch master -> parameter run-release = true.
#
# Usage: CIRCLE_TOKEN=<personal API token> ./Scripts/trigger-release.sh [--yes]
#   Create the token at https://app.circleci.com/settings/user/tokens

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT_SLUG="gh/contentful/contentful.swift"

: "${CIRCLE_TOKEN:?Set CIRCLE_TOKEN to a CircleCI personal API token (https://app.circleci.com/settings/user/tokens)}"

git fetch --quiet origin master
VERSION="$(git show origin/master:.env | sed -n 's/^CONTENTFUL_SDK_VERSION=//p' | tr -d '[:space:]')"
COMMIT="$(git rev-parse --short origin/master)"

if git ls-remote --exit-code --tags origin "refs/tags/$VERSION" >/dev/null 2>&1; then
  echo "ERROR: origin/master has version $VERSION, which is already tagged." >&2
  echo "Merge a version bump (./Scripts/set-version.sh X.Y.Z) to master first." >&2
  exit 1
fi

echo "About to release contentful.swift $VERSION from origin/master ($COMMIT)."
if [[ "${1:-}" != "--yes" ]]; then
  read -r -p "Type the version to confirm: " answer
  [[ "$answer" == "$VERSION" ]] || { echo "Aborted."; exit 1; }
fi

response="$(curl -fsS -X POST "https://circleci.com/api/v2/project/$PROJECT_SLUG/pipeline" \
  -H "Circle-Token: $CIRCLE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"branch": "master", "parameters": {"run-release": true}}')"

number="$(printf '%s' "$response" | sed -n 's/.*"number" *: *\([0-9]*\).*/\1/p')"
echo "Release pipeline #${number:-?} started:"
echo "https://app.circleci.com/pipelines/$PROJECT_SLUG/${number}"
