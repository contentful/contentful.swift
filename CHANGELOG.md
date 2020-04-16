# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) starting from 1.x releases.

### Merged, but not yet released
> All recent changes are published
---

## Table of contents
#### 5.x Releases
- `5.0.0` Releases - [5.0.7](#507) | [5.0.8](#261)
#### 4.x Releases
- `4.2.0` Releases - [4.2.0](#420) | [4.2.1](#421) | [4.2.2](#422) | [4.2.3](#423) | [4.2.4](#424) | [4.2.5](#425)
- `4.1.0` Releases - [4.1.0](#410) | [4.1.3](#413)
- `4.0.0` Releases - [4.0.0](#400) | [4.0.1](#401)

#### 3.x Releases
- `3.1.0` Releases - [3.1.0](#310) | [3.1.1](#311) | [3.1.2](#312)
- `3.0.0` Releases - [3.0.0](#300)

#### 2.x Releases
- `2.2.0` Releases - [2.2.0](#220) | [2.2.1](#221)
- `2.1.0` Releases - [2.1.0](#210)
- `2.0.0` Releases - [2.0.0](#200)

#### 1.x Releases
- `1.0.0` Releases - [1.0.0](#100) | [1.0.1](#101)
- `1.0.0-betax` Releases - [1.0.0-beta1](#100-beta1) | [1.0.0-beta2](#100-beta2) | [1.0.0-beta3](#100-beta3) | [1.0.0-beta4](#100-beta4) | [1.0.0-beta5](#100-beta5)

#### 0.x Releases
- `0.10.x` Releases - [0.11.0](#0110)
- `0.10.x` Releases - [0.10.0](#0100) | [0.10.1](#0101) | [0.10.2](#0102)
- `0.9.x` Releases - [0.9.0](#090) | [0.9.1](#091) | [0.9.2](#092) | [0.9.3](#093)
- `0.8.x` Releases - [0.8.0](#080)
- `0.7.x` Releases - [0.7.0](#070) | [0.7.1](#071) | [0.7.2](#072) | [0.7.3](#073) | [0.7.4](#074) | [0.7.5](#075) | [0.7.6](#076) | [0.7.7](#077)
- `0.6.x` Releases - [0.6.0](#060) | [0.6.1](#061)
- `0.5.x` Releases - [0.5.0](#050)
- `0.4.x` Releases - [0.4.0](#040) | [0.4.1](#041)
- `0.3.x` Releases - [0.3.0](#030) | [0.3.1](#031)

---
## [`5.0.7`](https://github.com/contentful/contentful.swift/releases/tag/5.0.7)
Released on 2020-02-18

#### Fixes
 - Setting build for external distribution
---

## [`4.2.4`](https://github.com/contentful/contentful.swift/releases/tag/4.2.4)
Released on 2018-12-27

#### Fixed
- A bug in which one-to-many links could become out-of-order in [#253](https://github.com/contentful/contentful.swift/pull/253) by [@chrisozenne](https://github.com/chrisozenne).

---

## [`4.2.3`](https://github.com/contentful/contentful.swift/releases/tag/4.2.3)
Released on 2018-12-06

#### Fixes
- Check for protocol conformance when fetching an `EntryDecodable` by id that prevented links from being resolved.

---

## [`4.2.2`](https://github.com/contentful/contentful.swift/releases/tag/4.2.2)
Released on 2018-12-02

#### Improves
- Compiler handling of chainable query methods by adding `@discardableResult` to some methods it was missing from

---

## [`4.2.1`](https://github.com/contentful/contentful.swift/releases/tag/4.2.1)
Released on 2018-11-22

#### Improved
- All reference documentation has been improved.

---

## [`4.2.0`](https://github.com/contentful/contentful.swift/releases/tag/4.2.0)
Released on 2018-11-13

#### Added
- A `ContentfulLogger` singleton which will log messages to the console. `ContentfulLogger` can be configured with a `CustomLogger` in order to use any third-party logging frameworks of your choice.

---

## [`4.1.3`](https://github.com/contentful/contentful.swift/releases/tag/4.1.3)
Released on 2018-11-08

#### Changed
- `4.1.1`, `4.1.2`, and `4.1.3` are all hotfix releases that fixed small corruptions in the Xcode project configuration. `4.1.3` specifically sets the deployment version on the macOS target, even though the correct deployment version was set on the macOS framework target.

---

## [`4.1.0`](https://github.com/contentful/contentful.swift/releases/tag/4.1.0)
Released on 2018-11-06

#### Added
- The `RichTextDocument` type which can be used in `EntryDecodable` instances as a field type corresponding to rich text fields in Contentful.

#### Removed
- Support for iOS 8.

---

## [`4.0.1`](https://github.com/contentful/contentful.swift/releases/tag/4.0.1)
Released on 2018-10-25

#### Changed
- This release ensures that CI runs on Xcode 10 with Swift 4.2

---

## [`4.0.0`](https://github.com/contentful/contentful.swift/releases/tag/4.0.0)
Released on 2018-10-24

#### Changed
- *BREAKING:* `Interstellar` has been removed as a dependency of the SDK and the SDK now has its own `Result` type. If you were relying on fetch methods that returned an `Observable`, you will need to update your code.
- *BREAKING:* The syntax for many of the fetch methods on `Client` have changed. Refer to the [v4 migration guide](Migrations.md#migrating-from-version-3xx-to-4xx).
- *BREAKING:* `EntryQueryable` has been renamed `FieldKeysQueryable`, the required associated type `Fields` has been renamed `FieldKeys` to accurately reflect the type's real usage.
- *BREAKING:* `MixedMappedArrayResponse` has been renamed `MixedArrayResponse`. 

#### Added
- Base fetch methods for fetching data, or fetching data and deserializing any type conforming to `Swift.Decodable` have been exposed so that SDK usage is more flexible for various development strategies.
- `Endpoint` enum and `EndpointAccessible` protocol for clarity on endpoints available through the APIs and which resource types are returned from said endpoints.
- `ResourceQueryable` protocol, which `Asset`, `Entry`, `ContentType` conform to; it enables querying and filtering on the API for conforming types.
- `FlatResource` protocol which can be used if you prefer to have all `sys` properties on the top level of your `EntryDecodable`. All `Resource` types have a default implementation of `FlatResource` so refactoring is opt-in.

#### Removed
- The `DataDelegate` protocol has been removed in favor of directly fetching raw `Data` on your own. If you want to store JSON to disk, simply fetch it and do what you like.
- The `EntryModellable` protocol is now gone. Just use `EntryDecodable`.

---

## [`3.1.2`](https://github.com/contentful/contentful.swift/releases/tag/3.1.2)
Released on 2018-08-24

#### Fixed
A retain cycle due to the fact that the `URLSession` owned by `Client` was not invalidated on client deallocation. Thanks to [@edwardmp](https://github.com/edwardmp) for identifying the issue and submitting a fix in [#226](https://github.com/contentful/contentful.swift/pull/226).

---

## [`3.1.1`](https://github.com/contentful/contentful.swift/releases/tag/3.1.1)
Released on 2018-08-22

#### Fixed
- A critical bug that caused the `fetchLocales(then:)` method to not pass the correct error back to it's completion handler. This bug would, for example, incorrectly pass back an `SDKError` if internet connection dropped rather than passing back the proper `NSErrror` from Foundation.

---

## [`3.1.0`](https://github.com/contentful/contentful.swift/releases/tag/3.1.0)
Released on 2018-08-10

#### Added
- `Query` and `QueryOn` methods for finding entries which reference another entry (by `id`) with a specific linking field.
 
---

## [`3.0.0`](https://github.com/contentful/contentful.swift/releases/tag/3.0.0)
Released on 2018-07-30

#### Added
- **BREAKING:** PNGs can now be retrieved with `.standard` or `.eight` bits as an additional `ImageOption` to request PNGs from the Images API.

#### Fixed
- Now all error responses from the API will fallback to seraializing an `SDKError` if the SDK is unable to serialize an `APIError`

#### Changed
- **BREAKING:** Configuring a `Client` to interface with Content Preview API is no longer done through the `ClientConfiguration` type. Instead, pass `host: Host.preview` to the `Client` initializer. Also, you can now configure the client to use any arbitrary string host if you have whitelisted via your plan in Contentful.
 
---

## [`2.2.1`](https://github.com/contentful/contentful.swift/releases/tag/2.2.1)
Released on 2018-07-30

#### Fixed
- Accessing fields on assets was not respecting fallback chain logic when assets were requested with a multi-locale format. This is now fixed.

---

## [`2.2.0`](https://github.com/contentful/contentful.swift/releases/tag/2.2.0)
Released on 2018-06-13

#### Added
- An additional configuration option, `timeZone` on the `ClientConfiguration` to specify which `TimeZone` should be used when normalizing dates returned by the API. The default timezone is 0 seconds offset from GMT which enables serializing the exact representation the API returns rather than transforming to the current system time.

---

## [`2.1.0`](https://github.com/contentful/contentful.swift/releases/tag/2.1.0)
Released on 2018-04-27

#### Added
- Support for using the `/sync` endpoint on non-master environments.

---

## [`2.0.0`](https://github.com/contentful/contentful.swift/releases/tag/2.0.0)
Released on 2018-04-16

#### Fixed
- Typed queries prepending "fields" two times when using the select operator. Thanks to [@cysp](https://github.com/cysp) for submitting the fix in [#169](https://github.com/contentful/contentful.swift/pull/169).
- Assets that contained media files that were not images failed to deserialize the metadata about the file properly.
- `null` values that were present for fields were being stored in dictionaries as a Bool with a value of `true`. Now these values are omitted from the dictionary. The handling of `null` values in JSON arrays has also been improved.
- Date formats supported by the Contentful web app that were previously not being deserialized by the SDK's JSONDecoder

#### Added
- Support for the new Environments
- Locales are now a property of `Client` and can be fetched on their own with the `fetchLocales` methods.
- `AssetProtocol` to enable data fetches for other asset data types.

#### Changed
- **BREAKING:** Upgrades project to Swift 4.1 and Xcode 9.3
- **BREAKING:** The interface for synchronization has been simplified. `initialSync` and `nextSync` have been replaced with `sync` with a default argument of an empty sync space to start an initial sync operation.
- **BREAKING:** The SDK provided methods for creating a new `Swift.JSONDecoder` and updating it with locale information of your space or environment has changed.
- **BREAKING:** The `LocalizationContext` property of `Space` has been moved and is now a property of `Client`.
- **BREAKING:** `ResourceQueryable` has been renamed `EntryQueryable` for correctness and consistency.

---

## [`1.0.1`](https://github.com/contentful/contentful.swift/releases/tag/1.0.1)
Released on 2017-01-31

#### Fixed
- `String` extension to generate an image url that didn't always prepend the "https" scheme to the url.

---

## [`1.0.0`](https://github.com/contentful/contentful.swift/releases/tag/1.0.0)
Released on 2017-01-25

#### Added
- Support for the new query parameters to find incoming links [to a specific entry](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/links-to-entry) or [to a specific asset](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/links-to-asset) in a space.

#### Fixed
- Shared `static` localization context on the `Client` which caused issues if a new client connected to a different space was instantiated.
- HTTP status codes not being exposed.

---

## [`1.0.0-beta5`](https://github.com/contentful/contentful.swift/releases/tag/1.0.0-beta5)
Released on 2017-01-09

#### Added
- Instance method for mutating a query by appending a `LinkQuery`

#### Fixed
- When generating a url from the helper methods that append `ImageOptions`, the 'https' scheme will always be applied.
- The `Location` type is now an Objective-C that conforms to NSCoding class so that it may be stored in CoreData as an attribute on an `NSManagedObject`
  
---

## [`1.0.0-beta4`](https://github.com/contentful/contentful.swift/releases/tag/1.0.0-beta4)
Released on 2017-12-19

#### Fixed
- Accessibility identifiers for the `width` and `height` properties of the `ImageInfo` for an `Asset` are now public so they can be used. Thanks to [@ErikLuimes](https://github.com/ErikLuimes) for the pull request: [#157](https://github.com/contentful/contentful.swift/pull/157)

---

## [`1.0.0-beta3`](https://github.com/contentful/contentful.swift/releases/tag/1.0.0-beta3)
Released on 2017-11-27

#### Fixed
- Issue where `true` would be decoded to `Int` with value `1` when decoding JSON to `[String: Any]`. The SDK now attempts to decode `Bool` before `Int` to prevent this error.

---

## [`1.0.0-beta2`](https://github.com/contentful/contentful.swift/releases/tag/1.0.0-beta2)
Released on 2017-11-03

#### Fixed
- Deprecation warnings that appeared starting with Xcode9.1
- Incorrect assertion that asserted that all link were resolved since it is possible for unresolvable links to retured from CDA
- If an entry was of a content type not known to the `Client`, the SDK would enter an infinite loop.

---

## [`1.0.0-beta1`](https://github.com/contentful/contentful.swift/releases/tag/1.0.0-beta1)
Released on 2017-10-24

No more breaking changes will be made before 1.0.0 release. Following this point, the project will strictly adhere to [Semantic Versioning](http://semver.org/).

#### Added
- `ResourceQueryable` protocol to enable safer queries via the `QueryOn` query type.
- `SyncSpace.SyncableType` enum for specifying which Contentful types should be synced.
- A description property to `ContentType`
- A `ContentTypeQuery` for syncing content types.
- `ArrayResponseError` type as a member of all array responses to inform you when your links are not resolvable because the target resources are unpubished.

#### Improved
- All Error types now have better debug descriptions so that the most relevant info is given to you while debugging.

#### Fixed
- Multiple link resolution callbacks can now be stored for one link in case multiple entries are linking to the same resource.

#### Changed
- **BREAKING:** The helper methods for resolving links on the fields JSON container no longer requires passing in the current locale.
- **BREAKING:** The parameter names have been made consistent accross all fetch method names. The parameter signatures for all fetch methods are now: `(matching:then:)`.
- **BREAKING:** All query initializers have been changed to static methods so that the syntax exactly matches the syntax of the instance methods.
- **BREAKING:** Various methods for creating and mutating queries no longer `throw` errors and so the need to call them in a `do` `catch` block has been obviated.
- **BREAKING:** `QueryOperation` is now called `Query.Operation`.

#### Removed
- **BREAKING:** All fetch methods that previously took dictionary arguments have been removed. Use fetch methods that take query types instead.
- **BREAKING:** Now unnecessary `QueryError`s.

---

## [`0.11.0`](https://github.com/contentful/contentful.swift/releases/tag/0.11.0)
Released on 2017-10-10

#### Changed
- **BREAKING:** `EntryModellable` is now called `EntryDecodable` and extends `Decodable` from the Swift 4 Foundation standard library. There are convenience methods for deserializing fields in the "fields" container for an entry.
- **BREAKING:** The `MappedContent` type no longer exists. If requesting heterogeneous collections (by hitting "/entries" with no query paramters for intance), you will get a `Result<MixedMappedArrayResponse>` and it is up to you to filter the array by the contained types. 

#### Fixed
- [#132](https://github.com/contentful/contentful.swift/issues/132) `EntryDecodable` not synthesizing arrays of links
- [#133](https://github.com/contentful/contentful.swift/issues/133) `EntryDecodable` not allowing properties that are implicit optionals 

---

## [`0.10.2`](https://github.com/contentful/contentful.swift/releases/tag/0.10.2)
Released on 2017-10-06

#### Fixed
- Compile error due to incorrect protection level setting

---

## [`0.10.1`](https://github.com/contentful/contentful.swift/releases/tag/0.10.1)
Released on 2017-10-03

#### Added
- API for retreiving a JSONDecoder from the SDK and configuring it with localization information from your Contentful space.

#### Fixed
- Array's of links not being decoded.

---

## [`0.10.0`](https://github.com/contentful/contentful.swift/releases/tag/0.10.0)
Released on 2017-10-02

#### Changed
- **BREAKING:** The project is now compiled using Swift 4 and therefore must be developed against with Xcode 9. Backwards compatibility with Swift 3 is not possible as the SDK now uses Swift 4 features like JSON decoding via the `Decodable` protocol in Foundation.
- **BREAKING:** `CLLocationCoordinate2D` has been replaced with `Location` type native to the SDK so that linking with CoreLocation is no longer necessary. If you have location enabled queries, you'll need to migrate your code.
• `Resource` is now a protocol and is no longer the base class for `Asset` and `Entry`. `LocalizableResource` is the new base class.
- [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper) has been pruned and is no longer a dependency of the SDK. If managing your dependencies with Carthage, make sure to manually remove ObjectMapper if you aren't using it yourself.

---

## [`0.9.3`](https://github.com/contentful/contentful.swift/releases/tag/0.9.3)
Released on 2017-09-08

#### Fixed
- Ensured all functions and instance members had an explicit protection level set.
#### Added
- Xcode 8 and 9 are now tested on Travis CI for iOS, macOS, and tvOS in a matrix build. You can now rest easy knowing that if you are developing for one of these platforms, the SDK will work for you!
- The Swift playground has been migrated from it's former home to live here, with the main SDK. Instructions have been added to the README.
- `DataDelegate` protocol to receive callbacks from SDK which contain raw `Data` from fetches to the API.

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

