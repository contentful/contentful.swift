# Contributing to contentful.swift

We appreciate any help on this repository. Bug reports, feature proposals, and
pull requests are all welcome — see the [Reach out to us](README.md#reach-out-to-us)
section of the README for where to raise which kind of issue.

## Development and versioning

Development should be done with Xcode as a strict requirement of the project is that iOS, macOS, tvOS, and watchOS stay supported. This, in turn, means that development will be done on a Mac, and it is therefore required that [homebrew](https://brew.sh/) is installed. The `make setup_env` command will install or update the necessary brew packages required to work on the contentful.swift project (note that it will not install homebrew for you).

## Setting up your environment

```bash
make setup_env
```

`Scripts/setup-env.sh` (which `make setup_env` invokes) installs or upgrades
`carthage` and `swiftlint` via Homebrew, runs `bundle install` for the Ruby
tooling in the `Gemfile` (cocoapods, jazzy, slather, xcpretty, fastlane), and
resolves the test dependencies with
`carthage bootstrap --use-submodules --no-build`.

The Ruby version this project is developed against is in `_ruby-version`
(currently 3.0.5). Always prefix the Ruby-backed tools with `bundle exec` so you
get the versions pinned in `Gemfile.lock` — for example
`bundle exec pod trunk push`, not `pod trunk push`.

Open the project through the workspace, never the bare `.xcodeproj`:

```bash
make open   # opens Contentful.xcworkspace
```

## Project layout

- `Sources/Contentful/` — the SDK. Platform-specific code lives in
  `Sources/Contentful/UIKit/` (iOS, tvOS, watchOS),
  `Sources/Contentful/AppKit/` (macOS), and `Sources/Contentful/ImageOptions/`
  (shipped as a CocoaPods subspec).
- `Tests/ContentfulTests/` — the test suite, with stubbed HTTP responses in
  `Tests/ContentfulTests/DVRRecordings/` and JSON fixtures in
  `Tests/ContentfulTests/Fixtures/`.
- `Tests/Helpers/Models/` — the `EntryDecodable` model types (`Cat`, `Dog`,
  `City`) that the tests decode against.
- `Scripts/` — environment setup, version bumping, docs generation, release.
- `Supporting Files/` — the umbrella header and per-platform `Info-*.plist`
  files for the four framework targets.

## Running tests

There are four shared schemes — `Contentful_iOS`, `Contentful_macOS`,
`Contentful_tvOS`, `Contentful_watchOS` — and tests run against the first three
(Apple ships no unit testing framework for watchOS).

Locally, either run the scheme from Xcode or use the fastlane lanes that CI
uses, which is the closest match to what the pipeline will do:

```bash
bundle exec fastlane test_ios
bundle exec fastlane test_macos
bundle exec fastlane test_tvos
bundle exec fastlane build      # verifies `swift build` still works
```

The `make test` target also exists but pins an old simulator destination
(`iPhone X, OS=12.1`); prefer the fastlane lanes unless you have that runtime
installed.

Most tests replay recorded HTTP traffic through DVR rather than hitting the
Contentful APIs, so a normal test run needs no credentials. If you add a test
that needs a new recording, commit the cassette alongside it.

`make integration_test` builds the `API_Coverage` configuration and is driven by
CI; `Scripts/integration-test.sh` still targets the old Travis API and is not
wired into the current CircleCI config.

## Linting

```bash
make lint    # swiftlint, then `bundle exec pod lib lint Contentful.podspec`
```

SwiftLint also runs as an Xcode build phase via
`Scripts/BuildPhases/swiftlint.sh`, which skips itself when `CIRCLECI` is set.
Rules live in `.swiftlint.yml`; it lints `Sources` only — `Tests`, `Carthage`,
and `Contentful.playground` are excluded.

## Commit messages and pull requests

- Commits follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `chore:`, `docs:`) — see `git log` for the house style.
- Reference the Jira ticket in brackets when there is one, e.g.
  `chore: set up Renovate for dependency updates [MEC-3447]`.
- Open pull requests against `master`. `.github/CODEOWNERS` assigns review to
  `@contentful/team-developer-experience`.
- CircleCI runs `test-ios`, `test-macos`, `test-tvos`, and `build` on every
  pull request; all four must be green.
- Add a `CHANGELOG.md` entry for anything user-facing.
- Dependency bumps arrive via Renovate (`renovate.json`).

## Changing the SDK version

The version lives in two files that must stay in sync — `Config.xcconfig`
(consumed by the Xcode project and injected into the `X-Contentful-User-Agent`
header) and `.env` (read by `Contentful.podspec` through the `dotenv` gem, and
sourced by the release and docs scripts). Use the script rather than editing
them by hand:

```bash
./Scripts/set-version.sh 5.5.16
```

Raising a minimum deployment target in `Contentful.podspec` is a breaking change
and requires a major version bump.

## Releasing

Releases are run from `master` by a maintainer with CocoaPods trunk push rights:

1. Bump the version with `./Scripts/set-version.sh`.
2. Add the release notes to `CHANGELOG.md`.
3. Run `make release` (`Scripts/release.sh`), which tags the version, pushes to
   the CocoaPods trunk, builds the XCFramework, and regenerates the Jazzy
   reference docs onto the `gh-pages` branch.
4. Attach `Carthage/Build/Contentful.xcframework` (zipped) to the GitHub release
   and copy the changelog entry into the release body.

## Further reading

[ARCHITECTURE.md](ARCHITECTURE.md) covers how the pieces fit together.
[ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md) is the long-form
reference on the protocol design, the build system, and the reasoning behind the
distribution setup. Decision records are in [docs/ADRs/](docs/ADRs/).
