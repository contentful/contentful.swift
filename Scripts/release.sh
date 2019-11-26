#!/bin/sh 

source .env

echo "Making release for version $CONTENTFUL_SDK_VERSION of the SDK"


git tag $CONTENTFUL_SDK_VERSION
git push --tags
bundle exec pod trunk push Contentful.podspec --allow-warnings
make carthage
git checkout gh-pages
git rebase master
./Scripts/reference-docs.sh
git add .
git commit --amend --no-edit
git push -f

echo "Contentful v$CONTENTFUL_SDK_VERSION is officially released! Attach the binary found at Contentful.framework.zip to the release on Github"
