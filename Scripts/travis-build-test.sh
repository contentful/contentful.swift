#!/bin/sh

set -x -o pipefail

echo "Building"

rm -rf ${HOME}/Library/Developer/Xcode/DerivedData/*

# -jobs -- specify the number of concurrent jobs
# `sysctl -n hw.ncpu` -- fetch number of 'logical' cores in macOS machine
xcodebuild -jobs `sysctl -n hw.ncpu` test -workspace Contentful.xcworkspace -scheme ${SCHEME} \
  -sdk ${SDK} -destination "platform=${PLATFORM}" ONLY_ACTIVE_ARCH=YES CODE_SIGNING_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
   OTHER_SWIFT_FLAGS="-warnings-as-errors" | bundle exec xcpretty -c

