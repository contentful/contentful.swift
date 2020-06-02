//: [Previous](@previous)
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Contentful

//: In order to execute this playground, please build the "Contentful_macOS" scheme to build the SDK.
//: As a first step, we again create an instance of `Client` connected to the space of interest.
let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")

/*: You can fetch all entries from a space.
There are two sets of methods method's for fetching data from Contentful. One set returns an `Observable` from the [Interstellar](https://github.com/JensRavens/Interstellar) framework. */
let observable = client.fetchEntries()
//: The signal represents a stream of values over time, you can react to the eventual result of an array of entries:
observable.next { entriesArrayResponse in
    let total = entriesArrayResponse.total
    guard let firstEntry = entriesArrayResponse.items.first else { return }
    guard let entryName = firstEntry.fields.string(at: "name") else { return }
    print("The first entry in the response has a 'name' of '\(entryName)' and it is of type '\(firstEntry.sys.contentTypeId!)' ")
}
//: and you can also react to errors:
observable.error { error in
    print("Oh no, an error: \(error)!")
}
//: If you prefer a callback-based API, it is also available and has the added bonus of enabling request cancellation.
let urlTask = client.fetchEntries { result in
    switch result {
    case .success(let entriesArrayResponse):
        let total = entriesArrayResponse.total
        let secondEntry = entriesArrayResponse.items[1]
        guard let entryName = secondEntry.fields.string(at: "name") else { return }
        print("The second entry in the response has a 'name' of '\(entryName)' and it is of type '\(secondEntry.sys.contentTypeId!)'")
    case .failure(let error):
        print("Oh no, an error: \(error)!")
    }
}
/*: You can also fetch more specific content, using search parameters by defining a `Query`.
 In this case we'll limit our query results to only entries of type 'cat' and sort the results in reverse chronological order.
 */
let query = try! Query.where(contentTypeId: "cat").order(by: Ordering(sys: .createdAt, inReverse: true))
client.fetchEntries(matching: query).next { catsArrayResponse in
    let catNames = catsArrayResponse.items.flatMap { $0.fields["name"] }
    print("All cat names as an array: '\(catNames)'")

    guard let cat = catsArrayResponse.items.first else { return }
//: Each entry has a number of read-only system fields, like its creation date
    let creationDate = cat.sys.createdAt
//: You also have access to its user-defined fields in a similar fashion
    let name = cat.fields.string(at: "name") ?? ""
    let likes = cat.fields.strings(at: "likes")?.joined(separator: " and ") ?? ""
    let lives = cat.fields.int(at: "lives") ?? 0

    print("Accessing the name field for the first cat, we see that it's name is '\(name)'")
    print("\(name) likes '\(likes)'")
    print("\(name) has '\(lives)' lives")
//: The SDK will also resolve any included links automatically for you.
    guard let friend = cat.fields.linkedEntry(at: "bestFriend") else { return }

    let friendsName = friend.fields.string(at: "name") ?? ""
    let friendsLikes = friend.fields.strings(at: "likes")?.joined(separator: " and ") ?? ""

    print("\(name)'s friend is named: '\(friendsName)'")
    print("\(name)'s friend likes '\(friendsLikes)'")
}
//: Contentful also supports localization of entries, you can fetch a specific locale using the `Query` type.
let localeSpecificQuery = Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "tlh")
client.fetchEntries(matching: localeSpecificQuery).next { catsArrayResponse in
    let name = catsArrayResponse.items.first?.fields.string(at: "name") ?? ""

    print("The name of the first cat in the 'tlh' locale is '\(name)'")
}
//: It is also possible to fetch content for all locales, by specific the "*" locale.
let wildcardLocaleQuery = Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "*")
client.fetchEntries(matching: wildcardLocaleQuery).next { catsArrayResponse in
    var cat = catsArrayResponse.items.first

//: In that case, the fields property will point to values of the currently selected locale.
    var currentLocale = cat?.currentlySelectedLocale
    print("Default locale is: '\(currentLocale!.code)'")
    var name = cat?.fields.string(at: "name")
    var likes = cat?.fields.strings(at: "likes")?.joined(separator: " and" ) ?? ""
    print("The cat's likes for the default locale of the space are: '\(likes)'")
//: You can change the selected locale by using the `setLocale(withCode:)` instance method on `Entry`.
    cat?.setLocale(withCode: "tlh")
    currentLocale = cat?.currentlySelectedLocale
    print("Now the locale for reading data has been set to: '\(currentLocale!.code)'")
    name = cat?.fields.string(at: "name")
//: For fields which do not have a value for the currenlty selected locale, the "fallback chain" will be walked by the SDK until a value is found, or until the default locale is reached. This is similar to the behaviour of the API itself when using queries that don't specify the wildcard locale "*".
    likes = cat?.fields.strings(at: "likes")?.joined(separator: " and" ) ?? ""
    print("The cat's likes for the 'tlh' locale are \(likes)")
}

//: [Next](@next)
