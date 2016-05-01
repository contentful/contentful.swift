__SIM_ID=`xcrun simctl list|egrep -m 1 '$(SIM_NAME) \([^(]*\) \([^(]*\)$$'|sed -e 's/.* (\(.*\)) (.*)/\1/'`
SIM_NAME=iPhone 4s
SIM_ID=$(shell echo $(__SIM_ID))

ifeq ($(strip $(SIM_ID)),)
$(error Could not find $(SIM_NAME) simulator)
endif

.PHONY: test setup lint coverage

test:
	xcodebuild -workspace Contentful.xcworkspace \
		-scheme Contentful -destination 'id=$(SIM_ID)' test

setup:
	bundle install
	bundle exec pod install --no-repo-update

lint:
	bundle exec pod lib lint Contentful.podspec

coverage:
	bundle exec slather coverage -s Contentful.xcodeproj

carthage:
	carthage build --no-skip-current --platform iOS
	carthage archive Contentful
