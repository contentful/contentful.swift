import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
//: In order to execute this playground, please build the "Contentful_macOS" scheme to build the SDK.
/*:
  ![](contentful-logo-white.png)

  Contentful is an API-first CMS which helps developers deliver content to their apps with API calls, while offering content editors a familiar-looking [web app](https://app.contentful.com) for creating and managing content. This Playground shows how to make API calls to fetch content from Contentful's Content Delivery API (CDA) via the Swift SDK. It also explains what the API response looks like after it has been mapped to native Swift types, and suggests some relevant next steps.
 */
import Contentful
//: This is the space identifer. A space is like a project folder in Contentful terms.
let spaceId = "developer_bookshelf"
//: This is the access token for this space. You can find both the space id and your CDA access token in the Contentful web app.
let accessToken = "0b7f6x59a0"
/*:
 ## Make the first request
Create a `Client` object using those credentials, this type is used to make all API requests.
 */
let client = Client(spaceId: spaceId, accessToken: accessToken)

//: To request an entry with the specified ID:
client.fetchEntry(id: "5PeGS2SoZGSa4GuiQsigQu") { (result: Result<Entry, Error>) in
    switch result {
    case .failure(let error):
        print("Oh no an error: \(error)!")

    case .success(let entry):
//: All resources in Contentful have a variety of read-only, system-managed properties, stored in the “sys” property. This includes things like when the resource was last updated and how many revisions have been published.
        print("The system properties for this entry are: '\(entry.sys)'")

//: Entries contain a collection of fields, key-value pairs containing the content created in the web app.
        print("The fields for this entry are: '\(entry.fields)'")
/*:
## Custom content structures

Contentful is built on the principle of structured content: a set of key-value pairs is not a great interface to program against if the keys and data types are always changing!

Just the same way you can set up any content structure in a MySQL database, you can set up a custom content structure in Contentful, too. There are no presets, templates, or anything of the kind – you can (and should) set everything up depending on the logic of your project.

This structure is maintained by content types, which define what data fields are present in a content entry.
*/
        guard let contentTypeId = entry.sys.contentTypeId else { return }
        print("The content type for this entry is: '\(contentTypeId)'")

    }
}
//: This is a link to the content type which defines the structure of "book" entries. Being API-first, we can of course fetch this content type from the API and inspect it to understand what it contains.
client.fetchContentType(id: "book") { (result: Result<ContentType, Error>) in
    switch result {
    case .failure(let error):
        print("Oh no an error: \(error)!")

    case .success(let contentType):
//: Like entries, content types have a set of read-only system managed properties.
        print("The system properties for this content type are '\(contentType.sys)'")

//: A content type is a container for a collection of fields:
        guard let field = contentType.fields.first else { return }
//: The field ID is used in API responses.
        print("The first field for the 'book' content type has an internal identifier: '\(field.id)'")
//: The field name is shown to editors when changing content in the web app.
        print("The name of the field when editing entries of this content type at app.contentful.com is: '\(field.name)'")
//: Indicates whether the content in this field can be translated to another language.
        print("This field is localized, true or false? '\(field.localized)'")
//: The field type determines what can be stored in the field, and how it is queried. See the [doc on Contentful concepts](https://www.contentful.com/developers/docs/concepts/data-model/) for more information on field types
        print("The type of data that can be stored in this field is '\(field.type)'")
    }
}
/*:
**To sum up**: Contentful enables structuring content in any possible way, making it accessible both to developers through the API and for editors via the web interface. It becomes a reasonable tool to use for any project that involves at least some content that should be properly managed – by editors, in a CMS – instead of having developers deal with the pain of hardcoded content.
 
[Next](@next)
*/
