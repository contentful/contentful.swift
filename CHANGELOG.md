# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) starting from 1.x releases.

### Merged, but not yet released
> ~~All recent changes are published~~
> #### Changed
> - **BREAKING:** [Interstellar](https://github.com/JensRavens/Interstellar) has been pruned, and therefore all method that previously returned an `Observable` are no longer part of the SDK.
---

## Table of contents

#### 0.x Releases
- `0.9.x` Releases - [0.9.0](#090) | [0.9.1](#091) | [0.9.2](#092)
- `0.8.x` Releases - [0.8.0](#080)
- `0.7.x` Releases - [0.7.0](#070) | [0.7.1](#071) | [0.7.2](#072) | [0.7.3](#073) | [0.7.4](#074) | [0.7.5](#075) | [0.7.6](#076) | [0.7.7](#077)
- `0.6.x` Releases - [0.6.0](#060) | [0.6.1](#061)
- `0.5.x` Releases - [0.5.0](#050)
- `0.4.x` Releases - [0.4.0](#040) | [0.4.1](#041)
- `0.3.x` Releases - [0.3.0](#030) | [0.3.1](#031)

---

## [`0.9.2`](https://github.com/contentful/contentful.swift/releases/tag/0.9.2)
Released on 2017-08-16

#### Fixed
- Corrupt reference to AppKit extensions in xcodeproj which prevented compilation on macOS. In order to prevent future regressions, travis now runs unit tests for tvOS and macOS.
- Initializer for `ContentModel` which was implicitly `internal`. The initializer is now exposed as public.
#### Added
- Convenience methods for extracting typed values, including `Entry`s and `Asset`s, from `fields` dictionaries.
- Ability to make `Query`s on specific content types without conforming to `EntryModellable`.

---

## [`0.9.1`](https://github.com/contentful/contentful.swift/releases/tag/0.9.1)
Released on 2017-08-11

#### Added
- Support for installation via [Swift Package Manager](https://swift.org/package-manager)

---

## [`0.9.0`](https://github.com/contentful/contentful.swift/releases/tag/0.9.0)
Released on 2017-08-09

#### Changed
- **BREAKING:** `Modellable` protocol now splits mapping of regular (non-relationship) fields, and link fields into two separate methods.

#### Fixed
- [#108](https://github.com/contentful/contentful.swift/issues/108) circular link references causing recursive loops. Also, duplicate objects being mapped by the system is now fixed. Thanks to [@AntonTheDev](https://github.com/AntonTheDev) for help scoping the fix.

---

## [`0.8.0`](https://github.com/contentful/contentful.swift/releases/tag/0.8.0)
Released on 2017-07-26

#### Fixed
- Project configuration so that contentful.swift may be built from source without warnings. Thanks to [@brentleyjones](https://github.com/brentleyjones) for the help and guidance. Implications for this change are that:
  - Dependencies are still managed with carthage but with the `--use-submodules` flag and the source (i.e. Carthage/Checkouts) is now tracked in git
  - Now travis doesn't install carthage or use it at all to build the project and Contentful.xcodeproj framework search paths are cleared.
- [#100](https://github.com/contentful/contentful.swift/issues/100) enabling the usage of contentful.swift in app extensions.
  
#### Added
- The previously private `persistenceIntegration` instance variable is now a `public var` which means it can be set anytime after `Client` initialization.

---

## [`0.7.7`](https://github.com/contentful/contentful.swift/releases/tag/0.7.7)
Released on 2017-07-24

#### Added
- `String` extension methods to generate urls for the Contentful Images API.

---

## [`0.7.6`](https://github.com/contentful/contentful.swift/releases/tag/0.7.6)
Released on 2017-07-19

#### Fixed
- [#97](https://github.com/contentful/contentful.swift/issues/97)

---

## [`0.7.5`](https://github.com/contentful/contentful.swift/releases/tag/0.7.5)
Released on 2017-07-18

#### Changed
- Simplified and optimized sending messages to types conforming to  `PersistenceIntegration`.

---

## [`0.7.4`](https://github.com/contentful/contentful.swift/releases/tag/0.7.4)
Released on 2017-07-17

#### Fixed
- Deleted Links in Contentful that were not propagating to CoreData as nullfied managed relationships.

---

## [`0.7.3`](https://github.com/contentful/contentful.swift/releases/tag/0.7.3)
Released on 2017-07-17

#### Fixed
- Delta messages from `/sync` endpoint were only being sent for last page when a sync was returned on multiple pages.

---

## [`0.7.2`](https://github.com/contentful/contentful.swift/releases/tag/0.7.2)
Released on 2017-07-12

#### Added
- `LocalizationContext` is now a public variable on `Space` so that SDK consumers can direclty initialize `Entry` or `Asset` instances from bundled JSON.

---

## [`0.7.1`](https://github.com/contentful/contentful.swift/releases/tag/0.7.1)
Released on 2017-06-20

#### Fixed
- Delta messages were not always forwarded to `PersistenceIntegration` when calling `Client.nextSync()` and `Client.initialSync()` in [#71](https://github.com/contentful/contentful.swift/issues/71)

---

## [`0.7.0`](https://github.com/contentful/contentful.swift/releases/tag/0.7.0)
Released on 2017-06-19

#### Changed
- *BREAKING:* Subsequent sync is now a method on the `Client` called `nextSync` rather than being a method on `SyncSpace`.
#### Added
- `PersistenceIntegration` protocol. `Client` can now be initialized with a `persisistenceIntegration` which will receive messages when `Asset`s & `Entry`s are ready to be transformed to a persistable format and cached in persistent store such as CoreData. Note that this only works for the `initialSync` and `nextSync` operations.
- The `updatedAt` and `createdAt` properties of the `Sys` type are now stored as `Date` objects instead of as `String`s.
- `Integration` protocol to append information about external integrations to Contentul HTTP user-agent headers.
- A `ContentModel` type used to contain mapped `ContentModellable` (user-defined types) instances rather than `Entry` & `Asset`s.
- Support for `initialSync` when using the Content Preview API.

---

## [`0.6.1`](https://github.com/contentful/contentful.swift/releases/tag/0.6.1)
Released on 2017-06-12

#### Fixed
- `ImageOption` that changed background using `Fit.pad(with: Color) now generates the correct URL.
- Build error for watchOS caused by file from test target being added to watch target.

---

## [`0.6.0`](https://github.com/contentful/contentful.swift/releases/tag/0.6.0)
Released on 2017-06-12

#### Added
- Support for mirroring API fallback locale logic in the SDK for scenarios when all locales are returned (i.e. when using the `/sync` endpoint or specifing `locale=*`)
- Support for HTTP rate limit headers
#### Fixed
- Unintentionally triggered Swift errors that were thrown during JSON deserialization. 
	- Fixed by [@loudmouth](https://github.com/loudmouth) in [#71](https://github.com/contentful/contentful.swift/issues/71)
- Crash when using [contentful-persistence.swift](https://github.com/contentful/contentful-persistence.swift) caused by missing `defaultLocale` property: Issue [#68](https://github.com/contentful/contentful.swift/issues/68) and [#65](https://github.com/contentful/contentful.swift/issues/65)
	- Fixed by [@sebastianludwig](https://github.com/sebastianludwig) and [@tapwork](https://github.com/tapwork) in [#70](https://github.com/contentful/contentful.swift/pull/70).

---

## [`0.5.0`](https://github.com/contentful/contentful.swift/releases/tag/0.5.0)
Released on 2017-05-31

#### Added
- Better support and Swifty API for [Images API](https://www.contentful.com/developers/docs/references/images-api/).

---

## [`0.4.1`](https://github.com/contentful/contentful.swift/releases/tag/0.4.1)
Released on 2017-05-23.

#### Fixed
- Potential crash during sync callback due to unretained `SyncSpace` instance

---

## [`0.4.0`](https://github.com/contentful/contentful.swift/releases/tag/0.4.0)
Released on 2017-05-18.

#### Added
- Swift'ier API for [Contentful Delivery API Search Parameters](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters)
- Mechanism for mapping responses to user-defined Swift types when using `QueryOn` queries.
- Improved link resolving via the new `Link` type
- Swift 3.1, Xcode 8.3 support.

#### Changed
- **BREAKING:** `Contentful.Array` is now called `ArrayResponse` to avoid clashing with native Swift arrays.
- **BREAKING:** `fetch` methods no longer return tuples of `(URLSessionTask?, Observable)` and now simply return the observable.

---

## [`0.3.1`](https://github.com/contentful/contentful.swift/releases/tag/0.3.1)
Released on 2017-02-03.

#### Added
- Support for installation via Carthage on all of iOS, macOS, tvOS, & watchOS.

---

## [`0.3.0`](https://github.com/contentful/contentful.swift/releases/tag/0.3.0)
Released 2017-01-08.

#### Changed
- **BREAKING:** Upgrade to Swift 3 and Xcode 8. Versions of Swift < 3 and Xcode < 8 no longer supported. 

