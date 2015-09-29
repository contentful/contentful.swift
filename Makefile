.PHONY: test setup

test:
	xcodebuild -workspace Contentful.xcworkspace \
		-scheme Contentful -sdk iphonesimulator test

setup:
	bundle install
	bundle exec pod install --no-repo-update
