.PHONY: test setup lint

test:
	xcodebuild -workspace Contentful.xcworkspace \
		-scheme Contentful -sdk iphonesimulator test

setup:
	bundle install
	bundle exec pod install --no-repo-update

lint:
	bundle exec pod lib lint Contentful.podspec
