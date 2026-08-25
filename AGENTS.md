# AGENTS.md

Orientation for coding agents working in `contentful.swift`, the Swift client
for Contentful's Content Delivery and Content Preview APIs.

Read this first, then [ARCHITECTURE.md](ARCHITECTURE.md) for the layout and
[CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.
[ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md) is the deep
reference on protocol design and the build system.

## What this repo is

- A read-only client. Delivery and Preview only — there is no Management API
  surface here, so a request to "add a write/publish method" is out of scope for
  this repo.
- **Zero runtime dependencies.** `Package.swift` declares dependencies only for
  the test target. Do not add a runtime dependency; it is a deliberate,
  load-bearing constraint (app size, and installability through all three
  package managers).
- Multi-platform: iOS, macOS, tvOS, watchOS, from one source tree.
- Distributed through CocoaPods, Carthage, **and** SwiftPM at the same time.

## Default branch

`master`, not `main`. Branch from and open pull requests against `master`.

## Commands that actually exist

Everything below is defined in the `Makefile`, `fastlane/Fastfile`, or
`Scripts/`. Do not substitute conventional Swift commands for these.

```bash
make setup_env                 # Scripts/setup-env.sh: brew + bundle + carthage bootstrap
make open                      # opens Contentful.xcworkspace
make lint                      # swiftlint, then bundle exec pod lib lint Contentful.podspec
make docs                      # Scripts/reference-docs.sh (jazzy)
make release                   # Scripts/release.sh — maintainers only
./Scripts/set-version.sh 5.5.16

bundle exec fastlane test_ios
bundle exec fastlane test_macos
bundle exec fastlane test_tvos
bundle exec fastlane build     # swift build only
```

Notes before you run anything:

- Open `Contentful.xcworkspace`, never `Contentful.xcodeproj` on its own.
- `make test` exists but pins the `iPhone X, OS=12.1` simulator destination,
  which will not resolve on a modern toolchain. Use the fastlane lanes — those
  are what CircleCI runs.
- Ruby tools must be prefixed with `bundle exec`. `_ruby-version` is 3.0.5.
- Tests replay recorded HTTP, so they need **no** Contentful credentials.
- The build requires macOS and Xcode. On any other platform you can read and
  edit, but you cannot verify — say so rather than claiming a green build.

## Where to make changes

| Change | File |
| --- | --- |
| Request/response plumbing, session, config | `Sources/Contentful/Client.swift`, `ClientConfiguration.swift` |
| Fetch or sync surface | `Client+Fetch.swift`, `Client+Sync.swift` |
| A new API path | `Endpoints.swift` (the `Endpoint` enum) |
| Decoding, locale normalization | `Decodable.swift`, `JSONDecoderBuilder.swift` |
| Link/relationship resolution | `LinkResolver.swift`, `DataCache.swift` |
| Query building | `Query.swift`, `QueryOperation.swift`, `TypedQuery.swift` |
| Image transformations | `Sources/Contentful/ImageOptions/ImageOptions.swift` |
| iOS/tvOS/watchOS-only code | `Sources/Contentful/UIKit/` |
| macOS-only code | `Sources/Contentful/AppKit/` |
| Test models | `Tests/Helpers/Models/` (`Cat`, `Dog`, `City`) |

## Constraints that will bite you

- **A new source file must be added to all four framework targets** in
  `Contentful.xcodeproj`, not just SwiftPM. SwiftPM globs `Sources/`; Xcode does
  not. A file that only builds under `swift build` will fail CI's iOS, macOS,
  and tvOS jobs.
- **CocoaPods needs the file to match a `source_files` glob** in
  `Contentful.podspec`. The globs are one level deep per directory
  (`Sources/Contentful/*.swift`, `Sources/Contentful/UIKit/*.swift`, etc.), so a
  new subdirectory needs a new glob or subspec or it silently ships empty.
- **The version number lives in two files.** `Config.xcconfig` and `.env` must
  match. Always change them with `./Scripts/set-version.sh`, never by hand.
- **Deployment targets in `Contentful.podspec`** (iOS 12.0, macOS 10.13,
  tvOS 12.0, watchOS 4.0) — raising any of them is a breaking change requiring a
  major version bump.
- **Link resolution is deferred.** Linked fields on an `EntryDecodable` are
  assigned inside a `resolveLink(forKey:decoder:)` closure that runs after the
  whole response is decoded, so do not expect a linked value to be available
  inside `init(from:)`.
- **Do not reintroduce Nimble** or another matcher framework. It has been
  removed twice; assertions are plain `XCTest` on purpose. See
  [ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md#dependencies-and-testing).
- **Test dependencies point at Contentful forks** of DVR and OHHTTPStubs, in
  both `Cartfile.private` and `Package.swift`. Do not "fix" them back to
  upstream — see
  [docs/ADRs/2026-08-25-vendor-forked-test-http-stubbing-dependencies.md](docs/ADRs/2026-08-25-vendor-forked-test-http-stubbing-dependencies.md).
  If you change one manifest, change the other; they must stay in sync.
- **`docs/` is generated output** from Jazzy, published to `gh-pages`. Do not
  hand-edit it. `docs/ADRs/` is the one hand-written subtree.
- **`.env` and `Config.xcconfig` are tracked** and contain only
  `CONTENTFUL_SDK_VERSION`. Never add credentials to either.
- SwiftLint (`.swiftlint.yml`) lints `Sources` only, with a 150-char line-length
  warning and a number of rules deliberately disabled.
- `RateLimitTests.swift` is present but its body is commented out; it asserts
  nothing today. Do not treat it as coverage.

## Conventions

- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`. Put the Jira key in
  brackets when there is one, e.g. `fix: resolve decoding crash [DX-1234]`.
- Every source file starts with the existing header comment block
  (filename, module, author, copyright) — match it.
- Public API carries doc comments; Jazzy publishes them.
- Add a `CHANGELOG.md` entry for anything user-facing.
- Review is owned by `@contentful/team-developer-experience`
  (`.github/CODEOWNERS`, `catalog-info.yaml`).

## Definition of done

CircleCI must be green on `test-ios`, `test-macos`, `test-tvos`, and `build`.
`build` runs `swift build`, so all three package-manager paths stay exercised —
if you touched project structure, confirm the change lands in the Xcode targets,
the podspec globs, and `Package.swift`.
