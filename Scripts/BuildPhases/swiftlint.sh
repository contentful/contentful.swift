#!/bin/sh

# Exit if running on CircleCI
if [ "$CIRCLECI" == "true" ]; then
  exit 0  
fi

# Try the first hardcoded path
if [ -x "/usr/local/bin/swiftlint" ]; then
  /usr/local/bin/swiftlint ./Sources
  exit 0
fi

# Try the second hardcoded path
if [ -x "/opt/homebrew/bin/swiftlint" ]; then
  /opt/homebrew/bin/swiftlint ./Sources
  exit 0
fi

# Fallback to checking the generic `swiftlint` command in PATH
if which swiftlint >/dev/null; then
  swiftlint ./Sources
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi