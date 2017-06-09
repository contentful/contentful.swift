#!/bin/sh

set -x -o pipefail

echo "Building"

rm -rf ${HOME}/Library/Developer/Xcode/DerivedData/*

# -jobs -- specify the number of concurrent jobs
# `sysctl -n hw.ncpu` -- fetch number of 'logical' cores in macOS machine
xcodebuild -jobs `sysctl -n hw.ncpu` test -project Contentful.xcodeproj -scheme Contentful_iOS \
  -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 6s,OS=9.3" \
    ONLY_ACTIVE_ARCH=YES CODE_SIGNING_IDENTITY="" CODE_SIGNING_REQUIRED=NO OTHER_SWIFT_FLAGS="-warnings-as-errors" | bundle exec xcpretty -c

