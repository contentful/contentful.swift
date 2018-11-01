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
		-scheme Contentful_iOS -destination 'platform=iOS Simulator,name=iPhone X,OS=12.1' | bundle exec xcpretty -c

integration_test: clean clean_simulators
	set -x -o pipefail && xcodebuild test -workspace $(WORKSPACE) \
		-scheme Contentful_iOS -configuration "API_Coverage" \
		-destination 'platform=iOS Simulator,name=iPhone X,OS=12.1' | bundle exec xcpretty -c

setup_env:
	./Scripts/setup-env.sh

lint:
	swiftlint
	bundle exec pod lib lint Contentful.podspec

coverage:
	bundle exec slather coverage -s  

carthage:
	carthage build Contentful --no-skip-current --platform all
	carthage archive Contentful

docs:
	./Scripts/reference-docs.sh

release:
	./Scripts/release.sh

