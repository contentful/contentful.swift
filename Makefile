__SIM_ID=`xcrun simctl list|egrep -m 1 '$(SIM_NAME) \([^(]*\) \([^(]*\)$$'|sed -e 's/.* (\(.*\)) (.*)/\1/'`
SIM_NAME=iPhone 5s
SIM_ID=$(shell echo $(__SIM_ID))

ifeq ($(strip $(SIM_ID)),)
$(error Could not find $(SIM_NAME) simulator)
endif

PROJECT=Contentful.xcodeproj

.PHONY: open test integration_test setup lint coverage carthage docs

open:
	open $(PROJECT)

clean:
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData/*

clean_simulators: kill_simulator
	xcrun simctl erase all

kill_simulator:
	killall "Simulator" || true

test: clean clean_simulators
	set -x -o pipefail && xcodebuild test -project $(PROJECT) \
		-scheme Contentful_iOS -destination 'id=$(SIM_ID)' \
		OTHER_SWIFT_FLAGS="-warnings-as-errors" | xcpretty -c

integration_test: clean clean_simulators
	set -x -o pipefail && xcodebuild test -project $(PROJECT) \
		-scheme Contentful_iOS -configuration "API_Coverage" \
		-destination 'platform=iOS Simulator,name=iPhone 6s,OS=9.3' | xcpretty -c

setup:
	bundle install
	bundle exec pod install --no-repo-update

lint:
	bundle exec pod lib lint Contentful.podspec

coverage:
	bundle exec slather coverage -s $(PROJECT)

carthage:
	carthage build --no-skip-current --platform all
	carthage archive Contentful

docs:
	./Scripts/reference-docs.sh

