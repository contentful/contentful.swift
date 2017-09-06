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

    fileprivate var server: String {

        if clientConfiguration.previewMode && clientConfiguration.server == Defaults.cdaHost {
            return Defaults.previewHost
        }
        return clientConfiguration.server
    }

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
            self.urlSession.configuration.httpAdditionalHeaders = headers
        }
    }

    // The delegate which will receive messages containing the raw data fetched at a specified URL.
    private var dataDelegate: DataDelegate?

    internal var urlSession: URLSession

    internal let contentModel: ContentModel?

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
                accessToken: String,
                clientConfiguration: ClientConfiguration = .default,
                sessionConfiguration: URLSessionConfiguration = .default,
                persistenceIntegration: PersistenceIntegration? = nil,
                contentModel: ContentModel? = nil) {

        self.spaceId = spaceId
        self.clientConfiguration = clientConfiguration
        self.contentModel = contentModel

        self.persistenceIntegration = persistenceIntegration
        self.dataDelegate = clientConfiguration.dataDelegate
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
                let queryItems: [URLQueryItem] = parameters.map { (arg) in
                    var (key, value) = arg

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

    internal func fetch<MappableType: ImmutableMappable>(url: URL?,
                        then completion: @escaping ResultsHandler<MappableType>) -> URLSessionDataTask? {

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
            if let spaceURL = self.URL(), spaceURL.absoluteString == url.absoluteString {
                // Now that we have a space, start callback chain.
                finishDataFetch(dataResult)
            } else {
                self.fetchSpace { spaceResult in
                    switch spaceResult {
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

    internal func fetch(url: URL) ->  (task: URLSessionDataTask?, observable: Observable<Result<Data>>) {
        let asyncDataTask: AsyncDataTask<URL, Data> = fetch
        return toObservable(parameter: url, asyncDataTask: asyncDataTask)
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
            let localeCodes = space.locales.map { $0.code }
            persistenceIntegration?.update(localeCodes: localeCodes)

            completion(Result.success(space))
            return nil
        }
        return fetch(url: self.URL()) { (result: Result<Space>) in
            self.space = result.value
            let localeCodes = self.space?.locales.map { $0.code } ?? []
            self.persistenceIntegration?.update(localeCodes: localeCodes)
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
    @discardableResult public func fetchData(for asset: Asset, with imageOptions: [ImageOption] = []) -> Observable<Result<Data>> {
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
    @discardableResult public func fetchContentType(id: String,
                                                    completion: @escaping ResultsHandler<ContentType>) -> URLSessionDataTask? {
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
    @discardableResult public func fetchEntry(id: String,
                                              completion: @escaping ResultsHandler<Entry>) -> URLSessionDataTask? {
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

        let syncCompletion: (Result<SyncSpace>) -> Void = { result in
            self.finishSync(for: SyncSpace(syncToken: ""),
                            newestSyncResults: result,
                            completion: completion)
        }
        return sync(matching: parameters, completion: syncCompletion)
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
    @discardableResult public func nextSync(for syncSpace: SyncSpace,
                                     matching: [String: Any] = [:]) -> Observable<Result<SyncSpace>> {

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

        let syncCompletion: (Result<SyncSpace>) -> Void = { result in
            self.finishSync(for: syncSpace,
                            newestSyncResults: result,
                            completion: completion)
        }

        let task = self.sync(matching: parameters, completion: syncCompletion)
        return task
    }

    fileprivate func sync(matching: [String: Any] = [:],
                          completion: @escaping ResultsHandler<SyncSpace>) -> URLSessionDataTask? {

        return fetch(url: URL(forComponent: "sync", parameters: matching)) { (result: Result<SyncSpace>) in

            if let syncSpace = result.value, syncSpace.hasMorePages == true {
                self.nextSync(for: syncSpace, matching: matching, completion: completion)
            } else {
                completion(result)
            }
        }
    }

    fileprivate func finishSync(for syncSpace: SyncSpace,
                                newestSyncResults: Result<SyncSpace>,
                                completion: ResultsHandler<SyncSpace>) {

        switch newestSyncResults {
        case .success(let newSyncSpace):
            syncSpace.updateWithDiffs(from: newSyncSpace)
            persistenceIntegration?.update(with: newSyncSpace)

            // Send fully merged syncSpace to completion handler.
            completion(Result.success(syncSpace))
        case .error(let error):
            completion(Result.error(error))
        }
    }
}
