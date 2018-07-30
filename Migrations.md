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
