#!/bin/bash
# Sets the SDK version in every file that carries it.
#   .env             -> read by Contentful.podspec (dotenv) and by the release/docs scripts
#   Config.xcconfig  -> base configuration of Contentful.xcodeproj (CONTENTFUL_SDK_VERSION)
#
# Usage: ./Scripts/set-version.sh X.Y.Z

set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: $0 X.Y.Z" >&2
  exit 1
fi

for file in .env Config.xcconfig; do
  echo "CONTENTFUL_SDK_VERSION=$VERSION" > "$file"
done

echo "SDK version set to $VERSION in .env and Config.xcconfig"
