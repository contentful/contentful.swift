# contentful.swift

<!-- [![Version](https://img.shields.io/cocoapods/v/Contentful.svg?style=flat)](http://cocoadocs.org/docsets/Contentful)
[![Platform](https://img.shields.io/cocoapods/p/Contentful.svg?style=flat)](http://cocoadocs.org/docsets/Contentful)
[![License](https://img.shields.io/cocoapods/l/Contentful.svg?style=flat)](http://cocoadocs.org/docsets/Contentful) -->
[![Build Status](https://img.shields.io/travis/contentful/contentful.swift/master.svg?style=flat)](https://travis-ci.org/contentful/contentful.swift)
[![Coverage Status](https://img.shields.io/coveralls/contentful/contentful.swift.svg)](https://coveralls.io/github/contentful/contentful.swift)

Swift SDK for [Contentful's][1] Content Delivery API.

[Contentful][1] is a content management platform for web applications, mobile apps and connected devices. It allows you to create, edit & manage content in the cloud and publish it anywhere via powerful API. Contentful offers tools for managing editorial teams and enabling cooperation between organizations.

The Contentful Swift SDK hasn't reached 1.0, yet, but provides a much nicer API than using the [Objective-C SDK][4] from Swift. If you need some of the more advanced features, like [offline persistence][5] using Core Data, you have to stick to the Objective-C SDK for now. Check out our [Swift example][6] in this case.

## Usage


```swift
let client = Client(spaceIdentifier: "cfexampleapi", accessToken: "b4c0n73n7fu1")
client.fetchEntry("nyancat") { (result) in
    switch result {
        case let .Success(entry):
            print(entry)
        case .Error(_):
            print("Error!")
    }
}
```

## Documentation

For further information, check out the [Developer Documentation][3].

## Installation

The Contentful Swift SDK requires Swift 2.0 and therefore Xcode 7.

### CocoaPods

[CocoaPods][2] is a dependency manager for Swift, which automates and simplifies the process of using 3rd-party libraries like the Contentful Delivery API in your projects.

```ruby
platform :ios, '9.0'
use_frameworks!
pod 'Contentful'
```

## License

Copyright (c) 2014, 2015 Contentful GmbH. See LICENSE for further details.


[1]: https://www.contentful.com
[2]: http://www.cocoapods.org
[3]: https://www.contentful.com/developers/documentation/content-delivery-api/
[4]: https://github.com/contentful/contentful.objc
[5]: https://www.contentful.com/blog/2014/05/09/ios-content-synchronization/
[6]: https://github.com/contentful-labs/swiftful
