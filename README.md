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

# contentful.swift - Swift Delivery SDK for Contentful

> Swift SDK for the Contentful [Content Delivery API](https://www.contentful.com/developers/docs/references/content-delivery-api/) and [Content Preview API](https://www.contentful.com/developers/docs/references/content-preview-api/). It helps you to easily access your Content stored in Contentful with your Swift applications.

<p align="center">
  <img src="https://img.shields.io/badge/Status-Maintained-green.svg" alt="This repository is actively maintained" />
  &nbsp;
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License" />
  </a>
  &nbsp;
  <a href="https://travis-ci.org/contentful/contentful.swift">
    <img src="https://img.shields.io/travis/contentful/contentful.swift/master.svg?style=flat" alt="Build Status">
  </a>
  &nbsp;
  <a href="https://coveralls.io/github/contentful/contentful.swift">
    <img src="https://img.shields.io/coveralls/contentful/contentful.swift.svg" alt="Coverage Status">
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

- [contentful.swift - Swift Delivery SDK for Contentful](#contentfulswift---swift-delivery-sdk-for-contentful)
  - [Core Features](#core-features)
  - [Getting started](#getting-started)
    - [Installation](#installation)
        - [CocoaPods installation](#cocoapods-installation)
      - [Carthage installation](#carthage-installation)
      - [Swift Package Manager [swift-tools-version 5.0]](#swift-package-manager-swift-tools-version-5.0)
    - [Your first request](#your-first-request)
    - [Accessing the Preview API](#accessing-the-preview-api)
    - [Authorization](#authorization)
    - [Map Contentful entries to Swift classes via `EntryDecodable`](#map-contentful-entries-to-swift-classes-via-entrydecodable)
  - [Documentation & References](#documentation--references)
    - [Reference Documentation](#reference-documentation)
    - [Tutorials & other resources](#tutorials--other-resources)
      - [Swift playground](#swift-playground)
      - [Example application](#example-application)
    - [Migration](#migration)
  - [Swift Versioning](#swift-versioning)
  - [Reach out to us](#reach-out-to-us)
    - [You have questions about how to use this library?](#you-have-questions-about-how-to-use-this-library)
    - [You found a bug or want to propose a feature?](#you-found-a-bug-or-want-to-propose-a-feature)
    - [You need to share confidential information or have other questions?](#you-need-to-share-confidential-information-or-have-other-questions)
  - [Get involved](#get-involved)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

<!-- /TOC -->

</details>

## Core Features

- Content retrieval through [Content Delivery API](https://www.contentful.com/developers/docs/references/content-delivery-api/) and [Content Preview API](https://www.contentful.com/developers/docs/references/content-preview-api/).
- [Link resolution](https://www.contentful.com/developers/docs/concepts/links/)
- Rich query syntax for type-safe queries
- [Synchronization](https://www.contentful.com/developers/docs/concepts/sync/)
- [Localization support](https://www.contentful.com/developers/docs/concepts/locales/)
- Up-to-date with the latest Swift development stack: Swift 4.x | Xcode 10.x
- Supports [Environments](https://www.contentful.com/developers/docs/concepts/multiple-environments/) (**v2.0.0+**)
- Experimental: to render [Rich Text](https://www.contentful.com/developers/docs/concepts/rich-text/) on iOS apps, check out [rich-text-renderer.swift](https://github.com/contentful-labs/rich-text-renderer.swift) on Github.
## Getting started

In order to get started with the Contentful Swift SDK you'll need not only to install it, but also to get credentials which will allow you to have access to your content in Contentful.

- [Installation](#installation)
- [Your first request](#your-first-request)
- [Accessing Preview API](#accessing-the-preview-api)
- [Authorization](#authorization)

### Installation

##### CocoaPods installation

```ruby
platform :ios, '9.0'
use_frameworks!
pod 'Contentful'
```

You can specify a specific version of Contentful depending on your needs. To learn more about operators for dependency versioning within a Podfile, see the [CocoaPods doc on the Podfile](https://guides.cocoapods.org/using/the-podfile.html).

```ruby
pod 'Contentful', '~> 5.0.0'
```

#### Carthage installation

You can also use [Carthage](https://github.com/Carthage/Carthage) for integration by adding the following to your `Cartfile`:

```
github "contentful/contentful.swift" ~> 5.0.0
```

#### Swift Package Manager [swift-tools-version 5.0]

Add the following line to your array of dependencies:

```swift
.package(url: "https://github.com/contentful/contentful.swift", .upToNextMajor(from: "5.0.0"))
```

### Your first request

The following code snippet is the most basic one you can use to fetch content from Contentful with this SDK:

```swift
import Contentful

let client = Client(spaceId: "cfexampleapi",
                    environmentId: "master", // Defaults to "master" if omitted.
                    accessToken: "b4c0n73n7fu1")

client.fetch(Entry.self, id: "nyancat") { (result: Result<Entry>) in
    switch result {
    case .success(let entry):
        print(entry)
    case .error(let error):
        print("Error \(error)!")
    }
}
```

### Accessing the Preview API

To access the Content Preview API, use your preview access token and set your client configuration to use preview as shown below.

```swift

let client = Client(spaceId: "cfexampleapi",
                    accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50",
                    host: Host.preview) // Defaults to Host.delivery if omitted.
```

### Authorization

Grab credentials for your Contentful space by [navigating to the "APIs" section of the Contentful Web App](https://app.contentful.com/deeplink?link=api).
If you don't have access tokens for your app, create a new set for the Delivery and Preview APIs.
Next, pass the id of your space and delivery access token into the initializer like so:

### Map Contentful entries to Swift classes via `EntryDecodable`

The `EntryDecodable` protocol allows you to define a mapping between your content types and your Swift classes that entries will be serialized to. When using methods such as:

```swift
let query = QueryOn<Cat>.where(field: .color, .equals("gray"))

client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    guard let cats = result.value?.items else { return }
    print(cats)
}
```

The asynchronously returned result will be an instance of `ArrayResponse` in which the generic type parameter is the same type you've passed into the `fetch` method. If you are using a `Query` that does not restrict the response to contain entries of one content type, you will use methods that return `MixedArrayResponse` instead of `ArrayResponse`. The `EntryDecodable` protocol extends the `Decodable` protocol in Swift 4's Foundation standard library. The SDK provides helper methods for resolving relationships between `EntryDecodable`s and also for grabbing values from the fields container in the JSON for each resource.

In the example above, `Cat` is a type of our own definition conforming to `EntryDecodable` and `FieldKeysQueryable`. In order for the SDK to properly create your model types when receiving JSON, you must pass in these types to your `Client` instance:

```swift
let contentTypeClasses: [EntryDecodable.Type] = [
    Cat.self
    Dog.self,
    Human.self
]

let client = Client(spaceId: spaceId,
                    accessToken: deliveryAPIAccessToken,
                    contentTypeClasses: contentTypeClasses)
```

The source for the `Cat` model class is below; note the helper methods the SDK adds to Swift 4's `Decoder` type to simplify for parsing JSON returned by Contentful. You also need to pass in these types to your `Client` instance in order to use the fetch methods which take `EntryDecodable` type references:

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

    // Relationship fields.
    var bestFriend: Cat?

    public required init(from decoder: Decoder) throws {
        let sys         = try decoder.sys()
        id              = sys.id
        localeCode      = sys.locale
        updatedAt       = sys.updatedAt
        createdAt       = sys.createdAt

        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Cat.FieldKeys.self)

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

If you want to simplify the implementation of an `EntryDecodable`, declare conformance to `Resource` and add `let sys: Sys` property to the class and assign via `sys = try decoder.sys()` during initialization. Then, `id`, `localeCode`, `updatedAt`, and `createdAt` are all provided via the `sys` property and don't need to be declared as class members. However, note that this style of implementation may make integration with local database frameworks like Realm and CoreData more cumbersome.

Additionally, the SDK requires that instances of a type representing an entry or asset must be a `class` instance, not a `struct`—this is because the SDK ensures that the in-memory object graph is complete, but also that it has no duplicates.

## Documentation & References

### Reference Documentation

The SDK has 100% documentation coverage of all public variables, types, and functions. You can view the docs on the [web](https://contentful.github.io/contentful.swift/docs/index.html) or browse them in Xcode. For further information about the Content Delivery API, check out the [Content Delivery API Reference Documentation](https://www.contentful.com/developers/documentation/content-delivery-api/).

### Tutorials & other resources

* This library is a wrapper around our Contentful Delivery REST API. Some more specific details such as search parameters and pagination are better explained on the [REST API reference](https://www.contentful.com/developers/docs/references/content-delivery-api/), and you can also get a better understanding of how the requests look under the hood.
* Check the [Contentful for Swift](https://www.contentful.com/developers/docs/ios/tutorials/) page for Tutorials, Demo Apps, and more information on other ways of using Swift with Contentful

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

## Swift Versioning

It is recommended to use Swift 5.0, as older versions of the SDK will not have fixes backported. If you must use older Swift versions, see the compatible tags below.

 Swift version | Compatible Contentful tag |
| --- | --- |
| Swift 5.0 | [ ≥ `5.0.0` ] |
| Swift 4.2 | [ ≥ `4.0.0` ] |
| Swift 4.1 | [`2.0.0` - `3.1.2`] |
| Swift 4.0 | [`0.10.0` - `1.0.1`] |
| Swift 3.x | [`0.3.0` - `0.9.3`] |
| Swift 2.3 | `0.2.3` |
| Swift 2.2 | `0.2.1` |


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

We appreciate any help on our repositories. For more details about how to contribute see our [Contributing.md](Contributing.md) document.

## License

This repository is published under the [MIT](LICENSE) license.

## Code of Conduct

We want to provide a safe, inclusive, welcoming, and harassment-free space and experience for all participants, regardless of gender identity and expression, sexual orientation, disability, physical appearance, socioeconomic status, body size, ethnicity, nationality, level of experience, age, religion (or lack thereof), or other identity markers.

[Read our full Code of Conduct](https://github.com/contentful-developer-relations/community-code-of-conduct).
