//
//  Contentful
//
//  Created by Tomasz Szulc on 26/09/2020.
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Foundation

public extension Client {

    /**
    Fetches the raw `Data` objects and bypass the JSON parsing provided by the SDK.

    - Parameters:
        - url: The URL representing the endpoint with query parameters.
        - completion: The completion handler to call when the request is complete.
     */
    @discardableResult
    func fetch(
        url: URL,
        then completion: @escaping ResultsHandler<Data>
    ) -> URLSessionDataTask {
        fetchData(
            url: url,
            completion: completion
        )
    }

    /**
    Fetches the JSON data at the specified URL and decoding it.

    - Parameters:
        - url: The URL representing the endpoint with query parameters.
        - completion: The completion handler wrapping `DecodableType` to call when the request is complete.
     */
    @discardableResult
    func fetch<DecodableType: Decodable>(
        url: URL,
        then completion: @escaping ResultsHandler<DecodableType>
    ) -> URLSessionDataTask {
        fetchDecodable(
            url: url,
            completion: completion
        )
    }

    /**
    Fetches a resource by id.

    Available resource types that match this function's constraints are: `Space`, `Asset`, `ContentType`, `Entry`,
    or any of custom types conforming to `EntryDecodable` or `AssetDecodable`.

    - Parameters:
        - resourceType: A reference to the Swift type which conforms to `Decodable & EndpointAccessible`.
        - id: The identifier of the resource.
        - include: The level of includes to be resolved. Default value when nil. See more: [Retrieval of linked items].
        - completion: The completion handler to call when the request is complete.

    [Retrieval of linked items]: https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/links/retrieval-of-linked-items
     */
    @discardableResult
    func fetch<ResourceType>(
        _ resourceType: ResourceType.Type,
        id: String,
        include includesLevel: UInt? = nil,
        then completion: @escaping ResultsHandler<ResourceType>
    ) -> URLSessionDataTask where ResourceType: Decodable & EndpointAccessible {
        fetchResource(
            resourceType: resourceType,
            id: id,
            include: includesLevel,
            completion: completion
        )
    }

    /**
    Fetches collections of `ContentType`, `Entry`, and `Asset` types.

    - Parameters:
        - resourceType: A reference to concrete resource class which conforms to `Decodable & EndpointAccessible & ResourceQueryable`.
        - query: Query to match results against.
        - completion: The completion handler with `ArrayResponse` to call when the request is complete.
     */
    @discardableResult
    func fetchArray<ResourceType, QueryType>(
        of resourceType: ResourceType.Type,
        matching query: QueryType? = nil,
        then completion: @escaping ResultsHandler<HomogeneousArrayResponse<ResourceType>>
    ) -> URLSessionDataTask where ResourceType: ResourceQueryable, QueryType == ResourceType.QueryType {
        fetchDecodable(
            url: url(endpoint: ResourceType.endpoint, parameters: query?.parameters ?? [:]),
            completion: completion
        )
    }

    /**
    Fetches collections of `EntryDecodable` of your own definition.

    - Parameters:
        - entryType: A reference to a concrete Swift class conforming to `EntryDecodable` that will be fetched.
        - query: Query to match results against.
        - completion: The completion handler with `ArrayResponse` to call when the request is complete.
     */
    @discardableResult
    func fetchArray<EntryType>(
        of entryType: EntryType.Type,
        matching query: QueryOn<EntryType> = QueryOn<EntryType>(),
        then completion: @escaping ResultsHandler<HomogeneousArrayResponse<EntryType>>
    ) -> URLSessionDataTask {
        fetchDecodable(
            url: url(endpoint: .entries, parameters: query.parameters),
            completion: completion
        )
    }

    /**
    Fetches heterogenous collections of types conforming to `EntryDecodable`.

    - Parameters:
        - query: Query to match results against.
        - completion: The completion handler to call when the request is complete.
     */
    @discardableResult
    func fetchArray(
        matching query: Query? = nil,
        then completion: @escaping ResultsHandler<HeterogeneousArrayResponse>
    ) -> URLSessionDataTask {
        fetchDecodable(
            url: url(endpoint: .entries, parameters: query?.parameters ?? [:]),
            completion: completion
        )
    }

    /**
    Fetches data associated with `AssetProtocol` object.

    - Parameters:
        - asset: Instance that has the URL for media file.
        - imageOptions: Options for server-side manipulations of image files.
        - completion: The completion handler to call when the request is complete.
     */
    @discardableResult
    func fetchData(
        for asset: AssetProtocol,
        with imageOptions: [ImageOption] = [],
        then completion: @escaping ResultsHandler<Data>
    ) -> URLSessionDataTask? {
        do {
            let url = try asset.url(with: imageOptions)
            return fetchData(
                url: url,
                completion: completion
            )
        } catch let error {
            completion(.failure(error))
            return nil
        }
    }
    /**
    Fetches the space this client is configured to interface with.

    - Parameters:
        - completion: The completion handler to call when the reqeust is complete.
     */
    @discardableResult
    func fetchSpace(then completion: @escaping ResultsHandler<Space>) -> URLSessionDataTask? {
        fetchCurrentSpace(then: completion)
    }

    /**
    Fetches all `Locale`s belonging to the current space the client is configured to interface with.

    - Parameters:
        - completion: The completion handler to call when the request is complete.
     */
    @discardableResult
    func fetchLocales(then completion: @escaping ResultsHandler<HomogeneousArrayResponse<Contentful.Locale>>) -> URLSessionDataTask {
        fetchCurrentSpaceLocales(then: completion)
    }
}
