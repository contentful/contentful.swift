//
//  Client.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar


/// A tuple of data task, enabling the cancellation of http requests, and an `Observable` for the resulting
/// items that were fetched from the Contentful Content Delivery API.
public typealias TaskObservable<T> = (task: URLSessionDataTask?, observable: Observable<Result<T>>)

/// The completion callback for an API request with a `Result<T>` containing the requested object of
/// type `T` on success, or an error if the request was unsuccessful.
public typealias ResultsHandler<T> = (_ result: Result<T>) -> Void

/// Client object for performing requests against the Contentful API.
open class Client {

    fileprivate let clientConfiguration: ClientConfiguration

    /// The identifier of the space this Client is set to interface with.
    public let spaceId: String

    /// The identifier of the environment within the space that this Client is set to interface with.
    public let environmentId: String

    /// Available Locales for this environment
    public var locales: [Contentful.Locale]?

    /// Context for holding information about the fallback chain of locales for the Space.
    public private(set) var localizationContext: LocalizationContext! {
        didSet {
            // Inject locale information to JSONDecoder.
            jsonDecoder.update(with: localizationContext)
        }
    }

    /// The base domain that all URIs have for each request the client makes.
    public let host: String

    /// The JSONDecoder that the receiving client instance uses to deserialize JSON. The SDK will
    /// inject information about the locales to this decoder and use this information to normalize
    /// the fields dictionary of entries and assets.
    public var jsonDecoder: JSONDecoder

    /**
     The persistence integration which will receive delegate messages from the `Client` when new
     `Entry` and `Asset` objects are created from data being sent over the network. Currently, these
     messages are only sent for `client.initialSync()` and `client.nextSync`. The relevant
     persistence integration lives at <https://github.com/contentful/contentful-persistence.swift>.
     */
    public var persistenceIntegration: PersistenceIntegration? {
        didSet {
            guard var headers = self.urlSession.configuration.httpAdditionalHeaders else {
                assertionFailure("Headers should have already been set on the current URL Session.")
                return
            }
            assert(headers["Authorization"] != nil)
            headers["X-Contentful-User-Agent"] = clientConfiguration.userAgentString(with: persistenceIntegration)

            // There is a bug in foundation with directly setting the headers like so self.urlSession.configuration.header = ...
            // so we must recreate the URLSession in order to set the headers.
            let configuration = self.urlSession.configuration
            configuration.httpAdditionalHeaders = headers
            self.urlSession = URLSession(configuration: configuration)
        }
    }

    // The delegate which will receive messages containing the raw data fetched at a specified URL.
    private var dataDelegate: DataDelegate?

    internal var urlSession: URLSession

    fileprivate(set) var space: Space?

    fileprivate var scheme: String { return clientConfiguration.secure ? "https": "http" }

    /**
     Initializes a new Contentful client instance

     - Parameter spaceId: The space you want to perform requests against.
     - Parameter accessToken: The access token used for authorization.
     - Parameter clientConfiguration: Custom Configuration of the Client.
     - Parameter sessionConfiguration: The configuration for the URLSession. Note that HTTP headers will be overwritten
     interally by the SDK so that requests can be authorized correctly.
     - Parameter persistenceIntegration: An object conforming to the `PersistenceIntegration` protocol
     which will receive messages about created/deleted Resources when calling `sync()` methods.
     - Parameter contentModel: the ContentModel which references the model classes to map responses with Contentful entries 
                               to when using the relevant fetch methods.
     - Returns: An initialized client instance.
     */
    public init(spaceId: String,
                environmentId: String = "master",
                accessToken: String,
                host: String = Host.delivery,
                clientConfiguration: ClientConfiguration = .default,
                sessionConfiguration: URLSessionConfiguration = .default,
                persistenceIntegration: PersistenceIntegration? = nil,
                contentTypeClasses: [EntryDecodable.Type]? = nil) {

        self.spaceId = spaceId
        self.environmentId = environmentId
        self.host = host
        self.clientConfiguration = clientConfiguration

        self.jsonDecoder = JSONDecoder.withoutLocalizationContext()
        if let dateDecodingStrategy = clientConfiguration.dateDecodingStrategy {
            // Override default date decoding strategy if present
            jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        }
        if let timeZone = clientConfiguration.timeZone {
            jsonDecoder.userInfo[.timeZoneContextKey] = timeZone
        }

        if let contentTypeClasses = contentTypeClasses {
            var contentTypes = [ContentTypeId: EntryDecodable.Type]()
            for type in contentTypeClasses {
                contentTypes[type.contentTypeId] = type
            }
            jsonDecoder.userInfo[.contentTypesContextKey] = contentTypes
            jsonDecoder.userInfo[.linkResolverContextKey] = LinkResolver()
        }

        self.persistenceIntegration = persistenceIntegration
        self.dataDelegate = clientConfiguration.dataDelegate
        let contentfulHTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "X-Contentful-User-Agent": clientConfiguration.userAgentString(with: persistenceIntegration)
        ]
        sessionConfiguration.httpAdditionalHeaders = contentfulHTTPHeaders
        self.urlSession = URLSession(configuration: sessionConfiguration)
    }

    internal func url(endpoint: Endpoint, parameters: [String: String]? = nil) -> URL? {
        let pathComponent = endpoint.rawValue
        var components: URLComponents?

        switch endpoint {
        case .spaces:
            components = URLComponents(string: "\(scheme)://\(host)/spaces/\(spaceId)/\(pathComponent)")
        case .assets, .contentTypes, .locales, .entries, .sync:
            components = URLComponents(string: "\(scheme)://\(host)/spaces/\(spaceId)/environments/\(environmentId)/\(pathComponent)")
        }
        assert(components != nil)

        let queryItems: [URLQueryItem]? = parameters?.map { (key, value) in
            return URLQueryItem(name: key, value: value)
        }
        components?.queryItems = queryItems

        guard let url = components?.url else { return nil }
        return url
    }

    internal func fetch<DecodableType: Decodable>(url: URL?,
                        then completion: @escaping ResultsHandler<DecodableType>) -> URLSessionDataTask? {

        guard let url = url else {
            completion(Result.error(SDKError.invalidURL(string: "")))
            return nil
        }

        let finishDataFetch: (ResultsHandler<Data>) = { result in
            switch result {
            case .success(let mappableData):
                self.dataDelegate?.handleDataFetchedAtURL(mappableData, url: url)
                self.handleJSON(mappableData, completion)
            case .error(let error):
                completion(Result.error(error))
            }
        }

        let task = fetch(url: url) { dataResult in
            if url.lastPathComponent == "locales" || url.lastPathComponent == self.spaceId {
                // Now that we have all the locale information, start callback chain.
                finishDataFetch(dataResult)
            } else {
                self.fetchLocales { localesResult in
                    switch localesResult {
                    case .success:
                        // Trigger chain with data we're currently interested in.
                        finishDataFetch(dataResult)
                    case .error(let error):
                        // Return the current error.
                        finishDataFetch(Result.error(error))
                    }
                }
            }
        }
        return task
    }

    internal func fetch(url: URL, completion: @escaping ResultsHandler<Data>) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: url) { data, response, error in
            if let data = data {
                if self.didHandleRateLimitError(data: data, response: response, completion: completion) == true {
                    return // Exit if there was a RateLimitError.
                }

                // Use failable initializer to optional rather than initializer that throws,
                // because failure to find an error in the JSON should error should not throw an error that JSON is not parseable.
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        if let apiError = APIError.error(with: self.jsonDecoder,
                                                         data: data,
                                                         statusCode: response.statusCode) {
                            completion(Result.error(apiError))
                        } else {
                            // In case there is an error returned by the API that has an unexpected format, return a custom error.
                            let errorMessage = "An API error was returned that the SDK was unable to parse"
                            let error = SDKError.unparseableJSON(data: data, errorMessage: errorMessage)
                            completion(Result.error(error))
                        }
                        return
                    }
                }
                completion(Result.success(data))
                return
            }

            if let error = error {
                // An extra check, just in case.
                completion(Result.error(error))
                return
            }

            let sdkError = SDKError.invalidHTTPResponse(response: response)
            completion(Result.error(sdkError))
        }

        task.resume()
        return task
    }

    internal func fetch(url: URL) ->  (task: URLSessionDataTask?, observable: Observable<Result<Data>>) {
        let asyncDataTask: AsyncDataTask<URL, Data> = fetch
        return toObservable(parameter: url, asyncDataTask: asyncDataTask)
    }

    // Returns the rate limit reset.
    fileprivate func readRateLimitHeaderIfPresent(response: URLResponse?) -> Int? {
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {

                let rateLimitResetPair = httpResponse.allHeaderFields.filter { arg in
                    let (key, _) = arg
                    return (key as? String)?.lowercased() == "x-contentful-ratelimit-reset"
                }
                if let rateLimitResetString = rateLimitResetPair.first?.value as? String {
                    return Int(rateLimitResetString)
                }

            }
        }
        return nil
    }

    // Returns true if a rate limit error was returned by the API.
    fileprivate func didHandleRateLimitError(data: Data, response: URLResponse?, completion: ResultsHandler<Data>) -> Bool {
        if let timeUntilLimitReset = self.readRateLimitHeaderIfPresent(response: response) {
            // At this point, We know for sure that the type returned by the API can be mapped to an `APIError` instance.
            // Directly handle JSON and exit.
            self.handleRateLimitJSON(data, timeUntilLimitReset: timeUntilLimitReset) { (_ result: Result<RateLimitError>) in
                switch result {
                case .success(let rateLimitError):
                    completion(Result.error(rateLimitError))
                case .error(let auxillaryError):
                    // We should never get here, but we'll bubble up what should be a `SDKError.unparseableJSON` error just in case.
                    completion(Result.error(auxillaryError))
                }
            }
            return true
        }
        return false
    }

    fileprivate func handleRateLimitJSON(_ data: Data, timeUntilLimitReset: Int, _ completion: ResultsHandler<RateLimitError>) {
            guard let rateLimitError = try? jsonDecoder.decode(RateLimitError.self, from: data) else {
                completion(Result.error(SDKError.unparseableJSON(data: data, errorMessage: "SDK unable to parse RateLimitError payload")))
                return
            }
            rateLimitError.timeBeforeLimitReset = timeUntilLimitReset

            // In this case, .success means that a RateLimitError was successfully initialized.
            completion(Result.success(rateLimitError))
    }

    fileprivate func handleJSON<DecodableType: Decodable>(_ data: Data, _ completion: ResultsHandler<DecodableType>) {
        do {
            let decodedObject = try jsonDecoder.decode(DecodableType.self, from: data)
            completion(Result.success(decodedObject))
        } catch {
            completion(Result.error(SDKError.unparseableJSON(data: data, errorMessage: "The SDK was unable to parse the JSON: \(error)")))
        }
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
}

extension Client {

    /**
     Fetch all the locales belonging to the environment that was configured with the client.

     - Parameter completion: A handler being called on completion of the request.
     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchLocales(then completion: @escaping ResultsHandler<Array<Contentful.Locale>>) -> URLSessionDataTask? {
        if let locales = self.locales {
            let localeCodes = locales.map { $0.code }
            persistenceIntegration?.update(localeCodes: localeCodes)
            completion(Result.success(locales))
            return nil
        }

        // The robust thing to do would be to fetch all pages of the `/locales` endpoint, however, pagination is not supported
        // at the moment. We also are not expecting any consumers to have > 1000 locales as Contentful subscriptions do not allow that.
        let query = ResourceQuery.limit(to: QueryConstants.maxLimit)
        let url = self.url(endpoint: .locales, parameters: query.parameters)
        return fetch(url: url) { (result: Result<ArrayResponse<Contentful.Locale>>) in

            if let error = result.error {
                completion(Result.error(error))
                return
            }
            guard let locales = result.value?.items else {
                let error = SDKError.localeHandlingError(message: "Unable to parse locales from JSON")
                completion(Result.error(error))
                return
            }
            self.locales = locales

            let localeCodes = locales.map { $0.code }
            self.persistenceIntegration?.update(localeCodes: localeCodes)

            guard let localizationContext = LocalizationContext(locales: locales) else {
                let error = SDKError.localeHandlingError(message: "Locale with default == true not found in Environment!")
                completion(Result.error(error))
                return
            }
            self.localizationContext = localizationContext
            completion(Result.success(locales))
        }
    }

    /**
     Fetch all the locales belonging to the environment that was configured with the client.

     - Parameter completion: A handler being called on completion of the request.

     - Returns: The `Observable` for the resulting array of locales.
     */
    @discardableResult public func fetchLocales() -> Observable<Result<Array<Contentful.Locale>>> {
        let asyncDataTask: SignalBang<Array<Contentful.Locale>> = fetchLocales(then:)
        return toObservable(closure: asyncDataTask).observable
    }
}

extension Client {
    /**
     Fetch the space this client is constrained to.

     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, which enables cancellation of requests, or `nil` if the.
     Space was already cached locally
     */
    @discardableResult public func fetchSpace(then completion: @escaping ResultsHandler<Space>) -> URLSessionDataTask? {
        // Attempt to pull from cache first.
        if let space = self.space {
            completion(Result.success(space))
            return nil
        }
        return fetch(url: url(endpoint: .spaces)) { (result: Result<Space>) in
            self.space = result.value
            completion(result)
        }
    }

    /**
     Fetch the space this client is constrained to.

     - Returns: A tuple of data task and a signal for the resulting Space.
     */

    @discardableResult public func fetchSpace() -> Observable<Result<Space>> {
        let asyncDataTask: SignalBang<Space> = fetchSpace(then:)
        return toObservable(closure: asyncDataTask).observable
    }
}

extension Client {
    /**
     Fetch a single Asset from Contentful.

     - Parameter id: The identifier of the Asset to be fetched.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchAsset(id: String, then completion: @escaping ResultsHandler<Asset>) -> URLSessionDataTask? {
        return fetch(Asset.self, id: id, then: completion)
    }

    /**
     Fetch a single Asset from Contentful.

     - Parameter id: The identifier of the Asset to be fetched.

     - Returns: The `Observable` for the resulting Asset.
     */
    @discardableResult public func fetchAsset(id: String) -> Observable<Result<Asset>> {
        let asyncDataTask: AsyncDataTask<String, Asset> = fetchAsset(id:then:)
        return toObservable(parameter: id, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The AssetQuery object to match results against.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchAssets(matching query: AssetQuery? = nil,
                                               then completion: @escaping ResultsHandler<ArrayResponse<Asset>>) -> URLSessionDataTask? {
        return fetch(url: url(endpoint: .assets, parameters: query?.parameters), then: completion)
    }

    /**
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The AssetQuery object to match results against.
     - Returns: The `Observable` for the resulting array of Assets.
     */
    @discardableResult public func fetchAssets(matching query: AssetQuery? = nil) -> Observable<Result<ArrayResponse<Asset>>> {
        let asyncDataTask: AsyncDataTask<AssetQuery?, ArrayResponse<Asset>> = fetchAssets(matching:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch the underlying media file as `Data`.

     - Parameter asset: The `Asset` which contains the relevant media file.
     - Parameter imageOptions: An optional array of options for server side manipulations.
     - Returns: The `Observable` for the `Data` result.

     */
    @discardableResult public func fetchData(for asset: AssetProtocol, with imageOptions: [ImageOption] = []) -> Observable<Result<Data>> {
        do {
            return fetch(url: try asset.url(with: imageOptions)).observable
        } catch let error {
            let observable = Observable<Result<Data>>()
            observable.update(Result.error(error))
            return observable
        }
    }
}


// New way of interacting to be made public in future pull requests.
extension Client {

    @discardableResult internal func fetch<ResourceType, QueryType>(_ resourceType: ResourceType.Type, matching query: QueryType,
        then completion: @escaping ResultsHandler<ArrayResponse<ResourceType>>) -> URLSessionDataTask?
        where ResourceType: EndpointAccessible & ResourceQueryable, QueryType == ResourceType.QueryType {
            return fetch(url: url(endpoint: ResourceType.endpoint, parameters: query.parameters), then: completion)
    }

    @discardableResult internal func fetch<ResourceType>(_ resourceType: ResourceType.Type,
                                                         id: String,
                                                         then completion: @escaping ResultsHandler<ResourceType>) -> URLSessionDataTask?
        where ResourceType: Resource & Decodable & EndpointAccessible {

            // If the resource is not an entry, then don't worry about fetching with includes.
            if resourceType != EntryDecodable.self && resourceType != Entry.self {
                var url = self.url(endpoint: ResourceType.endpoint)
                url?.appendPathComponent(id)
                return fetch(url: url, then: completion)
            }

            let fetchCompletion: (Result<ArrayResponse<ResourceType>>) -> Void = { result in
                switch result {
                case .success(let response) where response.items.first != nil:
                    completion(Result.success(response.items.first!))
                case .error(let error):
                    completion(Result.error(error))
                default:
                    completion(Result.error(SDKError.noResourceFoundFor(id: id)))
                }
            }

            let query = ResourceQuery.where(sys: .id, .equals(id))
            return fetch(url: url(endpoint: ResourceType.endpoint, parameters: query.parameters), then: fetchCompletion)
    }

    @discardableResult internal func fetch<EntryType>(matching query: QueryOn<EntryType>,
                                                      then completion: @escaping ResultsHandler<MappedArrayResponse<EntryType>>) -> URLSessionDataTask? {
        let url = self.url(endpoint: .entries, parameters: query.parameters)
        return fetch(url: url, then: completion)
    }

    @discardableResult internal func fetch(matching query: Query,
                                           then completion: @escaping ResultsHandler<MixedMappedArrayResponse>) -> URLSessionDataTask? {
        let url = self.url(endpoint: .entries, parameters: query.parameters)
        return fetch(url: url, then: completion)
    }
}

extension Client {
    /**
     Fetch a single Content Type from Contentful.

     - Parameter id: The identifier of the Content Type to be fetched.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchContentType(id: String,
                                                    then completion: @escaping ResultsHandler<ContentType>) -> URLSessionDataTask? {
        return fetch(ContentType.self, id: id, then: completion)
    }

    /**
     Fetch a single Content Type from Contentful.

     - Parameter id: The identifier of the Content Type to be fetched.

     - Returns: A tuple of data task and a signal for the resulting Content Type.
     */
    @discardableResult public func fetchContentType(id: String) -> Observable<Result<ContentType>> {
        let asyncDataTask: AsyncDataTask<String, ContentType> = fetchContentType(id:then:)
        return toObservable(parameter: id, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a collection of Content Types from Contentful.

     - Parameter matching:   Optional list of search parameters the Content Types must match.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchContentTypes(matching query: ContentTypeQuery? = nil,
                                                     then completion: @escaping ResultsHandler<ArrayResponse<ContentType>>) -> URLSessionDataTask? {
        return fetch(url: url(endpoint: .contentTypes, parameters: query?.parameters), then: completion)
    }

    /**
     Fetch a collection of Content Types from Contentful.

     - Parameter matching: Optional list of search parameters the Content Types must match.

     - Returns: A tuple of data task and a signal for the resulting array of Content Types.
     */
    @discardableResult public func fetchContentTypes(matching query: ContentTypeQuery? = nil) -> Observable<Result<ArrayResponse<ContentType>>> {
        let asyncDataTask: AsyncDataTask<ContentTypeQuery?, ArrayResponse<ContentType>> = fetchContentTypes(matching:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }
}

extension Client {
    /**
     Fetch a single Entry from Contentful.

     - Parameter id: The identifier of the Entry to be fetched.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchEntry(id: String,
                                              then completion: @escaping ResultsHandler<Entry>) -> URLSessionDataTask? {
        let fetchEntriesCompletion: (Result<ArrayResponse<Entry>>) -> Void = { result in
            switch result {
            case .success(let entries) where entries.items.first != nil:
                completion(Result.success(entries.items.first!))
            case .error(let error):
                completion(Result.error(error))
            default:
                completion(Result.error(SDKError.noEntryFoundFor(id: id)))
            }
        }

        let query = Query.where(sys: .id, .equals(id))
        return fetchEntries(matching: query, then: fetchEntriesCompletion)
    }

    /**
     Fetch a single Entry from Contentful.

     - Parameter id: The identifier of the Entry to be fetched.

     - Returns: A tuple of data task and a signal for the resulting Entry.
     */
    @discardableResult public func fetchEntry(id: String) ->  Observable<Result<Entry>> {
        let asyncDataTask: AsyncDataTask<String, Entry> = fetchEntry(id:then:)
        return toObservable(parameter: id, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a collection of entries from Contentful matching the specified query. This method does not
     specify the content_type in the query parameters, so the entries returned in the results can be
     of any type.

     - Parameter query: The query object to match results againts.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchEntries(matching query: Query? = nil,
                                                then completion: @escaping ResultsHandler<ArrayResponse<Entry>>) -> URLSessionDataTask? {
        let url = self.url(endpoint: .entries, parameters: query?.parameters)
        return fetch(url: url, then: completion)
    }

    /**
     Fetch a collection of entries from Contentful matching the specified query. This method does not
     specify the content_type in the query parameters, so the entries returned in the results can be
     of any type.
     - Parameter query: The query object to match results againts.

     - Returns: A tuple of data task and an observable for the resulting array of Entry's.
     */
    @discardableResult public func fetchEntries(matching query: Query? = nil) -> Observable<Result<ArrayResponse<Entry>>> {
        let asyncDataTask: AsyncDataTask<Query?, ArrayResponse<Entry>> = fetchEntries(matching:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }
}


// MARK: Sync

extension Client {

    /**
     Perform a synchronization operation, updating the passed in `SyncSpace` object with
     latest content from Contentful. If the passed in `SyncSpace` is a new empty instance with an empty
     sync token, a full synchronization will be done.

     Calling this will mutate the instance and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - Parameter syncSpace: the relevant `SyncSpace` to perform the subsequent sync on. Defaults to a new empty instance of sync space.
     - Parameter syncableTypes: The types that can be synchronized.

     - Returns: An `Observable` which will be fired when the `SyncSpace` is fully synchronized with Contentful.
     */
    @discardableResult public func sync(for syncSpace: SyncSpace = SyncSpace(),
                                        syncableTypes: SyncSpace.SyncableTypes = .all) -> Observable<Result<SyncSpace>> {

        let observable = Observable<Result<SyncSpace>>()
        self.sync(for: syncSpace, syncableTypes: syncableTypes) { result in
            observable.update(result)
        }
        return observable
    }


    /**
     Perform a synchronization operation, updating the passed in `SyncSpace` object with
     latest content from Contentful. If the passed in `SyncSpace` is a new empty instance with an empty
     sync token, a full synchronization will be done.

     Calling this will mutate passed in SyncSpace and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - Parameter syncSpace: the relevant `SyncSpace` to perform the subsequent sync on. Defaults to a new empty instance of sync space.
     - Parameter syncableTypes: The types that can be synchronized.
     - Parameter completion: A handler which will be called on completion of the operation

     - Returns: The data task being used, enables cancellation of requests.
     */

    @discardableResult public func sync(for syncSpace: SyncSpace = SyncSpace(),
                                        syncableTypes: SyncSpace.SyncableTypes = .all,
                                        then completion: @escaping ResultsHandler<SyncSpace>) -> URLSessionDataTask? {

        // Preview mode only supports `initialSync` not `nextSync`. The only reason `nextSync` should
        // be called while in preview mode, is internally by the SDK to finish a multiple page sync.
        // We are doing a multi page sync only when syncSpace.hasMorePages is true.
        if !syncSpace.syncToken.isEmpty && host == Host.preview && syncSpace.hasMorePages == false {
            completion(Result.error(SDKError.previewAPIDoesNotSupportSync()))
            return nil
        }

        let parameters = syncableTypes.parameters + syncSpace.parameters
        return fetch(url: url(endpoint: .sync, parameters: parameters)) { (result: Result<SyncSpace>) in

            var mutableResult = result
            if case .success(let newSyncSpace) = result {
                // On each new page, update the original sync space and forward the diffs to the
                // persistence integration.
                syncSpace.updateWithDiffs(from: newSyncSpace)
                self.persistenceIntegration?.update(with: newSyncSpace)
                mutableResult = .success(syncSpace)
            }
            if let syncSpace = result.value, syncSpace.hasMorePages == true {
                self.sync(for: syncSpace, syncableTypes: syncableTypes, then: completion)
            } else {
                completion(mutableResult)
            }
        }
    }
}
