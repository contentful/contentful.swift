# Consume the test HTTP-stubbing dependencies from Contentful-maintained forks

- **Date:** 2026-08-25 (record written); decision made 2024-08-16
- **Status:** Accepted

> This record was written on 2026-08-25 from the commit history. It documents an
> existing decision rather than a new one. The commits, diffs, and manifest state
> cited below are verifiable in this repository; where the original motivation
> was not written down, that is stated explicitly rather than guessed at.

## Context

The SDK ships with no runtime dependencies, but its test suite needs two
libraries to avoid hitting the Contentful APIs on every run:

- **DVR** — records and replays HTTP traffic as JSON cassettes
  (`Tests/ContentfulTests/DVRRecordings/`, 17 files).
- **OHHTTPStubs** — hand-built responses for cases no recording can express;
  used in `Tests/ContentfulTests/ErrorTests.swift` to return an unparsable body.

Until August 2024 both came from upstream, and both were consumed as git
submodules whose Xcode projects were pulled into `Contentful.xcworkspace`. Before
`7d2399e`, `Cartfile.private` read:

```
github "venmo/DVR" ~> 2.1.0
github "AliSoftware/OHHTTPStubs" ~> 8.0.0
```

## Decision

Point both test dependencies at Contentful-maintained forks, and stop carrying
them as workspace submodules.

Evidence:

- **`7d2399e` — "fix: tests (#410)", 2024-08-16.** Rewrites
  `Cartfile.private` / `Cartfile.resolved` to
  `mariuskatcontentful/DVR ~> 2.1.0` and
  `mariuskatcontentful/OHHTTPStubs ~> 9.0.0`. The same commit deletes the
  `Carthage/Checkouts/DVR` and `Carthage/Checkouts/OHHTTPStubs` submodules,
  empties `.gitmodules`, drops their `FileRef`s from
  `Contentful.xcworkspace/contents.xcworkspacedata`, reworks
  `Contentful.xcodeproj/project.pbxproj` (299 lines), replaces the Travis
  configuration with `.circleci/config.yml` plus fastlane lanes, and re-records
  the `EntryTests` and `QueryTests` cassettes.
- **`81cb107` — "feat: update Swift tools version and add dependencies (#418)",
  2024-11-19.** Raises `Package.swift` to swift-tools-version 5.3 and adds the
  same two forks as SwiftPM dependencies, plus a `ContentfulTests` test target,
  so the SwiftPM path gains the stubbing libraries the Xcode path already had.
- **Current state:** `Cartfile.resolved` pins
  `mariuskatcontentful/OHHTTPStubs "9.1.0"`; `Package.resolved` pins the forks by
  revision (`fb4f867…` for DVR, `1c5f7b4…` for OHHTTPStubs).

The commit messages in `#410` are a long chain of `chore: update` /
`chore: try new script` entries, and neither the commit body nor the manifests
state which upstream limitation forced the fork. What is verifiable is that the
fork switch, the submodule removal, the Xcode 15.4 CI migration, and the cassette
re-recording all landed in one commit — i.e. the forks were adopted as part of
getting the suite building and passing again on a newer toolchain, not as an
independent dependency-policy change.

## Consequences

- Contentful owns the maintenance of both forks. If a toolchain bump breaks
  stubbing again, the fix is made in the fork, not waited on upstream. This is
  the same posture the repo already took toward test tooling when Nimble was
  removed in favour of plain `XCTest`.
- **The dependency is declared twice and must be kept in sync.** A change to
  `Cartfile.private` / `Cartfile.resolved` has to be mirrored in `Package.swift`
  / `Package.resolved` or the Xcode and SwiftPM test paths diverge. CircleCI runs
  both (`test-*` lanes via Xcode, `build` via `swift build`), so a drift shows up
  as a job failure rather than silently.
- **The SwiftPM declarations track `.branch("master")`, not a version.** SwiftPM
  therefore has no semantic-version constraint on the test dependencies;
  `Package.resolved` is the only thing pinning a revision. Anyone re-resolving
  will pick up whatever is on the fork's default branch.
- Reverting to upstream is not a safe drive-by change: it would need the
  stubbing behaviour re-verified across the iOS, macOS, and tvOS test jobs.
  `AGENTS.md` and `CONTRIBUTING.md` flag this so the forks are not "corrected"
  back by mistake.
- Because the submodules are gone, a fresh clone no longer has the dependency
  sources on disk, and `Scripts/setup-env.sh` — which still runs
  `carthage bootstrap --use-submodules --no-build` — no longer matches what CI
  does (`carthage update --use-xcframeworks`). The script has not been updated to
  follow.
