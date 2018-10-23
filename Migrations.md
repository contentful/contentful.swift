## Migrating from version `3.x.x` to `4.x.x`

Version 4 is the largest overhaul of the Swift SDK since version 1 and will require a number of changes. These changes have helped to create an SDK that is much more flexible in the ways you can use it. More details below:

1. Unless you are using the `Interstellar` framework on your own accord, you can now remove any `import Interstellar` statements from your codebase. The Contentful Swift SDK is now dependency free :tada:! If you were relying on some of the functional-reactive methods provided by `Interstellar`, you will now need to remove any calls to `.then` and replace them with callbacks that switch on the `Result`.

2. `EntryQueryable` has been renamed `FieldKeysQueryable`, the required associated type `Fields` has been renamed `FieldKeys` to accurately reflect the type's real usage and intent.

3. The most significant change in version 4 is that the syntax for all fetch methods has been upgraded. If you were previously fetching `Entry` instances with `client.fetchEntries`, migrate to the following:

```swift
client.fetchArray(of: Entry.self, matching: Query()) { (result: Result<ArrayResponse<Entry>>) in
  // Completion handler here.
}
```

Similarly, if you were previously fetching `EntryDecodable`, say `Cat` as an example, instances with `client.fetchMappedEntries`, migrate to the following:

```swift
client.fetchArray(of: Cat.self, matching: QueryOn<Cat>()) { (result: Result<ArrayResponse<Cat>>) in
  // Completion handler here. 
}
```

One thing to note is that `MappedArrayResponse` has been obviated and now `ArrayResponse` is used when fetching `Entry` instances as well as your own types conforming to `EntryDecodable`.

4. The SDK now exposes the base methods for fetching raw `Data` so that you can construct queries, but handle the data however you like rather than relying on the SDK for object deserialization and mapping. As an example, it is now possible to use the `fetch(url: URL, then completion: @escaping ResultsHandler<Data>)` method to fetch raw JSON data, and save that data to disk—you could still use the SDK to deserialize the JSON data, but it is no longer necessary to tightly couple the HTTP request execution with JSON deserialization.

For more information on all the changes in version 4, see the [CHANGELOG](CHANGELOG.md).

## Migrating from version `2.x.x` to `3.x.x`

There are only two breaking changes to look out for when migrating from `2.x.x` to `3.x.x` versions. 

#### Client configuration changes

If you were using the `Client` type to interface with the Content Preview API, you will need to refactor your `Client` initializer. Instead of setting a variable on the `ClientConfiguration`, you now will configure a `Client` like so:

```swift
let client = Client(spaceId: "<space_id>",
                    accessToken: "<preview_token>",
                    host: Host.preview) // Defaults to Host.delivery if omitted.
```

You can also pass in a custom host if your Contentful organization has white-labeled a separate API domain as part of your plan.

#### Image formatting changes

If you want to use the Images API to convert an image to a png before being returned from the server, you must now specify the bit depth. The options are `.eight` or `.standard`;

```swift
let imageOptions: [ImageOption] = [.formatAs(.png(bits: .eight))]

client.fetchImage(for: asset, with: imageOptions) { ... }
```


## Migrating from version `1.x.x` to `2.x.x`

The breaking changes between `1.x.x` and `2.x.x` are minimal. Nonetheless, you may need to update some of your code:

- The interface for synchronization has been simplified. `initialSync` and `nextSync` have been replaced with `sync` with a default argument of an empty sync space to start an initial sync operation. An initial sync would be done like this:
```swift
client.sync { result in
   ...
}
```

A subsequent sync is done like so:

```swift
// `syncSpace` is an existing instance returned by a prior sync.
client.sync(syncSpace: syncSpace) { result in
   ...
}
```

- The SDK provided methods for creating a new `Swift.JSONDecoder` and updating it with locale information of your space or environment has changed. The new syntax uses extensions on the `JSONDecoder` type and looks as follows:
```swift
let jsonDecoder = JSONDecoder.withoutLocalizationContext()
jsonDecoder.update(with: localizationContext) // Pass in an instance of `LocalizationContext`
```

- The `LocalizationContext` property of `Space` has been moved and is now a property of `Client`.
- `ResourceQueryable` has been renamed `EntryQueryable` for correctness and consistency; update your model class definitions as follows:

```swift
class MyModelClass: EntryDecodable, EntryQueryable
```
