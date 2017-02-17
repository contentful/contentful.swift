__SIM_ID=`xcrun simctl list|egrep -m 1 '$(SIM_NAME) \([^(]*\) \([^(]*\)$$'|sed -e 's/.* (\(.*\)) (.*)/\1/'`
SIM_NAME=iPhone 5s
SIM_ID=$(shell echo $(__SIM_ID))

ifeq ($(strip $(SIM_ID)),)
$(error Could not find $(SIM_NAME) simulator)
endif

.PHONY: open test setup lint coverage carthage

open:
	open Contentful.xcodeproj

clean:
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData/*

clean_simulators: kill_simulator
	xcrun simctl erase all

kill_simulator:
	killall "Simulator" || true

test: clean clean_simulators
	xcodebuild test -project Contentful.xcodeproj \
		-scheme Contentful_iOS -destination 'id=$(SIM_ID)' OTHER_SWIFT_FLAGS="-warnings-as-errors" | xcpretty -c

setup:
	bundle install
	bundle exec pod install --no-repo-update

lint:
	bundle exec pod lib lint Contentful.podspec

coverage:
	bundle exec slather coverage -s Contentful.xcodeproj

carthage:
	carthage build --no-skip-current --platform all
	carthage archive Contentful

