#!/bin/sh

if $TRAVIS == true; then
  exit 0  
fi

if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi

