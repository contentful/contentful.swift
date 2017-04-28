# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) starting from 1.x releases.

## Unreleased

#### Planned
- Further iteration on `ContentModellable` protocol.

#### Added
- Swift'ier API for [Contentful Delivery API Search Parameters](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters)
- Mechanism for mapping responses to user-defined Swift types when using `QueryOn` queries.
- Improved link resolving via the new `Link` type
- Swift 3.1, Xcode 8.3 support.

#### Changed
- **BREAKING:** `Contentful.Array` is now called `ArrayResponse` to avoid clashing with native Swift arrays.

#### Planned
- Better support and Swift'ier API for [Images API](https://www.contentful.com/developers/docs/references/images-api/).

#### Changed
- `fetch` methods no longer return tuples of `(URLSessionTask?, Observable)` and now simply return the observable.

---

## Table of contents

#### 0.x Releases
- `0.3.x` Releases - [0.3.0](#030) | [0.3.1](#031)

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

