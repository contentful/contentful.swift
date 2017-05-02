#!/bin/sh

echo "Generating Jazzy Reference Documentation"

SDK_VERSION=0.4.0-beta1

bundle exec jazzy \
  --clean \
  --author Contentful \
  --author_url https://www.contentful.com \
  --github_url https://github.com/contentful/contentful.swift \
  --github-file-prefix https://github.com/contentful/contentful.swift/tree/$SDK_VERSION \
  --module-version $SDK_VERSION \
  --module Contentful \
  --theme apple
#  --root-url https://realm.io/docs/swift/$SDK_VERSION/api/ \

