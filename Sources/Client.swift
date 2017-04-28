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
#if os(iOS) || os(tvOS)
    import UIKit
#endif


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

     - Returns: An initialized client instance.
     */
    public init(spaceId: String,
                accessToken: String,
                clientConfiguration: ClientConfiguration = .default,
                sessionConfiguration: URLSessionConfiguration = .default) {
        self.spaceId = spaceId
        self.clientConfiguration = clientConfiguration

        let contentfulHTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "User-Agent": clientConfiguration.userAgent
        ]
        sessionConfiguration.httpAdditionalHeaders = contentfulHTTPHeaders
        self.urlSession = URLSession(configuration: sessionConfiguration)
    }

    internal func URL(forComponent component: String = "", parameters: [String: Any]? = nil) -> URL? {
        if var components = URLComponents(string: "\(scheme)://\(server)/spaces/\(spaceId)/\(component)") {
            if let parameters = parameters {
                let queryItems: [URLQueryItem] = parameters.map { key, value in
                    var value = value

                    if let date = value as? Date, let dateString = date.toISO8601GMTString() {
                        value = dateString
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

        // Get the signal.
        let (task, observable) = fetch(url: url)

        if MappableType.self == Space.self {
            observable.then { [weak self] mappable in
                self?.handleJSON(mappable, completion)
            }.error { error in
                completion(Result.error(error))
            }
        } else {

            fetchSpace().then { _ in
                observable.then { [weak self] mappable in
                    self?.handleJSON(mappable, completion)
                }.error { error in
                    completion(Result.error(error))
                }
            }.error { error in
                completion(Result.error(error))
            }
        }

        return task
    }

    fileprivate func fetch(url: URL, completion: @escaping ResultsHandler<Data>) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: url) { data, response, error in
            if let data = data {
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
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let json = json as? NSDictionary { json.client = self }

            let map = Map(mappingType: .fromJSON, JSON: json as! [String : Any])

            // Handle error thrown by CDA.
            if let error = try? ContentfulError(map: map) {
                completion(Result.error(error))
                return
            }

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

     - Returns: Tuple of the data task and a signal for the `Data` result.
     */
    public func fetchData(for asset: Asset) -> Observable<Result<Data>> {
        do {
            return fetch(url: try asset.URL()).observable
        } catch let error {
            let observable = Observable<Result<Data>>()
            observable.update(Result.error(error))
            return observable
        }
    }

#if os(iOS) || os(tvOS)
    /**
     Fetch the underlying media file as `UIImage`.

     - returns: The signal for the `UIImage` result
     */
    public func fetchImage(for asset: Asset) -> Observable<Result<UIImage>> {
        return self.fetchData(for: asset).flatMap { result -> Observable<Result<UIImage>> in

            let imageResult = result.flatMap { data -> Result<UIImage> in
                if let image = UIImage(data: data) {
                    return Result.success(image)
                } else {
                    return Result.error(QueryError.invalidOrderProperty)
                }
            }

            return Observable<Result<UIImage>>(imageResult)
        }
    }
#endif
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
    @discardableResult public func fetchContentTypes(matching: [String: Any] = [:]) ->  Observable<Result<ArrayResponse<ContentType>>> {
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
        return fetch(url: self.URL(), then: completion)
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

    func sync(matching: [String: Any] = [:], completion: @escaping ResultsHandler<SyncSpace>) -> URLSessionDataTask? {
        if clientConfiguration.previewMode {
            completion(.error(SDKError.previewAPIDoesNotSupportSync()))
            return nil
        }

        return fetch(url: URL(forComponent: "sync", parameters: matching)) { (result: Result<SyncSpace>) in
            if let syncSpace = result.value {
                syncSpace.client = self

                if syncSpace.hasMorePages == true {
                    var parameters = matching
                    parameters.removeValue(forKey: "initial")
                    syncSpace.sync(matching: parameters, completion: completion)
                } else {
                    completion(.success(syncSpace))
                }
            } else {
                completion(result)
            }
        }
    }

    func sync(matching: [String: Any] = [:]) -> Observable<Result<SyncSpace>> {
        let asyncDataTask: AsyncDataTask<[String: Any], SyncSpace> = sync(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }
}
