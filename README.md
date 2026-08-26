![header](./.github/header-swift.png)
<p align="center">
  <a href="https://www.contentful.com/slack/">
    <img src="https://img.shields.io/badge/-Join%20Community%20Slack-2AB27B.svg?logo=slack&maxAge=31557600" alt="Join Contentful Community Slack">
  </a>
  &nbsp;
  <a href="https://www.contentfulcommunity.com/">
    <img src="https://img.shields.io/badge/-Join%20Community%20Forum-3AB2E6.svg?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MiA1OSI+CiAgPHBhdGggZmlsbD0iI0Y4RTQxOCIgZD0iTTE4IDQxYTE2IDE2IDAgMCAxIDAtMjMgNiA2IDAgMCAwLTktOSAyOSAyOSAwIDAgMCAwIDQxIDYgNiAwIDEgMCA5LTkiIG1hc2s9InVybCgjYikiLz4KICA8cGF0aCBmaWxsPSIjNTZBRUQyIiBkPSJNMTggMThhMTYgMTYgMCAwIDEgMjMgMCA2IDYgMCAxIDAgOS05QTI5IDI5IDAgMCAwIDkgOWE2IDYgMCAwIDAgOSA5Ii8+CiAgPHBhdGggZmlsbD0iI0UwNTM0RSIgZD0iTTQxIDQxYTE2IDE2IDAgMCAxLTIzIDAgNiA2IDAgMSAwLTkgOSAyOSAyOSAwIDAgMCA0MSAwIDYgNiAwIDAgMC05LTkiLz4KICA8cGF0aCBmaWxsPSIjMUQ3OEE0IiBkPSJNMTggMThhNiA2IDAgMSAxLTktOSA2IDYgMCAwIDEgOSA5Ii8+CiAgPHBhdGggZmlsbD0iI0JFNDMzQiIgZD0iTTE4IDUwYTYgNiAwIDEgMS05LTkgNiA2IDAgMCAxIDkgOSIvPgo8L3N2Zz4K&maxAge=31557600"
      alt="Join Contentful Community Forum">
  </a>
</p>

# contentful.swift - Swift Content Delivery Library for Contentful

> Swift library for the Contentful [Content Delivery API](https://www.contentful.com/developers/docs/references/content-delivery-api/) and [Content Preview API](https://www.contentful.com/developers/docs/references/content-preview-api/). It helps you to easily access your Content stored in Contentful with your Swift applications.

<p align="center">
  <img src="https://img.shields.io/badge/Status-Maintained-green.svg" alt="This repository is actively maintained" />
  &nbsp;
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License" />
  </a>
  &nbsp;
  <a href="https://app.circleci.com/pipelines/github/contentful/contentful.swift">
    <img src="https://img.shields.io/circleci/build/github/contentful/contentful.swift/master?style=flat" alt="Build Status">
  </a>
  &nbsp;
  <a href="https://codebeat.co/projects/github-com-contentful-contentful-swift">
    <img src="https://codebeat.co/badges/6ebc67e8-29ca-459f-a4b7-b32a84fa9074" alt="Codebeat badge">
  </a>
</p>


<p align="center">
  <a href="https://cocoapods.org/pods/Contentful">
    <img src="https://img.shields.io/cocoapods/v/Contentful.svg?style=flat" alt="Version">
  </a>
  &nbsp;
  <a href="https://github.com/Carthage/Carthage">
    <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible">
  </a>
  &nbsp;
  <a href="https://swift.org/package-manager/">
    <img src="https://rawgit.com/jlyonsmith/artwork/master/SwiftPackageManager/swiftpackagemanager-compatible.svg" alt="Swift Package Manager compatible">
  </a>
  &nbsp;
  <a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/cocoapods/p/Contentful.svg?style=flat" alt="iOS | macOS | watchOS | tvOS">
  </a>
  &nbsp;
</p>

**What is Contentful?**

[Contentful](https://www.contentful.com/) provides content infrastructure for digital teams to power websites, apps, and devices. Unlike a CMS, Contentful was built to integrate with the modern software stack. It offers a central hub for structured content, powerful management and delivery APIs, and a customizable web app that enable developers and content creators to ship their products faster.

<details>
<summary>Table of contents</summary>
<!-- TOC -->

- [contentful.swift - Swift Content Delivery Library for Contentful](#contentfulswift---swift-content-delivery-library-for-contentful)
  - [Core Features](#core-features)
  - [Getting started](#getting-started)
    - [Requirements](#requirements)
    - [Installation](#installation)
      - [Swift Package Manager](#swift-package-manager)
      - [CocoaPods](#cocoapods)
      - [Carthage](#carthage)
    - [Your first request](#your-first-request)
    - [Authorization](#authorization)
    - [Accessing the Preview API](#accessing-the-preview-api)
  - [Using the SDK](#using-the-sdk)
    - [Fetching resources](#fetching-resources)
    - [Queries and search parameters](#queries-and-search-parameters)
    - [Map Contentful entries to Swift classes via `EntryDecodable`](#map-contentful-entries-to-swift-classes-via-entrydecodable)
    - [Links and includes](#links-and-includes)
    - [Localization](#localization)
    - [Assets and the Images API](#assets-and-the-images-api)
    - [Synchronization](#synchronization)
    - [Tags and metadata](#tags-and-metadata)
    - [Rich text](#rich-text)
  - [Advanced configuration](#advanced-configuration)
    - [Client configuration](#client-configuration)
    - [Error handling](#error-handling)
    - [Logging](#logging)
    - [Request cancellation and threading](#request-cancellation-and-threading)
    - [Offline persistence](#offline-persistence)
    - [Privacy manifest](#privacy-manifest)
  - [Documentation & References](#documentation--references)
    - [Reference documentation](#reference-documentation)
    - [Tutorials & other resources](#tutorials--other-resources)
      - [Swift playground](#swift-playground)
      - [Example application](#example-application)
    - [Migration](#migration)
  - [Swift versioning](#swift-versioning)
  - [Reach out to us](#reach-out-to-us)
    - [Have questions about how to use this library?](#have-questions-about-how-to-use-this-library)
    - [You found a bug or want to propose a feature?](#you-found-a-bug-or-want-to-propose-a-feature)
    - [You need to share confidential information or have other questions?](#you-need-to-share-confidential-information-or-have-other-questions)
  - [Get involved](#get-involved)
    - [Development setup](#development-setup)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

<!-- /TOC -->

</details>

## Core Features

- Content retrieval through the [Content Delivery API](https://www.contentful.com/developers/docs/references/content-delivery-api/) and [Content Preview API](https://www.contentful.com/developers/docs/references/content-preview-api/).
- Type-safe mapping of your content types to your own Swift classes via `EntryDecodable`, built on Swift's `Decodable`.
- Rich, chainable query syntax with compile-time checked field keys.
- Automatic [link resolution](https://www.contentful.com/developers/docs/concepts/links/), including circular references, with a guaranteed complete and duplicate-free object graph.
- [Synchronization](https://www.contentful.com/developers/docs/concepts/sync/) with delta updates and resumable sync tokens.
- [Localization support](https://www.contentful.com/developers/docs/concepts/locales/) with locale fallback chains.
- Support for [Environments](https://www.contentful.com/developers/docs/concepts/multiple-environments/).
- Server-side image transformations through the [Images API](https://www.contentful.com/developers/docs/references/images-api/), plus `UIImage`/`NSImage` convenience fetching.
- [Rich Text](https://www.contentful.com/developers/docs/concepts/rich-text/) field decoding into a strongly typed node tree.
- [Tags](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/tags) exposed through the `metadata` property on entries and assets.
- Zero third-party runtime dependencies — the SDK only relies on `Foundation`.
- Ships with a [privacy manifest](PrivacyInfo.xcprivacy) for App Store submissions.

## Getting started

In order to get started with the Contentful Swift library you'll need not only to install it, but also to get credentials which will allow you to have access to your content in Contentful.

- [Requirements](#requirements)
- [Installation](#installation)
- [Your first request](#your-first-request)
- [Authorization](#authorization)
- [Accessing the Preview API](#accessing-the-preview-api)

### Requirements

| Requirement | Version |
| --- | --- |
| Swift | 5.0 or later |
| Xcode | 15.x recommended (CI builds against Xcode 15.4) |
| iOS | 12.0+ |
| macOS | 10.13+ |
| tvOS | 12.0+ |
| watchOS | 4.0+ |

The SDK has no third-party runtime dependencies. The dependencies declared in [`Package.swift`](Package.swift) are used exclusively by the test target to stub network responses.

### Installation

#### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is the recommended way to integrate the SDK. In Xcode, choose **File > Add Package Dependencies…** and enter `https://github.com/contentful/contentful.swift`, or add the dependency to your `Package.swift` manifest:

```swift
.package(url: "https://github.com/contentful/contentful.swift", .upToNextMajor(from: "5.5.15"))
```

Then add the product to the targets that need it:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Contentful", package: "contentful.swift")
    ]
)
```

#### CocoaPods

```ruby
platform :ios, '12.0'
use_frameworks!
pod 'Contentful', '~> 5.5.15'
```

To learn more about operators for dependency versioning within a Podfile, see the [CocoaPods doc on the Podfile](https://guides.cocoapods.org/using/the-podfile.html).

#### Carthage

Add the following to your `Cartfile`:

```
github "contentful/contentful.swift" ~> 5.5.15
```

Then build the XCFrameworks:

```bash
carthage update --use-xcframeworks
```

### Your first request

The following code snippet is the most basic one you can use to fetch content from Contentful with this library:

```swift
import Contentful

let client = Client(spaceId: "cfexampleapi",
                    environmentId: "master", // Defaults to "master" if omitted.
                    accessToken: "b4c0n73n7fu1")

client.fetch(Entry.self, id: "nyancat") { (result: Result<Entry, Error>) in
    switch result {
    case .success(let entry):
        print(entry)
    case .failure(let error):
        print("Error \(error)!")
    }
}
```

### Authorization

Grab credentials for your Contentful space by [navigating to the "APIs" section of the Contentful Web App](https://app.contentful.com/deeplink?link=api).
If you don't have access tokens for your app, create a new set for the Delivery and Preview APIs.
Next, pass the id of your space and delivery access token into the initializer like so:

```swift
let client = Client(spaceId: "<YOUR_SPACE_ID>",
                    environmentId: "<YOUR_ENVIRONMENT_ID>", // Defaults to "master" if omitted.
                    accessToken: "<YOUR_DELIVERY_ACCESS_TOKEN>")
```

Delivery tokens only return published content, while preview tokens return the latest draft of your content. The two are not interchangeable: a delivery token used against the Preview API—or the other way around—will return a `401` `APIError`. Never hard-code tokens into a shipping app; inject them from your build configuration or a secure store instead.

### Accessing the Preview API

To access the Content Preview API, use your preview access token and set your client configuration to use preview as shown below.

```swift
let client = Client(spaceId: "cfexampleapi",
                    accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50",
                    host: Host.preview) // Defaults to Host.delivery if omitted.
```

Note that the Preview API only supports an initial synchronization. Attempting a subsequent sync with a stored sync token while pointed at `Host.preview` fails with `SDKError.previewAPIDoesNotSupportSync`.

## Using the SDK

### Fetching resources

Every request is asynchronous, returns a `Result<T, Error>` to its completion handler, and is executed against the space and environment the `Client` was configured with.

Fetch a single resource by id. `Space`, `Entry`, `Asset`, `ContentType`, and your own `EntryDecodable`/`AssetDecodable` types are all supported:

```swift
client.fetch(Asset.self, id: "nyancat") { (result: Result<Asset, Error>) in
    switch result {
    case .success(let asset):
        print(asset.url as Any)
    case .failure(let error):
        print(error)
    }
}
```

Fetch a collection, optionally filtered with a query. Collection responses are `HomogeneousArrayResponse<T>` values that expose `items`, `limit`, `skip`, `total`, `errors`, `includedEntries`, and `includedAssets`:

```swift
let query = Query.where(contentTypeId: "cat")
    .order(by: try Ordering(sys: .createdAt, inReverse: true))

client.fetchArray(of: Entry.self, matching: query) { (result: Result<HomogeneousArrayResponse<Entry>, Error>) in
    guard case .success(let response) = result else { return }
    print("Fetched \(response.items.count) of \(response.total) entries.")
}
```

Fetch the current space and its locales:

```swift
client.fetchSpace { (result: Result<Space, Error>) in
    // The space is cached after the first request.
}

client.fetchLocales { (result: Result<HomogeneousArrayResponse<Contentful.Locale>, Error>) in
    // ...
}
```

If you would rather handle deserialization yourself—for instance to cache the raw payload on disk—use the raw `Data` escape hatch together with `Client.url(endpoint:parameters:)`:

```swift
let url = client.url(endpoint: .entries, parameters: Query.where(contentTypeId: "cat").parameters)

client.fetch(url: url) { (result: Result<Data, Error>) in
    // Raw JSON data, exactly as returned by the API.
}
```

### Queries and search parameters

Queries are built from small, composable types that map directly onto the [search parameters](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters) of the REST API:

| Query type | Use it for |
| --- | --- |
| `Query` | Entries, when you are working with the untyped `Entry` class. |
| `QueryOn<EntryType>` | Entries, when you are working with your own `EntryDecodable` types. Sets `content_type` for you. |
| `AssetQuery` | Assets, including `mimetype_group` filtering. |
| `ContentTypeQuery` | Content types. |
| `LinkQuery<EntryType>` | Filtering on the fields of a linked entry. |

Every query supports the chainable operators `where`, `select`, `order`, `limit`, `skip`, `include`, and `localizeResults`. Each is available as both a static factory and an instance method, so queries read naturally in either direction:

```swift
let query = Query.where(contentTypeId: "cat")
    .where(field: "color", .equals("gray"))
    .where(sys: .updatedAt, .isAfter("2023-01-01T00:00:00Z"))
    .order(by: try Ordering(sys: .createdAt))
    .limit(to: 50)
    .skip(theFirst: 100)
```

`Ordering` validates that the key path starts with `sys.` or `fields.`, so its initializer is throwing; use `Ordered<EntryType>(field:)` for the type-safe equivalent when ordering a `QueryOn`.

The available operations are expressed by the `Query.Operation` enum: `.equals`, `.doesNotEqual`, `.hasAll`, `.includes`, `.excludes`, `.exists`, `.matches` (full-text search), the range operators `.isLessThan`, `.isLessThanOrEqualTo`, `.isGreaterThan`, `.isGreaterThanOrEqualTo`, `.isBefore`, `.isAfter`, and the location operators `.isNear` and `.isWithin`.

When your model type conforms to `FieldKeysQueryable`, use `QueryOn` to get compile-time checking of field names:

```swift
let query = QueryOn<Cat>.where(field: .color, .equals("gray"))
```

Search on references by combining a `LinkQuery` with the field that holds the link:

```swift
let linkQuery = LinkQuery<Cat>.where(field: .name, .matches("Happy Cat"))
let query = QueryOn<Cat>.where(linkAtField: .bestFriend, matches: linkQuery)
```

You can also search for incoming links with `Query.where(linksToEntryWithId:)` and `Query.where(linksToAssetWithId:)`, and narrow assets by media type with `AssetQuery.where(mimetypeGroup: .image)`.

A few limits are enforced by the SDK so that invalid requests never reach the API: `limit(to:)` is capped at 1000, `include(_:)` at 10, and `select(fieldsNamed:)` at 99 key paths (`sys` is always requested). Invalid selections throw a `QueryError`—see [Error handling](#error-handling).

### Map Contentful entries to Swift classes via `EntryDecodable`

The `EntryDecodable` protocol allows you to define a mapping between your content types and your Swift classes that entries will be serialized to. When using methods such as:

```swift
let query = QueryOn<Cat>.where(field: .color, .equals("gray"))

client.fetchArray(of: Cat.self, matching: query) { (result: Result<HomogeneousArrayResponse<Cat>, Error>) in
    guard let cats = try? result.get().items else { return }
    print(cats)
}
```

The asynchronously returned result will be an instance of `HomogeneousArrayResponse` in which the generic type parameter is the same type you've passed into the `fetchArray` method. If you are using a `Query` that does not restrict the response to contain entries of one content type, you will use methods that return `HeterogeneousArrayResponse` instead, whose `items` are typed as `[EntryDecodable]`:

```swift
client.fetchArray(matching: Query.where(valueAtKeyPath: "sys.id", .exists(true))) { (result: Result<HeterogeneousArrayResponse, Error>) in
    guard case .success(let response) = result else { return }
    for item in response.items {
        switch item {
        case let cat as Cat: print(cat)
        case let dog as Dog: print(dog)
        default: break
        }
    }
}
```

> The older names `ArrayResponse` and `MixedArrayResponse` still exist as deprecated typealiases for `HomogeneousArrayResponse` and `HeterogeneousArrayResponse`. Prefer the new names in new code.

The `EntryDecodable` protocol extends the `Decodable` protocol in Swift's Foundation standard library. The library provides helper methods for resolving relationships between `EntryDecodable`s and also for grabbing values from the fields container in the JSON for each resource.

In the example above, `Cat` is a type of our own definition conforming to `EntryDecodable` and `FieldKeysQueryable`. In order for the library to properly create your model types when receiving JSON, you must pass in these types to your `Client` instance:

```swift
let contentTypeClasses: [EntryDecodable.Type] = [
    Cat.self,
    Dog.self,
    Human.self
]

let client = Client(spaceId: spaceId,
                    accessToken: deliveryAPIAccessToken,
                    contentTypeClasses: contentTypeClasses)
```

The source for the `Cat` model class is below; note the helper methods the library adds to Swift's `Decoder` type to simplify parsing JSON returned by Contentful. You also need to pass in these types to your `Client` instance in order to use the fetch methods which take `EntryDecodable` type references:

```swift
final class Cat: EntryDecodable, FieldKeysQueryable {

    static let contentTypeId: String = "cat"

    // FlatResource members.
    let id: String
    let localeCode: String?
    let updatedAt: Date?
    let createdAt: Date?

    let color: String?
    let name: String?
    let lives: Int?
    let likes: [String]?

    // Metadata object if available
    let metadata: Metadata?

    // Relationship fields.
    var bestFriend: Cat?

    public required init(from decoder: Decoder) throws {
        let sys         = try decoder.sys()
        id              = sys.id
        localeCode      = sys.locale
        updatedAt       = sys.updatedAt
        createdAt       = sys.createdAt

        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Cat.FieldKeys.self)
        self.metadata   = try decoder.metadata()
        self.name       = try fields.decodeIfPresent(String.self, forKey: .name)
        self.color      = try fields.decodeIfPresent(String.self, forKey: .color)
        self.likes      = try fields.decodeIfPresent(Array<String>.self, forKey: .likes)
        self.lives      = try fields.decodeIfPresent(Int.self, forKey: .lives)

        try fields.resolveLink(forKey: .bestFriend, decoder: decoder) { [weak self] linkedCat in
            self?.bestFriend = linkedCat as? Cat
        }
    }

    enum FieldKeys: String, CodingKey {
        case bestFriend
        case name, color, likes, lives
    }
}
```

If you want to simplify the implementation of an `EntryDecodable`, declare conformance to `Resource` and add a `let sys: Sys` property to the class and assign via `sys = try decoder.sys()` during initialization. Then, `id`, `localeCode`, `updatedAt`, and `createdAt` are all provided via the `sys` property and don't need to be declared as class members. However, note that this style of implementation may make integration with local database frameworks like Realm and CoreData more cumbersome.

Optionally, the decoder has a helper function to decode metadata.

Additionally, the library requires that instances of a type representing an entry or asset must be a `class` instance, not a `struct`—this is because the library ensures that the in-memory object graph is complete, but also that it has no duplicates.

### Links and includes

Contentful returns linked entries and assets in an `includes` section of the response rather than nesting them. The SDK resolves those links for you after decoding, so by the time your completion handler runs, `bestFriend` above already points at a fully realized `Cat` instance—even when two entries link to each other.

Use `resolveLink(forKey:decoder:callback:)` for a to-one relationship and `resolveLinksArray(forKey:decoder:callback:)` for a to-many relationship. Always capture `self` weakly in the callback, as the SDK holds the closure until the whole response has been deserialized.

Control how deep the API resolves links with the `include` parameter, which accepts values from 0 to 10 and defaults to 1:

```swift
client.fetch(Cat.self, id: "nyancat", include: 3) { (result: Result<Cat, Error>) in
    // Links up to three levels deep are resolved.
}

let query = QueryOn<Cat>().include(2)
```

Links that cannot be resolved—because the target is unpublished or the include depth was too shallow—are reported in the `errors` property of the array response rather than failing the whole request.

### Localization

By default, resources are returned in the space's default locale. Request a specific locale with `localizeResults(withLocaleCode:)`:

```swift
let query = QueryOn<Cat>().localizeResults(withLocaleCode: "de-DE")
```

Passing the wildcard `"*"` returns every locale in a single response. When you do, `Entry` and `Asset` instances hold all translations at once and you can switch between them in memory without another network request:

```swift
let query = Query.where(contentTypeId: "cat").localizeResults(withLocaleCode: "*")

client.fetchArray(of: Entry.self, matching: query) { (result: Result<HomogeneousArrayResponse<Entry>, Error>) in
    guard case .success(let response) = result, let entry = response.items.first else { return }

    entry.setLocale(withCode: "de-DE") // Returns false if the locale is unknown to the environment.
    print(entry.fields["name"] as Any)
}
```

Fields with no value for the selected locale fall back through the locale fallback chain configured in your space. If no value is found anywhere in the chain, the field is omitted from the `fields` dictionary entirely. The client fetches the locale information for the environment before the first content request and exposes it via `client.locales`.

### Assets and the Images API

`Asset` exposes `url`, `urlString`, `title`, `description`, and a `file` property carrying the MIME type, file size, and image dimensions.

Build a transformed image URL without performing a request:

```swift
let url = try asset.url(with: [
    .width(300),
    .height(200),
    .fit(for: .fill(focusingOn: .faces)),
    .formatAs(.jpg(withQuality: .asPercent(80))),
    .withCornerRadius(12)
])
```

The available options are `.width`, `.height`, `.formatAs`, `.fit(for:)`, and `.withCornerRadius`. Formats are `.jpg(withQuality:)` (`.unspecified`, `.asPercent`, or `.progressive`), `.png(bits:)` (`.standard` or `.eight`), and `.webp`. Fit modes are `.pad(withBackgroundColor:)`, `.crop(focusingOn:)`, `.fill(focusingOn:)`, `.thumb(focusingOn:)`, and `.scale`, where the focus area can be an edge, a corner, `.face`, or `.faces`. Specifying two options of the same case, or a width or height outside the range 1–4000, throws an `ImageOptionError`.

Fetch the bytes directly:

```swift
client.fetchData(for: asset, with: [.width(600)]) { (result: Result<Data, Error>) in
    // ...
}
```

On iOS, tvOS, and watchOS the SDK adds `fetchImage(for:with:then:)` returning a `UIImage`; on macOS the same method returns an `NSImage`:

```swift
client.fetchImage(for: asset, with: [.formatAs(.png(bits: .eight))]) { (result: Result<UIImage, Error>) in
    switch result {
    case .success(let image):
        imageView.image = image
    case .failure(let error):
        print(error)
    }
}
```

The SDK does not cache image data. Pair it with `URLCache` or an image-caching library of your choice.

### Synchronization

The [Sync API](https://www.contentful.com/developers/docs/concepts/sync/) lets you keep a local copy of a space up to date by fetching only what changed since your last call. An initial sync is performed by calling `sync` with no arguments; the SDK follows pagination for you and only calls your completion handler once every page has been consumed.

```swift
client.sync { (result: Result<SyncSpace, Error>) in
    switch result {
    case .success(let syncSpace):
        print(syncSpace.entries.count, syncSpace.assets.count)
        UserDefaults.standard.set(syncSpace.syncToken, forKey: "syncToken")
    case .failure(let error):
        print(error)
    }
}
```

To continue from where you left off, construct a `SyncSpace` with the persisted token and pass it back in. The returned `SyncSpace` is the same instance you passed in, mutated with the latest deltas, so operations can be chained:

```swift
let syncSpace = SyncSpace(syncToken: UserDefaults.standard.string(forKey: "syncToken") ?? "")

client.sync(for: syncSpace) { (result: Result<SyncSpace, Error>) in
    guard case .success(let syncSpace) = result else { return }

    // Resources removed since the previous sync.
    print(syncSpace.deletedEntryIds, syncSpace.deletedAssetIds)
    UserDefaults.standard.set(syncSpace.syncToken, forKey: "syncToken")
}
```

Restrict what is synchronized with `SyncSpace.SyncableTypes`, which offers `.all`, `.entries`, `.assets`, `.entriesOfContentType(withId:)`, `.allDeletions`, `.deletedEntries`, and `.deletedAssets`:

```swift
client.sync(syncableTypes: .entriesOfContentType(withId: "cat")) { result in
    // ...
}
```

Two constraints are worth remembering: sync always returns content in every locale, and the Preview API supports only the initial sync.

### Tags and metadata

Entries and assets carry an optional `metadata` property containing links to the [tags](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/tags) applied to them. Decode it in your own types with `try decoder.metadata()`, as shown in the `Cat` example above, then filter on it from a query:

```swift
let taggedQuery = Query.where(metadataTagsIds: .includes(["black", "white"]))
```

### Rich text

Rich text fields decode into a `RichTextDocument`—a tree of `Node` values such as `Paragraph`, `Heading`, `Text` with `Mark`s, `Hyperlink`, `ResourceLinkBlock`, and `ResourceLinkInline`. Entries and assets embedded in the document are resolved along with all other links.

```swift
final class Article: EntryDecodable, FieldKeysQueryable {
    static let contentTypeId: String = "article"

    let sys: Sys
    let body: RichTextDocument

    public required init(from decoder: Decoder) throws {
        sys        = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: Article.FieldKeys.self)
        body       = try fields.decode(RichTextDocument.self, forKey: .body)
    }

    enum FieldKeys: String, CodingKey {
        case body
    }
}
```

`RichTextDocument` is an `NSObject` conforming to `NSCoding`, so it can be stored in a transformable Core Data attribute. To render a document into native views on iOS, use [rich-text-renderer.swift](https://github.com/contentful/rich-text-renderer.swift).

## Advanced configuration

### Client configuration

`ClientConfiguration` controls how the SDK talks to the API and how it decodes dates:

```swift
var configuration = ClientConfiguration.default
configuration.timeZone = TimeZone(secondsFromGMT: 3600)
configuration.dateDecodingStrategy = .iso8601

let client = Client(spaceId: "<YOUR_SPACE_ID>",
                    accessToken: "<YOUR_DELIVERY_ACCESS_TOKEN>",
                    clientConfiguration: configuration)
```

- `secure` toggles HTTPS and defaults to `true`. Leave it enabled outside of local testing.
- `dateDecodingStrategy` overrides the SDK's default, which handles the variable-precision ISO 8601 timestamps that Contentful returns.
- `timeZone` sets the time zone dates are offset by; the SDK uses GMT when it is omitted.

The `host` parameter accepts `Host.delivery`, `Host.preview`, or any custom domain string if your organization has a white-labeled API domain.

Networking behavior such as timeouts, caching policy, and additional headers is configured by passing your own `URLSessionConfiguration`. The SDK merges its `Authorization` and `X-Contentful-User-Agent` headers into whatever you provide, and its own values win on conflict:

```swift
let sessionConfiguration = URLSessionConfiguration.default
sessionConfiguration.timeoutIntervalForRequest = 30
sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad

let client = Client(spaceId: "<YOUR_SPACE_ID>",
                    accessToken: "<YOUR_DELIVERY_ACCESS_TOKEN>",
                    sessionConfiguration: sessionConfiguration)
```

### Error handling

Failures arrive as the `.failure` case of the `Result` passed to your completion handler. Three families of error are relevant:

- **`SDKError`** — problems the SDK detects locally: `.invalidHTTPResponse`, `.invalidURL`, `.previewAPIDoesNotSupportSync`, `.unparseableJSON`, `.noResourceFoundFor(id:)`, `.unableToDecodeImageData`, and `.localeHandlingError`.
- **`QueryError`** — invalid query construction: `.textSearchTooShort`, `.invalidOrderProperty`, `.invalidSelection(fieldKeyPath:)`, and `.maxSelectionLimitExceeded`. These are thrown synchronously while building a query.
- **`APIError`** — an error payload returned by Contentful, carrying `statusCode`, `message`, `details`, and `requestId`. Include the `requestId` when contacting support. Its subclass `RateLimitError` is returned for HTTP 429 responses and exposes `timeBeforeLimitReset`, the number of seconds to wait before retrying.

```swift
client.fetch(Entry.self, id: "nyancat") { result in
    if case .failure(let error) = result {
        switch error {
        case let rateLimitError as RateLimitError:
            print("Retry in \(rateLimitError.timeBeforeLimitReset ?? 0)s")
        case let apiError as APIError:
            print("\(apiError.statusCode!): \(apiError.message!) (request \(apiError.requestId!))")
        case let sdkError as SDKError:
            print(sdkError.debugDescription)
        default:
            print(error)
        }
    }
}
```

The SDK does not retry automatically. Implement backoff in your own code, using `timeBeforeLimitReset` as the minimum delay.

### Logging

`ContentfulLogger` prints request, response, and error information. It logs errors only by default:

```swift
ContentfulLogger.logLevel = .info   // .none, .error, or .info
ContentfulLogger.logType = .print   // .print, .nsLog, or .custom(_:)
```

To route messages into your own logging stack, conform to `CustomLogger`:

```swift
struct MyLogger: CustomLogger {
    func log(message: String) {
        // Forward to your logging framework.
    }
}

ContentfulLogger.logType = .custom(MyLogger())
```

### Request cancellation and threading

Fetch methods return the underlying `URLSessionDataTask`, which you can retain and cancel—useful when a view controller is dismissed or a search field's text changes:

```swift
let task = client.fetchArray(of: Cat.self, matching: QueryOn<Cat>()) { _ in }
task.cancel()
```

The methods are marked `@discardableResult`, so you can ignore the return value when you don't need cancellation.

Completion handlers are invoked on a background queue owned by `URLSession`, not on the main queue. Dispatch back to the main queue before touching UI:

```swift
client.fetch(Entry.self, id: "nyancat") { result in
    DispatchQueue.main.async {
        // Safe to update UI here.
    }
}
```

A `Client` owns its `URLSession` and invalidates it on deinitialization, so keep a strong reference to the client for as long as requests are in flight.

### Offline persistence

For a ready-made Core Data integration, use [contentful-persistence.swift](https://github.com/contentful/contentful-persistence.swift), which plugs into the client via the `persistenceIntegration` parameter.

To build your own store, conform to `PersistenceIntegration` and pass it to the initializer. The client then reports created and deleted entries and assets, locale codes, and the updated sync token as `sync` responses are processed. Callbacks may arrive on any thread, so your implementation is responsible for hopping onto whichever queue your database requires.

### Privacy manifest

The SDK ships [`PrivacyInfo.xcprivacy`](PrivacyInfo.xcprivacy), declaring that it collects no data, performs no tracking, and uses file timestamp, user defaults, and system boot time APIs only for the reasons Apple permits. When installed via Swift Package Manager or CocoaPods the manifest is bundled automatically and folds into your app's privacy report.

## Documentation & References

### Reference documentation

The library has 100% documentation coverage of all public variables, types, and functions. You can view the docs on the [web](https://contentful.github.io/contentful.swift/docs/index.html) or browse them in Xcode. For further information about the Content Delivery API, check out the [Content Delivery API Reference Documentation](https://www.contentful.com/developers/documentation/content-delivery-api/).

For a tour of the SDK's internal design, protocols, build system, and release process, see [ARCHITECTURE-BUILD-CONFIG.md](ARCHITECTURE-BUILD-CONFIG.md).

### Tutorials & other resources

* This library is a wrapper around our Contentful Delivery REST API. Some more specific details such as search parameters and pagination are better explained on the [REST API reference](https://www.contentful.com/developers/docs/references/content-delivery-api/), and you can also get a better understanding of how the requests look under the hood.
* Check the [Contentful for Swift](https://www.contentful.com/developers/docs/ios/tutorials/) page for Tutorials, Demo Apps, and more information on other ways of using Swift with Contentful.
* Every released change is recorded in the [CHANGELOG.md](CHANGELOG.md).

#### Swift playground

If you'd like to try an interactive demo of the API via a Swift Playground, do the following:

```bash
git clone --recursive https://github.com/contentful/contentful.swift.git
cd contentful.swift
make open
```

Then build the "Contentful_macOS" scheme, open the playground file and go! Note: make sure the "Render Documentation" button is switched on in the Utilities menu on the right of Xcode, and also open up the console to see the outputs of the calls to `print`.

#### Example application

See the [Swift iOS app on Github](https://github.com/contentful/the-example-app.swift) and follow the instructions on the README to get a copy of the space so you can see how changing content in Contentful affects the presentation of the app.

### Migration

We gathered all information related to migrating from older versions of the library in our [Migrations.md](Migrations.md) document.

## Swift versioning

It is recommended to use Swift 5.0, as older versions of the library will not have fixes backported. If you must use older Swift versions, see the compatible tags below.

| Swift version | Compatible Contentful tag |
| --- | --- |
| Swift 5.x | [ ≥ `5.0.0` ] |
| Swift 4.2 | [`4.0.0` - `4.2.5`] |
| Swift 4.1 | [`2.0.0` - `3.1.2`] |
| Swift 4.0 | [`0.10.0` - `1.0.1`] |
| Swift 3.x | [`0.3.0` - `0.9.3`] |
| Swift 2.3 | `0.2.3` |
| Swift 2.2 | `0.2.1` |

The SDK follows [Semantic Versioning](https://semver.org/). Breaking API changes and increases to the minimum deployment targets only happen in major releases.

## Reach out to us

### Have questions about how to use this library?

* Reach out to our community forum: [![Contentful Community Forum](https://img.shields.io/badge/-Join%20Community%20Forum-3AB2E6.svg?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MiA1OSI+CiAgPHBhdGggZmlsbD0iI0Y4RTQxOCIgZD0iTTE4IDQxYTE2IDE2IDAgMCAxIDAtMjMgNiA2IDAgMCAwLTktOSAyOSAyOSAwIDAgMCAwIDQxIDYgNiAwIDEgMCA5LTkiIG1hc2s9InVybCgjYikiLz4KICA8cGF0aCBmaWxsPSIjNTZBRUQyIiBkPSJNMTggMThhMTYgMTYgMCAwIDEgMjMgMCA2IDYgMCAxIDAgOS05QTI5IDI5IDAgMCAwIDkgOWE2IDYgMCAwIDAgOSA5Ii8+CiAgPHBhdGggZmlsbD0iI0UwNTM0RSIgZD0iTTQxIDQxYTE2IDE2IDAgMCAxLTIzIDAgNiA2IDAgMSAwLTkgOSAyOSAyOSAwIDAgMCA0MSAwIDYgNiAwIDAgMC05LTkiLz4KICA8cGF0aCBmaWxsPSIjMUQ3OEE0IiBkPSJNMTggMThhNiA2IDAgMSAxLTktOSA2IDYgMCAwIDEgOSA5Ii8+CiAgPHBhdGggZmlsbD0iI0JFNDMzQiIgZD0iTTE4IDUwYTYgNiAwIDEgMS05LTkgNiA2IDAgMCAxIDkgOSIvPgo8L3N2Zz4K&maxAge=31557600)](https://support.contentful.com/)
* Jump into our community slack channel: [![Contentful Community Slack](https://img.shields.io/badge/-Join%20Community%20Slack-2AB27B.svg?logo=slack&maxAge=31557600)](https://www.contentful.com/slack/)

### You found a bug or want to propose a feature?

* File an issue here on GitHub: [![File an issue](https://img.shields.io/badge/-Create%20Issue-6cc644.svg?logo=github&maxAge=31557600)](https://github.com/contentful/contentful.swift/issues/new). Make sure to remove any credential from your code before sharing it.

### You need to share confidential information or have other questions?

* File a support ticket at our Contentful Customer Support: [![File support ticket](https://img.shields.io/badge/-Submit%20Support%20Ticket-3AB2E6.svg?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MiA1OSI+CiAgPHBhdGggZmlsbD0iI0Y4RTQxOCIgZD0iTTE4IDQxYTE2IDE2IDAgMCAxIDAtMjMgNiA2IDAgMCAwLTktOSAyOSAyOSAwIDAgMCAwIDQxIDYgNiAwIDEgMCA5LTkiIG1hc2s9InVybCgjYikiLz4KICA8cGF0aCBmaWxsPSIjNTZBRUQyIiBkPSJNMTggMThhMTYgMTYgMCAwIDEgMjMgMCA2IDYgMCAxIDAgOS05QTI5IDI5IDAgMCAwIDkgOWE2IDYgMCAwIDAgOSA5Ii8+CiAgPHBhdGggZmlsbD0iI0UwNTM0RSIgZD0iTTQxIDQxYTE2IDE2IDAgMCAxLTIzIDAgNiA2IDAgMSAwLTkgOSAyOSAyOSAwIDAgMCA0MSAwIDYgNiAwIDAgMC05LTkiLz4KICA8cGF0aCBmaWxsPSIjMUQ3OEE0IiBkPSJNMTggMThhNiA2IDAgMSAxLTktOSA2IDYgMCAwIDEgOSA5Ii8+CiAgPHBhdGggZmlsbD0iI0JFNDMzQiIgZD0iTTE4IDUwYTYgNiAwIDEgMS05LTkgNiA2IDAgMCAxIDkgOSIvPgo8L3N2Zz4K&maxAge=31557600)](https://www.contentful.com/support/)


## Get involved

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?maxAge=31557600)](http://makeapullrequest.com)

We appreciate any help on our repositories. For more details about how to contribute see our [CONTRIBUTING.md](CONTRIBUTING.md) document.

### Development setup

Development happens in Xcode on macOS, since iOS, macOS, tvOS, and watchOS all have to stay supported. [Homebrew](https://brew.sh/) is a prerequisite.

```bash
make setup_env                      # Install or update the required brew packages.
bundle install                      # Install the Ruby gems used for linting, docs, and coverage.
carthage update --use-xcframeworks  # Resolve the test-only dependencies.
make open                           # Open Contentful.xcworkspace.
```

Common tasks:

| Command | Purpose |
| --- | --- |
| `bundle exec fastlane test_ios` | Run the test suite on iOS (also `test_macos`, `test_tvos`). |
| `bundle exec fastlane build` | Verify the package builds with `swift build`. |
| `make lint` | Run SwiftLint and the CocoaPods podspec linter. |
| `make coverage` | Generate a code-coverage report with Slather. |
| `make docs` | Build the reference documentation with Jazzy. |
| `./Scripts/set-version.sh 5.5.15` | Update the version in `Config.xcconfig` and `.env` together. |

Tests stub their network traffic, so they neither depend on live content nor consume your API quota. Pull requests are validated on CircleCI against Xcode 15.4.

## License

This repository is published under the [MIT](LICENSE) license.

## Code of Conduct

We want to provide a safe, inclusive, welcoming, and harassment-free space and experience for all participants, regardless of gender identity and expression, sexual orientation, disability, physical appearance, socioeconomic status, body size, ethnicity, nationality, level of experience, age, religion (or lack thereof), or other identity markers.

[Read our full Code of Conduct](https://github.com/contentful-developer-relations/community-code-of-conduct).
