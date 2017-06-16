# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) starting from 1.x releases.

### Merged, but not yet released
> #### Changed
> - *BREAKING:* Subsequent sync is now a method on the `Client` called `nextSync` rather than being a method on `SyncSpace`.
> #### Added
> - `PersistenceIntegration` protocol. `Client` can now be initialized with a `persisistenceIntegration` which will receive messages when `Asset`s & `Entry`s are ready to be transformed to a persistable format and cached in persistent store such as CoreData. Note that this only works for the `initialSync` and `nextSync` operations.
> - The `updatedAt` and `createdAt` properties of the `Sys` type are now stored as `Date` objects instead of as `String`s.
> - `Integration` protocol to append information about external integrations to Contentul HTTP user-agent headers.
> - A `ContentModel` type used to contain mapped `ContentModellable` (user-defined types) instances rather than `Entry` & `Asset`s.
> - Support for `initialSync` when using the Content Preview API.

---

## Table of contents

#### 0.x Releases
- `0.6.x` Releases - [0.6.0](#060) | [0.6.1](#061)
- `0.5.x` Releases - [0.5.0](#050)
- `0.4.x` Releases - [0.4.0](#040) | [0.4.1](#041)
- `0.3.x` Releases - [0.3.0](#030) | [0.3.1](#031)

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

