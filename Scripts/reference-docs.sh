#!/bin/bash
# Generates the Jazzy reference documentation into docs/ for the version in .env.

set -euo pipefail

source .env

echo "Generating Jazzy Reference Documentation for version $CONTENTFUL_SDK_VERSION of the SDK"

bundle exec jazzy \
  --clean \
  --output docs \
  --author Contentful \
  --author_url https://www.contentful.com \
  --github_url https://github.com/contentful/contentful.swift \
  --github-file-prefix "https://github.com/contentful/contentful.swift/tree/$CONTENTFUL_SDK_VERSION" \
  --xcodebuild-arguments "-workspace,Contentful.xcworkspace,-scheme,Contentful_iOS,-destination,generic/platform=iOS,-derivedDataPath,build/DerivedData-docs" \
  --module-version "$CONTENTFUL_SDK_VERSION" \
  --module Contentful \
  --theme apple
