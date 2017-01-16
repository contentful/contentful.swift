#!/bin/sh

set -x -o pipefail

echo "Building"

rm -rf ${HOME}/Library/Developer/Xcode/DerivedData/*

# -jobs -- specify the number of concurrent jobs
# `sysctl -n hw.ncpu` -- fetch number of 'logical' cores in macOS machine
xcodebuild -jobs `sysctl -n hw.ncpu` test -workspace Contentful.xcworkspace -scheme Contentful \
  -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 6s,OS=9.3" \
    ONLY_ACTIVE_ARCH=NO CODE_SIGNING_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty -c

