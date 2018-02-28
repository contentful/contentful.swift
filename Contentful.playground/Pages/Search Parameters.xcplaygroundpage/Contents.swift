//: [Previous](@previous)
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Contentful
//: In order to execute this playground, please build the "Contentful_macOS" scheme to build the SDK.
//: As a first step, you have to create a client object again.
let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")
/*:
 Each collection endpoint supports a variety of query parameters to search & filter the items that will be included in the response. While the API calls in this section are focused on entries, there is similar syntax and query types available which can be used to filter assets.
 
 This page lists all possible search parameters supported by the API. You can find additional information in our [API reference documentation](http://docs.contentfulcda.apiary.io/#reference/search-parameters).
 
 Given the asynchronous nature of these network requests and their responses, the output in the console may not be ordered the same as the code below. The output is less important than the actual code for creating a query for the purposes of this demo.
 */
//: Searching by content type
var query = Query.where(contentTypeId: "cat")
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Search for entries which have a specific value for a specific property (equality). This works for "sys" properties as well as fields:
query = Query.where(sys: .id, .equals("nyanCat"))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Search for entries which do _not_ contain a specific value (inequality):
query = Query.where(sys: .id, .doesNotEqual("nyanCat"))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Searching for entries with specific values also works for arrays:
query = Query.where(contentTypeId: "cat").where(valueAtKeyPath: "fields.likes", .equals("lasagna"))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Filtering a field by multiple values:
query = Query.where(sys: .id, .includes(["finn", "jake"]))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Multiple-value filters can also be inverted:
query = Query.where(valueAtKeyPath: "sys.id", .excludes(["rainbows", "lasagna"]))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: You can filter using range operators, like less than or equal:
query = Query.where(sys: .updatedAt, .isGreaterThanOrEqualTo(Date()))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Full-text search across all text and symbol fields is also supported:
query = try! Query.searching(for: "bacon")
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Or you can search for text in a specific field:
query = Query.where(contentTypeId: "dog").where(valueAtKeyPath: "fields.description", .matches("bacon pancakes"))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}

//: If you have location-enabled content, you can use it for searching as well. Sort results by distance:
query = Query.where(contentTypeId: "1t9IbcfdCk6m04uISSsaIK").where(valueAtKeyPath: "fields.center", .isNear(Location(latitude: 38, longitude: -122)))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}

//: Or retrieve all resources in a bounding rectangle:
let bottomLeft = Location(latitude: 40, longitude: -124)
let topRight = Location(latitude: 36, longitude: -121)
let boundingBox = Bounds.box(bottomLeft: bottomLeft, topRight: topRight)
query = Query.where(contentTypeId: "1t9IbcfdCk6m04uISSsaIK").where(valueAtKeyPath: "fields.center", .isWithin(boundingBox))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Sort results by field values:
query = try! Query.order(by: Ordering(sys: .createdAt))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Sort results by field values in reverse order:
query = try! Query.order(by: Ordering(sys: .createdAt, inReverse: true))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Or order results by multiple fields:
query = try! Query.order(by: Ordering(sys: .createdAt), Ordering(sys: .id))
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: The API returns a maximum of 1000 entries, but the default is 100. You can specify the amount of results to return:
query = Query.limit(to: 3)
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: And you can skip a number of results. By combining both parameters, you can do paging for larger result sets:
query = Query.skip(theFirst: 3)
client.fetchEntries(matching: query).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: Finally, you can filter assets by their MIME type:
let assetsQuery = AssetQuery.where(mimetypeGroup: .image)
client.fetchAssets(matching: assetsQuery).next {
    let names = $0.items.flatMap { $0.fields.string(at: "name") }
    print(names)
}
//: [Next](@next)
