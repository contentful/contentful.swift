//
//  Client.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import ObjectMapper
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
    fileprivate let spaceId: String
    fileprivate var persistenceIntegration: PersistenceIntegration?
    fileprivate var server: String {

        if clientConfiguration.previewMode && clientConfiguration.server == Defaults.cdaHost {
            return Defaults.previewHost
        }
        return clientConfiguration.server
    }

    internal var urlSession: URLSession

    fileprivate let contentModel: ContentModel?

    fileprivate(set) var space: Space?

    fileprivate var scheme: String { return clientConfiguration.secure ? "https": "http" }

    /**
     Initializes a new Contentful client instance

     - Parameter spaceId: The space you want to perform requests against.
     - Parameter accessToken: The access token used for authorization.
     - Parameter clientConfiguration: Custom Configuration of the Client.
     - Parameter sessionConfiguration: The configuration for the URLSession. Note that HTTP headers will be overwritten
                                       interally by the SDK so that requests can be authorized correctly.

     - Returns: An initialized client instance.
     */
    public init(spaceId: String,
                accessToken: String,
                clientConfiguration: ClientConfiguration = .default,
                sessionConfiguration: URLSessionConfiguration = .default,
                persistenceIntegration: PersistenceIntegration? = nil,
                contentModel: ContentModel? = nil) {

        self.spaceId = spaceId
        self.clientConfiguration = clientConfiguration
        self.contentModel = contentModel
        self.persistenceIntegration = persistenceIntegration

        let contentfulHTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "X-Contentful-User-Agent": clientConfiguration.userAgentString(with: persistenceIntegration)
        ]
        sessionConfiguration.httpAdditionalHeaders = contentfulHTTPHeaders
        self.urlSession = URLSession(configuration: sessionConfiguration)
    }

    internal func URL(forComponent component: String = "", parameters: [String: Any]? = nil) -> URL? {
        if var components = URLComponents(string: "\(scheme)://\(server)/spaces/\(spaceId)/\(component)") {
            if let parameters = parameters {
                let queryItems: [URLQueryItem] = parameters.map { key, value in
                    var value = value

                    if let date = value as? Date {
                        value = date.iso8601String
                    }

                    if let array = value as? NSArray {
                        value = array.componentsJoined(by: ",")
                    }

                    return URLQueryItem(name: key, value: (value as AnyObject).description)
                }

                if queryItems.count > 0 {
                    components.queryItems = queryItems
                }
            }

            if let url = components.url {
                return url
            }
        }

        return nil
    }

    // MARK: -

    fileprivate func fetch<MappableType: ImmutableMappable>(url: URL?, then completion: @escaping ResultsHandler<MappableType>)
        -> URLSessionDataTask? {

        guard let url = url else {
            completion(Result.error(SDKError.invalidURL(string: "")))
            return nil
        }

        // Get the observable and the underlying url task.
        let (task, observable): (URLSessionDataTask?, Observable<Result<Data>>)
        (task, observable) = fetch(url: url)

        if let spaceURL = self.URL(), spaceURL.absoluteString == url.absoluteString {

            // observable for space http request.
            observable.then { [weak self] mappableSpaceData in
                self?.handleJSON(mappableSpaceData, completion)
                }.error { error in
                    completion(Result.error(error))
            }
        } else {
            // IMPORTANT: If there is an error fetching the space, the error is handled in the recursive call
            // to fetch, so we do NOT want to handle the error case here.
            _ = fetchSpace().then { _ in
                observable.then { [weak self] mappableData in
                    self?.handleJSON(mappableData, completion)
                }.error { error in
                    completion(Result.error(error))
                }
            }
        }
        return task
    }

    // Returns the rate limit reset.
    fileprivate func readRateLimitHeaderIfPresent(response: URLResponse?) -> Int? {
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {
                if let rateLimitResetString = httpResponse.allHeaderFields["X-Contentful-RateLimit-Reset"] as? String {
                    return Int(rateLimitResetString)
                }
            }
        }
        return nil
    }

    // Returns true if a rate limit error was returned by the API.
    fileprivate func didHandleRateLimitError(data: Data, response: URLResponse?, completion: ResultsHandler<Data>) -> Bool {
        if let timeUntilLimitReset = self.readRateLimitHeaderIfPresent(response: response) {
            // At this point, We know for sure that the type returned by the API can be mapped to a `ContentfulError` instance.
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
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                let error = SDKError.unparseableJSON(data: data, errorMessage: "SDK unable to parse RateLimitError payload")
                completion(Result.error(error))
                return
            }

            let map = Map(mappingType: .fromJSON, JSON: json)
            guard let rateLimitError = RateLimitError(map: map) else {
                completion(.error(SDKError.unparseableJSON(data: data, errorMessage: "SDK unable to parse RateLimitError payload")))
                return
            }
            rateLimitError.timeBeforeLimitReset = timeUntilLimitReset

            // In this case, .success means that a RateLimitError was successfully initialized.
            completion(Result.success(rateLimitError))
        } catch _ {
            completion(.error(SDKError.unparseableJSON(data: data, errorMessage: "SDK unable to parse RateLimitError payload")))
        }
    }

    fileprivate func fetch(url: URL, completion: @escaping ResultsHandler<Data>) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: url) { data, response, error in
            if let data = data {
                if self.didHandleRateLimitError(data: data, response: response, completion: completion) == true {
                    return // Exit if there was a RateLimitError.
                }
                completion(Result.success(data))
                return
            }

            if let error = error {
                completion(Result.error(error))
                return
            }

            let sdkError = SDKError.invalidHTTPResponse(response: response)
            completion(Result.error(sdkError))
        }

        task.resume()
        return task
    }

    fileprivate func fetch(url: URL) ->  (task: URLSessionDataTask?, observable: Observable<Result<Data>>) {
        let asyncDataTask: AsyncDataTask<URL, Data> = fetch
        return toObservable(parameter: url, asyncDataTask: asyncDataTask)
    }

    fileprivate func handleJSON<MappableType: ImmutableMappable>(_ data: Data, _ completion: ResultsHandler<MappableType>) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                let error = SDKError.unparseableJSON(data: data, errorMessage: "Foundation.JSONSerialization failed")
                completion(Result.error(error))
                return
            }

            let localizationContext = space?.localizationContext
            let map = Map(mappingType: .fromJSON, JSON: json, context: localizationContext)

            // Use `Mappable` failable initialzer to optional rather throwing `ImmutableMappable` initializer
            // because failure to find an error in the JSON should error should not throw an error that JSON is not parseable.
            if let apiError = ContentfulError(map: map) {
                completion(Result.error(apiError))
                return
            }

            // Locales will be injected via the map.property option.
            let decodedObject = try MappableType(map: map)
            completion(Result.success(decodedObject))

        } catch let error as MapError {
            completion(.error(SDKError.unparseableJSON(data: data, errorMessage: "\(error)")))
        } catch _ {
            completion(.error(SDKError.unparseableJSON(data: data, errorMessage: "")))
        }
    }
}

// MARK: - Query

extension Client {
    /**
     Fetch a collection of Entries from Contentful matching the specified query. This method does not
     specify the content_type in the query parameters, so the entries returned in the results can be
     of any type.

     - Parameter query: The Query object to match results againts.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchEntries(with query: Query,
                                                then completion: @escaping ResultsHandler<ArrayResponse<Entry>>) -> URLSessionDataTask? {

        let url = URL(forComponent: "entries", parameters: query.parameters)
        return fetch(url: url, then: completion)
    }

    /**
     Fetch a collection of Entries from Contentful matching the specified query. This method does not
     specify the content_type in the query parameters, so the entries returned in the results can be
     of any type.
     - Parameter query: The Query object to match results againts.

     - Returns: A tuple of data task and an observable for the resulting array of Entry's.
     */
    @discardableResult public func fetchEntries(with query: Query) -> Observable<Result<ArrayResponse<Entry>>> {
        let asyncDataTask: AsyncDataTask<Query, ArrayResponse<Entry>> = fetchEntries(with:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The Query object to match results againts.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchAssets(with query: AssetQuery,
                                               then completion: @escaping ResultsHandler<ArrayResponse<Asset>>) -> URLSessionDataTask? {

        let url = URL(forComponent: "assets", parameters: query.parameters)
        return fetch(url: url, then: completion)
    }

    /**
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The Query object to match results againts.
     - Returns: A tuple of data task and an observable for the resulting array of Assets.
     */
    @discardableResult public func fetchAssets(query: AssetQuery) -> Observable<Result<ArrayResponse<Asset>>> {
        let asyncDataTask: AsyncDataTask<AssetQuery, ArrayResponse<Asset>> = fetchAssets(with:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }
}


// MARK: Mappable

extension Client {
    /**
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The Query object to match results againts.
     - Returns: An Observable forr the resulting `MappedContent` container.
     */
    @discardableResult public func fetchMappedEntries(with query: Query) -> Observable<Result<MappedContent>> {
        let asyncDataTask: AsyncDataTask<Query, MappedContent> = fetchMappedEntries(with:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetches all entries and includes matching the passed in `Query`. The completion handler returned will return a `MappedContent` object which
     contains an array of `Asset`s and a dictionary of ContentTypeId's to arrays of `EntryModellable` types of your own defining.
     
     - Parameter query: The Query object to match results against.
     - Parameter completion: A handler being called on completion of the request containing a `MappedContent` instance.
     
     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchMappedEntries(with query: Query,
                                                      then completion: @escaping ResultsHandler<MappedContent>) -> URLSessionDataTask? {

        let url = URL(forComponent: "entries", parameters: query.parameters)

        return fetch(url: url) { (result: Result<ArrayResponse<Entry>>) in
            let mappedResult: Result<MappedContent> = result.flatMap { return Result.success($0.toMappedContent(for: self.contentModel)) }
            completion(mappedResult)
        }
    }

    /**
     Fetch a collection of Entries of a specified content type matching the query. The content_type
     parameter is specified by passing in a generic parameter: a model class conforming to `EntryModellable`.

     - Parameter query: A QueryOn object to match results of the specified EntryModellable against.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchMappedEntries<EntryType: EntryModellable>(with query: QueryOn<EntryType>,
                                                then completion: @escaping ResultsHandler<MappedArrayResponse<EntryType>>) -> URLSessionDataTask? {

        let url = URL(forComponent: "entries", parameters: query.parameters)

        return fetch(url: url) { (result: Result<ArrayResponse<Entry>>) in

            let transformedResult: Result<MappedArrayResponse<EntryType>> = result.flatMap { return Result.success($0.toMappedArrayResponse()) }
            completion(transformedResult)
        }
    }

    /**
     Fetch a collection of Entries of a specified content type matching the query. The content_type
     parameter is specified by passing in a generic parameter: a model class conforming to `EntryModellable`.

     - Parameter query: A QueryOn object to match results of the specified EntryModellable against.

     - Returns: A tuple of data task and an observable for the resulting array of EntryModellable types.
     */
    @discardableResult public func fetchMappedEntries<EntryType: EntryModellable>(with query: QueryOn<EntryType>)
        -> Observable<Result<MappedArrayResponse<EntryType>>> {

        let asyncDataTask: AsyncDataTask<QueryOn<EntryType>, MappedArrayResponse<EntryType>> = fetchMappedEntries(with:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }
}


extension Client {
    /**
     Fetch a single Asset from Contentful.

     - Parameter id: The identifier of the Asset to be fetched.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchAsset(id: String, completion: @escaping ResultsHandler<Asset>) -> URLSessionDataTask? {
        return fetch(url: URL(forComponent: "assets/\(id)"), then: completion)
    }

    /**
     Fetch a single Asset from Contentful.

     - Parameter id: The identifier of the Asset to be fetched.

     - Returns: A tuple of data task and a signal for the resulting Asset.
     */
    @discardableResult public func fetchAsset(id: String) -> Observable<Result<Asset>> {
        let asyncDataTask: AsyncDataTask<String, Asset> = fetchAsset(id:completion:)
        return toObservable(parameter: id, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a collection of Assets from Contentful.

     - Parameter matching: An optional list of search parameters the Assets must match.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchAssets(matching: [String: Any] = [:],
                                               completion: @escaping ResultsHandler<ArrayResponse<Asset>>) -> URLSessionDataTask? {
        return fetch(url: URL(forComponent: "assets", parameters: matching), then: completion)
    }

    /**
     Fetch a collection of Assets from Contentful.

     - Parameter matching: Optional list of search parameters the Assets must match.

     - Returns: A tuple of data task and a signal for the resulting array of Assets.
     */
    @discardableResult public func fetchAssets(matching: [String: Any] = [:]) -> Observable<Result<ArrayResponse<Asset>>> {
        let asyncDataTask: AsyncDataTask<[String: Any], ArrayResponse<Asset>> = fetchAssets(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch the underlying media file as `Data`.

     - Parameter asset: The `Asset` which contains the relevant media file.
     - Parameter imageOptions: An optional array of options for server side manipulations.
     - Returns: Tuple of the data task and a signal for the `Data` result.

     */
    public func fetchData(for asset: Asset, with imageOptions: [ImageOption] = []) -> Observable<Result<Data>> {
        do {
            return fetch(url: try asset.url(with: imageOptions)).observable
        } catch let error {
            let observable = Observable<Result<Data>>()
            observable.update(Result.error(error))
            return observable
        }
    }
}

extension Client {
    /**
     Fetch a single Content Type from Contentful.

     - Parameter id: The identifier of the Content Type to be fetched.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchContentType(id: String, completion: @escaping ResultsHandler<ContentType>) -> URLSessionDataTask? {
        return fetch(url: URL(forComponent: "content_types/\(id)"), then: completion)
    }

    /**
     Fetch a single Content Type from Contentful.

     - Parameter id: The identifier of the Content Type to be fetched.

     - Returns: A tuple of data task and a signal for the resulting Content Type.
     */
    @discardableResult public func fetchContentType(id: String) -> Observable<Result<ContentType>> {
        let asyncDataTask: AsyncDataTask<String, ContentType> = fetchContentType(id:completion:)
        return toObservable(parameter: id, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a collection of Content Types from Contentful.

     - Parameter matching:   Optional list of search parameters the Content Types must match.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchContentTypes(matching: [String: Any] = [:],
                                                     completion: @escaping ResultsHandler<ArrayResponse<ContentType>>) -> URLSessionDataTask? {
        return fetch(url: URL(forComponent: "content_types", parameters: matching), then: completion)
    }

    /**
     Fetch a collection of Content Types from Contentful.

     - Parameter matching: Optional list of search parameters the Content Types must match.

     - Returns: A tuple of data task and a signal for the resulting array of Content Types.
     */
    @discardableResult public func fetchContentTypes(matching: [String: Any] = [:]) -> Observable<Result<ArrayResponse<ContentType>>> {
        let asyncDataTask: AsyncDataTask<[String: Any], ArrayResponse<ContentType>> = fetchContentTypes(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }
}

extension Client {
    /**
     Fetch a collection of Entries from Contentful.

     - Parameter matching:   Optional list of search parameters the Entries must match.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func fetchEntries(matching: [String: Any] = [:],
                                                completion: @escaping ResultsHandler<ArrayResponse<Entry>>) -> URLSessionDataTask? {
        return fetch(url: URL(forComponent: "entries", parameters: matching), then: completion)
    }

    /**
     Fetch a collection of Entries from Contentful.

     - Parameter matching: Optional list of search parameters the Entries must match.

     - Returns: A tuple of data task and a signal for the resulting array of Entries.
     */
    @discardableResult public func fetchEntries(matching: [String: Any] = [:]) ->  Observable<Result<ArrayResponse<Entry>>> {
        let asyncDataTask = fetchEntries(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetch a single Entry from Contentful.

     - Parameter id: The identifier of the Entry to be fetched.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchEntry(id: String, completion: @escaping ResultsHandler<Entry>) -> URLSessionDataTask? {
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

        return fetchEntries(matching: ["sys.id": id], completion: fetchEntriesCompletion)
    }

    /**
     Fetch a single Entry from Contentful.

     - Parameter id: The identifier of the Entry to be fetched.

     - Returns: A tuple of data task and a signal for the resulting Entry.
     */
    @discardableResult public func fetchEntry(id: String) ->  Observable<Result<Entry>> {
        let asyncDataTask: AsyncDataTask<String, Entry> = fetchEntry(id:completion:)
        return toObservable(parameter: id, asyncDataTask: asyncDataTask).observable
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
        if let space = self.space {
            completion(.success(space))
            return nil
        }
        return fetch(url: self.URL()) { (result: Result<Space>) in
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

// MARK: Sync

extension Client {
    /**
     Perform an initial synchronization of the Space this client is constrained to.

     - Parameter matching:   Additional options for the synchronization.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func initialSync(matching: [String: Any] = [:],
                                               completion: @escaping ResultsHandler<SyncSpace>) -> URLSessionDataTask? {

        var parameters = matching
        parameters["initial"] = true
        return sync(matching: parameters, completion: completion)
    }

    /**
     Perform an initial synchronization of the Space this client is constrained to.

     - Parameter matching: Additional options for the synchronization.

     - Returns: A tuple of data task and a signal for the resulting SyncSpace.
     */

    @discardableResult public func initialSync(matching: [String: Any] = [:]) -> Observable<Result<SyncSpace>> {
        let asyncDataTask: AsyncDataTask<[String: Any], SyncSpace> = initialSync(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }

    /**
     Perform a subsequent synchronization operation, updating this object with
     the latest content from Contentful.

     Calling this will mutate the instance and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - Parameter syncSpace: the relevant `SyncSpace` to perform the subsequent sync on.
     - Parameter matching: Additional options for the synchronization

     - Returns: An `Observable` which will be fired when the `SyncSpace` is fully synchronized with Contentful.
     */
    @discardableResult func nextSync(for syncSpace: SyncSpace, matching: [String: Any] = [:]) -> Observable<Result<SyncSpace>> {

        let observable = Observable<Result<SyncSpace>>()
        self.nextSync(for: syncSpace) { result in
            observable.update(result)
        }
        return observable
    }

    /**
     Perform a subsequent synchronization operation, updating the passed in `SyncSpace` with the
     latest content from Contentful.

     Calling this will mutate passed in SyncSpace and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - Parameter syncSpace: the relevant `SyncSpace` to perform the subsequent sync on.
     - Parameter matching:   Additional options for the synchronization
     - Parameter completion: A handler which will be called on completion of the operation

     - Returns: The data task being used, enables cancellation of requests
     */

    @discardableResult public func nextSync(for syncSpace: SyncSpace,
                                            matching: [String: Any] = [:],
                                            completion: @escaping ResultsHandler<SyncSpace>) -> URLSessionDataTask? {

        // Preview mode only supports `initialSync` not `nextSync`. The only reason `nextSync` should
        // be called while in preview mode, is internally by the SDK to finish a multiple page sync.
        // We are doing a multi page sync only when syncSpace.hasMorePages is true.
        if clientConfiguration.previewMode == true && syncSpace.hasMorePages == false {
            completion(Result.error(SDKError.previewAPIDoesNotSupportSync()))
            return nil
        }

        var parameters = matching
        parameters.removeValue(forKey: "initial")
        parameters["sync_token"] = syncSpace.syncToken

        // Callback to merge the most recent sync page with the current sync space.
        let mergeSyncSpacesCompletion: (Result<SyncSpace>) -> Void = { result in

            switch result {
            case .success(let newSyncSpace):

                // Send messages to persistence layer about the diffs (pre-merge state).
                self.sendSyncSpaceDiffMessagesToPersistenceIntegration(newestSyncSpace: newSyncSpace, resolvingLinksWith: syncSpace)
                syncSpace.updateWithDiffs(from: newSyncSpace)

                completion(Result.success(syncSpace))
            case .error(let error):
                completion(Result.error(error))
            }
        }

        let task = self.sync(matching: parameters, completion: mergeSyncSpacesCompletion)
        return task
    }

    fileprivate func sendSyncSpaceDiffMessagesToPersistenceIntegration(newestSyncSpace: SyncSpace, resolvingLinksWith originalSyncSpac: SyncSpace?) {

        persistenceIntegration?.update(syncToken: newestSyncSpace.syncToken)

        let allEntries = newestSyncSpace.entries + (originalSyncSpac?.entries ?? [])
        for entry in allEntries {
            let allAssets = newestSyncSpace.assets + (originalSyncSpac?.assets ?? [])
            entry.resolveLinks(against: allEntries, and: allAssets)
            persistenceIntegration?.create(entry: entry)
        }

        for asset in newestSyncSpace.assets {
            persistenceIntegration?.create(asset: asset)
        }

        for deletedAssetId in newestSyncSpace.deletedAssets {
            persistenceIntegration?.delete(assetWithId: deletedAssetId)
        }

        for deletedEntryId in newestSyncSpace.deletedEntries {
            persistenceIntegration?.delete(entryWithId: deletedEntryId)
        }

        persistenceIntegration?.resolveRelationships()
        persistenceIntegration?.save()
    }

    fileprivate func sync(matching: [String: Any] = [:], completion: @escaping ResultsHandler<SyncSpace>) -> URLSessionDataTask? {

        return fetch(url: URL(forComponent: "sync", parameters: matching)) { (result: Result<SyncSpace>) in
            if let syncSpace = result.value {

                if syncSpace.hasMorePages == true {
                    self.nextSync(for: syncSpace, matching: matching, completion: completion)
                } else {
                    self.sendSyncSpaceDiffMessagesToPersistenceIntegration(newestSyncSpace: syncSpace, resolvingLinksWith: nil)
                    completion(Result.success(syncSpace))
                }
            } else {
                completion(result)
            }
        }
    }

    fileprivate func sync(matching: [String: Any] = [:]) -> Observable<Result<SyncSpace>> {
        let asyncDataTask: AsyncDataTask<[String: Any], SyncSpace> = sync(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }
}
