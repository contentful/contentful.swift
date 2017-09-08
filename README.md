<a href="https://www.contentful.com" target="_blank"><img src="./Resources/contentful-logo.png" alt="Contentful" width="680"/></a>

# contentful.swift
  
[![Version](https://img.shields.io/cocoapods/v/Contentful.svg?style=flat)](http://cocoadocs.org/docsets/Contentful)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager](https://rawgit.com/jlyonsmith/artwork/master/SwiftPackageManager/swiftpackagemanager-compatible.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/cocoapods/p/Contentful.svg?style=flat)](http://cocoadocs.org/docsets/Contentful)
[![License](https://img.shields.io/cocoapods/l/Contentful.svg?style=flat)](http://cocoadocs.org/docsets/Contentful)
[![Build Status](https://img.shields.io/travis/contentful/contentful.swift/master.svg?style=flat)](https://travis-ci.org/contentful/contentful.swift)
[![Coverage Status](https://img.shields.io/coveralls/contentful/contentful.swift.svg)](https://coveralls.io/github/contentful/contentful.swift)
[![codebeat badge](https://codebeat.co/badges/6ebc67e8-29ca-459f-a4b7-b32a84fa9074)](https://codebeat.co/projects/github-com-contentful-contentful-swift)

Swift SDK for [Contentful's][1] Content Delivery API.

[Contentful][1] is a content management platform for web applications, mobile apps and connected devices. It allows you to create, edit & manage content in the cloud and publish it anywhere via powerful API. Contentful offers tools for managing editorial teams and enabling cooperation between organizations.

The Contentful Swift SDK hasn't reached 1.0.0 and is therefore subject to API changes. However, it provides a more usable API than the [Objective-C SDK][4] and has support for more API features. It is recommended to use contentful.swift over contentful.objc as future development at Contentful will focus on Swift rather than Objective-C. However, if your project must utilize Contentful's [Content Managamement API][11], Objective-C is the only  language supported at the moment. See [ContentfulManagementAPI at Cocoapods.org][12] for more information.

#### Full feature comparison of [contentful.swift][9] & [contentful.objc][4]

| CDA Features | [contentful.swift][10] | [contentful.objc][4] |
| -----------  | ----------- | ----------- |
| API coverage* | :white_check_mark: | :white_check_mark: |
| Images API | :white_check_mark: | :white_check_mark: |
| Search Parameters | :white_check_mark: | :no_entry_sign: |
| Fallback locales for sync api | :white_check_mark: | :no_entry_sign: |
| Rate limit handling | :white_check_mark: | :no_entry_sign: |

*API Coverage definition: all endpoints can be interfaced with and complex queries can be constructed by passing in dictionaries of http parameter/argument pairs. Note that the Swift SDK provides much more comprehensive coverage and takes advantage of type system, outdoing the "stringly typed" interface that the Objective-C SDK offers.

## Usage

```swift
let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")
client.fetchEntry("nyancat") { (result: Result<Entry>) in
    switch result {
        case .success(entry):
            print(entry)
        case .error(let error):
            print("Error \(error)!")
    }
}
```

## `EntryModellable` and `MappedContent`

The `EntryModellable` protocols allows you to define types that will be mapped from `Entry`s of the various content types in your Contentful space. When using methods such as:

```swift
func fetchMappedEntries(with query: Query) -> Observable<Result<MappedContent>>
```

the asynchronously returned result will be an instance of `MappedContent` which will contain a dictionary which maps content type identifiers to arrays of `EntryModellable` (types of your own definition) that have been fetched. Note that these features are in beta and the API is subject to change.

## Swift playground

If you'd like to try an interactive demo of the API via a Swift Playground, do the following:

```bash
git clone --recursive https://github.com/contentful/contentful.swift.git
cd contentful.swift
make open
```

Then build the "Contentful_macOS" scheme, open the playground file and go! Note: make sure the "Render Documentation" button is switched on in the Utilities menu on the right of Xcode, and also open up the console to see the outputs of the calls to `print`.

## Reference Documentation

For further information about the API, check out the [Content Delivery API Reference Documentation][3].

## Xcode versioning

Unless you're using Swift 2.x, the project is built and unit tested in Travis CI on both Xcode 8.3 and Xcode 9. You should be able to integrate the SDK with either version of Xcode.

## Swift Versioning

The Contentful Swift SDK requires, at minimum, Swift 2.2 and therefore Xcode 7.3.

 Swift version | Compatible Contentful tag |
| --- | --- |
| Swift 3.0 | [`0.3.0` - `0.9.3`] |
| Swift 2.3 | `0.2.3` |
| Swift 2.2 | `0.2.1` |

While there have been some patches applied to the [`Swift-2.3` branch][9], no future maintainence is intended on this branch. It is recommended to upgrade to Swift 3 and
use the newest version of contentful.swift.

### CocoaPods installation

[CocoaPods][2] is a dependency manager for Swift, which automates and simplifies the process of using 3rd-party libraries like the Contentful Delivery API in your projects.

```ruby
platform :ios, '8.0'
use_frameworks!
pod 'Contentful'
```

You can specify a specific version of Contentful depending on your needs. To learn more about operators for dependency versioning within a Podfile, see the [CocoaPods doc on the Podfile][7].

```ruby
pod 'Contentful', '~> 0.9.3' 
```

Note that for Swift 2.3 support (contentful.swift `v0.2.3`) you will need to add a post-install script to your Podfile if installing with Cocoapods:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
```

### Carthage installation

You can also use [Carthage][8] for integration by adding the following to your `Cartfile`:

```
github "contentful/contentful.swift" ~> 0.9.3
```

## License

Copyright (c) 2016 Contentful GmbH. See LICENSE for further details.

[1]: https://www.contentful.com
[2]: http://www.cocoapods.org
[3]: https://www.contentful.com/developers/documentation/content-delivery-api/
[4]: https://github.com/contentful/contentful.objc
[5]: https://www.contentful.com/blog/2014/05/09/ios-content-synchronization/
[6]: https://github.com/contentful-labs/swiftful
[7]: https://guides.cocoapods.org/using/the-podfile.html
[8]: https://github.com/Carthage/Carthage
[9]: https://github.com/contentful/contentful.swift/tree/Swift-2.3
[10]: https://github.com/contentful/contentful.swift
[11]: https://www.contentful.com/developers/docs/references/content-management-api/
[12]: https://cocoapods.org/pods/ContentfulManagementAPI

