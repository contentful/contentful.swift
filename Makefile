.PHONY: test

test:
	xcodebuild -workspace Contentful.xcworkspace \
		-scheme Contentful -sdk iphonesimulator test
