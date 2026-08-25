# Architecture

`contentful.swift` is the Swift client for Contentful's Content Delivery API
(CDA) and Content Preview API (CPA). It is read-only — there is no management or
write surface here — and it ships with **no runtime dependencies**, which keeps
consumer app size down and keeps the SDK installable through CocoaPods,
Carthage, and Swift Package Manager alike.

This file is the map. For the long-form reference on the protocol design, the
Xcode/Carthage build system, and the reasoning behind the distribution setup,
see [ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md). Deliberate
choices with lasting consequences are recorded in [docs/ADRs/](docs/ADRs/).

## Repository layout

```
Sources/Contentful/          the SDK — one module, flat, plus three subfolders
  UIKit/                     iOS / tvOS / watchOS extensions
  AppKit/                    macOS extensions
  ImageOptions/              image transformation API (a CocoaPods subspec)
Tests/ContentfulTests/       24 test files
  DVRRecordings/             recorded HTTP cassettes replayed by DVR
  Fixtures/                  raw JSON fixtures
Tests/Helpers/Models/        Cat, Dog, City — the EntryDecodable test models
Supporting Files/            umbrella header + per-platform Info plists
Scripts/                     setup-env, set-version, reference-docs, release
  BuildPhases/swiftlint.sh   SwiftLint, invoked from the Xcode build phase
Contentful.xcworkspace/      the entry point for local development
fastlane/Fastfile            the lanes CircleCI runs
docs/                        generated Jazzy site (published to gh-pages)
docs/ADRs/                   architecture decision records
```

## Runtime shape

The public surface is one module, `Contentful`, built around a single client
type. There is no layered service/repository indirection — the client owns the
`URLSession` and the decoding pipeline directly.

- **`Client`** (`Client.swift`) is the entry point. It is `open`, holds a
  `ClientConfiguration`, a `spaceId`, an `environmentId`, a `host`, and the
  `URLSession`. Requests complete through
  `ResultsHandler<T> = (Result<T, Error>) -> Void`.
  `Client+Fetch.swift` and `Client+Sync.swift` split the fetch and
  synchronization surfaces into extensions; `Client+UIKit.swift` and
  `Client+AppKit.swift` add the platform-specific image fetching.
- **`Endpoint`** (`Endpoints.swift`) enumerates the five API paths the SDK
  talks to — `spaces` (the base path), `content_types`, `entries`, `assets`,
  `locales`, and `sync`. Adding a new API surface starts here.
- **Model types** map one-to-one to CDA resources: `Entry`, `Asset`,
  `ContentType`, `Field`, `FieldType`, `Space`, `Locale`, `Link`, `Sys`,
  `Location`, `Metadata`, `ArrayResponse`, `SyncSpace`, `RichText`.
- **Decoding** goes through `Decodable.swift` and `JSONDecoderBuilder.swift`.
  The client injects the space's `LocalizationContext` into the decoder builder
  so that the `fields` dictionary of entries and assets is normalized against
  the locale fallback chain before user code sees it. `Date.swift` and
  `DateFormatterCache.swift` handle ISO-8601 parsing.
- **Link resolution** is two-phase. `LinkResolver` registers a callback per
  unresolved `Link` while decoding, backed by a `DataCache` keyed as
  `<id>_<linktype>_`; once the whole response is decoded, the callbacks fire and
  both caches are cleared. This is why a linked property on an
  `EntryDecodable` is assigned inside a `resolveLink(forKey:decoder:)` closure
  rather than returned from `init(from:)`.
- **Querying** is in `Query.swift`, `QueryOperation.swift`, and
  `TypedQuery.swift`. Types conforming to `FieldKeysQueryable` get compile-time
  checked queries — `QueryOn<Cat>.where(field: .color, .equals("gray"))` becomes
  `content_type=cat&fields.color=gray`.
- **Persistence** is a delegate boundary, not an implementation. `Client` holds
  an optional `persistenceIntegration`; the `PersistenceIntegration` protocol in
  `Persistence.swift` receives create/update/delete messages during `sync`
  calls. The CoreData implementation lives in a separate repository,
  [contentful-persistence.swift](https://github.com/contentful/contentful-persistence.swift).
  Setting the integration rebuilds the `URLSession` because its user-agent
  header has to be regenerated.
- **Logging** goes through `ContentfulLogger.swift`.

The protocol hierarchy consumers actually implement — `Resource`,
`FlatResource`, `AssetProtocol`, `EntryDecodable`, `FieldKeysQueryable` — is
documented in detail in
[ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md#sdk-architecture-and-important-protocols).

## Multi-platform structure

All four Cocoa platforms are supported from one source tree. Platform-specific
code is guarded with `#if os(...)` and, where it needs its own file, split into
`Sources/Contentful/UIKit/` and `Sources/Contentful/AppKit/`. Four shared Xcode
schemes exist — `Contentful_iOS`, `Contentful_macOS`, `Contentful_tvOS`,
`Contentful_watchOS` — and tests run against the first three; Apple ships no
unit testing framework for watchOS.

Minimum deployment targets are declared in `Contentful.podspec`: iOS 12.0,
macOS 10.13, tvOS 12.0, watchOS 4.0. Raising any of them is a breaking change.

## Build and dependency management

Three package managers are supported simultaneously, and each one constrains the
project differently:

- **Xcode / Carthage** — `Contentful.xcworkspace` wraps
  `Contentful.xcodeproj` and the playground, and nothing else. Carthage supplies
  the *test* dependencies pinned in `Cartfile.private` /
  `Cartfile.resolved`; CI resolves them with
  `carthage update --use-xcframeworks`. Note that
  `Scripts/setup-env.sh` still runs the older
  `carthage bootstrap --use-submodules --no-build`, and the parts of
  `ARCHITECTURE-BUILD-CONFIG.md` describing `Carthage/Checkouts` as
  version-controlled submodules describe the pre-2024 setup — those submodules
  and their workspace references were removed in `7d2399e`, and `.gitmodules` is
  now empty.
- **Swift Package Manager** — `Package.swift` (swift-tools-version 5.3)
  declares the `Contentful` library target and a `ContentfulTests` test target
  at `path: "Tests"`, with `Package.resolved` pinning the test dependencies.
- **CocoaPods** — `Contentful.podspec` is a Ruby file that reads its version
  from `.env` via the `dotenv` gem, declares per-platform `source_files`, and
  exposes `ImageOptions` as a subspec.

Both test-dependency manifests point at Contentful-maintained forks of DVR and
OHHTTPStubs rather than upstream; see
[docs/ADRs/2026-08-25-vendor-forked-test-http-stubbing-dependencies.md](docs/ADRs/2026-08-25-vendor-forked-test-http-stubbing-dependencies.md).

The version number is duplicated in `Config.xcconfig` (read by the Xcode project
and injected into the `X-Contentful-User-Agent` header) and `.env` (read by the
podspec and sourced by the release and docs scripts). `Scripts/set-version.sh`
writes both so they cannot drift.

Ruby tooling is pinned through `Gemfile` / `Gemfile.lock` (`_ruby-version` is
3.0.5) and covers cocoapods, jazzy, slather, xcpretty, and fastlane. Renovate
(`renovate.json`, extending `contentful/renovate-config`) handles bumps.

## Testing strategy

Assertions are plain `XCTest`. Nimble was integrated, pruned, reintegrated, and
pruned again — the standing guidance in
[ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md#dependencies-and-testing)
is not to bring it back, because third-party matcher frameworks kept breaking
command-line builds for tvOS and macOS.

Network traffic is stubbed, not live: DVR replays 17 recorded cassettes in
`Tests/ContentfulTests/DVRRecordings/`, and OHHTTPStubs covers the one case that
needs a hand-built response — `ErrorTests.swift` stubs
`/spaces/cfexampleapi` to return a body the SDK cannot parse. That keeps the
suite fast and immune to content drift in the Contentful spaces the recordings
came from — and it means a normal test run needs no credentials.

`Makefile` has an `integration_test` target that builds the `API_Coverage`
configuration. `Scripts/integration-test.sh` still calls the Travis API and is
not wired into the current CircleCI config.

## CI and release

CircleCI (`.circleci/config.yml`, macOS image with Xcode 15.4) runs four jobs on
every pull request — `test-ios`, `test-macos`, `test-tvos`, and `build` — each
installing Carthage, running `carthage update --use-xcframeworks`,
`bundle install`, and then the matching `bundle exec fastlane` lane. The `build`
lane shells out to `swift build` so the SPM path stays verified.
`.github/workflows/codeql.yml` adds CodeQL scanning. SwiftLint skips itself in
CI (`Scripts/BuildPhases/swiftlint.sh` exits early when `CIRCLECI` is set).

`old-travis-config.yml` is the retired Travis configuration, kept for reference;
parts of `ARCHITECTURE-BUILD-CONFIG.md` still describe that era. The move to
CircleCI plus fastlane happened in `7d2399e`.

Releases run from `master` via `make release` (`Scripts/release.sh`): tag, push
to the CocoaPods trunk, build the XCFramework, regenerate the Jazzy docs onto
`gh-pages`. The XCFramework zip is attached to the GitHub release by hand.
Ownership is `group:team-developer-experience` (`catalog-info.yaml`,
`.github/CODEOWNERS`); service tier 4.
