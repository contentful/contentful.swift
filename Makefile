__SIM_ID=`xcrun simctl list|egrep -m 1 '$(SIM_NAME) \([^(]*\) \([^(]*\)$$'|sed -e 's/.* (\(.*\)) (.*)/\1/'`
SIM_NAME=iPhone 5s
SIM_ID=$(shell echo $(__SIM_ID))

ifeq ($(strip $(SIM_ID)),)
$(error Could not find $(SIM_NAME) simulator)
endif

WORKSPACE=Contentful.xcworkspace

.PHONY: open test integration_test setup lint coverage carthage docs release

open:
	open $(WORKSPACE)

clean:
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData/*

clean_simulators: kill_simulator
	xcrun simctl erase all

kill_simulator:
	killall "Simulator" || true

test: clean clean_simulators
	set -x -o pipefail && xcodebuild test -workspace $(WORKSPACE) \
		-scheme Contentful_iOS -destination 'id=$(SIM_ID)' | bundle exec xcpretty -c

integration_test: clean clean_simulators
	set -x -o pipefail && xcodebuild test -workspace $(WORKSPACE) \
		-scheme Contentful_iOS -configuration "API_Coverage" \
		-destination 'platform=iOS Simulator,name=iPhone 6s,OS=9.3' | bundle exec xcpretty -c

setup_env:
	./Scripts/setup-env.sh

lint:
	swiftlint
	bundle exec pod lib lint Contentful.podspec

coverage:
	bundle exec slather coverage -s  

carthage:
	carthage build --no-skip-current --platform all
	carthage archive Contentful

docs:
	./Scripts/reference-docs.sh

release:
	./Scripts/release.sh

