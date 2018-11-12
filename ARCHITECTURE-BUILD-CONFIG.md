# SDK architecture, build system, and release process

## SDK architecture and important protocols

Swift is, in the words of Apple, a "Protocol-Oriented Programming" language. Therefore there are many protocols in the SDK. Some of these protocols are especially important for SDK consumers, since their model-classes will have to conform to them.

### `Resource`

`Resource` is the base protocol for assets and entries in the SDK, as well as custom model-classes corresponding to user content types. All that is necessary to conform to resource is to have a `sys` property of type `Sys` on the type

### `FlatResource`

`FlatResource` takes all the properties that belong to `Sys` and requires that types implementing `FlatResource` put those properties one level up. So a `FlatResource` has `id`, `localeCode`, `createdAt`, and `updatedAt`. One of the reasons that this protocol exists, is to make the lives of Cocoa developers much easier by bringing `id` to the top level. For instance, if you want to store entities in CoreData, then `id` _should_ be on the top level of the object, rather than nested in a relationship to a separate `sys` object.

Because Swift offers languages features such as protocol extensions, default protocol implementations, and "conditional conformance", any class that implements `Resource` and also declares conformance to `FlatResource` gets an implementation of `FlatResource` for free:

```swift
public extension FlatResource where Self: Resource {
    public var id: String {
        return sys.id
    }

    public var type: String {
        return sys.type
    }

    public var updatedAt: Date? {
        return sys.updatedAt
    }

    public var createdAt: Date? {
        return sys.createdAt
    }

    public var localeCode: String? {
        return sys.locale
    }
}
```

### `AssetProtocol`

While `Asset` is the class that represents an asset in Contentful, the `AssetProtocol`, similar to `FlatResource` exists to simplify storing assets in local databases like CoreData. `Asset` conforms to `AssetProtocol`, and types for storing assets to CoreData when using the [contentful-persistence.swift](https://github.com/contentful/contentful-persistence.swift) also conform to `AssetProtocol`.

### `EntryDecodable`

`EntryDecodable` has a simple definition:

```swift
public protocol EntryDecodable: FlatResource, Decodable, EndpointAccessible {
    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }
}
```

Notice that this protocol extends [`Decodable`](https://developer.apple.com/documentation/swift/decodable), which is Swift standard library API for deserializing a type from JSON. When the SDK deserializes entries, it will introspect the `contentTypeId` string and then delegate to deserialize the correct `EntryDecodable`. One caveat to this is that the `EntryDecodable` type _must_ be passed to the client during initialization in order to properly lookup the users' content types:

```swift
let contentTypeClasses: [EntryDecodable.Type] = [ContentTypeA.self, ContentTypeB.self]
return TestClientFactory.testClient(withCassetteNamed: "LinkResolverTests",
                                    spaceId: "<SPACE_ID>",
                                    accessToken: "<DELIVERY_TOKEN>",
                                    contentTypeClasses: contentTypeClasses)
```

Because `Decodable` is standard library, all users need to do to conform to `EntryDecodable` is implement `Decodable` using helper methods provided by the SDK, add `sys` properties (or simply declare conformance to `Resource` and add a `sys: Sys` variable), and add a content type identifier. Here is an example:

```swift
final class Cat: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId: String = "cat"

    let sys: Sys
    let color: String?
    let name: String?
    let lives: Int?
    let likes: [String]?

    // Relationship fields.
    var bestFriend: Cat?
    var image: Asset?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Cat.FieldKeys.self)

        self.name       = try fields.decodeIfPresent(String.self, forKey: .name)
        self.color      = try fields.decodeIfPresent(String.self, forKey: .color)
        self.likes      = try fields.decodeIfPresent(Array<String>.self, forKey: .likes)
        self.lives      = try fields.decodeIfPresent(Int.self, forKey: .lives)

        try fields.resolveLink(forKey: .bestFriend, decoder: decoder) { [weak self] linkedCat in
            self?.bestFriend = linkedCat as? Cat
        }
        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self ] image in
            self?.image = image as? Asset
        }
    }
    
    enum FieldKeys: String, CodingKey {
        case bestFriend, image
        case name, color, likes, lives
    }
}
```

### `FieldKeysQueryable`

You probably noticed that there is an additional protocol that `Cat` conforms to above, which is `FieldKeysQueryable`. This class is used to enable type-safe construction of queries by using the `FieldKeys`. This paradigm was actually taken from `Decodable` as decoding methods require a `CodingKey` be used (this is the JSON key for a given member in a JSON object). Users can then construct queries such as the following:

```swift
let query = QueryOn<Cat>.where(field: .color, .equals("gray"))
```

This query resolves to the HTTP URL parameters:

```
content_type=cat&fields.color=gray
```

## Dependencies and testing
 
- There are no dependencies for the SDK and users are happy about this since it means a smaller app size and a simpler path to integrating the SDK in projects.
- There are a few test dependencies, both of which are used to facilitate stubbing network responses so that the SDK:
	1. Does not hit the API directly for every test run
	2. Is resilient to content changes in the Contentful spaces since many test assertions test that certain content is present on specific entries and fields.
- All assertions are simple `XCTest` assertions; the matcher framework [Nimble](https://github.com/Quick/Nimble) has been integrated into the SDK, pruned, integrated again, then pruned again. The last time it was pruned because the maintainers did not fix an issue that caused compilation failures from command line builds (such as Travis CI builds) for tvOS and macOS. Using native `XCTest` assertions guarantees a more robust build pipeline and avoids depending on third-party maintainers to keep their project up-to-date with the latest Xcode and Swift versions. It is recommended that Nimble not be integrated again despite the syntactic sugar niceties it provides.

## The build system and dependency management

### Xcode

- The project _must_ be buildable with Xcode as Xcode is used to submit iOS apps, tvOS apps, and watchOS apps to the app store.

### Swift version

- The Swift version used by the project must be reflected in three places: 
	- in the `.swift-version` file in the root directory,
	- in the Xcode target's "Build Settings" for the flag `SWIFT_VERSION`
	- in the Cocoapods podspec, `Contentful.podspec` with the line: `spec.swift_version = 'VERSION_NUMBER'`

### Ruby

- Most Cocoa developers are aware that Ruby is a required dependency for development: this is because tools like Cocoapods, [Jazzy](https://github.com/realm/jazzy) (SDK reference doc generator), [Slather](https://github.com/SlatherOrg/slather/) (code-coverage reporter), and [xcpretty](https://github.com/supermarin/xcpretty) (output formatter for tests run from the command line) are all implemented in Ruby and distributed as Ruby gems.
  - Therefore there is a `Gemfile` and `Gemfile.lock` in the project, and before development, those gems should be installed with: `bundle install`
  - **Important** ensure that you prefix any CLI commands for the above-mentioned tools with `bundle exec` so that you are using the correct version of the Ruby gem.
    - For instance, when you need to push a new release to Cocoapods, instead of using the command `pod trunk push`, you should use, `bundle exec pod trunk push`.
- The only dependencies the project has are for the testing suite, and therefore consumers of the SDK don't need to worry about any third-party dependencies when installing the SDK. Of course, people developing the SDK must worry about managing test dependencies and building them locally and on Travis CI.


### SwiftLint

- [SwiftLint](https://github.com/realm/SwiftLint) is a fantastic linter for Swift that enforces community-accepted best practices for code formatting in Swift. SwiftLint can be installed via home brew: `brew intall swiftlint` and executed from the command line.
- In the "Build Phases" configuration for each of the SDK targets, there is a SwiftLint script called (actually the Script delegates like so: `"$SRCROOT/Scripts/BuildPhases/SwiftLint.sh"` since the Xcode editor shows at most 3 lines of code. It is much easier to manage build scripts by putting them in their own files and using a better editor). 
- If you inspect `Scripts/BuildPhases/SwiftLint.s`, you'll notice that SwiftLint is not executed on Travis because installing SwiftLint on Travis adds too much unnecessary time to the build.
- SwiftLint is configured via the `.swiftlint.yml` file in the root directory of the project.

### Dependencies are managed with Carthage as Git submodules

  - The project itself manages it's own dependencies with [Carthage](https://github.com/Carthage/Carthage). A lot of developers use Carthage to integrate pre-compiled binaries into their Xcode projects, however, Carthage also offers other integration paths and the SDK uses two flags for the Carthage CLI: `--use-submodules` and `--no-build`. The `--use-submodules` flag turns Carthage into a mechanism for managing Git submodules, with each submodule being saved to within the `Carthage/Checkouts/` directory. The `Carthage/Checkouts` directory is, and should remain checked into version control.
  - The commands for installing, or updating dependencies are the following:
  - `carthage bootstrap --use-submodules --no-build` will download the dependency versions described in the `Cartfile.resolved` file. (Note that you could substitute this command with `git submodule update --init --recursive` and you would achieve the same result).
  - `carthage update --use-submodules --no-build` will update dependency versions depending on the operators used in the `Cartfile.private` and `Cartfile` files.
  - Each submodule, as they are all projects for the Cocoa platforms, has its own Xcode project. Those Xcode projects are pulled into the `Contentful.xcworkspace` so that the frameworks they build are made available for linking.
  - There are 7 targets in the project: 4 framework targets (Contentful_iOS, Contentful_macOS, Contentful_tvOS, Contentful_watchOS) and 3 test targets (ContentfulTests_iOS, ContentfulTests_macOS, ContentfulTests_tvOS; there is currently no unit testing framework provided by Apple for watchOS). Similarly, the test dependencies, [DVR](https://github.com/venmo/DVR) and [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs/) also have one target per operating system: iOS, tvOS, and macOS. Those test frameworks are linked in the "Link with Binary Libraries" "Build phases" section for each respective test target. Since the test dependencies Xcode projects are withing the workspace, no other linking flags need to be added, greatly simplifying the project configuration.
- Why wasn't Cocoapods used to manage (test) dependencies? Cocoapods is a great package manager, but when developing a framework, it turns out that the build scripts that Cocoapods adds to a Cocoapods-managed project make building the framework impossible if it was installed via other package managers like Carthage or [Swift Package Manager](https://swift.org/package-manager/). The build script injected by Cocoapods cannot be executed without Cocoapods being integrated into user's project. Managing the Contentful Swift SDK's dependencies with Carthage enables distribution with _all_ supported package managers.

## Continuous integration

- One of the fantastic things about using Carthage to manage Git submodules is that continuous integration systems like Travis and Circle don't actually need to install Carthage to resolve the dependencies: they can just run `git submodule update --init`. In fact, Travis runs this command by default and users must opt out of it if they so choose (Travis runs `git submodule update --init --recursive`).
- There is a build matrix setup on Travis so that each of the testable targets can be compiled and have it's tests run. 
- There is an additional job in the matrix to ensure that the project can be successfully compiled with `swift build` in case there are users building the project with the `swift` CLI.
- Command line builds are executed with `xcodebuild` commands. See the [.travis.yml](https://github.com/contentful/contentful.swift/blob/master/.travis.yml) file and the [Travis build script](https://github.com/contentful/contentful.swift/blob/master/Scripts/travis-build-test.sh) to get a better understanding of how command line builds work.
- Just as Ruby must be installed during local development so that the proper Gems can be installed and executed, Ruby must installed on Travis. This is common configuration for Cocoa projects. Ruby gems are cached for faster builds.

	```
	rvm:
	  - 2.4.3
	cache: bundler
	```

- Travis calls `slather` to report the code coverage back to the pull request
- Travis also uses the Cocoapods linter to ensure that the project will be ready for distribution via Cocoapods using the command: `bundle exec pod lib lint Contentful.podspec`.

## Supporting distribution on package managers

### Changing the SDK version number

There are a few places where the version number needs to be changed:

- The `Config.xcconfig` file which the Xcode project uses to set the version and inject it into the `X-Contentful-User-Agent` HTTP header.
- The `.env` file—the `Contentful.podspec` is a technically just a Ruby file, and that file uses the `dotenv` Ruby-gem to pull the version from the `.env` file. The release script and the doc generation script also source this file to tag the release properly and push the docs.
- To prevent mistakes caused by forgetting to set the version in one of these files, there is a script in the project that takes a version number as an argument, and will change version in the `Config.xcconfig` and the `.env` files:

```bash
./Scripts/set-version.sh 5.0.0
```

### Releasing

- Firstly, bump the version using the `set-version` script and make sure to add all the relevant release information to the CHANGELOG.md file.
- There is a `make` command for releasing. Simply run `make release` to:
	- Push a new version to the Cocoapods trunk
	- Compile the binaries to be attached to the relevant Github release
	- Build the SDK documentation website and push it to the `gh-pages` branch—deployed to the web with Github pages. The documentation is generated with a Ruby-gem called [Jazzy](https://github.com/realm/jazzy).
- After running this command, you must manually attach the `Contentful.framework.zip` file to the Github release. 
- Also, copy the text from the changelog entry into the Github release.


### Cocoapods

- Cocoapods is the only "centralized" package manager of the three that are supported by the SDK. What this means is that Cocoapods maintains a special "specs" repo which authorized framework and libraries developers must push to in order to release new versions for distribution.
	- Only registered Cocoapods users who have been added as "owners" to the project can push new versions of the SDK.
- The `Contentful.podspec` file describes the package that will be distributed to the Cocoapods "trunk".

### Carthage

- Carthage is a decentralized package manager. For users to install the SDK via Carthage, all that is necessary is a `git tag` pushed to a remote Git provider—in this case, Github. The user then simply adds a line to their `Cartfile` that points to the Github repo and desired tagged version. Carthage users can opt to integrate compiled binaries, or the project source code. If there is a compiled binary attached to the Github release, Carthage will simply download it and place it at `Carthage/Builds/PLATFOMR`, where `PLATFORM` could be any of the 4 Cocoa operating systems. If there is no binary attached to the Github release, it will download the source and _then_ compile it—this is quite time and energy consuming for the users' machine. Be nice and attach the binaries to the release ;-)

### Swift Package Manager

- Swift Package Manager is also a decentralized package manager. All that is necessary to distribute the package via SPM is to have the code hosted with a Git provider with a tagged version available.

## Supported operating systems

- We support all Cocoa operating systems: macOS, tvOS, watchOS, and iOS
- Operating specific code is wrapped in preprocessor macros:

```swift
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
```

## Deployment targets

In the world of Cocoa, frameworks and apps are built against a base SDK, generally the most recent operating system released by Apple, but are backwards compatible will all operating systems that have a version number greater than the "Minimum deployment target". Generally, we only support two operating systems back: so if the most recent version of iOS on the market is 12, we have a minimum deployment target of 10. Any change to the minimum deployment target is a breaking change and should result in a major version number bump on the SDK.

